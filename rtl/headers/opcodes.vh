`ifndef OPCODES_VH_
`define OPCODES_VH_

parameter OPCODE_NOPN = 8'h00;
parameter OPCODE_ADDR = 8'h01;
parameter OPCODE_ADDI = 8'h02;
parameter OPCODE_SUBR = 8'h03;
parameter OPCODE_SUBI = 8'h04;
parameter OPCODE_ANDR = 8'h05;
parameter OPCODE_ANDI = 8'h06;
parameter OPCODE_ORR  = 8'h07;
parameter OPCODE_ORI  = 8'h08;
parameter OPCODE_XORR = 8'h09;
parameter OPCODE_XORI = 8'h0A;
parameter OPCODE_LSHS = 8'h0B;
parameter OPCODE_RSHS = 8'h0C;
parameter OPCODE_NOTT = 8'h0D;
parameter OPCODE_LDI  = 8'h0E;
parameter OPCODE_LDF  = 8'h0F;
parameter OPCODE_LDE  = 8'h10;
parameter OPCODE_LDA  = 8'h11;
parameter OPCODE_STF  = 8'h12;
parameter OPCODE_STE  = 8'h13;
parameter OPCODE_STA  = 8'h14;
parameter OPCODE_BEQF = 8'h15;
parameter OPCODE_BEQE = 8'h16;
parameter OPCODE_BEQA = 8'h17;
parameter OPCODE_BNEF = 8'h18;
parameter OPCODE_BNEE = 8'h19;
parameter OPCODE_BNEA = 8'h1A;
parameter OPCODE_BGTF = 8'h1B;
parameter OPCODE_BGTE = 8'h1C;
parameter OPCODE_BGTA = 8'h1D;
parameter OPCODE_BLEF = 8'h1E;
parameter OPCODE_BLEE = 8'h1F;
parameter OPCODE_BLEA = 8'h20;
parameter OPCODE_JMPF = 8'h21;
parameter OPCODE_JMPE = 8'h22;
parameter OPCODE_JMPA = 8'h23;
parameter OPCODE_JALF = 8'h24;
parameter OPCODE_JALE = 8'h25;
parameter OPCODE_JALA = 8'h26;
parameter OPCODE_RETN = 8'h27;

`endif