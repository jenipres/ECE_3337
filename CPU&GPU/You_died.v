`timescale 1ns / 1ps
module You_died(
    input  wire pixel_clk,
    input  wire game_tick,
    input  wire hit,
    input  wire reset_btn,     // btnC (restart)
    output reg  [3:0] vgaRed ,vgaGreen, vgaBlue,
    output reg  game_over = 1'b0
);

    
    always @(posedge pixel_clk) begin
        if (reset_btn) begin
            game_over <= 1'b0;
        end else if (game_tick) begin
            if (hit)
                game_over <= 1'b1;   // latch and stay until reset
        end
    end
endmodule
