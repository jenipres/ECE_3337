`timescale 1ns / 1ps

module side_block_pair #(
    parameter [9:0] HALF        = 10'd20,
    parameter [9:0] Y_LOW       = 10'd458, // jump over
    parameter [9:0] Y_HIGH      = 10'd418, // crouch timing lane
    parameter [9:0] X_LEFT_SPAWN  = 10'd0,
    parameter [9:0] X_RIGHT_SPAWN = 10'd639
)(
    input  wire       pixel_clk,
    input  wire       game_tick,
    input  wire       game_over,
    input  wire       reset,
    input  wire [9:0] side_step,

    output reg        low_active,
    output reg  [9:0] low_x,
    output reg  [9:0] low_y,
    output reg        low_move_left,

    output reg        high_active,
    output reg  [9:0] high_x,
    output reg  [9:0] high_y,
    output reg        high_move_left
);

    localparam [9:0] X_MAX = 10'd639;

    // 16-bit LFSR for random event choice, side, and delays
    reg [15:0] lfsr = 16'hA5C3;
    wire fb = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

    // cooldown timers before next spawn
    reg [7:0] low_cd  = 8'd50;
    reg [7:0] high_cd = 8'd90;

    // queued combo event
    reg       queued_valid = 1'b0;
    reg       queued_is_high = 1'b0;
    reg [7:0] queued_delay = 8'd0;
    reg       queued_dir = 1'b0;

    // helper: spawn from left or right
    task spawn_low;
        input dir_in; // 0 = from left moving right, 1 = from right moving left
        begin
            low_active    <= 1'b1;
            low_move_left <= dir_in;
            low_y         <= Y_LOW;
            if (dir_in)
                low_x <= X_RIGHT_SPAWN;
            else
                low_x <= X_LEFT_SPAWN;
        end
    endtask

    task spawn_high;
        input dir_in; // 0 = from left moving right, 1 = from right moving left
        begin
            high_active    <= 1'b1;
            high_move_left <= dir_in;
            high_y         <= Y_HIGH;
            if (dir_in)
                high_x <= X_RIGHT_SPAWN;
            else
                high_x <= X_LEFT_SPAWN;
        end
    endtask

    always @(posedge pixel_clk) begin
        if (reset) begin
            lfsr <= 16'hA5C3;

            low_active    <= 1'b0;
            low_x         <= 10'd0;
            low_y         <= Y_LOW;
            low_move_left <= 1'b0;

            high_active    <= 1'b0;
            high_x         <= 10'd0;
            high_y         <= Y_HIGH;
            high_move_left <= 1'b1;

            low_cd  <= 8'd50;
            high_cd <= 8'd90;

            queued_valid   <= 1'b0;
            queued_is_high <= 1'b0;
            queued_delay   <= 8'd0;
            queued_dir     <= 1'b0;
        end
        else if (game_tick && !game_over) begin
            lfsr <= {lfsr[14:0], fb};

            // -----------------------------
            // Move LOW hazard
            // -----------------------------
            if (low_active) begin
                if (!low_move_left) begin
                    if (low_x > (X_MAX + HALF - side_step))
                        low_active <= 1'b0;
                    else
                        low_x <= low_x + side_step;
                end
                else begin
                    if (low_x < side_step)
                        low_active <= 1'b0;
                    else
                        low_x <= low_x - side_step;
                end
            end

            // -----------------------------
            // Move HIGH hazard
            // -----------------------------
            if (high_active) begin
                if (!high_move_left) begin
                    if (high_x > (X_MAX + HALF - side_step))
                        high_active <= 1'b0;
                    else
                        high_x <= high_x + side_step;
                end
                else begin
                    if (high_x < side_step)
                        high_active <= 1'b0;
                    else
                        high_x <= high_x - side_step;
                end
            end

            // -----------------------------
            // Count down cooldowns
            // -----------------------------
            if (low_cd != 0)
                low_cd <= low_cd - 1'b1;

            if (high_cd != 0)
                high_cd <= high_cd - 1'b1;

            // -----------------------------
            // Fire queued combo second event
            // -----------------------------
            if (queued_valid) begin
                if (queued_delay != 0) begin
                    queued_delay <= queued_delay - 1'b1;
                end
                else begin
                    if (queued_is_high) begin
                        if (!high_active)
                            spawn_high(queued_dir);
                    end
                    else begin
                        if (!low_active)
                            spawn_low(queued_dir);
                    end
                    queued_valid <= 1'b0;
                end
            end

            // -----------------------------
            // Random event generator
            // only starts when no queued event pending
            // -----------------------------
            if (!queued_valid) begin
                // 4 event types:
                // 00 = low only
                // 01 = high only
                // 10 = low then high
                // 11 = high then low

                if (!low_active && !high_active && (low_cd == 0) && (high_cd == 0)) begin
                    case (lfsr[1:0])
                        2'b00: begin
                            spawn_low(lfsr[2]);
                            low_cd  <= 8'd35 + {4'd0, lfsr[7:4]};   // 35..50
                            high_cd <= 8'd25 + {4'd0, lfsr[11:8]};  // 25..40
                        end

                        2'b01: begin
                            spawn_high(lfsr[3]);
                            low_cd  <= 8'd25 + {4'd0, lfsr[7:4]};
                            high_cd <= 8'd35 + {4'd0, lfsr[11:8]};
                        end

                        2'b10: begin
                            spawn_low(lfsr[4]);
                            queued_valid   <= 1'b1;
                            queued_is_high <= 1'b1;
                            queued_delay   <= 8'd10 + {4'd0, lfsr[9:6]}; // 10..25 ticks later
                            queued_dir     <= lfsr[5];

                            low_cd  <= 8'd45 + {4'd0, lfsr[13:10]};
                            high_cd <= 8'd45 + {4'd0, lfsr[15:12]};
                        end

                        default: begin
                            spawn_high(lfsr[6]);
                            queued_valid   <= 1'b1;
                            queued_is_high <= 1'b0;
                            queued_delay   <= 8'd10 + {4'd0, lfsr[11:8]}; // 10..25 ticks later
                            queued_dir     <= lfsr[7];

                            low_cd  <= 8'd45 + {4'd0, lfsr[13:10]};
                            high_cd <= 8'd45 + {4'd0, lfsr[15:12]};
                        end
                    endcase
                end
                else begin
                    // allow solo spawns when only one lane is available
                    if (!low_active && (low_cd == 0) && !high_active && lfsr[8]) begin
                        spawn_low(lfsr[9]);
                        low_cd <= 8'd30 + {4'd0, lfsr[13:10]};
                    end

                    if (!high_active && (high_cd == 0) && !low_active && !lfsr[8]) begin
                        spawn_high(lfsr[10]);
                        high_cd <= 8'd30 + {4'd0, lfsr[15:12]};
                    end
                end
            end
        end
    end

endmodule
