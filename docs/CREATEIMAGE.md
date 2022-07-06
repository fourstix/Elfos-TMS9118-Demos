# Create a Sun Raster Image

Making an image program using your own image involves four major steps.
- Set up pre-requisites and install [Convert9118 Conversion program.](http://harmlesslion.com/cgi-bin/onesoft.cgi?2).
- Converting the image to raw binary files using [Convert9918](https://github.com/tursilion/convert9918).
- Converting raw binary files to a Sun Raster Image file.
- Assemble the demo program using [Asm/02](https://github.com/fourstix/Asm-02/releases).

## Setup Pre-requisites and Install the Convert9918 Conversion program
The Convert9918 is a Windows program, so these instructions will set up the pre-requisites under Windows. 
- Download the zip file for [Convert9918 from github](https://github.com/tursilion/convert9918/blob/main/dist/Convert9918.zip) or from the [Harmlesslion.com website](http://harmlesslion.com/zips/Convert9918.zip).  Unzip the files and install the *Convert9918.exe* program under Windows in a working directory.  
- Download the [bin2sun.exe](https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/utils/bin2asm1802.exe) utility program into the working directory.
- Decide on a demo image.  An image with 4x3 aspect ratio with a central feature contrasting with a simple background seems to work best with the TI9118 graphics mode 2. A sample [demo image](https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/pics/demo.jpg) of the [Cape Hatteras lighthouse](https://en.wikipedia.org/wiki/Cape_Hatteras_Lighthouse) is used in this example.

## Convert the JPG image to raw binary Files
- Start the Convert9918 program, press Open and select your image.  
- The image will load and then a dithered version will appear.
  <table>
  <tr><td>
  <img src="https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/pics/Convert_1.jpg">
  </td></tr>
  <tr><td>Convert9918 Image Conversion</td></td></tr>
  </table>
- Press Save, and the dialog change the type to "Raw Files".  Note saving the image into any other type of   file will not work.  The *bin2asm1802* program requires raw binary files without any headers.
- Enter a file name, such as *demo*. Do not enter an extension.
  <table>
  <tr><td>
  <img src="https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/pics/Convert_2.jpg">
  </td></tr>
  <tr><td>Convert9918 Save File Dialog</td></td></tr>
  </table>
- Convert9918 will create two files: a bitmap pattern file named **DEMO.TIAP** and a colortable file named **DEMO.TIAC**.

# Convert the raw binary files to a Sun Raster Image file.
- Copy the two files **DEMO.TIAP** and **DEMO.TIAC** into the same directory as the **bin2sun** program.
- The command syntax is *bin2sun [-c]* **filename** where filename is the file name for the TIAP and TIAC files.
- Run command *bin2sun DEMO* to run the bin2sun with the parameter **DEMO**.
- The conversion program will create a file named **DEMO.ras**.  This Sun Raster image file contains the image bitmap pattern data and color table data in the uncompressed format.
- To create a compressed Sun Raster image file, run the bin2sun command with the '-c' option.
- Run the command *bin2sun -c DEMO* to run the bin2sun with the option -c and the file name **DEMO**.
- The conversion program will create a file named **DEMO.ras**.  This Sun Raster image file contains the image bitmap pattern data and color table data in the Sun RLE compressed format.  This is often smaller than the uncompressed data size.

# Display the image with the view program.  
- If desired, rename the assembled program to something more meaningful, like *hatteras.ras*.
- Download the program to the 1802-Mini and run the view program to display it.
- Run the Elf/OS program *view hatteras.ras* to display the demo image data in the **hatteras.ras** file.

Sun Raster Image Format
-----------------------
The Sun Raster Image format consists of a 32 byte header, consisting of eight 4-byte big-endian integers.
The header is followed by the color map data as raw data bytes, either uncompressed or compressed in the Sun RLE format.
The color map data is followed by the bitmap data, either uncompressed or compressed in the Sun RLE format.
<table>
<tr><th>Address</th><th colspan="4">Data Bytes</th><th>Description</th></tr>
<tr><td>0000h:</td><td>59</td><td>A6</td><td>6A</td><td>95</td><td>Magic Number</td></tr>
<tr><td>0004h:</td><td>00</td><td>00</td><td>01</td><td>00</td><td>Image width = 256 pixels</td></tr>
<tr><td>0008h:</td><td>00</td><td>00</td><td>00</td><td>C0</td><td>Image height = 192 pixels</td></tr>
<tr><td>000Ch:</td><td>00</td><td>00</td><td>00</td><td>01</td><td>Image depth = 1 plane</td></tr>
<tr><td>0010h:</td><td>00</td><td>00</td><td>00</td><td>xx</td><td>Data type: xx</td></tr>
<tr><td>0014h:</td><td>00</td><td>00</td><td>aa</td><td>bb</td><td>Bitmap data length: aabbh</td></tr>
<tr><td>0018h:</td><td>00</td><td>00</td><td>00</td><td>02</td><td>Color Map data type = 02</td></tr>
<tr><td>001Ch:</td><td>00</td><td>00</td><td>cc</td><td>dd</td><td>Color Map data length: ccddh</td></tr>
<tr><td>0020h:</td><td colspan="4"> Color Map Data</td><td>(ccddh bytes)</td></tr>
<tr><td>ccddh + 0020h:</td><td colspan="4"> Bitmap Data</td><td>(aabbh bytes)</td></tr>
</table>

**Notes:**
- Header size is 32 bytes, consisting of eight 4-byte big-endian integers.
- Data Type xx is either 01 for uncompressed, or 02 for Sun RLE compressed data. Other data types are not supported.
- Bitmap length aabbh is 1800h for uncompressed data.
- Only color map data type 02 for Raw Color Map Data is supported. RGB format is not supported.
- Color map length ccddh is 1800h for uncompressed data.
- Total data size is 3020h (or 12,320) bytes for an uncompressed image.

Sun RLE Algorithm
-----------------
- If the first byte is not 0x80, the record is one byte long, and contains a pixel value.  Output 1 pixel of that value.
-  If the first byte is 0x80 and the second byte is zero, the record is two bytes long.  Output 1 pixel with value 0x80.
-  If the first byte is 0x80, and the second byte is not zero, the record is three bytes long.  The second byte is a count and the third byte is a value.  Output (count+1) pixels of that value.

**Notes:**
- The count byte can be a maximum of 0xFF or 255, so up to 256 pixel bytes can be encoded at once.
- It's inefficient to encode a pixel sequence of less than 3 bytes, so double pixel bytes, are not usually encoded.
- But any sequence of 0x80 pixel bytes must always be encoded, and a single pixel value 0x80 is always encoded as 0x80 0x00. 
- Most efficient for graphic images with solid color pixel areas, but less efficient for photographic images with dithering.

**Examples**
<table>
<tr><th>Sun RLE Sequence</th><th>Decoded Pixel Bytes</th><th>Note</th></tr>
<tr><td>34 E7 72</td><td>34 E7 72</td><td>Unencoded byte sequence</td></tr>
<tr><td>E7 E7 40</td><td>E7 E7 40</td><td>Double bytes not usually encoded</td></tr>
<tr><td>80 02 34</td><td>34 34 34</td><td>3 byte (count+1) encoded sequence</td></tr>
<tr><td>80 04 E7</td><td>E7 E7 E7 E7 E7</td><td>5 byte (count+1) encoded sequence</td></tr>
<tr><td>80 00</td><td>80</td><td>Single 80 byte</td></tr>
<tr><td>80 01 80</td><td>80 80</td><td>Double 80 bytes must encoded</td></tr>
<tr><td>80 03 80</td><td>80 80 80 80</td><td>Four 80 bytes (count +1) sequence</td></tr>
</table>

References
----------
There are several good references on image conversion available on the harmlesslion.com website.
- [Convert9918](http://harmlesslion.com/cgi-bin/onesoft.cgi?2) - Convert modern graphics into TMS9918A compatible bitmaps.
- [Modern Graphics on the 9918](https://harmlesslion.com/text/Modern%20Graphics%20on%20the%209918.pdf) by Mike Brent aka Tursi.
- [Harmlesslion.com Conversion Software](http://harmlesslion.com/software/convert)
- [CG Notes: Sun Raster Image format](http://steve.hollasch.net/cgindex/formats/sunraster.html)
- [Multimedia Wiki: Sun Rasterfile](http://steve.hollasch.net/cgindex/formats/sunraster.html)
- [FileFormat.Info: Sun Rasterfile Specs](https://www.fileformat.info/format/sunraster/spec/index.htm)

License Information
-------------------
  
  This code is public domain under the MIT License, but please buy me a beverage
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  The demos code is based on programs written by Glenn Jolly.
  
  The Convert9918 program was written by Mike Brent (Tursi @ Harmlesslion.com).
  
  Convert9918 Image Conversion Program
  Copyright (c) 2017-2022 by Mike Brent
  
  TMS9118 Demo source and binaries
  Copyright (c) 2021 by Glenn Jolly
  
  Elf/OS 
  Copyright (c) 2004-2022 by Mike Riley
  
  Asm/02 1802 Assembler
  Copyright (c) 2004-2022 by Mike Riley
  
  The 1802-Mini Hardware
  Copyright (c) 2021-2022 by David Madole
  
  The bin2asm1802 Utility
  Copyright (c) 2022 by Gaston Williams
  
  The bin2sun Utility
  Copyright (c) 2022 by Gaston Williams
  
  Sun Rasterfile Image Specification
  Copyright (c) 1989 Sun Microsystems
  
  Many thanks to the original authors for making their designs and code available as open source.
   
  This code, firmware, and software is released under the [MIT License](http://opensource.org/licenses/MIT).
  
  The MIT License (MIT)
  
  Copyright (c) 2022 by Gaston Williams
  
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.
  
  **THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.**
