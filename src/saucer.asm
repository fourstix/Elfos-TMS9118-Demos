; -------------------------------------------------------------------
;                          saucer
;         Demo of flying sprite landing in the desert
;         Illustrates 2 color sprite and interrupt updates
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
  db      25                 ; day
  dw      2022               ; year
  dw      2                  ; build
              
  db      'Copyright 2021 by Glenn Jolly',0
              
  
  
main:       call SET_GROUP
            call SAVE_IE
            call INIT_VREG
            call CLEAR_VRAM
            call SEND_VDP_PATTERN
            call SEND_VDP_COLORS
            call SEND_VDP_NAME

            ; init sprite position data 
            ; else display flashes at last location
            mov  rf, SPRITE_ATTR
            mov  rd, START_SPRITE_DATA
            mov  rc, END_SPRITE_ATTR-SPRITE_ATTR
            sep  scall
            dw   f_memcpy      ; rd <- rf (rc bytes)

            ; init sprite(s) position data
            mov  rb, SAUCER_POINTS  ; pointer travel plan x,y coords
            call SPRITE_PIX
            call SPRITE_DAT
            dw   SPRITE_ATTR   ; display field now complete

            call DEL_1SEC      ; wait a bit before moving saucer
            call DEL_1SEC

; -----------------------------------------------------------------------
;                     Flying saucer landing loop
; -----------------------------------------------------------------------

            mov  rc, 0         ; init frame counter
            
            sex r3             ; set x = p for disable instruction
            dis                ; x=2, p=3 and disable interrupts
            db 23H             ; value for x=2, p=3
            call SET_INTR      ; enable video interrupt after painting screen

NEXT_FRAME: inp  VDP_REG_P     ; clear any existing VDP interrupt
WAIT_INTR:  bn1  WAIT_INTR     ; important - wait for VDP INT active low

            ; redraw but skip every other move update - effective 30Hz display
            ; must redraw else successive inp/waits will hang
            ; for this demo, 30Hz travel time of saucer is ~8 sec vs 4s
            glo  rc
            ani  1
            lbz  UPDATE_POS

            ; show saucer with blinking colors
            glo  rc
            ani  16
            lbz  FLASH
            mov  ra, SPRITE_POS0+3
            ldi  COLOR_RED
            str  ra
            mov  ra, SPRITE_POS1+3
            ldi  COLOR_WHITE
            str  ra
            lbr  MOVE_SAUCER
FLASH:      mov  ra, SPRITE_POS0+3
            ldi  COLOR_WHITE
            str  ra
            mov  ra, SPRITE_POS1+3
            ldi  COLOR_RED
            str  ra

MOVE_SAUCER:
            ; update X pos for sprite 1 & 2
            mov  ra, SPRITE_POS0+1
            ldn  rb
            lbz  QUIT
            str  ra
            mov  ra, SPRITE_POS1+1
            ldn  rb
            str  ra

            inc  rb  ; move pointer to y coord

            ; update Y pos for sprite 1 & 2
            mov  ra, SPRITE_POS0
            ldn  rb
            lbz  QUIT
            str  ra
            mov  ra, SPRITE_POS1
            ldn  rb
            str  ra
            inc  rb  ; next x,y

UPDATE_POS: call SPRITE_DAT
            dw   SPRITE_POS0
            inc  rc            ; update frame counter
            lbr  NEXT_FRAME

QUIT:       bn4     QUIT          ; wait for input to exit
            sex     r3            ; x = p
            out     VDP_REG_P
            db      088h          ; 16k=1, blank=0, m1=0, m2=1
            out     VDP_REG_P
            db      081h
            sex     r2            ; set x back to stack pointer
            call RESET_GROUP      ; set group back to default
            CALL RESTORE_IE       ; set int back to original state
            rtn                   ; return to Elf/OS
            
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
; ---------------------------------------------------------------------
; command VDP register VR1 to enable interrupt line in graphics mode 2
; ---------------------------------------------------------------------
SET_INTR:   ldi  0E2h
            str  r2
            out  VDP_REG_P
            dec  r2
            ldi  81h           ; VR1
            str  r2
            out  VDP_REG_P
            dec  r2
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
;        Copy pattern data to vram Pattern Table @ 0000h
; -----------------------------------------------------------
SEND_VDP_PATTERN:
            call SELECT_VDP_ADDR
            dw   4000h         ; set VDP write address to 0000h

            ; now we copy data to vram 0000h (Pattern table)
            mov  rf, START_BITMAP
            mov  r7, END_BITMAP-START_BITMAP  ; 6144 bytes
NEXT_BYTE:  lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_BYTE
            ghi  r7
            lbnz NEXT_BYTE
            rtn

; -----------------------------------------------------------
;           Copy color data to vram @ 2000h (Color table)
; -----------------------------------------------------------
SEND_VDP_COLORS:
            call SELECT_VDP_ADDR
            dw   6000h         ; set VDP write address to 2000h

            ; now copy data
            mov  rf, START_COLORTABLE
            mov  r7, END_COLORTABLE-START_COLORTABLE  ; also 6144 bytes
NEXT_CLR:   lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
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
NEXT_ROW:   lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_ROW
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
            mov  r7, END_SPRITE_ATTR-SPRITE_ATTR
NEXT_ATR:   lda  rf
            str  r2
            out  VDP_DAT_P     ; VDP will autoincrement VRAM address
            dec  r2
            dec  r7
            glo  r7
            lbnz NEXT_ATR
            rtn


; --------------------------------------------------------
;                     Delay routines
; --------------------------------------------------------

; approx 50mS delay on 4MHz Pico Elf 2
DELAY50MS:  ldi  0Dh
            phi  rc
            ldi  0CEh
            plo  rc
D50:        dec  rc
            glo  rc
            lbnz D50
            ghi  rc
            lbnz D50
            rtn

; approx one second delay subroutine
DEL_1SEC:   ldi  0ffh
            phi  rf
            ldi  0h
            plo  rf
DL1:        dec  rf
            glo  rf
            lbnz DL1
            ghi  rf
            lbnz DL1
            rtn


           ; default VDP register settings for graphics II mode
VREG_SET:   db  2       ; VR0 graphics 2 mode, no ext video
            db  0C2h    ; VR1 16k vram, display enabled, intr disabled; 16x16 sprites
            ;db  082h    ; VR1 16k vram, display disabled, intr disabled; 16x16 sprites
            ;db  0E2h    ; VR1 16k vram, display enabled, intr enabled; 16x16 sprites
            db  0Eh     ; VR2 Name table address 3800h
            db  0FFh    ; VR3 Color table address 2000h
            db  3       ; VR4 Pattern table address 0000h
            db  76h     ; VR5 Sprite attribute table address 3B00h
            db  3       ; VR6 Sprite pattern table address 1800h
            db  01h     ; Backdrop color black


; -----------------------------------------------------------------------------
;               Sprite pattern, attributes and position data
; -----------------------------------------------------------------------------

SPRITE_PAT:
            ; Sprite saucer pattern 1 (top half)
            db  000h, 000h, 000h, 001h, 007h, 01Fh, 07Fh, 0FFh
            db  000h, 000h, 000h, 000h, 000h, 003h, 000h, 000h
            db  000h, 000h, 000h, 000h, 0C0h, 0F0h, 0FCh, 0FEh
            db  000h, 000h, 000h, 000h, 000h, 080h, 000h, 000h

            ; Sprite saucer pattern 2 (bottom half)
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
            db  0FFh, 07Fh, 01Fh, 007h, 003h, 000h, 000h, 000h
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
            db  0FEh, 0FCh, 0F0h, 0C0h, 080h, 000h, 000h, 000h
END_SPRITE_PAT:

; Attributes
; Note: this copy used only at initialization - can serve as a backup copy
; Since these are 16x16 they take up 4 8x8 'slots' so are numbered 0 & 4
; Saucer begins white/red and flies as magenta/cyan
SPRITE_ATTR:
            ;  [Y,  X, Id, Color]
            db  26, 16, 0, COLOR_WHITE  ; saucer part 1 white
            db  26, 16, 4, COLOR_RED    ; saucer part 2 red
            db 0D0h             ; Sprite processing terminator
END_SPRITE_ATTR:

; dynamic position and color may be updated in this memory block
START_SPRITE_DATA:
;                Y   X
SPRITE_POS0: db  26, 16, 0, COLOR_WHITE  ; saucer part 1
SPRITE_POS1: db  26, 16, 4, COLOR_RED    ; saucer part 2
TERMINATOR:  db 0D0h
END_SPRITE_DATA:

; flight and landing plan
SAUCER_POINTS:  ; X    Y 
            db   16,  26
            db   17,  26
            db   18,  27
            db   19,  27
            db   20,  28
            db   21,  28
            db   22,  29
            db   23,  29
            db   24,  29
            db   25,  30
            db   26,  30
            db   27,  31
            db   28,  31
            db   29,  31
            db   30,  32
            db   31,  32
            db   32,  33
            db   33,  33
            db   34,  34
            db   35,  34
            db   36,  34
            db   37,  35
            db   38,  35
            db   39,  36
            db   40,  36
            db   41,  37
            db   42,  37
            db   43,  37
            db   44,  38
            db   45,  38
            db   46,  39
            db   47,  39
            db   48,  39
            db   49,  40
            db   50,  40
            db   51,  41
            db   52,  41
            db   53,  42
            db   54,  42
            db   55,  42
            db   56,  43
            db   57,  43
            db   58,  44
            db   59,  44
            db   60,  45
            db   61,  45
            db   62,  45
            db   63,  46
            db   64,  46
            db   65,  47
            db   66,  47
            db   67,  47
            db   68,  48
            db   69,  48
            db   70,  49
            db   71,  49
            db   72,  50
            db   73,  50
            db   74,  50
            db   75,  51
            db   76,  51
            db   77,  52
            db   78,  52
            db   79,  53
            db   80,  53
            db   81,  53
            db   82,  54
            db   83,  54
            db   84,  55
            db   85,  55
            db   86,  55
            db   87,  56
            db   88,  56
            db   89,  57
            db   90,  57
            db   91,  58
            db   92,  58
            db   93,  58
            db   94,  59
            db   95,  59
            db   96,  60
            db   97,  60
            db   98,  61
            db   99,  61
            db  100,  61
            db  101,  62
            db  102,  62
            db  103,  63
            db  104,  63
            db  105,  63
            db  106,  64
            db  107,  64
            db  108,  65
            db  109,  65
            db  110,  66
            db  111,  66
            db  112,  66
            db  113,  67
            db  114,  67
            db  115,  68
            db  116,  68
            db  117,  69
            db  118,  69
            db  119,  69
            db  120,  70
            db  121,  70
            db  122,  71
            db  123,  71
            db  124,  71
            db  125,  72
            db  126,  72
            db  127,  73
            db  128,  73
            db  129,  74
            db  130,  74
            db  131,  74
            db  132,  75
            db  133,  75
            db  134,  76
            db  135,  76
            db  136,  77
            db  137,  77
            db  138,  77
            db  139,  78
            db  140,  78
            db  141,  79
            db  142,  79
            db  143,  79
            db  144,  80
            db  145,  80
            db  146,  81
            db  147,  81
            db  148,  82
            db  149,  82
            db  150,  82
            db  151,  83
            db  152,  83
            db  153,  84
            db  154,  84
            db  155,  85
            db  156,  85
            db  157,  85
            db  158,  86
            db  159,  86
            db  160,  87
            db  161,  87
            db  162,  87
            db  163,  88
            db  164,  88
            db  165,  89
            db  166,  89
            db  167,  90
            db  168,  90
            db  169,  90
            db  170,  91
            db  171,  91
            db  172,  92
            db  173,  92
            db  174,  93
            db  175,  93
            db  176,  93
            db  177,  94
            db  178,  94
            db  179,  95
            db  180,  95
            db  181,  95
            db  182,  96
            db  183,  96
            db  184,  97
            db  185,  97
            db  186,  98
            db  187,  98
            db  187,  98
            db  186,  99
            db  186, 100
            db  185, 101
            db  184, 102
            db  184, 103
            db  183, 104
            db  182, 105
            db  182, 106
            db  181, 107
            db  180, 108
            db  180, 109
            db  179, 110
            db  178, 111
            db  178, 112
            db  177, 113
            db  176, 114
            db  176, 115
            db  175, 116
            db  174, 117
            db  174, 118
            db  173, 119
            db  172, 120
            db  172, 121
            db  171, 122
            db  170, 123
            db  170, 124
            db  169, 125
            db  168, 126
            db  168, 127
            db  167, 128
            db  166, 129
            db  165, 130
            db  165, 131
            db  164, 132
            db  163, 133
            db  163, 134
            db  162, 135
            db  161, 136
            db  161, 137
            db  160, 138
            db  159, 139
            db  159, 140
            db  158, 141
            db  157, 142
            db  157, 143
            db  156, 144
            db  155, 145
            db  155, 146
            db  154, 147
            db  153, 148
            db  153, 149
            db  152, 150
            db  151, 151
            db  151, 152
            db  150, 153
            db  150, 153
            db  150, 154
            db  150, 155
            db  150, 156
            db  150, 157
            db  150, 158
            db  150, 159
            db  150, 160
            db  150, 161
            db  150, 162
            db  150, 163
            db  150, 164
            db  150, 165
            db  150, 166
            db  150, 167
            db  150, 168
            db  150, 169
            db  150, 170
            db    0,   0
END_POINTS:



; -----------------------------------------------------------------------------
;                     Bitmap pattern and color data
; -----------------------------------------------------------------------------

START_BITMAP:
            db  000h, 0c3h, 001h, 001h, 007h, 003h, 000h, 000h, 
            db  000h, 000h, 000h, 030h, 007h, 003h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  003h, 0e0h, 0c0h, 0c0h, 080h, 080h, 000h, 000h, 
            db  0c0h, 0f0h, 003h, 003h, 001h, 001h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 003h, 007h, 0f0h, 0f0h, 0f0h, 
            db  000h, 000h, 000h, 003h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 0f0h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 080h, 0c0h, 0e0h, 0e0h, 0e0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 080h, 080h, 080h, 0c0h, 0c0h, 0f0h, 003h, 
            db  000h, 001h, 001h, 001h, 003h, 003h, 0f0h, 0c0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 001h, 000h, 000h, 000h, 
            db  000h, 000h, 001h, 007h, 002h, 000h, 000h, 0e0h, 
            db  000h, 000h, 007h, 007h, 007h, 000h, 000h, 000h, 
            db  0f0h, 0f0h, 007h, 000h, 000h, 000h, 038h, 000h, 
            db  000h, 001h, 003h, 0f0h, 000h, 000h, 003h, 000h, 
            db  000h, 0f0h, 003h, 000h, 000h, 0f0h, 000h, 000h, 
            db  0f0h, 0f0h, 0f0h, 030h, 000h, 000h, 000h, 0e0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  008h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  020h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 0f0h, 080h, 0e0h, 000h, 
            db  000h, 000h, 000h, 003h, 0f0h, 000h, 000h, 001h, 
            db  000h, 000h, 001h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0e0h, 0f0h, 001h, 001h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 081h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 0c0h, 000h, 000h, 000h, 000h, 
            db  0e0h, 0e1h, 0e1h, 000h, 0e1h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 0e0h, 000h, 000h, 003h, 0e0h, 
            db  000h, 000h, 0f0h, 000h, 000h, 003h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 0f0h, 
            db  000h, 000h, 007h, 000h, 000h, 0e0h, 0e0h, 0e0h, 
            db  0f0h, 0f0h, 0f0h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 001h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 003h, 0f0h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 080h, 000h, 000h, 
            db  000h, 000h, 000h, 001h, 007h, 000h, 000h, 000h, 
            db  000h, 0f0h, 081h, 003h, 007h, 000h, 000h, 000h, 
            db  020h, 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0e0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  002h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 003h, 001h, 000h, 000h, 000h, 000h, 
            db  001h, 003h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  006h, 000h, 000h, 000h, 001h, 000h, 000h, 000h, 
            db  007h, 000h, 000h, 000h, 0f0h, 0f0h, 000h, 000h, 
            db  000h, 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 070h, 003h, 0f0h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 080h, 0c0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  007h, 001h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 0c0h, 0f0h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 0f0h, 001h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 
            db  000h, 000h, 000h, 000h, 080h, 080h, 0e0h, 007h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0c0h, 0e0h, 0e0h, 0f0h, 0f0h, 007h, 003h, 003h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  003h, 0f0h, 0f0h, 0e0h, 0e0h, 0c0h, 080h, 000h, 
            db  003h, 001h, 000h, 000h, 000h, 000h, 000h, 001h, 
            db  000h, 000h, 0c0h, 080h, 080h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  003h, 001h, 001h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 080h, 0c0h, 0f0h, 007h, 003h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 00ch, 00dh, 092h, 092h, 092h, 092h, 
            db  000h, 000h, 000h, 080h, 080h, 080h, 080h, 080h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  001h, 003h, 003h, 007h, 0f0h, 0e0h, 0c0h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  007h, 0e0h, 0c0h, 080h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 0c0h, 0e0h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 0e0h, 0f0h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 0e0h, 003h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 0e0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  080h, 0c0h, 00ch, 00ch, 00ch, 00ch, 00ch, 000h, 
            db  080h, 000h, 000h, 000h, 000h, 0c0h, 000h, 000h, 
            db  000h, 000h, 0f0h, 080h, 080h, 070h, 000h, 000h, 
            db  003h, 000h, 000h, 000h, 000h, 000h, 001h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 001h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0f0h, 003h, 003h, 001h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 080h, 080h, 0c0h, 0e0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 00ch, 00dh, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 001h, 003h, 
            db  001h, 003h, 007h, 0e0h, 0c0h, 080h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 008h, 
            db  000h, 000h, 000h, 000h, 020h, 070h, 070h, 08eh, 
            db  0f0h, 007h, 003h, 001h, 001h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 0c0h, 0f0h, 
            db  092h, 092h, 092h, 092h, 092h, 080h, 080h, 00ch, 
            db  080h, 080h, 080h, 080h, 080h, 080h, 000h, 001h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 080h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 
            db  007h, 0f0h, 0e0h, 0c0h, 080h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 001h, 
            db  000h, 000h, 000h, 000h, 000h, 007h, 080h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 0c0h, 001h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 001h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 080h, 001h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 080h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  018h, 018h, 018h, 01ch, 01ch, 0f0h, 007h, 003h, 
            db  08ch, 08ch, 08ch, 08ch, 08ch, 08ch, 008h, 000h, 
            db  080h, 080h, 080h, 080h, 080h, 080h, 080h, 000h, 
            db  007h, 003h, 001h, 001h, 000h, 000h, 000h, 000h, 
            db  00ch, 00ch, 00ch, 00ch, 00ch, 000h, 000h, 000h, 
            db  0f0h, 0e0h, 0c0h, 0c0h, 080h, 0c0h, 000h, 000h, 
            db  0e0h, 0e0h, 0f0h, 007h, 000h, 000h, 0e0h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 0e0h, 003h, 0f0h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 001h, 007h, 
            db  003h, 007h, 0f0h, 0e0h, 0c0h, 080h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 003h, 0f0h, 0c0h, 000h, 
            db  007h, 0e0h, 080h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0f0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 080h, 003h, 000h, 000h, 000h, 007h, 0c0h, 
            db  000h, 000h, 000h, 0f0h, 000h, 000h, 000h, 0c0h, 
            db  000h, 0c0h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  008h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 080h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  081h, 083h, 087h, 070h, 070h, 070h, 070h, 070h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  007h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  00ch, 003h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  006h, 007h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  0f0h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  001h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h, 
            db  003h, 010h, 000h, 000h, 0c0h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 007h, 000h, 000h, 000h, 
            db  000h, 000h, 000h, 000h, 0e0h, 007h, 003h, 000h
END_BITMAP:

START_COLORTABLE:
            db  014h, 04eh, 04eh, 04eh, 0e4h, 0e4h, 014h, 014h, 
            db  014h, 014h, 014h, 0e4h, 04eh, 04eh, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  0a4h, 04ah, 04ah, 05ah, 04ah, 0dah, 01ah, 01ah, 
            db  0a4h, 0a4h, 04ah, 05ah, 04ah, 05ah, 01ah, 01ah, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 0e4h, 0e4h, 04eh, 04eh, 04eh, 
            db  014h, 014h, 014h, 04eh, 01eh, 01eh, 01eh, 01eh, 
            db  014h, 014h, 014h, 04eh, 01eh, 01eh, 01eh, 01eh, 
            db  014h, 014h, 014h, 0e4h, 0e4h, 0e4h, 0e4h, 0e4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  01ah, 0eah, 0dah, 04ah, 05ah, 04ah, 04ah, 0a4h, 
            db  01ah, 0dah, 05ah, 04ah, 05ah, 04ah, 0a4h, 0a4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 0e4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 01eh, 
            db  014h, 014h, 014h, 014h, 0e4h, 014h, 014h, 01eh, 
            db  014h, 014h, 0e4h, 0e4h, 04eh, 014h, 014h, 0e4h, 
            db  014h, 014h, 04eh, 04eh, 04eh, 014h, 014h, 01eh, 
            db  04eh, 04eh, 0e4h, 014h, 014h, 014h, 0e4h, 01eh, 
            db  01eh, 04eh, 04eh, 0e4h, 014h, 014h, 0e4h, 01eh, 
            db  01eh, 04eh, 0e4h, 014h, 014h, 0e4h, 01eh, 01eh, 
            db  0e4h, 0e4h, 0e4h, 0e4h, 014h, 014h, 014h, 0e4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  054h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  054h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 0e4h, 04eh, 04eh, 014h, 
            db  014h, 014h, 014h, 0e4h, 04eh, 01eh, 01eh, 0e4h, 
            db  014h, 014h, 0e4h, 01eh, 01eh, 01eh, 01eh, 01eh, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  04eh, 04eh, 0e4h, 0e4h, 014h, 014h, 014h, 014h, 
            db  01eh, 01eh, 0e4h, 014h, 014h, 014h, 014h, 014h, 
            db  01eh, 01eh, 01eh, 04eh, 014h, 014h, 014h, 014h, 
            db  0e4h, 0e4h, 0e4h, 01eh, 04eh, 014h, 014h, 014h, 
            db  01eh, 01eh, 01eh, 0e4h, 014h, 014h, 0e4h, 04eh, 
            db  01eh, 01eh, 0e4h, 014h, 014h, 0e4h, 01eh, 01eh, 
            db  01eh, 01eh, 014h, 014h, 014h, 01eh, 01eh, 04eh, 
            db  01eh, 01eh, 0e4h, 014h, 014h, 0e4h, 0e4h, 0e4h, 
            db  0e4h, 0e4h, 0e4h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 0e4h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 04eh, 04eh, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 0e4h, 014h, 014h, 
            db  014h, 014h, 014h, 0e4h, 0e4h, 014h, 014h, 014h, 
            db  014h, 04eh, 04eh, 04eh, 04eh, 014h, 014h, 014h, 
            db  0b4h, 0e4h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  04eh, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  0e4h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 0e4h, 0e4h, 014h, 014h, 014h, 014h, 
            db  0e4h, 0e4h, 01eh, 01eh, 014h, 014h, 014h, 014h, 
            db  04eh, 01eh, 01eh, 01eh, 0e4h, 014h, 014h, 014h, 
            db  04eh, 01eh, 01eh, 01eh, 0e4h, 0e4h, 014h, 014h, 
            db  014h, 0e4h, 01eh, 01eh, 01eh, 014h, 014h, 014h, 
            db  014h, 04eh, 01eh, 01eh, 01eh, 014h, 014h, 014h, 
            db  014h, 014h, 0e4h, 04eh, 0e4h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 094h, 094h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  049h, 049h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 094h, 094h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 094h, 049h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 094h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 094h, 
            db  019h, 019h, 019h, 019h, 0a9h, 0a9h, 0a9h, 09ah, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  094h, 094h, 094h, 094h, 094h, 049h, 049h, 049h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  094h, 049h, 049h, 049h, 049h, 049h, 049h, 019h, 
            db  09ah, 09ah, 01ah, 01ah, 01ah, 01ah, 01ah, 09ah, 
            db  019h, 019h, 0a9h, 0a9h, 0a9h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  049h, 049h, 049h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 094h, 094h, 064h, 046h, 046h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 0c4h, 0c4h, 04ch, 04ch, 04ch, 04ch, 
            db  014h, 014h, 014h, 0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  094h, 094h, 094h, 094h, 049h, 049h, 049h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  09ah, 0a9h, 0a9h, 0a9h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  016h, 096h, 096h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 014h, 094h, 094h, 019h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 094h, 049h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 094h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  04ch, 04ch, 0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 018h, 
            db  0c4h, 014h, 014h, 014h, 014h, 048h, 018h, 018h, 
            db  014h, 014h, 049h, 049h, 089h, 098h, 018h, 018h, 
            db  094h, 019h, 019h, 019h, 019h, 019h, 098h, 018h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 018h, 
            db  019h, 019h, 019h, 089h, 019h, 019h, 019h, 018h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  094h, 049h, 049h, 049h, 019h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 014h, 094h, 094h, 094h, 094h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 0c4h, 0c4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 0c4h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 084h, 084h, 
            db  084h, 084h, 084h, 048h, 048h, 048h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 0c9h, 
            db  019h, 019h, 019h, 019h, 0c9h, 0c9h, 0c9h, 09ch, 
            db  094h, 049h, 049h, 049h, 049h, 019h, 019h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 094h, 094h, 
            db  04ch, 04ch, 04ch, 04ch, 04ch, 04ch, 04ch, 0c4h, 
            db  0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 014h, 064h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 064h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 084h, 
            db  084h, 048h, 048h, 048h, 048h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 098h, 
            db  018h, 018h, 018h, 018h, 018h, 098h, 089h, 019h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 019h, 019h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 098h, 089h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 018h, 018h, 018h, 018h, 
            db  019h, 019h, 019h, 01eh, 01eh, 01eh, 01eh, 01eh, 
            db  019h, 019h, 019h, 09eh, 01eh, 01eh, 01eh, 01eh, 
            db  019h, 019h, 019h, 019h, 0e9h, 09eh, 01eh, 01eh, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 0e9h, 01eh, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  0c9h, 0c9h, 0c9h, 0c9h, 0c9h, 09ch, 0c9h, 0c9h, 
            db  09ch, 09ch, 09ch, 09ch, 09ch, 09ch, 09ch, 01ch, 
            db  0c9h, 0c9h, 0c9h, 0c9h, 0c9h, 0c9h, 0c9h, 019h, 
            db  049h, 049h, 049h, 049h, 019h, 019h, 019h, 019h, 
            db  0c4h, 0c4h, 0c4h, 0c4h, 0c4h, 019h, 019h, 019h, 
            db  046h, 046h, 046h, 046h, 046h, 096h, 019h, 019h, 
            db  064h, 064h, 064h, 046h, 016h, 016h, 096h, 019h, 
            db  014h, 014h, 014h, 014h, 014h, 064h, 046h, 096h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 014h, 014h, 
            db  014h, 014h, 014h, 014h, 014h, 014h, 084h, 084h, 
            db  084h, 084h, 048h, 048h, 048h, 048h, 018h, 018h, 
            db  018h, 018h, 018h, 018h, 098h, 089h, 089h, 019h, 
            db  098h, 089h, 089h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  098h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  018h, 098h, 089h, 019h, 019h, 019h, 0d9h, 09dh, 
            db  018h, 018h, 018h, 098h, 019h, 019h, 019h, 0d9h, 
            db  01eh, 0e9h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  09eh, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  01eh, 09eh, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  01eh, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  09ch, 09ch, 09ch, 0c9h, 0c9h, 0c9h, 0c9h, 0c9h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  049h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  074h, 0f9h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 01fh, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  074h, 09fh, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  014h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  048h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  098h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  019h, 019h, 019h, 019h, 019h, 019h, 019h, 019h, 
            db  0d9h, 09dh, 01dh, 01dh, 09dh, 019h, 019h, 019h, 
            db  01dh, 01dh, 01dh, 01dh, 09dh, 019h, 019h, 019h, 
            db  01dh, 01dh, 01dh, 01dh, 09dh, 0d9h, 0d9h, 019h
END_COLORTABLE:
ie_flag:    db   00h

END:
