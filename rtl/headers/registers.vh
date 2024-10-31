`ifndef REGISTERS_VH_
`define REGISTERS_VH_

// special registers
parameter REG_ZEROES_ADDR = 4'h0;
parameter REG_ONES_ADDR = 4'h1;
parameter REG_PC_ADDR = 4'h2;
parameter REG_SC_ADDR = 4'h3;

// general-purpose registers
parameter REG_R0_ADDR = 4'h8;
parameter REG_R1_ADDR = 4'h9;
parameter REG_R2_ADDR = 4'hA;
parameter REG_R3_ADDR = 4'hB;
parameter REG_R4_ADDR = 4'hC;
parameter REG_R5_ADDR = 4'hD;
parameter REG_R6_ADDR = 4'hE;
parameter REG_R7_ADDR = 4'hF;

`endif