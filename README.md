# Elfos-TMS9118-Demos
A set of Elf/OS Demo programs for the [1802-Mini TMS9x18 Video Card](https://github.com/dmadole/1802-Mini-9918-Video) by David Madole. These demos are based on programs originally written by Glen Jolly and posted in the
files section of the COSMAC ELF Group in the [Glenn Jolly/TMS9118](https://groups.io/g/cosmacelf/files/Glenn%20Jolly/TMS9118) folder at groups.io.  These programs were all assembled into 1802 binary files using the [Asm/02 1802 Assembler](https://github.com/rileym65/Asm-02) by Mike Riley.

Library 
--------
These commands were written to use the [TMS9X18 Video Library](https://github.com/fourstix/Elfos-TMS9X18-Library) so that the same code can run on multiple hardware configurations without the need to be re-assembled.  The library API communicates to the video card hardware through the [TMS9x18 Video Driver](https://github.com/fourstix/Elfos-TMS9X18-Driver) so that the program code doesn't need to be modified to match the hardware differences.

Elf/OS TMS9118 Demos
-------------------------------------
## blank
This program simply displays a black screen.

## collision
This program shows how the collision detection works for two sprites. Press Input to end.

## collision_noq
Same collision detection program as above, except this version does not change the Q bit
during the demo. Press Input to end.

## demo 
Template program to make your own demo program using Convert9918 and utility program
to convert TI99A raw binary files into 1802 Assembly code data statements.  Details
are in the Make Your Own tutorial [available here](docs/MAKEYOUROWN.md).
  
## fivesprites
This program shows five sprites, the fifth sprite moving up and down behind the band of
the other 4. The fourth sprite changes color when the fifth passes by. Press Input to end the demo.

## fivesprites_noq
Same five sprites demo program as above, except this version does not change the Q bit during 
the demo. Press Input to end.

## lena
This program displays a bitmap of the model Lena Forsen.

## mackaw
This program displays a bitmap of a colorful bird.

## mandrill
This program displays a bitmap of colorful monkey.

## plotPixel
This program plots a graph of the sine(x)/x function.

## saucer
This program displays a desert with a UFO sprite landing. Press Input to end the demo.

## showPalette
This program displays vertical bars for the palette colors.

## spaceship2
Displays a color version of the classic Cosmac spaceship by Joseph A Weisbecker. 

## textColors
Show different text and background color combinations. Press 0 to 9 to change colors and 'x' to exit.

## view
**Usage:** view *filename*  

Display a Sun Raster image file *filename*.  Supports uncompressed and Sun RLE compressed image files.

## slideshow
**Usage:** slideshow *[-r]* *[path]*

Show the Sun Raster image files in a directory specified by *path*. If *path* is not specified then the current directory is used. Press input to end the slideshow before all images are shown. The *-r* option will cause the slide show to repeat in a loop until input is pressed. 

Library Files
-------------
The demo files are grouped into an Elf/OS library file *tms9118.lbr* that can be unpacked with the Elf/OS lbr command using the e option to *extract* files. Extract these demo files with the Elf/OS command *lbr e tms9118*

[Make Your Own Demo](docs/MAKEYOUROWN.md)
------------------
The program [Convert9918](http://harmlesslion.com/cgi-bin/onesoft.cgi?2) by Tursi at Harmlesslion.com converts a jpeg image file into two raw binary data files that can then be converted into data statements in an 1802 include file which can then be assembled into a program to display the image under the Elf/OS.  A [step by step tutorial](docs/MAKEYOUROWN.md) is available that details how to create your own image demo. 

[Create a Sun Raster Image file](docs/CREATEIMAGE.md)
------------------
The program [Convert9918](http://harmlesslion.com/cgi-bin/onesoft.cgi?2) by Tursi at Harmlesslion.com converts a jpeg image file into two raw binary data files that can then be converted into a Sun Raster image file that can be displayed using the *view* utility or the *slideshow* program under the Elf/OS.  A [step by step tutorial](docs/CREATEIMAGE.md) is available that details how to create your own image demo. 

Repository Contents
-------------------
* **/src/**  -- Common source files for assembling Elf/OS utilities.
  * asm.bat - Windows batch file to assemble source file with Asm/02 to create binary file. Use the command *asm xxx.asm* to assemble the xxx.asm file.
  * blank.asm - Demo to blank the display.
  * collision.asm - Demo to show sprite collision detection.
  * collision_noq.asm - Collision demo without using the Q bit.
  * demo.asm - Template to make your own demo program.
  * fivesprites.asm - Demo with five sprites, the last one moving up and down.
  * fivesprites_noq.asm - Five sprites demo without using the Q bit.
  * lena.asm - Demo to display a test bitmap.
  * mackaw.asm - Demo to display a test bitmap.
  * mandrill.asm - Demo to display a test bitmap.
  * plotPixel.asm - Demo to display a data plot.
  * saucer.asm - Demo of a flying saucer landing in the desert.
  * showPalette - Demo showing vertical color bars.
  * spaceship2 - Demo to display color version of the Cosmac spaceship bitmap.
  * textColors - Demo to display various text and background colors.
  * view - Program to display Sun Raster image files.
  * slideshow - Program to display Sun Raster image files in a directory.
* **/src/include/**  -- Source files for Elf/OS file utilities.
  * ops.inc - Opcode definitions for Asm/02.
  * bios.inc - Bios definitions from Elf/OS
  * vdp.inc - Video card configuration constants  
* **/bin/**  -- Binary files for TMS9118 demo programs.
* **/docs/** -- Documentation files.
   * MAKEYOUROWN.md - Tutorial to make your own image demo using [Convert9918](https://github.com/tursilion/convert9918). 
* **/lbr/**  -- Library file for TMS9118 demos. (Unpack with Elf/OS lbr command)
  * tms9118.lbr - Library file for TMS9118 demos.
* **/pics/** -- Picture files used in the readme and demo tutorial, including sample demo image files.
  * demo.jpg - Sample jpeg image used in the tutorials. (Vacation photo of Cape Hatteras Lighthouse.)
  * demo.ras - Sample uncompressed Sun Raster image file.
  * demo.rle - Sample RLE compressed Sun Raster image file.
* **/pics/samples/** -- Sample Sun Raster image files for TMS9118 Video Card
  * eclipse.ras - Nasa photo of 2017 Solar Eclipse.
  * maui.ras - Vacation photo of a beach in Maui.
  * moose.ras - Vacation photo of a moose in Alaska.
  * niagara.ras - Vacation photo of Niagara Falls.
  * train.ras - Vacation photo of Alaskan Railroad train engine.
* **/utils/** -- Utility program used in the Make Your Own demo. 
  * bin2asmm1802.exe - Executable utility program to convert TI99A raw binary files into an 1802 Assembly include file.  
  * bin2asm1802.c - Source file for executable bin2asm1802 utility program.
  * bin2sun.exe - Executable utility program to convert TI99A raw binary files into a Sun Raster Image file.  
  * bin2sun.c - Source file for executable bin2sun utility program.

License Information
  -------------------
  
  This code is public domain under the MIT License, but please buy me a beverage
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  This code is based on programs written by Glenn Jolly.
  
  TMS9118 Demo source and binaries
  Copyright (c) 2021 by Glenn Jolly
  
  Elf/OS 
  Copyright (c) 2004-2022 by Mike Riley
  
  Asm/02 1802 Assembler
  Copyright (c) 2004-2022 by Mike Riley
  
  The 1802-Mini Hardware
  Copyright (c) 2021-2022 by David Madole
   
  The Convert9918 Image Conversion Program 
  Copyright (c) 2017-2022 by Mike Brent
  
  The bin2asm1802 Utility
  Copyright (c) 2022 by Gaston Williams
  
  The bin2sun Utility
  Copyright (c) 2022 by Gaston Williams
  
  Sun Rasterfile Image Specification
  Copyright (c) 1989 by Sun Microsystems
  
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
