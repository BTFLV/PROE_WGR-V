`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Verilog-Modell des FRAM-Bausteins MB85RS64V.
 *
 * Dieses Modul simuliert den internen SPI-Verhaltensablauf des
 * MB85RS64V-Fram-Speichers. Es reagiert auf die üblichen FRAM-OPCODES
 * (WRITE, READ, WREN) und unterstützt das Speichern von Daten in einem
 * internen Memory-Array. Das Modul ist nur für Simulation und
 * Verifikationszwecke gedacht und ersetzt in der Hardware ein
 * externes FRAM-Bauteil.
 *
 * Zustandsautomat:
 * - STATE_OPCODE:     Auswerten des eingehenden Opcodes (WREN, WRITE, READ)
 * - STATE_ADDR:       Erfassen der Adresse (2 Bytes)
 * - STATE_WRITE_DATA: Schreiben der ankommenden Bytes in Memory
 * - STATE_READ_DATA:  Ausgeben der gewünschten Bytes aus Memory
 *
 * @localparam OP_WRITE         SPI-Opcode für Schreibzugriff
 * @localparam OP_READ          SPI-Opcode für Lesezugriff
 * @localparam OP_WREN          SPI-Opcode für Write Enable
 * @localparam STATE_OPCODE     Zustand zum Erfassen des Opcodes
 * @localparam STATE_ADDR       Zustand zum Erfassen der Adresse
 * @localparam STATE_WRITE_DATA Zustand zum Schreiben der Daten ins Memory
 * @localparam STATE_READ_DATA  Zustand zum Auslesen der Daten
 *
 * @input  clk          Systemtakt
 * @input  rst_n        Asynchrones, aktives-LOW Reset
 * @input  spi_mosi     SPI-Datenleitung Master->Slave
 * @output reg spi_miso SPI-Datenleitung Slave->Master
 * @input  spi_clk      SPI-Takt
 * @input  spi_cs       SPI-Chip-Select (aktiv LOW)
 */

module mb85rs64v (
    input  wire clk,
    input  wire rst_n,
    input  wire spi_mosi,
    output reg  spi_miso,
    input  wire spi_clk,
    input  wire spi_cs
);


  // ---------------------------------------------------------
  // Lokale Konstanten / OPCODES
  // ---------------------------------------------------------
  localparam OP_WRITE = 8'h02;
  localparam OP_READ  = 8'h03;
  localparam OP_WREN  = 8'h06;

  // ---------------------------------------------------------
  // Zustandsdefinitionen
  // ---------------------------------------------------------
  localparam STATE_OPCODE     = 2'd0;
  localparam STATE_ADDR       = 2'd1;
  localparam STATE_WRITE_DATA = 2'd2;
  localparam STATE_READ_DATA  = 2'd3;

  // ---------------------------------------------------------
  // Internes Memory-Array (z. B. 8k x 8 Bit = 64 KBit)
  // ---------------------------------------------------------
  reg [ 7:0] memory[0:8191];

  // ---------------------------------------------------------
  // Registervariablen für OPCODE, Adresse, Daten etc.
  // ---------------------------------------------------------
  reg [15:0] address;
  reg [15:0] address_shift;
  reg [ 7:0] opcode;
  reg [ 7:0] opcode_shift;
  reg [ 7:0] tx_reg;
  reg [ 7:0] data_shift;
  reg [ 3:0] bit_cnt_tx;
  reg [ 3:0] bit_cnt_rx;
  reg [ 1:0] state;
  reg        spi_clk_prev;
  reg        cs_prev;
  reg        wel;

  // ---------------------------------------------------------
  // SPI-Signal-Flankenerkennung
  // - spi_clk_prev, cs_prev merken letzten Zustand
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state         <= STATE_OPCODE;
      opcode        <= 8'd0;
      opcode_shift  <= 8'd0;
      address_shift <= 16'd0;
      data_shift    <= 8'd0;
      bit_cnt_rx    <= 4'd0;
      bit_cnt_tx    <= 4'd0;
      tx_reg        <= 8'd0;
      wel           <= 1'b0;
      spi_miso      <= 1'b0;
      spi_clk_prev  <= 1'b0;
      cs_prev       <= 1'b1;
      address       <= 16'd0;
    end
    else
    begin
      // Merken des vorherigen SPI-Takt- und CS-Zustands
      spi_clk_prev <= spi_clk;
      cs_prev      <= spi_cs;

      // Wenn spi_cs = 1, wird State-Logik zurückgesetzt
      if (spi_cs)
      begin
        state         <= STATE_OPCODE;
        bit_cnt_rx    <= 4'd0;
        bit_cnt_tx    <= 4'd0;
        opcode_shift  <= 8'd0;
        address_shift <= 16'd0;
        data_shift    <= 8'd0;
        address       <= 16'd0;
        // Wenn ein Write-Opcode beendet wird, wel=0
        if (opcode == OP_WRITE)
          wel         <= 1'b0;
      end
      else
      begin
        // Flankenauswertung: steigende Flanke spi_clk
        if (spi_clk && !spi_clk_prev)
        begin
          case (state)


            // ---------------------------------------------
            // STATE_OPCODE: Zunächst 8 Bits für den OPCODE
            // ---------------------------------------------
            STATE_OPCODE:
            begin
              opcode_shift <= {opcode_shift[6:0], spi_mosi};
              bit_cnt_rx   <= bit_cnt_rx + 1;
              if (bit_cnt_rx == 4'd7)
              begin
                opcode       <= {opcode_shift[6:0], spi_mosi};
                bit_cnt_rx   <= 4'd0;
                opcode_shift <= 8'd0;
                if ({opcode_shift[6:0], spi_mosi} == OP_WREN)
                  wel <= 1'b1;
                else
                  state <= STATE_ADDR;
              end
            end

            // ---------------------------------------------
            // STATE_ADDR: 2 Bytes Adresse (16 Bit)
            // ---------------------------------------------
            STATE_ADDR:
            begin
              address_shift <= {address_shift[14:0], spi_mosi};
              bit_cnt_rx <= bit_cnt_rx + 1;
              if (bit_cnt_rx == 4'd15)
              begin
                tx_reg     <= memory[{address_shift[14:0], spi_mosi}];
                address    <= {address_shift[14:0], spi_mosi};
                bit_cnt_rx <= 4'd0;
                if (opcode == OP_READ)
                begin
                  state      <= STATE_READ_DATA;
                  bit_cnt_tx <= 4'd0;
                  spi_miso   <= memory[{address_shift[14:0], spi_mosi}][7];
                end
                else
                if (opcode == OP_WRITE)
                begin
                  if (wel)
                    state <= STATE_WRITE_DATA;
                  else
                    state <= STATE_OPCODE;
                end
                else
                  state <= STATE_OPCODE;
              end
            end

            // ---------------------------------------------
            // STATE_ADDR: 2 Bytes Adresse (16 Bit)
            // ---------------------------------------------
            STATE_WRITE_DATA:
            begin
              if (bit_cnt_rx == 4'd7)
              begin
                memory[(address[12:0])] <= {data_shift[6:0], spi_mosi};
                bit_cnt_rx              <= 4'd0;
                data_shift              <= 8'd0;
                address                 <= address + 1;
              end
              else
              begin
                data_shift <= {data_shift[6:0], spi_mosi};
                bit_cnt_rx <= bit_cnt_rx + 1;
              end
            end

            // ---------------------------------------------
            // STATE_ADDR: 2 Bytes Adresse (16 Bit)
            // ---------------------------------------------
            STATE_READ_DATA:
            begin
              if (bit_cnt_tx == 4'd7)
              begin
                bit_cnt_tx <= 4'd0;
                address    <= address + 1;
                tx_reg     <= memory[address + 1];
                spi_miso   <= memory[(address + 1)][7];
              end
              else
              begin
                spi_miso   <= tx_reg[6];
                tx_reg     <= {tx_reg[6:0], 1'b0};
                bit_cnt_tx <= bit_cnt_tx + 1;
              end
            end

            default:
              state <= STATE_OPCODE;

          endcase
        end
      end
    end
  end

endmodule
