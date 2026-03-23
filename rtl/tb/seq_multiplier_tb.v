`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Self-checking sequential multiplier unit test.
 *
 * Validates the shift-and-add multiplication with various test cases.
 */
module seq_multiplier_tb;

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
  localparam MUL1_OFFSET = 8'h04;
  localparam MUL2_OFFSET = 8'h08;
  localparam RESH_OFFSET = 8'h0C;
  localparam RESL_OFFSET = 8'h10;

  seq_multiplier uut (
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

  task test_multiply;
    input [31:0] a;
    input [31:0] b;
    input [31:0] expected_hi;
    input [31:0] expected_lo;
    reg [31:0] res_hi, res_lo;
    begin
      write_reg(MUL1_OFFSET, a);
      write_reg(MUL2_OFFSET, b);
      wait_not_busy;

      // Allow one extra cycle for result to settle
      @(posedge clk);

      read_reg(RESH_OFFSET, res_hi);
      read_reg(RESL_OFFSET, res_lo);

      if (res_hi === expected_hi && res_lo === expected_lo) begin
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL: %0d * %0d = 0x%08X_%08X (expected 0x%08X_%08X)",
                 a, b, res_hi, res_lo, expected_hi, expected_lo);
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

    // Test cases: a * b = {expected_hi, expected_lo}
    test_multiply(32'd10,   32'd20,   32'h0, 32'd200);
    test_multiply(32'd0,    32'd100,  32'h0, 32'd0);
    test_multiply(32'd1,    32'd1,    32'h0, 32'd1);
    test_multiply(32'd256,  32'd256,  32'h0, 32'd65536);
    test_multiply(32'hFFFF, 32'hFFFF, 32'h0, 32'hFFFE0001);  // 65535*65535
    test_multiply(32'hFFFFFFFF, 32'd2, 32'h1, 32'hFFFFFFFE); // (2^32-1)*2
    test_multiply(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFE, 32'h00000001); // (2^32-1)^2

    // Summary
    $display("Multiplier Test: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0)
      $display("MULTIPLIER TEST FAILED");
    else
      $display("MULTIPLIER TEST PASSED");
    $finish;
  end

  // Timeout
  initial begin
    #5000000;
    $display("TIMEOUT: Test did not complete in time");
    $finish;
  end

endmodule
