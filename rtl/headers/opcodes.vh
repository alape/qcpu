`ifndef OPCODES_VH_
`define OPCODES_VH_

`define OPCODE_NOP 5'h00
`define OPCODE_ADD 5'h01
`define OPCODE_SUB 5'h02
`define OPCODE_AND 5'h03
`define OPCODE_OR  5'h04
`define OPCODE_XOR 5'h05
`define OPCODE_LSH 5'h06
`define OPCODE_RSH 5'h07
`define OPCODE_NOT 5'h08
`define OPCODE_LD  5'h09
`define OPCODE_ST  5'h0A
`define OPCODE_BEQ 5'h0B
`define OPCODE_BNE 5'h0C
`define OPCODE_BGT 5'h0D
`define OPCODE_BLT 5'h0E
`define OPCODE_JMP 5'h0F
`define OPCODE_JAL 5'h10
`define OPCODE_RET 5'h11
`define OPCODE_PSH 5'h12
`define OPCODE_POP 5'h13

`define FLAVOUR_N 3'h0
`define FLAVOUR_R 3'h1
`define FLAVOUR_I 3'h2
`define FLAVOUR_S 3'h3
`define FLAVOUR_Q 3'h4
`define FLAVOUR_F 3'h5
`define FLAVOUR_E 3'h6
`define FLAVOUR_A 3'h7

`endif