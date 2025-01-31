;; (c) 2019 Alexander Sharikhin
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

    DEVICE ZXSPECTRUM128
    org    24100

start:
    di
    res    4, (iy+1)            ; Indicate we're in +3 mode so motor ticker runs
    ld     sp, stack_pointer    ; Move stack out of the way for +3DOS paging
    xor    a
    ld     (#5c6a), a           ; Thank you, Mario Prato, for feedback
    out    (#fe), a             ; Black border
    call   changeBank           ; Bank 0 to top
    jp     zx48start

    ds     128
stack_pointer = $ - 1

zx48start:
    ei

    call   clearScreen
    call   initDos
    call   loadWiFiConfig
    call   initWifi

    ld     a, 4                 ; Green border for success if we get here
    out    (-2), a
    di                          ; Halt forever
    jr     $

    include "screen42.asm"
    include "font42.asm"
    include "utils.asm"
    include "ring.asm"
    include "p3dos.asm"
    include "wifi.asm"
    include "prtwifi.asm"

waitSec:
    ei
    ld      b, 50
1:  halt
    djnz    1B
    ret

; Stubs to keep code happy (as we've removed all the gopher / render related code)

closedCallback:
    ret

showType:
    ret

cursor_pos:
    db 0

open_lbl:
    db     'Opening connection to ', 0

page_buffer equ $
    display "PAGE buffer:", $

eop equ $
    SAVE3DOS "build/debug.bin", start, $ - start

