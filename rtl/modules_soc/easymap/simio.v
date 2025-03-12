`define EASYMAP_GPIO_ID 32'h534D494F  // EasyMM ID is "SMIO"

`define REG_EASYMMAP_ID 'h0
`define REG_SIMO        'h1

module simio #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 32
) (
  input                    clk_i,       // primary clock source

  input      [A_WIDTH-1:0] address_i,   // address bus

  input      [D_WIDTH-1:0] data_i,      // data input

  output     [D_WIDTH-1:0] data_o,      // data output

  input                    enable_i,    // normal operation if 1, 
                                        // outputs not driven & data not written when 0
                                        
  input                    rw_i         // data is written if 1, read if 0
);
  reg [D_WIDTH-1:0] bus_out;
  reg               output_filter;
  
  initial begin
    output_filter = 1'b1;
    $write("--- SIMIO IP core present ---\n\n");
  end

  always @(negedge clk_i) begin
    if (enable_i) begin
      case (address_i)
        // EASYMMAP_ID = 32'h534D494F @0x0 r
        `REG_EASYMMAP_ID: begin
          if (!rw_i) begin
            bus_out = `EASYMAP_GPIO_ID;
          end
        end

        // REG_SIMO = 32'h0 @0x1 w
        `REG_SIMO: begin
          if (rw_i && output_filter) begin
            $write("%c", data_i[31:24]);
            output_filter = 1'b0;
          end
        end
      endcase
    end else begin
      output_filter = 1'b1;
    end
  end
  
  // drive bus only if enabled
  assign data_o = (enable_i)? bus_out : 'hZ;

endmodule
