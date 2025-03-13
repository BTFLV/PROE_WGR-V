`ifndef DEFINES_V
`define DEFINES_V

`define CLK_FREQ       10_000_000

`define BAUD_DIV(Baud) ((`CLK_FREQ / Baud) - 1)

`define RV32I

//`define FRAM_MEMORY

`define UART_FIFO_TX_DEPTH 4
`define UART_FIFO_RX_DEPTH 4

`define SPI_FIFO_TX_DEPTH 4
`define SPI_FIFO_RX_DEPTH 4

`define INCLUDE_DEBUG
`define INCLUDE_UART
`define INCLUDE_TIME
`define INCLUDE_PWM
`define INCLUDE_MULT
`define INCLUDE_DIV
`define INCLUDE_SPI
`define INCLUDE_GPIO
`define INCLUDE_WS

`endif
