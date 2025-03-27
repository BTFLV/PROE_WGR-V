`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Sequentieller Divider (Divisionseinheit).
 *
 * Dieses Modul führt eine sequentielle Division zweier 32-Bit-Werte durch.
 * Dabei wird fortlaufend ein Teil des Dividenden mit dem Divisor verglichen
 * und angepasst. Das Modul ist über ein Register-Interface ansprechbar:
 * - `INFO_OFFSET`: Enthält das `busy`-Bit (Division noch aktiv).
 * - `END_OFFSET` : Speicherort für den Dividenden (Endwert).
 * - `SOR_OFFSET` : Speicherort für den Divisor (Startet die Division).
 * - `QUO_OFFSET` : Liefert das Ergebnis (Quotient).
 * - `REM_OFFSET` : Liefert den Restwert (Remainder).
 *
 * @localparam INFO_OFFSET Offset für das Statusregister (busy).
 * @localparam END_OFFSET  Offset für den Dividenden.
 * @localparam SOR_OFFSET  Offset für den Divisor (startet Division).
 * @localparam QUO_OFFSET  Offset für den Quotienten.
 * @localparam REM_OFFSET  Offset für den Rest.
 *
 * @input  clk               Systemtakt.
 * @input  rst_n             Aktiv-low Reset.
 * @input  [7:0] address     Adresse für den Registerzugriff.
 * @input  [31:0] write_data Daten, die z. B. Dividenden/Divisor setzen.
*  @output [31:0] read_data  Ausgabedaten basierend auf address.
 * @input  we                Schreibaktivierungssignal (Write-Enable).
 * @input  re                Leseaktivierungssignal (Read-Enable).
 */

module seq_divider ( 
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re
);


  // ---------------------------------------------------------
  // Lokale Adress-Offsets für das Register-Interface
  // ---------------------------------------------------------
  localparam INFO_OFFSET = 8'h00; 
  localparam END_OFFSET  = 8'h04; 
  localparam SOR_OFFSET  = 8'h08; 
  localparam QUO_OFFSET  = 8'h0C; 
  localparam REM_OFFSET  = 8'h10;

  // ---------------------------------------------------------
  // Register für Dividenden, Divisor, Quotient und Rest
  // dvdend_tmp dient als Arbeitsregister (64 Bit),
  // um den Dividenden hochzuschieben und den Rest auszuarbeiten.
  // ---------------------------------------------------------
  reg [31:0] dividend; // Gespeicherter Dividendenwert
  reg [31:0] divisor;  // Gespeicherter Divisor
  reg [63:0] dvdend_tmp; // Temporäre 64-Bit-Repräsentation des Dividenden
  reg [31:0] quotient;  // Quotient
  reg [31:0] remainder; // Rest
  reg [ 5:0] bit_index; // Zähler für 32-Bit schrittweise Division
  reg        busy;  // Signalisiert laufende Division

  // ---------------------------------------------------------
  // Lesezugriffe: abhängig vom Offset wird das passende
  // Register oder das busy-Bit zurückgegeben.
  // ---------------------------------------------------------
  assign read_data = (address == INFO_OFFSET) ? {31'd0, busy} : 
                     (address == END_OFFSET)  ?  dividend     : 
                     (address == SOR_OFFSET)  ?  divisor      : 
                     (address == QUO_OFFSET)  ?  quotient     : 
                     (address == REM_OFFSET)  ?  remainder    : 
                     32'd0;


  // ---------------------------------------------------------
  // Sequentieller Ablauf:
  // - Schreiben von dividend und divisor startet Berechnung.
  // - Der Divisor wird sukzessive vom oberen Teil des Dividenden
  //   subtrahiert (wenn möglich), das Ergebnis fließt in quotient.
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      dividend   <= 32'd0;
      divisor    <= 32'd0;
      quotient   <= 32'd0;
      remainder  <= 32'd0;
      dvdend_tmp <= 64'd0;
      bit_index  <= 6'd0;
      busy       <= 1'b0;
    end
    else
    begin
      // Verarbeiten von Write-Zugriffen
      if (we)
      begin
        case (address)

          END_OFFSET:
          begin
            // Setzt den Dividenden und initialisiert das Arbeitsregister
            dividend   <= write_data;
            dvdend_tmp <= {32'd0, write_data}; 
            quotient   <= 32'd0;
            remainder  <= 32'd0;
          end

          SOR_OFFSET:
          begin
            // Setzt den Divisor und aktiviert die Division
            divisor    <= write_data;
            bit_index  <= 6'd31;
            busy       <= 1'b1;
          end

        endcase
      end


      // Division in kleinen Schritten, solange busy=1
      if (busy)
      begin
        // Jede Iteration: 
        // 1) Schiebe das 64-Bit-Fenster nach links (dvdend_tmp << 1),
        // 2) Schiebe quotient nach links, 
        // 3) teste, ob Divisor subtrahierbar ist.
        dvdend_tmp <= dvdend_tmp << 1;
        quotient   <= quotient << 1;

        // Prüfe den oberen 32-Bit-Teil gegen divisor
        if (dvdend_tmp[63:32] >= divisor)
        begin
          dvdend_tmp[63:32] <= dvdend_tmp[63:32] - divisor;
          quotient[0] = 1;
        end

        // Sobald alle Bits bearbeitet sind, legen wir remainder fest.
        if (bit_index == 0)
        begin
          remainder <= dvdend_tmp[63:32];
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
