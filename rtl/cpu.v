`default_nettype none
`timescale 1ns / 1ns

module cpu (
  input  wire        clk,
  input  wire        rst_n,
  output wire [31:0] address,
  output reg  [31:0] write_data,
  input  wire [31:0] read_data,
  output reg         we,
  output reg         re,
  input  wire        mem_busy
);

localparam [3:0]
    FETCH        = 4'd0,
    WAIT         = 4'd1,
    DECODE       = 4'd2,
    EXECUTE      = 4'd3,
    MEMORY       = 4'd4,
    MEMHALT      = 4'd5,
    WRITEBACK    = 4'd6,
    RMW_WAIT     = 4'd7,
    STORE_RMW    = 4'd8;

localparam [3:0]
    OP_ADD       = 4'b0000,
    OP_SUB       = 4'b0001,
    OP_AND       = 4'b0010,
    OP_OR        = 4'b0011,
    OP_XOR       = 4'b0100,
    OP_SLL       = 4'b0101,
    OP_SRL       = 4'b0110,
    OP_SRA       = 4'b0111,
    OP_SLT       = 4'b1000,
    OP_SLTU      = 4'b1001;

localparam [2:0]
    F3_ADD_SUB   = 3'b000,
    F3_SLL       = 3'b001,
    F3_SLT       = 3'b010,
    F3_SLTU      = 3'b011,
    F3_XOR       = 3'b100,
    F3_SRL_SRA   = 3'b101,
    F3_OR        = 3'b110,
    F3_AND       = 3'b111;

localparam [2:0]
    F3_LB        = 3'b000,
    F3_LH        = 3'b001,
    F3_LW        = 3'b010,
    F3_LBU       = 3'b100,
    F3_LHU       = 3'b101;

localparam [2:0]
    F3_SB        = 3'b000,
    F3_SH        = 3'b001,
    F3_SW        = 3'b010;

localparam [2:0]
    F3_BEQ       = 3'b000,
    F3_BNE       = 3'b001,
    F3_BLT       = 3'b100,
    F3_BGE       = 3'b101,
    F3_BLTU      = 3'b110,
    F3_BGEU      = 3'b111;

localparam [6:0]
    F7_ADD       = 7'b0000000,
    F7_SUB       = 7'b0100000,
    F7_SLL       = 7'b0000000,
    F7_SLT       = 7'b0000000,
    F7_SLTU      = 7'b0000000,
    F7_XOR       = 7'b0000000,
    F7_SRL       = 7'b0000000,
    F7_SRA       = 7'b0100000,
    F7_OR        = 7'b0000000,
    F7_AND       = 7'b0000000;

localparam [6:0]
    OPCODE_LUI      = 7'b0110111,
    OPCODE_AUIPC    = 7'b0010111,
    OPCODE_JAL      = 7'b1101111,
    OPCODE_JALR     = 7'b1100111,
    OPCODE_BRANCH   = 7'b1100011,
    OPCODE_LOAD     = 7'b0000011,
    OPCODE_STORE    = 7'b0100011,
    OPCODE_OP_IMM   = 7'b0010011,
    OPCODE_OP       = 7'b0110011;

  reg [31:0] PC;
  reg [31:0] inst;
  reg [31:0] address_reg;
  reg [31:0] reg_w_data;
  reg [31:0] alu_operand1;
  reg [31:0] alu_operand2;
  reg [31:0] imm;
  reg [ 4:0] reg_write_addr;
  reg [ 3:0] alu_op;
  reg [ 3:0] state;
  reg [ 3:0] next_state;
  reg [ 1:0] mem_offset;
  reg        reg_we;

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [31:0] alu_result;
  wire [ 6:0] opcode;
  wire [ 6:0] funct7;
  wire [ 4:0] rs1;
  wire [ 4:0] rs2;
  wire [ 4:0] rd;
  wire [ 2:0] funct3;
  wire        alu_zero;

  assign address = address_reg;

  assign opcode = inst[ 6: 0];
  assign funct7 = inst[31:25];
  assign rs1    = inst[19:15];
  assign rs2    = inst[24:20];
  assign rd     = inst[11: 7];
  assign funct3 = inst[14:12];

  register_file reg_file (
    .rst_n     (rst_n),
    .clk       (clk),
    .we        (reg_we),
    .rd        (reg_write_addr),
    .rs1       (rs1),
    .rs2       (rs2),
    .rd_data   (reg_w_data),
    .rs1_data  (rs1_data),
    .rs2_data  (rs2_data)
  );

  alu alu_inst (
    .operand1  (alu_operand1),
    .operand2  (alu_operand2),
    .operation (alu_op),
    .result    (alu_result),
    .zero      (alu_zero)
  );

  always @( * )
  begin

    case (opcode)

      OPCODE_OP_IMM,
      OPCODE_LOAD,
      OPCODE_JALR: 
        imm = {{20{inst[31]}}, inst[31:20]};

      OPCODE_STORE:
        imm = {{20{inst[31]}}, 
                   inst[31:25], 
                   inst[11:7]};

      OPCODE_BRANCH:
        imm = {{20{inst[31]}}, 
                   inst[7], 
                   inst[30:25], 
                   inst[11: 8], 
                   1'b0};

      OPCODE_LUI,
      OPCODE_AUIPC:
        imm = {inst[31: 12], 12'b0};

      OPCODE_JAL:
        imm = {{11{inst[31]}},
                   inst[31],
                   inst[19:12],
                   inst[20],
                   inst[30:21],
                   1'b0};

      default: imm = 32'd0;

    endcase
  end

  always @( * )
  begin
    case (state)

      FETCH:
        next_state = WAIT;

      WAIT:
        next_state = (mem_busy || re) ? WAIT : DECODE;

      DECODE:
        next_state = EXECUTE;

      EXECUTE:
      begin
        if (opcode == OPCODE_LOAD || opcode == OPCODE_STORE)
          next_state = MEMORY;
        else
          next_state = WRITEBACK;
      end

      MEMORY:
      begin
        if (opcode == OPCODE_LOAD)
          next_state = (mem_busy || re) ? MEMORY : MEMHALT;
        else
          if (opcode == OPCODE_STORE)
          begin
            if (funct3 == F3_SW)
              next_state = (mem_busy || re) ? MEMORY : MEMHALT;
            else
              if (funct3 == F3_SB || funct3 == F3_SH)
                next_state = (mem_busy || re) ? MEMORY : RMW_WAIT;
              else
                next_state = (mem_busy || re) ? MEMORY : MEMHALT;
          end
          else
            next_state = WRITEBACK;
      end

      RMW_WAIT:
        next_state = (mem_busy || re || we) ? RMW_WAIT  : STORE_RMW;
      STORE_RMW:
        next_state = (mem_busy || re || we) ? STORE_RMW : MEMHALT;
      MEMHALT:
        next_state = (mem_busy || re || we) ? MEMHALT   : WRITEBACK;
      WRITEBACK:
        next_state = FETCH;
      default:
        next_state = FETCH;

    endcase
  end

  always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      state       <= FETCH;
      PC          <= 32'h00004000;
      inst        <= 32'h00000013;
      reg_we      <= 1'b0;
      re          <= 1'b0;
      we          <= 1'b0;
      write_data  <= 32'd0;
      address_reg <= 32'h00004000;
      mem_offset  <= 2'b00;
    end
    else
    begin
      state      <= next_state;
      reg_we     <= 1'b0;
      write_data <= 32'd0;
      re         <= 1'b0;
      we         <= 1'b0;

      case (state)

        FETCH:
        begin
          re          <= 1'b1;
          address_reg <= PC;
        end

        WAIT:
        begin
          re   <= 1'b0;
        end

        DECODE:
        begin
          inst <= read_data;
        end

        EXECUTE:
        begin
          case (opcode)

            OPCODE_OP:
            begin
              alu_operand1 <= rs1_data;
              alu_operand2 <= rs2_data;

              case (funct3)

                F3_ADD_SUB:
                  alu_op <= funct7[5] ? OP_SUB : OP_ADD;

                F3_AND:
                  alu_op <= OP_AND;

                F3_OR:
                  alu_op <= OP_OR;

                F3_XOR:
                  alu_op <= OP_XOR;

                F3_SLL:
                  alu_op <= OP_SLL;

                F3_SRL_SRA:
                  alu_op <= funct7[5] ? OP_SRA : OP_SRL;

                F3_SLT:
                  alu_op <= OP_SLT;

                F3_SLTU:
                  alu_op <= OP_SLTU;

                default:
                  alu_op <= 4'b1111;

              endcase
            end

            OPCODE_OP_IMM:
            begin
              alu_operand1 <= rs1_data;

              if (funct3 == F3_SLL || funct3 == F3_SRL_SRA)
                alu_operand2 <= inst[24: 20];
              else
                alu_operand2 <= imm;

              case (funct3)

                F3_ADD_SUB:
                  alu_op <= OP_ADD;

                F3_AND:
                  alu_op <= OP_AND;

                F3_OR:
                  alu_op <= OP_OR;

                F3_XOR:
                  alu_op <= OP_XOR;

                F3_SLT:
                  alu_op <= OP_SLT;

                F3_SLTU:
                  alu_op <= OP_SLTU;

                F3_SLL:
                  alu_op <= OP_SLL;

                F3_SRL_SRA:
                  alu_op <= (inst[30]) ? OP_SRA : OP_SRL;

                default:
                  alu_op <= 4'b1111;

              endcase
            end

            OPCODE_LOAD:
            begin
              alu_operand1 <= rs1_data;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

            OPCODE_STORE:
            begin
              alu_operand1 <= rs1_data;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

           OPCODE_JAL:
            begin
              alu_operand1 <= PC;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

            OPCODE_JALR:
            begin
              alu_operand1 <= rs1_data;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

            OPCODE_BRANCH:
            begin
              alu_operand1 <= rs1_data;
              alu_operand2 <= rs2_data;
              alu_op       <= OP_SUB;
            end

            OPCODE_AUIPC:
            begin
              alu_operand1 <= PC;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

            OPCODE_LUI:
            begin
              alu_operand1 <= 32'd0;
              alu_operand2 <= imm;
              alu_op       <= OP_ADD;
            end

            default:
            begin
              alu_operand1 <= 32'd0;
              alu_operand2 <= 32'd0;
              alu_op       <= 4'b1111;
            end

          endcase
        end

        MEMORY:
        begin
          if (opcode == OPCODE_LOAD)
          begin
            re          <= 1'b1;
            address_reg <= alu_result & 32'hFFFFFFFC;
            mem_offset  <= alu_result[1: 0];
          end
          else
            if (opcode == OPCODE_STORE)
            begin
              if (funct3 == F3_SW)
              begin
                write_data  <= rs2_data;
                we          <= 1'b1;
                address_reg <= alu_result;
              end
              else
                if (funct3 == F3_SB || funct3 == F3_SH)
                begin
                  re          <= 1'b1;
                  address_reg <= alu_result & 32'hFFFFFFFC;
                  mem_offset  <= alu_result[1:0];
                end
            end
        end

        RMW_WAIT:
        begin
          // wait
        end

        STORE_RMW:
        begin
          if (funct3 == F3_SB)
          begin
            case (mem_offset[1: 0])

              2'b00:
                write_data <= {read_data[31:8], rs2_data[7:0]};

              2'b01:
                write_data <= {read_data[31:16], rs2_data[7:0], read_data[7: 0]};

              2'b10:
                write_data <= {read_data[31:24], rs2_data[7:0], read_data[15: 0]};

              2'b11:
                write_data <= {rs2_data[7:0], read_data[23:0]};

              default:
                write_data <= read_data;

            endcase
          end
          else
            if (funct3 == F3_SH)
            begin
              if (mem_offset[1] == 1'b0)
                write_data <= {read_data[31: 16], rs2_data[15: 0]};
              else
                write_data <= {rs2_data[15: 0], read_data[15: 0]};
            end
            else
              write_data <= read_data;

          we <= 1'b1;
        end

        MEMHALT:
        begin
          // wait
        end

        WRITEBACK:
        begin
          if (opcode == 7'b0000011)
          begin
            case (funct3)

              F3_LB:
              begin
                case (mem_offset[1: 0])
                  2'b00:   reg_w_data <= {{24{read_data[ 7]}}, read_data[ 7: 0]};
                  2'b01:   reg_w_data <= {{24{read_data[15]}}, read_data[15: 8]};
                  2'b10:   reg_w_data <= {{24{read_data[23]}}, read_data[23:16]};
                  2'b11:   reg_w_data <= {{24{read_data[31]}}, read_data[31:24]};
                  default: reg_w_data <= read_data;
                endcase
              end

              F3_LH:
              begin
                if (mem_offset[1] == 1'b0)
                  reg_w_data <= {{16{read_data[15]}}, read_data[15:0]};
                else
                  reg_w_data <= {{16{read_data[31]}}, read_data[31:16]};
              end

              F3_LW:
              begin
                reg_w_data <= read_data;
              end

              F3_LBU:
              begin
                case (mem_offset[1: 0])

                  2'b00:
                    reg_w_data <= {24'd0, read_data[ 7:0]};

                  2'b01:
                    reg_w_data <= {24'd0, read_data[15:8]};

                  2'b10:
                    reg_w_data <= {24'd0, read_data[23:16]};

                  2'b11:
                    reg_w_data <= {24'd0, read_data[31:24]};

                  default:
                    reg_w_data <= read_data;

                endcase
              end

              F3_LHU:
              begin
                if (mem_offset[1] == 1'b0)
                  reg_w_data <= {16'd0, read_data[15: 0]};
                else
                  reg_w_data <= {16'd0, read_data[31:16]};
              end

              default:
                reg_w_data <= read_data;

            endcase
          end

          else if (opcode == OPCODE_JAL || 
                   opcode == OPCODE_JALR)
            reg_w_data <= PC + 4;

          else if (opcode == OPCODE_LUI)
            reg_w_data <= imm;

          else if (opcode == OPCODE_AUIPC)
            reg_w_data <= PC + imm;

          else if (opcode == OPCODE_OP_IMM || 
                   opcode == OPCODE_OP)
            reg_w_data <= alu_result;

          else
            reg_w_data <= 32'd0;

          if (opcode == OPCODE_LOAD  || opcode == OPCODE_JAL    ||
              opcode == OPCODE_JALR  || opcode == OPCODE_LUI    ||
              opcode == OPCODE_AUIPC || opcode == OPCODE_OP_IMM ||
              opcode == OPCODE_OP)
          begin
            reg_write_addr <= rd;
            reg_we <= (rd != 5'd0);
          end

          else
            reg_we <= 1'b0;

          if (opcode == OPCODE_JAL)
            PC <= alu_result;
          else
            if (opcode == OPCODE_JALR)
              PC <= alu_result & ~32'd1;
            else
              if (opcode == OPCODE_BRANCH)
              begin
                case (funct3)

                  F3_BEQ:
                    PC <= (alu_zero) ? (PC + imm) : (PC + 4);

                  F3_BNE:
                    PC <= (!alu_zero) ? (PC + imm) : (PC + 4);

                  F3_BLT:
                    PC <= ($signed(rs1_data) < $signed(rs2_data)) ? (PC + imm) : (PC + 4);

                  F3_BGE:
                    PC <= ($signed(rs1_data) >= $signed(rs2_data)) ? (PC + imm) : (PC + 4);

                  F3_BLTU:
                    PC <= (rs1_data < rs2_data) ? (PC + imm) : (PC + 4);

                  F3_BGEU:
                    PC <= (rs1_data >= rs2_data) ? (PC + imm) : (PC + 4);

                  default: 
                    PC <= PC + 4;

                endcase
              end
              else
                PC <= PC + 4;
        end

        default: ;

      endcase
    end
  end

endmodule
