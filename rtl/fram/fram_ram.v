`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Abstraktes FRAM-Zugriffsmodul, das nach außen wie RAM erscheint,
 * intern jedoch über SPI kommuniziert.
 *
 * Dieses Modul nimmt Lese- und Schreibanforderungen (über address, we, re) entgegen
 * und leitet sie an das `fram_spi`-Modul weiter. Nach Abschluss der SPI-Operation
 * wird `read_data` gültig, bzw. die Schreiboperation ist abgeschlossen.
 * Ein `req_ready`-Signal zeigt an, wann das Modul wieder bereit für neue Befehle ist.
 *
 * @localparam ST_IDLE  Leerlaufzustand (wartet auf we/re)
 * @localparam ST_START Vorbereitung der SPI-Operation (Adress-/Datenübergabe)
 * @localparam ST_WAIT  Wartezustand, bis `fram_spi` fertigsignalisiert
 * @localparam ST_DONE  Abschluss der Operation, Daten liegen vor, req_ready=1
 *
 * @input  clk               Systemtakt
 * @input  rst_n             Asynchrones, aktives-LOW Reset
 * @output reg req_ready     Signal, das anzeigt, ob ein neuer Lese-/Schreibzugriff
 *                           entgegen genommen werden kann
 * @input  [15:0] address    Adress-Eingang (16 Bit, FRAM-Adressbereich)
 * @input  [31:0] write_data Daten, die bei we=1 in den FRAM geschrieben werden
 * @input  we                Schreibeaktivierung (Write Enable)
 * @input  re                Leseaktivierung (Read Enable)
 * @output reg [31:0]        read_data  Ausgelesene Daten bei einem Lesezugriff
 *
 * @output spi_mosi          SPI-Ausgang (Master Out, Slave In)
 * @input  spi_miso          SPI-Eingang (Master In, Slave Out)
 * @output spi_clk           SPI-Taktleitung
 * @output spi_cs            SPI-Chip-Select
 */

module fram_ram (
    input  wire        clk,
    input  wire        rst_n,
    output reg         req_ready,
    input  wire [15:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    input  wire        we,
    input  wire        re,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_clk,
    output wire        spi_cs,
);


  // ---------------------------------------------------------
  // Zustandsdefinitionen für die interne Steuerung
  // ---------------------------------------------------------
  localparam [2:0] ST_IDLE  = 3'd0;
  localparam [2:0] ST_START = 3'd1;
  localparam [2:0] ST_WAIT  = 3'd2;
  localparam [2:0] ST_DONE  = 3'd3;
  
  // ---------------------------------------------------------
  // Registervariablen
  // ---------------------------------------------------------
  reg  [31:0] spi_write_data;
  reg  [31:0] lat_write_data;
  reg  [15:0] spi_address;
  reg  [15:0] lat_address;
  reg  [ 2:0] state;
  reg         spi_we;
  reg         latched_we;
  reg         spi_re;


  // ---------------------------------------------------------
  // Rückgabedaten und Status von fram_spi
  // ---------------------------------------------------------
  wire [31:0] spi_read_data;
  wire        spi_done;

  // ---------------------------------------------------------
  // Instanzierung des FRAM-SPI-Moduls
  // ---------------------------------------------------------
  fram_spi fram_spi_inst (
    .clk         (clk),
    .rst_n       (rst_n),
    .address     (spi_address),
    .write_data  (spi_write_data),
    .read_data   (spi_read_data),
    .we          (spi_we),
    .re          (spi_re),
    .done        (spi_done),
    .spi_mosi    (spi_mosi),
    .spi_miso    (spi_miso),
    .spi_clk     (spi_clk),
    .spi_cs      (spi_cs)
  );


  // ---------------------------------------------------------
  // Zustandsmaschine zur Abwicklung eines Lese-/Schreibzugriffs
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
    begin
      state          <= ST_IDLE;
      req_ready      <= 1'b1;
      latched_we     <= 1'b0;
      lat_address    <= 16'd0;
      lat_write_data <= 32'd0;
      read_data      <= 32'd0;
      spi_re         <= 1'b0;
      spi_we         <= 1'b0;
      spi_address    <= 16'd0;
      spi_write_data <= 32'd0;
    end
    else
    begin
      spi_we <= 1'b0;
      spi_re <= 1'b0;

      case (state)
        
        // ---------------------------------------------------
        // ST_IDLE: Warten auf we oder re
        // ---------------------------------------------------
        ST_IDLE: begin
          if (we || re)
          begin
            lat_address    <= address;
            lat_write_data <= write_data;
            latched_we     <= we;
            req_ready      <= 1'b0;
            state          <= ST_START;
          end
          else
            req_ready <= 1'b1;
        end


        // ---------------------------------------------------
        // ST_START: Setze Parameter für fram_spi
        // ---------------------------------------------------
        ST_START:
        begin
          spi_address    <= lat_address;
          spi_write_data <= lat_write_data;

          if (latched_we) 
            spi_we <= 1'b1;
          else 
            spi_re  <= 1'b1;

          state <= ST_WAIT;
        end

        // ---------------------------------------------------
        // ST_WAIT: Warten, bis fram_spi fertig signalisiert (spi_done)
        // ---------------------------------------------------
        ST_WAIT:
        begin
          if (spi_done) 
          begin
            if (!latched_we) 
              read_data <= spi_read_data;

            state <= ST_DONE;
          end
        end

        // ---------------------------------------------------
        // ST_DONE: Vorgang abgeschlossen, req_ready = 1
        // ---------------------------------------------------
        ST_DONE:
        begin
          req_ready <= 1'b1;
          state     <= ST_IDLE;
        end

        default:
          state <= ST_IDLE;

      endcase
    end
  end

endmodule
