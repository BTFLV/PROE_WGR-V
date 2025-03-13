`default_nettype none
`timescale 1ns / 1ns

module fram_ram (
    input  wire        clk,
    input  wire        rst_n,
    output reg         req_ready,
    input  wire [15:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data,
    input  wire        we,
    input  wire        re,
    output wire        spi_mosi,
    input  wire        spi_miso,
    output wire        spi_clk,
    output wire        spi_cs,
);

  localparam [2:0] ST_IDLE  = 3'd0;
  localparam [2:0] ST_START = 3'd1;
  localparam [2:0] ST_WAIT  = 3'd2;
  localparam [2:0] ST_DONE  = 3'd3;
  
  reg  [31:0] spi_write_data;
  reg  [31:0] lat_write_data;
  reg  [15:0] spi_address;
  reg  [15:0] lat_address;
  reg  [ 2:0] state;
  reg         spi_we;
  reg         latched_we;
  reg         spi_re;

  wire [31:0] spi_read_data;
  wire        spi_done;

  fram_spi fram_spi_inst (
    .clk         (clk),
    .rst_n       (rst_n),
    .address     (spi_address),
    .write_data  (spi_write_data),
    .read_data   (spi_read_data),
    .we          (spi_we),
    .re          (spi_re),
    .done        (spi_done),
    .spi_mosi    (spi_mosi),
    .spi_miso    (spi_miso),
    .spi_clk     (spi_clk),
    .spi_cs      (spi_cs)
  );

  always @(posedge clk or negedge rst_n) 
  begin
    if (!rst_n) 
    begin
      state          <= ST_IDLE;
      req_ready      <= 1'b1;
      latched_we     <= 1'b0;
      lat_address    <= 16'd0;
      lat_write_data <= 32'd0;
      read_data      <= 32'd0;
      spi_re         <= 1'b0;
      spi_we         <= 1'b0;
      spi_address    <= 16'd0;
      spi_write_data <= 32'd0;
    end
    else
    begin
      spi_we <= 1'b0;
      spi_re <= 1'b0;

      case (state)
        
        ST_IDLE: begin
          if (we || re)
          begin
            lat_address    <= address;
            lat_write_data <= write_data;
            latched_we     <= we;
            req_ready      <= 1'b0;
            state          <= ST_START;
          end
          else
            req_ready <= 1'b1;
        end

        ST_START:
        begin
          spi_address    <= lat_address;
          spi_write_data <= lat_write_data;

          if (latched_we) 
            spi_we <= 1'b1;
          else 
            spi_re  <= 1'b1;

          state <= ST_WAIT;
        end

        ST_WAIT:
        begin
          if (spi_done) 
          begin
            if (!latched_we) 
              read_data <= spi_read_data;

            state <= ST_DONE;
          end
        end

        ST_DONE:
        begin
          req_ready <= 1'b1;
          state     <= ST_IDLE;
        end

        default:
          state <= ST_IDLE;

      endcase
    end
  end

endmodule
