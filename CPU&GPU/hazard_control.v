`timescale 1ns / 1ps

module Hazard_Control(
    input  wire       clk,
    input  wire       reset,
    input  wire       game_tick,

    input  wire       reg_hazard_enable,
    input  wire       reg_hazard_force_spawn,
    input  wire       reg_hazard_burst_enable,
    input  wire       reg_hazard_pattern_override,
    input  wire [2:0] reg_hazard_pattern_id,

    output reg        hazard_enable,
    output reg        hazard_force_spawn_pulse,
    output reg        hazard_burst_enable,
    output reg        hazard_pattern_override,
    output reg  [2:0] hazard_pattern_id
);

    reg force_spawn_d;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hazard_enable           <= 1'b1;
            hazard_force_spawn_pulse<= 1'b0;
            hazard_burst_enable     <= 1'b1;
            hazard_pattern_override <= 1'b0;
            hazard_pattern_id       <= 3'd0;
            force_spawn_d           <= 1'b0;
        end
        else begin
            hazard_enable           <= reg_hazard_enable;
            hazard_burst_enable     <= reg_hazard_burst_enable;
            hazard_pattern_override <= reg_hazard_pattern_override;
            hazard_pattern_id       <= reg_hazard_pattern_id;

            // one pulse when CPU sets the bit
            hazard_force_spawn_pulse <= game_tick && reg_hazard_force_spawn && !force_spawn_d;
            force_spawn_d            <= reg_hazard_force_spawn;
        end
    end

endmodule