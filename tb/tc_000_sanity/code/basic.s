.text
    _start:     ld r0, 0
                ld r1, 100
                ld r2, 0xAAAA
                ld r3, 0xBBBB
                ld r4, 0xCCCC
                ld r5, 0xDDDD
                ld r6, $addproc
                ld r7, $subproc

    addproc:    add r0, r0, 1
                blt r6, r0, 100
                
    subproc:    sub r1, r1, 1
                bgt r7, r1, 0

    loop:       nop
                jmp loop
