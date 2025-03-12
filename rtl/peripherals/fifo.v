`default_nettype none
`timescale 1ns / 1ns

module fifo #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH      = 16
  ) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire                  rd_en,
    output wire                  empty,
    output wire                  full,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
  );

  localparam ADDR_WIDTH = $clog2(DEPTH);

  reg [ADDR_WIDTH  :0]    rd_ptr;
  reg [ADDR_WIDTH  :0]    wr_ptr;
  reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];

  reg wr_en_prev;
  reg rd_en_prev;

  wire [ADDR_WIDTH: 0] next_wr;

  assign empty   = (rd_ptr  == wr_ptr);
  
  assign full    = (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]) &&
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
                   
  assign next_wr = (wr_ptr   + 1);

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      wr_en_prev <= 0;
      rd_en_prev <= 0;
    end
    else
    begin
      wr_en_prev <= wr_en;
      rd_en_prev <= rd_en;

      if (wr_en && !wr_en_prev && !full)
      begin
        mem[wr_ptr[ADDR_WIDTH - 1: 0]] <= din;
        wr_ptr <= next_wr;
      end

      if (rd_en && !rd_en_prev && !empty)
      begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  assign dout = empty ? {DATA_WIDTH{1'b0}} : mem[rd_ptr[ADDR_WIDTH - 1 : 0]];

endmodule
