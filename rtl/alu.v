`default_nettype none
`timescale 1ns / 1ns

module alu (
  input  wire [31:0] operand1,
  input  wire [31:0] operand2,
  input  wire [ 3:0] operation,
  output reg  [31:0] result,
  output wire        zero
);

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

  wire signed [31:0] sign_op1;
  wire signed [31:0] sign_op2;

  assign sign_op1 = $signed(operand1);
  assign sign_op2 = $signed(operand2);

  assign zero = (result == 32'd0);

  always @( * )
  begin
    case (operation)

      OP_ADD:
        result =  operand1  +  operand2;
 
      OP_SUB: 
        result =  sign_op1  -  sign_op2;
 
      OP_AND: 
        result =  operand1  &  operand2;
 
      OP_OR: 
        result =  operand1  |  operand2;
 
      OP_XOR: 
        result =  operand1  ^  operand2;

      OP_SLL:
        result =  operand1 <<  operand2[4:0];

      OP_SRL:
        result =  operand1  >> operand2[4:0];

      OP_SRA:
        result =  sign_op1 >>> operand2[4:0];

      OP_SLT:
        result = (sign_op1  <  sign_op2) ? 32'd1 : 32'd0;

      OP_SLTU:
        result = (operand1  <  operand2) ? 32'd1 : 32'd0;


      default:
        result = 32'd0;

    endcase
  end

endmodule
