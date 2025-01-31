    device ZXSPECTRUM128

    org 0

start:
    ld   a, 'A'
    call pushRing
    ld   a, 'B'
    call pushRing
    ld   a, 'C'
    call pushRing

    ld   hl, searchStr
    defb 0xED, 0xFF
    call searchRing
    ret

    include "../ring.asm"

searchStr:
    defb "ABC", 0

end:

    savebin "ringtest.bin", start, end-start
