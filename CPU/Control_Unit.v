`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 10:30:10 AM
// Design Name: 
// Module Name: Control_Unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Control_Unit(
    input  wire        clk,
    input  wire        reset,
    input  wire [3:0]  opcode,
    input  wire        zero_flag,
    input  wire [2:0]  funct,      //NEW, R-type ALU function bits

    output reg         RegWrite,
    output reg         MemToReg,
    output reg         ALUSrc,
    output reg  [2:0]  ALUOp,
    output reg         PCWrite,
    output reg         PCSrc,
    output reg         IRWrite,
    output reg         IorD,
    output reg         MemWrite
);

    localparam
        S_FETCH   = 4'd0,
        S_DECODE  = 4'd1,
        S_EXECUTE = 4'd2,
        S_MEM     = 4'd3,
        S_WB      = 4'd4,
        S_BRANCH  = 4'd5,
        S_JUMP    = 4'd6,
        S_LDI     = 4'd7,
        S_HALT    = 4'd8;

    reg [3:0] state, next_state;

    // =====================
    // State Register
    // =====================

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S_FETCH;
        else
            state <= next_state;
    end

    // =====================
    // Next State Logic
    // =====================

    always @(*) begin
        case (state)

            S_FETCH:
                next_state = S_DECODE;

            S_DECODE: begin
                case (opcode)
                    4'b0000: next_state = S_EXECUTE; // R-type
                    
                    
                    4'b0001, 4'b1010, 4'b1011:
                               next_state = S_EXECUTE; // ADDI/ANDI/ORI
                    4'b0010, 4'b0011:
                               next_state = S_EXECUTE; // LOAD/STORE
                    4'b0100, 4'b0101:
                               next_state = S_EXECUTE; // BREQ/BRNEQ
                    4'b0110: next_state = S_JUMP;
                    4'b0111: next_state = S_LDI;
                    4'b1000: next_state = S_EXECUTE; // CMP
                    4'b1111: next_state = S_HALT;
                    default: next_state = S_FETCH;
                endcase
            end

            S_EXECUTE: begin
                case (opcode)
                    4'b0010, 4'b0011: next_state = S_MEM;    // LOAD/STORE
                    4'b0100, 4'b0101: next_state = S_BRANCH; // Branches
                    4'b1000:          next_state = S_FETCH;  // CMP
                    default:          next_state = S_WB;
                endcase
            end

            S_MEM:
              next_state = (opcode == 4'b0010) ? S_WB : S_FETCH;

            S_WB:
                next_state = S_FETCH;

            S_BRANCH:
                next_state = S_FETCH;

            S_JUMP:
                next_state = S_FETCH;

            S_LDI:
                next_state = S_FETCH;

            S_HALT:
                next_state = S_HALT;

            default:
                next_state = S_FETCH;
        endcase
    end

    // =====================
    // Output Logic
    // =====================

    always @(*) begin

        // Defaults
        RegWrite = 0;
        MemToReg = 0;
        ALUSrc   = 0;
        ALUOp    = 3'b000;
        PCWrite  = 0;
        PCSrc    = 0;
        IRWrite  = 0;
        IorD     = 0;
        MemWrite = 0;

        case (state)

            S_FETCH: begin
                IRWrite = 1;
                PCWrite = 1;
                PCSrc   = 0;
                IorD    = 0;
            end

            S_EXECUTE: begin
                case (opcode)
                    //---- R-TYPE ----
                   4'b0000:begin
                        ALUOp = funct; //NEW: use function bits
                        ALUSrc = 0;   //hold on, check up on this LINE
                        end
                       
                   // ===== IMMEDIATE ALU =====
                  4'b0001: begin ALUOp = 3'b000; ALUSrc = 1; end // ADDI
                  4'b1010: begin ALUOp = 3'b010; ALUSrc = 1; end // ANDI
                  4'b1011: begin ALUOp = 3'b011; ALUSrc = 1; end // ORI

                   // ===== LOAD / STORE =====
                  4'b0010, 4'b0011: begin
                  ALUOp  = 3'b000; // address calc
                  ALUSrc = 1;
                  end

                 // ===== BRANCH / CMP =====
                4'b0100, 4'b0101,
                4'b1000: ALUOp = 3'b001; // SUB

                endcase
            end

            S_MEM: begin
                IorD = 1;
                if (opcode == 4'b0011)
                    MemWrite = 1; // STORE
            end

            S_WB: begin
                RegWrite = 1;
                if (opcode == 4'b0010)
                    MemToReg = 1; // LOAD
            end

            S_BRANCH: begin
                if ((opcode == 4'b0100 && zero_flag) ||
                    (opcode == 4'b0101 && !zero_flag)) begin
                    PCWrite = 1;
                    PCSrc   = 1;
                end
            end

            S_JUMP: begin
                PCWrite = 1;
                PCSrc   = 1;
            end

            S_LDI: begin
                RegWrite = 1;
            end

            S_HALT: begin
                // Freeze CPU
            end

        endcase
    end

endmodule

