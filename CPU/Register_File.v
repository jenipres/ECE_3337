`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 10:30:10 AM
// Design Name: 
// Module Name: Register_File
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


module Register_File(
    input  wire        clk,
    input  wire        reset,
    input  wire        RegWrite,

    input  wire [2:0]  read_reg1,
    input  wire [2:0]  read_reg2,
    input  wire [2:0]  write_reg,

    input  wire [7:0] write_data,

    output wire [7:0] read_data1,  //used to be 16-bit, now fixed to 8-bits
    output wire [7:0] read_data2
);

    // 8 registers of 8 bits each
    reg [7:0] registers [0:7];

    integer i;

    // Optional reset (clears R1–R7)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 8'b0;
        end
        else if (RegWrite && write_reg != 3'b000) begin
            registers[write_reg] <= write_data;
        end
    end

    // Combinational reads
    assign read_data1 = (read_reg1 == 3'b000) ? 8'b0 : registers[read_reg1];
                                             

    assign read_data2 = (read_reg2 == 3'b000) ? 8'b0 : registers[read_reg2];
                                      
endmodule
