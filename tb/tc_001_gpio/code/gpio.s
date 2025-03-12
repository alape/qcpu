.text
    _start:     ld r0, 0
                ld r1, $loop
                st r0, @0x203  ; gpio.MODEBUF=0
                st r0, @0x202  ; gpio.OBUF=0

    loop:       add r0, r0, 1
                st r0, @0x202
                blt r1, r0, 0xFF
                
                ld r0, 0
                jmp loop
