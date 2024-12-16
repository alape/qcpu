module soc_top (
    input clk,
    input reset
);

    wire [31:0] bus_data_output;
    wire [31:0] bus_data_input;
    wire [31:0] bus_addr;
    wire        bus_rw;
    wire        bus_enable;

    // CPU core
    pipeline cpu_core (
        .clk_i(clk),
        .reset_i(reset),

        .bus_data_o(bus_data_output),
        .bus_data_i(bus_data_input),
        .bus_addr_o(bus_addr),
        .bus_rw_o(bus_rw),
        .bus_enable_o(bus_enable)
    );

    // some RAM
    ram #(.A_MAX(512)) cpu_ram (
        .clk_i(clk),

        .address_i(bus_addr),
        .data_i(bus_data_output),
        .data_o(bus_data_input),

        .enable_i(bus_enable),
        .rw_i(bus_rw)
    );

endmodule
