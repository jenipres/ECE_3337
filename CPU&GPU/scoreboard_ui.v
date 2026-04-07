`timescale 1ns / 1ps

module scoreboard_ui(
    input  wire       pixel_clk,
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       in_scoreboard,

    input  wire [7:0] name0_c0, input wire [7:0] name0_c1, input wire [7:0] name0_c2,
    input  wire [7:0] name1_c0, input wire [7:0] name1_c1, input wire [7:0] name1_c2,
    input  wire [7:0] name2_c0, input wire [7:0] name2_c1, input wire [7:0] name2_c2,
    input  wire [7:0] name3_c0, input wire [7:0] name3_c1, input wire [7:0] name3_c2,
    input  wire [7:0] name4_c0, input wire [7:0] name4_c1, input wire [7:0] name4_c2,

    input  wire [13:0] score0,
    input  wire [13:0] score1,
    input  wire [13:0] score2,
    input  wire [13:0] score3,
    input  wire [13:0] score4,
        input wire valid0,
    input wire valid1,
    input wire valid2,
    input wire valid3,
    input wire valid4,

    output reg        ui_on,
    output reg  [3:0] R,
    output reg  [3:0] G,
    output reg  [3:0] B
);

    localparam [9:0] CHAR_W = 10'd16;
    localparam [9:0] CHAR_H = 10'd16;

    // Header placement inside big white rectangle
    localparam [9:0] HEADER_X = 10'd280;
    localparam [9:0] HEADER_Y = 10'd80;

    // Column anchors: Position | Score | Name
    localparam [9:0] RANK_X  = 10'd170;
    localparam [9:0] SCORE_X = 10'd220;
    localparam [9:0] NAME_X  = 10'd380;

    // Row anchors
    localparam [9:0] ROW0_Y = 10'd170;
    localparam [9:0] ROW1_Y = 10'd220;
    localparam [9:0] ROW2_Y = 10'd270;
    localparam [9:0] ROW3_Y = 10'd320;
    localparam [9:0] ROW4_Y = 10'd370;

    // -----------------------------
    // Score digit breakdown
    // -----------------------------
    wire [3:0] s0_th = (score0 / 1000) % 10;
    wire [3:0] s0_hu = (score0 / 100)  % 10;
    wire [3:0] s0_te = (score0 / 10)   % 10;
    wire [3:0] s0_on =  score0         % 10;

    wire [3:0] s1_th = (score1 / 1000) % 10;
    wire [3:0] s1_hu = (score1 / 100)  % 10;
    wire [3:0] s1_te = (score1 / 10)   % 10;
    wire [3:0] s1_on =  score1         % 10;

    wire [3:0] s2_th = (score2 / 1000) % 10;
    wire [3:0] s2_hu = (score2 / 100)  % 10;
    wire [3:0] s2_te = (score2 / 10)   % 10;
    wire [3:0] s2_on =  score2         % 10;

    wire [3:0] s3_th = (score3 / 1000) % 10;
    wire [3:0] s3_hu = (score3 / 100)  % 10;
    wire [3:0] s3_te = (score3 / 10)   % 10;
    wire [3:0] s3_on =  score3         % 10;

    wire [3:0] s4_th = (score4 / 1000) % 10;
    wire [3:0] s4_hu = (score4 / 100)  % 10;
    wire [3:0] s4_te = (score4 / 10)   % 10;
    wire [3:0] s4_on =  score4         % 10;

    // -----------------------------
    // Character helper functions
    // -----------------------------
    function [7:0] header_char;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: header_char = "T";
                3'd1: header_char = "O";
                3'd2: header_char = "P";
                3'd3: header_char = " ";
                3'd4: header_char = "5";
                default: header_char = " ";
            endcase
        end
    endfunction

    function [7:0] rank_char;
        input [2:0] row;
        begin
            case (row)
                3'd0: rank_char = "1";
                3'd1: rank_char = "2";
                3'd2: rank_char = "3";
                3'd3: rank_char = "4";
                default: rank_char = "5";
            endcase
        end
    endfunction

    function [7:0] name_char;
        input [2:0] row;
        input [1:0] idx;
        begin
            case (row)
                3'd0: begin
                    case (idx)
                        2'd0: name_char = name0_c0;
                        2'd1: name_char = name0_c1;
                        default: name_char = name0_c2;
                    endcase
                end
                3'd1: begin
                    case (idx)
                        2'd0: name_char = name1_c0;
                        2'd1: name_char = name1_c1;
                        default: name_char = name1_c2;
                    endcase
                end
                3'd2: begin
                    case (idx)
                        2'd0: name_char = name2_c0;
                        2'd1: name_char = name2_c1;
                        default: name_char = name2_c2;
                    endcase
                end
                3'd3: begin
                    case (idx)
                        2'd0: name_char = name3_c0;
                        2'd1: name_char = name3_c1;
                        default: name_char = name3_c2;
                    endcase
                end
                default: begin
                    case (idx)
                        2'd0: name_char = name4_c0;
                        2'd1: name_char = name4_c1;
                        default: name_char = name4_c2;
                    endcase
                end
            endcase
        end
    endfunction

    function [7:0] score_char;
        input [2:0] row;
        input [2:0] idx;
        begin
            case (row)
                3'd0: begin
                    case (idx)
                        3'd0: score_char = "0" + s0_th;
                        3'd1: score_char = "0" + s0_hu;
                        3'd2: score_char = "0" + s0_te;
                        default: score_char = "0" + s0_on;
                    endcase
                end
                3'd1: begin
                    case (idx)
                        3'd0: score_char = "0" + s1_th;
                        3'd1: score_char = "0" + s1_hu;
                        3'd2: score_char = "0" + s1_te;
                        default: score_char = "0" + s1_on;
                    endcase
                end
                3'd2: begin
                    case (idx)
                        3'd0: score_char = "0" + s2_th;
                        3'd1: score_char = "0" + s2_hu;
                        3'd2: score_char = "0" + s2_te;
                        default: score_char = "0" + s2_on;
                    endcase
                end
                3'd3: begin
                    case (idx)
                        3'd0: score_char = "0" + s3_th;
                        3'd1: score_char = "0" + s3_hu;
                        3'd2: score_char = "0" + s3_te;
                        default: score_char = "0" + s3_on;
                    endcase
                end
                default: begin
                    case (idx)
                        3'd0: score_char = "0" + s4_th;
                        3'd1: score_char = "0" + s4_hu;
                        3'd2: score_char = "0" + s4_te;
                        default: score_char = "0" + s4_on;
                    endcase
                end
            endcase
        end
    endfunction
    
        function row_valid;
        input [2:0] row;
        begin
            case (row)
                3'd0: row_valid = valid0;
                3'd1: row_valid = valid1;
                3'd2: row_valid = valid2;
                3'd3: row_valid = valid3;
                default: row_valid = valid4;
            endcase
        end
    endfunction

    // -----------------------------
    // Header region: "TOP 5"
    // -----------------------------
    wire [9:0] hx = h_count - HEADER_X;
    wire [9:0] hy = v_count - HEADER_Y;

    wire in_header_text =
        in_scoreboard &&
        (h_count >= HEADER_X) && (v_count >= HEADER_Y) &&
        (hx < (10'd5 * CHAR_W)) && (hy < CHAR_H);

    wire [2:0] h_char_idx = hx[9:4];
    wire [2:0] h_fx       = hx[3:1];
    wire [2:0] h_fy       = hy[3:1];
    wire [7:0] h_ch       = header_char(h_char_idx);
    wire [7:0] h_bits;

    Font_ROM U_FONT_HEADER (
        .clk(pixel_clk),
        .ch(h_ch),
        .row(h_fy),
        .bits(h_bits)
    );

    reg in_header_text_d;
    reg [2:0] h_fx_d;

    always @(posedge pixel_clk) begin
        in_header_text_d <= in_header_text;
        h_fx_d           <= h_fx;
    end

    wire header_bit = h_bits[7 - h_fx_d];

    // -----------------------------
    // Row select
    // -----------------------------
    wire in_row0 = in_scoreboard && (v_count >= ROW0_Y) && (v_count < ROW0_Y + CHAR_H);
    wire in_row1 = in_scoreboard && (v_count >= ROW1_Y) && (v_count < ROW1_Y + CHAR_H);
    wire in_row2 = in_scoreboard && (v_count >= ROW2_Y) && (v_count < ROW2_Y + CHAR_H);
    wire in_row3 = in_scoreboard && (v_count >= ROW3_Y) && (v_count < ROW3_Y + CHAR_H);
    wire in_row4 = in_scoreboard && (v_count >= ROW4_Y) && (v_count < ROW4_Y + CHAR_H);

    wire any_row = in_row0 || in_row1 || in_row2 || in_row3 || in_row4;

    wire [2:0] row_sel =
        in_row0 ? 3'd0 :
        in_row1 ? 3'd1 :
        in_row2 ? 3'd2 :
        in_row3 ? 3'd3 :
                  3'd4;

    wire [9:0] row_base_y =
        in_row0 ? ROW0_Y :
        in_row1 ? ROW1_Y :
        in_row2 ? ROW2_Y :
        in_row3 ? ROW3_Y :
                  ROW4_Y;

    // -----------------------------
    // Rank region
    // -----------------------------
    wire [9:0] rkx = h_count - RANK_X;
    wire [9:0] rky = v_count - row_base_y;

    wire in_rank_text =
    any_row && row_valid(row_sel) &&
        (h_count >= RANK_X) &&
        (rkx < CHAR_W);

    wire [2:0] rank_fx = rkx[3:1];
    wire [2:0] rank_fy = rky[3:1];
    wire [7:0] rank_bits;

    Font_ROM U_FONT_RANK (
        .clk(pixel_clk),
        .ch(rank_char(row_sel)),
        .row(rank_fy),
        .bits(rank_bits)
    );

    reg in_rank_text_d;
    reg [2:0] rank_fx_d;

    always @(posedge pixel_clk) begin
        in_rank_text_d <= in_rank_text;
        rank_fx_d      <= rank_fx;
    end

    wire rank_bit = rank_bits[7 - rank_fx_d];

    // -----------------------------
    // Score region (4 chars)
    // -----------------------------
    wire [9:0] scx = h_count - SCORE_X;
    wire [9:0] scy = v_count - row_base_y;

    wire in_score_text =
    any_row && row_valid(row_sel) &&
        (h_count >= SCORE_X) &&
        (scx < (10'd4 * CHAR_W));

    wire [2:0] score_idx = scx[9:4];
    wire [2:0] score_fx  = scx[3:1];
    wire [2:0] score_fy  = scy[3:1];
    wire [7:0] score_bits;

    Font_ROM U_FONT_SCORE (
        .clk(pixel_clk),
        .ch(score_char(row_sel, score_idx)),
        .row(score_fy),
        .bits(score_bits)
    );

    reg in_score_text_d;
    reg [2:0] score_fx_d;

    always @(posedge pixel_clk) begin
        in_score_text_d <= in_score_text;
        score_fx_d      <= score_fx;
    end

    wire score_bit = score_bits[7 - score_fx_d];

    // -----------------------------
    // Name region (3 chars)
    // -----------------------------
    wire [9:0] nmx = h_count - NAME_X;
    wire [9:0] nmy = v_count - row_base_y;

    wire in_name_text =
    any_row && row_valid(row_sel) &&
        (h_count >= NAME_X) &&
        (nmx < (10'd3 * CHAR_W));

    wire [1:0] name_idx = nmx[9:4];
    wire [2:0] name_fx  = nmx[3:1];
    wire [2:0] name_fy  = nmy[3:1];
    wire [7:0] name_bits;

    Font_ROM U_FONT_NAME (
        .clk(pixel_clk),
        .ch(name_char(row_sel, name_idx)),
        .row(name_fy),
        .bits(name_bits)
    );

    reg in_name_text_d;
    reg [2:0] name_fx_d;

    always @(posedge pixel_clk) begin
        in_name_text_d <= in_name_text;
        name_fx_d      <= name_fx;
    end

    wire name_bit = name_bits[7 - name_fx_d];

    // -----------------------------
    // Output compositor
    // -----------------------------
    always @(*) begin
        ui_on = 1'b0;
        R = 4'h0;
        G = 4'h0;
        B = 4'h0;

        if (in_scoreboard) begin
            if ((in_header_text_d && header_bit) ||
                (in_rank_text_d   && rank_bit)   ||
                (in_score_text_d  && score_bit)  ||
                (in_name_text_d   && name_bit)) begin
                ui_on = 1'b1;
                R = 4'h0;
                G = 4'h0;
                B = 4'h0;
            end
        end
    end

endmodule