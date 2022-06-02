# Make Your Own Demo

Making an image program using your own image involves four major steps.
- Set up the pre-requisites for [Asm/02 assembler](https://github.com/rileym65/Asm-02) and install [Convert9118 Conversion program.](http://harmlesslion.com/cgi-bin/onesoft.cgi?2).
- Converting the image to raw binary files using [Convert9918](https://github.com/tursilion/convert9918).
- Converting raw binary files to an 1802 Assembly include file.
- Assemble the demo program using [Asm/02](https://github.com/fourstix/Asm-02/releases).

## Set up Pre-Requisites
The Convert9918 is a Windows program, so these instructions will set up the pre-requisites under Windows. 
- Download the zip file for [Convert9918 from github](https://github.com/tursilion/convert9918/blob/main/dist/Convert9918.zip) or from the [Harmlesslion.com website](http://harmlesslion.com/zips/Convert9918.zip).  Unzip the files and install the *Convert9918.exe* program under Windows in a working directory.  
- Download the [bin2asm1802.exe](https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/utils/bin2asm1802.exe) utility program into the working directory.
- Download the latest release [Windows version of the Asm/02 assembler](https://github.com/fourstix/Asm-02/releases) and install the *Asm02.exe* file under Windows in an Asm02 program directory.
- In an assembly source directory, download the asm.bat file and bin2asm1802.exe file.  Edit the asm.bat file to replace the text *[Your_PATH]* with the correct path to the Asm02 program directory on your computer.
- Download the [demo.asm](https://github.com/fourstix/Elfos-TMS9118-Demos/blob/main/src/demo.asm) source file and place it in the assembly source directory with *asm.bat*.
- Underneath the assembly source directory, create an [include directory](https://github.com/fourstix/Elfos-TMS9118-Demos/tree/main/src/include) with the files *vdp.inc*, *bios.inc* and *ops.inc*.  These are the common include files for definitions for all programs in this repository.
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

# Convert the raw binary files to an 1802 Assembly include file.
- Copy the two files **DEMO.TIAP** and **DEMO.TIAC** into the same directory as the **bin2asm1802** program.
- Run command *bin2asm1802 DEMO* to run the bin2asm1802 with the parameter **DEMO**.
- The conversion program will create a file named **DEMO.inc**.  This file contains the data statements with the bitmap pattern data and colortable data.

# Assemble the image data into the demo program.  
- Copy the 1802 Assembly file **DEMO.inc** into the same directory as *demo.asm* and *asm.bat*.
- Run the command *asm demo.asm* to assemble the demo program with the image data in the **DEMO.inc** file.
- If desired, rename the assembled program to something more meaningful, like *hatteras*.
- Download the program to the 1802-Mini and run it.

References
----------
There are several good references on image conversion available on the harmlesslion.com website.
- [Convert9918](http://harmlesslion.com/cgi-bin/onesoft.cgi?2) - Convert modern graphics into TMS9918A compatible bitmaps.
- [Modern Graphics on the 9918](https://harmlesslion.com/text/Modern%20Graphics%20on%20the%209918.pdf) by Mike Brent aka Tursi.
- [Harmlesslion.com Conversion Software](http://harmlesslion.com/software/convert)

License Information
-------------------
  
  This code is public domain under the MIT License, but please buy me a beverage
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  The demo.as code is based on programs written by Glenn Jolly.
  
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
