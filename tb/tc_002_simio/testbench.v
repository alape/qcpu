`timescale 1ns/1ps

module tb_002_simio();
    reg tb_clock;
    reg tb_reset;

    wire [31:0] bus_data_output;
    wire [31:0] bus_data_input;
    wire [31:0] bus_addr;
    wire        bus_rw;

    // ------------ SoC setup ------------

    // CPU core
    pipeline cpu_core (
        .clk_i(tb_clock),
        .reset_i(tb_reset),

        .bus_data_o(bus_data_output),
        .bus_data_i(bus_data_input),
        .bus_addr_o(bus_addr),
        .bus_rw_o(bus_rw),
        
        .irq_i(32'b0)
    );

    // some RAM @'h0 ~ 'h1FF
    ram #(.A_MAX(512)) cpu_ram (
        .clk_i(tb_clock),

        .address_i(bus_addr),
        .data_i(bus_data_output),
        .data_o(bus_data_input),

        .enable_i(bus_addr < 'h200),
        .rw_i(bus_rw)
    );

    // SIMIO IP @'h200 (enable_i is 1 << 9)
    simio #(.A_WIDTH(9)) cpu_simio (
        .clk_i(tb_clock),

        .address_i(bus_addr[8:0]),
        .data_i(bus_data_output),
        .data_o(bus_data_input),

        .enable_i(bus_addr[9]),
        .rw_i(bus_rw)
    );

    localparam CLK_PERIOD = 10;
    
    always #(CLK_PERIOD / 2) tb_clock =~ tb_clock;
    
    `include "tc_002_simio.vh"

    initial begin
        #1 tb_reset <= 1'bx; tb_clock <= 1'bx;
        #(CLK_PERIOD * 3) tb_reset <= 1; tb_clock <= 0;
        #(CLK_PERIOD * 3) tb_reset <= 0;
    end
endmodule

`default_nettype wire