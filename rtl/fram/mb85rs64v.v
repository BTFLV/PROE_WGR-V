`default_nettype none
`timescale 1ns / 1ns

module mb85rs64v (
    input  wire clk,
    input  wire rst_n,
    input  wire spi_mosi,
    output reg  spi_miso,
    input  wire spi_clk,
    input  wire spi_cs
);

  localparam OP_WRITE = 8'h02;
  localparam OP_READ  = 8'h03;
  localparam OP_WREN  = 8'h06;

  localparam STATE_OPCODE     = 2'd0;
  localparam STATE_ADDR       = 2'd1;
  localparam STATE_WRITE_DATA = 2'd2;
  localparam STATE_READ_DATA  = 2'd3;

  reg [ 7:0] memory[0:8191];

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
      spi_clk_prev <= spi_clk;
      cs_prev      <= spi_cs;

      if (spi_cs)
      begin
        state         <= STATE_OPCODE;
        bit_cnt_rx    <= 4'd0;
        bit_cnt_tx    <= 4'd0;
        opcode_shift  <= 8'd0;
        address_shift <= 16'd0;
        data_shift    <= 8'd0;
        address       <= 16'd0;
        if (opcode == OP_WRITE)
          wel         <= 1'b0;
      end
      else
      begin
        if (spi_clk && !spi_clk_prev)
        begin
          case (state)

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
