; -------------------------------------------------------------------
;                        blank
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
            db      29                 ; day
            dw      2022               ; year
            dw      2                  ; build
                        
            db      'Copyright 2022 by Gaston Williams',0
                        
            
            
main:       call SET_GROUP
            call INIT_VREG
            call CLEAR_VRAM
            call SEND_VDP_COLORS
            call SEND_VDP_NAME
            call RESET_GROUP
            rtn


; -------------------------------------------------------------------
;            Set the Expansion Group for Video Card
; -------------------------------------------------------------------
SET_GROUP:  
#ifdef EXP_PORT
            ldi  VDP_GROUP    ; Video card is in group 1 
            str  r2
            out  EXP_PORT     ; Set group on expansion card
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
            bnz  NEXTREG
            rtn

; -----------------------------------------------------------
;         Select VDP destination address for sending
; -----------------------------------------------------------
SELECT_VDP_ADDR:
            lda  r6
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
            bnz  CLEAR_NXT
            ghi  r7
            bnz  CLEAR_NXT
            rtn

; -----------------------------------------------------------
;           Copy color data to vram @ 2000h (Color table)
; -----------------------------------------------------------
SEND_VDP_COLORS:
            call SELECT_VDP_ADDR
            dw   6000h         ; set VDP write address to 2000h

            ; now copy data
            mov  r7, 1800h     ; 6144 bytes
            ldi  COLOR_BLACK   ; background
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
            bnz  NAME_IDX
            ghi  r7
            bnz  NAME_IDX
            rtn


           ; default VDP register settings for graphics II mode
VREG_SET:   db  2       ; VR0 graphics 2 mode, no ext video
            db  0C2h    ; VR1 16k vram, display enabled, intr dis; 16x16 sprites
            db  0Eh     ; VR2 Name table address 3800h
            db  0FFh    ; VR3 Color table address 2000h
            db  3       ; VR4 Pattern table address 0000h
            db  76h     ; VR5 Sprite attribute table address 3B00h
            db  3       ; VR6 Sprite pattern table address 1800h
            db  01h     ; Backdrop color black

END:
