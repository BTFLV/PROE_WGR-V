`include "./defines.v"
`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Registerdatei für den CPU-Kern.
 *
 * Diese Registerdatei umfasst entweder 32 Register (im RV32I-Mode)
 * oder 16 Register (ansonsten) und unterstützt Lese- und Schreibzugriffe.
 * Der Schreibzugriff erfolgt über ein Write-Enable-Signal, sowie
 * Auswahl des Ziel- und Quellregisters. Bei RISC-V (RV32I) bleibt
 * das Register x0 jederzeit auf 0.
 *
 * @macro RV32I Falls definiert, werden 32 Register angelegt.
 *
 * @input  clk             Systemtakt.
 * @input  rst_n           Asynchroner, aktiver-LOW Reset.
 * @input  we              Write-Enable-Signal zum Beschreiben eines Registers.
 * @input  [4:0] rd        Zielregister, in das bei we=1 geschrieben werden soll.
 * @input  [4:0] rs1       Erstes Quellregister für eine Leseanfrage.
 * @input  [4:0] rs2       Zweites Quellregister für eine Leseanfrage.
 * @input  [31:0] rd_data  Daten, die in rd geschrieben werden (falls we=1).
 *
 * @output [31:0] rs1_data Daten aus dem Register rs1.
 * @output [31:0] rs2_data Daten aus dem Register rs2.
 */

module register_file (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        we,
  input  wire [ 4:0] rd,
  input  wire [ 4:0] rs1,
  input  wire [ 4:0] rs2,
  input  wire [31:0] rd_data,
  output wire [31:0] rs1_data,
  output wire [31:0] rs2_data
);

`ifdef RV32I
  // Bei aktiviertem RV32I-Macro werden 32 Register definiert (1..31).
  // Register 0 bleibt immer 0.
  reg [31:0] registers[31:1];
`else
  // Sonst 16 Register (1..15).
  reg [31:0] registers[15:1];
`endif

  // ---------------------------------------------------------
  // Lesezugriffe:
  // - Wenn rs1 != 0, wird das entsprechende Register ausgegeben,
  //   sonst 0.
  // - Wenn rs2 != 0, wird das entsprechende Register ausgegeben,
  //   sonst 0.
  // ---------------------------------------------------------
`ifdef RV32I
  assign rs1_data  = (rs1 != 5'd0) ? registers[rs1] : 32'd0;
  assign rs2_data  = (rs2 != 5'd0) ? registers[rs2] : 32'd0;
`else
  // Nur die unteren 16 Register sind gültig (rd[4] = 0).
  assign rs1_data = (rs1 != 5'd0 && ~rs1[4]) ? registers[rs1] : 32'd0;
  assign rs2_data = (rs2 != 5'd0 && ~rs2[4]) ? registers[rs2] : 32'd0;
`endif

  // ---------------------------------------------------------
  // Schreibzugriffe:
  // - Bei RV32I wird registr[rd] nur beschrieben, wenn rd != 0.
  // - Ansonsten nur, wenn rd != 0 und rd[4] nicht gesetzt.
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      registers[ 1] <= 32'd0;
      registers[ 2] <= 32'd0;
      registers[ 3] <= 32'd0;
      registers[ 4] <= 32'd0;
      registers[ 5] <= 32'd0;
      registers[ 6] <= 32'd0;
      registers[ 7] <= 32'd0;
      registers[ 8] <= 32'd0;
      registers[ 9] <= 32'd0;
      registers[10] <= 32'd0;
      registers[11] <= 32'd0;
      registers[12] <= 32'd0;
      registers[13] <= 32'd0;
      registers[14] <= 32'd0;
      registers[15] <= 32'd0;
`ifdef RV32I
      registers[16] <= 32'd0;
      registers[17] <= 32'd0;
      registers[18] <= 32'd0;
      registers[19] <= 32'd0;
      registers[20] <= 32'd0;
      registers[21] <= 32'd0;
      registers[22] <= 32'd0;
      registers[23] <= 32'd0;
      registers[24] <= 32'd0;
      registers[25] <= 32'd0;
      registers[26] <= 32'd0;
      registers[27] <= 32'd0;
      registers[28] <= 32'd0;
      registers[29] <= 32'd0;
      registers[30] <= 32'd0;
      registers[31] <= 32'd0;
`endif
    end
    else
`ifdef RV32I
    if (we && (rd != 5'd0))
      registers[rd] <= rd_data;
`else
    if (we && (rd != 5'd0) && ~rd[4])
      registers[rd] <= rd_data;
`endif
  end

endmodule
