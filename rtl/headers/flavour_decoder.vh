`ifndef FLAVOUR_DECODER_VH_
`define FLAVOUR_DECODER_VH_

`include "opcodes.vh"

parameter FLAVOUR_N = 3'b0;
parameter FLAVOUR_R = 3'b1;
parameter FLAVOUR_I = 3'b10;
parameter FLAVOUR_S = 3'b11;
parameter FLAVOUR_T = 3'b100;
parameter FLAVOUR_F = 3'b101;
parameter FLAVOUR_E = 3'b110;
parameter FLAVOUR_A = 3'b111;

function [2:0] decode_flavour(input [7:0] opcode);
    begin
        case (opcode)
            OPCODE_NOPN, OPCODE_RETN: begin
                decode_flavour = FLAVOUR_N;
            end

            OPCODE_ADDR, OPCODE_SUBR, OPCODE_ANDR, OPCODE_ORR, OPCODE_XORR: begin
                decode_flavour = FLAVOUR_R;
            end

            OPCODE_ADDI, OPCODE_SUBI, OPCODE_ANDI, OPCODE_ORI, OPCODE_XORI, OPCODE_LDI: begin
                decode_flavour = FLAVOUR_I;
            end

            OPCODE_LSHS, OPCODE_RSHS: begin
                decode_flavour = FLAVOUR_S;
            end

            OPCODE_NOTT: begin
                decode_flavour = FLAVOUR_T;
            end

            OPCODE_LDF, OPCODE_STF, OPCODE_BEQF, OPCDOE_BNEF, OPCODE_BGTF, OPCODE_BLEF, OPCODE_JMPF, OPCODE_JALF: begin
                decode_flavour = FLAVOUR_F;
            end

            OPCODE_LDE, OPCODE_STE, OPCODE_BEQE, OPCDOE_BNEE, OPCODE_BGTE, OPCODE_BLEE, OPCODE_JMPE, OPCODE_JALE: begin
                decode_flavour = FLAVOUR_E;
            end

            OPCODE_LDA, OPCODE_STA, OPCODE_BEQA, OPCDOE_BNEA, OPCODE_BGTA, OPCODE_BLEA, OPCODE_JMPA, OPCODE_JALA: begin
                decode_flavour = FLAVOUR_A;
            end
        endcase
    end
endfunction

`endif