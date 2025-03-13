`default_nettype none
`timescale 1ns / 1ns

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

  localparam [7:0] OPCODE_WREN    = 8'h06;
  localparam [7:0] OPCODE_WRITE   = 8'h02;
  localparam [7:0] OPCODE_READ    = 8'h03;
  
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

  localparam CMD_WIDTH            = 56;
  localparam CMD_WIDTH_WREN       = 8;

  reg [55:0] shift_reg;
  reg [ 5:0] bit_count;
  reg [ 3:0] state;
  reg        spi_clk_en;
  reg        shifting;

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

        ST_WREN_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_WREN_SHIFT;
        end

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

        ST_WREN_DONE:
        begin
          shift_reg <= {OPCODE_WRITE, addr, write_data};
          state     <= ST_WRITE_INIT;
        end

        ST_WRITE_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_WRITE_SHIFT;
        end

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

        ST_WRITE_DONE:
        begin
          done  <= 1'b1;
          state <= ST_IDLE;
        end

        ST_READ_INIT:
        begin
          spi_cs  <= 1'b0;
          spi_clk_en <= 1'b0;
          bit_count  <= 6'd0;
          shifting   <= 1'b0;
          spi_mosi   <= shift_reg[55];
          state      <= ST_READ_SHIFT;
        end

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

        ST_READ_DONE:
        begin
          read_data <= shift_reg[31:0];
          done <= 1'b1;
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase

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
