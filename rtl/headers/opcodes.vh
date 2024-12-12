`ifndef OPCODES_VH_
`define OPCODES_VH_

`define OPCODE_NOPN 8'h00
`define OPCODE_ADDR 8'h01
`define OPCODE_ADDI 8'h02
`define OPCODE_SUBR 8'h03
`define OPCODE_SUBI 8'h04
`define OPCODE_ANDR 8'h05
`define OPCODE_ANDI 8'h06
`define OPCODE_ORR  8'h07
`define OPCODE_ORI  8'h08
`define OPCODE_XORR 8'h09
`define OPCODE_XORI 8'h0A
`define OPCODE_LSHS 8'h0B
`define OPCODE_RSHS 8'h0C
`define OPCODE_NOTT 8'h0D
`define OPCODE_LDI  8'h0E
`define OPCODE_LDF  8'h0F
`define OPCODE_LDE  8'h10
`define OPCODE_LDA  8'h11
`define OPCODE_STF  8'h12
`define OPCODE_STE  8'h13
`define OPCODE_STA  8'h14
`define OPCODE_BEQF 8'h15
`define OPCODE_BEQE 8'h16
`define OPCODE_BEQA 8'h17
`define OPCODE_BNEF 8'h18
`define OPCODE_BNEE 8'h19
`define OPCODE_BNEA 8'h1A
`define OPCODE_BGTF 8'h1B
`define OPCODE_BGTE 8'h1C
`define OPCODE_BGTA 8'h1D
`define OPCODE_BLEF 8'h1E
`define OPCODE_BLEE 8'h1F
`define OPCODE_BLEA 8'h20
`define OPCODE_JMPF 8'h21
`define OPCODE_JMPE 8'h22
`define OPCODE_JMPA 8'h23
`define OPCODE_JALF 8'h24
`define OPCODE_JALE 8'h25
`define OPCODE_JALA 8'h26
`define OPCODE_RETN 8'h27

`define FLAVOUR_N 3'b0
`define FLAVOUR_R 3'b1
`define FLAVOUR_I 3'b10
`define FLAVOUR_S 3'b11
`define FLAVOUR_T 3'b100
`define FLAVOUR_F 3'b101
`define FLAVOUR_E 3'b110
`define FLAVOUR_A 3'b111

`endif