LASTK = 23560

; Returns in A key code or zero if key wans't pressed
inkey:
    halt
    ld   a, (LASTK)
    ld   b, a
    xor  a
    ld   (LASTK), a
    ld   a, b
    ret

waitkey:
    call inkey
    or   a
    ret  nz
    jr   waitkey

findZero:
    ld   a, (hl)
    or   a
    ret  z
    inc  hl
    jp   findZero

input:
    ld   hl, inputBuffer
    call findZero

inputLoop:
    push hl

    ld b, 23 : call clearLine
    ld b, 23 : ld c, 0 : call gotoXY

    ld   hl, inputBuffer
    call printZ64
    ld   a, '_'
    call putC
    
    call waitkey

    cp   12
    jr   z, inputBackspace

    cp   13
    jr   z, inputReturn

    pop  hl
    ld   (hl), a
    push hl
    inc  hl
    xor  a
    ld   (hl), a
    dec  hl

    ld   de, inputBuffer + 40
    sub  hl, de
    ld   a, h
    or   l
    jr   z, inputLoop
    
    pop  hl
    inc  hl
    jr   inputLoop

inputBackspace:
    pop  hl
    push hl
    ld   de, inputBuffer
    sub  hl, de
    ld   a, h
    or   l
    pop  hl
    jr   z, inputLoop
     
    dec  hl
    ld   (hl), 0
    jr   inputLoop

clearInputBuffer:
    xor  a
    ld   bc, 42
    ld   hl, inputBuffer
    ld   de, inputBuffer + 1
    ld   (hl), a
    ldir
    ret

inputReturn:
    ld   b, 20
    call clearLine
    pop hl
    ret

inputBuffer defs 43
