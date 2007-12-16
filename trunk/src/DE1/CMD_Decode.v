//Legal Notice: (C)2006 Altera Corporation. All rights reserved. Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

// Modifications (C) 2007 by Viacheslav Slavinsky
// Removed everything not related to SRAM interface, latched SRAM data

module CMD_Decode(	//	USB JTAG
					iRXD_DATA,oTXD_DATA,iRXD_Ready,iTXD_Done,oTXD_Start,
					//	SRAM
					oSR_DATA,iSR_DATA,oSR_ADDR,oSR_WE_N,oSR_OE_N, f_SRAM,
					//	Control
					iCLK,iRST_n	);
//	USB JTAG
input [7:0] iRXD_DATA;
input iRXD_Ready,iTXD_Done;
output [7:0] oTXD_DATA;
output oTXD_Start;
//	SRAM
input	[15:0]	iSR_DATA;
output	reg [15:0]	oSR_DATA;
output	reg	[17:0]	oSR_ADDR;
output	oSR_WE_N,oSR_OE_N;
output 	f_SRAM;
//	Control
input iCLK,iRST_n;

//	Internal Register
reg [63:0] 	CMD_Tmp;
reg [2:0] 	mSR_ST;

//	SRAM Control Register
reg	mSR_WRn,mSR_Start;

//	Active Flag
reg f_SETUP, f_SR_SEL;
reg	f_SRAM;

//	USB JTAG TXD Output
reg oSR_TXD_Start;
reg [7:0] oSR_TXD_DATA;
//	TXD Output Select Register
reg sel_FL,sel_SDR,sel_PS2,sel_SR;

`include "RS232_Command.h"

wire [7:0]	CMD_Action	=	CMD_Tmp[63:56];
wire [7:0]	CMD_Target	=	CMD_Tmp[55:48];
wire [23:0]	CMD_ADDR	=	CMD_Tmp[47:24];
wire [15:0]	CMD_DATA	=	CMD_Tmp[23: 8];
wire [7:0]	CMD_MODE	=	CMD_Tmp[ 7: 0];
wire [7:0] 	Pre_Target	=	CMD_Tmp[47:40];


reg  [15:0]	sram_idata_latch;

/////////////////////////////////////////////////////////
////////////////	 SRAM Select	/////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
	if(!iRST_n)
	begin
		//oSR_Select	<=0;
		f_SR_SEL	<=0;
	end
	else
	begin
		if(iRXD_Ready && (Pre_Target == SRSEL) )
		f_SR_SEL<=1;
		if(f_SR_SEL)
		begin
			if( (CMD_Action	== SETUP) && (CMD_MODE	== OUTSEL) && 
				(CMD_ADDR == 24'h123456) )
			//oSR_Select<=CMD_DATA[1:0];
			f_SR_SEL<=0;
		end
	end
end
/////////////////////////////////////////////////////////
/////////////////	TXD	Output Select		/////////////
always@(posedge iCLK or negedge iRST_n)
begin
	if(!iRST_n)
	begin
		sel_SR<=0;
		f_SETUP<=0;
	end
	else
	begin
		if(iRXD_Ready && (Pre_Target == SET_REG) )
		f_SETUP<=1;
		if(f_SETUP)
		begin
			if( (CMD_Action	== SETUP) && (CMD_MODE	== OUTSEL) &&
				(CMD_ADDR == 24'h123456) )
			begin
				case(CMD_DATA[7:0])
				SRAM:	begin
							//sel_FL	<=0;
							//sel_SDR	<=0;
							//sel_PS2	<=0;
							sel_SR	<=1;
						end
				endcase
			end
			f_SETUP<=0;
		end
	end
end
assign oTXD_Start	= 	oSR_TXD_Start;
assign oTXD_DATA	=	oSR_TXD_DATA;

/////////////////////////////////////////////////////////
///////		Shift Register For Command Temp	/////////////
always@(posedge iCLK or negedge iRST_n)
begin
	if(!iRST_n)
	CMD_Tmp<=0;
	else
	begin
		if(iRXD_Ready)
		CMD_Tmp<={CMD_Tmp[55:0],iRXD_DATA};
	end
end

/////////////////////////////////////////////////////////
////////////////	SRAM Control	/////////////////////
always@(posedge iCLK or negedge iRST_n)
begin
	if(!iRST_n)
	begin
		oSR_TXD_Start	<=0;
		mSR_WRn			<=0;
		mSR_Start		<=0;
		f_SRAM			<=0;
		mSR_ST			<=0;
	end
	else
	begin
		if( CMD_Action == READ )
		mSR_WRn	<=	1'b0;
		else if( CMD_Action == WRITE )
		mSR_WRn	<=	1'b1;
		
		if(iRXD_Ready && (Pre_Target == SRAM))
		f_SRAM<=1;
		if(f_SRAM)
		begin
			case(mSR_ST)
			0:	begin
					if( (CMD_MODE	== NORMAL) && (CMD_Target == SRAM) )
					begin
						oSR_ADDR	<=	CMD_ADDR;
						oSR_DATA	<=	CMD_DATA;
						mSR_Start	<= 	1;
						mSR_ST		<=	1;
					end
					else
					begin
						mSR_ST	<=	0;
						f_SRAM	<=	0;
					end
				end
			1:	begin
					if(mSR_WRn == 1'b0) begin
						mSR_ST	<=	2;
						sram_idata_latch <= iSR_DATA;		// +svo latch the SRAM data
					end 
					else
					begin
						mSR_ST	<=	0;
						f_SRAM	<=	0;							
						mSR_Start	<=	0;
					end
				end
			2:	begin
					oSR_TXD_DATA	<= 	sram_idata_latch[7:0];//iSR_DATA[7:0];
					oSR_TXD_Start	<=	1;
					mSR_ST			<=	3;
				end
			3:	begin
					if(iTXD_Done)
					begin
						oSR_TXD_Start<=0;
						mSR_ST	<=	4;
					end											
				end
			4:	begin
					oSR_TXD_DATA	<= 	sram_idata_latch[15:8];//iSR_DATA[15:8];
					oSR_TXD_Start	<=	1;
					mSR_ST			<=	5;
				end
			5:	begin
					if(iTXD_Done)
					begin
						mSR_Start	<=	0;
						oSR_TXD_Start<=	0;
						mSR_ST		<=	0;
						f_SRAM		<=	0;
					end				
				end
			endcase
		end
	end
end

assign	oSR_OE_N	=	~(~mSR_WRn & mSR_Start );
assign	oSR_WE_N	=	~( mSR_WRn & mSR_Start );


endmodule

// $Id$