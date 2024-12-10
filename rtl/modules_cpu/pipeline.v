module pipeline #(
    parameter DATA_WIDTH     = 32,
    parameter MEM_ADDR_WIDTH = 32,
    parameter REG_IDX_WIDTH  = 4,

    parameter STATE_WIDTH    = 3,

    parameter PL_FETCH_INSTR_STAGE    = 3'b000,
    parameter PL_EVAL_OPCODE_STAGE    = 3'b001,
    parameter PL_EVAL_ADDR_STAGE      = 3'b010,
    parameter PL_FETCH_OPERANDS_STAGE = 3'b011,
    parameter PL_EXECUTE_STAGE        = 3'b100,
    parameter PL_WRITEBACK_STAGE      = 3'b101
) (
    input clk_i,
    input reset_i,

    // bus
    output reg [DATA_WIDTH-1:0]     bus_data_o,
    input      [DATA_WIDTH-1:0]     bus_data_i,
    output reg [MEM_ADDR_WIDTH-1:0] bus_addr_o,
    output reg                      bus_rw_o,     // 1 for W, 0 for R
    output reg                      bus_enable_o,

    // register file
    output reg                     reg_write_enable_o,
    output reg [DATA_WIDTH-1:0]    reg_write_data_o,
    output reg [REG_IDX_WIDTH-1:0] reg_write_addr_o,
    output reg [REG_IDX_WIDTH-1:0] reg_read_addr_1_o,
    output reg [REG_IDX_WIDTH-1:0] reg_read_addr_2_o,
    input      [DATA_WIDTH-1:0]    reg_read_data_1_i,
    input      [DATA_WIDTH-1:0]    reg_read_data_2_i
);
    `include "opcodes.vh"
    `include "registers.vh"
    `include "flavour_decoder.vh"

    // internal variables
    reg [STATE_WIDTH-1:0] stage;
    reg [STATE_WIDTH-1:0] next_stage;

    // operand storage
    reg [DATA_WIDTH-1:0] operand_1;
    reg [DATA_WIDTH-1:0] operand_2;

    // instruction storage
    reg [DATA_WIDTH-1:0] instruction;
    reg [7:0] opcode;
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
            stage <= PL_FETCH_INSTR_STAGE;
            bus_data_o <= 32'b0;
            bus_addr_o <= 32'b0;
            reg_write_data_o <= 32'b0;
            reg_write_addr_o <= 32'b0;
            reg_read_addr_1_o <= 32'b0;
            reg_read_addr_2_o <= 32'b0;
            operand_1 <= 32'b0;
            operand_2 <= 32'b0;
            pc_advance <= 1'b1;
        end else begin
            // advance stage
            case (stage)
                PL_FETCH_INSTR_STAGE: begin
                    // reset register WE flag
                    reg_write_enable_o = 1'b0;

                    // prepare to fetch PC
                    reg_read_addr_1_o = REG_PC_ADDR;
                    
                    // prepare to fetch instruction from memory by PC
                    bus_addr_o = reg_read_data_1_i;
                    bus_rw_o = 1'b0;
                    bus_enable_o = 1'b1;

                    // advance stage
                    stage = PL_EVAL_OPCODE_STAGE;
                end

                PL_EVAL_OPCODE_STAGE: begin
                    // fetch instruction from memory
                    instruction = bus_data_i;
                    bus_enable_o = 1'b0;

                    // slice out the opcode and decode the flavour
                    opcode = instruction[31:24];
                    flavour = decode_flavour(opcode);

                    // advance stage:
                    //     - skip PL_EVAL_ADDR_STAGE if instruction is not F-, E- or A-flavoured
                    //     - skip both PL_EVAL_ADDR_STAGE and PL_FETCH_OPERANDS_STAGE if instruction is N-flavoured
                    case (flavour)
                        FLAVOUR_A, FLAVOUR_E, FLAVOUR_F: begin
                            stage = PL_EVAL_ADDR_STAGE;
                        end

                        FLAVOUR_N: begin
                            stage = PL_EXECUTE_STAGE;
                        end

                        default: begin
                            stage = PL_FETCH_OPERANDS_STAGE;
                        end
                    endcase
                end

                PL_EVAL_ADDR_STAGE: begin
                    // only invoked if instruction is F-, A- or E-flavoured 
                    // (i.e. needs to fetch operands from memory)
                    
                    // set memory address to be fetched:
                    case (flavour)
                        FLAVOUR_A: begin
                            // if A-flavoured, use argument as straight address
                            bus_addr_o = instruction[19:0];
                        end

                        FLAVOUR_E: begin
                            // if E-flavoured, fetch PC and add offset to it
                            reg_read_addr_1_o = REG_PC_ADDR;

                            bus_addr_o = reg_read_data_1_i + instruction[19:0];
                        end

                        FLAVOUR_F: begin
                            // if F-flavoured, fetch register referenced by instruction argument
                            reg_read_addr_1_o = instruction[19:16];

                            bus_addr_o = reg_read_data_1_i;
                        end
                    endcase

                    // enable bus read
                    bus_rw_o = 1'b0;
                    bus_enable_o = 1'b1;

                    // advance stage
                    stage = PL_FETCH_OPERANDS_STAGE;
                end

                PL_FETCH_OPERANDS_STAGE: begin
                    case (flavour)
                        FLAVOUR_R: begin
                            // R flavour: both operands are fetched from registers
                            reg_read_addr_1_o = instruction[19:16];
                            reg_read_addr_2_o = instruction[15:12];

                            operand_1 = reg_read_data_1_i;
                            operand_2 = reg_read_data_2_i;
                        end

                        FLAVOUR_I: begin
                            // I flavour: one operand is fetched from register, other is immediate
                            reg_read_addr_1_o = instruction[19:16];
                            
                            operand_1 = reg_read_data_1_i;
                            operand_2 = instruction[15:0];
                        end

                        FLAVOUR_S: begin
                            // S flavour: first operand is in the same register as destination, other operand
                            //            is immediate
                            reg_read_addr_1_o = instruction[23:20];

                            operand_1 = reg_read_data_1_i;
                            operand_2 = instruction[19:0]; 
                        end

                        FLAVOUR_T: begin
                            // T flavour: only one operand is fetched from registers
                            reg_read_addr_1_o = instruction[19:16];

                            operand_1 = reg_read_data_1_i;
                        end

                        FLAVOUR_F, FLAVOUR_E, FLAVOUR_A: begin
                            // F, E, A flavours: first operand is fetched from registers,
                            //                   second operand fetched from memory in previous stage
                            reg_read_addr_1_o = instruction[23:20];

                            operand_1 = reg_read_data_1_i;
                            operand_2 = bus_data_i;

                            bus_enable_o = 1'b0;
                        end
                    endcase

                    // advance stage
                    stage = PL_EXECUTE_STAGE;
                end

                PL_EXECUTE_STAGE: begin
                    case (opcode)
                        OPCODE_ADDI, OPCODE_ADDR: begin
                            // ADD: patch through the ALU output
                            stage_output = alu_add_output;
                        end

                        OPCODE_SUBI, OPCODE_SUBR: begin
                            // SUB: patch through the ALU output
                            stage_output = alu_sub_output;
                        end

                        OPCODE_ANDI, OPCODE_ANDR: begin
                            // AND: patch through the ALU output
                            stage_output = alu_and_output;
                        end

                        OPCODE_ORI, OPCODE_ORR: begin
                            // OR: patch through the ALU output
                            stage_output = alu_or_output;
                        end

                        OPCODE_XORI, OPCODE_XORR: begin
                            // ADD: patch through the ALU output
                            stage_output = alu_xor_output;
                        end

                        OPCODE_LSHS: begin
                            // LSH: patch through the ALU output
                            stage_output = alu_lsh_output;
                        end

                        OPCODE_RSHS: begin
                            // RSH: patch through the ALU output
                            stage_output = alu_rsh_output;
                        end

                        OPCODE_NOTT: begin
                            // NOT: patch through the ALU output
                            stage_output = alu_not_output;
                        end

                        OPCODE_LDI, OPCODE_LDE, OPCODE_LDA: begin
                            // LD: load memory by address in operand_1 into destination register
                            reg_write_addr_o = instruction[23:20];

                            bus_addr_o = operand_1;
                            reg_write_data_o = bus_data_i;

                            reg_write_enable_o = 1'b1;

                            bus_rw_o = 1'b0;
                            bus_enable_o = 1'b1;
                        end

                        OPCODE_STF, OPCODE_STE, OPCODE_STA: begin
                            // ST: store source register into memory by address operand_1
                            reg_read_addr_1_o = instruction[23:20];

                            bus_addr_o = operand_1;
                            bus_data_o = reg_read_data_1_i;

                            bus_rw_o = 1'b1;
                            bus_enable_o = 1'b1;
                        end

                        OPCODE_JMPF, OPCODE_JMPE, OPCODE_JMPA: begin
                            // JMP: load PC with operand_1's contents
                            pc_advance = 1'b0;

                            reg_write_addr_o = REG_PC_ADDR;
                            reg_write_data_o = operand_1;

                            reg_write_enable_o = 1'b1;
                        end
                    endcase

                    // advance stage
                    stage = PL_WRITEBACK_STAGE;
                end

                PL_WRITEBACK_STAGE: begin
                    // advance PC (if needed), reset memory enable flags and reset stage pointer
                    if (pc_advance) begin
                        reg_read_addr_1_o = REG_PC_ADDR;
                        reg_write_addr_o = REG_PC_ADDR;
                        reg_write_data_o = reg_read_data_1_i + 1'b1;
                        reg_write_enable_o = 1'b1;
                    end else begin
                        pc_advance = 1'b1;
                    end

                    reg_write_enable_o = 1'b0;
                    bus_enable_o = 1'b0;

                    stage = PL_FETCH_INSTR_STAGE;
                end

                default: begin
                    stage = PL_FETCH_INSTR_STAGE;
                end
            endcase
        end
    end

    // stages themselves
endmodule
