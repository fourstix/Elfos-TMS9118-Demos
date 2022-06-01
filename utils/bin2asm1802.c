/*
 * bin2asm1802.c - Convert raw binary TI99a image files to 1802 Asssembly
 * Copyright 2022 by Gaston Williams
 * Based on bin2inc by Tursi - http://harmlesslion.com
 *
 * The original code said "Please do not modify and redistribute"
 * So I wrote a new program to do a similar thing for the 1802
 * assembler, rather than adding a new '1802' option to the original code.
 *
 * This program is a bit different from the original, in that it creates 
 * one large include file, and doesn't require as many options. Alsos it's 
 * written in C rather than C++.
 *
 * Many thanks to the original author for making the code available.
 */
#include <stdio.h>
#include <ctype.h>

//Image size is 256x192 bits or 6144 bytes
#define TI99_SIZE  6144

// global file handles
FILE *f_input, *f_output;			  

int convertImageData(char* image_name, char* ext, char* array_name);
void showInfo(char* data_type, int size);

int main(int argc, char* argv[]) {
	char f_name[256];  // file name buffer
	int converted = 0;  // count of data bytes converted

	//if no image name, show usage message
	if (argc != 2) {
		printf("Usage: %s image_name \n", argv[0]);
		printf("  Converts raw binary TI99 image data files into 1802 Assembler data statements.\n");
		printf("  Image data files should be raw binary files that have no headers.\n");
		printf("Inputs:\n");
		printf("  Bitmap pattern raw data file: image_name.TIAP.\n");
		printf("  Colortable raw data file: image_name.TIAC.\n");
    printf("Output:\n");
		printf("  1802 Assembler include file: image_name.inc.\n");
		return -1;
	} //if

  //open the bitmap pattern file first
  sprintf(f_name, "%s.TIAP", argv[1]);
	printf("\nOpening bitmap pattern file: %s\n", f_name);
	f_input = fopen( f_name, "rb");  //open file as binary data
	if (!f_input) {
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if
	
	//create include file for output
  sprintf(f_name, "%s.inc", argv[1]);
	f_output = fopen( f_name, "w");	//create otuput file as text
	if (!f_output) {
		fclose(f_input);
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if

	//convert raw bitmap data to 1802 data statments 
  converted = convertImageData(argv[1], ".TIAP", "BITMAP");
  //show the number of data bytes converted
	showInfo("Bitmap", converted); 
	//close bitmap data file
	fclose(f_input);
	
	//process colortable data file
	sprintf(f_name, "%s.TIAC", argv[1]);	
	printf("\nOpening colortable file: %s\n", f_name);
	f_input = fopen( f_name, "rb");
	if (!f_input) {
		fclose(f_output);
		printf("Cannot open %s\n", f_name);
		return -1;
	} //if
	//convert raw colortable data to 1802 data statments 
	converted = convertImageData(argv[1], ".TIAC", "COLORTABLE");
  //close colortable and include file
	fclose(f_input);
	fclose(f_output);
	
  //show the number of data bytes converted
	showInfo("Colortable", converted);
	printf("\nCreated 1802 Assembler include file: %s.inc\n", argv[1]);
  printf("Done.\n");
	return 0;
} //main

//read image data from file and convert to 1802 Assembler data statements
int convertImageData(char* image_name, char* ext, char* array_name) {
	unsigned char buf[16];  //was 128 but shouldn't go over 8 so 16 should be safe
	int line_width = 8;			// number bytes expected per line
	int total = 0;          // total bytes processed
	int position = 0;       // position in data array for comments
	
	//create commments with file name
	fprintf(f_output, ";\n; Data file %s%s\n;\n", image_name, ext);
	//create label at start of data structure
	fprintf(f_output, "START_%s:\n", array_name);
  
	//read the bytes in the file and convert them
	while (!feof(f_input)) {
		int byte_count;  //number of bytes actually read per line

    //clear buffer for bytes and read one line's worth
		memset(buf, 0, line_width);
		byte_count = (int) fread(buf, 1, line_width, f_input);
		if (byte_count > 0) {
			// if we got any bytes write them as a defined byte data line
			fprintf(f_output, "\tdb ");
			//write bytes as comma separated hex values
			for (int i = 0; i < byte_count; i++) {
				fprintf(f_output, "0%02Xh", buf[i]);
				if (i < byte_count-1) {
					fprintf(f_output, ", ");
				} //if
			} //for
			
			// output end of line data postion as a comment for each line
			fprintf(f_output, "\t; %04X ", position+byte_count);
			fprintf(f_output, " \n");
			total += byte_count;
			position += byte_count;
		} else {
			//no bytes read or an error occurred
			break;
		} //if-else byte_count > 0
	} //while
  //create a label at END of data structure
	fprintf(f_output, "END_%s:\n", array_name);
	//define constant word value for size of array	
	fprintf(f_output, "%s_SIZE: equ %d\t", array_name, total);
  fprintf(f_output, "; Size of data in above array\n");
	return total;
} // convertImageData

void showInfo(char* data_type, int size) {
	printf("%s data: Converted %d bytes\n", data_type, size);
	
	//If TI99 data size is greater than 256 x 192 bits, or 6144 bytes,
	//then the file probably had some kind of header data that got converted
	//along with the image data bytes into the image data statments. 
	//So warn user that the data in the created include file is corrupted.
	if (size > TI99_SIZE) {
		printf("\n*** Warning ***\n");
		printf("The converted data size %d is larger than expected size of 6144 bytes.\n", size);
		printf("%s data in the include file is probably corruptted by header data.\n", data_type);
		printf("Files created by Convert9918 must be saved as type *Raw Files*.\n");
	  } //if
} //showInfo
