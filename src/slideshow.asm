; -------------------------------------------------------------------
;                         viewer
; Display a Sun Raster image file on the TMS9118 Video Card
; Supports uncompressed and RLE compressed raster image data.
;
; Copyright 2022 by Gaston Williams
; ------------------------------------------------------------------- 
; Program for 1802-Mini with the TMS9118 Color Video Card
; published by David Madole:
;
;      https://github.com/dmadole/1802-Mini
;
; This program uses the TMS9118 graphics mode 2 for 'bitmap' display
; -------------------------------------------------------------------
; -------------------------------------------------------------------
; *** Uses BIOS calls from software written by Michael H Riley
; *** Original author copyright notice:
; -------------------------------------------------------------------
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; -------------------------------------------------------------------
;             TMS9118 / TMS9918
;            Graphics 2 memory map
;            +-----------------+ 0000h
;            |                 |
;            |  Pattern Table  |
;            |   6144 bytes    |
;            +-----------------+ 1800h
;            |                 |
;            | Sprite Patterns |
;            |    512 bytes    |
;            +-----------------+ 2000h
;            |                 |
;            |   Color Table   |
;            |   6144 bytes    |
;            +-----------------+ 3800h 
;            |                 |
;            |    Name Table   |
;            |    768 bytes    |
;            +-----------------+ 3B00h 
;            |                 |
;            |Sprite Attributes|
;            |    256 bytes    |
;            +-----------------+ 3C00h 
;            |                 |
;            |     Unused      |
;            |                 |
;            +-----------------+ 3FFFh 
;
; -------------------------------------------------------------------
;                     Sun Raster Image Format
;      32-byte header consisting of eight 4-byte Big Endian Integers
;      Followed by color map data as raw bytes (uncompressed or Sun rle)
;      Followed by bitmap data (uncompressed or Sun rle)
;
;     +-------------------+ 0000h 
;  1  | 59 | A6 | 6A | 95 |  Magic Number
;     +-------------------+ 0004h 
;  2  | 00 | 00 | 01 | 00 |  image width = 256 pixels
;     +-------------------+ 0008h 
;  3  | 00 | 00 | 00 | C0 |  image height = 192 pixels
;     +-------------------+ 000Ch 
;  4  | 00 | 00 | 00 | 01 |  image depth = 1 plane
;     +-------------------+ 0010h 
;  5  | 00 | 00 | 00 | xx |  data type xx: 01 = uncompressed, 02 = Sun rle compression
;     +-------------------+ 0014h 
;  6  | 00 | 00 | aa | bb |  bitmap data length = aabbh (Uncompressed length is 1800h bytes)
;     +-------------------+ 0018h 
;  7  | 00 | 00 | 00 | 02 |  color data type: 02 = raw data 
;     +-------------------+ 001Ch 
;  8  | 00 | 00 | cc | dd |  color map data length = ccddh (Uncompressed length is 1800h bytes)
;     +-------------------+ 0020h
;     |  Color Map Data   |  
;     +-------------------+ ccddh + 0020h (always 1820h for data type 01)
;     |    Bitmap Data    | 
;     +-------------------+ aabbh + cccch + 0020h (always 3020h for data type 01)
;
;     bytes 0-18 = magic number, image size must match exatly as shown above
;     byte 19 = data type, must be 01 or 02, anything else is an error
;     bytes 22,23 = bitmap data length (16 bit)
;     byte 27 = color map data type, must be 02 for raw color data (not rgb)
;     bytes 30,31 = color map data length (16 bit)
; -------------------------------------------------------------------

#include    include/bios.inc
#include    include/kernel.inc
#include    include/ops.inc
#include    include/vdp.inc

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
   org     02000h-6              ; Header starts at 01ffah
          dw      02000h          ; Program load address
          dw      endrom-2000h    ; Program size
          dw      02000h          ; Program execution address

   org     02000h            ; Program code starts here
          br      start           ; Jump past build information

     ; Build date
date:     db      80H+7           ; Month, 80H offset means extended info
          db      05              ; Day
          dw      2022            ; Year

     ; Current build number
build:     dw      2

     ; Must end with 0 (null)
          db      'Copyright 2022 Gaston Williams',0

start:     mov     rf,next             ; point to dirents pointer
           mov     r7,dirents          ; dirents storage
           ldi     0                   ; terminate list
           str     r7
           ghi     r7                  ; store pointer
           str     rf
           inc     rf
           glo     r7
           str     rf
           CALL    docrlf              ; display a cr/lf
           ghi     ra
           phi     rf
           glo     ra
           plo     rf
sw_lp:     CALL    f_ltrim             ; move past leading whitespace
           ldn     rf                  ; check for switches
           smi     '-'                 ; which begin with -
           bnz     no_sw               ; jump if no switches
           inc     rf                  ; move to switch char
           lda     rf                  ; retrieve switch
           smi     'r'                 ; check for long mode
           lbnz    usage               ; unknown option show usage message
           LOAD    rb, mode            ; point to modes variable
           ldi     0FFh
           str     rb                  ; set mode to true to repeat
           CALL    f_ltrim             ; move past leading whitespace
no_sw:     LOAD    rd, path            ; point to save path           
           CALL    f_strcpy            ; copy path into memory
           LOAD    rf, path            ; check the path 
           ldn     rf
           lbz     get_path             ; if no path just skip check
find_end:  lda     rf
           lbnz    find_end           
           dec     rf                  ; back up to null
           dec     rf                  ; back up to last character
           lda     rf                  ; check last character 
           smi     '/'
           lbz     get_path            ; path ends in slash,  okay to use
           ldi     '/'                 ; otherwise add path separator
           str     rf
           inc     rf                  ; advance to next character position     
           ldi     0                   ; end with a null
           str     rf                              

get_path:  LOAD    rf, path            ; point rf to path
           CALL    o_opendir           ; open the directory
           ldi     0                   ; setup line counter
           plo     r7
dirloop:   ldi     0                   ; need to read 32 bytes
           phi     rc
           ldi     32
           plo     rc
           ldi     high buffer         ; setup transfer buffer
           phi     rf
           ldi     low buffer
           plo     rf
           CALL    o_read              ; read files from dir
           glo     rc                  ; see if eof was hit
           smi     32
           lbnz    dirdone             ; jump if done
           ldi     high buffer         ; setup transfer buffer
           phi     rf
           ldi     low buffer
           plo     rf
           lda     rf                  ; check for good entry
           bnz     dirgood
           lda     rf                  ; check for good entry
           bnz     dirgood
           lda     rf                  ; check for good entry
           bnz     dirgood
           lda     rf                  ; check for good entry
           bnz     dirgood
           lbr     dirloop             ; not a valid entry, loop back
; *************************************************************
; *** Good entry found, copy needed data to dirents storage ***
; *************************************************************
dirgood:   mov     rf,buffer+6         ; point to flags byte
           ldn     rf                  ; retrieve it
           ani     11                  ; check for hidden, excutable or directory
           lbz     noflags             ; jump if plain file
           lbr     dirloop             ; otherwise do not show it
noflags:   mov     rf,next             ; need to retrieve next pointer
           lda     rf                  ; put into rc
           phi     rc
           ldn     rf
           plo     rc                  ; rc now points to blank space in dirents
           mov     rf,buffer+12        ; point to filename
           ldi     19                  ; 20 bytes per filename
           plo     re
namelp:    lda     rf                  ; get next byte from name
           lbz     namedn              ; jump if name is done
           str     rc                  ; store into dirents storage
           inc     rc
           dec     re                  ; decrement count
           glo     re                  ; check count
           lbnz    namelp              ; loop until all bytes copied
namedn:    ldi     0                   ; write a string terminator
           str     rc
           inc     rc
             
; ***********************
; *** Done with entry ***
; ***********************
           ldi     0                   ; write terminator into list
           str     rc
           mov     rf,next             ; save new pointer
           ghi     rc
           str     rf
           inc     rf
           glo     rc
           str     rf
           lbr     dirloop             ; keep reading entries
           
; **************************************************************************
; *** Done reading directory, now it needs to be processed and displayed ***
; **************************************************************************
dirdone:   CALL o_close             ; close the directory
           
display:   mov  rf,dirents          ; point to dirents storage
displp:    ldn  rf                  ; rf points to next entry
           lbz  list_done           ; see if done with list
           
           PUSH rf                  ; save rf before copying string
           LOAD rd, iname           ; point to image name
           CALL f_strcpy            ; copy to image name buffer
           POP  rf                  ; restore rf
           
           LOAD rb, path            ; copy path in front of filename
           LOAD rd, fname
           lda  rb
           lbz  cpy_name            ; if no path, just copy name                 
cpy_path:  str  rd                  ; put path character in filename
           inc  rd
           lda  rb                  ; get next character
           lbnz cpy_path            ; continue until last character copied         
cpy_name:  CALL f_strcpy            ; copy to filename buffer, rf points to dirent
           PUSH rf                  ; rf points to next entry in dirents, so save
        
showfile:  LOAD rf, fname           
           LOAD rd, fildes          ; set file descriptor
           ldi  0                   ; flags for open
           plo  r7
           CALL o_open              ; attempt to open file
           lbdf fskip               ; if can't open, try next file
                               
           LOAD rc, HEADER_SIZE     ; try to read 32 byte header
           LOAD rf, hbuffer         ; buffer to retrieve data
           LOAD rd, fildes          ; set file descriptor
           CALL o_read              ; read the header
           lbdf fdone               ; if error, not a sun raster file
          
           LOAD rf, hbuffer         ; buffer with header data
           LOAD rd, sun_headr       ; load expected header values in rd
           LOAD rc, 18              ; check first 18 bytes in header
           CALL memcmp              ; compare buffers
           lbnz fdone               ; if headers don't match, skip

           LOAD rf, rtype           ; get the raster type byte
           lda  rf                  ; should be 01 or 02
           smi  01h                 ; check for 01 (uncompressed)
           lbz  rt_ok
           smi  01h                 ; check for 02 (rle compression)
           lbz  rt_ok           
           lbr  fdone               ; anything but 01 or 02 is not supported
            
rt_ok:     LOAD rf, mtype           ; get color map type and verify it
           ldn  rf                  ; get the type byte from the header
           smi  02h                 ; validate that it is raw data
           lbnz fdone               ; any type except 02 is invalid
           
           LOAD rf, iname           ; print image name
           CALL o_msg               ; print name without path onscreen
           CALL docrlf              ; one per line

           ; reading and writing bitmap data first reduces flash

           CALL seek_bmp            ; move file pointer to bitmap data
           LOAD rf, bsize           ; get the size of bitmap data
           lda  rf                  ; get hi byte of bit map size
           phi  rc
           ldn  rf                  ; get lo byte of bit map size
           plo  rc             
           CALL read_data           ; read the bitmap data
           lbdf data_err            ; if error reading data, show msg

           ; write bitmap to display
             
           CALL set_group           ; set expander card group for video card
           CALL init_vreg           ; reset display
           CALL clear_vram          ; clear video memory
           LOAD rf, rtype           ; check the type
           ldn  rf                  ; put the type in D 
           smi  01h                 ; 01 means uncompressed
           lbnz rle_bmp             ; 02 means rle compressed           
           CALL send_bmap           ; send bitmap data to video card
           lbr  end_bmp 
rle_bmp:   CALL rle_bmap            ; send rle bitmap data to video card
end_bmp:   CALL reset_group         ; set expander card group back to default

           ; read color map
           
           CALL seek_clr            ; move file pointer to color map data
           LOAD rf, csize           ; get the size of  color map data
           lda  rf                  ; get hi byte of color map size
           phi  rc
           ldn  rf                  ; get lo byte of color map size
           plo  rc
           CALL read_data           ; read the color table data
           lbdf data_err            ; if error, show msg

           LOAD rd, fildes          ; set file descriptor
           CALL o_close             ; close the file

            
           ; update display with color map
           
           CALL set_group           ; set expander card group for video card
           LOAD rf, rtype           ; check the type
           ldn  rf                  ; put the type in D 
           smi  01h                 ; 01 means uncompressed
           lbnz rle_cmp             ; 02 means rle compressed
           CALL send_cmap           ; send color map data
           lbr  end_cmp 
rle_cmp:   CALL rle_cmap            ; send rle color map data to video card
end_cmp:   CALL send_names          ; set color names
           CALL reset_group         ; set expander card group back to default

           ; done updating display, set flag and wait a bit before continuing
           
           LOAD rb, shown           ; point to shown flag
           ldi  0ffh                ; indicate at least one picture was shown
           str  rb                  ; set flag true

           LOAD rc, 5               ; show display for a few seconds
wait:      glo  rc                  ; check outside loop counter
           lbnz cont
           ghi  rc
           lbnz cont                ; keep waiting until exhausted
           lbr  fskip               ; do next image after time out

quit:      POP  rf                  ; if input is pressed, clean up stack
           lbr  complete            ; and exit program
           
cont:      dec  rc
           LOAD rf, 00h             ; set inner counter to max value
spin:      dec  rf
           b4   quit                ; if input pressed, quit waiting and exit  
           glo  rf
           bnz  spin                ; inner loop is about a second
           ghi  rf
           bnz  spin      
           lbr  wait                ; continue to wait before next image
           
           
data_err:  CALL O_INMSG
           db 'Bad image data',10,13,0           
fdone:     LOAD rd, fildes          ; set file descriptor
           CALL o_close             ; close the file
fskip:     POP  rf                  ; restore rf to next pointer  
           lbr  displp              ; loop until all displaye

usage:     LOAD rf, info0           ; show usage information
           CALL o_msg 
           LOAD rf, info1
           CALL o_msg
           LOAD rf, info2
           CALL o_msg
           LOAD rf, info3
           call o_msg
           RTN                      ; exit to Elf/OSs
           
list_done: LOAD rf, mode            ; check mode flag to repeat images
           ldn  rf
           lbz  complete            ; if not repeat mode, just exit
           LOAD rf, shown           ; check if any images to show
           ldn  rf                  
           lbz  complete            ; if no images, just exit
           lbr  display             ; otherwise, display images again
                
complete:  CALL docrlf           
           ldi  0                 
           RTN                      ; return to os

; ************************************************************
; docrlf -- Print a new line on screen
; ************************************************************   
docrlf:    CALL    o_inmsg
           db      10,13,0
           RTN                         ; and return

; ************************************************************
; read_data -- Read 0x1800 bytes of raster data.  
;              Used for the color map and bitmap data.
; Input: 
;   RC = Count of bytes to read (0x1800)
; Internal: 
;   RD = File descriptor
; Output:
;   RF = Pointer to buffer with data
;   DF = 0 Success
;   DF = 1 Error
; ************************************************************

read_data: LOAD rd, fildes          ; put file descripter in rd
           LOAD rf, dbuffer         ; set pointer to data buffer 
           CALL o_read              ; read the header
           lbdf rd_done             ; exit immediately, if read error
rd_done:   RTN

; ************************************************************
; seek_bmp -- Move file pointer to bitmap data  
;
; Input:             
;   R8 = High word of seek address
;   R7 = Low word of seek address
;   RC = Seek from (0 = beginning)
;   RD = File descriptor
; Output:
;   R8 = High word of file pointer
;   R7 = Low word of file pointer
;   DF = 0 Success
;   DF = 1 Error
; ************************************************************
         
seek_bmp:  LOAD rf, csize         ; bitmap is after color map and header data
           lda  rf                ; get the high byte of color map size
           stxd                   ; store on stack
           irx                    ; point x back to data
           lda  rf                ; get the low byte of color map size 
           adi  020h              ; add the header size 
           plo  r7                ; put in seek size lo byte
           ldx                    ; get hi byte of csize from stack
           adci  00h              ; add in the carry flag if needed
           phi r7                 ; put in hi byte of seek size   
           LOAD r8, 00h           ; set the seek offset
           LOAD rc, 00h           ; seek from current
           LOAD rd, fildes        ; set file descriptor
           CALL o_seek
           RTN

; ************************************************************
; seek_clr -- Move file pointer to color map data  
;
; Input:             
;   R8 = High word of seek address
;   R7 = Low word of seek address
;   RC = Seek from (0 = beginning)
;   RD = File descriptor
; Output:
;   R8 = High word of file pointer
;   R7 = Low word of file pointer
;   DF = 0 Success
;   DF = 1 Error
; ************************************************************
       
seek_clr: LOAD r8, 00h              ; set the seek offset
          LOAD r7, COLORMAP_OFFSET  ; color map is after header data
          LOAD rc, 00h              ; seek from beginning
          LOAD rd, fildes           ; set file descriptor
          CALL o_seek
          RTN

; ************************************************************
; memcmp -- Compare two memory arrays
;
; Inputs:
;   RF = pointer to array 1
;   RD = pointer to array 2
;   RC = number of byte to check 
; Output:
;   D = 0 -> arrays equal
;   D = 01 -> array 1 > array 2
;   D = FF -> array 1 < array 2
; ************************************************************
memcmp:   glo  rc          ; check count in RC
          lbnz mc_cont     ; count > 0, continue on
          ghi  rc          ; check count in RC
          lbz  mc_match    ; count = 0, arrays match
mc_cont:  dec  rc          ; check next byte
          lda  rd          ; get next byte in second string
          stxd             ; store into memory
          irx              ; point x back to memory 
          lda  rf          ; get byte from first string
          sm               ; subtract 2nd byte from it (D - MX)
          lbz   memcmp     ; so far a match, keep looking
          lbnf mc_grtr     ; jump if m1 byte is greater than m2
          ldi  0ffh        ; indicate first array is smaller
          lbr  mc_done     ; and return to caller
mc_grtr:  ldi  001h        ; indicate first array is larger
          lbr  mc_done     ; and return to caller
mc_match: ldi  0           ; arrays match
mc_done:  RTN              ; return to caller 


; -------------------------------------------------------------------
;            Set the Expansion Group for Video Card
; -------------------------------------------------------------------
set_group:
      
#ifdef EXP_PORT
        ldi  VDP_GROUP    ; Video card is in group 1 
        str  r2
        out  EXP_PORT     ; Set group on expansion card
        dec  r2
#endif            
        RTN 

; -------------------------------------------------------------------
;            Set the Expansion Group back to default
; -------------------------------------------------------------------
reset_group:  
#ifdef EXP_PORT
        ldi  DEF_GROUP    ; All other cards are in group 0
        str  r2
        out  EXP_PORT     ; Set group on expansion card
        dec  r2
#endif              
        RTN
                            
; -------------------------------------------------------------------
;            Initialize the 8 TMS9118 VDP Registers
; -------------------------------------------------------------------
init_vreg:  mov  rf, vreg_def
            ldi  80h
            plo  r7
next_reg:   lda  rf
            str  r2
            out  VDP_REG_P
            dec  r2
            glo  r7
            str  r2
            out  VDP_REG_P
            dec  r2
            inc  r7
            glo  r7
            smi  88h
            lbnz next_reg
            RTN

; -----------------------------------------------------------
;         Set VDP destination address for sending data
; -----------------------------------------------------------
send_addr:  lda  r6
            phi  rf
            lda  r6
            plo  rf          ; rf has address from linkage
            str  r2
            out  VDP_REG_P   ; send low byte of address
            dec  r2
            ghi  rf
            str  r2
            out  VDP_REG_P   ; and then high byte
            dec  r2
            RTN


; -----------------------------------------------------------
;                     Clear VDP memory
; -----------------------------------------------------------
clear_vram: CALL send_addr
            dw   4000h         ; set VDP write address to 0000h

            mov  r7, 4000h     ; 16k memory
clear_next: ldi  0
            str  r2
            out  VDP_DAT_P     ; VDP performs autoincrement of VRAM address  
            dec  r2
            dec  r7
            glo  r7
            lbnz clear_next
            ghi  r7
            lbnz clear_next
            RTN


; -----------------------------------------------------------
;        Send bitmap data to vram Pattern Table @ 0000h
; -----------------------------------------------------------
send_bmap:  CALL send_addr
            dw   4000h         ; set VDP write address to 0000h

            ; now we copy data to vram 0000h (Pattern table)
            mov  rf, bsize     ; point rf to bitmap size in buffer
            lda  rf            ; get hi byte of size
            phi  r7            ; put in r7
            ldn  rf            ; get lo byte of size
            plo  r7            ; bitmap size is now in r7
            mov  rf, dbuffer   ; point rf to data buffer 6144 bytes
next_byte:  lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz next_byte
            ghi  r7
            lbnz next_byte
            RTN

; -----------------------------------------------------------
;        Send RLE bitmap data to vram Pattern Table @ 0000h
; -----------------------------------------------------------
rle_bmap:   CALL send_addr
            dw   4000h         ; set VDP write address to 0000h

            ; now we copy data to vram 0000h (Pattern table)
            mov rf, bsize     ; point rf to bitmap size in buffer
            lda  rf            ; get hi byte of size
            phi  r7            ; put in r7
            ldn  rf            ; get lo byte of size
            plo  r7            ; bitmap size is in r7
            mov  rf, dbuffer            
next_bdata: lda  rf
            str  r2
            smi  080h          ; check for marker byte
            lbz  b_marker      ; if not a marker just output data byte
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            lbr  chk_bcnt      ; check count
b_marker:   dec  r7            ; adjust count for second byte read
            lda  rf            ; get second byte
            lbnz set_b_rcnt    ; second byte is the repeat count or zero
            ldi  080h          ; if second byte zero, write a literal 0x80 
            str  r2            ; store literal 0x80 in M(X)
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            lbr  chk_bcnt      ; check the data stream count
set_b_rcnt: plo  rc           
            ldi  0h
            phi  rc     
            inc  rc            ; set count + 1 in rc to repeat data n+1 times
            lda  rf            ; get the third byte as the value to repeat
            dec  r7            ; adjust count for third byte
            str  r2            ; put third byte in M(X)
rle_b_rpt:  out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2            ; point X back to data byte
            dec  rc            ; decrement repeat count
            glo  rc            ; check repeat count in rc
            lbnz rle_b_rpt
            ghi  rc
            lbnz rle_b_rpt                          
chk_bcnt:   dec  r7
            glo  r7
            lbnz next_bdata
            ghi  r7
            lbnz next_bdata
            RTN


; -----------------------------------------------------------
;           Copy color data to vram @ 2000h (Color table)
; -----------------------------------------------------------
send_cmap:  CALL send_addr
            dw   6000h         ; set VDP write address to 2000h

            mov rf, csize     ; point rf to bitmap size in buffer
            lda  rf            ; get hi byte of size
            phi  r7            ; put in r7
            ldn  rf            ; get lo byte of size
            plo  r7            ; bitmap size is in r7
            mov  rf, dbuffer   ; point rf to data buffer, 6144 bytes

            ; now copy data            
next_clr:   lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz  next_clr
            ghi  r7
            lbnz  next_clr
            RTN

; -----------------------------------------------------------
;        Copy RLE color data to vram @ 2000h (Color table)
; -----------------------------------------------------------
rle_cmap:   CALL send_addr
            dw   6000h         ; set VDP write address to 2000h

            ; now we copy data to vram 2000h (color map)
            mov  rf, csize     ; point rf to color map size in buffer
            lda  rf            ; get hi byte of size
            phi  r7            ; put in r7
            ldn  rf            ; get lo byte of size
            plo  r7            ; bitmap size is in r7
            mov  rf, dbuffer
            
            ; now copy rle data
            
next_cdata: lda  rf
            str  r2
            smi  080h          ; check for marker byte 0x80
            lbz  c_marker      ; if not a marker just output data byte
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            lbr  chk_c_cnt
c_marker:   dec  r7            ; adjust count for second byte
            lda  rf            ; get second byte
            lbnz set_c_rcnt    ; second byte is the repeat count or zero
            ldi  080h          ; if second byte zero, write a literal 0x80 
            str  r2            ; store literal 0x80 in M(X)
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            lbr  chk_c_cnt     ; check the data stream count
set_c_rcnt: plo  rc            ; second byte is data repeat count           
            ldi  0h            ; clear out high byte of rc
            phi  rc            
            inc  rc            ; set count + 1 in rc
            lda  rf            ; get the third byte as the value to repeat
            dec  r7            ; adjust data count for third byte
            str  r2            ; put data byte in M(X)
rle_c_rpt:  out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2            ; point back to data byte in M(X)
            dec  rc            ; decrement repeat count
            glo  rc            ; check repeat count in rc
            lbnz rle_c_rpt    
            ghi  rc
            lbnz rle_c_rpt                          
chk_c_cnt:  dec  r7
            glo  r7
            lbnz next_cdata
            ghi  r7
            lbnz next_cdata
            RTN
            
; -----------------------------------------------------------
; Set name table entries of vram @ 3800h (Name table)
; -----------------------------------------------------------
send_names: CALL send_addr
            dw   7800h         ; set VDP write address to 3800h

            ; fill with triplet series 0..255, 0..255, 0..255
            mov  r7, 768       ; number of entries to write
            ldi  0             ; starting index
            plo  r8
name_idx:   glo  r8
            str  r2
            out  VDP_DAT_P
            dec  r2
            inc  r8
            dec  r7
            glo  r7
            lbnz name_idx
            ghi  r7
            lbnz name_idx
            RTN

           ; default VDP register settings for graphics II mode
vreg_def:   db  2       ; VR0 graphics 2 mode, no ext video
            db  0C2h    ; VR1 16k vram, display enabled, intr dis; 16x16 sprites
            db  0Eh     ; VR2 Name table address 3800h
            db  0FFh    ; VR3 Color table address 2000h
            db  3       ; VR4 Pattern table address 0000h
            db  76h     ; VR5 Sprite attribute table address 3B00h
            db  3       ; VR6 Sprite pattern table address 1800h
            db  01h     ; Backdrop color blue            

           ; define 32-byte Sun Raster header data fields
sun_headr: db   059h, 0a6h, 06ah, 095h   ; magic number for Sun Raster format
           db   0,    0,    01h,  00h    ; image width = 256 pixels
           db   0,    0,    0,    0C0h   ; image height = 192 pixels
           db   0,    0,    0,    001h   ; image depth = 1 plane 
           db   0,    0,    0            
           db   01h            ; raster data type 1 = no compression
           db   0,    0    
           db   018h, 00h      ; length = 0x1800 or 6614 bytes
           db   0,    0,    0
           db   02h            ; color map type 2 = raw bytes (not rgb)
           db   0,    0
           db   018h, 00h      ; length = 0x1800 or 6614 bytes

mode:      db   0           ; flag to repeast slideshow loop
shown:     db   0           ; flag to indicate at least one picture shown
next:      dw   0           ; where to store dirents pointer
fildes:    db   0,0,0,0
           dw   dta
           db   0,0
           db   0
           db   0,0,0,0
           dw   0,0
           db   0,0,0,0
path:      db   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 
iname:     ds   21
fname:     ds   41

           ; define constants for data in header  
hbuffer:   db   0, 0, 0, 0   ; magic number
           db   0, 0, 0, 0   ; image width
           db   0, 0, 0, 0   ; image height
           db   0, 0, 0, 0   ; image depth
           db   0, 0, 0
rtype:     db   0            ; data type 01 for standard, 02 for rle
           db   0, 0    
bsize:     db   0, 0         ; length = 0x1800 or 6614 bytes
           db   0, 0, 0
mtype:     db   0            ; color map type = 02 for raw bytes (not rgb)
           db   0, 0
csize:     db   0, 0         ; length = 0x1800 or 6614 bytes
buffer:    ds      32
info0:     db 'Show all Sun raster image files in a directory.',10,13,0
info1:     db 'Usage: slideshow [-r][path]',10,13,0
info2:     db '-r = repeat slideshow until input is pressed.',10,13,0
info3:     db 'path = directory for images (default is current directory)',10,13,0
endrom:    equ     $

dta:       ds   512
dbuffer:   ds   01800h       ; should be sufficient to hold rle and uncompressed data
overflow:  ds   512          ; but worse case rle can sometimes expand data slightly
dirents:   db   0            
        
