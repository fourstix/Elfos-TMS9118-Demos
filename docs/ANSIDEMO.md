# ANSI Demo

The ansi demo program supports writing text strings to the TMS9X18 display. It supports escape codes for 
several common ASCII control chracters, and it support a limited set of ANSI control strings that relate to 
changing text colors.

## Supported ASCII Control characters
The ASCII control characters are supported through escape sequences that begin with the backslash (\) character.
<table>
<tr><th>Escape sequence</th><th>ASCII Name</th><th>Hex Value</th><th>Action</th></tr>
<tr><td>\a</td><td>Alert</td><td>0x07</td><td>Toggle Inverse Text.</td></tr>
<tr><td>\b</td><td>Backspace</td><td>0x08</td><td>Move left, and erase character</td></tr>
<tr><td>\t</td><td>Horizontal Tab</td><td>0x09</td><td>Move to next tab stop. (Right 4 characters)</td></tr>
<tr><td>\n</td><td>Newline</td><td>0x0A</td><td>Move to beginning of next line.</td></tr>
<tr><td>\v</td><td>Vertical Tab</td><td>0x0B</td><td>Move down two lines. (Double space)</td></tr>
<tr><td>\f</td><td>Form Feed</td><td>0x0C</td><td>Clear screen and return cursor to home.</td></tr>
<tr><td>\r</td><td>Carriage Return</td><td>0x0D</td><td>Move to beginning of next line.</td></tr>
<tr><td>\g</td><td>Shift Out</td><td>0x0E</td><td>Bold Text.</td></tr>
<tr><td>\d</td><td>Shift In</td><td>0x0F</td><td>Reset text to default style.</td></tr>
<tr><td>\c</td><td>Device Linked Escape</td><td>0x10</td><td>Set the next byte as the color map byte.</td></tr>
<tr><td>\e</td><td>Escape</td><td>0x1B</td><td>Escape character for ANSI sequences.</td></tr>
<tr><td>\\</td><td>Backslash</td><td>0x5C</td><td>Literal backslash character.</td></tr>
<tr><td>\x</td><td>Hexadecimal byte</td><td>0xhh</td><td>Treat next two characters hh as a Hexadecimal byte value.</td></tr>
</table>
  
## Notes for the ASCII contrl characters
- The sequences \r\n and \n\r are interpreted as a single new line.  
- The sequence \\ denotes a single literal backslash character.
- The sequence \xhh denotes a hexadecimal byte value of hh.
- The sequence \e denotes the escape character (0x1B).
- The sequence \c can be used to send a particular color byte such as \x4f to the display. The first
four bits of the color byte denote the foreground and the lower four bits denote the background.
- A zero in the upper 4 bits will leave the foreground color unchanged, and a zero in the lower 4 bits of the color byte will leave the background color unchanged.
- Horizontal tabs do not wrap around to the next line, and vertical tabs do not wrap to the first line of the screen.

## ANSI Sequences

<table>
<tr><th>Address</th><th colspan="4">Data Bytes</th><th>Description</th></tr>
<tr><td>0000h:</td><td>59</td><td>A6</td><td>6A</td><td>95</td><td>Magic Number</td></tr>
<tr><td>0004h:</td><td>00</td><td>00</td><td>01</td><td>00</td><td>Image width = 256 pixels</td></tr>
<tr><td>0008h:</td><td>00</td><td>00</td><td>00</td><td>C0</td><td>Image height = 192 pixels</td></tr>
<tr><td>000Ch:</td><td>00</td><td>00</td><td>00</td><td>01</td><td>Image depth = 1 plane</td></tr>
<tr><td>0010h:</td><td>00</td><td>00</td><td>aa</td><td>bb</td><td>Bitmap data length: aabbh</td></tr>
<tr><td>0014h:</td><td>00</td><td>00</td><td>00</td><td>xx</td><td>Data type: xx</td></tr>
<tr><td>0018h:</td><td>00</td><td>00</td><td>00</td><td>02</td><td>Color Map data type = 02</td></tr>
<tr><td>001Ch:</td><td>00</td><td>00</td><td>cc</td><td>dd</td><td>Color Map data length: ccddh</td></tr>
<tr><td>0020h:</td><td colspan="4"> Color Map Data</td><td>(ccddh bytes)</td></tr>
<tr><td>ccddh + 0020h:</td><td colspan="4"> Bitmap Data</td><td>(aabbh bytes)</td></tr>
</table>

**Notes:**
- Header size is 32 bytes, consisting of eight 4-byte big-endian integers.
- Data Type xx is either 01 for uncompressed, or 02 for Sun RLE compressed data. Other data types are not supported.
- Bitmap length aabb is 1800h (or 6144) bytes for uncompressed data.
- Only color map data type 02 for Raw Color Map Data is supported. RGB format is not supported.
- Color map length ccdd is 1800h (or 6144) bytes for uncompressed data.
- Total size, including header size, is 3020h (or 12,320) bytes for an uncompressed image.

S
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
