`include "../defines.v"
`default_nettype none
`timescale 1ns / 1ns

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

  reg [MSW-1:0] ms_counter;
  reg [MKW-1:0] mik_counter;
  reg [ 63  :0] sys_tim_ms;
  reg [ 63  :0] sys_tim_mik;
  
  wire [31:0] sys_clk;

  assign sys_clk = `CLK_FREQ;

  assign read_data = (address == MS_L_OFFSET)  ? sys_tim_ms [31: 0] : 
                     (address == MS_H_OFFSET)  ? sys_tim_ms [63:32] : 
                     (address == MIK_L_OFFSET) ? sys_tim_mik[31: 0] : 
                     (address == MIK_H_OFFSET) ? sys_tim_mik[63:32] : 
                     (address == SYS_CLOCK)    ? sys_clk    [31: 0]  : 
                     32'd0;

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
