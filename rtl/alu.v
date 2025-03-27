`default_nettype none
`timescale 1ns / 1ns

/**
 * @brief Arithmetisch-Logische Einheit (ALU) für 32-Bit-Operationen.
 *
 * Dieses Modul führt verschiedene arithmetische und logische Operationen
 * auf zwei 32-Bit-Operanden durch, basierend auf einem 4-Bit-Steuersignal.
 * Zusätzlich erzeugt es ein Zero-Flag, falls das Ergebnis 0 ist.
 *
 * Unterstützte Operationen (OP_...):
 * - ADD  (4'b0000) Addieren
 * - SUB  (4'b0001) Subtrahieren
 * - AND  (4'b0010) Bitwise UND
 * - OR   (4'b0011) Bitwise ODER
 * - XOR  (4'b0100) Bitwise EXKLUSIVE ODER
 * - SLL  (4'b0101) Bitweises Shift-Left
 * - SRL  (4'b0110) Bitweises Shift-Right (logisch)
 * - SRA  (4'b0111) Vorzeichenbehaftetes, bitweises Shift-Right (arithmetisch)
 * - SLT  (4'b1000) Vergleich (signed)
 * - SLTU (4'b1001) Vergleich (unsigned)
 *
 * @localparam OP_ADD  = 4'b0000
 * @localparam OP_SUB  = 4'b0001
 * @localparam OP_AND  = 4'b0010
 * @localparam OP_OR   = 4'b0011
 * @localparam OP_XOR  = 4'b0100
 * @localparam OP_SLL  = 4'b0101
 * @localparam OP_SRL  = 4'b0110
 * @localparam OP_SRA  = 4'b0111
 * @localparam OP_SLT  = 4'b1000
 * @localparam OP_SLTU = 4'b1001
 *
 * @input  [31:0]     operand1 Erstes Eingangsoperand
 * @input  [31:0]     operand2 Zweites Eingangsoperand
 * @input  [ 3:0]     operation 4-Bit-Operationscode
 *
 * @output reg [31:0] result Ergebnis des Rechenvorgangs
 * @output wire       zero   Signal, falls result=0
 */

module alu (
  input  wire [31:0] operand1,
  input  wire [31:0] operand2,
  input  wire [ 3:0] operation,
  output reg  [31:0] result,
  output wire        zero
);

  // ---------------------------------------------------------
  // Operationen als lokale Konstanten
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // Vorzeichenbehaftete Interpretionen der Operanden
  // ---------------------------------------------------------
  wire signed [31:0] sign_op1;
  wire signed [31:0] sign_op2;

  assign sign_op1 = $signed(operand1);
  assign sign_op2 = $signed(operand2);

  assign zero = (result == 32'd0);

  // ---------------------------------------------------------
  // Hauptzuweisung für result abhängig von operation
  // ---------------------------------------------------------
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
