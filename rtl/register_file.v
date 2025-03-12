`default_nettype none
`timescale 1ns / 1ns

module register_file (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        we,
  input  wire [ 4:0] rd,
  input  wire [ 4:0] rs1,
  input  wire [ 4:0] rs2,
  input  wire [31:0] rd_data,
  output wire [31:0] rs1_data,
  output wire [31:0] rs2_data
);

  reg [31:0] registers[31:1];

  assign rs1_data  = (rs1 != 5'd0) ? registers[rs1] : 32'd0;
  assign rs2_data  = (rs2 != 5'd0) ? registers[rs2] : 32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      registers[ 1] <= 32'd0;
      registers[ 2] <= 32'd0;
      registers[ 3] <= 32'd0;
      registers[ 4] <= 32'd0;
      registers[ 5] <= 32'd0;
      registers[ 6] <= 32'd0;
      registers[ 7] <= 32'd0;
      registers[ 8] <= 32'd0;
      registers[ 9] <= 32'd0;
      registers[10] <= 32'd0;
      registers[11] <= 32'd0;
      registers[12] <= 32'd0;
      registers[13] <= 32'd0;
      registers[14] <= 32'd0;
      registers[15] <= 32'd0;
      registers[16] <= 32'd0;
      registers[17] <= 32'd0;
      registers[18] <= 32'd0;
      registers[19] <= 32'd0;
      registers[20] <= 32'd0;
      registers[21] <= 32'd0;
      registers[22] <= 32'd0;
      registers[23] <= 32'd0;
      registers[24] <= 32'd0;
      registers[25] <= 32'd0;
      registers[26] <= 32'd0;
      registers[27] <= 32'd0;
      registers[28] <= 32'd0;
      registers[29] <= 32'd0;
      registers[30] <= 32'd0;
      registers[31] <= 32'd0;
    end
    else
      if (we && (rd != 5'd0))
        registers[rd] <= rd_data;
  end

endmodule
