// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
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
// Tang Nano 9K version.
//
// Sigma-Delta modulated stereo output on o_pwm[1:0]
//
// --------------------------------------------------------------------

//`default_nettype wire

module soundcodec(
    input   clk24,
    input   [3:0] pulses,
    input   [7:0] ay_soundA,
    input   [7:0] ay_soundB,
    input   [7:0] ay_soundC,
    input   [7:0] rs_soundA,
    input   [7:0] rs_soundB,
    input   [7:0] rs_soundC,
    input   [7:0] covox,
    output  reg tapein,
    input   reset_n,

    output reg [1:0] o_pwm,

    output  oAUD_MCLK,
    output  oAUD_BCK,
    output  oAUD_DACDAT,
    output  oAUD_LRCK,
    input   iAUD_ADCDAT);

parameter HYST = 4;
parameter PWM_WIDTH = 9;

// -------------------------------------
// I2S interface
// -------------------------------------

reg [8:0] decimator;
always @(posedge clk24) decimator <= decimator + 1'd1;

wire ma_ce = decimator == 0;

wire clk12rip = decimator[0] == 0;

assign oAUD_MCLK = clk12rip;

wire [15:0] linein;			// comes from codec
reg [15:0] ma_pulseL,ma_pulseR;		// goes to codec

//reg [7:0] pulses_sample[0:3];

// 8x2[4]
reg [15:0] timer_hist[0:3];
reg [8:0] sumL, sumR;

// sample * 16
wire [5:0] m04 = {pulses[0], 4'b0};   // timer ch0
wire [5:0] m14 = {pulses[1], 4'b0};   // timer ch1
wire [5:0] m24 = {pulses[2], 4'b0};   // timer ch2
wire [5:0] m34 = {pulses[3], 4'b0};   // beeper

reg [7:0] sum;

wire [7:0] timerL = {pulses[2],4'b0} + {pulses[1],3'b0} + {pulses[3], 4'b0};
wire [7:0] timerR = {pulses[0],4'b0} + {pulses[1],3'b0} + {pulses[3], 4'b0};


always @(posedge clk24) begin
	if (ma_ce)
    begin
        timer_hist[3] <= timer_hist[2];
        timer_hist[2] <= timer_hist[1];
        timer_hist[1] <= timer_hist[0];
        timer_hist[0] <= {timerL, timerR};


		//pulses_sample[3] <= pulses_sample[2];
		//pulses_sample[2] <= pulses_sample[1];
		//pulses_sample[1] <= pulses_sample[0];
		//pulses_sample[0] <= m04 + m14 + m24/* + m34*/;
		//sum <= pulses_sample[0] + pulses_sample[1] + pulses_sample[2] + pulses_sample[3];

        sumL <= timer_hist[0][15:8] + timer_hist[1][15:8] + timer_hist[2][15:8] + timer_hist[3][15:8];
        sumR <= timer_hist[0][7:0]  + timer_hist[1][7:0]  + timer_hist[2][7:0]  + timer_hist[3][7:0];
	end

	ma_pulseL <= {sumL,7'b0}
            + {ay_soundC,5'b0} + {ay_soundB,4'b0}
            + {rs_soundC,5'b0} + {rs_soundB,4'b0}
            + {covox,4'b0};
	ma_pulseR <= {sumR,7'b0}
            + {ay_soundA,5'b0} + {ay_soundB,4'b0}
            + {rs_soundA,5'b0} + {rs_soundB,4'b0}
            + {covox,4'b0};
	//ma_pulseL <= {sum[7:1],6'b0}+{m34,7'b0}+{ay_soundC,4'b0}+{ay_soundB,3'b0}+{rs_soundC,4'b0}+{rs_soundB,3'b0}+{covox,4'b0};
	//ma_pulseR <= {sum[7:1],6'b0}+{m34,7'b0}+{ay_soundA,4'b0}+{ay_soundB,3'b0}+{rs_soundA,4'b0}+{rs_soundB,3'b0}+{covox,4'b0};
end

audio_io audioio(
    .oAUD_BCK(oAUD_BCK),
    .oAUD_DATA(oAUD_DACDAT),
    .oAUD_LRCK(oAUD_LRCK),
    .iAUD_ADCDAT(iAUD_ADCDAT),
    .iCLK12(clk12rip),
    .iRST_N(reset_n),
    .pulsesL({~ma_pulseL[15],ma_pulseL[14:0]}),
    .pulsesR({~ma_pulseR[15],ma_pulseR[14:0]}),
    .linein(linein));

wire [7:0] line8in = {~linein[15],linein[14:8]};    // shift signed value to be within 0..255 range, 128 is midpoint

always @(posedge clk24) begin
    if (line8in < 128+HYST) tapein <= 1'b0;
    if (line8in > 128-HYST) tapein <= 1'b1; 
end

// PWM output mono/stereojk


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
wire [9:0] rssum = rs_soundA + rs_soundB + rs_soundC;

wire [15:0] mixed[0:1];

wire [15:0] mixed_mono = {beepsum, 13'b0} + 
`ifdef WITH_RSOUND
    {aysum, 4'b0} + {rssum, 4'b0} 
`else
    {aysum, 5'b0}
`endif    
    + {covox, 4'b0};

`ifdef PWM_STEREO
    assign mixed[0] = {~ma_pulseL[15], ma_pulseL[14:0]};
    assign mixed[1] = {~ma_pulseR[15], ma_pulseR[14:0]};
`else
    assign mixed[0] = mixed_mono;
    assign mixed[1] = mixed_mono;
`endif

reg [PWM_WIDTH:0] delta_sigma_accu[0:1];
   
always @(posedge clk24)  
    if (delta_sigma_ce)
    begin
        delta_sigma_accu[0] <= delta_sigma_accu[0][PWM_WIDTH - 1:0] + mixed[0][15:15 - (PWM_WIDTH - 1)];
        delta_sigma_accu[1] <= delta_sigma_accu[1][PWM_WIDTH - 1:0] + mixed[1][15:15 - (PWM_WIDTH - 1)];
    end
  
always @*
begin
    o_pwm[0] <= delta_sigma_accu[0][PWM_WIDTH];
    o_pwm[1] <= delta_sigma_accu[1][PWM_WIDTH];
end


endmodule
