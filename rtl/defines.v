`ifndef DEFINES_V
`define DEFINES_V

`define CLK_FREQ       10_000_000

`define BAUD_DIV(Baud) ((`CLK_FREQ / Baud) - 1)

`endif
