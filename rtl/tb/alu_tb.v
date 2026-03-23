`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Self-checking ALU unit test.
 *
 * Validates all 10 ALU operations with known input/output pairs.
 */
module alu_tb;

  reg  [31:0] operand1;
  reg  [31:0] operand2;
  reg  [ 3:0] operation;
  wire [31:0] result;
  wire        zero;

  integer pass_count;
  integer fail_count;

  localparam OP_ADD  = 4'b0000;
  localparam OP_SUB  = 4'b0001;
  localparam OP_AND  = 4'b0010;
  localparam OP_OR   = 4'b0011;
  localparam OP_XOR  = 4'b0100;
  localparam OP_SLL  = 4'b0101;
  localparam OP_SRL  = 4'b0110;
  localparam OP_SRA  = 4'b0111;
  localparam OP_SLT  = 4'b1000;
  localparam OP_SLTU = 4'b1001;

  alu uut (
    .operand1  (operand1),
    .operand2  (operand2),
    .operation (operation),
    .result    (result),
    .zero      (zero)
  );

  task check;
    input [31:0] expected;
    input [127:0] test_name;
    begin
      #1;
      if (result === expected) begin
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL: %0s: expected 0x%08X, got 0x%08X", test_name, expected, result);
        fail_count = fail_count + 1;
      end
    end
  endtask

  initial begin
    pass_count = 0;
    fail_count = 0;

    // --- ADD ---
    operand1 = 32'd10; operand2 = 32'd20; operation = OP_ADD;
    check(32'd30, "ADD 10+20");

    operand1 = 32'hFFFFFFFF; operand2 = 32'd1; operation = OP_ADD;
    check(32'd0, "ADD overflow");

    operand1 = 32'd0; operand2 = 32'd0; operation = OP_ADD;
    check(32'd0, "ADD 0+0");

    // --- SUB ---
    operand1 = 32'd20; operand2 = 32'd10; operation = OP_SUB;
    check(32'd10, "SUB 20-10");

    operand1 = 32'd0; operand2 = 32'd1; operation = OP_SUB;
    check(32'hFFFFFFFF, "SUB 0-1");

    // --- AND ---
    operand1 = 32'hFF00FF00; operand2 = 32'h0F0F0F0F; operation = OP_AND;
    check(32'h0F000F00, "AND");

    // --- OR ---
    operand1 = 32'hFF00FF00; operand2 = 32'h0F0F0F0F; operation = OP_OR;
    check(32'hFF0FFF0F, "OR");

    // --- XOR ---
    operand1 = 32'hFF00FF00; operand2 = 32'h0F0F0F0F; operation = OP_XOR;
    check(32'hF00FF00F, "XOR");

    // --- SLL ---
    operand1 = 32'd1; operand2 = 32'd4; operation = OP_SLL;
    check(32'd16, "SLL 1<<4");

    operand1 = 32'h80000000; operand2 = 32'd1; operation = OP_SLL;
    check(32'd0, "SLL overflow");

    // --- SRL ---
    operand1 = 32'd16; operand2 = 32'd4; operation = OP_SRL;
    check(32'd1, "SRL 16>>4");

    operand1 = 32'h80000000; operand2 = 32'd1; operation = OP_SRL;
    check(32'h40000000, "SRL logical");

    // --- SRA ---
    operand1 = 32'h80000000; operand2 = 32'd1; operation = OP_SRA;
    check(32'hC0000000, "SRA sign ext");

    operand1 = 32'h40000000; operand2 = 32'd1; operation = OP_SRA;
    check(32'h20000000, "SRA positive");

    // --- SLT ---
    operand1 = 32'hFFFFFFFF; operand2 = 32'd0; operation = OP_SLT;
    check(32'd1, "SLT -1<0");

    operand1 = 32'd0; operand2 = 32'hFFFFFFFF; operation = OP_SLT;
    check(32'd0, "SLT 0>-1");

    operand1 = 32'd5; operand2 = 32'd5; operation = OP_SLT;
    check(32'd0, "SLT 5==5");

    // --- SLTU ---
    operand1 = 32'd0; operand2 = 32'hFFFFFFFF; operation = OP_SLTU;
    check(32'd1, "SLTU 0<MAX");

    operand1 = 32'hFFFFFFFF; operand2 = 32'd0; operation = OP_SLTU;
    check(32'd0, "SLTU MAX>0");

    // --- Zero flag ---
    operand1 = 32'd5; operand2 = 32'd5; operation = OP_SUB;
    #1;
    if (zero === 1'b1) pass_count = pass_count + 1;
    else begin $display("FAIL: zero flag not set"); fail_count = fail_count + 1; end

    operand1 = 32'd5; operand2 = 32'd4; operation = OP_SUB;
    #1;
    if (zero === 1'b0) pass_count = pass_count + 1;
    else begin $display("FAIL: zero flag incorrectly set"); fail_count = fail_count + 1; end

    // --- Default ---
    operand1 = 32'hDEADBEEF; operand2 = 32'h12345678; operation = 4'b1111;
    check(32'd0, "default op");

    // --- Summary ---
    $display("ALU Test: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0) begin
      $display("ALU TEST FAILED");
      $finish;
    end else begin
      $display("ALU TEST PASSED");
    end
    $finish;
  end

endmodule
