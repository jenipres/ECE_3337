`timescale 1ns / 1ps

module Font_ROM(
    input  wire       clk,
    input  wire [7:0] ch,
    input  wire [2:0] row,
    output reg  [7:0] bits
);

    wire [10:0] addr = {ch, row};

    (* ram_style = "block" *)
    reg [7:0] mem [0:2047];

    initial begin
        $readmemh("font.mem", mem);
    end

    function [7:0] glyph_override;
        input [7:0] ch_in;
        input [2:0] row_in;
        begin
            case (ch_in)

                // A
                "A": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h18;
                        3'd1: glyph_override = 8'h3C;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h66;
                        3'd4: glyph_override = 8'h7E;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h66;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // B
                "B": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h7C;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h7C;
                        3'd4: glyph_override = 8'h66;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h7C;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // F
                "F": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h7E;
                        3'd1: glyph_override = 8'h60;
                        3'd2: glyph_override = 8'h60;
                        3'd3: glyph_override = 8'h7C;
                        3'd4: glyph_override = 8'h60;
                        3'd5: glyph_override = 8'h60;
                        3'd6: glyph_override = 8'h60;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // G
                "G": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h3C;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h60;
                        3'd3: glyph_override = 8'h6E;
                        3'd4: glyph_override = 8'h66;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h3C;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // H
                "H": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h66;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h7E;
                        3'd4: glyph_override = 8'h66;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h66;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // J
                "J": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h1E;
                        3'd1: glyph_override = 8'h0C;
                        3'd2: glyph_override = 8'h0C;
                        3'd3: glyph_override = 8'h0C;
                        3'd4: glyph_override = 8'h0C;
                        3'd5: glyph_override = 8'h6C;
                        3'd6: glyph_override = 8'h38;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // K
                "K": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h66;
                        3'd1: glyph_override = 8'h6C;
                        3'd2: glyph_override = 8'h78;
                        3'd3: glyph_override = 8'h70;
                        3'd4: glyph_override = 8'h78;
                        3'd5: glyph_override = 8'h6C;
                        3'd6: glyph_override = 8'h66;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // L
                "L": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h60;
                        3'd1: glyph_override = 8'h60;
                        3'd2: glyph_override = 8'h60;
                        3'd3: glyph_override = 8'h60;
                        3'd4: glyph_override = 8'h60;
                        3'd5: glyph_override = 8'h60;
                        3'd6: glyph_override = 8'h7E;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // M
                "M": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h63;
                        3'd1: glyph_override = 8'h77;
                        3'd2: glyph_override = 8'h7F;
                        3'd3: glyph_override = 8'h6B;
                        3'd4: glyph_override = 8'h63;
                        3'd5: glyph_override = 8'h63;
                        3'd6: glyph_override = 8'h63;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // N
                "N": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h66;
                        3'd1: glyph_override = 8'h76;
                        3'd2: glyph_override = 8'h7E;
                        3'd3: glyph_override = 8'h7E;
                        3'd4: glyph_override = 8'h6E;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h66;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // P
                "P": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h7C;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h7C;
                        3'd4: glyph_override = 8'h60;
                        3'd5: glyph_override = 8'h60;
                        3'd6: glyph_override = 8'h60;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // Q
                "Q": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h3C;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h66;
                        3'd4: glyph_override = 8'h6E;
                        3'd5: glyph_override = 8'h3C;
                        3'd6: glyph_override = 8'h0E;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // T
                "T": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h7E;
                        3'd1: glyph_override = 8'h5A;
                        3'd2: glyph_override = 8'h18;
                        3'd3: glyph_override = 8'h18;
                        3'd4: glyph_override = 8'h18;
                        3'd5: glyph_override = 8'h18;
                        3'd6: glyph_override = 8'h3C;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // V
                "V": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h66;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h66;
                        3'd3: glyph_override = 8'h66;
                        3'd4: glyph_override = 8'h66;
                        3'd5: glyph_override = 8'h3C;
                        3'd6: glyph_override = 8'h18;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // W
                "W": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h63;
                        3'd1: glyph_override = 8'h63;
                        3'd2: glyph_override = 8'h63;
                        3'd3: glyph_override = 8'h6B;
                        3'd4: glyph_override = 8'h7F;
                        3'd5: glyph_override = 8'h77;
                        3'd6: glyph_override = 8'h63;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // X
                "X": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h66;
                        3'd1: glyph_override = 8'h66;
                        3'd2: glyph_override = 8'h3C;
                        3'd3: glyph_override = 8'h18;
                        3'd4: glyph_override = 8'h3C;
                        3'd5: glyph_override = 8'h66;
                        3'd6: glyph_override = 8'h66;
                        default: glyph_override = 8'h00;
                    endcase
                end

                // Z
                "Z": begin
                    case (row_in)
                        3'd0: glyph_override = 8'h7E;
                        3'd1: glyph_override = 8'h06;
                        3'd2: glyph_override = 8'h0C;
                        3'd3: glyph_override = 8'h18;
                        3'd4: glyph_override = 8'h30;
                        3'd5: glyph_override = 8'h60;
                        3'd6: glyph_override = 8'h7E;
                        default: glyph_override = 8'h00;
                    endcase
                end

                default: glyph_override = 8'h00;
            endcase
        end
    endfunction

    wire mem_blank = (mem[addr] == 8'h00);

    always @(posedge clk) begin
        if (mem_blank)
            bits <= glyph_override(ch, row);
        else
            bits <= mem[addr];
    end

endmodule