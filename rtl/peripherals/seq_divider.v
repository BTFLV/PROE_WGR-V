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
  reg [31:0] dividend;
  reg [31:0] divisor;
  reg [63:0] dvdend_tmp;
  reg [31:0] quotient;
  reg [31:0] remainder;
  reg [ 5:0] bit_index;
  reg        busy;

  // ---------------------------------------------------------
  // Kombinatorische Signale für die Division (Shift + Vergleich)
  // ---------------------------------------------------------
  wire [63:0] shifted_tmp;
  wire [31:0] shifted_upper;
  wire [31:0] sub_result;
  wire        cmp_ge;

  assign shifted_tmp   = {dvdend_tmp[62:0], 1'b0};
  assign shifted_upper = shifted_tmp[63:32];
  assign sub_result    = shifted_upper - divisor;
  assign cmp_ge        = (shifted_upper >= divisor);

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
  // - Restoring Division: Pro Takt wird dvdend_tmp nach links
  //   geschoben. Ist der obere Teil >= divisor, wird subtrahiert
  //   und das jeweilige Quotientenbit gesetzt.
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
            dividend   <= write_data;
            dvdend_tmp <= {32'd0, write_data}; 
            quotient   <= 32'd0;
            remainder  <= 32'd0;
          end

          SOR_OFFSET:
          begin
            divisor    <= write_data;
            bit_index  <= 6'd31;
            busy       <= 1'b1;
          end

        endcase
      end

      // Division in kleinen Schritten, solange busy=1
      if (busy)
      begin
        if (cmp_ge)
        begin
          dvdend_tmp <= {sub_result, shifted_tmp[31:0]};
          quotient   <= {quotient[30:0], 1'b1};
        end
        else
        begin
          dvdend_tmp <= shifted_tmp;
          quotient   <= {quotient[30:0], 1'b0};
        end

        if (bit_index == 0)
        begin
          remainder <= cmp_ge ? sub_result : shifted_upper;
          busy      <= 1'b0;
        end
        else
        begin
          bit_index <= bit_index - 1;
        end
      end
    end
  end

endmodule
