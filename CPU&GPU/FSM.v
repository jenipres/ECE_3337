`timescale 1ns / 1ps

module FSM(
    input  wire       clk,
    input  wire       reset,
    input  wire       btnBack,
    input  wire       btnSelect,
    input  wire [1:0] menu_index,
    input  wire       game_over,
    input  wire       name_done,
    output reg  [1:0] state,
    output reg        game_restart
);

    localparam TITLE      = 2'd0;
    localparam SCOREBOARD = 2'd1;
    localparam GAME       = 2'd2;
    localparam NAME_ENTRY = 2'd3;

    reg [1:0] next_state;

    reg btnBack_d, btnSelect_d;
    reg name_entry_select_armed;

    wire btnBack_pulse   = btnBack   & ~btnBack_d;
    wire btnSelect_pulse = btnSelect & ~btnSelect_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state                   <= TITLE;
            btnBack_d               <= 1'b0;
            btnSelect_d             <= 1'b0;
            name_entry_select_armed <= 1'b0;
        end else begin
            state       <= next_state;
            btnBack_d   <= btnBack;
            btnSelect_d <= btnSelect;

            if (state != NAME_ENTRY) begin
                name_entry_select_armed <= 1'b0;
            end else begin
                if (!btnSelect)
                    name_entry_select_armed <= 1'b1;
            end
        end
    end
    
    always @(*) begin
        next_state   = state;
        game_restart = 1'b0;

        case (state)
            TITLE: begin
                if (btnSelect_pulse) begin
                    case (menu_index)
                        2'd0: begin
                            next_state   = GAME;
                            game_restart = 1'b1;
                        end
                        2'd1: next_state = SCOREBOARD;
                        2'd2: next_state = TITLE;
                    endcase
                end
            end

            SCOREBOARD: begin
                if (btnBack_pulse)
                    next_state = TITLE;
            end

            GAME: begin
                if (game_over) begin
                    if (btnSelect_pulse)
                        next_state = NAME_ENTRY;
                end
            end

            NAME_ENTRY: begin
                if (name_entry_select_armed && name_done && btnSelect_pulse)
                    next_state = SCOREBOARD;
            end
        endcase
    end

endmodule