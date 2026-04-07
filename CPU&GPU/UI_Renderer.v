`timescale 1ns / 1ps

module UI_Renderer(
    input  wire        pixel_clk,     // NEW: needed for BRAM font read
    input  wire [9:0]  h_count,
    input  wire [9:0]  v_count,
    input  wire        visible,

    input  wire        game_over,

    input  wire [3:0]  score_thousands,
    input  wire [3:0]  score_hundreds,
    input  wire [3:0]  score_tens,
    input  wire [3:0]  score_ones,

    output reg         ui_on,
    output reg  [3:0]  uiR,
    output reg  [3:0]  uiG,
    output reg  [3:0]  uiB
);

    // 16x16 character cell (8x8 font scaled by 2)
    localparam [9:0] CHAR_W = 10'd16;
    localparam [9:0] CHAR_H = 10'd16;

    // SCORE position (top-left)
    localparam [9:0] SCORE_X = 10'd8;
    localparam [9:0] SCORE_Y = 10'd8;

    // YOU DIED centered (8 chars including space)
    localparam [9:0] DIE_X = 10'd256;
    localparam [9:0] DIE_Y = 10'd232;

    // returns the Nth character of SCORE:#### and YOU DIED
    function [7:0] score_char;
        input [3:0] idx;
        begin
            case (idx)
                4'd0: score_char = "S";
                4'd1: score_char = "C";
                4'd2: score_char = "O";
                4'd3: score_char = "R";
                4'd4: score_char = "E";
                4'd5: score_char = ":";
                4'd6: score_char = "0" + score_thousands;
                4'd7: score_char = "0" + score_hundreds;
                4'd8: score_char = "0" + score_tens;
                4'd9: score_char = "0" + score_ones;
                default: score_char = " ";
            endcase
        end
    endfunction

    function [7:0] died_char;
        input [3:0] idx;
        begin
            case (idx)
                4'd0: died_char = "Y";
                4'd1: died_char = "O";
                4'd2: died_char = "U";
                4'd3: died_char = " ";
                4'd4: died_char = "D";
                4'd5: died_char = "I";
                4'd6: died_char = "E";
                4'd7: died_char = "D";
                default: died_char = " ";
            endcase
        end
    endfunction

    // -----------------------------
    // SCORE region decode
    // -----------------------------
    wire [9:0] sx = h_count - SCORE_X;
    wire [9:0] sy = v_count - SCORE_Y;

    wire in_score_box =
        visible &&
        (h_count >= SCORE_X) && (v_count >= SCORE_Y) &&
        (sx < (10'd10 * CHAR_W)) && (sy < CHAR_H);

    wire [3:0] score_char_idx = sx[9:4];   // /16
    wire [3:0] score_px16     = sx[3:0];   // 0..15
    wire [3:0] score_py16     = sy[3:0];

    wire [2:0] score_fx = score_px16[3:1]; // /2 -> 0..7
    wire [2:0] score_fy = score_py16[3:1]; // /2 -> 0..7

    wire [7:0] score_ch = score_char(score_char_idx);

    // -----------------------------
    // YOU DIED region decode
    // -----------------------------
    wire [9:0] dx = h_count - DIE_X;
    wire [9:0] dy = v_count - DIE_Y;

    wire in_died_box =
        visible && game_over &&
        (h_count >= DIE_X) && (v_count >= DIE_Y) &&
        (dx < (10'd8 * CHAR_W)) && (dy < CHAR_H);

    wire [3:0] died_char_idx = dx[9:4];
    wire [3:0] died_px16     = dx[3:0];
    wire [3:0] died_py16     = dy[3:0];

    wire [2:0] died_fx = died_px16[3:1];
    wire [2:0] died_fy = died_py16[3:1];

    wire [7:0] died_ch = died_char(died_char_idx);

    // =========================================================
    // BRAM FONT (1-cycle latency)
    // =========================================================
    wire [7:0] score_row_bram;
    wire [7:0] died_row_bram;

    // Font_ROM must exist in your project and load "font.mem"
    Font_ROM U_FONT_SCORE (
        .clk(pixel_clk),
        .ch(score_ch),
        .row(score_fy),
        .bits(score_row_bram)
    );

    Font_ROM U_FONT_DIED (
        .clk(pixel_clk),
        .ch(died_ch),
        .row(died_fy),
        .bits(died_row_bram)
    );

    // Delay selectors/region flags by 1 cycle to match BRAM output timing
    reg in_score_box_d, in_died_box_d;
    reg [2:0] score_fx_d, died_fx_d;

    always @(posedge pixel_clk) begin
        in_score_box_d <= in_score_box;
        in_died_box_d  <= in_died_box;
        score_fx_d     <= score_fx;
        died_fx_d      <= died_fx;
    end

    wire score_bit = score_row_bram[7 - score_fx_d];
    wire died_bit  = died_row_bram[7 - died_fx_d];

    // =========================================================
    // Output compositor (uses delayed flags)
    // =========================================================
    always @(*) begin
        ui_on = 1'b0;
        uiR = 4'h0; uiG = 4'h0; uiB = 4'h0;

        // Priority: YOU DIED over score
        if (in_died_box_d && died_bit) begin
            ui_on = 1'b1;
            uiR = 4'hF; uiG = 4'h0; uiB = 4'h0; // red
        end else if (in_score_box_d && score_bit) begin
            ui_on = 1'b1;
            uiR = 4'hF; uiG = 4'hF; uiB = 4'hF; // white
        end
    end

endmodule