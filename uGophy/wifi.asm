; Initialize WiFi chip and connect to WiFi
initWifi
    call    uartBegin
    ld      hl, cmd_rst
    call    uartWriteStringZ

    ld      hl, connectTo
    call    putStringZ
    call    mvCR

1
    ; Flush ESP TX buffer
    call    uartBegin

    ; WiFi client mode
    ld      hl, cmd_mode
    call    okErrCmd
    and     1
    jr      z, errInit

    ; Disable ECHO. BTW Basic UART test
    ld      hl, cmd_at
    call    okErrCmd
    and     1
    jr      z, errInit

    ; Lets disconnect from last AP
    ld      hl, cmd_cwqap
    call    okErrCmd
    and     1
    jr      z, errInit

    ; Single connection mode
    ld      hl, cmd_cmux
    call    okErrCmd
    and     1
    jr      z, errInit

    ; FTP enables this info? We doesn't need it :-)
    ld      hl, cmd_inf_off
    call    okErrCmd
    and     1
    jr      z, errInit

; Access Point connection
    ld      hl, cmd_cwjap1
    call    uartWriteStringZ
    ld      hl, ssid
    call    uartWriteStringZ
    ld      hl, cmd_cwjap2
    call    uartWriteStringZ
    ld      hl, pass
    call    uartWriteStringZ
    ld      hl, cmd_cwjap3
    call    okErrCmd

    and 1 :jr z, errInit

    ld hl, log_ok : call putStringZ
    ld   a, 4
    out  (-2), a

    ret

errInit
    ld hl, log_err : call putStringZ
    ld   a, 3
    out  (-2), a
    jr $


; Send AT-command and wait for result.
; HL - Z-terminated AT-command(with CR/LF)
; A:
;    1 - Success
;    0 - Failed
okErrCmd
    call    uartWriteStringZ
okErrCmdLp
    call    uartReadBlocking
    call    pushRing

    ld      hl, response_ok
    call    searchRing
    jr      c, okErrOk
    ld      hl, response_err
    call    searchRing
    jr      c, okErrErr
    ld      hl, response_fail
    call    searchRing
    jr      c, okErrErr

    jp      okErrCmdLp
okErrOk
    ld      a, 1
    ret
okErrErr
    xor     a
    ret

; Gets packet from network
; packet will be in var 'output_buffer'
; received packet size in var 'bytes_avail'
;
; If connection was closed it calls 'closed_callback'
getPacket
    call    uartReadBlocking
    cp      '+'
    jr      z, .checkIpdStart
    cp      'O'
    jr      z, .checkClosed
    jr      getPacket

.readPacket
    call    count_ipd_length
    ld      (bytes_avail), hl
    push    hl
    pop     bc                      ; BC = byte count

    ld      hl, output_buffer
.readByte
    push bc
    push hl
    call uartReadBlocking
    pop  hl
    ld   (hl), a
    pop  bc

    inc  hl
    dec  bc

    ld   a, b
    or   c
    jr   nz, .readByte

    ret

.checkIpdStart
    call uartReadBlocking : cp 'I' : jr nz, getPacket
    call uartReadBlocking : cp 'P' : jr nz, getPacket
    call uartReadBlocking : cp 'D' : jr nz, getPacket
    call uartReadBlocking ; Comma
    jr   .readPacket

.checkClosed
    call uartReadBlocking : cp 'S' : jr nz, getPacket
    call uartReadBlocking : cp 'E' : jr nz, getPacket
    call uartReadBlocking : cp 'D' : jr nz, getPacket
    call uartReadBlocking : cp 13  : jr nz, getPacket
    jp   closed_callback

count_ipd_length
    ld   hl, 0          ; count length
1:  push hl
    call uartReadBlocking
    push af
    call pushRing
    pop  af
    pop  hl
    cp   ':'
    ret  z

    call atoi2
    jr   1B

loadWiFiConfig:
    IFDEF   PLUS3DOS
    ld      hl, conf_file
    ld      c, ACCESS_MODE_EXCLUSIVE_READ
    ld      d, CREATE_ACTION_DONTCREATE
    ld      e, OPEN_ACTION_POSITION_TO_DATA
    call    fopen
    ld      c, 0
    ld      de, 160
    ld      hl, ssid
    call    fread
    call    fclose
    ENDIF

    IFDEF   ESXDOS
    ld      b, FMODE_READ
    ld      hl, conf_file
    call    fopen
    push    af
    ld      hl, ssid
    ld      bc, 160
    call    fread
    pop     af
    call    fclose
    ENDIF
    ret

cmd_setBaud defb "AT+UARTCUR=57600,8,1,0,2", 13, 10, 0
cmd_rst     defb "AT+RST",13, 10, 0
cmd_at      defb "ATE0", 13, 10, 0                  ; Disable echo - less to parse
cmd_mode    defb "AT+CWMODE_DEF=1",13,10,0          ; Client mode
cmd_cmux    defb "AT+CIPMUX=0",13,10,0              ; Single connection mode
cmd_cwqap   defb "AT+CWQAP",13,10,0                 ; Disconnect from AP
cmd_inf_off defb "AT+CIPDINFO=0",13,10,0            ; doesn't send me info about remote port and ip

cmd_cwjap1  defb  "AT+CWJAP_CUR=", #22,0        ;Connect to AP. Send this -> SSID
cmd_cwjap2  defb #22,',',#22,0                  ; -> This -> Password
cmd_cwjap3  defb #22, 13, 10, 0                 ; -> And this

cmd_open1   defb "AT+CIPSTART=", #22, "TCP", #22, ",", #22, 0
cmd_open2   defb #22, ",", 0
cmd_open3   defb 13, 10, 0
cmd_send    defb "AT+CIPSEND=", 0
cmd_close   defb "AT+CIPCLOSE",13,10,0
cmd_send_b  defb "AT+CIPSEND=1", 13, 10,0
closed      defb "CLOSED", 13, 10, 0
ipd         defb 13, 10, "+IPD,", 0

response_rdy        defb 'ready', 0
response_invalid    defb 'invalid', 0
response_ok         defb 'OK', 13, 10, 0      ; Sucessful operation
response_err        defb 13, 10, 'ERROR', 13, 10, 0      ; Failed operation
response_fail       defb 13, 10, 'FAIL', 13, 10, 0       ; Failed connection to WiFi. For us same as ERROR

log_err defb 13, 'Failed connect to WiFi!', 13, 0
log_ok  defb 13, 'WiFi connected!', 13, 0

connectTo   db 'Connecting to '

ssid defs 80
pass defs 80

bytes_avail   defw 0
sbyte_buff     defb 0, 0

send_prompt defb ">",0
output_buffer defs 4096 ; buffer for downloading data

; WiFi configuration
    IFDEF PLUS3DOS
conf_file defb "iw.cfg",0
    ENDIF

    IFDEF ESXDOS
conf_file defb "/sys/config/iw.cfg",0
    ENDIF
