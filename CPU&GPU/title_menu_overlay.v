`timescale 1ns / 1ps

module title_menu_overlay(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire [1:0] menu_index,
    input  wire       in_title,
    output wire       highlight_on,
    output wire [3:0] R,
    output wire [3:0] G,
    output wire [3:0] B
);

    // adjust these to line up with your menu text
    localparam [9:0] BOX_X0 = 10'd260;
    localparam [9:0] BOX_X1 = 10'd380;

    localparam [9:0] Y0_TOP = 10'd220; // NEW GAME
    localparam [9:0] Y1_TOP = 10'd280; // SCOREBOARD
    localparam [9:0] Y2_TOP = 10'd340; // EXIT GAME

    localparam [9:0] BOX_H  = 10'd31;

    wire [9:0] selected_y =
        (menu_index == 2'd0) ? Y0_TOP :
        (menu_index == 2'd1) ? Y1_TOP :
                               Y2_TOP;

    assign highlight_on =
        in_title &&
        (h_count >= BOX_X0) && (h_count <= BOX_X1) &&
        (v_count >= selected_y) && (v_count < selected_y + BOX_H);

    // light gray / white highlight
    assign R = 4'hF;
    assign G = 4'hF;
    assign B = 4'hF;

endmodule