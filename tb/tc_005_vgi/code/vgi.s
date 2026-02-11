.text
    _start:     ld sc, $stack
                ld r7, 0x403        ; VGI framebuffer base address

                ld r2, 0xFFFF       ; set r2 (pixel colour) to 0xFFFFFF (100% white)
                lsh r2, 16
                or r2, r2, 0xFF00

                ld r0, 5
                ld r1, 5
                jal putpixel

                ld r0, 15
                jal putpixel

                ld r1, 15
                jal putpixel

                ld r0, 5
                jal putpixel

                jmp endloop


    putpixel:   ; update a pixel by specified coordinates in the VGI framebuffer:
                ;   r0: X coordinate,
                ;   r1: Y coordinate,
                ;   r2: colour (24bpp big-endian BGR)
                
                ; calculate pixel's linear coordinates (i.e. framebuffer offset):
                add r3, r7, r0          ; addr = base_addr + X

                ld r4, 0                ; X coordinate counter
                ld r5, $_ycalc          ; _ycalc() vector
                ld r6, $_wrpixel        ; _wrpixel() vector

                beq r6, r1, 0           ; if Y = 0, skip _ycalc()

                _ycalc:
                    add r3, r3, 0x280  ; addr = addr + 640 * X
                    add r4, r4, 1
                    blt r5, r4, r1

                _wrpixel:
                    st r2, r3          ; write pixel to the framebuffer

                ret 

    endloop:    nop                 ; when framebuffer is filled, enter endless loop
                jmp endloop

.bss
    stack:      word 0
