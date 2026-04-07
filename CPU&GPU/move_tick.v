`timescale 1ns / 1ps

module move_tick #(
    parameter integer DIV = 2500000  // adjust for speed
)(
    input  wire clk,
    input  wire reset,
    output reg  tick
);

    reg [$clog2(DIV):0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            tick  <= 1'b0;
        end else begin
            tick <= 1'b0;

            if (count == DIV-1) begin
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule