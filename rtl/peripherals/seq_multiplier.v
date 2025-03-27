`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Sequentieller Multiplikator.
 *
 * Dieses Modul implementiert eine sequentielle Multiplikation zweier
 * 32-Bit-Werte. Die Multiplikation erfolgt durch aufeinanderfolgende
 * Additionen basierend auf den Bits des Multiplikators.
 *
 * Das Modul ist speicherabbildbasiert und kann über Adressen gesteuert werden:
 * - `MUL1_OFFSET`: Erster Multiplikand.
 * - `MUL2_OFFSET`: Zweiter Multiplikator (startet die Berechnung).
 * - `RESH_OFFSET`: Höhere 32 Bits des Ergebnisses.
 * - `RESL_OFFSET`: Niedrigere 32 Bits des Ergebnisses.
 * - `INFO_OFFSET`: Gibt an, ob die Berechnung noch läuft (`busy`).
 *
 * @localparam INFO_OFFSET Adresse für den Status (`busy`-Bit).
 * @localparam MUL1_OFFSET Adresse für den ersten Multiplikanden.
 * @localparam MUL2_OFFSET Adresse für den zweiten Multiplikator (startet Berechnung).
 * @localparam RESH_OFFSET Adresse für die höheren 32 Bit des Ergebnisses.
 * @localparam RESL_OFFSET Adresse für die niedrigeren 32 Bit des Ergebnisses.
 *
 * @input clk         Systemtakt.
 * @input rst_n       Aktiv-low Reset.
 * @input address     Speicheradresse für den Zugriff auf Register.
 * @input write_data  Daten, die in die ausgewählten Register geschrieben werden sollen.
 * @output read_data  Zu lesende Daten basierend auf der Adresse.
 * @input we          Schreibaktivierungssignal (Write-Enable).
 * @input re          Leseaktivierungssignal (Read-Enable).
 */
module seq_multiplier (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re
);

  // -------------------------------------------------------
  // Lokale Adress-Offsets für die Register
  // -------------------------------------------------------
  localparam INFO_OFFSET = 8'h00;
  localparam MUL1_OFFSET = 8'h04;
  localparam MUL2_OFFSET = 8'h08;
  localparam RESH_OFFSET = 8'h0C;
  localparam RESL_OFFSET = 8'h10;

  // -------------------------------------------------------
  // Register für Multiplikanden, Ergebnis und Steuerung
  // -------------------------------------------------------
  reg [31:0] multiplicand;
  reg [31:0] multiplier;
  reg [63:0] product;
  reg [ 5:0] bit_index;
  reg        busy;

  // -------------------------------------------------------
  // Leseausgabe: Je nach Adress-Offset wird entsprechender
  // Registerinhalt oder Status zurückgegeben.
  // -------------------------------------------------------
  assign read_data = (address == INFO_OFFSET) ? {31'd0, busy} :
                     (address == MUL1_OFFSET) ? multiplicand  :
                     (address == MUL2_OFFSET) ? multiplier    :
                     (address == RESH_OFFSET) ? product[63:32]:
                     (address == RESL_OFFSET) ? product[31: 0]:
                     32'd0;

  // -------------------------------------------------------
  // Sequentielle Abarbeitung der Multiplikation
  // -------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      // Initialisierung bei Reset
      multiplicand <= 32'd0;
      multiplier   <= 32'd0;
      product      <= 64'd0;
      bit_index    <= 6'd0;
      busy         <= 1'b0;
    end
    else
    begin
      // Behandlung von Bus-Schreibzugriffen
      if (we)
      begin
        case (address)
          MUL1_OFFSET: begin
            // Schreiben des ersten Multiplikanden
            multiplicand <= write_data;
          end
          MUL2_OFFSET: begin
            // Schreiben des zweiten Multiplikators -> Start der Multiplikation
            multiplier <= write_data;
            product    <= 64'd0;
            bit_index  <= 6'd31;
            busy       <= 1'b1;
          end
        endcase
      end

      // Wenn busy = 1, läuft die sequentielle Multiplikation
      if (busy)
      begin
        if (multiplier[bit_index])
        begin
          product <= product + ((64'd1 << bit_index) * multiplicand);
        end

        // Bitzähler reduzieren
        if (bit_index == 0)
        begin
          // Sobald alle Bits durch sind, ist die Multiplikation abgeschlossen
          busy <= 1'b0;
        end
        else
        begin
          bit_index <= bit_index - 1;
        end
      end
    end
  end

endmodule
