`default_nettype none
`timescale 1ns / 1ns

module spi #(
  parameter FIFO_TX_DEPTH = 8,
  parameter FIFO_RX_DEPTH = 8
) (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output reg         spi_clk,
  output reg         spi_mosi,
  input  wire        spi_miso,
  output wire        spi_cs
);

  localparam CTRL_OFFSET     = 8'h00;
  localparam CLK_OFFSET      = 8'h04;
  localparam STATUS_OFFSET   = 8'h08;
  localparam TX_OFFSET       = 8'h0C;
  localparam RX_OFFSET       = 8'h10;
  localparam CS_OFFSET       = 8'h14;

  localparam STATE_IDLE      = 2'd0;
  localparam STATE_LOAD      = 2'd1;
  localparam STATE_LOAD_WAIT = 2'd2;
  localparam STATE_TRANSFER  = 2'd3;

  reg [15:0] spi_clk_div;
  reg [15:0] new_spi_clk_div;
  reg [16:0] clk_counter;
  reg [ 7:0] tx_shift;
  reg [ 7:0] rx_shift;
  reg [ 7:0] rx_fifo_din;
  reg [ 1:0] state;
  reg [ 3:0] bit_cnt;
  reg [ 1:0] spi_ctrl;
  reg tx_fifo_rd_en;
  reg rx_fifo_wr_en;
  reg rx_fifo_rd_en;
  reg read_flag;
  reg spi_clk_en;
  reg active;
  reg cs;
  reg cs_gen;
  reg cs_manual;
  reg cs_manual_next;

  wire [8:0] tx_fifo_din;
  wire [8:0] tx_fifo_dout;
  wire [7:0] rx_fifo_dout;
  wire [7:0] status_bits;
  wire clk_div_zero;
  wire spi_busy;
  wire spi_ready;
  wire tx_fifo_wr_en;
  wire tx_fifo_empty;
  wire tx_fifo_full;
  wire rx_fifo_empty;
  wire rx_fifo_full;
  wire fifo_full;

  assign clk_div_zero     = (~|spi_clk_div);
  assign spi_busy         = (state != STATE_IDLE);
  assign fifo_full        = rx_fifo_full | tx_fifo_full;
  assign spi_ready        = !spi_busy & tx_fifo_empty & rx_fifo_empty;
  assign status_bits      = {clk_div_zero, fifo_full, spi_ready, spi_busy, rx_fifo_full, rx_fifo_empty, tx_fifo_full, tx_fifo_empty};
  assign tx_fifo_din[8:0] = write_data[8:0];
  assign tx_fifo_wr_en    = we && (address[7:0] == TX_OFFSET);
  assign spi_cs           = cs_gen ? cs : cs_manual;

  fifo #(
    .DATA_WIDTH (9),
    .DEPTH      (FIFO_TX_DEPTH)
  ) spi_tx_fifo (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (tx_fifo_wr_en),
    .rd_en (tx_fifo_rd_en),
    .din   (tx_fifo_din),
    .dout  (tx_fifo_dout),
    .empty (tx_fifo_empty),
    .full  (tx_fifo_full)
  );

  fifo #(
    .DATA_WIDTH (8),
    .DEPTH      (FIFO_RX_DEPTH)
  ) spi_rx_fifo (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (rx_fifo_wr_en),
    .rd_en (rx_fifo_rd_en),
    .din   (rx_fifo_din),
    .dout  (rx_fifo_dout),
    .empty (rx_fifo_empty),
    .full  (rx_fifo_full)
  );

  assign read_data = (address[7:0] == CTRL_OFFSET)   ? {30'd0, cs_gen, active} :
                     (address[7:0] == CLK_OFFSET)    ? {16'd0,    spi_clk_div} :
                     (address[7:0] == STATUS_OFFSET) ? {24'd0,    status_bits} :
                     (address[7:0] == RX_OFFSET)     ? {24'd0,   rx_fifo_dout} :
                     (address[7:0] == CS_OFFSET)     ? {31'd0,      cs_manual} :
                     32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      clk_counter <= 16'b0;
      spi_clk_en <= 1'b0;
    end
    else
    begin

      if (state == STATE_LOAD)
      begin
        clk_counter <= 16'b1;
        spi_clk_en <= 1'b0;

      end
      else if (clk_counter >= {spi_clk_div[15: 0], ~|spi_clk_div})
      begin
        clk_counter <= 16'b1;
        spi_clk_en <= 1'b1;

      end
      else
      begin
        clk_counter <= clk_counter + 16'b1;
        spi_clk_en <= 1'b0;
      end

    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state         <= STATE_IDLE;
      cs            <= 1'b1;
      cs_manual     <= 1'b1;
      spi_clk       <= 1'b0;
      bit_cnt       <= 4'b0;
      tx_shift      <= 8'b0;
      rx_shift      <= 8'b0;
      read_flag     <= 1'b0;
      tx_fifo_rd_en <= 1'b0;
      rx_fifo_wr_en <= 1'b0;
      spi_mosi      <= 1'b0;
    end
    else
    begin

      tx_fifo_rd_en <= 1'b0;
      rx_fifo_wr_en <= 1'b0;

      case (state)

        STATE_IDLE:
        begin
          cs_manual <= cs_manual_next;
          cs      <= 1'b1;
          spi_clk <= 1'b0;
          bit_cnt <= 4'b0;

          if (active && !tx_fifo_empty)
          begin
            cs            <= 1'b0;
            tx_shift      <= tx_fifo_dout[7:0];
            tx_fifo_rd_en <= 1'b0;
            state         <= STATE_LOAD;
          end
        end

        STATE_LOAD:
        begin
          tx_fifo_rd_en <= 1'b1;
          state         <= STATE_LOAD_WAIT;
          cs            <= 1'b0;
        end

        STATE_LOAD_WAIT:
        begin
          tx_shift      <= tx_fifo_dout[7:0];
          read_flag     <= tx_fifo_dout[8];
          tx_fifo_rd_en <= 1'b0;
          rx_shift      <= 8'd0;
          bit_cnt       <= 4'b0;
          spi_clk       <= 1'b0;
          spi_mosi      <= tx_fifo_dout[7];
          state         <= STATE_TRANSFER;
        end

        STATE_TRANSFER:
        begin
          if (spi_clk_en)
          begin
            if (spi_clk == 0)
            begin
              spi_clk <= 1'b1;

              if (bit_cnt <= 3'd7)
              begin
                rx_shift[3'd7 - bit_cnt[2:0]] <= spi_miso;
              end
            end
            else
            begin
              spi_clk <= 1'b0;

              if (bit_cnt < 3'd7)
              begin
                bit_cnt  <= bit_cnt + 4'b1;
                spi_mosi <= tx_shift[3'd6 - bit_cnt[2: 0]];
              end
              else
              begin
                if (read_flag)
                begin
                  rx_fifo_din   <= rx_shift;
                  rx_fifo_wr_en <= 1'b1;
                end

                if (!tx_fifo_empty)
                begin
                  state <= STATE_LOAD;
                  //tx_fifo_rd_en <= 1'b1;
                end
                else
                begin
                  cs     <= 1'b1;
                  state  <= STATE_IDLE;
                end
              end
            end
          end
          else
            state <= STATE_TRANSFER;
        end

        default:
          state <= STATE_IDLE;

      endcase
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      active          <= 1'b1;
      cs_manual_next  <= 1'b1;
      cs_gen          <= 1'b1;
      spi_clk_div     <= 16'd0;
      new_spi_clk_div <= 16'd0;
    end
    else if (we)
    begin

      case (address[7:0])

        CTRL_OFFSET:
        begin
          active   <= write_data[0];
          cs_gen   <= write_data[1];
        end

        CLK_OFFSET:
        begin
          new_spi_clk_div <= write_data;
        end
        
        CS_OFFSET:
        begin
          cs_manual_next <= ~write_data[0];
        end

        default : ;

      endcase

    end
    else if (spi_ready)
      spi_clk_div <= new_spi_clk_div;
  end

endmodule
