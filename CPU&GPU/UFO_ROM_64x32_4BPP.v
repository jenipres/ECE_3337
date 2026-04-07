`timescale 1ns / 1ps

module UFO_ROM_64x32_4BPP(
    input  wire        clk,
    input  wire [6:0]  x,    // 0..127
    input  wire [5:0]  y,    // 0..63
    output reg  [11:0] rgb
);
    wire [12:0] addr = y * 13'd128 + x;

    (* ram_style="block" *)
    reg [11:0] mem [0:8191];

    initial begin
        $readmemh("UFO_128x64_rgb444.mem", mem);
    end

    always @(posedge clk) begin
        rgb <= mem[addr];
    end
endmodule