`timescale 1ns / 1ps
module vga_timing(
    input  wire pixel_clk,
    output wire Hsync,
    output wire Vsync,
    output reg  [9:0] h_count = 10'd0,
    output reg  [9:0] v_count = 10'd0,
    output wire new_frame
);
    // 640x480 @ 60 Hz timing
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    // Counters
    always @(posedge pixel_clk) begin
        if (h_count == H_TOTAL-1) begin
            h_count <= 10'd0;
            if (v_count == V_TOTAL-1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 1'b1;
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    // Sync pulses (active low)
    assign Hsync = ~(h_count >= (H_VISIBLE + H_FRONT) &&
                     h_count <  (H_VISIBLE + H_FRONT + H_SYNC));

    assign Vsync = ~(v_count >= (V_VISIBLE + V_FRONT) &&
                     v_count <  (V_VISIBLE + V_FRONT + V_SYNC));

    // new_frame tick: VSYNC falling edge
    reg vsync_d = 1'b1;
    always @(posedge pixel_clk)
        vsync_d <= Vsync;

    assign new_frame = (vsync_d == 1'b1) && (Vsync == 1'b0);

endmodule

