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
// Minor changes for stereo by Ivan Gorodetsky
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
module audio_io(oAUD_BCK,
				oAUD_DATA,
				oAUD_LRCK,
				iAUD_ADCDAT,
				oAUD_ADCLRCK,
				iCLK_18_4,
				iRST_N,
				pulsesL,
				pulsesR,
				linein);				

parameter	REF_CLK			=	18432000;	//	18.432	MHz
parameter	SAMPLE_RATE		=	48000;		//	48		KHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel

//	Audio Side
output			oAUD_DATA;
output			oAUD_LRCK;
output	reg		oAUD_BCK;
input			iAUD_ADCDAT;
output			oAUD_ADCLRCK;
//	Control Signals
input			iCLK_18_4;
input			iRST_N;
input	[15:0]	pulsesL;
input	[15:0]	pulsesR;
output	[15:0]	linein;

//	Internal Registers and Wires
reg		[3:0]	BCK_DIV;
reg		[8:0]	LRCK_1X_DIV;
reg		[4:0]	SEL_Cont;

reg				LRCK_1X;

////////////	AUD_BCK Generator	//////////////
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
	if(!iRST_N)	begin
		BCK_DIV		<=	0;
		oAUD_BCK	<=	0;
	end
	else begin
		if(BCK_DIV >= REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1 )
		begin
			BCK_DIV		<=	0;
			oAUD_BCK	<=	~oAUD_BCK;
		end
		else
			BCK_DIV		<=	BCK_DIV + 1'd1;
	end
end
//////////////////////////////////////////////////
////////////	AUD_LRCK Generator	//////////////
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
	if(!iRST_N)	begin
		LRCK_1X_DIV	<=	0;
		LRCK_1X		<=	0;
	end
	else begin
		//	LRCK 1X
		if(LRCK_1X_DIV >= REF_CLK/(SAMPLE_RATE*2)-1 ) begin
			LRCK_1X_DIV	<=	0;
			LRCK_1X	<=	~LRCK_1X;
		end	else
			LRCK_1X_DIV		<=	LRCK_1X_DIV+1'd1;
	end
end

assign	oAUD_LRCK	=	LRCK_1X;
assign 	oAUD_ADCLRCK=	oAUD_LRCK;

//////////////////////////////////////////////////
//////////	16 Bits PISO MSB First	//////////////
always@(negedge oAUD_BCK or negedge iRST_N)
begin
	if(!iRST_N)
		SEL_Cont	<=	0;
	else
		SEL_Cont	<=	SEL_Cont+1'd1;
end


reg [31:0] pulsebuf;
always @(negedge LRCK_1X) begin
	pulsebuf[15:0] <= pulsesL;//L
	pulsebuf[31:16] <= pulsesR;//R
end

assign	oAUD_DATA	=	pulsebuf[~SEL_Cont];

assign linein = inputsample;
reg [15:0] inputsample;
reg [15:0] inputbuf;
always @(negedge oAUD_BCK) begin
	inputbuf[~SEL_Cont[3:0]] <= iAUD_ADCDAT;
end

always @(negedge LRCK_1X) begin
	inputsample <= inputbuf;
end

endmodule
								
// $Id$			
					
