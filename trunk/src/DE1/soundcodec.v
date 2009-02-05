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
// Design File: soundcodec.v
//
// Audio interface between raw audio pulses from 8253, tape i/o and
// sound codec. Includes simple moving average filter for all but
// tape signals.
//
// --------------------------------------------------------------------

`default_nettype none

module soundcodec(clk18, pulses, pcm, tapein, reset_n, oAUD_XCK, oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK);
input	clk18;
input	[3:0] pulses;
input	[7:0] pcm;
output	reg tapein;
input	reset_n;
output	oAUD_XCK = clk18;
output	oAUD_BCK;
output	oAUD_DATA;
output	oAUD_LRCK;
input	iAUD_ADCDAT;
output	oAUD_ADCLRCK;

parameter HYST = 4;

reg [7:0] decimator;
always @(posedge clk18) decimator <= decimator + 1'd1;

wire ma_ce = decimator == 0;


wire [15:0] linein;			// comes from codec
reg [15:0] ma_pulse;		// goes to codec

reg [7:0] pulses_sample[0:3];

// sample * 16
wire [5:0] m04 = {pulses[0], 4'b0};
wire [5:0] m14 = {pulses[1], 4'b0};
wire [5:0] m24 = {pulses[2], 4'b0};
wire [5:0] m34 = {pulses[3], 4'b0};

reg [7:0] sum;

always @(posedge clk18) begin
	if (ma_ce) begin
		pulses_sample[3] <= pulses_sample[2];
		pulses_sample[2] <= pulses_sample[1];
		pulses_sample[1] <= pulses_sample[0];
		pulses_sample[0] <= m04 + m14 + m24/* + m34*/;
		sum <= pulses_sample[0] + pulses_sample[1] + pulses_sample[2] + pulses_sample[3];
	end

	ma_pulse <= {sum[7:2], 7'b0} + {m34,8'b0} + {pcm,5'b0};
	
end

audio_io audioio(oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK, clk18, reset_n, ma_pulse, linein);		

reg [15:0] level_avg;
reg [7:0] lowest;
reg [7:0] highest;
reg [7:0] abs_low;
reg [7:0] abs_high;

wire [7:0] line8in = {~linein[15],linein[14:8]};    // shift signed value to be withing 0..255 range, 128 is midpoint

always @(posedge clk18) begin
    if (line8in < 128+HYST) tapein <= 1'b0;
    if (line8in > 128-HYST) tapein <= 1'b1; 
end

endmodule

// $Id$