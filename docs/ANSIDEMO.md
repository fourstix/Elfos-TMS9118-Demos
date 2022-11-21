# ANSI Demo

The ANSI demo program supports writing text strings to the TMS9X18 display. It supports escape codes for 
several common ASCII control characters, and it support a limited set of ANSI control strings that relate to 
changing text colors.

## Supported ASCII Control characters
The ASCII control characters are supported through escape sequences that begin with the backslash (\) character.

<table>
<tr><th>Escape sequence</th><th>ASCII Name</th><th>Hex Value</th><th>Action</th></tr>
<tr><td>\a</td><td>Alert</td><td>0x07</td><td>Reverse Text.</td></tr>
<tr><td>\b</td><td>Backspace</td><td>0x08</td><td>Move left, and erase previous character</td></tr>
<tr><td>\t</td><td>Horizontal Tab</td><td>0x09</td><td>Move to next tab stop. (Right 4 characters)</td></tr>
<tr><td>\n</td><td>Newline</td><td>0x0A</td><td>Move to beginning of next line.</td></tr>
<tr><td>\v</td><td>Vertical Tab</td><td>0x0B</td><td>Move cursor down two lines, the horizontal location is not changed. (Double space)</td></tr>
<tr><td>\f</td><td>Form Feed</td><td>0x0C</td><td>Clear screen and return cursor to home.</td></tr>
<tr><td>\r</td><td>Carriage Return</td><td>0x0D</td><td>Move to beginning of next line.</td></tr>
<tr><td>\g</td><td>Shift Out</td><td>0x0E</td><td>Bold Text.</td></tr>
<tr><td>\d</td><td>Shift In</td><td>0x0F</td><td>Reset text to default style.</td></tr>
<tr><td>\c</td><td>Device Linked Escape</td><td>0x10</td><td>Set the next byte as the color map byte.</td></tr>
<tr><td>\e</td><td>Escape</td><td>0x1B</td><td>Escape character for ANSI sequences.</td></tr>
<tr><td>\\</td><td>Backslash</td><td>0x5C</td><td>Literal backslash character.</td</tr>
<tr><td>\x</td><td>Hexadecimal byte</td><td>0xhh</td><td>Treat next two characters hh as a Hexadecimal byte value.</td></tr>
</table>
  
**Notes:**
- The sequences \r\n and \n\r are interpreted as a single new line.  
- The sequence \\ denotes a single literal backslash character.
- The sequence \xhh denotes a hexadecimal byte value of hh. For example, \x1b would give the Escape character denoted by \e.
- The sequence \e denotes the escape character (\x1b).
- The sequence \c can be used to send a particular color byte such as \x4f to the display. The first four bits of the color byte denote the TMS9X18 foreground color and the lower four bits denote the TMS9X18 background color.
- A zero (Transparent color) in the upper 4 bits will leave the foreground color unchanged, and a zero in the lower 4 bits of the color byte will leave the background color unchanged.
- Horizontal tabs do not wrap around to the next line, and vertical tabs do not wrap around to the first line of the screen.

## Supported ANSI Sequences

**Note:**
- All ANSI Escape sequences start with the characters *\e[* (0x1b0x5b). 
- An erase sequence ends with *J*, and only 1 erase sequence *\e[2J* (erase screen) is supported. 
- All the other supported sequences are ANSI graphics sequences. 
- All ANSI graphics sequences end with *m*. Multiple graphics sequences may appear in a single ANSI escape sequence separated by a *;* (semicolon).  
- For example the ANSI sequence *\e[1;37;44m* would set the text foreground color to Bright White and the background color to Blue.

<table>
<tr><th>ANSI Sequence</th><th>Description</th><th>Notes</th></tr>
<tr><td>\e[m</td><td>Reset text style and color</td><td>Same as \e[0m</td></tr>
<tr><td>\e[0m</td><td>Reset text style and color</td><td>The foreground and background colors are set to their default values.</td></tr>
<tr><td>\e[1m</td><td>Bright color</td><td>If no color specified in sequence, set foreground color bright (intense).</td></tr>
<tr><td>\e[2J</td><td>Clear Screen</td><td>Clear Screen, Home Cursor and Exit.</td></tr>
<tr><td>\e[2m</td><td>Dim color</td><td>If no color specified in sequence, set foreground color dim (normal).</td></tr>
<tr><td>\e[30m to \e[37m</td><td>Set foreground color</td><td>See table below for color values.</td></tr>
<tr><td>\e[40m to \e[47m</td><td>Set background color</td><td>See table below for color values.</td></tr>
<tr><td>\e[5m</td><td>Blink Text</td><td>Shift foreground and background colors and then swap. See table below for color shift pairs. </td></tr>
<tr><td>\e[7m</td><td>Reverse Text</td><td>Swap foreground color with background color.</td></tr>
</table>

**Notes:**
- Blink is supported by shifting and swapping the foreground and background colors, since the TMS9X18 display hardware does not directly support blinking text.
- The default foreground color is Bright White and the default background color is Black.

## TMS9X18 Color Values
<table>
<tr><td>0</td><td>Transparent</td><td>8</td><td>Red</td></tr>
<tr><td>1</td><td>Black</td><td>9</td><td>Light Red</td></tr>
<tr><td>2</td><td>Green</td><td>A</td><td>Yellow</td></tr>
<tr><td>3</td><td>Light Green</td><td>B</td><td>Light Yellow</td></tr>
<tr><td>4</td><td>Blue</td><td>C</td><td>Dark Green</td></tr>
<tr><td>5</td><td>Light Blue</td><td>D</td><td>Magenta</td></tr>
<tr><td>6</td><td>Dark Red</td><td>E</td><td>Gray</td></tr>
<tr><td>7</td><td>Cyan</td><td>F</td><td>White</td></tr>
</table>

**Notes:**
- The color byte after the \c (Device Link Escape) control character has the foreground color value in its upper 4-bits and the background color in its lower 4-bits.
- For example, the control characters \c\xf4 will set the text color to White on Blue.
- The default color map byte value is \xf1, White on Black.
- A value of zero (Transparent) in the color byte will not change the corresponding color value. For example, \c\x04 will not change the foreground color, but will set the background color to Blue.

## ANSI Foreground Color Values

<table>
<tr><th colspan="4">Normal (Dim) Colors</th></tr>
<tr><th>ANSI Sequence</th><th>ANSI Color</th><th>TMS9x18 Color</th><th>TMS9x18 Value</th></tr>
<tr><td>\e[30m</td><td>Black</td><td>Black</td><td>1</td></tr>
<tr><td>\e[31m</td><td>Red</td><td>Dark Red</td><td>6</td></tr>
<tr><td>\e[32m</td><td>Green</td><td>Dark Green</td><td>C</td></tr>
<tr><td>\e[33m</td><td>Yellow</td><td>Yellow</td><td>A</td></tr>
<tr><td>\e[34m</td><td>Blue</td><td>Blue</td><td>4</td></tr>
<tr><td>\e[35m</td><td>Magenta</td><td>Magenta</td><td>D</td></tr>
<tr><td>\e[36m</td><td>Cyan</td><td>Black</td><td>1</td></tr>
<tr><td>\e[37m</td><td>White</td><td>Gray</td><td>E</td></tr>
<tr><th colspan="4">Bright (Intense) Colors</th></tr>
<tr><th>ANSI Sequence</th><th>ANSI Color</th><th>TMS9x18 Color</th><th>TMS9x18 Value</th></tr>
<tr><td>\e[1;30m</td><td>Bright Black</td><td>Gray</td><td>E</td></tr>
<tr><td>\e[1;31m</td><td>Bright Red</td><td>Light Red</td><td>9</td></tr>
<tr><td>\e[1;32m</td><td>Bright Green</td><td>Green</td><td>2</td></tr>
<tr><td>\e[1;33m</td><td>Bright Yellow</td><td>Light Yellow</td><td>B</td></tr>
<tr><td>\e[1;34m</td><td>Bright Blue</td><td>Light Blue</td><td>5</td></tr>
<tr><td>\e[1;35m</td><td>Bright Magenta</td><td>Red</td><td>8</td></tr>
<tr><td>\e[1;36m</td><td>Bright Cyan</td><td>Light Green</td><td>3</td></tr>
<tr><td>\e[1;37m</td><td>Bright White</td><td>White</td><td>F</td></tr>
<table>

**Notes:**
- The default foreground color is (\e[1;37m) Bright White.
- Bright Black (\e[1;30m) and (Normal) White (\e[37m) are both mapped to the same TMS9X18 color Gray (E).

## ANSI Background Color Values
<table>
<tr><th colspan="4">Normal (Dim) Colors</th></tr>
<tr><th>ANSI Sequence</th><th>ANSI Color</th><th>TMS9x18 Color</th><th>TMS9x18 Value</th></tr>
<tr><td>\e[40m</td><td>Black</td><td>Black</td><td>1</td></tr>
<tr><td>\e[41m</td><td>Red</td><td>Dark Red</td><td>6</td></tr>
<tr><td>\e[42m</td><td>Green</td><td>Dark Green</td><td>C</td></tr>
<tr><td>\e[43m</td><td>Yellow</td><td>Yellow</td><td>A</td></tr>
<tr><td>\e[44m</td><td>Blue</td><td>Blue</td><td>4</td></tr>
<tr><td>\e[45m</td><td>Magenta</td><td>Magenta</td><td>D</td></tr>
<tr><td>\e[46m</td><td>Cyan</td><td>Black</td><td>1</td></tr>
<tr><td>\e[47m</td><td>White</td><td>Gray</td><td>E</td></tr>
<tr><th colspan="4">Bright (Intense) Colors</th></tr>
<tr><th>ANSI Sequence</th><th>ANSI Color</th><th>TMS9x18 Color</th><th>TMS9x18 Value</th></tr>
<tr><td>\e[1;40m</td><td>Bright Black</td><td>Gray</td><td>E</td></tr>
<tr><td>\e[1;41m</td><td>Bright Red</td><td>Light Red</td><td>9</td></tr>
<tr><td>\e[1;42m</td><td>Bright Green</td><td>Green</td><td>2</td></tr>
<tr><td>\e[1;43m</td><td>Bright Yellow</td><td>Light Yellow</td><td>B</td></tr>
<tr><td>\e[1;44m</td><td>Bright Blue</td><td>Light Blue</td><td>5</td></tr>
<tr><td>\e[1;45m</td><td>Bright Magenta</td><td>Red</td><td>8</td></tr>
<tr><td>\e[1;46m</td><td>Bright Cyan</td><td>Light Green</td><td>3</td></tr>
<tr><td>\e[1;47m</td><td>Bright White</td><td>White</td><td>F</td></tr>
<table>

**Notes:**
- The default background color is Black (\e[47m).
- Bright Black (\e[1;40m) and (Normal) White (\e[47m) are both mapped to the same TMS9X18 color, Gray (E).

## ANSI Blink Color Shift

ANSI foreground and background color indexes are represented as 4-bit hex numbers, bit numbered as bit 3,2,1,0. For the ANSI sequence \e[5m (Blink) the foreground and background colors are shifted by toggling bit 2 (xor 0x04) of the 4-bit ANSI color index value, and then the foreground and background colors are swapped.  Bit 3 of the 4-bit color index value is used as the Intensity (Bright) bit and is not changed.  The table below gives the following ANSI color pairs. The blink sequence shifts colors between the values on each row.

<table>
<tr><th colspan="4">Normal (Dim) Color Pairs</th></tr>
<tr><th>Index Value</th><th>Color</th><th>Index Value</th><th>Color</th></tr>
<tr><td>0</td><td>Black</td><td>4</td><td>Blue</td></tr>
<tr><td>1</td><td>Red</td><td>5</td><td>Magenta</td></tr>
<tr><td>2</td><td>Green</td><td>6</td><td>Cyan</td></tr>
<tr><td>3</td><td>Yellow</td><td>7</td><td>Gray (Dim White)</td></tr>
<tr><th colspan="4">Bright (Intense) Color Pairs</th></tr>
<tr><th>Index Value</th><th>Color</th><th>Index Value</th><th>Color</th></tr>
<tr><td>8</td><td>Gray (Intense Black)</td><td>C</td><td>Bright Blue</td></tr>
<tr><td>9</td><td>Bright Red</td><td>D</td><td>Bright Magenta</td></tr>
<tr><td>A</td><td>Bright Green</td><td>E</td><td>Bright Cyan</td></tr>
<tr><td>B</td><td>Bright Yellow</td><td>F</td><td>Bright White</td></tr>
</table>


ANSI Parser State Machine
-------------------------
<table>
<tr><th>State</th><th>Character</th><th>Action</th><th>Next State</th></tr>
<tr><td>Start</td><td>\e[</td><td>Begin Parsing ANSI Command String</td><td>Begin ANSI Seq</td></tr>
<tr><td rowspan="10">Begin ANSI Seq</td><td>(peak) m</td><td rowspan="3">Reset, Set fg and bg to default, clear Intensity flag</td><td rowspan="6">End ANSI Seq</td></tr>
<tr><td>(peak) ;</td></tr>
<tr><td>0</td></tr>
<tr><td>1</td><td>Bright, Set Intensity flag</td></tr>
<tr><td>2, (peak) J</td><td>Clear Screen and Home Cursor</td></tr>
<tr><td>2</td><td>Dim, Clear Intensity flag</td></tr>
<tr><td>3</td><td>(Next character determines foreground color)</td><td>Set Foreground Color</td></tr>
<tr><td>4</td><td>(Next character determines background color)</td><td>Set Background Color</td></tr>
<tr><td>5</td><td>Blink, Shift fg and bg colors, swap</td><td rowspan="4">End ANSI Seq</td></tr>
<tr><td>7</td><td>Reverse, Swap fg and bg colors</td></tr>
<tr><td>Set Foreground Color</td><td>0-7 (Color Index)</td><td>Set fg color based on index and intensity flag, clear intensity flag</td></tr>
<tr><td>Set Background Color</td><td>0-7 (Color Index)</td><td>Set bg color based on index and intensity flag, clear intensity flag</td></tr>
<tr><td rowspan="3">End ANSI Seq</td><td>;</td><td>Continue Parsing ANSI Graphics Command</td><td>Begin ANSI Seq</td></tr>
<tr><td>m</td><td>Set Colors based on ANSI Graphics Command and Exit</td><td rowspan="3">Exit</td></tr>
<tr><td>J</td><td>(Exit after ANSI Erase Command)</td></tr>
<tr><td>(Any State)<td>Unexpected Character</td><td>Print "^[?" to indicate error and Exit</td></tr>
</table>

**Note:**
- "Start" is the initial state, and "Exit" is the final state.
- The ASCII escape character represented by \e could also be represented by \x1b. 
- (peak) means the parser looks at the next character, without consuming it. The character will be consumed at the next state.
- The parsed ANSI string should end with an 'm' or 'J' character.
- A semicolon (;) can be used to string several ANSI graphic sequences together in single command.
- The ANSI graphics command always ends with an 'm' character and the text color updates are done when the end character is encountered.
- An empty sequence, such as "\e[m" or "\e[;m", are interpreted as the default ANSI graphics sequence, Reset ("\e[0m").
- An unexpected character will end the parser with an error message, "^[?".

References
----------

- [Wikipedia: ANSI escape code](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [ANSI Escape Sequences Gist](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797])
- [Summary of ANSI standards for ASCII terminals](http://www.inwap.com/pdp10/ansicode.txt)
- [ANSI.SYS Documentation and Reference](http://www.roysac.com/learn/ansisys.html)

License Information
-------------------
  
  This code is public domain under the MIT License, but please buy me a beverage
  if you use this and we meet someday (Beerware).
  
  References to any products, programs or services do not imply
  that they will be available in all countries in which their respective owner operates.
  
  Any company, product, or services names may be trademarks or services marks of others.
  
  All libraries used in this code are copyright their respective authors.
  
  Some demos program code is based on programs originally written by Glenn Jolly.
  
  The original TMS9118 Demo source and binaries
  Copyright (c) 2021 by Glenn Jolly
  
  Elf/OS 
  Copyright (c) 2004-2022 by Mike Riley
  
  Asm/02 1802 Assembler
  Copyright (c) 2004-2022 by Mike Riley
  
  The 1802-Mini Hardware
  Copyright (c) 2021-2022 by David Madole
    
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
