// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 					Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
//
// Stereo and DSP Mode by Ivan Gorodetsky
// 
// Design File: audio_io.v
//
// Low-level i/o interface to audio codec. 
// Based on development board example:
//
// Legal Notice: (C)2006 Altera Corporation. All rights reserved. Your
// use of Altera Corporation's design tools, logic functions and other
// software and tools, and its AMPP partner logic functions, and any
// output files any of the foregoing (including device programming or
// simulation files), and any associated documentation or information are
// expressly subject to the terms and conditions of the Altera Program
// License Subscription Agreement or other applicable license agreement,
// including, without limitation, that your use is for the sole purpose
// of programming logic devices manufactured by Altera and sold by Altera
// or its authorized distributors.  Please refer to the applicable
// agreement for further details.
//
// --------------------------------------------------------------------
module audio_io(
				oAUD_BCK,
				oAUD_DATA,
				oAUD_LRCK,
				iAUD_ADCDAT,
				oAUD_ADCLRCK,
				iCLK12,
				iRST_N,
				pulsesL,
				pulsesR,
				linein);				

parameter	REF_CLK			=	12000000;	//	12	MHz
parameter	SAMPLE_RATE		=	48000;		//	48		kHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel

//	Audio Side
output			oAUD_DATA;
output			oAUD_LRCK;
output	oAUD_BCK=iCLK12;
input			iAUD_ADCDAT;
output			oAUD_ADCLRCK;
//	Control Signals
input			iCLK12;
input			iRST_N;
input	[15:0]	pulsesL;
input	[15:0]	pulsesR;
output	[15:0]	linein;

//	Internal Registers and Wires
reg		[3:0]	BCK_DIV;
reg		[8:0]	LRCK_1X_DIV;
reg		[5:0]	SEL_Cont;

reg				LRCK_1X;

always@(negedge oAUD_BCK or negedge iRST_N)
begin
	if(!iRST_N)	begin
		LRCK_1X_DIV	<=	0;
		LRCK_1X		<=	0;
	end
	else if(LRCK_1X_DIV>=REF_CLK/SAMPLE_RATE-1) begin
		LRCK_1X_DIV	<=	0;
		LRCK_1X	<=	1;
	end
	else begin
		LRCK_1X_DIV		<=	LRCK_1X_DIV+1'd1;
		LRCK_1X	<=	0;
	end
end


assign	oAUD_LRCK	=	LRCK_1X;
assign 	oAUD_ADCLRCK=	oAUD_LRCK;

//////////////////////////////////////////////////
//////////	16 Bits PISO MSB First	//////////////
always@(negedge oAUD_BCK or negedge iRST_N)
begin
	if(!iRST_N) SEL_Cont	<=	0;
	else if(oAUD_LRCK==1)
		SEL_Cont	<=	0;
	else if(SEL_Cont!=6'd32)
		SEL_Cont	<=	SEL_Cont+1'd1;
end


reg [31:0] pulsebuf;
always @(posedge LRCK_1X) begin
	pulsebuf[15:0] <= pulsesR;//R
	pulsebuf[31:16] <= pulsesL;//L
end

assign	oAUD_DATA	=	pulsebuf[~SEL_Cont];

assign linein = inputsample;
reg [15:0] inputsample;
reg [15:0] inputbuf;
always @(negedge oAUD_BCK) begin
	if(SEL_Cont!=6'd32)inputbuf[~SEL_Cont[3:0]] <= iAUD_ADCDAT;
end

always @(posedge LRCK_1X) begin
	inputsample <= inputbuf;//only one channel
end

endmodule