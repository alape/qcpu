.text
    _start:     ld sc, $stack           ; initialize stack
                ld iv, $irqhandler      ; initialize interrupt vector

                ld r0, $hello_text      ; output initial messages
                ld r1, hello_len
                jal puts

                ld r0, $wait_text
                ld r1, wait_len
                jal puts

                or sr, sr, 0x2          ; allow interrupts (set SR.IE flag)

                jmp end                 ; loop infinitely while waiting for interrupts

    irqhandler: ; handles an incoming interrupt
                ld r0, $irq_text        ; output interrupt message
                ld r1, irq_len
                jal puts

                st ir, $outc
                ld r0, $outc            ; output interrupt reason as a word
                ld r1, 1
                jal puts

                xor sr, sr, 0x4         ; mark interrupt as processed (reset SR.II flag)

                ret                     ; return from interrupt

    puts:       ; outputs a string via SIMIO: string pointer is r0, string length is r1
                ld r2, $putsloop        ; loop() vector
                ld r3, r0               ; current word
                ld r4, 0                ; word counter

        putsloop:   jal putw                ; output current word
                    add r4, r4, 1           ; increment word counter and word pointer
                    add r0, r0, 1

                    ld r3, r0               ; load next word into R3
                    
                    blt r2, r4, r1          ; repeat if word counter is less than message length...
                    ret                     ; ...otherwise, exit puts()


        putw:       ld r5, 0                ; byte counter (4 bytes per word)
                    ld r6, $putwloop        ; loop vector
        putwloop:   st r3, 0x201            ; output current word via SIMIO (its first byte will be printed)

                    lsh r3, 8               ; shift current word left by one byte
                    add r5, r5, 1           ; increment byte counter

                    blt r6, r5, 4           ; repeat loop if byte counter < 4 to output all bytes in current word

                    ret                     ; exit putw()


    end:        nop                     ; infinite loop
                jmp end


.data
    hello_text:     data "Hello, world!" 0xA
    hello_len:      word 0x4
    wait_text:      data "Waiting for an interrupt..." 0xA
    wait_len:       word 0x7
    irq_text:       data "An interrupt has occurred" 0xA
    irq_len:        word 0x7
    outc:           word 0x0

.bss
    stack:           word 0
