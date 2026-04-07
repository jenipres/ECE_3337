`timescale 1ns / 1ps

module scoreboard_table(
    input  wire        clk,
    input  wire        reset,
    input  wire        submit_pulse,
    input  wire [13:0] new_score,
    input  wire [7:0]  new_c0,
    input  wire [7:0]  new_c1,
    input  wire [7:0]  new_c2,

    output reg         valid0,
    output reg         valid1,
    output reg         valid2,
    output reg         valid3,
    output reg         valid4,

    output reg [13:0] score0,
    output reg [13:0] score1,
    output reg [13:0] score2,
    output reg [13:0] score3,
    output reg [13:0] score4,

    output reg [7:0] name0_c0, output reg [7:0] name0_c1, output reg [7:0] name0_c2,
    output reg [7:0] name1_c0, output reg [7:0] name1_c1, output reg [7:0] name1_c2,
    output reg [7:0] name2_c0, output reg [7:0] name2_c1, output reg [7:0] name2_c2,
    output reg [7:0] name3_c0, output reg [7:0] name3_c1, output reg [7:0] name3_c2,
    output reg [7:0] name4_c0, output reg [7:0] name4_c1, output reg [7:0] name4_c2
);

    reg [2:0] insert_pos;
    reg       qualifies;

    always @(*) begin
        insert_pos = 3'd5;
        qualifies  = 1'b0;

        if (!valid0 || (new_score > score0)) begin
            insert_pos = 3'd0;
            qualifies  = 1'b1;
        end
        else if (!valid1 || (new_score > score1)) begin
            insert_pos = 3'd1;
            qualifies  = 1'b1;
        end
        else if (!valid2 || (new_score > score2)) begin
            insert_pos = 3'd2;
            qualifies  = 1'b1;
        end
        else if (!valid3 || (new_score > score3)) begin
            insert_pos = 3'd3;
            qualifies  = 1'b1;
        end
        else if (!valid4 || (new_score > score4)) begin
            insert_pos = 3'd4;
            qualifies  = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            valid0 <= 1'b0; valid1 <= 1'b0; valid2 <= 1'b0; valid3 <= 1'b0; valid4 <= 1'b0;

            score0 <= 14'd0; score1 <= 14'd0; score2 <= 14'd0; score3 <= 14'd0; score4 <= 14'd0;

            name0_c0 <= " "; name0_c1 <= " "; name0_c2 <= " ";
            name1_c0 <= " "; name1_c1 <= " "; name1_c2 <= " ";
            name2_c0 <= " "; name2_c1 <= " "; name2_c2 <= " ";
            name3_c0 <= " "; name3_c1 <= " "; name3_c2 <= " ";
            name4_c0 <= " "; name4_c1 <= " "; name4_c2 <= " ";
        end
        else if (submit_pulse && qualifies) begin
            case (insert_pos)
                3'd0: begin
                    valid4 <= valid3; valid3 <= valid2; valid2 <= valid1; valid1 <= valid0; valid0 <= 1'b1;
                    score4 <= score3; score3 <= score2; score2 <= score1; score1 <= score0; score0 <= new_score;

                    name4_c0 <= name3_c0; name4_c1 <= name3_c1; name4_c2 <= name3_c2;
                    name3_c0 <= name2_c0; name3_c1 <= name2_c1; name3_c2 <= name2_c2;
                    name2_c0 <= name1_c0; name2_c1 <= name1_c1; name2_c2 <= name1_c2;
                    name1_c0 <= name0_c0; name1_c1 <= name0_c1; name1_c2 <= name0_c2;
                    name0_c0 <= new_c0;   name0_c1 <= new_c1;   name0_c2 <= new_c2;
                end

                3'd1: begin
                    valid4 <= valid3; valid3 <= valid2; valid2 <= valid1; valid1 <= 1'b1;
                    score4 <= score3; score3 <= score2; score2 <= score1; score1 <= new_score;

                    name4_c0 <= name3_c0; name4_c1 <= name3_c1; name4_c2 <= name3_c2;
                    name3_c0 <= name2_c0; name3_c1 <= name2_c1; name3_c2 <= name2_c2;
                    name2_c0 <= name1_c0; name2_c1 <= name1_c1; name2_c2 <= name1_c2;
                    name1_c0 <= new_c0;   name1_c1 <= new_c1;   name1_c2 <= new_c2;
                end

                3'd2: begin
                    valid4 <= valid3; valid3 <= valid2; valid2 <= 1'b1;
                    score4 <= score3; score3 <= score2; score2 <= new_score;

                    name4_c0 <= name3_c0; name4_c1 <= name3_c1; name4_c2 <= name3_c2;
                    name3_c0 <= name2_c0; name3_c1 <= name2_c1; name3_c2 <= name2_c2;
                    name2_c0 <= new_c0;   name2_c1 <= new_c1;   name2_c2 <= new_c2;
                end

                3'd3: begin
                    valid4 <= valid3; valid3 <= 1'b1;
                    score4 <= score3; score3 <= new_score;

                    name4_c0 <= name3_c0; name4_c1 <= name3_c1; name4_c2 <= name3_c2;
                    name3_c0 <= new_c0;   name3_c1 <= new_c1;   name3_c2 <= new_c2;
                end

                3'd4: begin
                    valid4 <= 1'b1;
                    score4 <= new_score;
                    name4_c0 <= new_c0; name4_c1 <= new_c1; name4_c2 <= new_c2;
                end
            endcase
        end
    end

endmodule