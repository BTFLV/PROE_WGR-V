`default_nettype none
`timescale 1ns / 1ns

module gpio (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [ 7:0] address,
  input  wire [31:0] write_data,
  output wire [31:0] read_data,
  input  wire        we,
  input  wire        re,
  output  reg [ 7:0] gpio_out,
  output  reg [ 7:0] gpio_dir,
  input  wire [ 7:0] gpio_in
);

  localparam GPIO_DIR_OFFSET = 8'h0;
  localparam GPIO_OUT_OFFSET = 8'h4;
  localparam GPIO_IN_OFFSET  = 8'h8;

  assign read_data = (address == GPIO_DIR_OFFSET) ? gpio_dir :
                     (address == GPIO_OUT_OFFSET) ? gpio_out :
                     (address == GPIO_IN_OFFSET)  ? gpio_in  :
                     32'd0;

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      gpio_dir <= 8'd0;
      gpio_out <= 8'd0;
    end
    else if (we)
    begin

      case (address)

        GPIO_DIR_OFFSET:
          gpio_dir <= write_data[7:0];

        GPIO_OUT_OFFSET:
          gpio_out <= write_data[7:0];

        default: ;

      endcase
    end
  end

endmodule
