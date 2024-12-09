module soc_top (
    input clk,
    input reset
);

    wire [31:0] bus_data_output;
    wire [31:0] bus_data_input;
    wire [31:0] bus_addr;
    wire        bus_rw;
    wire        bus_enable;

    wire        reg_write_enable;
    wire [31:0] reg_write_data;
    wire [3:0]  reg_write_addr;
    wire [3:0]  reg_read_addr_1;
    wire [3:0]  reg_read_addr_2;
    wire [31:0] reg_read_data_1;
    wire [31:0] reg_read_data_2;

    // register file
    register_file regs (
        .clk_i(clk),
        .reset_i(reset),
        .write_enable_i(reg_write_enable),
        .write_addr_i(reg_write_addr),
        .write_data_i(reg_write_data),
        .read_addr_1_i(reg_read_addr_1),
        .read_addr_2_i(reg_read_addr_2),
        .read_data_1_i(reg_read_data_1),
        .read_data_2_i(reg_read_data_2)
    );

    // CPU core
    pipeline cpu_core (
        .clk_i(clk),
        .reset_i(reset),

        .bus_data_o(bus_data_output),
        .bus_data_i(bus_data_input),
        .bus_addr_o(bus_addr),
        .bus_rw_o(bus_rw),
        .bus_enable_o(bus_enable),

        .reg_write_enable_o(reg_write_enable),
        .reg_write_data_o(reg_write_data),
        .reg_write_addr_o(reg_write_addr),
        .reg_read_addr_1_o(reg_read_addr_1),
        .reg_read_addr_2_o(reg_read_addr_2),
        .reg_read_data_1_i(reg_read_data_1),
        .reg_read_data_1_i(reg_read_data_2)
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
