`timescale 1ns / 1ps

module top(
    input  wire        CLK100MHZ,
    input  wire        btnL, btnR, btnU, btnD, btnC,
    input  wire [7:0]  JA,
    output wire [15:0] LED,
    output wire        Hsync, Vsync,
    output wire [3:0]  vgaRed, vgaGreen, vgaBlue
);
    wire       cpu_hazard_enable;
    wire       cpu_hazard_force_spawn;
    wire       cpu_hazard_burst_enable;
    wire       cpu_hazard_pattern_override;
    wire [2:0] cpu_hazard_pattern_id;

    wire btnU_p     = ~JA[0];
    wire btnD_p     = ~JA[4];
    wire btnL_p     = ~JA[1];
    wire btnR_p     = ~JA[5];

    wire btnA_p     = ~JA[2];
    wire btnB_p     = ~JA[6];

    wire btnStart_p = ~JA[3];
    wire btnX_p     = ~JA[7];

    wire btnL_final = btnL | btnL_p;
    wire btnR_final = btnR | btnR_p;
    wire btnU_final = btnStart_p | btnU_p;
    wire btnD_final = btnD | btnD_p;

    wire reset_final = btnC;

    wire btnSelect_final = btnA_p;
    wire btnBack_final   = btnB_p;

    localparam USE_GPU_REGS = 1'b1;
    
    wire [7:0] player_x_lo;
    wire [7:0] player_x_hi;
    wire [7:0] cpu_player_y_8;
    wire [2:0] cpu_pose;
    wire       cpu_crouch;
    wire       cpu_game_over;

    wire [7:0] cpu_ufo_x_8, cpu_ufo_y_8;

    wire [7:0] cpu_blk0_x_8, cpu_blk0_y_8;
    wire       cpu_blk0_active;

    wire [7:0] cpu_blk1_x_8, cpu_blk1_y_8;
    wire       cpu_blk1_active;

    wire [15:0] cpu_player_x_full = {player_x_hi, player_x_lo};
    wire [9:0] cpu_player_x = cpu_player_x_full[9:0] << 1;
    wire [9:0] cpu_player_y = {2'b00, cpu_player_y_8, 1'b0};
    wire [9:0] cpu_ufo_x    = {2'b00, cpu_ufo_x_8};
    wire [9:0] cpu_ufo_y    = {2'b00, cpu_ufo_y_8};
    wire [9:0] cpu_blk0_x   = {2'b00, cpu_blk0_x_8};
    wire [9:0] cpu_blk0_y   = {2'b00, cpu_blk0_y_8};
    wire [9:0] cpu_blk1_x   = {2'b00, cpu_blk1_x_8};
    wire [9:0] cpu_blk1_y   = {2'b00, cpu_blk1_y_8};
    wire [7:0] cpu_difficulty;
    wire [7:0] cpu_top_intensity;
    wire [7:0] cpu_side_intensity;
    wire [7:0] cpu_burst_intensity;
    wire [7:0] cpu_pattern_bias;
    wire [7:0] cpu_random_seed;

    wire top_valid0, top_valid1, top_valid2, top_valid3, top_valid4;

    wire btnL_db, btnR_db, btnU_db, btnD_db;
    wire [1:0] game_state;

    localparam TITLE      = 2'd0;
    localparam SCOREBOARD = 2'd1;
    localparam GAME       = 2'd2;
    localparam NAME_ENTRY = 2'd3;

    wire in_title      = (game_state == TITLE);
    wire in_scoreboard = (game_state == SCOREBOARD);
    wire in_game       = (game_state == GAME);
    wire in_name_entry = (game_state == NAME_ENTRY);

    wire [3:0] titleR, titleG, titleB;
    wire [3:0] game_vgaRed, game_vgaGreen, game_vgaBlue;
    wire [1:0] menu_index;
    wire menu_highlight_on;
    wire [3:0] menu_highlight_R, menu_highlight_G, menu_highlight_B;
    wire [3:0] scoreR, scoreG, scoreB;
    wire scoreboard_ui_on;
    wire [3:0] scoreboard_ui_R, scoreboard_ui_G, scoreboard_ui_B;

    wire [13:0] live_score;
    wire [13:0] final_score;

    wire [3:0] live_score_thousands = (live_score  / 1000) % 10;
    wire [3:0] live_score_hundreds  = (live_score  / 100)  % 10;
    wire [3:0] live_score_tens      = (live_score  / 10)   % 10;
    wire [3:0] live_score_ones      =  live_score          % 10;

    wire [3:0] final_score_thousands = (final_score / 1000) % 10;
    wire [3:0] final_score_hundreds  = (final_score / 100)  % 10;
    wire [3:0] final_score_tens      = (final_score / 10)   % 10;
    wire [3:0] final_score_ones      =  final_score         % 10;

    wire [13:0] top_score0, top_score1, top_score2, top_score3, top_score4;

    wire [7:0] top_name0_c0, top_name0_c1, top_name0_c2;
    wire [7:0] top_name1_c0, top_name1_c1, top_name1_c2;
    wire [7:0] top_name2_c0, top_name2_c1, top_name2_c2;
    wire [7:0] top_name3_c0, top_name3_c1, top_name3_c2;
    wire [7:0] top_name4_c0, top_name4_c1, top_name4_c2;

    wire pixel_clk;
    wire game_restart;
    wire [7:0] name_char0, name_char1, name_char2;
    wire [1:0] name_cursor_pos;
    wire [3:0] nameR, nameG, nameB;
    wire       name_done;

    Clock_div u_clk (
        .clk_in(CLK100MHZ),
        .pixel_clk(pixel_clk)
    );

    cpu_top u_cpu (
        .clk(CLK100MHZ),
        .reset(reset_final),

        .btnL(btnL_final && !game_over && (player_x > 10'd20)),
        .btnR(btnR_final && !game_over && (player_x < 10'd619)),
        .btnU(1'b0),
        .btnD(btnD_final && !game_over),
        .btnC(reset_final),

        .btnA(btnA_p),
        .btnB(btnB_p),
        .btnStart(btnStart_p),
        .btnX(btnX_p),

        .player_x_lo(player_x_lo),
        .player_x_hi(player_x_hi),
        .player_y(cpu_player_y_8),
        .pose(cpu_pose),
        .crouch(cpu_crouch),
        .game_over(cpu_game_over),

        .ufo_x(cpu_ufo_x_8),
        .ufo_y(cpu_ufo_y_8),

        .blk0_x(cpu_blk0_x_8),
        .blk0_y(cpu_blk0_y_8),
        .blk0_active(cpu_blk0_active),

        .blk1_x(cpu_blk1_x_8),
        .blk1_y(cpu_blk1_y_8),
        .blk1_active(cpu_blk1_active),

        .hazard_enable(cpu_hazard_enable),
        .hazard_force_spawn(cpu_hazard_force_spawn),
        .hazard_burst_enable(cpu_hazard_burst_enable),
        .hazard_pattern_override(cpu_hazard_pattern_override),
        .difficulty_level(cpu_difficulty),
        .top_intensity(cpu_top_intensity),
        .side_intensity(cpu_side_intensity),
        .burst_intensity(cpu_burst_intensity),
        .pattern_bias(cpu_pattern_bias),
        .random_seed(cpu_random_seed),
        .hazard_pattern_id(cpu_hazard_pattern_id)
    );

    wire [9:0] h_count, v_count;
    wire       new_frame;
    wire       Hsync_raw, Vsync_raw;

    vga_timing u_vga (
        .pixel_clk(pixel_clk),
        .h_count(h_count),
        .v_count(v_count),
        .Hsync(Hsync_raw),
        .Vsync(Vsync_raw),
        .new_frame(new_frame)
    );

    reg [9:0] h1, v1, h2, v2, h3, v3;
    reg hs1, vs1, hs2, vs2, hs3, vs3;

    always @(posedge pixel_clk) begin
        h1  <= h_count;
        v1  <= v_count;
        hs1 <= Hsync_raw;
        vs1 <= Vsync_raw;

        h2  <= h1;
        v2  <= v1;
        hs2 <= hs1;
        vs2 <= vs1;

        h3  <= h2;
        v3  <= v2;
        hs3 <= hs2;
        vs3 <= vs2;
    end

    assign Hsync = hs3;
    assign Vsync = vs3;

    wire game_tick;

    Game_tick #(
        .UPDATE_DIV(4)
    ) u_game_tick (
        .pixel_clk(pixel_clk),
        .new_frame(new_frame),
        .game_tick(game_tick)
    );

    reg [9:0] scroll_x = 10'd0;
    reg [2:0] scroll_div = 3'd0;

    always @(posedge pixel_clk) begin
        if (reset_final) begin
            scroll_x   <= 10'd0;
            scroll_div <= 3'd0;
        end
        else if (new_frame) begin
            scroll_div <= scroll_div + 1'b1;

            if (scroll_div == 3'd7) begin
                scroll_div <= 3'd0;

                if (scroll_x == 10'd639)
                    scroll_x <= 10'd0;
                else
                    scroll_x <= scroll_x + 1'b1;
            end
        end
    end

    wire [9:0] phys_player_x, phys_player_y;
    wire moving;
    wire in_air;
    wire logic_tick;
    wire [2:0] anim_pose_out;
    wire logic_game_over;

    wire [2:0] pose = anim_pose_out;
    wire       player_crouch_final = USE_GPU_REGS ? cpu_crouch : btnD_final;
    wire [9:0] player_x_unclamped = cpu_player_x;
    wire [9:0] player_x =
        (player_x_unclamped < 10'd20)  ? 10'd20  :
        (player_x_unclamped > 10'd619) ? 10'd619 :
                                         player_x_unclamped;
    wire [9:0] player_y = phys_player_y;
    wire       game_over = logic_game_over;

    wire moving_anim = in_game && (btnL_final ^ btnR_final) && !player_crouch_final;

    wire [9:0] logic_ufo_x, logic_ufo_y;
    wire       drop_pulse;
    wire [9:0] drop_x;
    wire [9:0] fall_step, side_step;

    wire [9:0] ufo_x = logic_ufo_x;
    wire [9:0] ufo_y = logic_ufo_y;

    wire side_low_active;
    wire side_high_active;

    wire [9:0] side_low_x;
    wire [9:0] side_low_y;
    wire [9:0] side_high_x;
    wire [9:0] side_high_y;

    wire side_low_move_left;
    wire side_high_move_left;

    wire logic_blk0_active, logic_blk1_active;
    wire logic_blk2_active, logic_blk3_active, logic_blk4_active, logic_blk5_active;
    wire logic_blk6_active, logic_blk7_active;
    wire logic_blk8_active, logic_blk9_active, logic_blk10_active, logic_blk11_active;
    wire logic_blk12_active, logic_blk13_active, logic_blk14_active, logic_blk15_active;

    wire [9:0] logic_blk0_x, logic_blk0_y;
    wire [9:0] logic_blk1_x, logic_blk1_y;
    wire [9:0] logic_blk2_x, logic_blk2_y;
    wire [9:0] logic_blk3_x, logic_blk3_y;
    wire [9:0] logic_blk4_x, logic_blk4_y;
    wire [9:0] logic_blk5_x, logic_blk5_y;
    wire [9:0] logic_blk6_x, logic_blk6_y;
    wire [9:0] logic_blk7_x, logic_blk7_y;
    wire [9:0] logic_blk8_x, logic_blk8_y;
    wire [9:0] logic_blk9_x, logic_blk9_y;
    wire [9:0] logic_blk10_x, logic_blk10_y;
    wire [9:0] logic_blk11_x, logic_blk11_y;
    wire [9:0] logic_blk12_x, logic_blk12_y;
    wire [9:0] logic_blk13_x, logic_blk13_y;
    wire [9:0] logic_blk14_x, logic_blk14_y;
    wire [9:0] logic_blk15_x, logic_blk15_y;

    wire blk0_active  = logic_blk0_active;
    wire blk1_active  = logic_blk1_active;
    wire blk2_active  = logic_blk2_active;
    wire blk3_active  = logic_blk3_active;
    wire blk4_active  = logic_blk4_active;
    wire blk5_active  = logic_blk5_active;
    wire blk6_active  = logic_blk6_active;
    wire blk7_active  = logic_blk7_active;
    wire blk8_active  = logic_blk8_active;
    wire blk9_active  = logic_blk9_active;
    wire blk10_active = logic_blk10_active;
    wire blk11_active = logic_blk11_active;
    wire blk12_active = logic_blk12_active;
    wire blk13_active = logic_blk13_active;
    wire blk14_active = logic_blk14_active;
    wire blk15_active = logic_blk15_active;

    wire [9:0] blk0_x  = logic_blk0_x;
    wire [9:0] blk0_y  = logic_blk0_y;
    wire [9:0] blk1_x  = logic_blk1_x;
    wire [9:0] blk1_y  = logic_blk1_y;
    wire [9:0] blk2_x  = logic_blk2_x;
    wire [9:0] blk2_y  = logic_blk2_y;
    wire [9:0] blk3_x  = logic_blk3_x;
    wire [9:0] blk3_y  = logic_blk3_y;
    wire [9:0] blk4_x  = logic_blk4_x;
    wire [9:0] blk4_y  = logic_blk4_y;
    wire [9:0] blk5_x  = logic_blk5_x;
    wire [9:0] blk5_y  = logic_blk5_y;
    wire [9:0] blk6_x  = logic_blk6_x;
    wire [9:0] blk6_y  = logic_blk6_y;
    wire [9:0] blk7_x  = logic_blk7_x;
    wire [9:0] blk7_y  = logic_blk7_y;
    wire [9:0] blk8_x  = logic_blk8_x;
    wire [9:0] blk8_y  = logic_blk8_y;
    wire [9:0] blk9_x  = logic_blk9_x;
    wire [9:0] blk9_y  = logic_blk9_y;
    wire [9:0] blk10_x = logic_blk10_x;
    wire [9:0] blk10_y = logic_blk10_y;
    wire [9:0] blk11_x = logic_blk11_x;
    wire [9:0] blk11_y = logic_blk11_y;
    wire [9:0] blk12_x = logic_blk12_x;
    wire [9:0] blk12_y = logic_blk12_y;
    wire [9:0] blk13_x = logic_blk13_x;
    wire [9:0] blk13_y = logic_blk13_y;
    wire [9:0] blk14_x = logic_blk14_x;
    wire [9:0] blk14_y = logic_blk14_y;
    wire [9:0] blk15_x = logic_blk15_x;
    wire [9:0] blk15_y = logic_blk15_y;

    wire       hazard_enable;
    wire       hazard_force_spawn_pulse;
    wire       hazard_burst_enable;
    wire       hazard_pattern_override;
    wire [2:0] hazard_pattern_id;

    Hazard_Control u_hazard_ctrl (
        .clk(pixel_clk),
        .reset(reset_final || game_restart),
        .game_tick(game_tick && in_game),

        .reg_hazard_enable(cpu_hazard_enable),
        .reg_hazard_force_spawn(cpu_hazard_force_spawn),
        .reg_hazard_burst_enable(cpu_hazard_burst_enable),
        .reg_hazard_pattern_override(cpu_hazard_pattern_override),
        .reg_hazard_pattern_id(cpu_hazard_pattern_id),

        .hazard_enable(hazard_enable),
        .hazard_force_spawn_pulse(hazard_force_spawn_pulse),
        .hazard_burst_enable(hazard_burst_enable),
        .hazard_pattern_override(hazard_pattern_override),
        .hazard_pattern_id(hazard_pattern_id)
    );

    localparam [1:0] ATTACK_TOP   = 2'd0;
    localparam [1:0] ATTACK_SIDE  = 2'd1;
    localparam [1:0] ATTACK_BURST = 2'd2;

    reg [1:0] attack_mode = ATTACK_TOP;
    reg [7:0] attack_timer = 8'd0;

    always @(posedge pixel_clk) begin
        if (reset_final || game_restart) begin
            attack_mode  <= ATTACK_TOP;
            attack_timer <= 8'd60;
        end
        else if (game_tick && in_game) begin
            if (attack_timer == 0) begin
                case ((cpu_random_seed[1:0] + cpu_pattern_bias[1:0]) % 3)
                    2'd0: attack_mode <= ATTACK_TOP;
                    2'd1: attack_mode <= ATTACK_SIDE;
                    default: attack_mode <= ATTACK_BURST;
                endcase

                attack_timer <= 8'd120 - (cpu_difficulty << 2);
            end
            else begin
                attack_timer <= attack_timer - 1'b1;
            end
        end
    end

    wire hazard_enable_mode =
        hazard_enable &&
        ((attack_mode == ATTACK_TOP) || (attack_mode == ATTACK_BURST)) &&
        (cpu_top_intensity > 8'd2);
    
    wire hazard_burst_enable_mode =
        hazard_burst_enable &&
        (attack_mode == ATTACK_BURST) &&
        (cpu_burst_intensity > 8'd3);
    
    wire side_attack_enable =
        ((attack_mode == ATTACK_SIDE) || (attack_mode == ATTACK_BURST)) &&
        (cpu_side_intensity > 8'd2);

    wire hit_fall0, hit_fall1, hit_fall2, hit_fall3;
    wire hit_fall4, hit_fall5, hit_fall6, hit_fall7;
    wire hit_fall8, hit_fall9, hit_fall10, hit_fall11;
    wire hit_fall12, hit_fall13, hit_fall14, hit_fall15;
    wire hit_side_low, hit_side_high;

    wire hit_fall0_g  = blk0_active  & hit_fall0;
    wire hit_fall1_g  = blk1_active  & hit_fall1;
    wire hit_fall2_g  = blk2_active  & hit_fall2;
    wire hit_fall3_g  = blk3_active  & hit_fall3;
    wire hit_fall4_g  = blk4_active  & hit_fall4;
    wire hit_fall5_g  = blk5_active  & hit_fall5;
    wire hit_fall6_g  = blk6_active  & hit_fall6;
    wire hit_fall7_g  = blk7_active  & hit_fall7;
    wire hit_fall8_g  = blk8_active  & hit_fall8;
    wire hit_fall9_g  = blk9_active  & hit_fall9;
    wire hit_fall10_g = blk10_active & hit_fall10;
    wire hit_fall11_g = blk11_active & hit_fall11;
    wire hit_fall12_g = blk12_active & hit_fall12;
    wire hit_fall13_g = blk13_active & hit_fall13;
    wire hit_fall14_g = blk14_active & hit_fall14;
    wire hit_fall15_g = blk15_active & hit_fall15;

    wire hit_side_low_g  = side_low_active  & hit_side_low;
    wire hit_side_high_g = side_high_active & hit_side_high;

    wire hit_any = hit_fall0_g | hit_fall1_g | hit_fall2_g | hit_fall3_g |
                   hit_fall4_g | hit_fall5_g | hit_fall6_g | hit_fall7_g |
                   hit_fall8_g | hit_fall9_g | hit_fall10_g | hit_fall11_g |
                   hit_fall12_g | hit_fall13_g | hit_fall14_g | hit_fall15_g |
                   hit_side_low_g | hit_side_high_g;

    wire [3:0] bgR, bgG, bgB;

    Background_Renderer u_bg (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .scroll_x(scroll_x),
        .bgR(bgR),
        .bgG(bgG),
        .bgB(bgB)
    );

    UFO u_ufoctl (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick && in_game),
        .reset(reset_final || game_restart),
        .ufo_x(logic_ufo_x),
        .ufo_y(logic_ufo_y),
        .drop_pulse(drop_pulse),
        .drop_x(drop_x),
        .fall_step(fall_step),
        .side_step(side_step)
    );

    Falling_Block_Manager u_blocks (
        .clk(pixel_clk),
        .rst(reset_final || game_restart),
        .game_tick(game_tick && in_game),

        .ufo_x(ufo_x),
        .ufo_y(ufo_y),
        .drop_pulse(drop_pulse),

        .hazard_enable(hazard_enable_mode),
        .hazard_force_spawn_pulse(hazard_force_spawn_pulse),
        .hazard_burst_enable(hazard_burst_enable_mode),
        .hazard_pattern_override(hazard_pattern_override),
        .hazard_pattern_id(hazard_pattern_id),

        .blk0_active(logic_blk0_active),
        .blk0_x(logic_blk0_x),
        .blk0_y(logic_blk0_y),

        .blk1_active(logic_blk1_active),
        .blk1_x(logic_blk1_x),
        .blk1_y(logic_blk1_y),

        .blk2_active(logic_blk2_active),
        .blk2_x(logic_blk2_x),
        .blk2_y(logic_blk2_y),

        .blk3_active(logic_blk3_active),
        .blk3_x(logic_blk3_x),
        .blk3_y(logic_blk3_y),

        .blk4_active(logic_blk4_active),
        .blk4_x(logic_blk4_x),
        .blk4_y(logic_blk4_y),

        .blk5_active(logic_blk5_active),
        .blk5_x(logic_blk5_x),
        .blk5_y(logic_blk5_y),

        .blk6_active(logic_blk6_active),
        .blk6_x(logic_blk6_x),
        .blk6_y(logic_blk6_y),

        .blk7_active(logic_blk7_active),
        .blk7_x(logic_blk7_x),
        .blk7_y(logic_blk7_y),

        .blk8_active(logic_blk8_active),
        .blk8_x(logic_blk8_x),
        .blk8_y(logic_blk8_y),

        .blk9_active(logic_blk9_active),
        .blk9_x(logic_blk9_x),
        .blk9_y(logic_blk9_y),

        .blk10_active(logic_blk10_active),
        .blk10_x(logic_blk10_x),
        .blk10_y(logic_blk10_y),

        .blk11_active(logic_blk11_active),
        .blk11_x(logic_blk11_x),
        .blk11_y(logic_blk11_y),

        .blk12_active(logic_blk12_active),
        .blk12_x(logic_blk12_x),
        .blk12_y(logic_blk12_y),

        .blk13_active(logic_blk13_active),
        .blk13_x(logic_blk13_x),
        .blk13_y(logic_blk13_y),

        .blk14_active(logic_blk14_active),
        .blk14_x(logic_blk14_x),
        .blk14_y(logic_blk14_y),

        .blk15_active(logic_blk15_active),
        .blk15_x(logic_blk15_x),
        .blk15_y(logic_blk15_y)
    );

    side_block_pair #(
        .HALF(10'd20),
        .Y_LOW(10'd458),
        .Y_HIGH(10'd420)
    ) u_side_pair (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick && in_game),
        .game_over(game_over),
        .reset(reset_final || game_restart),
        .side_step(side_step),

        .low_active(side_low_active),
        .low_x(side_low_x),
        .low_y(side_low_y),
        .low_move_left(side_low_move_left),

        .high_active(side_high_active),
        .high_x(side_high_x),
        .high_y(side_high_y),
        .high_move_left(side_high_move_left)
    );

    Physics u_player (
        .pixel_clk(pixel_clk),
        .game_over(game_over),
        .btnL(1'b0),
        .btnR(1'b0),
        .btnU(btnU_db && in_game),
        .reset_btn(reset_final || game_restart),
        .moving(moving),
        .in_air(in_air),
        .logic_tick(logic_tick),
        .player_x(phys_player_x),
        .player_y(phys_player_y)
    );

    Logic_tick u_logic (
        .pixel_clk(pixel_clk),
        .logic_tick(logic_tick)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall0 (
        .ax(player_x), .ay(player_y),
        .bx(blk0_x),   .by(blk0_y),
        .hit(hit_fall0)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall1 (
        .ax(player_x), .ay(player_y),
        .bx(blk1_x),   .by(blk1_y),
        .hit(hit_fall1)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall2 (
        .ax(player_x), .ay(player_y),
        .bx(blk2_x),   .by(blk2_y),
        .hit(hit_fall2)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall3 (
        .ax(player_x), .ay(player_y),
        .bx(blk3_x),   .by(blk3_y),
        .hit(hit_fall3)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall4 (
        .ax(player_x), .ay(player_y),
        .bx(blk4_x),   .by(blk4_y),
        .hit(hit_fall4)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall5 (
        .ax(player_x), .ay(player_y),
        .bx(blk5_x),   .by(blk5_y),
        .hit(hit_fall5)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall6 (
        .ax(player_x), .ay(player_y),
        .bx(blk6_x),   .by(blk6_y),
        .hit(hit_fall6)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall7 (
        .ax(player_x), .ay(player_y),
        .bx(blk7_x),   .by(blk7_y),
        .hit(hit_fall7)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall8 (
        .ax(player_x), .ay(player_y),
        .bx(blk8_x),   .by(blk8_y),
        .hit(hit_fall8)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall9 (
        .ax(player_x), .ay(player_y),
        .bx(blk9_x),   .by(blk9_y),
        .hit(hit_fall9)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall10 (
        .ax(player_x), .ay(player_y),
        .bx(blk10_x),  .by(blk10_y),
        .hit(hit_fall10)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall11 (
        .ax(player_x), .ay(player_y),
        .bx(blk11_x),  .by(blk11_y),
        .hit(hit_fall11)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall12 (
        .ax(player_x), .ay(player_y),
        .bx(blk12_x),  .by(blk12_y),
        .hit(hit_fall12)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall13 (
        .ax(player_x), .ay(player_y),
        .bx(blk13_x),  .by(blk13_y),
        .hit(hit_fall13)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall14 (
        .ax(player_x), .ay(player_y),
        .bx(blk14_x),  .by(blk14_y),
        .hit(hit_fall14)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_fall15 (
        .ax(player_x), .ay(player_y),
        .bx(blk15_x),  .by(blk15_y),
        .hit(hit_fall15)
    );

    CD #(.HALF_A(10'd20), .HALF_B(10'd20)) u_hit_side_low (
        .ax(player_x),   .ay(player_y),
        .bx(side_low_x), .by(side_low_y),
        .hit(hit_side_low)
    );

    wire [9:0] player_high_half = player_crouch_final ? 10'd8 : 10'd20;
    wire [9:0] player_high_y    = player_crouch_final ? (player_y + 10'd10) : player_y;

    wire x_overlap_side_high =
        (player_x + player_high_half >= side_high_x) &&
        (side_high_x + 10'd20 >= player_x);

    wire y_overlap_side_high =
        (player_high_y + player_high_half >= side_high_y) &&
        (side_high_y + 10'd20 >= player_high_y);

    assign hit_side_high = x_overlap_side_high && y_overlap_side_high;

    You_died u_go (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick && in_game),
        .hit(hit_any),
        .reset_btn(reset_final || game_restart),
        .game_over(logic_game_over)
    );

    Anim_Pose #(.TOGGLE_TICKS(2)) u_pose (
        .pixel_clk(pixel_clk),
        .game_tick(game_tick && in_game),
        .reset_btn(reset_final || game_restart),
        .moving(moving_anim),
        .in_air(in_air),
        .crouch(player_crouch_final),
        .pose(anim_pose_out)
    );

    wire ui_on;
    wire [3:0] uiR, uiG, uiB;

    UI_Renderer u_ui (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .visible((h3 < 10'd640) && (v3 < 10'd480)),
        .game_over(game_over),

        .score_thousands(live_score_thousands),
        .score_hundreds (live_score_hundreds),
        .score_tens     (live_score_tens),
        .score_ones     (live_score_ones),

        .ui_on(ui_on),
        .uiR(uiR),
        .uiG(uiG),
        .uiB(uiB)
    );

    Sprite_Renderer u_render (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),

        .bgR(bgR),
        .bgG(bgG),
        .bgB(bgB),

        .ui_on(ui_on),
        .uiR(uiR),
        .uiG(uiG),
        .uiB(uiB),

        .player_x(player_x),
        .player_y(player_y),

        .blk0_active(blk0_active),
        .blk0_x(blk0_x),
        .blk0_y(blk0_y),

        .blk1_active(blk1_active),
        .blk1_x(blk1_x),
        .blk1_y(blk1_y),

        .blk2_active(blk2_active),
        .blk2_x(blk2_x),
        .blk2_y(blk2_y),

        .blk3_active(blk3_active),
        .blk3_x(blk3_x),
        .blk3_y(blk3_y),

        .blk4_active(blk4_active),
        .blk4_x(blk4_x),
        .blk4_y(blk4_y),

        .blk5_active(blk5_active),
        .blk5_x(blk5_x),
        .blk5_y(blk5_y),

        .blk6_active(blk6_active),
        .blk6_x(blk6_x),
        .blk6_y(blk6_y),

        .blk7_active(blk7_active),
        .blk7_x(blk7_x),
        .blk7_y(blk7_y),

        .blk8_active(blk8_active),
        .blk8_x(blk8_x),
        .blk8_y(blk8_y),

        .blk9_active(blk9_active),
        .blk9_x(blk9_x),
        .blk9_y(blk9_y),

        .blk10_active(blk10_active),
        .blk10_x(blk10_x),
        .blk10_y(blk10_y),

        .blk11_active(blk11_active),
        .blk11_x(blk11_x),
        .blk11_y(blk11_y),

        .blk12_active(blk12_active),
        .blk12_x(blk12_x),
        .blk12_y(blk12_y),

        .blk13_active(blk13_active),
        .blk13_x(blk13_x),
        .blk13_y(blk13_y),

        .blk14_active(blk14_active),
        .blk14_x(blk14_x),
        .blk14_y(blk14_y),

        .blk15_active(blk15_active),
        .blk15_x(blk15_x),
        .blk15_y(blk15_y),

        .side_low_active(side_low_active),
        .side_low_x(side_low_x),
        .side_low_y(side_low_y),
        .side_low_move_left(side_low_move_left),

        .side_high_active(side_high_active),
        .side_high_x(side_high_x),
        .side_high_y(side_high_y),
        .side_high_move_left(side_high_move_left),

        .ufo_x(ufo_x),
        .ufo_y(ufo_y),

        .pose(pose),
        .game_over(game_over),

        .vgaRed(game_vgaRed),
        .vgaGreen(game_vgaGreen),
        .vgaBlue(game_vgaBlue)
    );

    assign vgaRed =
        in_title      ? (menu_highlight_on ? ((titleR >> 1) + (menu_highlight_R >> 1)) : titleR) :
        in_scoreboard ? (scoreboard_ui_on ? scoreboard_ui_R : scoreR) :
        in_name_entry ? nameR :
        in_game       ? game_vgaRed :
        4'h0;

    assign vgaGreen =
        in_title      ? (menu_highlight_on ? ((titleG >> 1) + (menu_highlight_G >> 1)) : titleG) :
        in_scoreboard ? (scoreboard_ui_on ? scoreboard_ui_G : scoreG) :
        in_name_entry ? nameG :
        in_game       ? game_vgaGreen :
        4'h0;

    assign vgaBlue =
        in_title      ? (menu_highlight_on ? ((titleB >> 1) + (menu_highlight_B >> 1)) : titleB) :
        in_scoreboard ? (scoreboard_ui_on ? scoreboard_ui_B : scoreB) :
        in_name_entry ? nameB :
        in_game       ? game_vgaBlue :
        4'h0;

    FSM u_game_state_fsm (
        .clk(pixel_clk),
        .reset(1'b0),
        .btnBack(btnBack_final),
        .btnSelect(btnSelect_final),
        .menu_index(menu_index),
        .game_over(game_over),
        .name_done(name_done),
        .state(game_state),
        .game_restart(game_restart)
    );

    Title_Renderer u_title (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .R(titleR),
        .G(titleG),
        .B(titleB)
    );

    title_menu_fsm u_title_menu (
        .clk(pixel_clk),
        .reset(reset_final),
        .in_title(in_title),
        .btnUp(btnU_final),
        .btnDown(btnD_final),
        .menu_index(menu_index)
    );

    title_menu_overlay u_title_menu_overlay (
        .h_count(h3),
        .v_count(v3),
        .menu_index(menu_index),
        .in_title(in_title),
        .highlight_on(menu_highlight_on),
        .R(menu_highlight_R),
        .G(menu_highlight_G),
        .B(menu_highlight_B)
    );

    scoreboard u_scoreboard (
        .h_count(h3),
        .v_count(v3),
        .R(scoreR),
        .G(scoreG),
        .B(scoreB)
    );

    scoreboard_ui u_scoreboard_ui (
        .pixel_clk(pixel_clk),
        .h_count(h3),
        .v_count(v3),
        .in_scoreboard(in_scoreboard),

        .valid0(top_valid0),
        .valid1(top_valid1),
        .valid2(top_valid2),
        .valid3(top_valid3),
        .valid4(top_valid4),

        .name0_c0(top_name0_c0), .name0_c1(top_name0_c1), .name0_c2(top_name0_c2),
        .name1_c0(top_name1_c0), .name1_c1(top_name1_c1), .name1_c2(top_name1_c2),
        .name2_c0(top_name2_c0), .name2_c1(top_name2_c1), .name2_c2(top_name2_c2),
        .name3_c0(top_name3_c0), .name3_c1(top_name3_c1), .name3_c2(top_name3_c2),
        .name4_c0(top_name4_c0), .name4_c1(top_name4_c1), .name4_c2(top_name4_c2),

        .score0(top_score0),
        .score1(top_score1),
        .score2(top_score2),
        .score3(top_score3),
        .score4(top_score4),

        .ui_on(scoreboard_ui_on),
        .R(scoreboard_ui_R),
        .G(scoreboard_ui_G),
        .B(scoreboard_ui_B)
    );

    name_entry u_name_entry (
        .clk(pixel_clk),
        .reset(reset_final || game_restart),
        .in_name_entry(in_name_entry),
        .btnL(btnL_final),
        .btnR(btnR_final),
        .btnU(btnU_final),
        .btnD(btnD_final),
        .char0(name_char0),
        .char1(name_char1),
        .char2(name_char2),
        .cursor_pos(name_cursor_pos),
        .name_done(name_done)
    );

    name_entry_renderer u_name_entry_renderer (
        .h_count(h3),
        .v_count(v3),
        .in_name_entry(in_name_entry),
        .cursor_pos(name_cursor_pos),
        .char0(name_char0),
        .char1(name_char1),
        .char2(name_char2),
        .R(nameR),
        .G(nameG),
        .B(nameB)
    );

    score_system #(
        .FPS(15),
        .MAX_SCORE(9999)
    ) u_score_system (
        .clk(pixel_clk),
        .reset(reset_final || game_restart),
        .game_tick(game_tick),
        .in_game(in_game),
        .game_over(game_over),
        .live_score(live_score),
        .final_score(final_score)
    );

    reg btnSelect_score_d;
    always @(posedge pixel_clk) begin
        if (reset_final)
            btnSelect_score_d <= 1'b0;
        else
            btnSelect_score_d <= btnSelect_final;
    end

    wire submit_score_pulse = in_name_entry && btnSelect_final && !btnSelect_score_d;

    scoreboard_table u_scoreboard_table (
        .clk(pixel_clk),
        .reset(reset_final),
        .submit_pulse(submit_score_pulse),
        .new_score(final_score),
        .new_c0(name_char0),
        .new_c1(name_char1),
        .new_c2(name_char2),

        .valid0(top_valid0),
        .valid1(top_valid1),
        .valid2(top_valid2),
        .valid3(top_valid3),
        .valid4(top_valid4),

        .score0(top_score0),
        .score1(top_score1),
        .score2(top_score2),
        .score3(top_score3),
        .score4(top_score4),

        .name0_c0(top_name0_c0), .name0_c1(top_name0_c1), .name0_c2(top_name0_c2),
        .name1_c0(top_name1_c0), .name1_c1(top_name1_c1), .name1_c2(top_name1_c2),
        .name2_c0(top_name2_c0), .name2_c1(top_name2_c1), .name2_c2(top_name2_c2),
        .name3_c0(top_name3_c0), .name3_c1(top_name3_c1), .name3_c2(top_name3_c2),
        .name4_c0(top_name4_c0), .name4_c1(top_name4_c1), .name4_c2(top_name4_c2)
    );

    debounce #(
        .COUNT_MAX(1000000)
    ) u_btnU_debounce (
        .clk(CLK100MHZ),
        .reset(reset_final),
        .noisy(btnU_final),
        .clean(btnU_db)
    );

    assign LED[0] = btnU_p;
    assign LED[1] = btnD_p;
    assign LED[2] = btnL_p;
    assign LED[3] = btnR_p;
    assign LED[4] = btnA_p;
    assign LED[5] = btnB_p;
    assign LED[6] = btnStart_p;
    assign LED[7] = btnX_p;
    assign LED[15:8] = 8'h00;

endmodule