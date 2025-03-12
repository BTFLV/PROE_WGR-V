`default_nettype none
`timescale 1ns / 1ns

module seq_divider ( 
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re
);

  localparam INFO_OFFSET = 8'h00; 
  localparam END_OFFSET  = 8'h04; 
  localparam SOR_OFFSET  = 8'h08; 
  localparam QUO_OFFSET  = 8'h0C; 
  localparam REM_OFFSET  = 8'h10;

  reg [31:0] dividend;
  reg [31:0] divisor;
  reg [31:0] dvdend_tmp;
  reg [31:0] dvsor_tmp;
  reg [31:0] quotient;
  reg [31:0] remainder;
  reg [ 5:0] bit_index;
  reg        busy;
  
  assign read_data = (address == INFO_OFFSET) ? {31'd0, ~busy} : 
                     (address == END_OFFSET)  ?  divisor       : 
                     (address == SOR_OFFSET)  ?  dividend      : 
                     (address == QUO_OFFSET)  ?  quotient      : 
                     (address == REM_OFFSET)  ?  remainder     : 
                     32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n) 
    begin
      dividend     <= 32'd0;
      divisor      <= 32'd0;
      quotient     <= 32'd0;
      remainder    <= 32'd0;
      dvdend_tmp   <= 32'd0;
      dvsor_tmp    <= 32'd0;
      bit_index    <= 6'd0;
      busy         <= 1'b0;
    end
    else
    begin
      if (we)
      begin
        case (address)

          SOR_OFFSET:
          begin
            dividend     <= write_data;
            dvdend_tmp   <= write_data;
            bit_index    <= 6'd32;
            busy         <= 1'b1;
          end

          END_OFFSET:
            divisor <= write_data;

        endcase
      end

      if (busy)
      begin
        if (dvdend_tmp >= divisor)
        begin
          dvdend_tmp  <= dvdend_tmp - divisor;
          quotient    <= (quotient << 1) | 1;
        end
        else
        begin
          quotient <= quotient << 1;
        end

        dvdend_tmp <= dvdend_tmp << 1;

        if (bit_index == 0)
        begin
          remainder <= dvdend_tmp;
          busy      <= 1'b0;
        end
        else
        begin
          bit_index <= bit_index - 1;
        end
      end
    end
  end

endmodule
