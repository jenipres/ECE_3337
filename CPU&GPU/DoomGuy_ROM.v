`timescale 1ns / 1ps

module DoomGuy_ROM(
    input  wire        clk,
    input  wire [8:0]  x,    // 0..239
    input  wire [6:0]  y,    // 0..63
    output reg  [11:0] rgb
);

    wire [13:0] addr = y * 14'd240 + x;

    (* ram_style="block" *)
    reg [11:0] mem [0:15359];

    initial begin
        $readmemh("doomguy_sheet_240x64_rgb444.mem", mem);
    end

    always @(posedge clk) begin
        rgb <= mem[addr];
    end

endmodule
