`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief GPIO Modul zur Steuerung allgemeiner I/O.
 *
 * Dieses Modul implementiert einen einfachen GPIO-Controller.
 * Es unterstützt das Auslesen von Eingangspins und das Schreiben auf Ausgangspins
 * über definierte Adressen. Die Richtungssteuerung (gpio_dir) ist derzeit nicht
 * implementiert.
 *
 * @localparam GPIO_DIR_BASE   Momentan Nicht benutzt (exemplarisch, nicht benutzt)
 * @localparam GPIO_IN_OFFSET  Basisadresse (Offset) für das GPIO-Eingangsregister
 * @localparam GPIO_OUT_OFFSET Basisadresse (Offset) für das GPIO-Ausgangsregister
 * @localparam GPIO_OUT_STEP   Schrittweite (Abstand) zwischen einzelnen GPIO-Ausgangsregistern
 * 
 * @input clk         Systemtakt.
 * @input rst_n       Aktiv-low Reset-Signal.
 * @input address     Speicheradresse zur Auswahl der GPIO-Register.
 * @input write_data  Daten, die in die angesprochenen GPIO-Register geschrieben werden.
 * @output read_data  Ausgangsdaten basierend auf dem angesprochenen GPIO-Register.
 * @input we          Schreibaktivierungssignal (Write-Enable).
 * @input re          Leseaktivierungssignal (Read-Enable).
 * @output gpio_out   Register zur Steuerung des Ausgangszustands der GPIO-Pins.
 * @output gpio_dir   GPIO-Richtungsregister (nicht implementiert).
 * @input gpio_in     Eingangssignale von den GPIO-Pins.
 */
module gpio (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [7:0]  address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output reg  [7:0]  gpio_out,
  output reg  [7:0]  gpio_dir,
  input  wire [7:0]  gpio_in
);


  // ---------------------------------------------------------
  // Lokale Parameter für Adressbereiche
  // ---------------------------------------------------------
  localparam GPIO_DIR_BASE    = 8'h00;
  localparam GPIO_IN_OFFSET   = 8'h04;
  localparam GPIO_OUT_OFFSET  = 8'h08;
  localparam GPIO_OUT_STEP    = 8'h04;

  // ---------------------------------------------------------
  // pin_index wird aus der Adresse abgeleitet, um festzustellen,
  // welches Bit im gpio_out-Register angesprochen wird.
  // ---------------------------------------------------------
  wire [2:0] pin_index = (address - GPIO_OUT_OFFSET) >> 2;

  // ---------------------------------------------------------
  // Lesezugriffe:
  // - Wenn address == GPIO_IN_OFFSET, wird gpio_in zurückgegeben.
  // - Wenn address im Bereich der Ausgangsregister liegt,
  //   wird das entsprechende gpio_out-Bit zurückgegeben.
  // - Andernfalls 0.
  // ---------------------------------------------------------
  assign read_data = (address == GPIO_IN_OFFSET) ? {24'd0, gpio_in} :
                     (address >= GPIO_OUT_OFFSET && address < (GPIO_OUT_OFFSET + (8 * GPIO_OUT_STEP))) 
                     ? {31'd0, gpio_out[pin_index]} : 32'd0;

  // ---------------------------------------------------------
  // Schreiben der gpio_out-Bits:
  // - Beim Reset werden gpio_out und gpio_dir initialisiert.
  // - Nur wenn address im Bereich für Ausgangsregister liegt und we=1,
  //   wird genau ein Bit (write_data[0]) im gpio_out geschrieben.
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      gpio_out <= 8'd0;
      gpio_dir <= 8'd0;
    end
    else
    if (we && address >= GPIO_OUT_OFFSET && address < (GPIO_OUT_OFFSET + (8 * GPIO_OUT_STEP)))
    begin
      gpio_out[pin_index] <= write_data[0];
    end
  end

endmodule