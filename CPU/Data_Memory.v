`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/04/2026 10:30:10 AM
// Design Name: 
// Module Name: Data_Memory
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


module Data_Memory(
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [15:0] addr,
    input  [7:0]  write_data,
    output [7:0]  read_data
    
);

    reg [7:0] memory [0:65535];
    wire [7:0] debug_mem7 = memory[7];
    
    assign read_data = (mem_read) ? memory[addr] : 8'b0;

    always @(posedge clk) begin
        if (mem_write) begin
        memory[addr] <= write_data;
            $display("STORE: MEM[%0d] = %0d at time %0t",   
                     addr, write_data, $time);  //line for debugging purposes, view in terminal
    end
end
endmodule
