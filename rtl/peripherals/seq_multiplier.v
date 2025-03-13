`default_nettype none
`timescale 1ns / 1ns

module seq_multiplier (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re
);

  localparam INFO_OFFSET = 8'h00;
  localparam MUL1_OFFSET = 8'h04;
  localparam MUL2_OFFSET = 8'h08;
  localparam RESH_OFFSET = 8'h0C;
  localparam RESL_OFFSET = 8'h10;

  reg [31:0] multiplicand;
  reg [31:0] multiplier;
  reg [63:0] product;
  reg [ 5:0] bit_index;
  reg        busy;

  assign read_data = (address == INFO_OFFSET) ? {31'd0, busy} :
                     (address == MUL1_OFFSET) ? multiplicand  :
                     (address == MUL2_OFFSET) ? multiplier    :
                     (address == RESH_OFFSET) ? product[63:32]:
                     (address == RESL_OFFSET) ? product[31: 0]:
                     32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) begin
      multiplicand <= 32'd0;
      multiplier   <= 32'd0;
      product      <= 64'd0;
      bit_index    <= 6'd0;
      busy         <= 1'b0;
    end
    else
    begin
      if (we)
      begin
        case (address)
          MUL1_OFFSET: begin
            multiplicand <= write_data;
          end
          MUL2_OFFSET: begin
            multiplier <= write_data;
            product    <= 64'd0;
            bit_index  <= 6'd31;
            busy       <= 1'b1;
          end
        endcase
      end

      if (busy)
      begin
        if (multiplier[bit_index])
        begin
          product <= product + ((64'd1 << bit_index) * multiplicand);
        end

        if (bit_index == 0)
        begin
          busy <= 1'b0;
        end
        else
        begin
          bit_index <= bit_index - 1;
        end
      end
    end
  end

endmodule
