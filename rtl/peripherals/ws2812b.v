`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

module ws2812b (
  input  wire         clk,
  input  wire         rst_n,
  input  wire  [ 7:0] address,
  input  wire  [31:0] write_data,
  output wire  [31:0] read_data,
  input  wire         we,
  input  wire         re,
  output reg          ws_out
);

  localparam CLK_PERIOD_NS = 1_000_000_000 / `CLK_FREQ;
  localparam T0H     = (400 + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;
  localparam T0L     = (850 + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;
  localparam T1H     = (800 + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;
  localparam T1L     = (450 + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;
  localparam T_RESET = (50_000 + CLK_PERIOD_NS - 1) / CLK_PERIOD_NS;

  localparam STATE_LOAD_LED   = 2'd0;
  localparam STATE_SEND_HIGH  = 2'd1;
  localparam STATE_SEND_LOW   = 2'd2;
  localparam STATE_RESET      = 2'd3;

  reg [23:0] led_rgb [0:7];
  reg [23:0] shift_reg;
  reg [15:0] timer;
  reg [ 4:0] bit_index;
  reg [ 2:0] led_index;
  reg [ 1:0] state;

  assign read_data = (address[7:0] == 8'h00) ? {8'b0, led_rgb[0]} :
                     (address[7:0] == 8'h04) ? {8'b0, led_rgb[1]} :
                     (address[7:0] == 8'h08) ? {8'b0, led_rgb[2]} :
                     (address[7:0] == 8'h0C) ? {8'b0, led_rgb[3]} :
                     (address[7:0] == 8'h10) ? {8'b0, led_rgb[4]} :
                     (address[7:0] == 8'h14) ? {8'b0, led_rgb[5]} :
                     (address[7:0] == 8'h18) ? {8'b0, led_rgb[6]} :
                     (address[7:0] == 8'h1C) ? {8'b0, led_rgb[7]} :
                     32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) 
    begin
      led_rgb[0] <= 24'h0;
      led_rgb[1] <= 24'h0;
      led_rgb[2] <= 24'h0;
      led_rgb[3] <= 24'h0;
      led_rgb[4] <= 24'h0;
      led_rgb[5] <= 24'h0;
      led_rgb[6] <= 24'h0;
      led_rgb[7] <= 24'h0;
    end 
    else if (we) 
    begin
      case(address)
        8'h00: led_rgb[0] <= write_data[23:0];
        8'h04: led_rgb[1] <= write_data[23:0];
        8'h08: led_rgb[2] <= write_data[23:0];
        8'h0C: led_rgb[3] <= write_data[23:0];
        8'h10: led_rgb[4] <= write_data[23:0];
        8'h14: led_rgb[5] <= write_data[23:0];
        8'h18: led_rgb[6] <= write_data[23:0];
        8'h1C: led_rgb[7] <= write_data[23:0];
        default: ;
      endcase
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state     <= STATE_LOAD_LED;
      led_index <= 3'd0;
      bit_index <= 5'd23;
      timer     <= 0;
      ws_out    <= 0;
      shift_reg <= 0;
    end
    else
    begin
      case (state)

        STATE_LOAD_LED:
        begin
          shift_reg <= {led_rgb[led_index][23:16], led_rgb[led_index][15:8], led_rgb[led_index][7:0]};
          bit_index <= 23;

          if (shift_reg[23]) begin
            timer <= T1H - 1;
          end else begin
            timer <= T0H - 1;
          end

          ws_out <= 1;
          state  <= STATE_SEND_HIGH;
        end

        STATE_SEND_HIGH:
        begin
          if (timer == 0) begin
            timer <= shift_reg[bit_index] ? (T1L - 1) : (T0L - 1);
            ws_out <= 0;
            state <= STATE_SEND_LOW;
          end else begin
            timer <= timer - 1;
          end
        end

        STATE_SEND_LOW:
        begin
          if (timer == 0) begin
            if (bit_index == 0) begin
              if (led_index == 7) begin
                timer <= T_RESET - 1;
                state <= STATE_RESET;
              end else begin
                led_index <= led_index + 1;
                state <= STATE_LOAD_LED;
              end
            end else begin
              bit_index <= bit_index - 1;
              timer <= shift_reg[bit_index - 1] ? (T1H - 1) : (T0H - 1);
              ws_out <= 1;
              state <= STATE_SEND_HIGH;
            end
          end else begin
            timer <= timer - 1;
          end
        end

        STATE_RESET:
        begin
          if (timer == 0) begin
            led_index <= 0;
            state <= STATE_LOAD_LED;
          end else begin
            timer <= timer - 1;
          end
        end

        default: state <= STATE_LOAD_LED;

      endcase
    end
  end

endmodule
