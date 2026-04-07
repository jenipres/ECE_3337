`timescale 1ns / 1ps

module Title_Renderer(
    input  wire       pixel_clk,
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    output reg  [3:0] R,
    output reg  [3:0] G,
    output reg  [3:0] B
);

    wire visible = (h_count < 10'd640) && (v_count < 10'd480);

    wire [8:0] x_small = h_count[9:1];
    wire [7:0] y_small = v_count[8:1];

    wire [16:0] addr = (y_small * 9'd320) + x_small;

    wire [3:0]  title_idx;
    wire [11:0] title_rgb;

    Title_ROM u_title_rom (
        .clk(pixel_clk),
        .addr(addr),
        .pix_idx(title_idx)
    );

    Title_Palette_ROM u_title_palette (
        .idx(title_idx),
        .rgb(title_rgb)
    );

    always @(*) begin
        if (visible) begin
            R = title_rgb[11:8];
            G = title_rgb[7:4];
            B = title_rgb[3:0];
        end else begin
            R = 4'h0;
            G = 4'h0;
            B = 4'h0;
        end
    end

endmodule