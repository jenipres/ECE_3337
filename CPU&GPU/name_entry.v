`timescale 1ns / 1ps

module name_entry(
    input  wire       clk,
    input  wire       reset,
    input  wire       in_name_entry,
    input  wire       btnL,
    input  wire       btnR,
    input  wire       btnU,
    input  wire       btnD,
    output reg [7:0]  char0,
    output reg [7:0]  char1,
    output reg [7:0]  char2,
    output reg [1:0]  cursor_pos,
    output wire       name_done
);

    reg btnL_d, btnR_d, btnU_d, btnD_d;
    reg edited0, edited1, edited2;

    wire btnL_pulse = btnL & ~btnL_d;
    wire btnR_pulse = btnR & ~btnR_d;
    wire btnU_pulse = btnU & ~btnU_d;
    wire btnD_pulse = btnD & ~btnD_d;

    assign name_done = edited0 && edited1 && edited2;

    task inc_char;
        inout [7:0] c;
        begin
            if (c == "Z")
                c = "A";
            else
                c = c + 8'd1;
        end
    endtask

    task dec_char;
        inout [7:0] c;
        begin
            if (c == "A")
                c = "Z";
            else
                c = c - 8'd1;
        end
    endtask

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            char0      <= "A";
            char1      <= "A";
            char2      <= "A";
            cursor_pos <= 2'd0;

            edited0    <= 1'b0;
            edited1    <= 1'b0;
            edited2    <= 1'b0;

            btnL_d     <= 1'b0;
            btnR_d     <= 1'b0;
            btnU_d     <= 1'b0;
            btnD_d     <= 1'b0;
        end else begin
            btnL_d <= btnL;
            btnR_d <= btnR;
            btnU_d <= btnU;
            btnD_d <= btnD;

            if (in_name_entry) begin
                if (btnL_pulse) begin
                    if (cursor_pos == 2'd0)
                        cursor_pos <= 2'd2;
                    else
                        cursor_pos <= cursor_pos - 1'b1;
                end
                else if (btnR_pulse) begin
                    if (cursor_pos == 2'd2)
                        cursor_pos <= 2'd0;
                    else
                        cursor_pos <= cursor_pos + 1'b1;
                end
                else if (btnU_pulse) begin
                    case (cursor_pos)
                        2'd0: begin
                            inc_char(char0);
                            edited0 <= 1'b1;
                        end
                        2'd1: begin
                            inc_char(char1);
                            edited1 <= 1'b1;
                        end
                        2'd2: begin
                            inc_char(char2);
                            edited2 <= 1'b1;
                        end
                    endcase
                end
                else if (btnD_pulse) begin
                    case (cursor_pos)
                        2'd0: begin
                            dec_char(char0);
                            edited0 <= 1'b1;
                        end
                        2'd1: begin
                            dec_char(char1);
                            edited1 <= 1'b1;
                        end
                        2'd2: begin
                            dec_char(char2);
                            edited2 <= 1'b1;
                        end
                    endcase
                end
            end
            else begin
                // re-arm for next run whenever not in name entry
                char0      <= "A";
                char1      <= "A";
                char2      <= "A";
                cursor_pos <= 2'd0;

                edited0    <= 1'b0;
                edited1    <= 1'b0;
                edited2    <= 1'b0;
            end
        end
    end

endmodule