; Kernel vector for Video Driver
O_VIDEO:            equ 0456h

; Video Driver functions
V_SET_ADDRESS:      equ 00h
V_SET_GROUP:        equ 01h
V_RESET_GROUP:      equ 02h
V_WRITE_VREG:       equ 03h
V_FILL_VRAM:        equ 04h
V_WRITE_DATA:       equ 05h
V_FILL_SEQ:         equ 06h
V_WRITE_BYTE:       equ 07h
V_READ_STATUS:      equ 08h
V_WRITE_RLE:        equ 09h
V_GET_BYTE:         equ 0ah
V_SET_BYTE:         equ 0bh 
V_GET_INFO:         equ 0ch
V_SET_INFO:         equ 0dh
V_GET_VERSION:      equ 0eh 

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


; VDP Graphics Mode 2 addresses
V_VDP_MEMORY:       equ 4000h
V_BITMAP_PATTERN:   equ 4000h
V_CHAR_PATTERN:     equ 4000h 
V_COLOR_TABLE:      equ 6000h
V_NAME_TABLE:       equ 7800h
V_SPRITE_PATTERN:   equ 5800h
V_SPRITE_ATTRIB:    equ 7B00h
V_CHAR_NAMES:       equ 4800h

; Other VDP constants
V_VDP_KEEP:         equ  00h 
V_VDP_RESET:        equ  0FFh

; Sun Raster file
BITMAP_OFFSET:      equ 01820h    ; after header and color map (uncompressed only)
COLORMAP_OFFSET:    equ 00020h    ; after header (always)
HEADER_SIZE:        equ 32        ; 32 bytes in header
