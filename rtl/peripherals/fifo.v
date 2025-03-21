`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Ein einfacher FIFO-Speicher.
 *
 * Dieser FIFO (First-In-First-Out) Puffer speichert Daten mit einer
 * konfigurierbaren Breite (`DATA_WIDTH`) und Tiefe (`DEPTH`). Daten
 * werden über das `wr_en` Signal hineingeschrieben und über das
 * `rd_en` Signal ausgelesen. Das Modul liefert die Signale `empty`
 * und `full`, um anzuzeigen, ob weitere Lese- oder Schreibvorgänge
 * möglich sind.
 *
 * @parameter DATA_WIDTH Breite der gespeicherten Daten in Bits.
 * @parameter DEPTH      Anzahl der Einträge im FIFO.
 *
 * @localparam ADDR_WIDTH Breite der Adresszeiger basierend auf `DEPTH`.
 *
 * @input clk      Systemtakt.
 * @input rst_n    Aktiv-low Reset.
 * @input wr_en    Aktivierungssignal (Write-Enable) zum Schreiben in den FIFO.
 * @input rd_en    Aktivierungssignal (Read-Enable) zum Lesen aus dem FIFO.
 * @input din      Eingangsdaten mit Breite `DATA_WIDTH`.
 *
 * @ouput empty    Signal, das anzeigt, ob der FIFO leer ist.
 * @ouput full     Signal, das anzeigt, ob der FIFO voll ist.
 * @ouput dout     Ausgangsdaten mit Breite `DATA_WIDTH`.
 */
module fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 16
  ) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    output wire                  empty,
    output wire                  full,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
  );

  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [ADDR_WIDTH  :0]    rd_ptr;
  reg [ADDR_WIDTH  :0]    wr_ptr;
  reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];

  reg wr_en_prev;
  reg rd_en_prev;

  wire [ADDR_WIDTH: 0] next_wr;

  assign empty   = (rd_ptr  == wr_ptr);
  
  assign full    = (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]) &&
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
                   
  assign next_wr = (wr_ptr   + 1);

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      wr_en_prev <= 0;
      rd_en_prev <= 0;
    end
    else
    begin
      wr_en_prev <= wr_en;
      rd_en_prev <= rd_en;

      if (wr_en && !wr_en_prev && !full)
      begin
        mem[wr_ptr[ADDR_WIDTH - 1: 0]] <= din;
        wr_ptr <= next_wr;
      end

      if (rd_en && !rd_en_prev && !empty)
      begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  assign dout = empty ? {DATA_WIDTH{1'b0}} : mem[rd_ptr[ADDR_WIDTH - 1 : 0]];

endmodule
