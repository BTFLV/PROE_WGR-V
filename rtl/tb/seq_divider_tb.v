`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Self-checking sequential divider unit test.
 *
 * Validates the restoring division algorithm with various test cases.
 */
module seq_divider_tb;

  reg         clk;
  reg         rst_n;
  reg  [ 7:0] address;
  reg  [31:0] write_data;
  wire [31:0] read_data;
  reg         we;
  reg         re;

  integer pass_count;
  integer fail_count;

  localparam INFO_OFFSET = 8'h00;
  localparam END_OFFSET  = 8'h04;
  localparam SOR_OFFSET  = 8'h08;
  localparam QUO_OFFSET  = 8'h0C;
  localparam REM_OFFSET  = 8'h10;

  seq_divider uut (
    .clk        (clk),
    .rst_n      (rst_n),
    .address    (address),
    .write_data (write_data),
    .read_data  (read_data),
    .we         (we),
    .re         (re)
  );

  // Clock generation: 10 MHz
  initial clk = 0;
  always #50 clk = ~clk;

  task write_reg;
    input [7:0] addr;
    input [31:0] data;
    begin
      @(posedge clk);
      address    <= addr;
      write_data <= data;
      we         <= 1'b1;
      @(posedge clk);
      we         <= 1'b0;
    end
  endtask

  task read_reg;
    input  [7:0]  addr;
    output [31:0] data;
    begin
      @(posedge clk);
      address <= addr;
      re      <= 1'b1;
      @(posedge clk);
      re      <= 1'b0;
      data    = read_data;
    end
  endtask

  task wait_not_busy;
    reg [31:0] status;
    begin
      status = 32'd1;
      while (status[0]) begin
        read_reg(INFO_OFFSET, status);
      end
    end
  endtask

  task test_divide;
    input [31:0] dividend;
    input [31:0] divisor;
    input [31:0] expected_quo;
    input [31:0] expected_rem;
    reg [31:0] quo, rem;
    begin
      write_reg(END_OFFSET, dividend);
      write_reg(SOR_OFFSET, divisor);
      wait_not_busy;

      // Allow one extra cycle for result to settle
      @(posedge clk);

      read_reg(QUO_OFFSET, quo);
      read_reg(REM_OFFSET, rem);

      if (quo === expected_quo && rem === expected_rem) begin
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL: %0d / %0d = %0d r %0d (expected %0d r %0d)",
                 dividend, divisor, quo, rem, expected_quo, expected_rem);
        fail_count = fail_count + 1;
      end
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n      = 0;
    we         = 0;
    re         = 0;
    address    = 0;
    write_data = 0;

    // Reset
    #200;
    rst_n = 1;
    #100;

    // Test cases
    test_divide(32'd100,  32'd10,   32'd10,  32'd0);
    test_divide(32'd100,  32'd3,    32'd33,  32'd1);
    test_divide(32'd7,    32'd2,    32'd3,   32'd1);
    test_divide(32'd0,    32'd5,    32'd0,   32'd0);
    test_divide(32'd1,    32'd1,    32'd1,   32'd0);
    test_divide(32'd255,  32'd16,   32'd15,  32'd15);
    test_divide(32'd1000, 32'd7,    32'd142, 32'd6);
    test_divide(32'hFFFFFFFF, 32'd2, 32'h7FFFFFFF, 32'd1);

    // Summary
    $display("Divider Test: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0)
      $display("DIVIDER TEST FAILED");
    else
      $display("DIVIDER TEST PASSED");
    $finish;
  end

  // Timeout
  initial begin
    #5000000;
    $display("TIMEOUT: Test did not complete in time");
    $finish;
  end

endmodule
