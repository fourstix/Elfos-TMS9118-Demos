; -------------------------------------------------------------------
;                        ansi
;
; Basic TTY ANSI write demo for the TMS9X18-Library
;
;      https://github.com/dmadole/1802-Mini
;
; This program uses the TMS9118 graphics mode 2 for 'bitmap' display
; -------------------------------------------------------------------
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
;
;             TMS9118 / TMS9918
;            Graphics 2 memory map
;            +-----------------+ 0000h
;            |  Pattern Table  |
;            |   6144 bytes    |
;            +-----------------+ 1800h
;            | Sprite Patterns |
;            |    512 bytes    |
;            +-----------------+ 2000h
;            |   Color Table   |
;            |   6144 bytes    |
;            +-----------------+ 3800h 
;            |    Name Table   |
;            |    768 bytes    |
;            +-----------------+ 3B00h 
;            |Sprite Attributes|
;            |    256 bytes    |
;            +-----------------+ 3C00h 
;            |     Unused      |
;            +-----------------+ 3FFFh 
;
; -------------------------------------------------------------------
;
;                         TMS9118 Colors
;            +---+--------------+---+--------------+ 
;            | 0 | Transparent  | 8	|     Red      |
;            +---+--------------+---+--------------+ 
;            | 1 |   	Black     | 9	|  Light Red   |
;            +---+--------------+---+--------------+ 
;            | 2 |    Green     | A	|    Yellow    |
;            +---+--------------+---+--------------+ 
;            | 3 | Light Green  | B | Light Yellow |
;            +---+--------------+---+--------------+ 
;            | 4 |	   Blue     | C |  Dark Green  |
;            +---+--------------+---+--------------+
;            | 5 |	Light Blue  | D |   Magenta    |
;            +---+------------- +---+--------------+
;            | 6 |   Dark Red   | E |     Gray     |
;            +---+--------------+---+--------------+
;            | 7 |     Cyan     | F |	    White    |
;            +---+--------------+---+--------------+
;
; -------------------------------------------------------------------
;           Foreground ANSI Colors Mapped to TMS9118 Colors
;                     Dim (Normal)      Intense (Bright)  
;            +----+------------------+-------------------+ 
;            | 30 |     Black (1)    |      Gray (E)     |
;            +----+------------------+-------------------+ 
;            | 31 |   Dark Red (6)   |    Light Red (9)  |
;            +----+------------------+-------------------+
;            | 32 |  Dark Green (C)  |     Green (2)     |
;            +----+------------------+-------------------+
;            | 33 |    Yellow (A)    | Light Yellow  (B) |
;            +----+------------------+-------------------+ 
;            | 34 |     Blue (4)     |   Light Blue (5)  |
;            +----+------------------+-------------------+ 
;            | 35 |    Magenta (D)   |       Red (8)     |
;            +----+------------------+-------------------+ 
;            | 36 |     Cyan (7)     |  Light Green (3)  |
;            +----+------------------+-------------------+ 
;            | 37 |     Gray (E)     |      White (F)    |
;            +----+------------------+-------------------+
;     Note:  Default Foreground Color is ^[1;37m (Intense White), but Gray (E) 
;            is mapped to both ^[1;30m (Intense Black) and  ^[37m (Dim White).
;            Reverse map foreground color Gray (E) to ^[37m (Dim White) 
; -------------------------------------------------------------------
;           Background ANSI Colors Mapped to TMS9118 Colors
;                     Dim (Normal)      Intense (Bright)  
;            +----+------------------+-------------------+ 
;            | 40 |     Black (1)    |      Gray (E)     |
;            +----+------------------+-------------------+ 
;            | 41 |   Dark Red (6)   |    Light Red (9)  |
;            +----+------------------+-------------------+
;            | 42 |  Dark Green (C)  |     Green (2)     |
;            +----+------------------+-------------------+
;            | 43 |    Yellow (A)    | Light Yellow  (B) |
;            +----+------------------+-------------------+ 
;            | 44 |     Blue (4)     |   Light Blue (5)  |
;            +----+------------------+-------------------+ 
;            | 45 |    Magenta (D)   |       Red (8)     |
;            +----+------------------+-------------------+ 
;            | 46 |     Cyan (7)     |  Light Green (3)  |
;            +----+------------------+-------------------+ 
;            | 47 |     Gray (E)     |      White (F)    |
;            +----+------------------+-------------------+
;     Note:  Default Background Color is ^[40m (Black), but: Gray (E) is mapped
;            to both ^[1;40m (Intense Black) and ^[47m (Dim White). Reverse map
;            background color Gray (E) to ^[1;40m (Intense Black).  
; -------------------------------------------------------------------


#include    include/bios.inc
#include    include/kernel.inc
#include    include/ops.inc
#include    include/vdp.inc
    
            extrn checkVideo
            extrn getInfo
            extrn setInfo
            extrn beginG2Mode
            extrn updateG2Mode
            extrn endG2Mode
            extrn setBackground
            extrn sendNames
            extrn getG2CharXY
            extrn setG2CharXY
            extrn blankG2Line
            extrn blankG2Screen
            extrn drawG2ColorChar
            extrn setColor
            extrn resetColor
            extrn invertColor
            extrn ADD16



          ; Executable program header generated by linker

            org     2000h
ansi:       br      main
                      
                      
                              ; Build information
                      
            db      11+80h             ; month
            db      30                 ; day
            dw      2022               ; year
            dw      3                 ; build
                      
            db      'Copyright 2022 by Gaston Williams',0
                      
          



main:       lda   ra            ; move past any spaces
            smi   ' '
            bz    main
            dec   ra            ; move back to non-space character
            ldn   ra            ; check for nonzero byte
            bnz   good          ; jump if non-zero
            LOAD  rf, usage     ; display usage message
            CALL  o_msg         ; otherwise display
            RETURN              ; return to Elf/OS
                              
good:       COPY  ra, rf        ; copy RA to RF
            LOAD  rc, 0h        ; clear RC for characters
            
            call checkVideo     ; verify vdp driver is loaded in memory
            lbdf no_driver

            call getInfo        ; check to see if g2 char mode ready
            ghi  r8             ; hi byte of r8 should be default color (f1h)
            smi  0f1h           ; check for default color
            lbz  g2ready
            
            ldi  V_VDP_CLEAR    ; if not loaded, clear memory & start G2 Mode
            call beginG2Mode    ; set up Expansion group and vdp hardware
            ldi  0f1h           ; white text on black background as default
            call setBackground                        
            call sendNames

            LOAD r7, 0000h      ; set up xy location and color info
            LOAD r8, 0f1f1h     ; set up color information
            call setInfo 
            lbr  chkChar        ; ready to go
            
             
g2ready:    ldi  V_VDP_KEEP       ; restart graphics mode 2 without clearing
            call beginG2Mode      ; set the Expansion Group, if needed             
            call set_idx          ; set ANSI color indexes from current color byte
          

chkChar:    ldn  rf               ; check to see if end of string            
            lbz  done             ; if null, update display and exit   
            call getG2CharXY      ; get the co-ords from char to graphics address
            ;--- r9 has (y,x) check for beginning of line (X = 0)
            ; if beginning of line, clear pattern for 256 (32 x 8) bytes
            glo r9
            lbnz draw             ; if not on column 0, line is already cleared
            call blankG2Line      ; blank out next line
                        
draw:       lda  rf               ; get character
            plo  rc               ; save in rc.0
            smi  '\'              ; check for escape
            lbnz not_esc
            call escape           ; process escape sequence
not_esc:    call draw_it          ; process the characters
            lbr  chkChar          ; repeat until null
            

done:       call updateG2Mode     ; force refresh of display
                             
            ldi  V_VDP_KEEP       ; set Expansion Group back to default
            call endG2Mode
            rtn

; -------------------------------------------------------------------
; Process a character in a string
; Inputs:  RF - pointer to string
;          RC.0 - character to process
;          RC.1 - previous character
;          
; Outputs: RC.1 - previous character with character processed 
; -------------------------------------------------------------------
draw_it:    ghi  rc               ; check previous character for escape
            smi  010h             ; previous DLE means set color with byte
            lbz do_dle
            
            smi 0Bh               ; check for ANSI escape (0x1B) char            
            lbnz draw_char        ; anything else was not an escape

            ldi  0h               ; erase previous character (0x1B)
            phi  rc               
            glo  rc               ; get the current character
            smi  '['              ; check for control sequence introducer  
            lbz  ansi_seq         ; if CSI we have a valid ansi sequence
            call bad_ansi         ; otherwise invalid ansi escape sequence
            lbr  drawn

ansi_seq:   call  do_ansi         ; process the escape sequence
            lbr  drawn

                        
do_dle:     call set_clr          ; set color with this byte value 
            lbr  drawn 

            ; process a control or printable character  
draw_char:  glo  rc               ; get character
            smi  ' '              ; anything less than space is control char
            lbdf draw_print       ; space or higher is printable
            call do_ctrl          ; process control character  
            lbr  drawn
                          
draw_print: glo  rc 
            phi  rc               ; update previous character
            call drawG2ColorChar  ; get char from rf and draw it
            
drawn:      rtn

; -------------------------------------------------------------------
; Process a control character
; Inputs:  RF - pointer to string
;          RC.0 - character to process
;          RC.1 - previous character
;          
; Outputs: RC.1 - updates previous character (may be cleared)
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------
do_ctrl:    glo  rc
            smi  07h
            lbnf ctrl_done    ; ignore everything less than 0x07  
            lbz  do_bel       ; 0x07 is BEL (invert color)
            smi  01h 
            lbz  do_bs        ; 0x08 is BS (backspace)
            smi  01h
            lbz  do_tab       ; 0x09 is TAB (horizontal tab)
            smi  01h           
            lbz  do_lf        ; 0x0A is LF (newline)
            smi  01h          
            lbz  do_vt        ; 0x0B is VT (vertical tab)
            smi  01h          
            lbz  do_ff        ; 0x0C is FF (clear screen)        
            smi  01h      
            lbz  do_cr        ; 0x0D is CR (newline) 
            smi  01h          
            lbz  do_so        ; 0x0E is SO (bold color)
            smi  01h          
            lbz  do_si        ; 0x0F is SI (default color)
            lbr  ctrl_done    ; ignore all other control characters
              
do_bel:     call invertColor  
            lbr  ctrl_done

do_bs:      call move_left    ; move back to previous cursor postion
            ldi  ' '          ; wipe out chracter
            call drawG2ColorChar  
            call move_left    ; move back to overwrite previous character
            lbr  ctrl_done

do_tab:     call getG2CharXY  ; get XY value in R9
            glo  r9           ; get X value
            adi  04h          ; advance X four spaces
            ani  03Ch         ; mask off last two bits (round down to 4)
            plo  r9
            ani  020h         ; check for overflow past end of line
            lbz  tab_ok
            ldi  01Fh         ; set last tab at end of line
            plo  r9            
tab_ok:     call setG2CharXY  ; update the index value
            lbr  ctrl_done
                      
do_lf:      ghi  rc           ; check previous character
            smi  0Dh          ; ignore \r\n sequences
            lbnz lf_ok          
            ldi  0h           ; clear previous character
            phi  rc           ; so next \n or \r is processed
            lbr  ctrl_exit
lf_ok:      call newline  
            lbr  ctrl_done

do_vt:      call move_down      ; move down 2 lines
            call move_down
            lbr  ctrl_done

do_ff:      call resetColor     ; set to default color
            call blankG2Screen  ; clear out the screen
            lbr  ctrl_done
            
do_cr:      ghi  rc           ; check previous character
            smi  0Ah          ; ignore \n\r sequences
            lbnz cr_ok          
            ldi  0h           ; clear previous character
            phi  rc           ; so next \n or \r is processed
            lbr  ctrl_exit
cr_ok:      call newline  
            lbr  ctrl_done      
                              ; Change SO to do ANSI color shift  
do_so:      call shift_idx    ; Shift ANSI color indexes
            call get_color    ; get the color byte from ANSI indexes
            call setColor     ; update color byte in memory
            lbr  ctrl_done  
            
do_si:      call getInfo    ; get R7 and R8
            ghi  r8         ; get default color byte
            plo  r8         ; set current color byte to default
            call setInfo    ; save new R7 and R8 values

ctrl_done:  glo  rc         ; update previous character and return
            phi  rc
ctrl_exit:  rtn             

; -------------------------------------------------------------------
; Set color from a byte value in string
; Inputs:  RF - pointer to string
;          RC.0 - byte value
;          RC.1 - previous character
;          
; Outputs: RC.1 - previous character is cleared 
; -------------------------------------------------------------------
set_clr:    call getInfo  ; set R7 and R8      
            glo  rc       ; get new color byte
            ani  0F0h     ; get new foreground color
            lbz  no_fg    ; 0 (transparent) means no change
            str  r2       ; put new fg value in M(X)
            lbr  do_bg   ; now do background color
no_fg:      glo  r8       ; get current color byte
            ani  0F0h     ; get current fg color
            str  r2       ; put current fg value in M(X)
do_bg:      glo  rc       ; get new color byte
            ani  0Fh      ; get new background color (in D)
            lbz  no_bg    ; 0 (transparent) means no change
            lbr  set_new  ; jump to set new color
no_bg:      glo  r8       ; get current color byte           
            ani  0Fh      ; get current bg color (in D)              
set_new:    or            ; or D with M(x) to create new color byte
            plo  r8       ; put new color byte in r8
            call setInfo  ; update color byte in memory
            ldi  0h       ; we are done so clear previous character
            phi  rc       ; so no match on next control character
            rtn

; -------------------------------------------------------------------
; Advance cursor to next line
; Inputs:            
; Outputs: 
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------            
newline:    call getG2CharXY  ; get XY value in R9
            ldi  0h
            plo  r9           ; set X = 0
            ghi  r9           ; get y value
            adi  01h          ; add one
            phi  r9           ; save in r9
            smi  018h         ; check for overflow (line 24)
            lbnz nl_done
            ldi  0h
            phi  r9           ; set y=0 to go top line
nl_done:    call setG2CharXY  ; update XY values
            rtn
            
; -------------------------------------------------------------------
; Move cursor back one character position
; Inputs:            
; Outputs: 
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------            
move_left:  call getG2CharXY  ; get XY in R9
            glo  r9           ; get the X position
            lbz  ml_y         ; if x=0 adjust y to move back to previous line
            smi  01h          ; move x back one position
            plo  r9           
            lbr  ml_save      
ml_y:       ghi  r9           ; get y location
            lbz  ml_done      ; if x=0, y=0 just return
            smi  01h          ; back up one line
            phi  r9           ; y = y-1
            ldi  1fh          ; x = 31
            plo  r9
ml_save:    call setG2CharXY  ; set the new position            
ml_done:    rtn

; -------------------------------------------------------------------
; Move cursor back one character position
; Inputs:            
; Outputs: 
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------            
move_right: call getG2CharXY  ; get XY in R9
            glo  r9           ; get the X position
            adi  01h          ; move x forward one position
            plo  r9           ; save x = x+1
            smi  32           ; check if we advanced beyond end of line           
            lbnz mr_save      ; if not just save updated x (y is unchanged)
            ghi  r9           ; get y location
            adi  01h          ; advance one line
            phi  r9           ; save y update (y = y+1)
            smi  24           ; check if past end of screen (y=24)
            lbz  mr_done      ; if x=32, y=24, just return (stay at end of screen)
            ldi  0h           ; set x = 0 (y = y+1)
            plo  r9
mr_save:    call setG2CharXY  ; set the new position            
mr_done:    rtn
          
; -------------------------------------------------------------------
; Advance cursor down one position
; Inputs:            
; Outputs: 
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------            
move_down:  call getG2CharXY  ; get XY value in R9
            ghi  r9           ; get y value
            adi  01h          ; add one
            phi  r9           ; save y in r9 (x is unchanged)
            smi  018h         ; check for overflow (line 24)
            lbz md_done       ; don't save, to stay on bottom line      
            call setG2CharXY  ; update XY values
md_done:    rtn

; -------------------------------------------------------------------
; Back cursor up one line
; Inputs:            
; Outputs: 
;
; Uses:    R7, R8 and R9 used internally
; -------------------------------------------------------------------            
move_up:    call getG2CharXY  ; get XY value in R9
            ghi  r9           ; get y value
            lbz  mu_done      ; If on first line (y = 0), just exit
            smi  01h          ; sumbract one
            phi  r9           ; save y in r9 (x is unchanged)
            call setG2CharXY  ; update XY values
mu_done:    rtn
            
; -------------------------------------------------------------------
; Process escape sequence in string
; Inputs:  RF - pointer to string
;          
; Outputs: RC.0 byte value from escape sequence
;
; Uses:    RD - pointer to hex char buffer for \xhh sequence 
; -------------------------------------------------------------------
            
escape:     lda  rf               ; get next character in escape sequence
            plo  rc               ; put in rc.0
            smi  '\'              ; check for literal slash
            lbnf unknown          ; if negative then unknown
            lbz  escaped          ; backslash is already in rc.0
            
            smi  05h              ; check for \a 
            lbnf unknown          ; if negative then unknown
            lbnz bs_chk           ; if not, check for next escape sequence
            ldi  07h              ; BEL control character (invert color)
            plo  rc               ; update rc.0 with control character
            lbr  escaped
                 
bs_chk:     smi  01h              ; check for \b
            lbnz dle_chk  
            ldi  08h              ; BS control character (backspace)
            plo  rc
            lbr  escaped
            
dle_chk:    smi  01h              ; check for \c
            lbnz si_chk           ; if not, check for next escape sequence
            ldi  010h             ; DLE control character (set color)
            plo  rc
            lbr  escaped

si_chk:     smi  01h              ; check for \d
            lbnz esc_chk          ; if not, check for next escape sequence
            ldi  0Fh              ; SI control character (default color)
            plo  rc
            lbr  escaped

esc_chk:    smi  01h              ; check for \e
            lbnz ff_chk           ; if not, check for next escape sequence
            ldi  01Bh             ; ESC control character (escape)
            plo  rc
            lbr  escaped

ff_chk:     smi  01h              ; check for \f
            lbnz so_chk           ; if not, check for next escape sequence
            ldi  0Ch              ; FF control character (clear screen)
            plo  rc
            lbr  escaped

so_chk:     smi  01h              ; check for \g
            lbnz nl_chk           ; if not, check for next escape sequence
            ldi  0Eh              ; SO control character (bold)
            plo  rc
            lbr  escaped

nl_chk:     smi  07h              ; check for \n
            lbnf unknown          ; if negative then unknown
            lbnz cr_chk           ; if not, check for next escape sequence
            ldi  0Ah              ; NL control character (newline)
            plo  rc
            lbr  escaped
            
cr_chk:     smi  04h              ; check for \r
            lbnf unknown          ; if negative then unknown
            lbnz tab_chk          ; if not, check for next escape sequence
            ldi  0Dh              ; CR control character (carriage return)
            plo  rc
            lbr  escaped
                        
tab_chk:    smi  02h              ; check for \t         
            lbnf unknown          ; if negative then unknown
            lbnz vt_chk           ; if not, check for next escape sequence
            ldi  09h              ; TAB control character (horizontal tab)
            plo  rc
            lbr  escaped
            
vt_chk:     smi  02h              ; check for \v        
            lbnf unknown          ; if negative then unknown
            lbnz hex_chk          ; if not, check for last escape sequence
            ldi  0Bh              ; VT control character (vertical tab)
            plo  rc
            lbr  escaped
            
hex_chk:    smi  02h              ; check for \x (hexadecimal byte value)         
            lbnf unknown          ; if negative then unknown escape sequence
            lbnz unknown          ; anything other than x is also unknown
            LOAD rd, hex_buffer   ; point rd to hex_bufffer
            ldn  rf               ; check for ascii hex digit after escape
            call f_ishex          ; bios to verify hex digit
            lbnf unknown          ; DF=0, means non-hex after \x (invalid)
            lda  rf               ; get hex character  
            str  rd               ; put in buffer 
            inc  rd               ; move buffer ptr to next position
            ldn  rf               ; peek at second character
            call f_ishex          ; bios to verify hex digit
            lbnf parse            ; DF=0, means non-hex char after single hex digit
            lda  rf               ; get hex character  
            str  rd               ; put in buffer 
            inc  rd               ; move buffer ptr to next position
parse:      ldi  0h               ; make sure buffer ends in null  
            str  rd               ; put null at end of buffer
            push rf               ; save rf before calling bios
            LOAD rf, hex_buffer   ; point rf to hex digits in buffer
            call f_hexin          ; rd has hexadecimal byte value on return
            glo  rd               ; get byte value
            plo  rc               ; put in rc.0
            pop  rf               ; restore rf
            lbr  escaped
          
unknown:    ldi  '?'              ; set char to '?'
            plo  rc               ; unknown escape sequence
            dec  rf               ; back up to last character
escaped:    rtn
            

; -------------------------------------------------------------------
; Set the ANSI indexes to values based on the color byte
; Inputs:            
; Outputs: 
;
; Uses:   R7, R8 - scratch registers 
;         RC.0 - color byte value
;         RD - pointer to ANSI index values 
; -------------------------------------------------------------------

set_idx:    LOAD rd, fg_idx     ; point RD to fg_idx
            call getInfo        ; get color data in R8
            glo  r8             ; get the color byte and save in RC.
            plo  rc             ; save in rc.0
            shr                 ; shift 4 times to get foreground color
            shr 
            shr 
            shr                 ; foreground color now in lowest 4 bits
            plo  r8             ; put forground color into r8.0
            ldi  0h             ; clear r8.1
            phi  r8             ; r8 has offset for foreground color
            LOAD r7, fg_map     ; r7 points to foreground map
            call ADD16          ; r7 = r7 + r8 (fg_map + offset)
            ldn  r7             ; get ansi foreground color index
            str  rd             ; save as fg_idx
            inc  rd             ; advance pointer to bg_idx
              
            glo  rc             ; get color byte
            ani  0Fh            ; mask off the lower bits to get the background color
            plo  r8
            ldi  0h             ; clear r8.1
            phi  r8             ; r8 has offset for background color
            LOAD r7, bg_map     ; r7 points to background map
            call ADD16          ; r7 = r7 + r8 (bg_map + offset)
            ldn  r7             ; get ansi background color index           
            str  rd             ; save as bg_idx
            rtn

; -------------------------------------------------------------------
; Reset the ANSI indexes to their default values (white on black)
; Also clears the color intensity flag
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------

reset_idx:  LOAD rd, intense
            ldi  00h            ; clear intensity flag 
            str  rd     
            inc  rd             ; advance to fg_idx
            ldi  0fh            ; set foreground index to intense white (0f) 
            str  rd
            inc  rd             ; advance to bg_idx
            ldi  00h            ; set background index to black (00)
            str  rd
            rtn

; -------------------------------------------------------------------
; Swap the ANSI indexes to invert the color text
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------            
swap_idx:   LOAD rd, fg_idx
            lda  rd               ; get foreground index, advance to bg_idx
            str  r2               ; save in M(X)
            ldn  rd               ; get background index
            dec  rd               ; back up to foreground index
            str  rd               ; save old bg_idx as new fg_idx
            inc  rd               ; advance to background index
            ldx                   ; get old fg_idx from M(X)
            str  rd               ; save old fg_idx as new bg_idx
            rtn
            
; -------------------------------------------------------------------
; Blink the ANSI colors by shifting the color by toggling 
; bit 2 in the foreground index and background indexes, and then
; swapping them.
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------            
blink_idx:  LOAD rd, fg_idx
            lda  rd               ; get foreground index, advance to background 
            xri  04h              ; toggle bit 4 to change color
            str  r2               ; save modified fg_idx in M(X)
            ldn  rd               ; get background index
            xri  04h              ; toggle bit 4 to change color
            dec  rd               ; back up to foreground index location
            str  rd               ; save modified bg_idx as new fg_idx
            inc  rd               ; advance to background index
            ldx                   ; get modified fg_idx from M(X)
            str  rd               ; save modified fg_idx as new bg_idx
            rtn

; -------------------------------------------------------------------
; Shift the ANSI colors by toggling bit 2 in the foreground index
; and background indexes.
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------            
shift_idx:  LOAD rd, fg_idx
            ldn  rd               ; get foreground index 
            xri  04h              ; toggle bit 4 to change color
            str  rd               ; save modified fg_idx
            inc  rd               ; advance to background index
            ldn  rd               ; get background index
            xri  04h              ; toggle bit 4 to change color
            str  rd               ; save modified bg_idx
            rtn

; -------------------------------------------------------------------
; Set the ANSI foreground index to its dim color value (Intensity off)
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------
dim_fg:     LOAD rd, fg_idx
            ldn  rd           ; get the foreground index
            ani  07h          ; clear intensity bit 
            str  rd           ; put back in foreground index
            rtn

; -------------------------------------------------------------------
; Set the ANSI foreground index to its intense color value (Intensity on)
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------
intense_fg: LOAD rd, fg_idx
            ldn  rd           ; get the foreground index
            ori  08h          ; set intensity bit 
            str  rd           ; put back in foreground index
            rtn

; -------------------------------------------------------------------
; Set the ANSI background index to its intense color value
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------
intense_bg: LOAD rd, bg_idx
            ldn  rd           ; get the foreground index
            ori  08h          ; set intensity bit 
            str  rd           ; put back in foreground index
            rtn

; -------------------------------------------------------------------
; Set the intense color flag
; Inputs:  D - value to set          
; Outputs: 
;
; Uses:    RD - pointer to intensity flag  
; -------------------------------------------------------------------
set_intense:  str  r2           ; save D at M(X)              
              LOAD rd, intense
              ldx               ; get D from M(X)
              str  rd           ; set intensity flag to D
              rtn

; -------------------------------------------------------------------
; Get the intense color flag
; Inputs:            
; Outputs: D - value to set
;
; Uses:    RD - pointer to intensity flag  
; -------------------------------------------------------------------
get_intense:  LOAD rd, intense
              ldn  rd           ; put intensity flag in D
              rtn

; -------------------------------------------------------------------
; Get the ANSI color value from the ANSI color array.
;
; Inputs:  RD - pointer to ANSI index values 
; Outputs: D - color value (0n) from ANSI color array
;
; Uses:    R7 - pointer to ANSI color array
;          R8 - offset value into array
; Notes:   RD - is advanced to next index value  
; -------------------------------------------------------------------                        
ansi_color: LOAD r7, ansi_colors  ; point r7 to ansi color byte array
            ldi  0h               ; set up r8 with offset
            phi  r8
            lda  rd               ; get the fg_idx value
            plo  r8               ; put offset in r8
            call ADD16            ; r7 = ansi_colors + offset
            ldn  r7               ; get the color byte (0n)
            rtn
            
; -------------------------------------------------------------------
; Get the TMS9x18 color byte indicated by the ANSI color indexes.
; Inputs:            
; Outputs: D - color byte calculated from fg_idx and bg_indx
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------                        
get_color:  LOAD rd, fg_idx       ; point rd to foreground index
            call ansi_color       ; get the foreground color in D  
            shl                   ; convert to foreground byte (n0)
            shl                   ; by shifting value up to hi nibble
            shl
            shl
            stxd                  ; save foreground color value on stack                     
            call ansi_color       ; background color is in D
            irx                   ; back up stack so M(X) is foreground color
            or                    ; combine foreground and background values
            rtn                   ; return with byte value in D
                
; -------------------------------------------------------------------
; Set the ANSI foreground index 
; Inputs:            
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------
set_fg:     str  r2           ; Save D in M(X)
            LOAD rd, fg_idx
            ldx               ; get value from M(X) 
            str  rd           ; put value in foreground index
            rtn


; -------------------------------------------------------------------
; Set the ANSI background index 
; Inputs:  D - value to set          
; Outputs: 
;
; Uses:    RD - pointer to ANSI index values 
; -------------------------------------------------------------------
set_bg:     str  r2           ; Save D in M(X)
            LOAD rd, bg_idx
            ldx               ; get value from M(X) 
            str  rd           ; put value in background index
            rtn

            ; inital state - parse
do_ansi:    ldn rf            ; peak to see if we have an ; or m with no number
            smi ';'           ; check for semicolon without numeric code
            lbz ansi_def      ; default is reset for ';' or 'm' with numeric no code
            smi 50            ; m is 50 characters after semicolon
            lbnz ansi_parse   ; anything else, parse as normal
ansi_def:   lbr ansi_0        ; treat as ^[0; or ^[0m
            
ansi_parse: lda rf            ; get next character in string
            smi '0'           ; ^[0 reset logic
            lbz  ansi_0
            smi  01h          ; ^[1 intense color
            lbz  ansi_1     
            smi  01h          ; ^[2m dim color or clear screen (^[2J)
            lbz  ansi_2
            smi  01h          ; ^[30 to ^[37 indicates foreground color
            lbz  ansi_3
            smi  01h          ; ^[40 to ^[47 indicates background color
            lbz  ansi_4
            smi  01h          ; ^[5m blink (toggle foreground intensity, swap)
            lbz  ansi_5
            smi  01h          ; ^[6 not supported (slow blink)
            lbz  ansi_err
            smi  01h          ; ^[7m reverse colors (swap foreground and background)
            lbz  ansi_7
            
            ; anything else is an error so signal a problem and quit                    
ansi_err:   call bad_ansi     ; signal a parsing error
            lbr  ansi_done    ; stop parsing
   
            ; set foreground and background indexes to defaults
ansi_0:     call reset_idx    ; reset the color indexes
            lbr  ansi_end     ; process end of ansi sequence
          
            ; set intensity on
ansi_1:     ldi  0FFh         ; set intensity flag to true 
            call set_intense  ; for the next color state
            lbr  ansi_end     ; process end of ansi sequence   

            ; check for J (clear screen) or set foreground index dim
ansi_2:     ldn rf            ; peak at next character to check for clear screen
            smi 'J'           
            lbz clear_2       ; ^[2J clears the screen

dim_2:      ldi  00h          ; clear the intensity flag
            call set_intense
            call dim_fg       ; dim the foreground color
            lbr  ansi_end     ; process end of ansi sequence
            
clear_2:    call reset_idx      ; reset the color indexes
            call resetColor     ; set to display to default color
            call blankG2Screen  ; clear out the screen
            inc  rf             ; skip over J that ends ansi command
            lbr  ansi_done      ; exit ansi processing

            ; Refactor index code into common routine
            ; Set foreground color based on next character 0-7
ansi_3:     lda  rf           ; consume next character (0 to 7)
            smi  '0'          ; get index
            lbnf ansi_err     ; DF = 0, negative means chars before 0 (error) 
            str  r2           ; save index at M(X)
            sdi  07h          ; only 0 to 7 is valid
            lbnf ansi_err     ; DF = 0, negative means chars after 7, like 8 or 9 (error)
            ldx               ; get index from M(X)
            call set_fg       ; save in foreground
            call get_intense  ; get the intensity flag
            lbz  ansi_end     ; if no intensity, we're done
            call intense_fg   ; set intense color in foreground
            ldi  0
            call set_intense  ; clear intensity flag after use
            lbr  ansi_end     ; process end of ansi sequence
            
            ; Refactor index code into common routine
            ; Set background color based on next character 0-7
ansi_4:     lda  rf           ; consume next character (0 to 7)
            smi  '0'          ; get index
            lbnf ansi_err     ; DF = 0, negative means chars before 0 (error) 
            str  r2           ; save index at M(X)
            sdi  07h          ; only 0 to 7 is valid
            lbnf ansi_err     ; DF = 0, negative means chars after 7, like 8 or 9 (error)
            ldx               ; get index from M(X)
            call set_bg       ; save in foreground
            call get_intense  ; get the intensity flag
            lbz  ansi_end     ; if no intensity, we're done
            call intense_bg   ; set intense color in foreground
            ldi  0
            call set_intense  ; clear intensity flag after use
            lbr ansi_end      ; process end of ansi sequence

            ; ^[5m is blink (toggle intensity of fg, swap fg and bg)
ansi_5:     call blink_idx    
            lbr  ansi_end     ; process end of ansi sequence

            ; ^[6m is not supported, so no ansi_6 condition
            
            ; ^[7m is inverse text (swap fg and bg)
ansi_7:     call swap_idx    
            ; lbr ansi_end
            ; falls through to ansi_end    

            ; process the end of an ansi sequnce
            ; 'm' updates colors and exits or ';' to continue parsing next sequence
ansi_end:   lda  rf           ; consume next character after ansi sequence
            smi ';'           ; semicolon continues the parsing
            lbz  do_ansi      ; go back to continue with next sequence
            smi 50            ; 'm' is 50 characters after semicolon
            lbz  ansi_m       ; 'm' ends the ansi command
            lbr ansi_err      ; anything but 'm' or ';' is a bad ansi sequence
              
            ; m at the end sets the color to values from previous ansi sequences
ansi_m:     call get_intense  ; check intense flag set previously
            lbz  ansi_set
            call intense_fg   ; make current foreground color intense
            ldi  0h           ; clear intensity flag
            call set_intense      
ansi_set:   call get_color    ; get the color byte from indexes
            call setColor     ; update color byte in memory
            ; and we are done!            
ansi_done:  rtn

; -------------------------------------------------------------------
; Print an ANSI sequence error message "^[?"
;
; Inputs:  
; Outputs: RF - points to invalid character that terminated ANSI seqence
; -------------------------------------------------------------------
bad_ansi:   dec  rf               ; back up to invalid chracter
            ldi  '^'              ; print unknown ansi escape string
            call drawG2ColorChar
            ldi  '['              
            call drawG2ColorChar            
            ldi  '?'
            call drawG2ColorChar
            rtn

no_driver:  call O_INMSG
            db 'TMS9X18 Video driver v1.3 is not loaded.',10,13,0
            rtn            

hex_buffer:   db 0,0,0

intense:      db 0h             ; intensity flag for ansi sequences
fg_idx:       db 0fh            ; intense white is default
bg_idx:       db 00h            ; black is default
 
; ansi color values as TSM9x18 values, 0-7 are dim, 8-f are intense colors
ansi_colors:  db 01h, 06h, 0ch, 0ah, 04h, 0dh, 07h, 0eh  
              db 0eh, 09h, 02h, 0bh, 05h, 08h, 03h, 0fh

          ; Note that 0 (default) and E (Gray) differ for fg and bg color maps
          ;   0   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
fg_map:   db 0fh, 00h, 0ah, 0eh, 04h, 0ch, 01h, 06h, 0dh, 09h, 03h, 0bh, 02h, 05h, 07h, 0fh

          ;   0   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
bg_map:   db 00h, 00h, 0ah, 0eh, 04h, 0ch, 01h, 06h, 0dh, 09h, 03h, 0bh, 02h, 05h, 08h, 0fh                     

usage:        db   'Usage: ansi text',10,13,0           
                        
              end ansi
