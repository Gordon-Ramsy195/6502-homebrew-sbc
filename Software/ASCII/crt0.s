.import         _main
        .export         __STARTUP__ : absolute = 1
        .import         initlib, donelib
        .import         zerobss
        .import         copydata
        .import         __RAM_START__, __RAM_SIZE__

        .include        "zeropage.inc"

        .segment        "STARTUP"

_start:
        ; Set hardware stack pointer
        ldx     #$FF
        txs

        ; Initialize cc65 zero-page virtual stack pointer (c_sp) at high end of RAM
        lda     #<(__RAM_START__ + __RAM_SIZE__)
        sta     c_sp
        lda     #>(__RAM_START__ + __RAM_SIZE__)
        sta     c_sp+1

        ; Initialize BSS and Data segments
        jsr     zerobss
        jsr     copydata
        jsr     initlib

        ; Call C main
        jsr     _main

        ; Clean up (if main ever returns)
        jsr     donelib
exit:
        jmp     exit