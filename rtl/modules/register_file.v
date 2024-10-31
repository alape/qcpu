module register_file #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4
) (
    input clk_i,
    input reset_i,
    input write_enable_i,
    input [ADDR_WIDTH-1:0] write_addr_i,
    input [DATA_WIDTH-1:0] write_data_i,
    input [ADDR_WIDTH-1:0] read_addr_1_i,
    input [ADDR_WIDTH-1:0] read_addr_2_i,
    output [DATA_WIDTH-1:0] read_data_1_o,
    output [DATA_WIDTH-1:0] read_data_2_o
);  

    reg [DATA_WIDTH-1:0] registers [0:DEPTH-1];
    integer i;

    // read ops
    assign read_data_1_o = registers[read_addr_1_i];
    assign read_data_2_o = registers[read_addr_2_i];

    // reset
    always @(posedge clk_i) begin
        if (reset_i) begin
            for (i = 0; i < DEPTH; i++) begin
                registers[i] <= 0;
            end
        end
    end

    // write ops
    always @(posedge clk_i) begin
        if (write_enable_i) begin
            registers[write_addr_i] <= write_data_i;
        end
    end
endmodule
