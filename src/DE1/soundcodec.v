// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 				 Copyright (C) 2007,2008 Viacheslav Slavinsky
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
// --------------------------------------------------------------------

`default_nettype none

module soundcodec(clk12,
						pulses,
						ay_soundA,ay_soundB,ay_soundC,
						rs_soundA,rs_soundB,rs_soundC,
						covox,
						tapein, reset_n, oAUD_XCK, oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK);
input	clk12;
input	[3:0] pulses;
input	[7:0] ay_soundA;
input	[7:0] ay_soundB;
input	[7:0] ay_soundC;
input	[7:0] rs_soundA;
input	[7:0] rs_soundB;
input	[7:0] rs_soundC;
input	[7:0] covox;
output	reg tapein;
input	reset_n;
output	oAUD_XCK = clk12;
output	oAUD_BCK;
output	oAUD_DATA;
output	oAUD_LRCK;
input	iAUD_ADCDAT;
output	oAUD_ADCLRCK;

parameter HYST = 4;

reg [7:0] decimator;
always @(posedge clk12) decimator <= decimator + 1'd1;

wire ma_ce = decimator == 0;


wire [15:0] linein;			// comes from codec
reg [15:0] ma_pulseL,ma_pulseR;		// goes to codec

reg [7:0] pulses_sample[0:3];

// sample * 16
wire [5:0] m04 = {pulses[0], 4'b0};
wire [5:0] m14 = {pulses[1], 4'b0};
wire [5:0] m24 = {pulses[2], 4'b0};
wire [5:0] m34 = {pulses[3], 4'b0};

reg [7:0] sum;

always @(posedge clk12) begin
	if (ma_ce) begin
		pulses_sample[3] <= pulses_sample[2];
		pulses_sample[2] <= pulses_sample[1];
		pulses_sample[1] <= pulses_sample[0];
		pulses_sample[0] <= m04 + m14 + m24/* + m34*/;
		sum <= pulses_sample[0] + pulses_sample[1] + pulses_sample[2] + pulses_sample[3];
	end
	ma_pulseL <= {sum[7:2],7'b0}+{m34,8'b0}+{ay_soundC,4'b0}+{ay_soundB,3'b0}+{rs_soundC,4'b0}+{rs_soundB,3'b0}+{covox,4'b0};
	ma_pulseR <= {sum[7:2],7'b0}+{m34,8'b0}+{ay_soundA,4'b0}+{ay_soundB,3'b0}+{rs_soundA,4'b0}+{rs_soundB,3'b0}+{covox,4'b0};
end

audio_io audioio(oAUD_BCK,oAUD_DATA,oAUD_LRCK,iAUD_ADCDAT,oAUD_ADCLRCK,clk12,reset_n,
						{~ma_pulseL[15],ma_pulseL[14:0]},
						{~ma_pulseR[15],ma_pulseR[14:0]},
						linein);

wire [7:0] line8in = {~linein[15],linein[14:8]};    // shift signed value to be withing 0..255 range, 128 is midpoint
always @(posedge clk12) begin
    if (line8in < 128+HYST) tapein <= 1'b0;
    if (line8in > 128-HYST) tapein <= 1'b1; 
end

endmodule