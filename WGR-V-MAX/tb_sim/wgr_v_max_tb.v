`default_nettype none
`timescale 1ns / 1ns

module wgr_v_max_tb ();

  reg  [ 7:0] tb_gpio_in;

  reg         tb_clk;
  reg         tb_rst_n;
  reg         tb_spi_miso;
  reg         tb_uart_rx;

  wire [31:0] tb_debug_out;
  wire [ 7:0] tb_gpio_out;
  wire [ 7:0] tb_gpio_dir;

  wire        tb_halt_led;
  wire        tb_pwm_out;
  wire        tb_uart_tx;
  wire        tb_ws_out;
  wire        tb_spi_mosi;
  wire        tb_spi_clk;
  wire        tb_spi_cs;

  wgr_v_max dut (
    .clk        (tb_clk),
    .rst_n      (tb_rst_n),
    .halt_led   (tb_halt_led),
    .pwm_out    (tb_pwm_out),
    .uart_tx    (tb_uart_tx),
    .uart_rx    (tb_uart_rx),
    .debug_out  (tb_debug_out),
    .ws_out     (tb_ws_out),
    .spi_mosi   (tb_spi_mosi),
    .spi_miso   (tb_spi_miso),
    .spi_clk    (tb_spi_clk),
    .spi_cs     (tb_spi_cs),
    .gpio_out   (tb_gpio_out),
    .gpio_dir   (tb_gpio_dir),
    .gpio_in    (tb_gpio_in)
  );





  parameter CLK_FREQ = 10000000;    
  parameter BAUD_RATE = 115200;
  parameter BIT_PERIOD = 1000000000 / BAUD_RATE;
  
  reg [7:0] data_byte = 8'h42;
  integer i;

  initial begin
    tb_clk = 0;
    forever #50 tb_clk = ~tb_clk;
  end

  initial begin
    tb_rst_n      = 0;
    tb_uart_rx    = 1;
    tb_spi_miso   = 1;
    $display("[%0t ns] Reset asserted", $time);
    #500 tb_rst_n = 1;
    $display("[%0t ns] Reset deasserted", $time);
  end

  task uart_send_byte(input [7:0] byte);
    begin
      $display("[%0t ns] Sending Byte: 0x%02X", $time, byte);

      tb_uart_rx = 0;
      #(BIT_PERIOD);

      for (i = 0; i < 8; i = i + 1) begin
        tb_uart_rx = byte[i];
        #(BIT_PERIOD);
      end

      tb_uart_rx = 1;
      #(BIT_PERIOD);

      $display("[%0t ns] Stop Bit Sent", $time);
    end
  endtask

  initial begin
    #1000;
    if (tb_rst_n == 1)
      $display("[%0t ns] Starting UART Transmission", $time);

    forever begin
      uart_send_byte(data_byte);
      data_byte = data_byte + 1;
      #(10 * BIT_PERIOD);
    end
  end

  initial begin
    #1000000;
    $stop;
  end

endmodule
