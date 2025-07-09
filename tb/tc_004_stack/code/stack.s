.text
    _start:     ld sc, $stack           ; initialize stack

                ; push message onto stack
                ld r0, 0x5354
                lsh r0, 16
                or r0, r0, 0x4143
                psh r0                  ; 0x53544143: "STAC"

                ld r0, 0x4B20
                lsh r0, 16
                or r0, r0, 0x5341
                psh r0                  ; 0x4B205341: "K SA"

                ld r0, 0x5953
                lsh r0, 16
                or r0, r0, 0x2048
                psh r0                  ; 0x59532048: "YS H"

                ld r0, 0x4900
                lsh r0, 16
                psh r0                  ; 0x49: "I"

                ld r0, 0                ; word counter
                ld r1, $stack           ; word pointer
                ld r2, $loop            ; loop() vector
                ld r3, r1               ; current word
                ld r4, 4                ; message length (in words)


    loop:       jal putw                ; output current word
                add r0, r0, 1           ; increment word counter and word pointer
                add r1, r1, 1

                ld r3, r1               ; load next word into R3
                
                blt r2, r0, r4          ; repeat if word counter is less than message length...
                jmp end                 ; ...otherwise, go into infinite loop


    putw:       ld r5, 0                ; byte counter (4 bytes per word)
                ld r6, $putwloop        ; loop vector
    putwloop:   st r3, @0x201            ; output current word via SIMIO (its first byte will be printed)

                lsh r3, 8               ; shift current word left by one byte
                add r5, r5, 1           ; increment byte counter

                blt r6, r5, 4           ; repeat loop if byte counter < 4 to output all bytes in current word

                ret                     ; exit procedure


    end:        nop                     ; infinite loop
                jmp end


.bss
    stack:           word 0
