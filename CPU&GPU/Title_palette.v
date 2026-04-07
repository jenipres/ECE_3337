`timescale 1ns / 1ps

module Title_Palette_ROM(
    input  wire [3:0]  idx,
    output reg  [11:0] rgb
);

    reg [11:0] palette [0:15];

    initial begin
        $readmemh("Title_palette.mem", palette);
    end

    always @(*) begin
        rgb = palette[idx];
    end

endmodule