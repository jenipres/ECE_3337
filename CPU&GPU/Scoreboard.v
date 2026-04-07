`timescale 1ns / 1ps

module scoreboard(
    input  wire [9:0] h_count,
    input  wire [9:0] v_count,
    output reg  [3:0] R,
    output reg  [3:0] G,
    output reg  [3:0] B
);

    wire visible = (h_count < 10'd640) && (v_count < 10'd480);

    wire header_box =
        (h_count >= 10'd140) && (h_count <= 10'd500) &&
        (v_count >= 10'd60)  && (v_count <= 10'd120);

    wire row1 =
        (h_count >= 10'd160) && (h_count <= 10'd480) &&
        (v_count >= 10'd160) && (v_count <= 10'd195);

    wire row2 =
        (h_count >= 10'd160) && (h_count <= 10'd480) &&
        (v_count >= 10'd210) && (v_count <= 10'd245);

    wire row3 =
        (h_count >= 10'd160) && (h_count <= 10'd480) &&
        (v_count >= 10'd260) && (v_count <= 10'd295);

    wire row4 =
        (h_count >= 10'd160) && (h_count <= 10'd480) &&
        (v_count >= 10'd310) && (v_count <= 10'd345);

    wire row5 =
        (h_count >= 10'd160) && (h_count <= 10'd480) &&
        (v_count >= 10'd360) && (v_count <= 10'd395);

    always @(*) begin
        if (!visible) begin
            R = 4'h0;
            G = 4'h0;
            B = 4'h0;
        end
        else begin
            // dark blue background
            R = 4'h0;
            G = 4'h1;
            B = 4'h4;

            if (header_box) begin
                R = 4'hF;
                G = 4'hF;
                B = 4'hF;
            end
            else if (row1 || row2 || row3 || row4 || row5) begin
                R = 4'h8;
                G = 4'h8;
                B = 4'hA;
            end
        end
    end

endmodule