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

    parameter RESET_VECTOR   = 0,
    parameter STACK_VECTOR   = 0
) (
    input clk_i,
    input reset_i,

    // bus
    output reg [DATA_WIDTH-1:0]     bus_data_o,
    input      [DATA_WIDTH-1:0]     bus_data_i,
    output reg [MEM_ADDR_WIDTH-1:0] bus_addr_o,
    output reg                      bus_rw_o,     // 1 for W, 0 for R
    
    // interrupts
    input      [DATA_WIDTH-1:0]     irq_i
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
            operand_1 = 32'b0;
            operand_2 = 32'b0;
            pc_advance = 1'b1;
            
            // load reset vector into PC
            registers[`REG_PC_ADDR] = RESET_VECTOR;
            
            // load stack vector into SC
            registers[`REG_SC_ADDR] = STACK_VECTOR;
        end else begin
            // handle interrupts
            if ((irq_i != 32'b0) && (!(registers[`REG_SR_ADDR] & 32'b100))) begin
                registers[`REG_IR_ADDR] = irq_i;
                
                // if SR.IE is set and SR.II is not, JAL to IRQ vector
                // interrupts won't resume until SR.II is reset by the program
                if ((registers[`REG_SR_ADDR] & 32'b10) && 
                    (!(registers[`REG_SR_ADDR] & 32'b100))) begin
						  registers[`REG_SR_ADDR] = registers[`REG_SR_ADDR] | 32'b100;  // set SR.II
						  
                    pc_advance = 1'b0;
                                            
                    bus_addr_o = registers[`REG_SC_ADDR];
                    bus_data_o = registers[`REG_PC_ADDR] + 1;
                    
                    bus_rw_o = 1'b1;
                    
                    registers[`REG_PC_ADDR] = registers[`REG_IV_ADDR];
                    registers[`REG_SC_ADDR] = registers[`REG_SC_ADDR] + 1;
                end
            end
        
            // advance stage
            case (stage)
                `PL_FETCH_INSTR_STAGE: begin
                    // prepare to fetch instruction from memory by PC
                    bus_addr_o = registers[`REG_PC_ADDR];
                    bus_rw_o = 1'b0;

                    // advance stage
                    stage = `PL_EVAL_OPCODE_STAGE;
                end

                `PL_EVAL_OPCODE_STAGE: begin
                    // fetch instruction from memory
                    instruction = bus_data_i;

                    // slice out the opcode and flavour
                    opcode = instruction[28:24];
                    flavour = instruction[31:29];

                    // advance stage:
                    //     - skip `PL_EVAL_ADDR_STAGE if instruction is not LD
                    //     - skip both `PL_EVAL_ADDR_STAGE and `PL_FETCH_OPERANDS_STAGE if instruction is N-flavoured
                    if ((opcode == `OPCODE_LD) && (flavour != `FLAVOUR_S)) begin
                        stage = `PL_EVAL_ADDR_STAGE;
                    end else if (flavour == `FLAVOUR_N) begin 
                        stage = `PL_EXECUTE_STAGE;  
                    end else begin
                        stage = `PL_FETCH_OPERANDS_STAGE;
                    end
                end

                `PL_EVAL_ADDR_STAGE: begin
                    // only invoked if instruction is LD
                    // (i.e. it needs to fetch operands from memory)
                    
                    // prepare to fetch operand
					if (flavour == `FLAVOUR_F) begin
                        bus_addr_o = registers[instruction[19:16]];
                    end else if (flavour == `FLAVOUR_A) begin
                        bus_addr_o = instruction[19:0];
                    end

                    // enable bus read
                    bus_rw_o = 1'b0;

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

                        `FLAVOUR_F: begin
                            // F flavour: one operand is fetched from memory by register reference
                            operand_2 = bus_data_i;
                        end
                        
                        `FLAVOUR_E: begin
                            // E flavour: one operand is fetched from registers
                            operand_2 = registers[instruction[23:20]];
                        end
                        
                        `FLAVOUR_Q: begin
                            // Q flavour: one full-width (24 bits) immediate operand
                            operand_2 = instruction[23:0];
                        end

                        `FLAVOUR_A: begin
                            // A flavour: one operand is either fetched from memory (LD) or is immediate (ST)
                            if (opcode == `OPCODE_LD) begin
                               operand_2 = bus_data_i;
                            end else begin
                               operand_2 = instruction[19:0];
                            end
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
                            // LD: patch through the operand fetched in the previous stage
                            stage_output = operand_2;
                        end

                        `OPCODE_ST: begin
                            // ST: store source register into memory by address operand_2
                            bus_addr_o = operand_2;
                            bus_data_o = registers[instruction[23:20]];

                            bus_rw_o = 1'b1;
                        end
                        
                        `OPCODE_BEQ: begin
                            // BEQ: jump to destination if operand_1 == operand_2
                            if (operand_1 == operand_2) begin
                                pc_advance = 1'b0;
                                
                                registers[`REG_PC_ADDR] = registers[instruction[23:20]];
                            end
                        end
                        
                        `OPCODE_BNE: begin
                            // BNE: jump to destination if operand_1 != operand_2
                            if (operand_1 != operand_2) begin
                                pc_advance = 1'b0;
                                
                                registers[`REG_PC_ADDR] = registers[instruction[23:20]];
                            end
                        end
                        
                        `OPCODE_BGT: begin
                            // BGT: jump to destination if operand_1 > operand_2
                            if (operand_1 > operand_2) begin
                                pc_advance = 1'b0;
                                
                                registers[`REG_PC_ADDR] = registers[instruction[23:20]];
                            end
                        end
                        
                        `OPCODE_BLT: begin
                            // BLT: jump to destination if operand_1 < operand_2
                            if (operand_1 < operand_2) begin
                                pc_advance = 1'b0;
                                
                                registers[`REG_PC_ADDR] = registers[instruction[23:20]];
                            end
                        end

                        `OPCODE_JMP: begin
                            // JMP: load PC with operand_2's contents
                            pc_advance = 1'b0;

                            registers[`REG_PC_ADDR] = operand_2;
                        end
                        
                        `OPCODE_JAL: begin
                            // JAL: load PC with operand_2's contents, push PC+1 to stack
                            pc_advance = 1'b0;
                            
                            bus_addr_o = registers[`REG_SC_ADDR];
                            bus_data_o = registers[`REG_PC_ADDR] + 1;
                            
                            bus_rw_o = 1'b1;
                            
                            registers[`REG_PC_ADDR] = operand_2;
                            registers[`REG_SC_ADDR] = registers[`REG_SC_ADDR] + 1;
                        end
                        
                        `OPCODE_RET: begin
                            // RET: pop value from stack to PC
                            pc_advance = 1'b0;
                            
							registers[`REG_SC_ADDR] = registers[`REG_SC_ADDR] - 1;
                            bus_addr_o = registers[`REG_SC_ADDR];
                            
                            bus_rw_o = 1'b0;
                        end
                        
                        `OPCODE_PSH: begin
                            // PSH: push operand_2 to stack
                            bus_addr_o = registers[`REG_SC_ADDR];
                            bus_data_o = operand_2;
                            
                            bus_rw_o = 1'b1;
                            
                            registers[`REG_SC_ADDR] = registers[`REG_SC_ADDR] + 1;
                        end
                        
                        `OPCODE_POP: begin
                             // POP: pop value from stack to destination register
                             registers[`REG_SC_ADDR] = registers[`REG_SC_ADDR] - 1;
                             bus_addr_o = registers[`REG_SC_ADDR];
                             
                             bus_rw_o = 1'b0;
                         end
                    endcase

                    // advance stage
                    stage = `PL_WRITEBACK_STAGE;
                end

                `PL_WRITEBACK_STAGE: begin
                    // finish the memory access operations
                    case (opcode)
                        `OPCODE_ADD, `OPCODE_SUB, `OPCODE_AND, `OPCODE_OR, 
                        `OPCODE_XOR, `OPCODE_LSH, `OPCODE_RSH, `OPCODE_NOT,
                        `OPCODE_LD: begin
                            // write stage output to destination (if necessary, depending on the opcode)
                            registers[instruction[23:20]] = stage_output;
                        end
                        
                        `OPCODE_RET: begin
                            // finish RET execution
                            registers[`REG_PC_ADDR] = bus_data_i;
                         end
                         
                        `OPCODE_POP: begin
                            // finish POP execution
                            registers[instruction[23:20]] = bus_data_i;
                        end
                    endcase
				    
                    // advance PC (if needed), reset memory enable flags and reset stage pointer
                    if (pc_advance) begin
                        registers[`REG_PC_ADDR] = registers[`REG_PC_ADDR] + 1'b1;
                    end else begin
                        pc_advance = 1'b1;
                    end

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
