`timescale 1ns / 1ps

module Title_ROM(
    input  wire        clk,
    input  wire [16:0] addr,
    output reg  [3:0]  pix_idx
);

    (* rom_style = "block" *) reg [3:0] memory [0:76799];

    initial begin
        $readmemh("Title_index.mem", memory);
    end

    always @(posedge clk) begin
        pix_idx <= memory[addr];
    end

endmodule