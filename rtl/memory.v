`include "./defines.v"
`default_nettype none
`timescale 1ns / 1ns

module memory (
  input  wire        clk,
  input  wire        rst_n,
  output wire        mem_busy,
  input  wire [31:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output wire        uart_tx,
  input  wire        uart_rx,
  output wire [31:0] debug_out,
  output wire        pwm_out,
  output wire        ws_out,
  output wire        spi_mosi,
  input  wire        spi_miso,
  output wire        spi_clk,
  output wire        spi_cs,
  output wire [ 7:0] gpio_out,
  output wire [ 7:0] gpio_dir,
  input  wire [ 7:0] gpio_in
);

  wire [31:0] ram_addr;
  wire [31:0] ram_data;
  wire [13:0] per_addr;
  wire [31:0] per_data;

  wire is_ram;
  wire we_ram;
`ifdef FRAM_MEMORY
  wire re_ram;
`endif
  wire we_per;
  wire re_per;
  wire req_ready;

  assign we_ram    = we &&  is_ram;
`ifdef FRAM_MEMORY
  assign re_ram    = re &&  is_ram;
`endif
  assign we_per    = we && !is_ram;
  assign re_per    = re && !is_ram;
  assign is_ram    = (address >= 32'h00004000);
  assign ram_addr  = (address  - 32'h00004000);
  assign per_addr  = is_ram ? 14'b0 : address[13:0];
  assign read_data = is_ram ? ram_data : per_data;
  assign mem_busy  = !req_ready;
`ifndef FRAM_MEMORY
  assign req_ready = 1'b1;
`endif

`ifdef FRAM_MEMORY
  fram_ram fram_ram_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .req_ready  (req_ready),
    .address    (ram_addr[15:0]),
    .write_data (write_data),
    .read_data  (ram_data),
    .we         (we_ram),
    .re         (re_ram),
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso),
    .spi_clk    (spi_clk),
    .spi_cs     (spi_cs)
  );
`else
  ram1p ram1p_inst (
    .address (ram_addr[14:2]),
    .clock   (clk),
    .data    (write_data),
    .wren    (we_ram),
    .q       (ram_data)
  );
`endif

  peripheral_bus peripheral_bus_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (per_addr),
    .write_data (write_data),
    .read_data  (per_data),
    .we         (we_per),
    .re         (re_per),
    .debug_out  (debug_out),
    .uart_tx    (uart_tx),
    .uart_rx    (uart_rx),
    .pwm_out    (pwm_out),
    .ws_out     (ws_out),
`ifdef FRAM_MEMORY
    .spi_mosi   (),
    .spi_miso   (1'b0),
    .spi_clk    (),
    .spi_cs     (),
`else
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso),
    .spi_clk    (spi_clk),
    .spi_cs     (spi_cs),
`endif
    .gpio_out   (gpio_out),
    .gpio_dir   (gpio_dir),
    .gpio_in    (gpio_in)
  );

endmodule
