`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief PWM-Timer zur Erzeugung eines Pulsweitenmodulationssignals
 *
 * Dieses Modul generiert ein PWM-Signal (Pulsweitenmodulation) mit
 * konfigurierbarer Periode und Pulsbreite. Es wird typischerweise
 * zur Ansteuerung von Motoren, LEDs oder anderen zeitgesteuerten
 * Peripherien eingesetzt. Der Zähler läuft periodisch hoch und vergleicht
 * seinen Wert mit einem Pulsbreitenwert, um das Ausgangssignal zu setzen.
 * 
 * @input clk Systemtakt
 * @input rst Reset-Signal
 * @input enable Aktivierung des Timers
 * @input [31:0] period Maximale Zählerperiode (PWM-Zykluslänge)
 * @input [31:0] duty_cycle Vergleichswert für Pulsbreite (PWM-Anteil)
 * 
 * @output pwm_out PWM-Ausgangssignal
 */

module pwm_timer (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [7:0]  address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output reg         pwm_out
);

  localparam PERIOD_ADDR  = 8'h00;
  localparam DUTY_ADDR    = 8'h04;
  localparam COUNTER_ADDR = 8'h08;
  localparam CTRL_ADDR    = 8'h0C;

  reg [31:0] period;
  reg [31:0] duty;
  reg [31:0] counter;
  reg [31:0] ctrl;
  reg [15:0] pre_count;

  assign read_data = (address == PERIOD_ADDR)  ? period  :
                     (address == DUTY_ADDR)    ? duty    :
                     (address == COUNTER_ADDR) ? counter :
                     (address == CTRL_ADDR)    ? ctrl    :
                     32'h0;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      period    <= 32'd1000;
      duty      <= 32'd500;
      counter   <= 32'd0;
      ctrl      <= 32'h00010000;
      pre_count <= 16'd0;
    end else begin
      if (we) begin
        case (address)
          PERIOD_ADDR:
            period    <= write_data;
          DUTY_ADDR:
            duty      <= write_data;
          COUNTER_ADDR:
            counter   <= 32'd0;
          CTRL_ADDR:
          begin
            ctrl      <= write_data;
            pre_count <= write_data[31:16];
          end
          default: ;
        endcase
      end else
      if (pre_count > 0) begin
        pre_count <= pre_count - 1;
      end else begin
        pre_count <= ctrl[31:16];

        if (counter >= period - 1) begin
          counter <= 32'd0;
        end else begin
          counter <= counter + 1;
        end
      end
    end
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      pwm_out <= 1'b0;
    else begin
      if (ctrl[0]) begin
        if (ctrl[1])
          pwm_out <= (counter < (period >> 1)) ? 1'b1 : 1'b0;
        else
          pwm_out <= (counter < duty) ? 1'b1 : 1'b0;
      end else
        pwm_out <= 1'b0;
    end
  end

endmodule
