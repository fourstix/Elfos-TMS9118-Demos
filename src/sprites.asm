; -------------------------------------------------------------------
;                          sprite5th
;
; Demo of a moving 5th sprite, as it passes line of 4 sprites it
; blanks out, and the fourth sprite changes color. The color change is
; is simply used as an indicator, not a property of the 5th sprite
; behavior.  Press input to exit.
;
; Program for 1802-Mini with the TMS9118 Color Video Card
; published by David Madole:
;
;      https://github.com/dmadole/1802-Mini
;
; This program uses the TMS9118 graphics mode 2 for 'bitmap' display
; -------------------------------------------------------------------
; *** Based on software written by Glenn Jolly
; *** Original author copyright notice:
; Copyright (C) 2021 by Glenn Jolly
; -------------------------------------------------------------------
; *** Based on software written by Michael H Riley
; *** Original author copyright notice:
; -------------------------------------------------------------------
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; -------------------------------------------------------------------
;
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

#include    include/bios.inc
#include    include/ops.inc
#include    include/vdp.inc


          ; Executable program header
          org     2000h - 6
            dw      start
            dw      end-start
            dw      start

start:    org     2000h
            br      main
                                                  
          ; Build information                          
            db      5+80h              ; month
            db      26                 ; day
            dw      2022               ; year
            dw      2                  ; build
                        
            db      'Copyright 2021 by Glenn Jolly',0
              

main:           ; init sprite position data
            mov  rf, SPRITE_ATTR
            mov  rd, START_SPRITE_DATA
            mov  rc, END_SPRITE_ATTR-SPRITE_ATTR
            sep  scall
            dw   f_memcpy      ; rd <- rf (rc bytes)

            call SET_GROUP  
            call SAVE_IE
            call DISABLE_IE            
            call INIT_VREG
            call CLEAR_VRAM
            call SEND_VDP_COLORS     ; no color table per se, just poke single color
            call SEND_VDP_NAME

            call SPRITE_PIX    ; pattern data
            call SPRITE_DAT    ; position and colors
            dw   SPRITE_ATTR


; -----------------------------------------------------------
;                   Command loop
; -----------------------------------------------------------
            mov  rc, 0         ; init frame counter
SET_POSITION_PTR:
            mov  rb, FIFTH_SPRITE_YPOS

NEXT_FRAME: inp  VDP_REG_P     ; clear any existing VDP interrupt, D holds status
            ;plo  r7            ; save status

WAIT_INTR:  bn1  WAIT_INTR     ; wait for VDP INT active low

            ; pulse for frame time measurement
            ;seq
            ;req

            ;glo  r7
            smi  0C4h          ; test for 5th sprite flag
            lbz FLAG5          ; 5th sprite flag set so change color of 4th ball
            
            ; reset color of 4th ball back to white
            mov  ra, SPRITE_POS3+3
            ldi  COLOR_WHITE   ; white
            str  ra            ; set color
            lbr  DONE_5FLAG
            
            ; change color of 4th ball when 5 sprite flag set
FLAG5:      mov  ra, SPRITE_POS3+3
            ldi  COLOR_MAGENTA ; magenta
            str  ra            ; set color
            ; sep  scall
            ; dw   f_inmsg
            ; db   '  5th sprite!', 13,10,0

DONE_5FLAG: ; user input for exit
            b4  QUIT          ; exit if input typed

            ; redraw but skip every other move - effective 30Hz display
            ; must redraw else successive inp/waits will hang
            glo  rc
            ani  1
            lbz  UPDATE_POS

MOVE_SPRITES:
            ; update Y pos of fifth sprite
            mov  ra, SPRITE_POS4
            ldn  rb
            lbz  SET_POSITION_PTR
            str  ra
            inc  rb

UPDATE_POS: call SPRITE_DAT
            dw   SPRITE_POS0
            inc  rc
            lbr  NEXT_FRAME

QUIT:       CALL RESET_VDP        ; reset video to turn of vdp interrupt
            CALL RESET_GROUP      ; set group back to default
            CALL RESTORE_IE       ; restore 1802 int back to original state
            rtn

; -------------------------------------------------------------------
;            Reset Video and turn off VDP interrupts
; -------------------------------------------------------------------
RESET_VDP:    sex     r3            ; x = p for VDP out
              out     VDP_REG_P     ; Clear display and turn off VDP interrupt
              db      088h          ; 16k=1, blank=0, m1=0, m2=1
              out     VDP_REG_P
              db      081h
              sex     r2            ; set x back to stack pointer
              rtn                 

; -------------------------------------------------------------------
;            Save IE (1802 INT) state
; -------------------------------------------------------------------
SAVE_IE:      mov  rf, ie_flag    ; point rf to flag location
              ldi  0FFh           ; assume true
              lsie                ; long skip if ie true
              ldi  00h            ; set false, skipped if true
              str  rf             ; save in memory
              rtn                 
                 
; -------------------------------------------------------------------
;            Restore IE (1802 INT) state
; -------------------------------------------------------------------
            
RESTORE_IE:   mov rf, ie_flag    ; point rf to flag location
              ldn rf             ; Get saved value of ie
              lbz RI_Done        ; if ie false, just return
              sex r3             ; x = p for ret instruction
              ret                ; Turn interrupts back on
              db 23H             ; with x=2, p=3
RI_Done:      rtn 

; -------------------------------------------------------------------
;            Disable IE (1802 Interrupts)
; -------------------------------------------------------------------
DISABLE_IE:   sex r3             ; x = p for dis instruction
              dis                ; Turn interrupts off
              db 23H             ; with x=2, p=3
              rtn
                
; -------------------------------------------------------------------
;            Set the Expansion Group for Video Card
; -------------------------------------------------------------------
SET_GROUP:  
#ifdef EXP_PORT
            ldi  VDP_GROUP   ; Video card is in group 1 
            str  r2
            out  EXP_PORT    ; Set group on expansion card
            dec  r2
#endif            
            rtn 

; -------------------------------------------------------------------
;            Set the Expansion Group back to default
; -------------------------------------------------------------------
RESET_GROUP:
#ifdef EXP_PORT          
            ldi  DEF_GROUP    ; All other cards are in group 0
            str  r2
            out  EXP_PORT     ; Set group on expansion card
            dec  r2
#endif
            rtn
                                       

; -------------------------------------------------------------------
;            Initialize the 8 TMS9118 VDP Registers
; -------------------------------------------------------------------
INIT_VREG:  mov  rf, VREG_SET
            ldi  80h
            plo  r7
NEXTREG:    lda  rf
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
            lbnz NEXTREG
            rtn

; -----------------------------------------------------------
;         Select VDP destination address for sending
; -----------------------------------------------------------
; Note:   Selected VDP address must have bit 14 set,
;         so add 4000h to any VDP address selection.
;         e.g. VDP colortable address 2000h-> 6000h  
; -----------------------------------------------------------
SELECT_VDP_ADDR:
            lda  r6
            phi  rf
            lda  r6
            plo  rf            ; rf has address from linkage
            str  r2
            out  VDP_REG_P     ; send low byte of address
            dec  r2
            ghi  rf
            str  r2
            out  VDP_REG_P     ; and then high byte
            dec  r2
            rtn


; -----------------------------------------------------------
;                     Clear VDP memory
; -----------------------------------------------------------
CLEAR_VRAM: 
            call SELECT_VDP_ADDR
            dw   4000h         ; set VDP write address to 0000h

            mov  r7, 4000h     ; 16k memory
CLEAR_NXT:  ldi  0
            str  r2
            out  VDP_DAT_P     ; VDP performs autoincrement of VRAM address  
            dec  r2
            dec  r7
            glo  r7
            lbnz CLEAR_NXT
            ghi  r7
            lbnz CLEAR_NXT
            rtn

; -----------------------------------------------------------
;           Copy color data to vram @ 2000h (Color table)
; -----------------------------------------------------------
SEND_VDP_COLORS:
            call SELECT_VDP_ADDR
            dw   6000h         ; set VDP write address to 2000h

            ; now copy data
            mov  r7, 1800h     ; 6144 bytes
            ldi  COLOR_GRAY    ; gray field
            str  r2
NEXT_CLR:   out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_CLR
            ghi  r7
            lbnz NEXT_CLR
            rtn

; -----------------------------------------------------------
; Set name table entries of vram @ 3800h (Name table)
; -----------------------------------------------------------
SEND_VDP_NAME:            
            call SELECT_VDP_ADDR
            dw   7800h         ; set VDP write address to 3800h

            ; fill with triplet series 0..255, 0..255, 0..255
            mov  r7, 768       ; number of entries to write
            ldi  0             ; starting index
            plo  r8
NAME_IDX:   glo  r8
            str  r2
            out  VDP_DAT_P
            dec  r2
            inc  r8
            dec  r7
            glo  r7
            lbnz NAME_IDX
            ghi  r7
            lbnz NAME_IDX
            rtn

; -------------------------------------------------------------------
;        Get sprite pixel pattern data and send to VDP
; -------------------------------------------------------------------
            ; set VDP write address to 1800h
SPRITE_PIX: call SELECT_VDP_ADDR
            dw   5800h         ; set VDP write address to 1800h

            ;copy sprite definitions to VDP
            mov  rf, SPRITE_PAT
            mov  r7, END_SPRITE_PAT-SPRITE_PAT
NEXT_BYTE:  lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_BYTE
            rtn
            
; -------------------------------------------------------------------
;      Get sprite attributes data and send to VDP
; -------------------------------------------------------------------
            ; set VDP write address to 3B00h
SPRITE_DAT: call SELECT_VDP_ADDR
            dw   7B00h         ; set VDP write address to 3B00h
            
            ;copy sprite attributes pos and color to VDP
            lda  r6
            phi  rf
            lda  r6
            plo  rf
            mov  r7, END_SPRITE_DATA-START_SPRITE_DATA
NEXT_ATR:   lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_ATR
            rtn
    
        
            ; default VDP register settings for graphics II mode
VREG_SET:   db  2       ; VR0 graphics 2 mode, no ext video
            ;db  0C2h    ; VR1 16k vram, display enabled, intr disabled; 16x16 sprites
            db  0E2h    ; VR1 16k vram, display enabled, intr enabled; 16x16 sprites
            db  0Eh     ; VR2 Name table address 3800h
            db  0FFh    ; VR3 Color table address 2000h
            db  3       ; VR4 Pattern table address 0000h
            db  76h     ; VR5 Sprite attribute table address 3B00h
            db  3       ; VR6 Sprite pattern table address 1800h
            db  0ch     ; Backdrop color dark green

SPRITE_PAT:
            ; 16x16 ball 1
            db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,07Fh,07Fh,03Fh,01Fh,007h
            db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,0FEh,0FEh,0FCh,0F8h,0E0h

            ; 16x16 ball 2
            db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,07Fh,07Fh,03Fh,01Fh,007h
            db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,0FEh,0FEh,0FCh,0F8h,0E0h

            ; 16x16 ball 3
            db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,07Fh,07Fh,03Fh,01Fh,007h
            db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,0FEh,0FEh,0FCh,0F8h,0E0h

            ; 16x16 ball 4
            db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,07Fh,07Fh,03Fh,01Fh,007h
            db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,0FEh,0FEh,0FCh,0F8h,0E0h

            ; 16x16 ball 5
            db  007h,01Fh,03Fh,07Fh,07Fh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,07Fh,07Fh,03Fh,01Fh,007h
            db  0E0h,0F8h,0FCh,0FEh,0FEh,0FFh,0FFh,0FFh
            db  0FFh,0FFh,0FFh,0FEh,0FEh,0FCh,0F8h,0E0h
END_SPRITE_PAT:

; Note: backup copy not really used in this version except at initialization
; Since each 16x16 sprite takes up 4 8x8 'slots' they are numbered 0,4,8,12,16
SPRITE_ATTR:
            ;   [Y,   X, Id#, Color]
             db  88,  80, 0,  COLOR_RED    ; red ball1
             db  88, 100, 4,  COLOR_GREEN  ; green ball2
             db  88, 120, 8,  COLOR_BLUE   ; blue ball3
             db  88, 140, 12, COLOR_WHITE  ; white ball4
             db  56, 160, 16, COLOR_CYAN   ; cyan ball5
             db  0D0h              ; Sprite processing terminator
END_SPRITE_ATTR:

; dynamic position will be updated in this memory block
START_SPRITE_DATA:
;                Y    X
SPRITE_POS0: db  88,  80, 0,  COLOR_RED    ; red ball1
SPRITE_POS1: db  88, 100, 4,  COLOR_GREEN  ; green ball2
SPRITE_POS2: db  88, 120, 8,  COLOR_BLUE   ; blue ball3
SPRITE_POS3: db  88, 140, 12, COLOR_WHITE  ; white ball4
SPRITE_POS4: db  56, 160, 16, COLOR_CYAN   ; cyan ball5
TERMINATOR:  db  0D0h
END_SPRITE_DATA:

FIFTH_SPRITE_YPOS:
            db    57,  58,  59,  60,  61,  62,  63,  64,  65,  66,  67,  68,  69,  70,  71,  72,
            db    73,  74,  75,  76,  77,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,
            db    89,  90,  91,  92,  93,  94,  95,  96,  97,  98,  99, 100, 101, 102, 103, 104,
            db   105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
            db   120, 119, 118, 117, 116, 115, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105,
            db   104, 103, 102, 101, 100,  99,  98,  97,  96,  95,  94,  93,  92,  91,  90,  89,
            db    88,  87,  86,  85,  84,  83,  82,  81,  80,  79,  78,  77,  76,  75,  74,  73,
            db    72,  71,  70,  69,  68,  67,  66,  65,  64,  63,  62,  61,  60,  59,  58,  57,
            db     0,   0

ie_flag:    db 00h
END:
