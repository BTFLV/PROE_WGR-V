`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief System Timer
 *
 * Dieses Modul stellt einen System-Timer bereit, der sowohl Millisekunden-
 * als auch Mikrosekunden-Zähler verwaltet. Zwei Zähler (ms_counter, mik_counter)
 * laufen in Abhängigkeit von `CLK_FREQ`, wodurch sich systemweite Zeitstempel
 * erzeugen lassen. Über Register kann der Zählerinhalt ausgelesen oder
 * zurückgesetzt werden.
 *
 * Register-Offsets:
 * - `MS_L_OFFSET`  : Niedrigere 32 Bit des Millisekunden-Zählers
 * - `MS_H_OFFSET`  : Höhere 32 Bit des Millisekunden-Zählers
 * - `MIK_L_OFFSET` : Niedrigere 32 Bit des Mikrosekunden-Zählers
 * - `MIK_H_OFFSET` : Höhere 32 Bit des Mikrosekunden-Zählers
 * - `SYS_CLOCK`    : Liefert die aktuelle Taktrate in Hz (niedrigere 32 Bit)
 *
 * @localparam MS_COUNT_LIMIT    Obergrenze für 1 ms (basierend auf `CLK_FREQ`)
 * @localparam MIK_COUNT_LIMIT   Obergrenze für 1 µs (basierend auf `CLK_FREQ`)
 * @localparam MS_COUNTER_WIDTH  Breite des Zählers für ms_counter
 * @localparam MIK_COUNTER_WIDTH Breite des Zählers für mik_counter
 * 
 * @localparam MS_L_OFFSET   Registeroffset für Millisekunden (Low)
 * @localparam MS_H_OFFSET   Registeroffset für Millisekunden (High)
 * @localparam MIK_L_OFFSET  Registeroffset für Mikrosekunden (Low)
 * @localparam MIK_H_OFFSET  Registeroffset für Mikrosekunden (High)
 * @localparam SYS_CLOCK     Registeroffset für das Auslesen der Taktfrequenz
 *
 * @input  clk               Systemtakt.
 * @input  rst_n             Asynchroner, aktiver-LOW Reset.
 * @input  [7:0] address     Busadresse für das Lesen/Schreiben der Timerregister.
 * @input  [31:0] write_data Zu schreibende Daten (z. B. zum Zurücksetzen).
 * @output [31:0] read_data  Enthält gelesene Daten abhängig von `address`.
 * @input  we                Write-Enable.
 * @input  re                Read-Enable.
 */

module system_timer (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re
);

	localparam MS_COUNT_LIMIT    = (`CLK_FREQ / 1000)    - 1;
  localparam MIK_COUNT_LIMIT   = (`CLK_FREQ / 1000000) - 1;
	localparam MS_COUNTER_WIDTH  = $clog2(MS_COUNT_LIMIT + 1);
  localparam MIK_COUNTER_WIDTH = $clog2(MIK_COUNT_LIMIT + 1);

  localparam MSW = MS_COUNTER_WIDTH;
  localparam MKW = MIK_COUNTER_WIDTH;

  localparam MS_L_OFFSET   = 8'h00;
  localparam MS_H_OFFSET   = 8'h04;
  localparam MIK_L_OFFSET  = 8'h08;
  localparam MIK_H_OFFSET  = 8'h0C;
  localparam SYS_CLOCK     = 8'h10;

  // ---------------------------------------------------------
  // Timer-Register:
  // - ms_counter  + sys_tim_ms: für Millisekunden
  // - mik_counter + sys_tim_mik: für Mikrosekunden
  // ---------------------------------------------------------
  reg [MSW-1:0] ms_counter;
  reg [MKW-1:0] mik_counter;
  reg [ 63  :0] sys_tim_ms;
  reg [ 63  :0] sys_tim_mik;
  
  wire [31:0] sys_clk;

  assign sys_clk = `CLK_FREQ;

  // ---------------------------------------------------------
  // Leseauswahl je nach address:
  // ---------------------------------------------------------
  assign read_data = (address == MS_L_OFFSET)  ? sys_tim_ms [31: 0] : 
                     (address == MS_H_OFFSET)  ? sys_tim_ms [63:32] : 
                     (address == MIK_L_OFFSET) ? sys_tim_mik[31: 0] : 
                     (address == MIK_H_OFFSET) ? sys_tim_mik[63:32] : 
                     (address == SYS_CLOCK)    ? sys_clk    [31: 0] : 
                     32'd0;

  // ---------------------------------------------------------
  // Millisekunden-Zähler
  // - ms_counter zählt bis MS_COUNT_LIMIT
  // - Wird der Wert erreicht, dann sys_tim_ms++
  // - Auf Write an MS_L_OFFSET wird Timer zurückgesetzt
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      sys_tim_ms <= 64'd0;
      ms_counter <= {MSW{1'b0}};
    end
    else
    begin
      if(we && (address == MS_L_OFFSET))
      begin
        sys_tim_ms   <= 64'd0;
        ms_counter   <= {MSW{1'b0}};
      end
      else if (ms_counter == MS_COUNT_LIMIT)
      begin
        sys_tim_ms <= sys_tim_ms + 1;
        ms_counter <= {MSW{1'b0}};
      end
      else
      begin
        ms_counter <= ms_counter + 1;
      end
    end
  end

  // ---------------------------------------------------------
  // Mikrosekunden-Zähler
  // - mik_counter zählt bis MIK_COUNT_LIMIT
  // - Wird der Wert erreicht, dann sys_tim_mik++
  // - Auf Write an MIK_L_OFFSET wird Timer zurückgesetzt
  // ---------------------------------------------------------
  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      sys_tim_mik   <= 64'd0;
      mik_counter   <= {MKW{1'b0}};
    end
    else
    begin
      if(we && (address == MIK_L_OFFSET))
      begin
        sys_tim_mik   <= 64'd0;
        mik_counter   <= {MKW{1'b0}};
      end
      else if (mik_counter == MIK_COUNT_LIMIT)
      begin
        sys_tim_mik <= sys_tim_mik + 1;
        mik_counter <= {MKW{1'b0}};
      end
      else
      begin
        mik_counter <= mik_counter + 1;
      end
    end
  end

endmodule
