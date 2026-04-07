`timescale 1ns / 1ps

module Background_Renderer(
    input  wire        pixel_clk,
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire [9:0]  scroll_x,   // 0..639
    output wire [3:0]  bgR,
    output wire [3:0]  bgG,
    output wire [3:0]  bgB
);

    // ---------------------------------------
    // Stage 0: scroll + scale (combinational)
    // ---------------------------------------
    wire [10:0] sum_x = {1'b0,h_count} + {1'b0,scroll_x};
    wire [9:0]  x_sc  = (sum_x >= 11'd640) ? (sum_x - 11'd640) : sum_x[9:0];
    wire [9:0]  y_sc  = v_count;

    // 640x480 -> 320x240
    wire [8:0] bg_x0 = x_sc[9:1];  // 0..319
    wire [7:0] bg_y0 = y_sc[9:1];  // 0..239

    // ---------------------------------------
    // IMPORTANT: pipeline h/v 3 stages too
    // so we compute visible exactly aligned
    // with the BRAM output stage
    // ---------------------------------------
    reg [9:0] h1, v1, h2, v2, h3, v3;
    always @(posedge pixel_clk) begin
        h1 <= h_count;  v1 <= v_count;
        h2 <= h1;       v2 <= v1;
        h3 <= h2;       v3 <= v2;
    end

    wire visible_s3 = (h3 < 10'd640) && (v3 < 10'd480);

    // ---------------------------------------
    // Stage 1: BG ROM read (1 cycle)
    // ---------------------------------------
    wire [7:0] bg_idx_s1;
BG_ROM_320x240_4BPP u_bgrom (
    .clk(pixel_clk),
    .x(bg_x0),
    .y(bg_y0),
    .idx(bg_idx_s1)
);
    // ---------------------------------------
    // Stage 2: Palette read (1 cycle)
    // ---------------------------------------
    wire [3:0] pr_s2, pg_s2, pb_s2;
Palette u_pal (
    .clk(pixel_clk),
    .color_idx(bg_idx_s1),
    .r(pr_s2),
    .g(pg_s2),
    .b(pb_s2)
);

    // ---------------------------------------
    // Stage 3: register RGB (1 cycle)
    // ---------------------------------------
    reg [3:0] pr_s3, pg_s3, pb_s3;
    always @(posedge pixel_clk) begin
        pr_s3 <= pr_s2;
        pg_s3 <= pg_s2;
        pb_s3 <= pb_s2;
    end

    // Gate with visible computed from delayed coords (NOT delayed boolean)
    assign bgR = visible_s3 ? pr_s3 : 4'h0;
    assign bgG = visible_s3 ? pg_s3 : 4'h0;
    assign bgB = visible_s3 ? pb_s3 : 4'h0;

endmodule