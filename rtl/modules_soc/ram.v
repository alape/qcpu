module ram #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 32,
    parameter A_MAX   = 256, // 2^A_WIDTH
    parameter A_OFFSET = 0
) (
  input                    clk_i,       // primary clock source

  input      [A_WIDTH-1:0] address_i,   // address bus

  input      [D_WIDTH-1:0] data_i,      // data input

  output reg [D_WIDTH-1:0] data_o,      // data output

  input                    enable_i,    // normal operation if 1, 
                                        // outputs not driven & data not written when 0

  input                    rw_i         // data is written if 1, read if 0
);
  
  // memory as multi-dimensional array
  reg [D_WIDTH-1:0] memory [A_MAX-1:0];
  
  // initialize memory with zeroes if needed
  integer i;
  initial for (i = 0; i < (A_MAX - 1); i = i + 1) memory[i] = 'b0; 

  always @(posedge clk_i) begin
    if (enable_i) begin
      if (rw_i) 
        memory[address_i - A_OFFSET] <= data_i;   // write data
      else
        data_o <= memory[address_i - A_OFFSET];    // read data
    end
  end
endmodule
