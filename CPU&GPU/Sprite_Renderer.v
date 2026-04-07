`timescale 1ns / 1ps

module Sprite_Renderer #(
    parameter [9:0] HALF_BLOCK = 10'd20
)(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       pixel_clk,

    // Background from tile engine
    input  wire [3:0] bgR,
    input  wire [3:0] bgG,
    input  wire [3:0] bgB,

    // UI overlay
    input  wire       ui_on,
    input  wire [3:0] uiR,
    input  wire [3:0] uiG,
    input  wire [3:0] uiB,

    // Objects (center coords)
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    input  wire       blk0_active,
    input  wire [9:0] blk0_x,
    input  wire [9:0] blk0_y,

    input  wire       blk1_active,
    input  wire [9:0] blk1_x,
    input  wire [9:0] blk1_y,

    input  wire       blk2_active,
    input  wire [9:0] blk2_x,
    input  wire [9:0] blk2_y,

    input  wire       blk3_active,
    input  wire [9:0] blk3_x,
    input  wire [9:0] blk3_y,
    input  wire       blk4_active,
    input  wire [9:0] blk4_x,
    input  wire [9:0] blk4_y,

    input  wire       blk5_active,
    input  wire [9:0] blk5_x,
    input  wire [9:0] blk5_y,

    input  wire       blk6_active,
    input  wire [9:0] blk6_x,
    input  wire [9:0] blk6_y,

    input  wire       blk7_active,
    input  wire [9:0] blk7_x,
    input  wire [9:0] blk7_y,

    input  wire       blk8_active,
    input  wire [9:0] blk8_x,
    input  wire [9:0] blk8_y,

    input  wire       blk9_active,
    input  wire [9:0] blk9_x,
    input  wire [9:0] blk9_y,

    input  wire       blk10_active,
    input  wire [9:0] blk10_x,
    input  wire [9:0] blk10_y,

    input  wire       blk11_active,
    input  wire [9:0] blk11_x,
    input  wire [9:0] blk11_y,

    input  wire       blk12_active,
    input  wire [9:0] blk12_x,
    input  wire [9:0] blk12_y,

    input  wire       blk13_active,
    input  wire [9:0] blk13_x,
    input  wire [9:0] blk13_y,

    input  wire       blk14_active,
    input  wire [9:0] blk14_x,
    input  wire [9:0] blk14_y,

    input  wire       blk15_active,
    input  wire [9:0] blk15_x,
    input  wire [9:0] blk15_y,

    input  wire       side_low_active,
    input  wire [9:0] side_low_x,
    input  wire [9:0] side_low_y,
    input  wire       side_low_move_left,

    input  wire       side_high_active,
    input  wire [9:0] side_high_x,
    input  wire [9:0] side_high_y,
    input  wire       side_high_move_left,

    input  wire [9:0] ufo_x,
    input  wire [9:0] ufo_y,

    // Player pose
    input  wire [2:0] pose,

    // Game state
    input  wire       game_over,

    output reg  [3:0] vgaRed,
    output reg  [3:0] vgaGreen,
    output reg  [3:0] vgaBlue
);

    // -------------------------------
    // Visible region
    // -------------------------------
    localparam [9:0] H_VISIBLE = 10'd640;
    localparam [9:0] V_VISIBLE = 10'd480;
    wire visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // =========================================================
    // DOOMGUY SPRITE SHEET
    // 240x64 sheet, 5 frames, each 48x64
    // draw cropped horizontally to remove edge junk
    // transparent key = 12'hF0F
    // =========================================================
    localparam [5:0] DOOM_FRAME_W  = 6'd48;
    localparam [6:0] DOOM_FRAME_H  = 7'd64;

    localparam [5:0] DOOM_CROP_L   = 6'd3;
    localparam [5:0] DOOM_CROP_R   = 6'd3;
    localparam [5:0] DOOM_DRAW_W   = 6'd44;

    localparam [2:0] DOOM_IDLE0   = 3'd0;
    localparam [2:0] DOOM_WALK0   = 3'd1;
    localparam [2:0] DOOM_WALK1   = 3'd2;
    localparam [2:0] DOOM_WALK2   = 3'd3;
    localparam [2:0] DOOM_CROUCH0 = 3'd4;

    reg [2:0] doom_frame;

    // =========================================================
    // Frame-latched player state
    // Freeze player state once per frame to avoid mid-frame tearing/phasing
    // =========================================================
    reg [9:0] player_x_frame;
    reg [9:0] player_y_frame;
    reg [2:0] pose_frame;
    reg       game_over_frame;

    always @(posedge pixel_clk) begin
        if (h_count == 10'd0 && v_count == 10'd0) begin
            player_x_frame  <= player_x;
            player_y_frame  <= player_y;
            pose_frame      <= pose;
            game_over_frame <= game_over;
        end
    end

    always @(*) begin
    if (game_over_frame) begin
        doom_frame = DOOM_CROUCH0;
    end else begin
        case (pose_frame)
            3'b000: doom_frame = DOOM_IDLE0;
            3'b001: doom_frame = DOOM_WALK0;
            3'b010: doom_frame = DOOM_WALK1;
            3'b011: doom_frame = DOOM_WALK2;   // use this as jump for now
            3'b100: doom_frame = DOOM_CROUCH0;
            default: doom_frame = DOOM_IDLE0;
        endcase
    end
end
    wire [10:0] doom_left_tmp = {1'b0, player_x_frame} - (DOOM_DRAW_W >> 1);
    wire [10:0] doom_top_tmp  = {1'b0, player_y_frame} - DOOM_FRAME_H + 10'd20;

    wire [9:0] doom_left = doom_left_tmp[10] ? 10'd0 : doom_left_tmp[9:0];
    wire [9:0] doom_top  = doom_top_tmp[10]  ? 10'd0 : doom_top_tmp[9:0];

    wire doom_box =
        visible &&
        (h_count >= doom_left) && (h_count < doom_left + DOOM_DRAW_W) &&
        (v_count >= doom_top ) && (v_count < doom_top  + DOOM_FRAME_H);

    wire [5:0] doom_local_x = h_count - doom_left;
    wire [6:0] doom_local_y = v_count - doom_top;

    wire [8:0] doom_rom_x = (doom_frame * DOOM_FRAME_W) + DOOM_CROP_L + doom_local_x;
    wire [6:0] doom_rom_y = doom_local_y;

    reg        doom_box_d1;
    reg [8:0]  doom_rom_x_d1;
    reg [6:0]  doom_rom_y_d1;

    always @(posedge pixel_clk) begin
        doom_box_d1   <= doom_box;
        doom_rom_x_d1 <= doom_rom_x;
        doom_rom_y_d1 <= doom_rom_y;
    end

    wire [11:0] doom_rgb_s1;

    DoomGuy_ROM u_doom_rom (
        .clk(pixel_clk),
        .x(doom_rom_x_d1),
        .y(doom_rom_y_d1),
        .rgb(doom_rgb_s1)
    );

    reg        doom_box_d2;
    reg [11:0] doom_rgb_s2;

    always @(posedge pixel_clk) begin
        doom_box_d2 <= doom_box_d1;
        doom_rgb_s2 <= doom_rgb_s1;
    end

    wire doom_visible_pix = (doom_rgb_s2 != 12'hF0F);

    // =========================================================
    // HAZARDS: scale 40x40 hitbox -> 16x16 sprite
    // =========================================================
    localparam [9:0] BOX_W = (HALF_BLOCK << 1);

    localparam [1:0] BILL_DOWN  = 2'b00;
    localparam [1:0] BILL_RIGHT = 2'b01;
    localparam [1:0] BILL_LEFT  = 2'b10;

    // =========================================================
    // Falling block 0
    // =========================================================
    wire block0_on =
        blk0_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk0_x) && (h_count <= blk0_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk0_y) && (v_count <= blk0_y + (HALF_BLOCK - 1));

    wire [9:0] block0_relx = (h_count + HALF_BLOCK) - blk0_x;
    wire [9:0] block0_rely = (v_count + HALF_BLOCK) - blk0_y;

    wire [9:0] block0_rx_tmp = (block0_relx >= BOX_W) ? 10'd15 : ((block0_relx * 10'd16) / BOX_W);
    wire [9:0] block0_ry_tmp = (block0_rely >= BOX_W) ? 10'd15 : ((block0_rely * 10'd16) / BOX_W);
    wire [3:0] block0_rx_s   = block0_rx_tmp[3:0];
    wire [3:0] block0_ry_s   = block0_ry_tmp[3:0];

    reg       block0_on_d;
    reg [3:0] block0_rx_d, block0_ry_d;

    always @(posedge pixel_clk) begin
        block0_on_d <= block0_on;
        block0_rx_d <= block0_rx_s;
        block0_ry_d <= block0_ry_s;
    end

    // =========================================================
    // Falling block 1
    // =========================================================
    wire block1_on =
        blk1_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk1_x) && (h_count <= blk1_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk1_y) && (v_count <= blk1_y + (HALF_BLOCK - 1));

    wire [9:0] block1_relx = (h_count + HALF_BLOCK) - blk1_x;
    wire [9:0] block1_rely = (v_count + HALF_BLOCK) - blk1_y;

    wire [9:0] block1_rx_tmp = (block1_relx >= BOX_W) ? 10'd15 : ((block1_relx * 10'd16) / BOX_W);
    wire [9:0] block1_ry_tmp = (block1_rely >= BOX_W) ? 10'd15 : ((block1_rely * 10'd16) / BOX_W);
    wire [3:0] block1_rx_s   = block1_rx_tmp[3:0];
    wire [3:0] block1_ry_s   = block1_ry_tmp[3:0];

    reg       block1_on_d;
    reg [3:0] block1_rx_d, block1_ry_d;

    always @(posedge pixel_clk) begin
        block1_on_d <= block1_on;
        block1_rx_d <= block1_rx_s;
        block1_ry_d <= block1_ry_s;
    end

    // =========================================================
    // Falling block 2
    // =========================================================
    wire block2_on =
        blk2_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk2_x) && (h_count <= blk2_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk2_y) && (v_count <= blk2_y + (HALF_BLOCK - 1));

    wire [9:0] block2_relx = (h_count + HALF_BLOCK) - blk2_x;
    wire [9:0] block2_rely = (v_count + HALF_BLOCK) - blk2_y;

    wire [9:0] block2_rx_tmp = (block2_relx >= BOX_W) ? 10'd15 : ((block2_relx * 10'd16) / BOX_W);
    wire [9:0] block2_ry_tmp = (block2_rely >= BOX_W) ? 10'd15 : ((block2_rely * 10'd16) / BOX_W);
    wire [3:0] block2_rx_s   = block2_rx_tmp[3:0];
    wire [3:0] block2_ry_s   = block2_ry_tmp[3:0];

    reg       block2_on_d;
    reg [3:0] block2_rx_d, block2_ry_d;

    always @(posedge pixel_clk) begin
        block2_on_d <= block2_on;
        block2_rx_d <= block2_rx_s;
        block2_ry_d <= block2_ry_s;
    end

    // =========================================================
    // Falling block 3
    // =========================================================
    wire block3_on =
        blk3_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk3_x) && (h_count <= blk3_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk3_y) && (v_count <= blk3_y + (HALF_BLOCK - 1));

    wire [9:0] block3_relx = (h_count + HALF_BLOCK) - blk3_x;
    wire [9:0] block3_rely = (v_count + HALF_BLOCK) - blk3_y;

    wire [9:0] block3_rx_tmp = (block3_relx >= BOX_W) ? 10'd15 : ((block3_relx * 10'd16) / BOX_W);
    wire [9:0] block3_ry_tmp = (block3_rely >= BOX_W) ? 10'd15 : ((block3_rely * 10'd16) / BOX_W);
    wire [3:0] block3_rx_s   = block3_rx_tmp[3:0];
    wire [3:0] block3_ry_s   = block3_ry_tmp[3:0];

    reg       block3_on_d;
    reg [3:0] block3_rx_d, block3_ry_d;

    always @(posedge pixel_clk) begin
        block3_on_d <= block3_on;
        block3_rx_d <= block3_rx_s;
        block3_ry_d <= block3_ry_s;
    end

    // =========================================================
    // Falling block 4
    // =========================================================
    wire block4_on =
        blk4_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk4_x) && (h_count <= blk4_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk4_y) && (v_count <= blk4_y + (HALF_BLOCK - 1));

    wire [9:0] block4_relx = (h_count + HALF_BLOCK) - blk4_x;
    wire [9:0] block4_rely = (v_count + HALF_BLOCK) - blk4_y;

    wire [9:0] block4_rx_tmp = (block4_relx >= BOX_W) ? 10'd15 : ((block4_relx * 10'd16) / BOX_W);
    wire [9:0] block4_ry_tmp = (block4_rely >= BOX_W) ? 10'd15 : ((block4_rely * 10'd16) / BOX_W);
    wire [3:0] block4_rx_s   = block4_rx_tmp[3:0];
    wire [3:0] block4_ry_s   = block4_ry_tmp[3:0];

    reg       block4_on_d;
    reg [3:0] block4_rx_d, block4_ry_d;

    always @(posedge pixel_clk) begin
        block4_on_d <= block4_on;
        block4_rx_d <= block4_rx_s;
        block4_ry_d <= block4_ry_s;
    end

    // =========================================================
    // Falling block 5
    // =========================================================
    wire block5_on =
        blk5_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk5_x) && (h_count <= blk5_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk5_y) && (v_count <= blk5_y + (HALF_BLOCK - 1));

    wire [9:0] block5_relx = (h_count + HALF_BLOCK) - blk5_x;
    wire [9:0] block5_rely = (v_count + HALF_BLOCK) - blk5_y;

    wire [9:0] block5_rx_tmp = (block5_relx >= BOX_W) ? 10'd15 : ((block5_relx * 10'd16) / BOX_W);
    wire [9:0] block5_ry_tmp = (block5_rely >= BOX_W) ? 10'd15 : ((block5_rely * 10'd16) / BOX_W);
    wire [3:0] block5_rx_s   = block5_rx_tmp[3:0];
    wire [3:0] block5_ry_s   = block5_ry_tmp[3:0];

    reg       block5_on_d;
    reg [3:0] block5_rx_d, block5_ry_d;

    always @(posedge pixel_clk) begin
        block5_on_d <= block5_on;
        block5_rx_d <= block5_rx_s;
        block5_ry_d <= block5_ry_s;
    end

    // =========================================================
    // Falling block 6
    // =========================================================
    wire block6_on =
        blk6_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk6_x) && (h_count <= blk6_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk6_y) && (v_count <= blk6_y + (HALF_BLOCK - 1));

    wire [9:0] block6_relx = (h_count + HALF_BLOCK) - blk6_x;
    wire [9:0] block6_rely = (v_count + HALF_BLOCK) - blk6_y;

    wire [9:0] block6_rx_tmp = (block6_relx >= BOX_W) ? 10'd15 : ((block6_relx * 10'd16) / BOX_W);
    wire [9:0] block6_ry_tmp = (block6_rely >= BOX_W) ? 10'd15 : ((block6_rely * 10'd16) / BOX_W);
    wire [3:0] block6_rx_s   = block6_rx_tmp[3:0];
    wire [3:0] block6_ry_s   = block6_ry_tmp[3:0];

    reg       block6_on_d;
    reg [3:0] block6_rx_d, block6_ry_d;

    always @(posedge pixel_clk) begin
        block6_on_d <= block6_on;
        block6_rx_d <= block6_rx_s;
        block6_ry_d <= block6_ry_s;
    end

    // =========================================================
    // Falling block 7
    // =========================================================
    wire block7_on =
        blk7_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk7_x) && (h_count <= blk7_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk7_y) && (v_count <= blk7_y + (HALF_BLOCK - 1));

    wire [9:0] block7_relx = (h_count + HALF_BLOCK) - blk7_x;
    wire [9:0] block7_rely = (v_count + HALF_BLOCK) - blk7_y;

    wire [9:0] block7_rx_tmp = (block7_relx >= BOX_W) ? 10'd15 : ((block7_relx * 10'd16) / BOX_W);
    wire [9:0] block7_ry_tmp = (block7_rely >= BOX_W) ? 10'd15 : ((block7_rely * 10'd16) / BOX_W);
    wire [3:0] block7_rx_s   = block7_rx_tmp[3:0];
    wire [3:0] block7_ry_s   = block7_ry_tmp[3:0];

    reg       block7_on_d;
    reg [3:0] block7_rx_d, block7_ry_d;

    always @(posedge pixel_clk) begin
        block7_on_d <= block7_on;
        block7_rx_d <= block7_rx_s;
        block7_ry_d <= block7_ry_s;
    end

    // =========================================================
    // Falling block 8
    // =========================================================
    wire block8_on =
        blk8_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk8_x) && (h_count <= blk8_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk8_y) && (v_count <= blk8_y + (HALF_BLOCK - 1));

    wire [9:0] block8_relx = (h_count + HALF_BLOCK) - blk8_x;
    wire [9:0] block8_rely = (v_count + HALF_BLOCK) - blk8_y;

    wire [9:0] block8_rx_tmp = (block8_relx >= BOX_W) ? 10'd15 : ((block8_relx * 10'd16) / BOX_W);
    wire [9:0] block8_ry_tmp = (block8_rely >= BOX_W) ? 10'd15 : ((block8_rely * 10'd16) / BOX_W);
    wire [3:0] block8_rx_s   = block8_rx_tmp[3:0];
    wire [3:0] block8_ry_s   = block8_ry_tmp[3:0];

    reg       block8_on_d;
    reg [3:0] block8_rx_d, block8_ry_d;

    always @(posedge pixel_clk) begin
        block8_on_d <= block8_on;
        block8_rx_d <= block8_rx_s;
        block8_ry_d <= block8_ry_s;
    end

    // =========================================================
    // Falling block 9
    // =========================================================
    wire block9_on =
        blk9_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk9_x) && (h_count <= blk9_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk9_y) && (v_count <= blk9_y + (HALF_BLOCK - 1));

    wire [9:0] block9_relx = (h_count + HALF_BLOCK) - blk9_x;
    wire [9:0] block9_rely = (v_count + HALF_BLOCK) - blk9_y;

    wire [9:0] block9_rx_tmp = (block9_relx >= BOX_W) ? 10'd15 : ((block9_relx * 10'd16) / BOX_W);
    wire [9:0] block9_ry_tmp = (block9_rely >= BOX_W) ? 10'd15 : ((block9_rely * 10'd16) / BOX_W);
    wire [3:0] block9_rx_s   = block9_rx_tmp[3:0];
    wire [3:0] block9_ry_s   = block9_ry_tmp[3:0];

    reg       block9_on_d;
    reg [3:0] block9_rx_d, block9_ry_d;

    always @(posedge pixel_clk) begin
        block9_on_d <= block9_on;
        block9_rx_d <= block9_rx_s;
        block9_ry_d <= block9_ry_s;
    end

    // =========================================================
    // Falling block 10
    // =========================================================
    wire block10_on =
        blk10_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk10_x) && (h_count <= blk10_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk10_y) && (v_count <= blk10_y + (HALF_BLOCK - 1));

    wire [9:0] block10_relx = (h_count + HALF_BLOCK) - blk10_x;
    wire [9:0] block10_rely = (v_count + HALF_BLOCK) - blk10_y;

    wire [9:0] block10_rx_tmp = (block10_relx >= BOX_W) ? 10'd15 : ((block10_relx * 10'd16) / BOX_W);
    wire [9:0] block10_ry_tmp = (block10_rely >= BOX_W) ? 10'd15 : ((block10_rely * 10'd16) / BOX_W);
    wire [3:0] block10_rx_s   = block10_rx_tmp[3:0];
    wire [3:0] block10_ry_s   = block10_ry_tmp[3:0];

    reg       block10_on_d;
    reg [3:0] block10_rx_d, block10_ry_d;

    always @(posedge pixel_clk) begin
        block10_on_d <= block10_on;
        block10_rx_d <= block10_rx_s;
        block10_ry_d <= block10_ry_s;
    end

    // =========================================================
    // Falling block 11
    // =========================================================
    wire block11_on =
        blk11_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk11_x) && (h_count <= blk11_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk11_y) && (v_count <= blk11_y + (HALF_BLOCK - 1));

    wire [9:0] block11_relx = (h_count + HALF_BLOCK) - blk11_x;
    wire [9:0] block11_rely = (v_count + HALF_BLOCK) - blk11_y;

    wire [9:0] block11_rx_tmp = (block11_relx >= BOX_W) ? 10'd15 : ((block11_relx * 10'd16) / BOX_W);
    wire [9:0] block11_ry_tmp = (block11_rely >= BOX_W) ? 10'd15 : ((block11_rely * 10'd16) / BOX_W);
    wire [3:0] block11_rx_s   = block11_rx_tmp[3:0];
    wire [3:0] block11_ry_s   = block11_ry_tmp[3:0];

    reg       block11_on_d;
    reg [3:0] block11_rx_d, block11_ry_d;

    always @(posedge pixel_clk) begin
        block11_on_d <= block11_on;
        block11_rx_d <= block11_rx_s;
        block11_ry_d <= block11_ry_s;
    end

    // =========================================================
    // Falling block 12
    // =========================================================
    wire block12_on =
        blk12_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk12_x) && (h_count <= blk12_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk12_y) && (v_count <= blk12_y + (HALF_BLOCK - 1));

    wire [9:0] block12_relx = (h_count + HALF_BLOCK) - blk12_x;
    wire [9:0] block12_rely = (v_count + HALF_BLOCK) - blk12_y;

    wire [9:0] block12_rx_tmp = (block12_relx >= BOX_W) ? 10'd15 : ((block12_relx * 10'd16) / BOX_W);
    wire [9:0] block12_ry_tmp = (block12_rely >= BOX_W) ? 10'd15 : ((block12_rely * 10'd16) / BOX_W);
    wire [3:0] block12_rx_s   = block12_rx_tmp[3:0];
    wire [3:0] block12_ry_s   = block12_ry_tmp[3:0];

    reg       block12_on_d;
    reg [3:0] block12_rx_d, block12_ry_d;

    always @(posedge pixel_clk) begin
        block12_on_d <= block12_on;
        block12_rx_d <= block12_rx_s;
        block12_ry_d <= block12_ry_s;
    end

    // =========================================================
    // Falling block 13
    // =========================================================
    wire block13_on =
        blk13_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk13_x) && (h_count <= blk13_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk13_y) && (v_count <= blk13_y + (HALF_BLOCK - 1));

    wire [9:0] block13_relx = (h_count + HALF_BLOCK) - blk13_x;
    wire [9:0] block13_rely = (v_count + HALF_BLOCK) - blk13_y;

    wire [9:0] block13_rx_tmp = (block13_relx >= BOX_W) ? 10'd15 : ((block13_relx * 10'd16) / BOX_W);
    wire [9:0] block13_ry_tmp = (block13_rely >= BOX_W) ? 10'd15 : ((block13_rely * 10'd16) / BOX_W);
    wire [3:0] block13_rx_s   = block13_rx_tmp[3:0];
    wire [3:0] block13_ry_s   = block13_ry_tmp[3:0];

    reg       block13_on_d;
    reg [3:0] block13_rx_d, block13_ry_d;

    always @(posedge pixel_clk) begin
        block13_on_d <= block13_on;
        block13_rx_d <= block13_rx_s;
        block13_ry_d <= block13_ry_s;
    end

    // =========================================================
    // Falling block 14
    // =========================================================
    wire block14_on =
        blk14_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk14_x) && (h_count <= blk14_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk14_y) && (v_count <= blk14_y + (HALF_BLOCK - 1));

    wire [9:0] block14_relx = (h_count + HALF_BLOCK) - blk14_x;
    wire [9:0] block14_rely = (v_count + HALF_BLOCK) - blk14_y;

    wire [9:0] block14_rx_tmp = (block14_relx >= BOX_W) ? 10'd15 : ((block14_relx * 10'd16) / BOX_W);
    wire [9:0] block14_ry_tmp = (block14_rely >= BOX_W) ? 10'd15 : ((block14_rely * 10'd16) / BOX_W);
    wire [3:0] block14_rx_s   = block14_rx_tmp[3:0];
    wire [3:0] block14_ry_s   = block14_ry_tmp[3:0];

    reg       block14_on_d;
    reg [3:0] block14_rx_d, block14_ry_d;

    always @(posedge pixel_clk) begin
        block14_on_d <= block14_on;
        block14_rx_d <= block14_rx_s;
        block14_ry_d <= block14_ry_s;
    end

    // =========================================================
    // Falling block 15
    // =========================================================
    wire block15_on =
        blk15_active &&
        visible &&
        (h_count + HALF_BLOCK >= blk15_x) && (h_count <= blk15_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= blk15_y) && (v_count <= blk15_y + (HALF_BLOCK - 1));

    wire [9:0] block15_relx = (h_count + HALF_BLOCK) - blk15_x;
    wire [9:0] block15_rely = (v_count + HALF_BLOCK) - blk15_y;

    wire [9:0] block15_rx_tmp = (block15_relx >= BOX_W) ? 10'd15 : ((block15_relx * 10'd16) / BOX_W);
    wire [9:0] block15_ry_tmp = (block15_rely >= BOX_W) ? 10'd15 : ((block15_rely * 10'd16) / BOX_W);
    wire [3:0] block15_rx_s   = block15_rx_tmp[3:0];
    wire [3:0] block15_ry_s   = block15_ry_tmp[3:0];

    reg       block15_on_d;
    reg [3:0] block15_rx_d, block15_ry_d;

    always @(posedge pixel_clk) begin
        block15_on_d <= block15_on;
        block15_rx_d <= block15_rx_s;
        block15_ry_d <= block15_ry_s;
    end

    // =========================================================
    // Bullet Bill frame select
    // =========================================================
    wire [1:0] block0_dir = BILL_DOWN;
    wire [1:0] block1_dir = BILL_DOWN;
    wire [1:0] block2_dir = BILL_DOWN;
    wire [1:0] block3_dir = BILL_DOWN;
    wire [1:0] block4_dir = BILL_DOWN;
    wire [1:0] block5_dir = BILL_DOWN;
    wire [1:0] block6_dir = BILL_DOWN;
    wire [1:0] block7_dir = BILL_DOWN;
    wire [1:0] block8_dir = BILL_DOWN;
    wire [1:0] block9_dir = BILL_DOWN;
    wire [1:0] block10_dir = BILL_DOWN;
    wire [1:0] block11_dir = BILL_DOWN;
    wire [1:0] block12_dir = BILL_DOWN;
    wire [1:0] block13_dir = BILL_DOWN;
    wire [1:0] block14_dir = BILL_DOWN;
    wire [1:0] block15_dir = BILL_DOWN;

    wire [5:0] block0_frame_x = (block0_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block0_rx_d}) :
                                (block0_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block0_rx_d}) :
                                                              (6'd16 + {2'b00, block0_rx_d});

    wire [5:0] block1_frame_x = (block1_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block1_rx_d}) :
                                (block1_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block1_rx_d}) :
                                                              (6'd16 + {2'b00, block1_rx_d});

    wire [5:0] block2_frame_x = (block2_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block2_rx_d}) :
                                (block2_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block2_rx_d}) :
                                                              (6'd16 + {2'b00, block2_rx_d});

    wire [5:0] block3_frame_x = (block3_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block3_rx_d}) :
                                (block3_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block3_rx_d}) :
                                                              (6'd16 + {2'b00, block3_rx_d});

    wire [5:0] block4_frame_x = (block4_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block4_rx_d}) :
                                (block4_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block4_rx_d}) :
                                                              (6'd16 + {2'b00, block4_rx_d});

    wire [5:0] block5_frame_x = (block5_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block5_rx_d}) :
                                (block5_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block5_rx_d}) :
                                                              (6'd16 + {2'b00, block5_rx_d});

    wire [5:0] block6_frame_x = (block6_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block6_rx_d}) :
                                (block6_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block6_rx_d}) :
                                                              (6'd16 + {2'b00, block6_rx_d});

    wire [5:0] block7_frame_x = (block7_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block7_rx_d}) :
                                (block7_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block7_rx_d}) :
                                                              (6'd16 + {2'b00, block7_rx_d});

    wire [5:0] block8_frame_x = (block8_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block8_rx_d}) :
                                (block8_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block8_rx_d}) :
                                                              (6'd16 + {2'b00, block8_rx_d});
    wire [5:0] block9_frame_x = (block9_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block9_rx_d}) :
                                (block9_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block9_rx_d}) :
                                                              (6'd16 + {2'b00, block9_rx_d});
    wire [5:0] block10_frame_x = (block10_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block10_rx_d}) :
                                (block10_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block10_rx_d}) :
                                                              (6'd16 + {2'b00, block10_rx_d});
    wire [5:0] block11_frame_x = (block11_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block11_rx_d}) :
                                (block11_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block11_rx_d}) :
                                                              (6'd16 + {2'b00, block11_rx_d});
    wire [5:0] block12_frame_x = (block12_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block12_rx_d}) :
                                (block12_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block12_rx_d}) :
                                                              (6'd16 + {2'b00, block12_rx_d});
    wire [5:0] block13_frame_x = (block13_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block13_rx_d}) :
                                (block13_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block13_rx_d}) :
                                                              (6'd16 + {2'b00, block13_rx_d});
    wire [5:0] block14_frame_x = (block14_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block14_rx_d}) :
                                (block14_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block14_rx_d}) :
                                                              (6'd16 + {2'b00, block14_rx_d});
    wire [5:0] block15_frame_x = (block15_dir == BILL_DOWN ) ? (6'd0  + {2'b00, block15_rx_d}) :
                                (block15_dir == BILL_RIGHT) ? (6'd32 + {2'b00, block15_rx_d}) :
                                                              (6'd16 + {2'b00, block15_rx_d});

    wire [11:0] block0_rgb_s1, block1_rgb_s1, block2_rgb_s1, block3_rgb_s1;
    wire [11:0] block4_rgb_s1, block5_rgb_s1, block6_rgb_s1, block7_rgb_s1;
    wire [11:0] block8_rgb_s1, block9_rgb_s1, block10_rgb_s1, block11_rgb_s1;
    wire [11:0] block12_rgb_s1, block13_rgb_s1, block14_rgb_s1, block15_rgb_s1;

    BILL u_bill0 (
        .clk(pixel_clk),
        .x(block0_frame_x),
        .y(block0_ry_d),
        .rgb(block0_rgb_s1)
    );

    BILL u_bill1 (
        .clk(pixel_clk),
        .x(block1_frame_x),
        .y(block1_ry_d),
        .rgb(block1_rgb_s1)
    );

    BILL u_bill2 (
        .clk(pixel_clk),
        .x(block2_frame_x),
        .y(block2_ry_d),
        .rgb(block2_rgb_s1)
    );

    BILL u_bill3 (
        .clk(pixel_clk),
        .x(block3_frame_x),
        .y(block3_ry_d),
        .rgb(block3_rgb_s1)
    );

    BILL u_bill4 (
        .clk(pixel_clk),
        .x(block4_frame_x),
        .y(block4_ry_d),
        .rgb(block4_rgb_s1)
    );

    BILL u_bill5 (
        .clk(pixel_clk),
        .x(block5_frame_x),
        .y(block5_ry_d),
        .rgb(block5_rgb_s1)
    );

    BILL u_bill6 (
        .clk(pixel_clk),
        .x(block6_frame_x),
        .y(block6_ry_d),
        .rgb(block6_rgb_s1)
    );

    BILL u_bill7 (
        .clk(pixel_clk),
        .x(block7_frame_x),
        .y(block7_ry_d),
        .rgb(block7_rgb_s1)
    );

    BILL u_bill8 (
        .clk(pixel_clk),
        .x(block8_frame_x),
        .y(block8_ry_d),
        .rgb(block8_rgb_s1)
    );

    BILL u_bill9 (
        .clk(pixel_clk),
        .x(block9_frame_x),
        .y(block9_ry_d),
        .rgb(block9_rgb_s1)
    );

    BILL u_bill10 (
        .clk(pixel_clk),
        .x(block10_frame_x),
        .y(block10_ry_d),
        .rgb(block10_rgb_s1)
    );

    BILL u_bill11 (
        .clk(pixel_clk),
        .x(block11_frame_x),
        .y(block11_ry_d),
        .rgb(block11_rgb_s1)
    );

    BILL u_bill12 (
        .clk(pixel_clk),
        .x(block12_frame_x),
        .y(block12_ry_d),
        .rgb(block12_rgb_s1)
    );

    BILL u_bill13 (
        .clk(pixel_clk),
        .x(block13_frame_x),
        .y(block13_ry_d),
        .rgb(block13_rgb_s1)
    );

    BILL u_bill14 (
        .clk(pixel_clk),
        .x(block14_frame_x),
        .y(block14_ry_d),
        .rgb(block14_rgb_s1)
    );

    BILL u_bill15 (
        .clk(pixel_clk),
        .x(block15_frame_x),
        .y(block15_ry_d),
        .rgb(block15_rgb_s1)
    );

    reg        block0_on_d2, block1_on_d2, block2_on_d2, block3_on_d2;
    reg        block4_on_d2, block5_on_d2, block6_on_d2, block7_on_d2;
    reg        block8_on_d2, block9_on_d2, block10_on_d2, block11_on_d2;
    reg        block12_on_d2, block13_on_d2, block14_on_d2, block15_on_d2;
    reg [11:0] block0_rgb_s2, block1_rgb_s2, block2_rgb_s2, block3_rgb_s2;
    reg [11:0] block4_rgb_s2, block5_rgb_s2, block6_rgb_s2, block7_rgb_s2;
    reg [11:0] block8_rgb_s2, block9_rgb_s2, block10_rgb_s2, block11_rgb_s2;
    reg [11:0] block12_rgb_s2, block13_rgb_s2, block14_rgb_s2, block15_rgb_s2;

    always @(posedge pixel_clk) begin
        block0_on_d2  <= block0_on_d;
        block1_on_d2  <= block1_on_d;
        block2_on_d2  <= block2_on_d;
        block3_on_d2  <= block3_on_d;
        block4_on_d2  <= block4_on_d;
        block5_on_d2  <= block5_on_d;
        block6_on_d2  <= block6_on_d;
        block7_on_d2  <= block7_on_d;
        block8_on_d2  <= block8_on_d;
        block9_on_d2  <= block9_on_d;
        block10_on_d2 <= block10_on_d;
        block11_on_d2 <= block11_on_d;
        block12_on_d2 <= block12_on_d;
        block13_on_d2 <= block13_on_d;
        block14_on_d2 <= block14_on_d;
        block15_on_d2 <= block15_on_d;

        block0_rgb_s2 <= block0_rgb_s1;
        block1_rgb_s2 <= block1_rgb_s1;
        block2_rgb_s2 <= block2_rgb_s1;
        block3_rgb_s2 <= block3_rgb_s1;
        block4_rgb_s2 <= block4_rgb_s1;
        block5_rgb_s2 <= block5_rgb_s1;
        block6_rgb_s2 <= block6_rgb_s1;
        block7_rgb_s2 <= block7_rgb_s1;
        block8_rgb_s2 <= block8_rgb_s1;
        block9_rgb_s2 <= block9_rgb_s1;
        block10_rgb_s2 <= block10_rgb_s1;
        block11_rgb_s2 <= block11_rgb_s1;
        block12_rgb_s2 <= block12_rgb_s1;
        block13_rgb_s2 <= block13_rgb_s1;
        block14_rgb_s2 <= block14_rgb_s1;
        block15_rgb_s2 <= block15_rgb_s1;
    end

    wire block0_visible_pix = (block0_rgb_s2 != 12'hF0F);
    wire block1_visible_pix = (block1_rgb_s2 != 12'hF0F);
    wire block2_visible_pix = (block2_rgb_s2 != 12'hF0F);
    wire block3_visible_pix = (block3_rgb_s2 != 12'hF0F);
    wire block4_visible_pix = (block4_rgb_s2 != 12'hF0F);
    wire block5_visible_pix = (block5_rgb_s2 != 12'hF0F);
    wire block6_visible_pix = (block6_rgb_s2 != 12'hF0F);
    wire block7_visible_pix = (block7_rgb_s2 != 12'hF0F);
    wire block8_visible_pix = (block8_rgb_s2 != 12'hF0F);
    wire block9_visible_pix = (block9_rgb_s2 != 12'hF0F);
    wire block10_visible_pix = (block10_rgb_s2 != 12'hF0F);
    wire block11_visible_pix = (block11_rgb_s2 != 12'hF0F);
    wire block12_visible_pix = (block12_rgb_s2 != 12'hF0F);
    wire block13_visible_pix = (block13_rgb_s2 != 12'hF0F);
    wire block14_visible_pix = (block14_rgb_s2 != 12'hF0F);
    wire block15_visible_pix = (block15_rgb_s2 != 12'hF0F);

    // -------------------------
    // Side LOW block region
    // -------------------------
    wire side_low_on =
        side_low_active &&
        visible &&
        (h_count + HALF_BLOCK >= side_low_x) && (h_count <= side_low_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= side_low_y) && (v_count <= side_low_y + (HALF_BLOCK - 1));

    wire [9:0] side_low_relx = (h_count + HALF_BLOCK) - side_low_x;
    wire [9:0] side_low_rely = (v_count + HALF_BLOCK) - side_low_y;

    wire [9:0] side_low_rx_tmp = (side_low_relx >= BOX_W) ? 10'd15 : ((side_low_relx * 10'd16) / BOX_W);
    wire [9:0] side_low_ry_tmp = (side_low_rely >= BOX_W) ? 10'd15 : ((side_low_rely * 10'd16) / BOX_W);
    wire [3:0] side_low_rx_s   = side_low_rx_tmp[3:0];
    wire [3:0] side_low_ry_s   = side_low_ry_tmp[3:0];

    reg       side_low_on_d;
    reg [3:0] side_low_rx_d, side_low_ry_d;

    always @(posedge pixel_clk) begin
        side_low_on_d <= side_low_on;
        side_low_rx_d <= side_low_rx_s;
        side_low_ry_d <= side_low_ry_s;
    end

    wire [1:0] side_low_dir = side_low_move_left ? BILL_LEFT : BILL_RIGHT;

    wire [5:0] side_low_frame_x =
        (side_low_dir == BILL_DOWN ) ? (6'd0  + {2'b00, side_low_rx_d}) :
        (side_low_dir == BILL_RIGHT) ? (6'd16 + {2'b00, side_low_rx_d}) :
                                       (6'd32 + {2'b00, side_low_rx_d});

    wire [11:0] side_low_rgb_s1;

    BILL u_side_low_bill (
        .clk(pixel_clk),
        .x(side_low_frame_x),
        .y(side_low_ry_d),
        .rgb(side_low_rgb_s1)
    );

    reg        side_low_on_d2;
    reg [11:0] side_low_rgb_s2;

    always @(posedge pixel_clk) begin
        side_low_on_d2  <= side_low_on_d;
        side_low_rgb_s2 <= side_low_rgb_s1;
    end

    wire side_low_visible_pix = (side_low_rgb_s2 != 12'hF0F);

    // -------------------------
    // Side HIGH block region
    // -------------------------
    wire side_high_on =
        side_high_active &&
        visible &&
        (h_count + HALF_BLOCK >= side_high_x) && (h_count <= side_high_x + (HALF_BLOCK - 1)) &&
        (v_count + HALF_BLOCK >= side_high_y) && (v_count <= side_high_y + (HALF_BLOCK - 1));

    wire [9:0] side_high_relx = (h_count + HALF_BLOCK) - side_high_x;
    wire [9:0] side_high_rely = (v_count + HALF_BLOCK) - side_high_y;

    wire [9:0] side_high_rx_tmp = (side_high_relx >= BOX_W) ? 10'd15 : ((side_high_relx * 10'd16) / BOX_W);
    wire [9:0] side_high_ry_tmp = (side_high_rely >= BOX_W) ? 10'd15 : ((side_high_rely * 10'd16) / BOX_W);
    wire [3:0] side_high_rx_s   = side_high_rx_tmp[3:0];
    wire [3:0] side_high_ry_s   = side_high_ry_tmp[3:0];

    reg       side_high_on_d;
    reg [3:0] side_high_rx_d, side_high_ry_d;

    always @(posedge pixel_clk) begin
        side_high_on_d <= side_high_on;
        side_high_rx_d <= side_high_rx_s;
        side_high_ry_d <= side_high_ry_s;
    end

    wire [1:0] side_high_dir = side_high_move_left ? BILL_LEFT : BILL_RIGHT;

    wire [5:0] side_high_frame_x =
        (side_high_dir == BILL_DOWN ) ? (6'd0  + {2'b00, side_high_rx_d}) :
        (side_high_dir == BILL_RIGHT) ? (6'd16 + {2'b00, side_high_rx_d}) :
                                        (6'd32 + {2'b00, side_high_rx_d});

    wire [11:0] side_high_rgb_s1;

    BILL u_side_high_bill (
        .clk(pixel_clk),
        .x(side_high_frame_x),
        .y(side_high_ry_d),
        .rgb(side_high_rgb_s1)
    );

    reg        side_high_on_d2;
    reg [11:0] side_high_rgb_s2;

    always @(posedge pixel_clk) begin
        side_high_on_d2  <= side_high_on_d;
        side_high_rgb_s2 <= side_high_rgb_s1;
    end

    wire side_high_visible_pix = (side_high_rgb_s2 != 12'hF0F);

    // =========================================================
    // TERRARIA-STYLE GROUND
    // =========================================================
    localparam [9:0] HORIZON_Y = 10'd445;
    localparam [9:0] GRASS_H   = 10'd3;

    wire ground_on = visible && (v_count >= HORIZON_Y);
    wire grass_on  = ground_on && (v_count < (HORIZON_Y + GRASS_H));

    wire [3:0] noise = (h_count[3:0] ^ v_count[3:0] ^ h_count[7:4]);

    localparam [11:0] GRASS_MAIN = 12'h29F;
    localparam [11:0] GRASS_DARK = 12'h17C;
    localparam [11:0] GRASS_LITE = 12'h3BF;

    localparam [11:0] DIRT_MAIN  = 12'h742;
    localparam [11:0] DIRT_DARK  = 12'h521;
    localparam [11:0] DIRT_LITE  = 12'h963;

    reg [11:0] ground_rgb;
    always @(*) begin
        ground_rgb = 12'h000;

        if (grass_on) begin
            if (noise == 4'h0 || noise == 4'h7) ground_rgb = GRASS_DARK;
            else if (noise == 4'hF)             ground_rgb = GRASS_LITE;
            else                                ground_rgb = GRASS_MAIN;
        end
        else if (ground_on) begin
            if (noise == 4'h1 || noise == 4'h9) ground_rgb = DIRT_DARK;
            else if (noise == 4'hE)             ground_rgb = DIRT_LITE;
            else                                ground_rgb = DIRT_MAIN;
        end
    end

    wire [3:0] gR = ground_rgb[11:8];
    wire [3:0] gG = ground_rgb[7:4];
    wire [3:0] gB = ground_rgb[3:0];

    // =========================================================
    // UFO SPRITE - cropped draw region from 128x64 RGB444 ROM
    // scaled 2x on screen
    // ufo_x / ufo_y are CENTER coordinates
    // Transparent key color = 12'hF0F
    // =========================================================
    localparam [6:0] UFO_CROP_X = 7'd8;
    localparam [5:0] UFO_CROP_Y = 6'd0;
    localparam [6:0] UFO_SRC_W  = 7'd112;
    localparam [5:0] UFO_SRC_H  = 6'd64;

    localparam [7:0] UFO_DRAW_W = 8'd224;
    localparam [7:0] UFO_DRAW_H = 8'd128;

    wire [10:0] ufo_left_tmp = {1'b0, ufo_x} - (UFO_DRAW_W >> 1);
    wire [10:0] ufo_top_tmp  = {1'b0, ufo_y} - (UFO_DRAW_H >> 1);

    wire [9:0] ufo_left = ufo_left_tmp[10] ? 10'd0 : ufo_left_tmp[9:0];
    wire [9:0] ufo_top  = ufo_top_tmp[10]  ? 10'd0 : ufo_top_tmp[9:0];

    wire ufo_box =
        visible &&
        (h_count >= ufo_left) && (h_count < ufo_left + UFO_DRAW_W) &&
        (v_count >= ufo_top)  && (v_count < ufo_top + UFO_DRAW_H);

    wire [7:0] ufo_local_x = h_count - ufo_left;
    wire [7:0] ufo_local_y = v_count - ufo_top;

    wire [6:0] ufo_rx = UFO_CROP_X + ufo_local_x[7:1];
    wire [5:0] ufo_ry = UFO_CROP_Y + ufo_local_y[6:1];

    reg       ufo_box_d1;
    reg [6:0] ufo_rx_d1;
    reg [5:0] ufo_ry_d1;

    always @(posedge pixel_clk) begin
        ufo_box_d1 <= ufo_box;
        ufo_rx_d1  <= ufo_rx;
        ufo_ry_d1  <= ufo_ry;
    end

    wire [11:0] ufo_rgb_s1;
    UFO_ROM_64x32_4BPP u_ufo_rom (
        .clk(pixel_clk),
        .x(ufo_rx_d1),
        .y(ufo_ry_d1),
        .rgb(ufo_rgb_s1)
    );

    reg        ufo_box_d2;
    reg [11:0] ufo_rgb_s2;

    always @(posedge pixel_clk) begin
        ufo_box_d2 <= ufo_box_d1;
        ufo_rgb_s2 <= ufo_rgb_s1;
    end

    wire ufo_visible_pix;
    assign ufo_visible_pix = (ufo_rgb_s2 != 12'hF0F);

    // =========================================================
    // FINAL COMPOSITOR
    // UI > player > hazards > UFO > ground > background
    // =========================================================
    always @(*) begin
        vgaRed   = 4'h0;
        vgaGreen = 4'h0;
        vgaBlue  = 4'h0;

        if (visible) begin
            vgaRed   = bgR;
            vgaGreen = bgG;
            vgaBlue  = bgB;

            if (ground_on) begin
                vgaRed   = gR;
                vgaGreen = gG;
                vgaBlue  = gB;
            end

            if (ufo_box_d2 && ufo_visible_pix) begin
                vgaRed   = ufo_rgb_s2[11:8];
                vgaGreen = ufo_rgb_s2[7:4];
                vgaBlue  = ufo_rgb_s2[3:0];
            end
            if (block0_on_d2 && block0_visible_pix) begin
                vgaRed   = block0_rgb_s2[11:8];
                vgaGreen = block0_rgb_s2[7:4];
                vgaBlue  = block0_rgb_s2[3:0];
            end
            if (block1_on_d2 && block1_visible_pix) begin
                vgaRed   = block1_rgb_s2[11:8];
                vgaGreen = block1_rgb_s2[7:4];
                vgaBlue  = block1_rgb_s2[3:0];
            end
            if (block2_on_d2 && block2_visible_pix) begin
                vgaRed   = block2_rgb_s2[11:8];
                vgaGreen = block2_rgb_s2[7:4];
                vgaBlue  = block2_rgb_s2[3:0];
            end
            if (block3_on_d2 && block3_visible_pix) begin
                vgaRed   = block3_rgb_s2[11:8];
                vgaGreen = block3_rgb_s2[7:4];
                vgaBlue  = block3_rgb_s2[3:0];
            end
            if (block4_on_d2 && block4_visible_pix) begin
                vgaRed   = block4_rgb_s2[11:8];
                vgaGreen = block4_rgb_s2[7:4];
                vgaBlue  = block4_rgb_s2[3:0];
            end
            if (block5_on_d2 && block5_visible_pix) begin
                vgaRed   = block5_rgb_s2[11:8];
                vgaGreen = block5_rgb_s2[7:4];
                vgaBlue  = block5_rgb_s2[3:0];
            end
            if (block6_on_d2 && block6_visible_pix) begin
                vgaRed   = block6_rgb_s2[11:8];
                vgaGreen = block6_rgb_s2[7:4];
                vgaBlue  = block6_rgb_s2[3:0];
            end
            if (block7_on_d2 && block7_visible_pix) begin
                vgaRed   = block7_rgb_s2[11:8];
                vgaGreen = block7_rgb_s2[7:4];
                vgaBlue  = block7_rgb_s2[3:0];
            end
            if (block8_on_d2 && block8_visible_pix) begin
                vgaRed   = block8_rgb_s2[11:8];
                vgaGreen = block8_rgb_s2[7:4];
                vgaBlue  = block8_rgb_s2[3:0];
            end
            if (block9_on_d2 && block9_visible_pix) begin
                vgaRed   = block9_rgb_s2[11:8];
                vgaGreen = block9_rgb_s2[7:4];
                vgaBlue  = block9_rgb_s2[3:0];
            end
            if (block10_on_d2 && block10_visible_pix) begin
                vgaRed   = block10_rgb_s2[11:8];
                vgaGreen = block10_rgb_s2[7:4];
                vgaBlue  = block10_rgb_s2[3:0];
            end
            if (block11_on_d2 && block11_visible_pix) begin
                vgaRed   = block11_rgb_s2[11:8];
                vgaGreen = block11_rgb_s2[7:4];
                vgaBlue  = block11_rgb_s2[3:0];
            end
            if (block12_on_d2 && block12_visible_pix) begin
                vgaRed   = block12_rgb_s2[11:8];
                vgaGreen = block12_rgb_s2[7:4];
                vgaBlue  = block12_rgb_s2[3:0];
            end
            if (block13_on_d2 && block13_visible_pix) begin
                vgaRed   = block13_rgb_s2[11:8];
                vgaGreen = block13_rgb_s2[7:4];
                vgaBlue  = block13_rgb_s2[3:0];
            end
            if (block14_on_d2 && block14_visible_pix) begin
                vgaRed   = block14_rgb_s2[11:8];
                vgaGreen = block14_rgb_s2[7:4];
                vgaBlue  = block14_rgb_s2[3:0];
            end
            if (block15_on_d2 && block15_visible_pix) begin
                vgaRed   = block15_rgb_s2[11:8];
                vgaGreen = block15_rgb_s2[7:4];
                vgaBlue  = block15_rgb_s2[3:0];
            end
            else if (side_low_on_d2 && side_low_visible_pix) begin
                vgaRed   = side_low_rgb_s2[11:8];
                vgaGreen = side_low_rgb_s2[7:4];
                vgaBlue  = side_low_rgb_s2[3:0];
            end
            else if (side_high_on_d2 && side_high_visible_pix) begin
                vgaRed   = side_high_rgb_s2[11:8];
                vgaGreen = side_high_rgb_s2[7:4];
                vgaBlue  = side_high_rgb_s2[3:0];
            end

            if (doom_box_d2 && doom_visible_pix) begin
                vgaRed   = doom_rgb_s2[11:8];
                vgaGreen = doom_rgb_s2[7:4];
                vgaBlue  = doom_rgb_s2[3:0];
            end

            if (game_over_frame) begin
                vgaRed   = (vgaRed >> 1) + 4'h4;
                vgaGreen = (vgaGreen >> 2);
                vgaBlue  = (vgaBlue >> 2);
            end

            if (ui_on) begin
                vgaRed   = uiR;
                vgaGreen = uiG;
                vgaBlue  = uiB;
            end
        end
    end

endmodule