; XModem Receiver for 6502 + 6551 UART
; Program location: $C000
; Receive buffer: $0300
; UART base: $8400

; 6551 Register addresses
UART_DATA   = $8400
UART_STATUS = $8401
UART_CMD    = $8402
UART_CTRL   = $8403

; XModem constants
SOH         = $01
EOT         = $04
ACK         = $06
NAK         = $15
CAN         = $18

; Zero page variables
DEST_ADDR_L = $85
DEST_ADDR_H = $86
BLOCK_NUM   = $80
BLOCK_INV   = $81
CHECKSUM    = $82
RX_COUNT    = $83
CHKSUM_RX   = $84
BLOCK_COUNT = $87

        ORG $C000

START:
        ; Control register: 8 bits, 1 stop bit, no parity, 19200 baud
        LDA #$1F
        STA UART_CTRL

        ; Command register
        LDA #$0B
        STA UART_CMD

        ; Short startup delay
        LDX #$20
INIT_DELAY:
        DEX
        BNE INIT_DELAY

        ; Initialize receive address to $0300
        LDA #$00
        STA DEST_ADDR_L
        LDA #$03
        STA DEST_ADDR_H
        LDA #$00
        STA BLOCK_COUNT

        ; Send initial NAK
        LDA #NAK
        JSR TX_CHAR

; $C020 - Main receive loop with timeout
        LDX #$FF
RECV_LOOP:
        LDY #$FF
RX_TIMEOUT:
        LDA UART_STATUS
        AND #$08
        BNE GOT_BYTE
        DEY
        BNE RX_TIMEOUT
        DEX
        BNE RECV_LOOP
        JMP $C01B           ; Timeout

; $C034
GOT_BYTE:
        LDA UART_DATA

        CMP #SOH
        BEQ RECV_BLOCK
        CMP #EOT
        BEQ XMODEM_DONE
        CMP #CAN
        BEQ XMODEM_ERROR

        JMP $C01B

; $C046
RECV_BLOCK:
        JSR RX_CHAR
        STA BLOCK_NUM

        JSR RX_CHAR
        STA BLOCK_INV

        LDA BLOCK_NUM
        EOR #$FF
        CMP BLOCK_INV
        BNE BAD_BLOCK

        LDA #$00
        STA CHECKSUM
        LDA #$00
        STA RX_COUNT

; $C060
DATA_LOOP:
        JSR RX_CHAR

        LDY RX_COUNT
        STA (DEST_ADDR_L),Y

        CLC
        ADC CHECKSUM
        STA CHECKSUM

        INC RX_COUNT
        LDA RX_COUNT
        CMP #$80
        BNE DATA_LOOP

        JSR RX_CHAR
        STA CHKSUM_RX

        LDA CHECKSUM
        CMP CHKSUM_RX
        BNE BAD_BLOCK

        CLC
        LDA DEST_ADDR_L
        ADC #$80
        STA DEST_ADDR_L
        LDA DEST_ADDR_H
        ADC #$00
        STA DEST_ADDR_H

        INC BLOCK_COUNT

        LDA #ACK
        JSR TX_CHAR
        JMP $C09E

; $C096
BAD_BLOCK:
        LDA #NAK
        JSR TX_CHAR
        JMP $C09E

; $C09E - Second timeout recv loop (after ACK/NAK)
        ORG $C09E
        LDX #$FF
RECV_LOOP2:
        LDY #$FF
RX_TIMEOUT2:
        LDA UART_STATUS
        AND #$08
        BNE GOT_BYTE        ; Branch to $C034
        DEY
        BNE RX_TIMEOUT2
        DEX
        BNE RECV_LOOP2
        JMP $C01B

; $C0B2
XMODEM_DONE:
        LDA #ACK
        JSR TX_CHAR

        LDX #$FF
DELAY:  DEX
        BNE DELAY

        JMP $0300

; $C0BF
XMODEM_ERROR:
        JMP $C0BF           ; Self-loop (infinite)

; $C0C2
RX_CHAR:
RX_WAIT:
        LDA UART_STATUS
        AND #$08
        BEQ RX_WAIT
        LDA UART_DATA
        RTS

; $C0CD
TX_CHAR:
        PHA
TX_WAIT:
        LDA UART_STATUS
        AND #$10
        BEQ TX_WAIT
        PLA
        STA UART_DATA
        RTS

        NOP
        NOP
        NOP
        NOP
        NOP
        NOP