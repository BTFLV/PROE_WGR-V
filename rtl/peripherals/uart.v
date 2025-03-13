`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

module uart #(
  parameter FIFO_TX_DEPTH = 16,
  parameter FIFO_RX_DEPTH = 16
) (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output reg         uart_tx,
  input  wire        uart_rx
);

  localparam BAUD_DIV_115200 = `BAUD_DIV(115200);
  localparam BAUD_DIV_57600  = `BAUD_DIV(57600);
  localparam BAUD_DIV_38400  = `BAUD_DIV(38400);
  localparam BAUD_DIV_28800  = `BAUD_DIV(28800);
  localparam BAUD_DIV_23040  = `BAUD_DIV(23040);
  localparam BAUD_DIV_19200  = `BAUD_DIV(19200);
  localparam BAUD_DIV_14400  = `BAUD_DIV(14400);
  localparam BAUD_DIV_9600   = `BAUD_DIV(9600);
  localparam BAUD_DIV_4800   = `BAUD_DIV(4800);
  localparam BAUD_DIV_2400   = `BAUD_DIV(2400);
  localparam BAUD_DIV_1200   = `BAUD_DIV(1200);
  localparam BAUD_DIV_300    = `BAUD_DIV(300);

  localparam DIV_WIDTH       = $clog2(BAUD_DIV_300 + 1);

  localparam CTRL_OFFSET     = 8'h00;
  localparam BAUD_OFFSET     = 8'h04;
  localparam STATUS_OFFSET   = 8'h08;
  localparam TX_OFFSET       = 8'h0C;
  localparam RX_OFFSET       = 8'h10;

  localparam RX_IDLE         = 2'd0;
  localparam RX_START        = 2'd1;
  localparam RX_DATA         = 2'd2;
  localparam RX_STOP         = 2'd3;

  localparam TX_IDLE         = 2'd0;
  localparam TX_START        = 2'd1;
  localparam TX_DATA         = 2'd2;
  localparam TX_STOP         = 2'd3;

  reg [DIV_WIDTH - 1:0] tx_bd_cntr;
  reg [DIV_WIDTH - 1:0] rx_bd_cntr;
  reg [DIV_WIDTH - 1:0] bd_div_cnt;

  reg [ 7:0] tx_shift;
  reg [ 7:0] rx_shift;
  reg [ 3:0] baud_sel;
  reg [ 3:0] new_baud_sel;
  reg [ 2:0] tx_bit_id;
  reg [ 2:0] rx_bit_id;
  reg [ 1:0] tx_state;
  reg [ 1:0] rx_state;

  reg rx_fifo_we;
  reg tx_fifo_rd;
  reg rx_sync_1;
  reg rx_sync_2;
  reg rx_last;
  reg new_active;
  reg active;

  wire [7:0] tx_fifo_dout;
  wire [7:0] rx_fifo_dout;
  wire [7:0] tx_data;
  wire [7:0] rx_data;
  wire [5:0] status_bits;

  wire tx_fifo_we;
  wire rx_fifo_re;
  wire tx_fifo_empty;
  wire tx_fifo_full;
  wire rx_fifo_empty;
  wire rx_fifo_full;
  wire rx_fall_edge;
  wire uart_busy;
  wire uart_ready;

  always @( * )
  begin
    case (baud_sel)
      4'd0    : bd_div_cnt = BAUD_DIV_115200;
      4'd1    : bd_div_cnt = BAUD_DIV_57600;
      4'd2    : bd_div_cnt = BAUD_DIV_38400;
      4'd3    : bd_div_cnt = BAUD_DIV_28800;
      4'd4    : bd_div_cnt = BAUD_DIV_23040;
      4'd5    : bd_div_cnt = BAUD_DIV_19200;
      4'd6    : bd_div_cnt = BAUD_DIV_14400;
      4'd7    : bd_div_cnt = BAUD_DIV_9600;
      4'd8    : bd_div_cnt = BAUD_DIV_4800;
      4'd9    : bd_div_cnt = BAUD_DIV_2400;
      4'd10   : bd_div_cnt = BAUD_DIV_1200;
      4'd11   : bd_div_cnt = BAUD_DIV_300;
      default : bd_div_cnt = BAUD_DIV_115200;
    endcase
  end

  assign tx_data[7:0] =   write_data[7:0];
  assign rx_data[7:0] = rx_fifo_dout[7:0];

  assign tx_fifo_we   = we && (address[7:0] == TX_OFFSET);
  assign rx_fifo_re   = re && (address[7:0] == RX_OFFSET);

  assign uart_busy    = ((tx_state != TX_IDLE) | (rx_state != RX_IDLE));
  assign uart_ready   = !uart_busy & tx_fifo_empty & rx_fifo_empty;

  assign status_bits  = {uart_ready, uart_busy, rx_fifo_full, rx_fifo_empty, tx_fifo_full, tx_fifo_empty};
  
  assign rx_fall_edge = (rx_last == 1'b1) && (rx_sync_2 == 1'b0);

  assign read_data    = (address[7:0] == CTRL_OFFSET)   ? {31'd0, active} :
                        (address[7:0] == BAUD_OFFSET)   ? {28'd0, baud_sel} :
                        (address[7:0] == STATUS_OFFSET) ? {26'd0, status_bits} :
                        (address[7:0] == RX_OFFSET)     ? {23'd0, !rx_fifo_empty, rx_data} :
                        32'd0;

  fifo #(
    .DATA_WIDTH (8),
    .DEPTH      (FIFO_TX_DEPTH)
  ) tx_fifo_inst (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (tx_fifo_we),
    .din   (tx_data),
    .rd_en (tx_fifo_rd),
    .dout  (tx_fifo_dout),
    .empty (tx_fifo_empty),
    .full  (tx_fifo_full)
  );

  fifo #(
    .DATA_WIDTH (8),
    .DEPTH      (FIFO_RX_DEPTH)
  ) rx_fifo_inst (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (rx_fifo_we),
    .din   (rx_shift),
    .rd_en (rx_fifo_re),
    .dout  (rx_fifo_dout),
    .empty (rx_fifo_empty),
    .full  (rx_fifo_full)
  );

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      tx_state   <= TX_IDLE;
      tx_bd_cntr <= {DIV_WIDTH{1'b0}};
      tx_fifo_rd <= 1'b0;
      uart_tx    <= 1'b1;
      tx_shift   <= 8'd0;
      tx_bit_id  <= 3'b0;
    end
    else
    begin

      case (tx_state)

        TX_IDLE:
        begin
          tx_bd_cntr <= {DIV_WIDTH{1'b0}};

          if (!tx_fifo_empty && active)
          begin
            tx_shift   <= tx_fifo_dout;
            tx_state   <= TX_START;
            tx_fifo_rd <= 1'b1;
          end
        end

        TX_START:
        begin
          tx_fifo_rd <= 1'b0;
          if (tx_bd_cntr == bd_div_cnt)
          begin
            tx_bd_cntr <= {DIV_WIDTH{1'b0}};
            tx_bit_id  <= 3'b0;
            uart_tx    <= tx_shift[0];
            tx_shift   <= {1'b0, tx_shift[7:1]};
            tx_state   <= TX_DATA;
          end
          else
          begin
            tx_bd_cntr <= tx_bd_cntr + {{(DIV_WIDTH - 1) {1'b0}}, 1'b1};
            uart_tx    <= 1'b0;
          end        
        end

        TX_DATA:
        begin
          if (tx_bd_cntr == bd_div_cnt)
          begin
            tx_bd_cntr <= {DIV_WIDTH{1'b0}};
            uart_tx    <= tx_shift[0];
            tx_shift   <= {1'b0, tx_shift[7:1]};

            if (tx_bit_id < 7)
            begin
              tx_bit_id <= tx_bit_id + 3'b1;
              tx_state  <= TX_DATA;
            end
            else
              tx_state <= TX_STOP;
          end
          else
          begin
            tx_bd_cntr <= tx_bd_cntr + {{(DIV_WIDTH - 1) {1'b0}}, 1'b1};
            tx_state   <= TX_DATA;
          end
        end

        TX_STOP:
        begin
          if (tx_bd_cntr == bd_div_cnt)
          begin
            tx_bd_cntr <= {DIV_WIDTH{1'b0}};
            tx_state   <= TX_IDLE;
          end
          else
          begin
            tx_bd_cntr <= tx_bd_cntr + {{(DIV_WIDTH - 1) {1'b0}}, 1'b1};
            uart_tx    <= 1'b1;
          end
        end

        default : tx_state <= TX_IDLE;

      endcase
    end
  end
  
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      rx_sync_1 <= 1'b1;
      rx_sync_2 <= 1'b1;
      rx_last   <= 1'b1;
    end
    else
    begin
      rx_sync_1 <= uart_rx;
      rx_sync_2 <= rx_sync_1;
      rx_last   <= rx_sync_2;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      rx_state   <= RX_IDLE;
      rx_bd_cntr <= {DIV_WIDTH{1'b0}};
      rx_bit_id  <= 3'b0;
      rx_fifo_we <= 1'b0;
    end
    else
    begin
      rx_fifo_we <= 1'b0;

      case (rx_state)

          RX_IDLE:
          begin
            rx_bd_cntr <= {DIV_WIDTH{1'b0}};

            if (rx_fall_edge)
                rx_state <= RX_START;
          end

          RX_START:
          begin
            if (rx_bd_cntr == (bd_div_cnt >> 1))
            begin
              rx_bd_cntr <= {DIV_WIDTH{1'b0}};
              rx_bit_id  <= 3'b0;
              rx_state   <= RX_DATA;
            end
            else
              rx_bd_cntr <= rx_bd_cntr + 1;
          end

          RX_DATA:
          begin
            if (rx_bd_cntr == bd_div_cnt)
            begin
              rx_bd_cntr          <= {DIV_WIDTH{1'b0}};
              rx_shift[rx_bit_id] <= uart_rx;

              if (rx_bit_id == 7)
                rx_state <= RX_STOP;
              else
                rx_bit_id <= rx_bit_id + 1;

            end
            else
              rx_bd_cntr <= rx_bd_cntr + 1;
          end

          RX_STOP:
          begin
            if (rx_bd_cntr == bd_div_cnt)
            begin
              rx_bd_cntr <= {DIV_WIDTH{1'b0}};

              if (!rx_fifo_full)
                  rx_fifo_we <= 1'b1;

              rx_state <= RX_IDLE;
            end
            else
              rx_bd_cntr <= rx_bd_cntr + 1;
          end

          default:
            rx_state <= RX_IDLE;

      endcase
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      active       <= 1'b1;
      new_active   <= 1'b1;
      baud_sel     <= 4'd0;
      new_baud_sel <= 4'd0;
    end
    else if (we)
    begin

      case (address[7:0])

        CTRL_OFFSET:
        begin
          new_active   <= write_data[0];
        end

        BAUD_OFFSET:
          new_baud_sel <= write_data[3:0];

        default: ;

      endcase
    end
    else
    if (uart_ready)
    begin
      baud_sel <= new_baud_sel;
      active   <= new_active;
    end
  end

endmodule
