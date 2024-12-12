`timescale 1ns/1ps

module tb_000_sanity();
    reg tb_clock;
    reg tb_reset;

    soc_top cpu(
        .clk (tb_clock),
        .reset (tb_reset)
    );

    localparam CLK_PERIOD = 10;
    
    always #(CLK_PERIOD / 2) tb_clock =~ tb_clock;

    initial begin
        #1 tb_reset <= 1'bx; tb_clock <= 1'bx;
        #(CLK_PERIOD * 3) tb_reset <= 1; tb_clock <= 0;
        #(CLK_PERIOD * 3) tb_reset <= 0;
    end
endmodule

`default_nettype wire