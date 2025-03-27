`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Debug-Modul für Host-Kommunikation und Speicherzugriff
 *
 * Dieses Modul stellt ein einfaches Register zur Verfügung, das über den
 * Bus geschrieben und gelesen werden kann. Es wird außerdem über eine
 * separate Leitung (debug_out) nach außen ausgegeben. Auf jeden
 * Schreibzugriff hin wird der neue Wert im Simulator protokolliert.
 * 
 * @localparam DEBUG_ADDR Basiskonstante zur Adresszuordnung
 * 
 * @input clk        Systemtakt
 * @input rst_n      Reset-Signal
 * @input address    Adresse, über die auf das Debug-Register zugegriffen wird
 * @input write_data Zu schreibende Daten
 * @output read_data Gelesene Daten aus dem Debug-Register
 * @input we         Write Enable-Signal
 * @input re         Read Enable-Signal
 * @output debug_out Direkte Ausgabe des Debug-Registers (z. B. zu Diagnosezwecken)
 */

module debug_module (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [ 7:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,
    input  wire        we,
    input  wire        re,
    output wire [31:0] debug_out
  );

  // Basiskonstante für Debug-Adressen
  localparam DEBUG_ADDR = 32'h00000000;

  // Internes Register, in dem Debug-Informationen abgelegt werden
  reg [31:0] debug_reg;


  // Zuweisungen: Leseausgabe und Debug-Ausgang geben dasselbe Register aus
  assign read_data = debug_reg;
  assign debug_out = debug_reg;

  // Speichern oder Zurücksetzen des Debug-Registers
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      debug_reg <= 32'h00000000;
    end
    else
    if (we)
    begin
      debug_reg <= write_data;
      // Meldung im Simulator bei jedem Schreibzugriff
      $display("DEBUG_REG UPDATED: 0x%08X (%d) at time %0t", write_data, write_data, $time);
    end
  end

endmodule
