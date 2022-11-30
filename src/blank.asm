; -------------------------------------------------------------------
;                        blank
; 
; Program for a TMS9X18 Color Video Card driver and Elf/OS
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

#include    include/bios.inc
#include    include/kernel.inc
#include    include/ops.inc
#include    include/vdp.inc

            extrn checkVideo
            extrn beginG2Mode
            extrn setBackground
            extrn sendNames
            extrn clearInfo
            extrn endG2Mode
            
            org     2000h
blank:      br      main
            
            ; Build information                        
            db      11+80h             ; month
            db      30                 ; day
            dw      2022               ; year
            dw      3                  ; build
                        
            db      'Copyright 2022 by Gaston Williams',0                                    
            
main:       call checkVideo     ; verify vdp driver is loaded in memory
            lbdf no_driver
            
            ldi  V_VDP_CLEAR    ; clear vdp memory
            call beginG2Mode    ; start graphics mode 2
            
            ldi  COLOR_BLACK    ; D has background color
            call setBackground

            call sendNames
            
            call clearInfo      ; clear user info in memory
            
            ldi  V_VDP_KEEP     ; Set D to keep vdp display after exit
            call endG2Mode      ; end graphics mode 2
            
            rtn

no_driver:  call O_INMSG
            db 'TMS9X18 Video driver is not loaded.',10,13,0
            rtn
            
            end blank
