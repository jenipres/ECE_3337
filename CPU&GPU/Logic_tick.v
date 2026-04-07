`timescale 1ns / 1ps

module Logic_tick #(
    parameter integer DIV = 300000   // ~10 kHz from 25 MHz
)(
    input  wire pixel_clk,
    output reg  logic_tick = 1'b0
);

    integer cnt = 0;

    always @(posedge pixel_clk) begin
        logic_tick <= 1'b0;

        if (cnt >= DIV-1) begin
            cnt <= 0;
            logic_tick <= 1'b1;
        end else begin
            cnt <= cnt + 1;
        end
    end

endmodule