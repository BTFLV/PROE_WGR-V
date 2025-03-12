`default_nettype none
`timescale 1ns / 1ns

module debug_module (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [ 7:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data,
    input  wire        we,
    input  wire        re,
    output wire        debug_re,
    output wire [31:0] debug_out
  );

  localparam DEBUG_ADDR = 32'h00000000;

  reg [31:0] debug_reg;

  assign read_data = debug_reg;
  assign debug_out = debug_reg;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      debug_reg <= 32'h00000000;
    end
    else
    if (we)
    begin
      debug_reg <= write_data;
      $display("DEBUG_REG UPDATED: 0x%08X at time %0t", write_data, $time);
    end
  end

endmodule
