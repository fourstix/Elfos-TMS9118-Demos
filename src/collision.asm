; -------------------------------------------------------------------
;                      collision
;
; Demo of sprite collision detection, as a projectile hits 
; a target the target changes color.  Press input to exit.
;
; Program for 1802-Mini with the TMS9118 Color Video Card
; published by David Madole:
;
;      https://github.com/dmadole/1802-Mini
;
; This program uses the TMS9118 graphics mode 2 for 'bitmap' display
;
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
            
start:      org     2000h
              br      main
                                                    
            ; Build information                          
              db      5+80h              ; month
              db      30                 ; day
              dw      2022               ; year
              dw      2                  ; build
                          
              db      'Copyright 2022 by Gaston Williams',0
                          

main:      ; init sprite position data
            mov  rf, SPRITE_ATTR
            mov  rd, START_SPRITE_DATA
            mov  rc, END_SPRITE_ATTR-SPRITE_ATTR
            sep  scall
            dw   f_memcpy      ; rd <- rf (rc bytes)

            call SET_GROUP            
            call INIT_VREG
            call CLEAR_VRAM
            call SEND_VDP_COLORS     ; just single background color
            call SEND_VDP_NAME

            call SPRITE_PIX    ; pattern data
            call SPRITE_DAT    ; position and colors
            dw   SPRITE_ATTR


; -----------------------------------------------------------
;                   Command loop
; -----------------------------------------------------------
            mov  rc, 0        ; init frame counter
            req               ; make sure q is off initially
            
SET_POSITION_PTR:
            mov  rb, PROJECTILE_SPRITE_XPOS

NEXT_FRAME: inp  VDP_REG_P    ; READ VDP status, D holds status byte
            plo  r7           ; save status byte for frame test
            ani  020h         ; test for collision flag
            bz   CHK_FRAME    
            seq               ; set Q if a collision occurred
CHK_FRAME:  glo  r7           ; get status byte to test for frame 
            shl               ; check msb to see if painting finished
            bnf  NEXT_FRAME   ; wait for screen to be painted            
                       
            lbq  COLLISION    ; test Q to see if collision occurred during frame
            
            ; reset color of target
            mov  ra, SPRITE_POS0+3
            ldi  COLOR_DARK_RED
            str  ra            ; set color
            req
            lbr  DONE_COLLISION
            
            ; change color of target to black at collision
COLLISION:  mov  ra, SPRITE_POS0+3
            ldi  COLOR_BLACK
            str  ra            ; set color                        
            
DONE_COLLISION: ; user input for exit            
            b4  QUIT             ; wait for input to exit             
            
MOVE_SPRITES:
            ; update X pos of projectile
            mov  ra, SPRITE_POS1+1
            ldn  rb
            lbz  SET_POSITION_PTR
            str  ra
            inc  rb

UPDATE_POS: call SPRITE_DAT
            dw   SPRITE_POS0
            inc  rc
            req                 ; clear collision flag after move
            lbr  NEXT_FRAME

QUIT:       CALL RESET_VDP      ; reset video to turn of vdp interrupt
            CALL RESET_GROUP    ; set group back to default
            req                 ; turn Q off
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
              ldi  DEF_GROUP   ; All other cards are in group 0
              str  r2
              out  EXP_PORT    ; Set group on expansion card
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
            ldi  COLOR_GRAY    ; background
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
            db  0C2h    ; VR1 16k vram, display enabled, intr disabled; 16x16 sprites
            ;db  0E2h    ; VR1 16k vram, display enabled, intr enabled; 16x16 sprites
            db  0Eh     ; VR2 Name table address 3800h
            db  0FFh    ; VR3 Color table address 2000h
            db  3       ; VR4 Pattern table address 0000h
            db  76h     ; VR5 Sprite attribute table address 3B00h
            db  3       ; VR6 Sprite pattern table address 1800h
            db  COLOR_GRAY     ; Backdrop color

SPRITE_PAT:
            ; 16x16 target
            db  007h, 01Fh, 03Fh, 07Fh, 07Fh, 0FFh, 0FFh, 0FFh
            db  0FFh, 0FFh, 0FFh, 07Fh, 07Fh, 03Fh, 01Fh, 007h
            db  0E0h, 0F8h, 0FCh, 0FEh, 0FEh, 0FFh, 0FFh, 0FFh
            db  0FFh, 0FFh, 0FFh, 0FEh, 0FEh, 0FCh, 0F8h, 0E0h

            ; 16x16 projectile
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h
            db  001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h
            db  080h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
END_SPRITE_PAT:

; Note: backup copy not really used in this version except at initialization
; Since each 16x16 sprite takes up 4 8x8 'slots' they are numbered 0&4
SPRITE_ATTR:
            ;   [Y,   X, Id#, Color]
             db  88, 120, 0,  COLOR_DARK_RED  ; target
             db  88,  57, 4,  COLOR_DARK_RED  ; projectile
             db  0D0h              ; Sprite processing terminator
END_SPRITE_ATTR:

; dynamic position will be updated in this memory block
START_SPRITE_DATA:
;                Y    X
SPRITE_POS0: db  88, 120, 0,  COLOR_DARK_RED  ; target
SPRITE_POS1: db  88,  57, 4,  COLOR_DARK_RED  ; projectile
TERMINATOR:  db  0D0h
END_SPRITE_DATA:


PROJECTILE_SPRITE_XPOS:
            db    57,  58,  59,  60,  61,  62,  63,  64,  65,  66,  67,  68,  69,  70,  71,  72,
            db    73,  74,  75,  76,  77,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,
            db    89,  90,  91,  92,  93,  94,  95,  96,  97,  98,  99, 100, 101, 102, 103, 104,
            db   105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120,
            db   121, 122, 123, 124, 125, 126, 127, 127, 127, 0,   0

END: 
