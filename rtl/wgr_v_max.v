`include "./defines.v"
`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Top-Level Modul („wgr_v_max“) eines minimalistischen SoC-Systems in HDL (mit CPU, Speicher und Peripherie).
 *
 * Dieses Modul instanziiert die CPU (`cpu.v`) sowie den Hauptspeicher (`memory.v`).
 * Es stellt außerdem einige grundlegende externe Signale bereit (UART, SPI, PWM, WS,
 * GPIO) und kann somit als oberstes Top-Level Modul fungieren. 
 *
 * Zusätzlich enthält es hier exemplarisch einen einfachen LED-Lauflicht-Zähler, 
 * der in `gpio_shift` gespeicherte Bits nacheinander auf `gpio_out` legt.
 *
 * @input  clk        Systemtakt
 * @input  rst_n      Asynchroner, aktiver-LOW Reset
 * @output uart_tx    TX-Ausgang der UART-Schnittstelle
 * @input  uart_rx    RX-Eingang der UART-Schnittstelle
 * @output [31:0]     debug_out Debugging-Signal aus dem Debug-Modul
 * @output pwm_out    PWM-Ausgang
 * @output ws_out     Datenleitung für WS2812B-LEDs
 * @output spi_mosi   SPI-Ausgang (Master->Slave)
 * @input  spi_miso   SPI-Eingang (Slave->Master)
 * @output spi_clk    SPI-Takt
 * @output spi_cs     SPI-Chipselect
 * @output [ 7:0]     gpio_out GPIO-Ausgänge
 * @output [ 7:0]     gpio_dir GPIO-Richtung (derzeit ungenutzt)
 * @input  [ 7:0]     gpio_in   GPIO-Eingänge
 */

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

  
  // ---------------------------------------------------------
  // Interne Verbindungs-Signale zwischen CPU und Memory
  // ---------------------------------------------------------
  wire [31:0] address;
  wire [31:0] write_data;
  wire [31:0] read_data;
  wire        mem_busy;
  wire        we;
  wire        re;
  
  // ---------------------------------------------------------
  // Beispiel: Lauflicht-Steuerung für GPIO
  // ---------------------------------------------------------

  //assign gpio_out = gpio_shift;
  
  reg [ 7:0]  gpio_shift;
  
  reg [22:0] counter = 0;
  reg [2:0] position = 0;

  always @(posedge clk) begin
      if (counter >= 23'd6000000 - 1) begin
          counter <= 0;
          gpio_shift <= 8'b00000001 << position;
          position <= (position == 3'd7) ? 0 : position + 1;
      end else begin
          counter <= counter + 1;
      end
  end

  // ---------------------------------------------------------
  // CPU-Instanz: generiert Adresse, write_data, we, re und
  // empfängt read_data sowie mem_busy
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // Speicher-Modul (RAM/Peripherie), an das die CPU
  // ihre Zugriffe weiterleitet
  // ---------------------------------------------------------
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
