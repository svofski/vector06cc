// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
//
// Modified by Ivan Gorodetsky
// 
// Design File: soundcodec.v
//
// Audio interface between raw audio pulses from 8253, tape i/o and
// sound codec. Includes simple moving average filter for all but
// tape signals.
//
// This is a version for boards that have no audio codec. WXEDA board.
//
// Sigma-Delta modulated output on o_pwm
//
// --------------------------------------------------------------------

`default_nettype none

module soundcodec(clk24,
        pulses,
        ay_soundA,ay_soundB,ay_soundC,
        rs_soundA,rs_soundB,rs_soundC,
        covox,
        tapein, reset_n,
        o_adc_clk, o_adc_cs_n, i_adc_data_in,
        o_pwm);
input   clk24;
input   [3:0] pulses;
input   [7:0] ay_soundA;
input   [7:0] ay_soundB;
input   [7:0] ay_soundC;
input   [7:0] rs_soundA;
input   [7:0] rs_soundB;
input   [7:0] rs_soundC;
input   [7:0] covox;
output  reg tapein;
input   reset_n;

output  o_adc_clk;
output  o_adc_cs_n;
input   i_adc_data_in;

output reg o_pwm;

parameter HYST = 4;
parameter PWM_WIDTH = 9;

//                    o +5V (from USB)
//                    |
//                    | /
//                    o||  8 Ohm PC 
//                    o||  Speaker
//                    | \
//                  |/
//  o----[ R27 ] -- |    2N3904
//                  |\,
//                    |
//                    |
//                   ---
//                    -
//
// at 2:0 2N3904 runs quite hot when playing music through 8-ohm PC speaker, but its loud and nice
//    3:0 it gets some time to chill, but the quality/loudness is worse
reg [2:0] divctr;
always @(posedge clk24)
    divctr <= divctr + 1'b1;
wire delta_sigma_ce = divctr == 0;

wire [2:0] beepsum = {pulses[0] + pulses[1] + pulses[2] + {2{pulses[3]}}}; 
wire [9:0] aysum = ay_soundA + ay_soundB + ay_soundC;

wire [15:0] mixed = {beepsum, 13'b0} + {aysum, 5'b0};

wire [7:0] line8in;
tlc549c adc(.clk24(clk24), .adc_data_in(i_adc_data_in), .adc_data(line8in), .adc_clk(o_adc_clk), .adc_cs_n(o_adc_cs_n));

always @(posedge clk24) begin 
    if (line8in < 128+HYST) tapein <= 1'b0;
    if (line8in > 128-HYST) tapein <= 1'b1; 
end

reg [PWM_WIDTH:0] delta_sigma_accu;
   
always @(posedge clk24)  
    if (delta_sigma_ce)
        delta_sigma_accu <= delta_sigma_accu[PWM_WIDTH - 1:0] + mixed[15:15 - (PWM_WIDTH - 1)];
  
always
    o_pwm <= delta_sigma_accu[PWM_WIDTH];
  
endmodule
