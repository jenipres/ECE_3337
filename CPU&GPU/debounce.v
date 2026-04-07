`timescale 1ns / 1ps

module debounce #(
    parameter integer COUNT_MAX = 1000000
)(
    input  wire clk,
    input  wire reset,
    input  wire noisy,
    output reg  clean
);

    reg sync0, sync1;
    reg [$clog2(COUNT_MAX):0] count;
    reg stable_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync0        <= 1'b0;
            sync1        <= 1'b0;
            clean        <= 1'b0;
            stable_state <= 1'b0;
            count        <= 0;
        end else begin
            sync0 <= noisy;
            sync1 <= sync0;

            if (sync1 == stable_state) begin
                count <= 0;
            end else begin
                if (count == COUNT_MAX-1) begin
                    stable_state <= sync1;
                    clean        <= sync1;
                    count        <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

endmodule