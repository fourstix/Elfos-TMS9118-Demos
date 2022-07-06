; set these values to match your 1802-Mini Video Card settings
#define VDP_DAT_P     6       ; data port
#define VDP_REG_P     7       ; register and address port
#define VDP_GROUP     1       ; video card group

; comment out this next line if not using an exapnder card
#define EXP_PORT      1       ; expander card group port

#define DEF_GROUP     0       ; default group for 1802-Mini

; TI VDP colors
COLOR_TRANSPARENT:  equ 00h
COLOR_BLACK:        equ 01h
COLOR_GREEN:        equ 02h
COLOR_LIGHT_GREEN:  equ 03h
COLOR_BLUE:         equ 04h
COLOR_LIGHT_BLUE:   equ 05h
COLOR_DARK_RED:     equ 06h
COLOR_CYAN:         equ 07h
COLOR_RED:          equ 08h
COLOR_LIGHT_RED:    equ 09h
COLOR_YELLOW:       equ 0ah
COLOR_LIGHT_YELLOW: equ 0bh
COLOR_DARK_GREEN:   equ 0ch
COLOR_MAGENTA:      equ 0dh
COLOR_GRAY:         equ 0eh
COLOR_WHITE:        equ 0fh

; Sun Raster file
BITMAP_OFFSET:     equ 01820h    ; after header and color map (uncompressed only)
COLORMAP_OFFSET:   equ 00020h    ; after header (always)
HEADER_SIZE:       equ 32        ; 32 bytes in header
