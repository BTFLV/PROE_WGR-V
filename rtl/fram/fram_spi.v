`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief SPI-Steuerung für FRAM-Zugriffe.
 *
 * Dieses Modul erzeugt eine sequenzielle SPI-Kommunikation mit einem
 * FRAM-Baustein (z. B. MB85RS64V). Es verwendet Opcode-Sequenzen für
 * das Aktivieren der Schreibberechtigung (WREN), das Schreiben (WRITE)
 * und das Lesen (READ). Die Operation wird anhand der Signale `we`,
 * `re`, `address`, `write_data` gestartet. Nach Abschluss
 * meldet das Modul den Zustand mit `done`.
 *
 * @localparam OPCODE_WREN    SPI-Opcode zum Aktivieren des Schreibens
 * @localparam OPCODE_WRITE   SPI-Opcode zum Schreiben von Daten
 * @localparam OPCODE_READ    SPI-Opcode zum Lesen von Daten
 *
 * @localparam ST_IDLE        Leerlaufzustand (wartet auf we/re)
 * @localparam ST_WREN_INIT   Start der WREN-Sequenz
 * @localparam ST_WREN_SHIFT  Shiften der WREN-Bits
 * @localparam ST_WREN_DONE   Abschluss der WREN-Operation
 * @localparam ST_WRITE_INIT  Start der WRITE-Operation
 * @localparam ST_WRITE_SHIFT Shiften der Schreibdaten
 * @localparam ST_WRITE_DONE  Abschluss der Schreiboperation
 * @localparam ST_READ_INIT   Start der READ-Operation
 * @localparam ST_READ_SHIFT  Shiften der gelesenen Daten
 * @localparam ST_READ_DONE   Abschluss der Leseoperation
 *
 * @parameter CMD_WIDTH       Anzahl der zu shiftenden Bits für WRITE/READ (Adresse + Daten)
 * @parameter CMD_WIDTH_WREN  Anzahl der Bits für OPCODE_WREN
 *
 * @input  clk               Systemtakt
 * @input  rst_n             Asynchrones, aktives-LOW Reset
 * @input  [15:0] address    Zieladresse (für WRITE/READ)
 * @input  [31:0] write_data Zu schreibende 32-Bit-Daten
 * @input  we                Write-Enable (löst WRITE-Sequenz aus)
 * @input  re                Read-Enable  (löst READ-Sequenz aus)
 * @output reg [31:0]        read_data Ausgelesene 32-Bit-Daten
 * @output reg               done      Signalisiert Abschluss einer Operation
 *
 * @output reg               spi_mosi  SPI-Datenleitung Master->Slave
 * @input  wire              spi_miso  SPI-Datenleitung Slave->Master
 * @output reg               spi_clk   SPI-Takt
 * @output reg               spi_cs    SPI-Chip-Select (aktiv LOW)
 */

module fram_spi (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [15:0] address,
  input  wire [31:0] write_data,
  output reg  [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output reg         done,
  output reg         spi_mosi,
  input  wire        spi_miso,
  output reg         spi_clk,
  output reg         spi_cs
); 

  // ---------------------------------------------------------
  // Lokale Parameter (OPCODEs)
  // ---------------------------------------------------------
  localparam [7:0] OPCODE_WREN    = 8'h06;
  localparam [7:0] OPCODE_WRITE   = 8'h02;
  localparam [7:0] OPCODE_READ    = 8'h03;

  // ---------------------------------------------------------
  // Zustände des internen State-Automaten
  // ---------------------------------------------------------
  localparam [3:0] ST_IDLE        = 4'd0;
  localparam [3:0] ST_WREN_INIT   = 4'd1;
  localparam [3:0] ST_WREN_SHIFT  = 4'd2;
  localparam [3:0] ST_WREN_DONE   = 4'd3;
  localparam [3:0] ST_WRITE_INIT  = 4'd4;
  localparam [3:0] ST_WRITE_SHIFT = 4'd5;
  localparam [3:0] ST_WRITE_DONE  = 4'd6;
  localparam [3:0] ST_READ_INIT   = 4'd7;
  localparam [3:0] ST_READ_SHIFT  = 4'd8;
  localparam [3:0] ST_READ_DONE   = 4'd9;

  // ---------------------------------------------------------
  // Anzahl der zu shiftenden Bits:
  // - CMD_WIDTH: 8 (Opcode) + 16 (Adresse) + 32 (Daten) = 56
  // - CMD_WIDTH_WREN: 8 (nur Opcode WREN)
  // ---------------------------------------------------------
  localparam CMD_WIDTH            = 56;
  localparam CMD_WIDTH_WREN       = 8;

  // ---------------------------------------------------------
  // Registervariablen für Shift und Steuerung
  // ---------------------------------------------------------
  reg [55:0] shift_reg;
  reg [ 5:0] bit_count;
  reg [ 3:0] state;
  reg        spi_clk_en;
  reg        shifting;


  // ---------------------------------------------------------
  // SPI-Taktdesign: spi_sck (genannt spi_clk)
  // Wenn spi_clk_en=1, toggelt spi_clk
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      spi_sck <= 1'b0;
    else
    begin
      if (spi_clk_en)
        spi_sck <= ~spi_sck;
      else
        spi_sck <= 1'b0;
    end
  end

  // ---------------------------------------------------------
  // Hauptzustandsmaschine: WREN -> WRITE oder READ
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state      <= ST_IDLE;
      done       <= 1'b0;
      bit_count  <= 6'd0;
      spi_cs     <= 1'b1;
      spi_clk_en <= 1'b0;
      spi_mosi   <= 1'b0;
      read_data  <= 32'd0;
      shift_reg  <= 56'd0;
      shifting   <= 1'b0;
    end
    else
    begin
      done <= 1'b0;

      case (state)

        // -------------------------------------------------
        // ST_IDLE: Warten auf we (WRITE) oder re (READ)
        // -------------------------------------------------
        ST_IDLE:
        begin
          spi_cs  <= 1'b1;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          if (write_enable)
          begin
            shift_reg <= {OPCODE_WREN, 48'd0};
            state     <= ST_WREN_INIT;
          end
          else
          if (read_enable)
          begin
            shift_reg <= {OPCODE_READ, addr, 32'd0};
            state     <= ST_READ_INIT;
          end
        end

        // -------------------------------------------------
        // ST_WREN_INIT: CS low, shift_reg bereit für WREN
        // -------------------------------------------------
        ST_WREN_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_WREN_SHIFT;
        end

        // -------------------------------------------------
        // ST_WREN_SHIFT: Schiebe 8 Bit des WREN-Opcode raus
        // -------------------------------------------------
        ST_WREN_SHIFT:
        begin
          spi_clk_en <= 1'b1;
          shifting   <= 1'b1;
          if (bit_count == CMD_WIDTH_WREN)
          begin
            spi_cs  <= 1'b1;
            spi_clk_en <= 1'b0;
            shifting   <= 1'b0;
            state      <= ST_WREN_DONE;
          end
        end

        // -------------------------------------------------
        // ST_WREN_DONE: Jetzt WRITE vorbereiten
        // -------------------------------------------------
        ST_WREN_DONE:
        begin
          shift_reg <= {OPCODE_WRITE, addr, write_data};
          state     <= ST_WRITE_INIT;
        end

        // -------------------------------------------------
        // ST_WRITE_INIT: CS wieder runter, neu schieben
        // -------------------------------------------------
        ST_WRITE_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_WRITE_SHIFT;
        end

        // -------------------------------------------------
        // ST_WRITE_SHIFT: 56 Bit (8+16+32) werden geshiftet
        // -------------------------------------------------
        ST_WRITE_SHIFT:
        begin
          spi_clk_en <= 1'b1;
          shifting   <= 1'b1;
          if (bit_count == CMD_WIDTH)
          begin
            spi_cs  <= 1'b1;
            spi_clk_en <= 1'b0;
            shifting   <= 1'b0;
            state      <= ST_WRITE_DONE;
          end
        end

        // -------------------------------------------------
        // ST_WRITE_DONE: Fertig, done=1
        // -------------------------------------------------
        ST_WRITE_DONE:
        begin
          done  <= 1'b1;
          state <= ST_IDLE;
        end

        // -------------------------------------------------
        // ST_READ_INIT: CS runter, shift_reg bereit (OPCODE+Adress+Dummy)
        // -------------------------------------------------
        ST_READ_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_READ_SHIFT;
        end

        // -------------------------------------------------
        // ST_READ_SHIFT: 56 Bit werden geshiftet, wobei
        //   die letzten 32 Bits Daten vom FRAM sind.
        // -------------------------------------------------
        ST_READ_SHIFT:
        begin
          spi_clk_en <= 1'b1;
          shifting   <= 1'b1;
          if (bit_count == CMD_WIDTH)
          begin
            spi_cs  <= 1'b1;
            spi_clk_en <= 1'b0;
            shifting   <= 1'b0;
            state      <= ST_READ_DONE;
          end
        end

        // -------------------------------------------------
        // ST_READ_DONE: Aus shift_reg die empfangenen 32 Bits
        // -------------------------------------------------
        ST_READ_DONE:
        begin
          read_data <= shift_reg[31:0];
          done <= 1'b1;
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase

      // -------------------------------------------------------
      // Schiebe-Operation
      // Bei jeder fallenden Flanke von spi_clk: shift_reg[0] <= spi_miso
      // Bei jeder steigenden Flanke: shift_reg << 1
      // Hier realisiert über spi_sck == 0 / == 1-Abfragen
      // -------------------------------------------------------
      if (shifting)
      begin
        if (spi_sck == 1'b0)
        begin
          shift_reg <= {shift_reg[54:0], 1'b0};
          bit_count <= bit_count + 1;
        end
        else
        begin
          shift_reg[0] <= spi_miso;
        end
      end

      spi_mosi <= shift_reg[55];

    end
  end
endmodule
