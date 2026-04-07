`timescale 1ns / 1ps

module BILL(
    input  wire        clk,
    input  wire [5:0]  x,    // 0..47
    input  wire [3:0]  y,    // 0..15
    output reg  [11:0] rgb
);
    wire [9:0] addr = y * 10'd48 + x;   // 48*16 = 768 pixels

    (* ram_style="block" *)
    reg [11:0] mem [0:767];

    initial begin
        $readmemh("bullet_bill2.mem", mem);
    end

    always @(posedge clk) begin
        rgb <= mem[addr];
    end
endmodule
