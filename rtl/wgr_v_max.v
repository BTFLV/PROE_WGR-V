`include "./defines.v"
`default_nettype none
`timescale 1ns / 1ns

module wgr_v_max (
  input  wire        clk,
  input  wire        rst_n,
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

  
  wire [31:0] address;
  wire [31:0] write_data;
  wire [31:0] read_data;
  wire        mem_busy;
  wire        we;
  wire        re;

  cpu cpu_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (address),
    .write_data (write_data),
    .read_data  (read_data),
    .we         (we),
    .re         (re),
    .mem_busy   (mem_busy)
  );

  memory memory_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (address),
    .write_data (write_data),
    .read_data  (read_data),
    .we         (we),
    .re         (re),
    .mem_busy   (mem_busy),
    .uart_tx    (uart_tx),
    .uart_rx    (uart_rx),
    .debug_out  (debug_out),
    .pwm_out    (pwm_out),
    .ws_out     (ws_out),
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso),
    .spi_clk    (spi_clk),
    .spi_cs     (spi_cs),
    .gpio_out   (gpio_out),
    .gpio_dir   (gpio_dir),
    .gpio_in    (gpio_in)
  );

endmodule
