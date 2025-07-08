.text
    _start:     ld sc, $stack           ; initialize stack

                ld r0, 15               ; SIZE - 1
                ld r1, 16               ; SIZE

                jmp line

    putc:       lsh r2, 24              ; putc(r2): outputs r2 contents (single byte in LSB) via SIMIO
                st r2, 0x201
                ret

    line:       ld r3, 0
                ld r4, $indentloop
    
    indentloop: ld r2, 0x20             ; ---------- INDENT CURRENT LINE
                jal putc

                add r3, r3, 1
                blt r4, r3, r0

                ld r3, 0
    plot:       add r4, r3, r1

                and r5, r3, r0
                ld r6, $plotgt
                bgt r6, r5, 0

                ld r2, 0x2A
                jal putc
                ld r2, 0x20
                jal putc
                jmp plotend

    plotgt:     ld r2, 0x20
                jal putc
                ld r2, 0x20
                jal putc
    
    plotend:    ld r6, $plot
                blt r6, r4, r1

                ld r2, 0xA              ; ---------- END CURRENT LINE
                jal putc

                sub r0, r0, 1           ; decrease SIZE and start loop() again
                ld r4, $line
                bgt r4, r0, 0

    end:        nop
                jmp end

.bss
    stack:      word 0
