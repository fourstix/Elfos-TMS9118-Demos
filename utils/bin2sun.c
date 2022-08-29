/*
 * bin2rle.c - Convert TI99a image data files to Sun image file.
 * Copyright 2022 by Gaston Williams
 *
 * The input data files can be raw data files or TI FILES format data.
 */
#include <stdio.h>
//show the number of data bytes converted
#include <string.h>
#include <ctype.h>

//Image size is 256x192 bits or 6144 bytes
#define TI99_SIZE   6144
#define STD_SIZE   12288



void writeSunHeader(FILE* f_out, int rle);
int  writeRasterData(FILE* f_in, FILE* f_out);
int  writeRleData(FILE* f_in, FILE* f_out);
void showInfo(char* data_type, int size, int rle);
void writeLengths(int b_size, int c_size, FILE* f_out);
void usageInfo(char* fname);

char* ti_header  = "\aTIFILES";   //Indicates a TIFILE data format
int   compressed = 0;

int main(int argc, char* argv[]) {
	FILE *f_cmap, *f_bmap, *f_output; // file handles			  
	char f_name[256];  // file name buffer
	int cmap_size  = 0;  // count of data bytes converted
  int bmap_size  = 0;  // count of data bytes converted
  int total_size = 0;
	int name_idx  = 1;	
	//if no image name, show usage message
	if (argc == 3) {
		//check for rle compression option
		if (strcmp(argv[1], "-c") == 0) {
			name_idx = 2;
			compressed = 1;
		} else {
			//if any unknown option show the syntax
			usageInfo(argv[0]);
		} //if strcmp
	} else if (argc == 2) {
		//default format is uncompressed
		name_idx = 1;
		compressed = 0;
	} else {
		usageInfo(argv[0]);
		return -1;
	} //if - else if argc

  //open the color map file first
  sprintf(f_name, "%s.TIAC", argv[name_idx]);
	printf("\nOpening colortable file: %s\n", f_name);
	f_cmap = fopen( f_name, "rb");  //open file as binary data
	if (!f_cmap) {
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if
	
	//create Sun raster image file for output
  sprintf(f_name, "%s.ras", argv[name_idx]);
	f_output = fopen( f_name, "wb");	//create otuput file as text
	if (!f_output) {
		fclose(f_cmap);
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if

  //write the SUN Raster header data
	writeSunHeader(f_output, compressed);
	//convert color map data into raster data 
  if (compressed) {
		cmap_size = writeRleData(f_cmap, f_output);
	} else {
		cmap_size = writeRasterData(f_cmap, f_output);
	}
	
	showInfo("Color map", cmap_size, compressed); 
	//close bitmap data file
	fclose(f_cmap);
	
	//process bitmap data file
	sprintf(f_name, "%s.TIAP", argv[name_idx]);	
	printf("\nOpening bitmap pattern file: %s\n", f_name);
	f_bmap = fopen(f_name, "rb");
	if (!f_bmap) {
		fclose(f_output);
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if
	
	//convert bitmap data to raster data
	if (compressed) {
		bmap_size = writeRleData(f_bmap, f_output);	
	} else {
		bmap_size = writeRasterData(f_bmap, f_output);
  }	//if-else compressed
  
	//close colortable and include file
	fclose(f_bmap);
	
	//update bitmap data and colortable data lengths in header
	writeLengths(bmap_size, cmap_size, f_output);
	fclose(f_output);
	
  //show the number of data bytes converted
	showInfo("Bitmap", bmap_size, compressed);
	printf("\nCreated Sun Raster image file: %s.ras\n", argv[name_idx]);
	//Warn if compressed file is larger than uncompressed
	if (compressed) {
		//check the size of RLE encoded image data
		int total_size = bmap_size + cmap_size;
		
		if (total_size > STD_SIZE) {
			printf("\nWarning: The RLE encoded image size of %d bytes is larger than uncompressed image size.\n", total_size);
		} //if total_size
	}//if compressed
  printf("Done.\n");
	return 0;
} //main

//Write the header for a Sun Raster image file
void writeSunHeader(FILE* f_out, int rle) {
	//SUN Raster header consists of eight 4-byte big endian integers
	char header[32] = 
				{'\x59','\xa6', '\x6a', '\x95',   //magic number for Sun Raster format
	      '\x00', '\x00', '\x01', '\x00',   //image width = 256 pixels
				'\x00', '\x00', '\x00', '\xC0',   //image height = 192 pixels
				'\x00', '\x00', '\x00', '\x01',   //image depth = 1 plane
				'\x00', '\x00', '\x00', '\x00',   //bitmap data length will go here
				'\x00', '\x00', '\x00', '\x02',   //raster data type 2 = rle compresion
				'\x00', '\x00', '\x00', '\x02',   //color map type 2 = raw bytes (not rgb)
				'\x00', '\x00', '\x00', '\x00'};  //color table length will go here
	
				if (!rle) {
					  //change data type byte to uncompressed
						header[23] = '\x01';
				} //if !rle
				
	//Write the 32 byte Sun Raster header 
	fwrite(header, 32, 1, f_out);
	
	
} //writeSunHeader
	
//update the length values in the header
void writeLengths(int b_size, int c_size, FILE* f_out) {
	unsigned char buf[4];  //write a 4 byte big-endian int value
	
	buf[0] = '\x00';
	buf[1] = '\x00';
	
	//Write the bitmap data length
	//swap byte order to write in big endian, not little endian form
	buf[3] = (b_size & 0xFF);
	buf[2] = ((b_size >> 8) & 0xFF);
	
	//move to bit map length 20 bytes from beginning
	fseek(f_out, 16, SEEK_SET);
  fwrite(buf, 1, 4, f_out);	
	
	//skip over 8 bytes for data type and color map type
	fseek(f_out, 8, SEEK_CUR);
	//Write the color map length next, swapping byte order for big endian form
	buf[3] = c_size & 0xFF;
	buf[2] = (c_size >> 8) & 0xFF;
	
	fwrite(buf, 1, 4, f_out);
}//writeLengths

//read image data from file and write it out as raster data
int writeRasterData(FILE* f_in, FILE* f_out) {
	unsigned char buf[256];  //read and write in 256 byte blocks
	int buf_size = 256;			// number bytes in a block
	int total = 0;          // total bytes processed
	
	//clear buffer to check header
	memset(buf, 0, buf_size);	
	//read the first nine bytes into the buffer 8 bytes + possible null
	fread(buf, 1, 9, f_in);
	
	//Check to see if this is a TI Files format data file
	if (strncmp(buf, ti_header, 8) == 0) {
		//File has TI header so skip next 119 bytes (128 - 9 already read)
		fseek(f_in, 119, SEEK_CUR);
		printf("TI FILES Format: Skipping header.\n");
	} else {
		//Raw data file so go back to beginning
		rewind(f_in);
		printf("Raw Data: No header.\n");
	} //if

	//read the bytes in the file and write them as raster data
	while (!feof(f_in)) {
		int byte_count;  //number of bytes actually read per line

    //clear buffer for bytes and read one block's worth
		memset(buf, 0, buf_size);
		byte_count = (int) fread(buf, 1, buf_size, f_in);
		
		if (byte_count > 0) {
			// if we got bytes write them as raster data
			int write_count = fwrite(buf, 1, byte_count, f_out);
			
			// bump total
			total += write_count;
		} else {
			//fflush(f_out);
			//no bytes read or an error occurred
			break;
		} //if-else byte_count > 0
	} //while
  return total;
} // writeRasterData

//read image data from file and write it out as raster data
int writeRleData(FILE* f_in, FILE* f_out) {
	unsigned char buf[10];  //buffer for first 9 bytes of header
	unsigned char curr;   //current character in data stream
	unsigned char next;  //next character in data stream
	unsigned char b_cnt; //output byte for rle count
	int c_count = 0;		 // number time character is repeated
	int total = 0;       // total bytes processed
	unsigned char marker = '\x80'; //marker byte for rle data sequence
	int finished = 0;		 // flag to exit when all data has been compressed
	
	//clear buffer and check header
	memset(buf, 0, 10);	
	//read the first nine bytes into the buffer 8 bytes + possible null
	fread(buf, 1, 9, f_in);
	
	//Check to see if this is a TI Files format data file
	if (strncmp(buf, ti_header, 8) == 0) {
		//File has TI header so skip next 119 bytes (128 - 9 already read)
		fseek(f_in, 119, SEEK_CUR);
		printf("TI FILES Format: Skipping header.\n");
	} else {
		//Raw data file so go back to beginning
		rewind(f_in);
		printf("Raw Data: No header.\n");
	} //if

  fread(&curr, 1, 1, f_in);
	fread(&next, 1, 1, f_in);
	
	//read the bytes in the file and write them as Sun RLE compressed data
	while (1) {
		// RLE count is encoded as one byte (count-1)
		if (c_count < 255 && (curr == next) && !finished) {
			c_count++;
		} else if (curr == marker) {
			b_cnt = (unsigned char) c_count;
			if (c_count > 0) {
				//multiple 0x80 bytes
				fwrite(&marker, 1, 1, f_out);
				fwrite(&b_cnt,  1, 1, f_out);
				fwrite(&curr,   1, 1, f_out);
				total += 3;
			} else {
				//always escape 0x80;
				b_cnt = (unsigned char) 0;
				fwrite(&marker, 1, 1, f_out);
				fwrite(&b_cnt,  1, 1, f_out);
				total += 2;
				} //if - else count > 0			
			c_count = 0;
		} else {
			 if (c_count > 1) {
				 //3 or more repeated bytes are compressed to 3 bytes
				 b_cnt = (unsigned char) c_count;
				 fwrite(&marker, 1, 1, f_out);
				 fwrite(&b_cnt, 1,1, f_out);
				 fwrite(&curr, 1, 1, f_out);
				 total += 3;
			 } else if (c_count == 1) {
				 //two bytes has no compression savings, so just write out
				 fwrite(&curr, 1, 1, f_out);
				 fwrite(&curr, 1, 1, f_out);
				 total += 2;
			 } else {
				 // single bytes that are just written out as is
				 fwrite(&curr, 1, 1, f_out);
				 total += 1;
			 } // if count > 1, 1 or 0			 
			 c_count = 0;
		} //if curr == next - else if curr == marker - else curr != marker 

		//if we have finished all the data exit loop
		if (finished) {
			break;
		} // if finished
		
		// put previous byte as current and get next byte
		curr = next;
    fread(&next, 1, 1, f_in);	
		//when we read past the end of file change flag to write out data and exit
		if (feof(f_in)) {
			finished = 1;
		}// if feof()
	} //while
	
  return total;
} // writeRleData

//show information after processing data file 
void showInfo(char* data_type, int size, int rle) {
	if (rle) {
		printf("%s data: Compressed to %d bytes\n", data_type, size);
	} else {
		printf("%s data: Converted %d bytes\n", data_type, size);
	}//if RLE
	
	if (rle && (size > TI99_SIZE)) {
		//Let the user know that the rle compression didn't save any bytes
		printf("The compressed data size %d is larger than uncompressed size of 6144 bytes.\n", size);
		printf("%s data in the raster image may be smaller if uncompressed.\n", data_type);
	} else if (!rle && (size != TI99_SIZE)) {
		//If uncompressed TI99 data size is greater than 256 x 192 bits, or 6144 bytes,
		//then the file probably had some unknown kind of header data that was
		//converted along with the image data bytes into the image data statments. 
		//So warn user that the data in the created include file is probably corrupted.
		
		printf("\n*** Warning ***\n");
		printf("The converted data size %d is not the expected size of 6144 bytes.\n", size);
		printf("%s data in the raster image file may be corrupt.\n", data_type);
		printf("Files created by Convert9918 must be saved with a *TIFILES header* or as type *Raw Files*.\n");		
	} //if-else if 
} //showInfo

//Print usage information on command line
void usageInfo(char* fname) {
	printf("Usage: %s [-c] image_name \n", fname);
	printf("  Converts TI99 image data files into a Sun Raster image file.\n");
	printf("  Image data files should be TI data files or raw binary files with no headers.\n");
	printf("Inputs:\n");
	printf("  Bitmap pattern data file: image_name.TIAP.\n");
	printf("  Color table data file: image_name.TIAC.\n");
	printf("Option:\n");
	printf("  -c compress the output image data using the Sun RLE format.\n");
	printf("Output:\n");
	printf("  Sun raster image file: image_name.ras.\n");
} //usageInfo
