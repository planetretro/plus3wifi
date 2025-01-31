PAGE_LINES equ 22

showPage:
    xor a : ld (show_offset), a
    ld (cursor_pos), a

backToPage:
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF

    call renderScreen
    call showCursor

showLp:
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF

controls:
    xor a : ld (s_show_flag), a

1:  call inkey
    or   a
    jp   z, 1B

    cp 'q' : jp z, pageCursorUp
    cp 11  : jp z, pageCursorUp
    cp 'a' : jp z, pageCursorDown
    cp 10  : jp z, pageCursorDown
    cp 13  : jp z, selectItem
    cp ' ' : jp z, selectItem
;    cp 't' : jp z, toggleHalf
    cp 'b' : jp z, historyBack
    cp 'o' : jp z, pageScrollUp
    cp 8   : jp z, pageScrollUp
    cp 'p' : jp z, pageScrollDn
    cp 9   : jp z, pageScrollDn
    cp 'n' : jp z, openURI
    cp 'r' : jp z, reloadPage

    jp showLp

historyBack:
    ld hl, server : ld de, path : ld bc, port : call openPage
    jp showPage

pageCursorUp:
    ld   a, (cursor_pos)
    cp   0 : jp z, pageScrollUp
    dec  a
    jr   updateCursor

pageCursorDown:
    ld a, (cursor_pos)
    inc a
    cp PAGE_LINES : jp z, pageScrollDn

updateCursor:
    push af : call hideCursor : pop af : ld (cursor_pos), a : call showCursor
    jp showLp

pageScrollDn:
    ld   hl, (show_offset)
    ld   de, PAGE_LINES
    add  hl, de
    ld   (show_offset), hl

    ld   a, 0
    ld   (cursor_pos), a

    jp backToPage

pageScrollUp:
    ld a, (show_offset) : and a : jp z, showLp
    ld hl, (show_offset) : ld de, PAGE_LINES : sub hl, de : ld (show_offset), hl
    ld a, PAGE_LINES-1 : ld (cursor_pos), a

    jp backToPage

selectItem:
    call calcLineNumber
    call findLine

    ld   a, h
    or   l
    jp   z, showLp

    ld   a, (hl)

    cp '1' : jr z, downPg
    cp '0' : jr z, downPg
    cp '9' : jp z, downFl
    cp '7' : jr z, userInput
    jp showLp

userInput:
    call clearInputBuffer
    call input
    call extractInfo

    ld hl, file_buffer : call findZero : ld a, 9 : ld (hl), a : inc hl
    ex hl, de : ld hl, inputBuffer : ld bc, 64 : ldir
    ld hl, hist : ld de, path : ld bc, 322 : ldir
    ld hl, server_buffer : ld de, file_buffer : ld bc, port_buffer : call openPage

    jp showPage

downPg:
    push af
    call extractInfo

    ld hl, hist : ld de, path : ld bc, 322 : ldir

    ld hl, server_buffer : ld de, file_buffer : ld bc, port_buffer : call openPage

    pop af

    cp '1' : jp z, showPage
    cp '0' : jp z, showText

    jp showLp

downFl:
    call extractInfo : call clearRing : call clearInputBuffer
    ld hl, file_buffer : call findFnme : jp isOpenable

dfl:
    IFDEF SPECTRANET
    jp backToPage
    ELSE
    ld hl, file_buffer : call findFnme
    ld de, inputBuffer : ld bc, 65 : ldir

    call clearURI
    call input

    ld hl, inputBuffer : call showTypePrint

    ld hl, server_buffer : ld de, file_buffer : ld bc, port_buffer : call makeRequest
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF
    ld hl, inputBuffer : call downloadData

    call hideCursor : call showCursor

    jp backToPage
    ENDIF

isOpenable:
    ld a, (hl) : and a : jr z, checkFile
    push hl : call pushRing : pop hl
    inc hl
    jr isOpenable

imgExt  db ".scr", 0
imgExt2 db ".SCR", 0
    IFNDEF ZX48
pt3Ext  db ".pt3", 0
pt3Ext2 db ".PT3", 0
pt2Ext  db ".pt2", 0
pt2Ext2 db ".PT2", 0
    ENDIF

checkFile:
    ;; Images
    ld hl, imgExt  : call searchRing : jr c, loadImage
    ld hl, imgExt2 : call searchRing : jr c, loadImage

    IFNDEF ZX48
    ;; Music
    xor a: ld (#400A), a

    ld hl, pt3Ext  : call searchRing : jr c, playMusic
    ld hl, pt3Ext2 : call searchRing : jr c, playMusic

    ld a, 2 : ld (#400A), a

    ld hl, pt2Ext2 : call searchRing : jr c, playMusic
    ld hl, pt2Ext  : call searchRing : jr c, playMusic
    ENDIF

    ; Something else, jump to download
    jp dfl

loadImage:
    ld hl, server_buffer : ld de, file_buffer : ld bc, port_buffer : call makeRequest

    IFNDEF ZX48
    ld a, 7 : call changeBank
    ld hl, #c000
    ELSE
    ld hl, #4000
    ENDIF

    call loadData

    xor a

    IFDEF UNO
    out (#ff), a
    ENDIF

    out (#fe), a

    ld b, 255
wKey:
    halt
    ld a, (s_show_flag) : and a : jr z, wK2
    dec b  : jp z, startNext
wK2:
    call inkey
    or a   : jr z, wKey
    cp 's' : jr z, toggleSS
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF
    jp backToPage

toggleSS:
    ld a, (s_show_flag) : xor #ff : ld (s_show_flag), a
    and a : jp nz, startNext
    jp backToPage

    IFNDEF ZX48
playMusic:
    ld hl, hist : ld de, path : ld bc, 322 : ldir

    ld hl, (show_offset) : ld (offset_tmp), hl

    xor a : call changeBank
    ld hl, server_buffer : ld de, file_buffer : ld bc, port_buffer : call openPage

    ld hl, playing : call showTypePrint

    xor a : call changeBank

    ld a, (#400A) : or 1 : ld  (#400A), a
    ld hl, page_buffer : call #4003
playLp:
    halt : di : call #4005 : ei
    xor a : in a, (#fe) : cpl : and 31 : jp nz, stopPlay
    ld a, (#400A) : rla : jr nc, playLp
songEnded:
    call #4008
    IFNDEF SPECTRANET
    call uartBegin
    ENDIF

    ld hl, server : ld de, path : ld bc, port : call openPage

    ld hl, (offset_tmp) : ld (show_offset), hl
    ENDIF
startNext:
    ld a, (cursor_pos) : inc a : cp 21 : jr z, playNxtPg : ld (cursor_pos), a

    jr playContinue
playNxtPg:
    ld a, (show_offset) : add PAGE_LINES : ld (show_offset), a : ld a, 1 : ld (cursor_pos), a
playContinue:
    call renderScreen : call showCursor
    IFNDEF ZX48
    xor a : call changeBank
    ENDIF
    jp selectItem
    IFNDEF ZX48
stopPlay:
    call #4008

    IFNDEF SPECTRANET
    call uartBegin
    ENDIF

    ld hl, server : ld de, path : ld bc, port : call openPage
    ld hl, (offset_tmp) : ld (show_offset), hl

    jp backToPage
    ENDIF

findFnme:
    push hl : pop de
ffnmlp:
    ld a, (hl)

    cp 0 : jr z, ffnmend
    cp '/' : jr z, fslsh
    inc hl
    jp ffnmlp
fslsh:
    inc hl : push hl : pop de
    jp ffnmlp
ffnmend:
    push de : pop hl
    ret

showType:
    call  calcLineNumber
    call  findLine

    ld    a, h : or l : jr z, showTypeUnknown
    ld    a, (hl)

    push  af
    call  clearURI
    pop   af

    cp 'i' : jr z, showTypeInfo
    cp '0' : jr z, showTypeText
    cp '9' : jr z, showTypeDown
    cp '1' : jr z, showTypePage
    cp '7' : jr z, showTypeInput

    jr showTypeUnknown

showTypeInput:
    ld hl, type_inpt : call showTypePrint : call showURI
    ret

showTypeText:
    ld hl, type_text : call showTypePrint : call showURI
    ret

showTypePage:
    ld hl, type_page : call showTypePrint : call showURI
    ret

showTypeDown:
    ld hl, type_down : call showTypePrint : call showURI
    ret

showTypeInfo:
    ld hl, type_info : jp showTypePrint

clearURI:
    ld  b, 23 : call clearLine
    ret

showURI:
    ld b, 23 : call clearLine
    ld b, 23 : ld c, 0 : call gotoXY

    call extractInfo : ld hl, server_buffer : call printZ64
    ld hl, file_buffer : call printZ64
    ret

showTypeUnknown:
    ld hl, type_unkn : jp showTypePrint

showTypePrint:
    ret
;    push hl
;
;    ld   b, 23
;    call clearLine
;
;    ld   b, 23
;    ld   c, 0
;    call gotoXY
;    pop  hl
;    jp   printZ64
;    ret

renderScreen:
    call clearScreen
    ld   b, PAGE_LINES
1:
    push bc

    ld   a, PAGE_LINES
    sub  b
    ld   b, a
    ld   c, a                           ; C = Screen line
    ld   a, (show_offset)
    add  b
    ld   b, a                           ; B = Page line
    call renderLine

    pop  bc
    djnz 1B
    ret

; b - line number
; c - screen line
renderLine:
    call findLine
    ld   a, h
    or   l
    ret  z

    ld   a, (hl)
    and  a
    ret  z
    inc  hl

;    ld a, (s_half) : and a : call nz, skipHalf64
    call printT64
    call mvCR
    ret

; B - line number
; HL - pointer to line(or zero if doesn't find it)
findLine:
    ld   hl, page_buffer
1:
    ld   a, b
    and  a
    ret  z

    ld   a, (hl)                        ; End of buffer?
    and  a
    jr   z, .end

    cp   10                             ; New line?
    jr   z, .next

    inc  hl
    jp   1B

.next:
    dec  b
    inc  hl
    jp   1B

.end:
    ld   hl, 0
    ret

calcLineNumber
    ld   a, (cursor_pos)
    ld   b, a
    ld   a, (show_offset)
    add  b
    ld   b, a
    ret

extractInfo:
    call  calcLineNumber
    call  findLine

    ld a, h : or l : ret z

    call findNextBlock

    inc hl : ld de, file_buffer   : call extractCol
    inc hl : ld de, server_buffer : call extractCol
    inc hl : ld de, port_buffer   : call extractCol
    ret

extractCol:
    ld a, (hl)

    cp 0 : jr z, endExtract
    cp 09 : jr z, endExtract
    cp 13 : jr z, endExtract

    ld (de), a : inc de : inc hl
    jr extractCol

endExtract:
    xor a : ld (de), a
    ret

findNextBlock:
    ld   a, (hl)

    cp   09 : ret z
    cp   13 : ret z
    cp   0  : ret z

    inc  hl
    jp   findNextBlock

s_half          db  0
s_show_flag     db  0
offset_tmp      dw  0
show_offset     db  0
cursor_pos      db  0

    IFNDEF ZX48
          ;   |--------------------------------------------------------------|
head      db "UGophy - ZX-128 Gopher client v1.0 - (c) Alexander Sharikhin    ", 0
    ELSE
head      db "UGophy - ZX-48 Gopher client v1.0 - (c) Alexander Sharikhin     ", 0

    ENDIF

playing   db "Playing. Hold <SPACE> to stop.", 0
type_inpt db "User input: ", 0
type_text db "Text file: ", 0
type_info db "Information ", 0
type_page db "Page: ", 0
type_down db "Download: ", 0
type_unkn db "Unknown type ", 0

    display $

file_buffer   defs 255     ; URI path
server_buffer defs 70      ; Host name
port_buffer   defs 7       ; Port

end_inf_buff equ $
