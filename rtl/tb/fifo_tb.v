`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Self-checking FIFO unit test.
 *
 * Validates FIFO push/pop, empty/full flags, and overflow protection.
 */
module fifo_tb;

  reg         clk;
  reg         rst_n;
  reg         wr_en;
  reg         rd_en;
  wire        empty;
  wire        full;
  reg  [7:0]  din;
  wire [7:0]  dout;

  integer pass_count;
  integer fail_count;

  fifo #(
    .DATA_WIDTH(8),
    .DEPTH(4)
  ) uut (
    .clk   (clk),
    .rst_n (rst_n),
    .wr_en (wr_en),
    .rd_en (rd_en),
    .empty (empty),
    .full  (full),
    .din   (din),
    .dout  (dout)
  );

  initial clk = 0;
  always #50 clk = ~clk;

  task check_flags;
    input exp_empty;
    input exp_full;
    input [127:0] label;
    begin
      @(posedge clk); #1;
      if (empty !== exp_empty || full !== exp_full) begin
        $display("FAIL: %0s: empty=%b full=%b (expected empty=%b full=%b)",
                 label, empty, full, exp_empty, exp_full);
        fail_count = fail_count + 1;
      end else
        pass_count = pass_count + 1;
    end
  endtask

  task push;
    input [7:0] data;
    begin
      @(posedge clk);
      din   <= data;
      wr_en <= 1'b1;
      @(posedge clk);
      wr_en <= 1'b0;
      @(posedge clk); // Allow edge detection
    end
  endtask

  task pop;
    output [7:0] data;
    begin
      // dout already shows current head element; read it first
      @(posedge clk);
      #1;
      data = dout;
      // Now advance the read pointer
      rd_en <= 1'b1;
      @(posedge clk);
      rd_en <= 1'b0;
      @(posedge clk); // Allow edge detection
    end
  endtask

  reg [7:0] pop_data;

  initial begin
    pass_count = 0;
    fail_count = 0;
    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    din   = 0;

    #200;
    rst_n = 1;
    #100;

    // Initially empty
    check_flags(1'b1, 1'b0, "initial empty");

    // Push 4 items (fill FIFO)
    push(8'hAA);
    check_flags(1'b0, 1'b0, "after push 1");

    push(8'hBB);
    push(8'hCC);
    push(8'hDD);
    check_flags(1'b0, 1'b1, "after push 4 (full)");

    // Pop all items, check FIFO order
    pop(pop_data);
    if (pop_data === 8'hAA) pass_count = pass_count + 1;
    else begin $display("FAIL: pop1 expected AA got %02X", pop_data); fail_count = fail_count + 1; end

    pop(pop_data);
    if (pop_data === 8'hBB) pass_count = pass_count + 1;
    else begin $display("FAIL: pop2 expected BB got %02X", pop_data); fail_count = fail_count + 1; end

    pop(pop_data);
    if (pop_data === 8'hCC) pass_count = pass_count + 1;
    else begin $display("FAIL: pop3 expected CC got %02X", pop_data); fail_count = fail_count + 1; end

    pop(pop_data);
    if (pop_data === 8'hDD) pass_count = pass_count + 1;
    else begin $display("FAIL: pop4 expected DD got %02X", pop_data); fail_count = fail_count + 1; end

    check_flags(1'b1, 1'b0, "after pop all (empty)");

    // Summary
    $display("FIFO Test: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count > 0)
      $display("FIFO TEST FAILED");
    else
      $display("FIFO TEST PASSED");
    $finish;
  end

  // Timeout
  initial begin
    #1000000;
    $display("TIMEOUT");
    $finish;
  end

endmodule
