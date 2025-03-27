`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Zentrales Peripherie-Bus-Modul
 *
 * Dieses Modul bündelt alle Zugriffe auf die verschiedenen Peripherie-Komponenten
 * (z. B. Debug, UART, Timer, PWM, SPI, GPIO etc.) und leitet Lese-/Schreibanfragen
 * anhand einer Adress-Dekodierung an die entsprechenden Module weiter.
 * Je nach aktivem Define (z. B. `INCLUDE_DEBUG`) wird die jeweilige Peripherie
 * eingebunden oder nicht. Die Schnittstellen zu den einzelnen Modulen sind
 * bereits in diesem Modul angelegt (z. B. uart_tx, gpio_out, pwm_out, ...).
 *
 * @localparam DEBUG_BASE  Basis-Adressenbereich für das Debug-Modul
 * @localparam UART_BASE   Basis-Adressenbereich für das UART-Modul
 * @localparam TIME_BASE   Basis-Adressenbereich für den System-Timer
 * @localparam PWM_BASE    Basis-Adressenbereich für das PWM-Modul
 * @localparam MULT_BASE   Basis-Adressenbereich für das Multiplikatormodul
 * @localparam DIV_BASE    Basis-Adressenbereich für das Divisionsmodul
 * @localparam SPI_BASE    Basis-Adressenbereich für das SPI-Modul
 * @localparam GPIO_BASE   Basis-Adressenbereich für das GPIO-Modul
 * @localparam WS_BASE     Basis-Adressenbereich für das WS2812B-Modul
 *
 * @input clk         Systemtakt
 * @input rst_n       Asynchrones, aktives-LOW Reset-Signal
 * @input [13:0]      address  Bus-Adresse, aus der das jeweilige Peripheriemodul dekodiert wird
 * @input [31:0]      write_data Zu schreibende Daten in das ausgewählte Modul
 * @input we          Write Enable-Signal
 * @input re          Read Enable-Signal
 * 
 * @output reg [31:0] read_data Gelesene Daten von den Peripheriemodulen
 * @output [31:0]     debug_out Debug-Ausgangssignal (z. B. zur Diagnose)
 * @output uart_tx    TX-Ausgang des UART
 * @input  uart_rx    RX-Eingang des UART
 * @output pwm_out    PWM-Ausgangssignal
 * @output ws_out     Datenleitung für WS2812B-LEDs
 * @output spi_mosi   SPI-Ausgangsdaten (Master Out, Slave In)
 * @input  spi_miso   SPI-Eingangsdaten (Master In, Slave Out)
 * @output spi_clk    SPI-Taktsignal
 * @output spi_cs     SPI-Chip-Select
 * @output [7:0]      gpio_out Ausgangssignale des GPIO-Moduls
 * @output [7:0]      gpio_dir Richtungsregister des GPIO-Moduls
 * @input  [7:0]      gpio_in  Eingangsleitungen des GPIO-Moduls
 */

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

  // Basis-Adressen für die einzelnen Peripherie-Komponenten
  localparam DEBUG_BASE  = 6'h01;
  localparam UART_BASE   = 6'h02;
  localparam TIME_BASE   = 6'h03;
  localparam PWM_BASE    = 6'h04;
  localparam MULT_BASE   = 6'h05;
  localparam DIV_BASE    = 6'h06;
  localparam SPI_BASE    = 6'h07;
  localparam GPIO_BASE   = 6'h08;
  localparam WS_BASE     = 6'h09;

  // Aus der 14-Bit-Adresse wird hier der 8-Bit-Funktionsanteil extrahiert
  // (lower 8 Bits), um innerhalb des Peripheriemoduls weiter zu dekodieren.
  wire [7:0] func_addr;

  assign func_addr = address[7:0];


  // ---------------------------------------------------------
  // Debug-Modul (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_DEBUG

  wire [31:0] debug_data;
  
  // Auswahl, ob Adresse in Bereich des Debug-Moduls fällt
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
  // Falls nicht eingebunden, werden ungenutzte Signale auf konstante Werte gesetzt
`else
  wire  [31:0]  debug_data = 32'h0;
  wire          debug_sel  = 1'b0;
  assign        debug_out  = 32'h0;
`endif


  // ---------------------------------------------------------
  // UART-Modul (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_UART

  wire [31:0] uart_data;

  wire uart_sel;
  wire uart_we;
  wire uart_re;

  assign uart_sel  = (address[12:8] == UART_BASE);
  assign uart_we   = we & uart_sel;
  assign uart_re   = re & uart_sel;

  uart #(
    .FIFO_TX_DEPTH(`UART_FIFO_TX_DEPTH),
    .FIFO_RX_DEPTH(`UART_FIFO_RX_DEPTH)
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

`else
  wire  [31:0]  uart_data = 32'h0;
  wire          uart_sel  = 1'b0;
  assign        uart_tx   = 1'b0;
`endif


  // ---------------------------------------------------------
  // System Timer (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_TIME

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

`else
  wire [31:0] time_data = 32'h0;
  wire        time_sel  = 1'b0;
`endif


  // ---------------------------------------------------------
  // PWM-Timer (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_PWM

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

`else
  wire [31:0] pwm_data = 32'h0;
  wire        pwm_sel  = 1'b0;
  assign      pwm_out  = 1'b0;
`endif


  // ---------------------------------------------------------
  // Sequentieller Multiplikator (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_MULT

  wire [31:0] mult_data;

  wire mult_sel;
  wire mult_we;
  wire mult_re;

  assign mult_sel  = (address[12:8] == MULT_BASE);
  assign mult_we   = we & mult_sel;
  assign mult_re   = re & mult_sel;

  seq_multiplier seq_multiplier_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (func_addr),
    .write_data (write_data),
    .read_data  (mult_data),
    .we         (mult_we),
    .re         (mult_re)
  );

`else
  wire [31:0] mult_data = 32'h0;
  wire        mult_sel  = 1'b0;
`endif


  // ---------------------------------------------------------
  // Sequentieller Divider (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_DIV

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

`else
  wire [31:0] div_data = 32'h0;
  wire        div_sel  = 1'b0;
`endif


  // ---------------------------------------------------------
  // SPI-Modul (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_SPI

  wire [31:0] spi_data;

  wire spi_sel;
  wire spi_we;
  wire spi_re;

  assign spi_sel  = (address[12:8] == SPI_BASE);
  assign spi_we   = we & spi_sel;
  assign spi_re   = re & spi_sel;

  spi #(
    .FIFO_TX_DEPTH(`SPI_FIFO_TX_DEPTH),
    .FIFO_RX_DEPTH(`SPI_FIFO_RX_DEPTH)
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

`else
  wire [31:0] spi_data = 32'h0;
  wire        spi_sel  = 1'b0;
  assign      spi_mosi = 1'b0;
  assign      spi_clk  = 1'b0;
  assign      spi_cs   = 1'b1;
`endif


  // ---------------------------------------------------------
  // GPIO-Modul (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_GPIO

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

`else
  wire [31:0]  gpio_data = 32'h0;
  wire         gpio_sel  = 1'b0;
  assign       gpio_out  = 8'b0;
  assign       gpio_dir  = 8'b0;
`endif


  // ---------------------------------------------------------
  // WS2812B-LED-Modul (optional über DEFINE eingebunden)
  // ---------------------------------------------------------
`ifdef INCLUDE_WS

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

`else
  wire [31:0] ws_data = 32'h0;
  wire        ws_sel  = 1'b0;
  assign      ws_out  = 1'b0;
`endif

  // ---------------------------------------------------------
  // Lesezugriffe: Hier wird je nach ausgewähltem Modul das passende
  // 'read_data' ausgegeben. Falls kein passendes Modul selektiert
  // ist, wird 0x0 zurückgegeben.
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      read_data <= 32'h0;
    else
    if (re)
    begin

`ifdef INCLUDE_DEBUG
      if      (debug_sel) read_data <= debug_data;
`endif
`ifdef INCLUDE_UART
      else if (uart_sel)  read_data <= uart_data;
`endif
`ifdef INCLUDE_TIME
      else if (time_sel)  read_data <= time_data;
`endif
`ifdef INCLUDE_PWM
      else if (pwm_sel)   read_data <= pwm_data;
`endif
`ifdef INCLUDE_MULT
      else if (mult_sel)  read_data <= mult_data;
`endif
`ifdef INCLUDE_DIV
      else if (div_sel)   read_data <= div_data;
`endif
`ifdef INCLUDE_SPI
      else if (spi_sel)   read_data <= spi_data;
`endif
`ifdef INCLUDE_GPIO
      else if (gpio_sel)  read_data <= gpio_data;
`endif
`ifdef INCLUDE_WS
      else if (ws_sel)    read_data <= ws_data;
`endif

      else
        read_data <= 32'h0;

    end
  end

endmodule
