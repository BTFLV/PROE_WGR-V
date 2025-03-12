`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

module peripheral_bus (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [13:0] address,
  input  wire [31:0] write_data,
  output reg  [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output wire [31:0] debug_out,
  output wire        uart_tx,
  input  wire        uart_rx,
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

  localparam DEBUG_BASE  = 6'h01;
  localparam UART_BASE   = 6'h02;
  localparam TIME_BASE   = 6'h03;
  localparam PWM_BASE    = 6'h04;
  localparam WS_BASE     = 6'h05;
  localparam DIV_BASE    = 6'h06;
  localparam SPI_BASE    = 6'h07;
  localparam GPIO_BASE   = 6'h08;

  wire [7:0] func_addr;

  assign func_addr = address[7:0];

  // Debug
  wire [31:0] debug_data;
  
  wire debug_sel;
  wire debug_we;
  wire debug_re;

  assign debug_sel  = (address[12:8] == DEBUG_BASE);
  assign debug_we   = we & debug_sel;
  assign debug_re   = re & debug_sel;

  debug_module debug_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (debug_data),
    .we         (debug_we),
    .re         (debug_re),
    .debug_out  (debug_out)
  );

  // UART
  wire [31:0] uart_data;

  wire uart_sel;
  wire uart_we;
  wire uart_re;

  assign uart_sel  = (address[12:8] == UART_BASE);
  assign uart_we   = we & uart_sel;
  assign uart_re   = re & uart_sel;

  uart #(
    .FIFO_TX_DEPTH(4),
    .FIFO_RX_DEPTH(4)
  ) uart_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (uart_data),
    .we         (uart_we),
    .re         (uart_re),
    .uart_tx    (uart_tx),
    .uart_rx    (uart_rx)
  );

  // System Timer
  wire [31:0] time_data;

  wire time_sel;
  wire time_we;
  wire time_re;

  assign time_sel  = (address[12:8] == TIME_BASE);
  assign time_we   = we & time_sel;
  assign time_re   = re & time_sel;

  system_timer system_timer_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (time_data),
    .we         (time_we),
    .re         (time_re)
  );

  // PWM Timer
  wire [31:0] pwm_data;

  wire pwm_sel;
  wire pwm_we;
  wire pwm_re;

  assign pwm_sel  = (address[12:8] == PWM_BASE);
  assign pwm_we   = we & pwm_sel;
  assign pwm_re   = re & pwm_sel;

  pwm_timer pwm_timer_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (pwm_data),
    .we         (pwm_we),
    .re         (pwm_re),
    .pwm_out    (pwm_out)
  );

  // WS2812B
  wire [31:0] ws_data;

  wire ws_sel;
  wire ws_we;
  wire ws_re;

  assign ws_sel  = (address[12:8] == WS_BASE);
  assign ws_we   = we & ws_sel;
  assign ws_re   = re & ws_sel;

  ws2812b ws2812b_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (ws_data),
    .we         (ws_we),
    .re         (ws_re),
    .ws_out     (ws_out)
  );

  // WS2812B
  wire [31:0] div_data;

  wire div_sel;
  wire div_we;
  wire div_re;

  assign div_sel  = (address[12:8] == DIV_BASE);
  assign div_we   = we & div_sel;
  assign div_re   = re & div_sel;

  seq_divider seq_divider_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (div_data),
    .we         (div_we),
    .re         (div_re)
  );

  // SPI Peripheral
  wire [31:0] spi_data;

  wire spi_sel;
  wire spi_we;
  wire spi_re;

  assign spi_sel  = (address[12:8] == SPI_BASE);
  assign spi_we   = we & spi_sel;
  assign spi_re   = re & spi_sel;

  spi #(
    .FIFO_TX_DEPTH(4),
    .FIFO_RX_DEPTH(4)
  ) spi_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (spi_data),
    .we         (spi_we),
    .re         (spi_re),
    .spi_clk    (spi_clk),
    .spi_mosi   (spi_mosi),
    .spi_miso   (spi_miso),
    .spi_cs     (spi_cs)
  );

  // GPIO Peripheral
  wire [31:0] gpio_data;

  wire gpio_sel;
  wire gpio_we;
  wire gpio_re;

  assign gpio_sel  = (address[12:8] == GPIO_BASE);
  assign gpio_we   = we & gpio_sel;
  assign gpio_re   = re & gpio_sel;

  gpio gpio_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (gpio_data),
    .we         (gpio_we),
    .re         (gpio_re),
    .gpio_out   (gpio_out),
    .gpio_dir   (gpio_dir),
    .gpio_in    (gpio_in)
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      read_data <= 32'h0;
    else
    if (re)
    begin
      if      (debug_sel) read_data <= debug_data;
      else if (uart_sel)  read_data <= uart_data;
      else if (time_sel)  read_data <= time_data;
      else if (pwm_sel)   read_data <= pwm_data;
      else if (ws_sel)    read_data <= ws_data;
      else if (div_sel)   read_data <= div_data;
      else if (spi_sel)   read_data <= spi_data;
      else if (gpio_sel)  read_data <= gpio_data;
      else                read_data <= 32'h0;
    end
  end

endmodule
