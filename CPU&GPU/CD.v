`timescale 1ns / 1ps
module CD #(
    parameter [9:0] HALF_A = 10'd20,
    parameter [9:0] HALF_B = 10'd20
)(
    input  wire [9:0] ax, ay,
    input  wire [9:0] bx, by,
    output wire hit
);
    // Overlap on X and Y for axis-aligned squares
    wire x_overlap = (ax + HALF_A >= bx) && (bx + HALF_B >= ax);
    wire y_overlap = (ay + HALF_A >= by) && (by + HALF_B >= ay);

    assign hit = x_overlap && y_overlap;
endmodule
