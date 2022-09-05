; uncomment line below for TI99 font, comment out to use CP437 font
;#define TI99_FONT         

; if not using TI99 font, then use the CP437 font
#ifndef TI99_FONT            
#define CP437_FONT
#endif

; define constant for charset size 
#ifdef TI99_FONT
#define VDP_CHARSET_SIZE  95
#else
#define VDP_CHARSET_SIZE  256
#endif
