`timescale 1ns / 1ps

module title_menu_fsm(
    input  wire       clk,
    input  wire       reset,
    input  wire       in_title,
    input  wire       btnUp,
    input  wire       btnDown,
    output reg  [1:0] menu_index
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            menu_index <= 2'd0;
        end
        else if (in_title) begin
            if (btnUp) begin
                if (menu_index == 2'd0)
                    menu_index <= 2'd2;
                else
                    menu_index <= menu_index - 1'b1;
            end
            else if (btnDown) begin
                if (menu_index == 2'd2)
                    menu_index <= 2'd0;
                else
                    menu_index <= menu_index + 1'b1;
            end
        end
    end

endmodule