bankm   equ 23388

    IFNDEF ZX48
; This routine checks availability of extended(128K) memory.
; Output:
; Flag: Z - High memory available
checkHighMem:
    xor a : call changeBank : ld hl, #c000 : xor a : ld (hl), a ; Let's write in zero page zero value
    inc a : call changeBank : ld a, 13 : ld (hl), a             ; In other page - any other value. Let's write luck 13
    xor a : call changeBank : ld a, (hl) : and a                ; When we back to zero page - still there zero?!
    ret

; A - memory bank
changeBank:
    ld bc, #7ffd : or #18 : out (c), a : ld (bankm), a
    ret
    ENDIF

    IFNDEF SPECTRANET
; Pushes to UART zero-terminated string
; HL - string poiner
uartWriteStringZ:
    push hl
    call putStringZ
    pop  hl

    IFNDEF ZX48
    ld a, 7 : call changeBank
    ENDIF

1:  ld a, (hl) : and a : jr z, 2F
    push hl : call uartWriteByte : pop hl

    ld  a, r
    and 7
    out (-2), a

    inc hl
    jr 1B

2:  xor  a
    out  (-2), a
    ret
    ENDIF

; Print zero-terminated string
; HL - string pointer
putStringZ:
printZ64:
    IFNDEF ZX48
    ld a, 7 : call changeBank
    ENDIF
    ld   b, 41
1:
    ld   a, (hl) : and a : ret z
    push bc
    push hl : call putC : pop hl
    inc  hl
    pop  bc

    dec  b                              ; Limit string display length
    ld   a, b
    or   a
    ret  z
    jr  1B

printT64:
    ld   b, 41
1:
    xor  a : or b : ret z

    ld   a, (hl)

    and  a : ret z
    cp   09 : ret z

    push bc

    push hl : call putC : pop hl

    inc  hl : pop bc : dec b
    jr   1B

printL64:

    ld b, 41
.loop
    xor a : or b : ret z
    ld a, (hl)

    and a : ret z
    cp #0A : ret z
    cp #0D : ret z;

    push hl, bc : call putC : pop bc, hl
    dec b
    inc hl
    jr .loop

; HL - string
; Return: bc - len
getStringLength:
    ld bc, 0
strLnLp
    ld a, (hl)
    and a
    ret z
    inc bc
    inc hl
    jr strLnLp

SkipWhitespace:
    ld a, (hl)
    cp ' ' : ret nz
    inc hl
    jr SkipWhitespace

; DE <= StringZ
; HL => output
atoi:
    ld   hl, 0
1:  ld   a, (de)
    and  a  : ret z
    cp   13 : ret z
    cp   9  : ret z
    call atoi2
    inc  de
    jr 1B

atoi2:
    sub  0x30
    ld   c, l
    ld   b, h
    add  hl, hl
    add  hl, hl
    add  hl, bc
    add  hl, hl
    ld   c, a
    ld   b, 0
    add  hl, bc
    ret

;findEnd:
;    ld   a, (hl)
;    and  a
;    ret  z
;    inc  hl
;    jr   findEnd

;;;;;;;;;;;;;;;;;;;;;;;;

; Binary to decimal stuff
; From https://www.msx.org/forum/development/msx-development/32-bit-long-ascii

; Combined routine for conversion of different sized binary numbers into
; directly printable ASCII(Z)-string
; Input value in registers, number size and -related to that- registers to fill
; is selected by calling the correct entry:
;
;  entry  inputregister(s)  decimal value 0 to:
;   B2D8             A                    255  (3 digits)
;   B2D16           HL                  65535   5   "
;   B2D24         E:HL               16777215   8   "
;   B2D32        DE:HL             4294967295  10   "
;   B2D48     BC:DE:HL        281474976710655  15   "
;   B2D64  IX:BC:DE:HL   18446744073709551615  20   "
;
; The resulting string is placed into a small buffer attached to this routine,
; this buffer needs no initialization and can be modified as desired.
; The number is aligned to the right, and leading 0's are replaced with spaces.
; On exit HL points to the first digit, (B)C = number of decimals
; This way any re-alignment / postprocessing is made easy.
; Changes: AF,BC,DE,HL,IX
; P.S. some examples below

; by Alwin Henseler

B2D8:    LD H,0
         LD L,A
B2D16:   LD E,0
B2D24:   LD D,0
B2D32:   LD BC,0
B2D48:   LD IX,0          ; zero all non-used bits
B2D64:   LD (B2DINV),HL
         LD (B2DINV+2),DE
         LD (B2DINV+4),BC
         LD (B2DINV+6),IX ; place full 64-bit input value in buffer
         LD HL,B2DBUF
         LD DE,B2DBUF+1
         LD (HL)," "
B2DFILC: EQU $-1         ; address of fill-character
         LD BC,18
         LDIR            ; fill 1st 19 bytes of buffer with spaces
         LD (B2DEND-1),BC ;set BCD value to "0" & place terminating 0
         LD E,1          ; no. of bytes in BCD value
         LD HL,B2DINV+8  ; (address MSB input)+1
         LD BC,0x0909
         XOR A
B2DSKP0: DEC B
         JR Z,B2DSIZ     ; all 0: continue with postprocessing
         DEC HL
         OR (HL)         ; find first byte <>0
         JR Z,B2DSKP0
B2DFND1: DEC C
         RLA
         JR NC,B2DFND1   ; determine no. of most significant 1-bit
         RRA
         LD D,A          ; byte from binary input value
B2DLUS2: PUSH HL
         PUSH BC
B2DLUS1: LD HL,B2DEND-1  ; address LSB of BCD value
         LD B,E          ; current length of BCD value in bytes
         RL D            ; highest bit from input value -> carry
B2DLUS0: LD A,(HL)
         ADC A,A
         DAA
         LD (HL),A       ; double 1 BCD byte from intermediate result
         DEC HL
         DJNZ B2DLUS0    ; and go on to double entire BCD value (+carry!)
         JR NC,B2DNXT
         INC E           ; carry at MSB -> BCD value grew 1 byte larger
         LD (HL),1       ; initialize new MSB of BCD value
B2DNXT:  DEC C
         JR NZ,B2DLUS1   ; repeat for remaining bits from 1 input byte
         POP BC          ; no. of remaining bytes in input value
         LD C,8          ; reset bit-counter
         POP HL          ; pointer to byte from input value
         DEC HL
         LD D,(HL)       ; get next group of 8 bits
         DJNZ B2DLUS2    ; and repeat until last byte from input value
B2DSIZ:  LD HL,B2DEND    ; address of terminating 0
         LD C,E          ; size of BCD value in bytes
         OR A
         SBC HL,BC       ; calculate address of MSB BCD
         LD D,H
         LD E,L
         SBC HL,BC
         EX DE,HL        ; HL=address BCD value, DE=start of decimal value
         LD B,C          ; no. of bytes BCD
         SLA C           ; no. of bytes decimal (possibly 1 too high)
         LD A,"0"
         RLD             ; shift bits 4-7 of (HL) into bit 0-3 of A
         CP "0"          ; (HL) was > 9h?
         JR NZ,B2DEXPH   ; if yes, start with recording high digit
         DEC C           ; correct number of decimals
         INC DE          ; correct start address
         JR B2DEXPL      ; continue with converting low digit
B2DEXP:  RLD             ; shift high digit (HL) into low digit of A
B2DEXPH: LD (DE),A       ; record resulting ASCII-code
         INC DE
B2DEXPL: RLD
         LD (DE),A
         INC DE
         INC HL          ; next BCD-byte
         DJNZ B2DEXP     ; and go on to convert each BCD-byte into 2 ASCII
         SBC HL,BC       ; return with HL pointing to 1st decimal
         RET

AppendB2D:
; Append results of B2D to string at HL
    ex      de, hl  ; Get destination into DE
    ld      hl, B2DBUF
    call        SkipWhitespace
    ldir
    ex      de, hl  ; Get destination into DE
    ret

B2DINV:  DS 8            ; space for 64-bit input value (LSB first)
B2DBUF:  DS 20           ; space for 20 decimal digits
B2DEND:  DB 0 ; space for terminating 0
