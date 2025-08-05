.text
    _start:     ld sc, $stack
                ld r0, 0x403        ; VGI framebuffer base address

                ld r1, 0x4b         ; 0x4b << 12 + 0x400 = \
                lsh r1, 12          ;   640 * 480 + FB_BASE_ADDRESS
                or r1, r1, 0x400

                ld r2, $putpixel    ; loop vector

                ld r3, 0            ; current pixel colour
                ld r4, 0            ; pixel shift scratchpad

    putpixel:   ;st ones, r0         ; fill two pixels at a time to create a checkerboard pattern
                ;add r0, r0, 1
                ;st zeroes, r0
                ;add r0, r0, 1

                add r4, r3, 0
                lsh r4, 8
                st r4, r0
                add r3, r3, 0x36
                add r0, r0, 1

                blt r2, r0, r1      ; loop until all pixels are filled

    endloop:    nop                 ; when framebuffer is filled, enter endless loop
                jmp endloop

.bss
    stack:      word 0
