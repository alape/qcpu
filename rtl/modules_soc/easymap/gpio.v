`define EASYMAP_GPIO_ID 32'h4750494F  // EasyMM ID is "GPIO"

`define REG_EASYMMAP_ID 'h0
`define REG_IBUF        'h1
`define REG_OBUF        'h2
`define REG_MODEBUF     'h3

module gpio #(
    parameter D_WIDTH = 32,
    parameter A_WIDTH = 32,
    parameter GPIO_WIDTH = 32
) (
  input                    clk_i,       // primary clock source

  input      [A_WIDTH-1:0] address_i,   // address bus

  input      [D_WIDTH-1:0] data_i,      // data input

  output     [D_WIDTH-1:0] data_o,      // data output

  input                    enable_i,    // normal operation if 1, 
                                        // outputs not driven & data not written when 0
                                        
  input                    rw_i,         // data is written if 1, read if 0

  inout   [GPIO_WIDTH-1:0] gpio_io      // GPIO tri-state IO
);

  reg [D_WIDTH-1:0] i_buf;
  reg [D_WIDTH-1:0] o_buf;
  reg [D_WIDTH-1:0] mode_buf;
  
  reg [D_WIDTH-1:0] bus_out;

  initial begin
    i_buf = 'b0;
    o_buf = 'b0;
    mode_buf = 'b0;
  end

  always @(negedge clk_i) begin
    if (enable_i) begin
      case (address_i)
        // EASYMMAP_ID = 32'h4750494F @0x0 r
        `REG_EASYMMAP_ID: begin
          if (!rw_i) begin
            bus_out = `EASYMAP_GPIO_ID;
          end
        end

        // IBUF = 32'h0 @0x1 r
        `REG_IBUF: begin
          if (!rw_i) begin
            bus_out = i_buf;
          end
        end

        // IBUF = 32'h0 @0x2 rw
        `REG_OBUF: begin
          if (rw_i) begin
            o_buf = data_i;
          end
          
          bus_out = o_buf;
        end

        // MODEBUF = 32'h0 @0x3 rw
        `REG_MODEBUF: begin
          if (rw_i) begin
            mode_buf = data_i;
          end
          
          bus_out = mode_buf;
        end
      endcase
    end
  end
  
  // drive bus only if enabled
  assign data_o = (enable_i)? bus_out : 'hZ;

  IOBUF iobuffers[GPIO_WIDTH-1:0] (
    .I(o_buf),
    .O(i_buf),
    .T(mode_buf),
    .IO(gpio_io)
  );

  // assign gpio_io = o_buf;

endmodule
