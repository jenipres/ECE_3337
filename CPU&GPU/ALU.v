`timescale 1ns / 1ps

module alu( //8-bit ALU
input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [2:0] ALUOp,

    output reg  [7:0] result,
    output wire       zero
);

always @(*) begin
    case (ALUOp)

        3'b000: result = A + B;
        3'b001: result = A - B;
        3'b010: result = A & B;
        3'b011: result = A | B;
        3'b100: result = A ^ B;
        3'b101: result = ~A;
        3'b110: result = A << 1;
        3'b111: result = A >> 1;

        default: result = 8'h00;

    endcase
end

assign zero = (result == 8'h00);

endmodule
