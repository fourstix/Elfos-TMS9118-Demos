; -------------------------------------------------------------------
;                        textColors
; 
; Program for a TMS9X18 Color Video Card driver and Elf/OS
;
; This program uses the TMS9118 mode 0 for 40x24 text
 -------------------------------------------------------------------
; *** Based on software written by Glenn Jolly
; *** Original author copyright notice:
; Copyright (C) 2021 by Glenn Jolly;
; You have permission to use, modify, copy, and distribute
; this software for non commercial uses.  Please notify me 
; on the COSMAC ELF Group at https://groups.io/g/cosmacelf of any
; improvements and/or corrections.
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

#include    include/bios.inc
#include    include/kernel.inc
#include    include/ops.inc
#include    include/vdp.inc

; need to access charset size 
#include    lib/include/charset.inc

#define cr  13
#define lf  10
            ; declare external procedures in vdp_video library
            extrn  checkVideo
            extrn  clearInfo
            extrn  beginTextMode
            extrn  setTextCharXY
            extrn  writeTextString
            extrn  writeTextData
            extrn  setTextColor
            extrn  resetGroup 
            extrn  setGroup
            extrn  ADD16
            extrn  endTextMode


; Executable program header generated by linker

        org   2000h
textColors: br      main
            
                    ; Build information            
            db      11+80h             ; month
            db      30                 ; day
            dw      2022               ; year
            dw      3                  ; build
            
            db      'Copyright 2022 by Gaston Williams',0
            
main:       call checkVideo     ; verify vdp driver is loaded in memory
            lbdf no_driver
            
            call clearInfo      ; wipe out user Info from G2 Mode

            call FILL_CHARSET   ; fill charset buffer with text
            
            call beginTextMode  ; start text mode
            
            call setTextCharXY
            db   10, 0
            mov  rf, TITLE_STR 
            call writeTextString

            call setTextCharXY
            db   8, 2
            mov  rf, CHAR_STR 
            call writeTextString

            call setTextCharXY
            db   0, 4
            
            call writeTextData
            dw DISP_CHAR
            dw END_DISP_CHAR-START_DISP_CHAR
 
            
            call setTextCharXY
            db   13,19
            mov  rf, C4_STR 
            call writeTextString

            call setTextCharXY
            db   0, 23
            mov  rf, PROMPT_STR 
            call writeTextString

; -------------------------------------------------------------------
;          Display various textcolor settings
; -------------------------------------------------------------------

            mov  rc, TXTCOLORS+4  ; pointer to default white on blue
COLOR_LOOP: ldn  rc               ; put color byte in D              
            call setTextColor 
            call resetGroup     ; set expansion group back to default for Serial card
            mov  rf, 0h
            call f_read         ; f_read puts byte in D
            plo  rf             ; so store in rf.0
            smi  078h
            lbz  QUIT           ; exit if 'x' typed
            call setGroup       ; set expansion group back to video card
            glo  rf
            lbz  NO_NUM

            call isnum          ; DF=1 if numeric ascii '0'..'9'
            lbdf NUM_OK

NO_NUM:     call DELAY100MS
            lbr  COLOR_LOOP
 
NUM_OK:     mov  r7, 0
            glo  rf             ; leave this at rf!
            smi  30h
            plo  rb             ; save number index
            plo  r7
            mov  r8, TXTCOLORS
            call ADD16  
            mov  rc,r7          ; rc points to color scheme F/B byte
            call setTextCharXY
            db   13,19
            
            mov  r7, 0
            glo  rb             ; get index back
            shl                 ; multiply by 16
            shl
            shl
            shl
            plo  r7             ; 16*index
            
            mov  r8, C0_STR 
            call ADD16          ; rd is address of color string message
              
            mov  rf,r7          ; rf <- C0_STR + 16*index

            call writeTextString
            call DELAY100MS
            lbr  COLOR_LOOP

QUIT:       call setGroup       ; set expansion group back to video card
            ldi V_VDP_CLEAR     ; reset the display
            call endTextMode
            rtn                 ; return to monitor


no_driver:  call O_INMSG        ; show error message 
            db 'TMS9X18 Video driver is not loaded.',10,13,0
            rtn                 ; return to Elf/OS

; -------------------------------------------------------------------
; Fill display buffer with selected character set
; -------------------------------------------------------------------
FILL_CHARSET:
            load r7, VDP_CHARSET_SIZE ; chars to write
            load r8, END_DISP_CHAR-1  ; point to last character in display buffer
            sex  r8                   ; set X to r8 to fill backwards
FILL_IT:    dec  r7                   ; move to next character
            ldi  0h                   ; pad display with blanks between chars
            stxd                      ; write character to buffer
            glo  r7
            stxd                      ; write blank and step back
            lbnz FILL_IT              ; continue for all chars until done
            sex  r2                   ; set x back to r2
            rtn
            
; -----------------------------------------------------------
; measured 99.994mS on 4mHz Pico Elf 2  22 June 2021
; -----------------------------------------------------------
DELAY100MS: ldi  01Bh
            phi  r7
            ldi  0C7h
            plo  r7
D100:       dec  r7
            glo  r7
            lbnz D100
            ghi  r7
            lbnz D100
            rtn


; *************************************
; *** Check if character is numeric ***
; *** D - char to check             ***
; *** Returns DF=1 if numeric       ***
; ***         DF=0 if not           ***
; *** from M H Riley BIOS source    ***
; *************************************
isnum:      plo     re       ; save a copy
            smi     '0'      ; check for below zero
            lbnf    fails    ; jump if below
            smi     10       ; see if above
            lbdf    fails    ; fails if so
passes:     smi     0        ; signal success
            lskp
fails:      adi     0        ; signal failure
            glo     re       ; recover character
            rtn              ; and return

TXTCOLORS:  db  0fdh   ; VR7 White text (F) on magenta background (D)
            db  0f6h   ; VR7 White text (F) on dark red background (6)
            db  0f1h   ; VR7 White text (F) on black background (1)
            db  0fch   ; VR7 White text (F) on dark green background (C)
            db  0f4h   ; VR7 White text (F) on blue background (4)
            db  01fh   ; VR7 Black text (1) on white background (F)
            db  012h   ; VR7 Black text (1) on green background (2)
            db  017h   ; VR7 Black text (1) on cyan background (7)
            db  01dh   ; VR7 Black text (1) on magenta background (D)
            db  019h   ; VR7 Black text (F) on lt red background (9)

            ; lesser quality combinations
            ;db  074h   ; VR7 Cyan text (1) on blue background (4)
            ;db  04fh   ; VR7 Blue text (4) on white background (F)
            ;db  0a6h   ; VR7 Yellow text (A) on dark red (6)
            ;db  0a1h   ; VR7 Yellow text (A) on black background (1)
            ;db  0a4h   ; VR7 Yellow text (A) on blue background (4) **very poor**

TITLE_STR:  db 'TMS9118 Text Mode', 0       ; 17 chars

#ifdef TI99_FONT
CHAR_STR:   db 'TI99/4a Character Set:', 0  ; 22 chars
#else
CHAR_STR:   db 'CP437 Character Set:', 0    ; 20 chars
#endif


PROMPT_STR: db 'Type 0..9 to change color - x to exit', 0 ; 37 chars

C0_STR:     db 'White / Magenta', 0       ; 16 chars including null
C1_STR:     db 'White / Red    ', 0
C2_STR:     db 'White / Black  ', 0
C3_STR:     db 'White / Dk Grn ', 0
C4_STR:     db 'White / Blue   ', 0
C5_STR:     db 'Black / White  ', 0
C6_STR:     db 'Black / Green  ', 0
C7_STR:     db 'Black / Cyan   ', 0
C8_STR:     db 'Black / Magenta', 0
C9_STR:     db 'Black / Lt Red ', 0

; character display size is 2*sizeof(charset) because of spaces
START_DISP_CHAR:
DISP_CHAR: ds VDP_CHARSET_SIZE*2 ; 
END_DISP_CHAR:
    end textColors
