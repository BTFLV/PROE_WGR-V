`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Debug-Modul für Host-Kommunikation und Speicherzugriff
 *
 * Dieses Modul stellt eine einfache Debug-Schnittstelle über UART bereit,
 * um mit einem Host-System zu kommunizieren. Es ermöglicht das Lesen und
 * Schreiben von Speicherinhalten über serielle Kommandos. Über den
 * UART-Eingang `rx` empfängt das Modul Befehle, die über interne
 * Kontrollsignale (`mem_rd`, `mem_wr`, etc.) an den CPU-internen Speicher
 * weitergegeben werden. Das Antwortsignal wird über `tx` gesendet.
 * 
 * @input clk Systemtakt
 * @input rst Reset-Signal
 * @input rx Eingang vom seriellen Host (UART)
 * @input mem_data_from_cpu Daten aus dem Speicher (vom CPU-Interface)
 * @input mem_ready_from_cpu Bereitschaftssignal vom Speicher
 * 
 * @output tx Ausgang zur seriellen Schnittstelle
 * @output mem_addr_to_cpu Speicheradresse für den Zugriff
 * @output mem_data_to_cpu Daten, die geschrieben werden sollen
 * @output mem_wr Speicher-Schreibsignal
 * @output mem_rd Speicher-Lesesignal
 * @output mem_valid Gültigkeitssignal für Speicherzugriff
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

  localparam DEBUG_ADDR = 32'h00000000;

  reg [31:0] debug_reg;

  assign read_data = debug_reg;
  assign debug_out = debug_reg;

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
      $display("DEBUG_REG UPDATED: 0x%08X (%d) at time %0t", write_data, write_data, $time);
    end
  end

endmodule
