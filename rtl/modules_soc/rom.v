module cpu_rom #(
    parameter A_WIDTH  = 32,
    parameter D_WIDTH  = 32,
    parameter A_MAX    = 65536,
    parameter A_OFFSET = 0
) (
    input wire               enable_i,
    input wire [A_WIDTH-1:0] address_i,
    inout wire [D_WIDTH-1:0] data_o
);

    reg [D_WIDTH-1:0] memory [A_MAX-1:0];

    integer i;
    // initial for (i = 0; i < A_MAX; i = i + 1) memory[i] = 0;

    assign data_o = enable_i? memory[address_i - A_OFFSET]: 'bz;
endmodule
