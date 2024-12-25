`include "opcodes.vh"
`include "registers.vh"

`define PL_FETCH_INSTR_STAGE    3'b000
`define PL_EVAL_OPCODE_STAGE    3'b001
`define PL_EVAL_ADDR_STAGE      3'b010
`define PL_FETCH_OPERANDS_STAGE 3'b011
`define PL_EXECUTE_STAGE        3'b100
`define PL_WRITEBACK_STAGE      3'b101

module pipeline #(
    parameter DATA_WIDTH     = 32,
    parameter MEM_ADDR_WIDTH = 32,
    parameter REG_IDX_WIDTH  = 4,

    parameter STATE_WIDTH    = 3,

    parameter RESET_VECTOR   = 0
) (
    input clk_i,
    input reset_i,

    // bus
    output reg [DATA_WIDTH-1:0]     bus_data_o,
    input      [DATA_WIDTH-1:0]     bus_data_i,
    output reg [MEM_ADDR_WIDTH-1:0] bus_addr_o,
    output reg                      bus_rw_o,     // 1 for W, 0 for R
    output reg                      bus_enable_o
);

    // internal variables
    reg [STATE_WIDTH-1:0] stage;

    // operand storage
    reg [DATA_WIDTH-1:0] operand_1;
    reg [DATA_WIDTH-1:0] operand_2;

    // instruction storage
    reg [DATA_WIDTH-1:0] instruction;
    reg [4:0] opcode;
    reg [2:0] flavour;

    // PC advance flag
    reg pc_advance;

    // ALU outputs
    reg [DATA_WIDTH-1:0] alu_add_output;
    reg [DATA_WIDTH-1:0] alu_sub_output;
    reg [DATA_WIDTH-1:0] alu_and_output;
    reg [DATA_WIDTH-1:0] alu_or_output;
    reg [DATA_WIDTH-1:0] alu_xor_output;
    reg [DATA_WIDTH-1:0] alu_not_output;
    reg [DATA_WIDTH-1:0] alu_lsh_output;
    reg [DATA_WIDTH-1:0] alu_rsh_output;

    // stage output
    reg [DATA_WIDTH-1:0] stage_output;
    
    // register file
    reg [DATA_WIDTH-1:0] registers [0:15];
    
    // reset registers
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) registers[i] = 'h0;
        
        registers[`REG_ZEROES_ADDR] = 'h0;
        registers[`REG_ONES_ADDR] = 32'hFFFF;
    end

    // ALU logic
    always @(*) begin
        alu_add_output <= operand_1 + operand_2;
        alu_sub_output <= operand_1 - operand_2;
        alu_and_output <= operand_1 & operand_2;
        alu_or_output <= operand_1 | operand_2;
        alu_xor_output <= operand_1 ^ operand_2;
        alu_not_output <= ~operand_1;
        alu_lsh_output <= operand_1 << operand_2;
        alu_rsh_output <= operand_2 >> operand_2;
    end

    // reset and stage advance logic
    always @(posedge clk_i) begin
        if (reset_i) begin
            // reset the stage counter and output regs
            stage = `PL_FETCH_INSTR_STAGE;
            bus_data_o = 32'b0;
            bus_addr_o = 32'b0;
            bus_rw_o = 1'b0;
            bus_enable_o = 1'b0;
            operand_1 = 32'b0;
            operand_2 = 32'b0;
            pc_advance = 1'b1;
            
            // load reset vector into PC
            registers[`REG_PC_ADDR] = RESET_VECTOR;
        end else begin
            // advance stage
            case (stage)
                `PL_FETCH_INSTR_STAGE: begin
                    // prepare to fetch instruction from memory by PC
                    bus_addr_o = registers[`REG_PC_ADDR];
                    bus_rw_o = 1'b0;
                    bus_enable_o = 1'b1;

                    // advance stage
                    stage = `PL_EVAL_OPCODE_STAGE;
                end

                `PL_EVAL_OPCODE_STAGE: begin
                    // fetch instruction from memory
                    instruction = bus_data_i;
                    bus_enable_o = 1'b0;

                    // slice out the opcode and flavour
                    opcode = instruction[28:24];
                    flavour = instruction[31:29];

                    // advance stage:
                    //     - skip `PL_EVAL_ADDR_STAGE if instruction is not F-, E- or A-flavoured
                    //     - skip both `PL_EVAL_ADDR_STAGE and `PL_FETCH_OPERANDS_STAGE if instruction is N-flavoured
                    case (flavour)
                        `FLAVOUR_A, `FLAVOUR_E, `FLAVOUR_F: begin
                            stage = `PL_EVAL_ADDR_STAGE;
                        end

                        `FLAVOUR_N: begin
                            stage = `PL_EXECUTE_STAGE;
                        end

                        default: begin
                            stage = `PL_FETCH_OPERANDS_STAGE;
                        end
                    endcase
                end

                `PL_EVAL_ADDR_STAGE: begin
                    // only invoked if instruction is F-, A- or E-flavoured 
                    // (i.e. needs to fetch operands from memory)
                    
                    // set memory address to be fetched:
                    case (flavour)
                        `FLAVOUR_A: begin
                            // if A-flavoured, use argument as straight address
                            bus_addr_o = instruction[19:0];
                        end

                        `FLAVOUR_E: begin
                            // if E-flavoured, fetch PC and add offset to it
                            bus_addr_o = registers[`REG_PC_ADDR] + instruction[19:0];
                        end

                        `FLAVOUR_F: begin
                            // if F-flavoured, fetch register referenced by instruction argument
                            bus_addr_o = registers[instruction[19:16]];
                        end
                    endcase

                    // enable bus read
                    bus_rw_o = 1'b0;
                    bus_enable_o = 1'b1;

                    // advance stage
                    stage = `PL_FETCH_OPERANDS_STAGE;
                end

                `PL_FETCH_OPERANDS_STAGE: begin
                    case (flavour)
                        `FLAVOUR_R: begin
                            // R flavour: both operands are fetched from registers
                            operand_1 = registers[instruction[19:16]];
                            operand_2 = registers[instruction[15:12]];
                        end

                        `FLAVOUR_I: begin
                            // I flavour: one operand is fetched from register, other is immediate
                            operand_1 = registers[instruction[19:16]];
                            operand_2 = instruction[15:0];
                        end

                        `FLAVOUR_S: begin
                            // S flavour: first operand is in the same register as destination, other operand
                            //            is immediate
                            operand_1 = registers[instruction[23:20]];
                            operand_2 = instruction[19:0]; 
                        end

                        `FLAVOUR_T: begin
                            // T flavour: only one operand is fetched from registers
                            operand_1 = registers[instruction[19:16]];
                        end

                        `FLAVOUR_F, `FLAVOUR_E, `FLAVOUR_A: begin
                            // F, E, A flavours: first operand is fetched from registers,
                            //                   second operand fetched from memory in previous stage
                            operand_1 = registers[instruction[23:20]];
                            operand_2 = bus_data_i;

                            bus_enable_o = 1'b0;
                        end
                    endcase

                    // advance stage
                    stage = `PL_EXECUTE_STAGE;
                end

                `PL_EXECUTE_STAGE: begin
                    case (opcode)
                        `OPCODE_ADD: begin
                            // ADD: patch through the ALU output
                            stage_output = alu_add_output;
                        end

                        `OPCODE_SUB: begin
                            // SUB: patch through the ALU output
                            stage_output = alu_sub_output;
                        end

                        `OPCODE_AND: begin
                            // AND: patch through the ALU output
                            stage_output = alu_and_output;
                        end

                        `OPCODE_OR: begin
                            // OR: patch through the ALU output
                            stage_output = alu_or_output;
                        end

                        `OPCODE_XOR: begin
                            // ADD: patch through the ALU output
                            stage_output = alu_xor_output;
                        end

                        `OPCODE_LSH: begin
                            // LSH: patch through the ALU output
                            stage_output = alu_lsh_output;
                        end

                        `OPCODE_RSH: begin
                            // RSH: patch through the ALU output
                            stage_output = alu_rsh_output;
                        end

                        `OPCODE_NOT: begin
                            // NOT: patch through the ALU output
                            stage_output = alu_not_output;
                        end

                        `OPCODE_LD: begin
                            // LD: 
                            //   flavours F, E, A: load memory by address in operand_1 into destination register
                            //   flavour S:        load immediate operand_2 into destination register
                            if (flavour == `FLAVOUR_S) begin
                                stage_output = operand_2;
                            end else begin
                                bus_addr_o = operand_1;
    
                                bus_rw_o = 1'b0;
                                bus_enable_o = 1'b1;
                            end
                        end

                        `OPCODE_ST: begin
                            // ST: store source register into memory by address operand_1
                            bus_addr_o = operand_1;
                            bus_data_o = registers[instruction[23:20]];

                            bus_rw_o = 1'b1;
                            bus_enable_o = 1'b1;
                        end

                        `OPCODE_JMP: begin
                            // JMP: load PC with operand_1's contents
                            pc_advance = 1'b0;

                            registers[`REG_PC_ADDR] = operand_1;
                        end
                    endcase

                    // advance stage
                    stage = `PL_WRITEBACK_STAGE;
                end

                `PL_WRITEBACK_STAGE: begin
                    // finish the memory access operations
                    case (opcode)
                        `OPCODE_LD: begin
                            if (flavour != `FLAVOUR_S) begin
                                registers[instruction[23:20]] = bus_data_i;
                            end
                        end
                    endcase
                    
                    // write stage output to destination (if necessary)
                    case (flavour)
                        `FLAVOUR_R, `FLAVOUR_I, `FLAVOUR_S, `FLAVOUR_T: begin
                            registers[instruction[23:20]] = stage_output;
                        end
                    endcase
                
                    // advance PC (if needed), reset memory enable flags and reset stage pointer
                    if (pc_advance) begin
                        registers[`REG_PC_ADDR] = registers[`REG_PC_ADDR] + 1'b1;
                    end else begin
                        pc_advance = 1'b1;
                    end

                    bus_enable_o = 1'b0;

                    stage = `PL_FETCH_INSTR_STAGE;
                end

                default: begin
                    stage = `PL_FETCH_INSTR_STAGE;
                end
            endcase
        end
    end

    // stages themselves
endmodule
