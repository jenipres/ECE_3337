`timescale 1ns / 1ps

module name_entry_renderer(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    input  wire       in_name_entry,
    input  wire [1:0] cursor_pos,
    input  wire [7:0] char0,
    input  wire [7:0] char1,
    input  wire [7:0] char2,
    output reg  [3:0] R,
    output reg  [3:0] G,
    output reg  [3:0] B
);

    wire visible = (h_count < 10'd640) && (v_count < 10'd480);

    localparam X0 = 10'd180, X1 = 10'd290, X2 = 10'd400;
    localparam Y0 = 10'd180;
    localparam BOX_W = 10'd60;
    localparam BOX_H = 10'd80;

    wire box0 = (h_count >= X0) && (h_count <= X0 + BOX_W) &&
                (v_count >= Y0) && (v_count <= Y0 + BOX_H);

    wire box1 = (h_count >= X1) && (h_count <= X1 + BOX_W) &&
                (v_count >= Y0) && (v_count <= Y0 + BOX_H);

    wire box2 = (h_count >= X2) && (h_count <= X2 + BOX_W) &&
                (v_count >= Y0) && (v_count <= Y0 + BOX_H);

    wire sel0 = box0 && (cursor_pos == 2'd0);
    wire sel1 = box1 && (cursor_pos == 2'd1);
    wire sel2 = box2 && (cursor_pos == 2'd2);

    function automatic [34:0] glyph5x7;
        input [7:0] ch;
        begin
            case (ch)
                "A": glyph5x7 = 35'b01110_10001_10001_11111_10001_10001_10001;
                "B": glyph5x7 = 35'b11110_10001_10001_11110_10001_10001_11110;
                "C": glyph5x7 = 35'b01111_10000_10000_10000_10000_10000_01111;
                "D": glyph5x7 = 35'b11110_10001_10001_10001_10001_10001_11110;
                "E": glyph5x7 = 35'b11111_10000_10000_11110_10000_10000_11111;
                "F": glyph5x7 = 35'b11111_10000_10000_11110_10000_10000_10000;
                "G": glyph5x7 = 35'b01111_10000_10000_10011_10001_10001_01110;
                "H": glyph5x7 = 35'b10001_10001_10001_11111_10001_10001_10001;
                "I": glyph5x7 = 35'b11111_00100_00100_00100_00100_00100_11111;
                "J": glyph5x7 = 35'b00001_00001_00001_00001_10001_10001_01110;
                "K": glyph5x7 = 35'b10001_10010_10100_11000_10100_10010_10001;
                "L": glyph5x7 = 35'b10000_10000_10000_10000_10000_10000_11111;
                "M": glyph5x7 = 35'b10001_11011_10101_10101_10001_10001_10001;
                "N": glyph5x7 = 35'b10001_11001_10101_10011_10001_10001_10001;
                "O": glyph5x7 = 35'b01110_10001_10001_10001_10001_10001_01110;
                "P": glyph5x7 = 35'b11110_10001_10001_11110_10000_10000_10000;
                "Q": glyph5x7 = 35'b01110_10001_10001_10001_10101_10010_01101;
                "R": glyph5x7 = 35'b11110_10001_10001_11110_10100_10010_10001;
                "S": glyph5x7 = 35'b01111_10000_10000_01110_00001_00001_11110;
                "T": glyph5x7 = 35'b11111_00100_00100_00100_00100_00100_00100;
                "U": glyph5x7 = 35'b10001_10001_10001_10001_10001_10001_01110;
                "V": glyph5x7 = 35'b10001_10001_10001_10001_10001_01010_00100;
                "W": glyph5x7 = 35'b10001_10001_10001_10101_10101_10101_01010;
                "X": glyph5x7 = 35'b10001_10001_01010_00100_01010_10001_10001;
                "Y": glyph5x7 = 35'b10001_10001_01010_00100_00100_00100_00100;
                "Z": glyph5x7 = 35'b11111_00001_00010_00100_01000_10000_11111;
                " ": glyph5x7 = 35'b00000_00000_00000_00000_00000_00000_00000;
                default: glyph5x7 = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction

    function automatic glyph_pixel_on;
        input [9:0] px, py;
        input [9:0] base_x, base_y;
        input [7:0] ch;
        input integer scale;
        reg [34:0] glyph;
        reg [2:0] row;
        reg [2:0] col;
        reg [9:0] lx, ly;
        begin
            glyph = glyph5x7(ch);
            if ((px >= base_x) && (px < base_x + 5*scale) &&
                (py >= base_y) && (py < base_y + 7*scale)) begin
                lx  = px - base_x;
                ly  = py - base_y;
                col = lx / scale;
                row = ly / scale;
                glyph_pixel_on = glyph[34 - (row*5 + col)];
            end else begin
                glyph_pixel_on = 1'b0;
            end
        end
    endfunction

    function automatic letter_pixel_on;
        input [9:0] px, py;
        input [9:0] box_x, box_y;
        input [7:0] ch;
        begin
            letter_pixel_on = glyph_pixel_on(px, py, box_x + 10'd10, box_y + 10'd12, ch, 8);
        end
    endfunction

    wire char0_on = letter_pixel_on(h_count, v_count, X0, Y0, char0);
    wire char1_on = letter_pixel_on(h_count, v_count, X1, Y0, char1);
    wire char2_on = letter_pixel_on(h_count, v_count, X2, Y0, char2);

    // ENTER NAME header
    wire hE1 = glyph_pixel_on(h_count, v_count, 10'd150, 10'd90,  "E", 4);
    wire hN1 = glyph_pixel_on(h_count, v_count, 10'd175, 10'd90,  "N", 4);
    wire hT  = glyph_pixel_on(h_count, v_count, 10'd200, 10'd90,  "T", 4);
    wire hE2 = glyph_pixel_on(h_count, v_count, 10'd225, 10'd90,  "E", 4);
    wire hR  = glyph_pixel_on(h_count, v_count, 10'd250, 10'd90,  "R", 4);
    wire hSP = glyph_pixel_on(h_count, v_count, 10'd275, 10'd90,  " ", 4);
    wire hN2 = glyph_pixel_on(h_count, v_count, 10'd300, 10'd90,  "N", 4);
    wire hA  = glyph_pixel_on(h_count, v_count, 10'd325, 10'd90,  "A", 4);
    wire hM  = glyph_pixel_on(h_count, v_count, 10'd350, 10'd90,  "M", 4);
    wire hE3 = glyph_pixel_on(h_count, v_count, 10'd375, 10'd90,  "E", 4);

    wire header_text_on = hE1 | hN1 | hT | hE2 | hR | hSP | hN2 | hA | hM | hE3;

    always @(*) begin
        if (!visible || !in_name_entry) begin
            R = 4'h0; G = 4'h0; B = 4'h0;
        end else begin
            R = 4'h0; G = 4'h0; B = 4'h2;

            if (box0 || box1 || box2) begin
                R = 4'h6; G = 4'h6; B = 4'h8;
            end

            if (sel0 || sel1 || sel2) begin
                R = 4'hF; G = 4'hF; B = 4'hA;
            end

            if (header_text_on) begin
                R = 4'hF; G = 4'hF; B = 4'hF;
            end

            if (char0_on || char1_on || char2_on) begin
                R = 4'h0; G = 4'h0; B = 4'h0;
            end
        end
    end

endmodule