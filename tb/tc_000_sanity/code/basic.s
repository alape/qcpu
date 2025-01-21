.text
    _start:     ld r0, 0
                ld r1, 0xAAAA
                ld r2, 0xBBBB
                ld r3, 0xCCCC
                ld r4, 0xDDDD
                ld r5, 0xEEEE
                ld r6, 0xFFFF
                ld r7, 0x1111

    addproc:    add r0, r0, 1
                jmp addproc
