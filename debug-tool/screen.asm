SECTION CODE

; TODO: Merge clearlines.s + scroll.s in to this file

public init_border
public cls
public cls_lower
public clearline
public print_hex
public _PrintHex
public _PrintHex8
public border_c
public paper_c
public xy_to_paddr
public xy_to_aaddr

extern line_address2
extern clearlines

defc i_black   = %00000000
defc i_blue    = %00000001
defc i_red     = %00000010
defc i_magenta = %00000011
defc i_green   = %00000100
defc i_cyan    = %00000101
defc i_yellow  = %00000110
defc i_white   = %00000111

defc p_black   = %00000000
defc p_blue    = %00001000
defc p_red     = %00010000
defc p_magenta = %00011000
defc p_cyan    = %00100000
defc p_green   = %00101000
defc p_yellow  = %00110000
defc p_white   = %00111000

; TODO: Make these variables

; Dark
defc border_c    = i_blue
defc paper_c     = p_blue
defc screen_attr = i_white + paper_c

; Light
;defc border_c    = i_white
;defc paper_c     = p_white
;defc screen_attr = i_black + paper_c

init_border:
    ld   a, border_c
    and  7
    out  (0xfe), a
    ret

; B = line, 0 == top, 24 == bottom
clearline:
    call line_address2
    ld   c, 8
cl_outer:
    ld   b, 32
cl_inner:
    ld   (hl), 0
    inc  hl
    djnz cl_inner

    ld   de, 255
    add  hl, de
    dec  c
    ld   a, c
    or   a
    jr   nz, cl_outer

    ret

cls_lower:
    ld    b, 22                   ; Clear the bottom lines of the screen
    call  clearlines
    ret

cls:
	ld   hl, 16384  		      ; Clear screen bitmap area
	ld   de, 16385
	ld   bc, 6144
	xor  a
	ld   (hl),a
	ldir

cls_attribs:
    ld   hl, 22528
	ld   bc, 768  			      ; Clear attributes to ...
	ld   a,  screen_attr     	  ; ...black paper, white ink
	ld   (hl), a
	ldir

	ret

PrintHex8:
_PrintHex8:
; L = Number to print
print_hex_8:
_printHex8:
    push   af
    ld     a, l
    call   print_hex_n1
    ld     a, l
    call   print_hex_n2
    pop    af
    ret

; C Entry point
; extern void printHex(u16 value) __z88dk_fastcall;
_PrintHex:
_PrintHex16:

; Assembly entry point
; HL = Number to print
; From: http://map.grauw.nl/sources/external/z80bits.html#5.2
print_hex:
    push   af
    ld     a, h
    call   print_hex_n1
    ld     a, h
    call   print_hex_n2
    ld     a, l
    call   print_hex_n1
    ld     a, l
    call   print_hex_n2
    pop    af
    ret

print_hex_n1:
    rra
    rra
    rra
    rra
print_hex_n2:
    or   0xF0
    daa
    add  a, 0xA0
    adc  a, 0x40
    rst  16
    ret

; Clear a row of pixels
; h = row
clearrow:
    xor  a
    ld   l, a
    call xy_to_paddr
    ld   bc, 256
    ld   de, hl
    inc  e
    xor  a
    ld   (hl), a
    ldir
    ret

; enter : h = valid character y coordinate
;         l = valid character x coordinate
;
; exit  : hl = screen address corresponding to the top
;              pixel row of the character square
;
; uses  : af, hl
xy_to_paddr:
   ld   a, h

   rrca
   rrca
   rrca
   and  0xe0
   or   l
   ld   l, a

   ld   a, h
   and  0x18
   or   0x40

   ld   h, a
   ret

; enter : h = valid character y coordinate
;         l = valid character x coordinate
;
; exit  : hl = attribute address corresponding to character
;
; uses  : af, hl
xy_to_aaddr:
   ld   a, h
   rrca
   rrca
   rrca
   ld   h, a

   and  0xe0
   or   l
   ld   l, a

   ld   a, h
   and  0x03
   or   0x58

   ld   h, a
   ret
