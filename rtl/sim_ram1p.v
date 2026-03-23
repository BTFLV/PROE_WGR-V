`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Portable Single-Port RAM for Simulation.
 *
 * This module provides a simulation-compatible replacement for the
 * Altera altsyncram-based ram1p module. It uses a standard Verilog
 * register array and supports optional hex file initialization via
 * the MEM_INIT_FILE parameter.
 *
 * Interface is identical to the Quartus-generated ram1p module.
 *
 * @parameter ADDR_WIDTH Width of address bus (default 13 for 8192 words)
 * @parameter DATA_WIDTH Width of data bus (default 32)
 * @parameter DEPTH      Number of words (default 8192)
 * @parameter MEM_INIT_FILE Optional hex initialization file path
 *
 * @input  [ADDR_WIDTH-1:0] address  Read/Write address
 * @input  clock                     System clock
 * @input  [DATA_WIDTH-1:0] data     Write data
 * @input  wren                      Write enable
 * @output [DATA_WIDTH-1:0] q        Read data (1-cycle latency)
 */

module ram1p #(
  parameter ADDR_WIDTH    = 13,
  parameter DATA_WIDTH    = 32,
  parameter DEPTH         = 8192,
  parameter MEM_INIT_FILE = ""
) (
  input  wire [ADDR_WIDTH-1:0] address,
  input  wire                  clock,
  input  wire [DATA_WIDTH-1:0] data,
  input  wire                  wren,
  output reg  [DATA_WIDTH-1:0] q
);

  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // Optional memory initialization from hex file
  initial begin
    if (MEM_INIT_FILE != "") begin
      $readmemh(MEM_INIT_FILE, mem);
    end
  end

  always @(posedge clock) begin
    if (wren) begin
      mem[address] <= data;
    end
    q <= mem[address];
  end

endmodule
