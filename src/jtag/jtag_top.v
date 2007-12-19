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
// Design File: jtag_top.v
//
// A toplevel module of JTAG framework. 
// Converts JTAG signals into signals useful in sram_map.v
// Instantiates Altera DE1-specific modules from DE1 directory. 
// This module can be re-written to adopt any hardware.
// --------------------------------------------------------------------


`default_nettype none

module jtag_top(clk24, reset_n, oHOLD, iHLDA, iTCK, oTDO, iTDI, iTCS, oJTAG_ADDR, iJTAG_DATA_TO_HOST, oJTAG_DATA_FROM_HOST, oJTAG_SRAM_WR_N, oJTAG_SELECT);
input	clk24;
input	reset_n;

output 	oHOLD;
input	iHLDA;

input	iTCK;
output	oTDO;
input	iTDI;
input	iTCS;

output	[17:0]	oJTAG_ADDR;
input	[15:0]	iJTAG_DATA_TO_HOST;
output	[15:0]	oJTAG_DATA_FROM_HOST;
output			oJTAG_SRAM_WR_N;
output			oJTAG_SELECT;

`ifdef WITH_DE1_JTAG

CLK_LOCK 			p0	(	.inclk(iTCK),.outclk(mTCK)	);

//	USB JTAG
wire [7:0] mRXD_DATA,mTXD_DATA;
wire mRXD_Ready,mTXD_Done,mTXD_Start;
wire mTCK;

USB_JTAG			u1	(	//	HOST
							.iTxD_DATA(mTXD_DATA),
							.oTxD_Done(mTXD_Done),
							.iTxD_Start(mTXD_Start),
							.oRxD_DATA(mRXD_DATA),
							.oRxD_Ready(mRXD_Ready),
							.iRST_n(reset_n),
							.iCLK(clk24),
							// raw JTAG
							.TDO(oTDO),.TDI(iTDI),.TCS(iTCS),.TCK(mTCK)	);

CMD_Decode				u5	(	//	USB JTAG
							.iRXD_DATA(mRXD_DATA),
							.iRXD_Ready(mRXD_Ready),
						 	.oTXD_DATA(mTXD_DATA),
							.oTXD_Start(mTXD_Start),
							.iTXD_Done(mTXD_Done),
							//	SRAM
							.iSR_DATA(iJTAG_DATA_TO_HOST),
							.oSR_DATA(oJTAG_DATA_FROM_HOST),
							.oSR_ADDR(oJTAG_ADDR),
							.oSR_WE_N(oJTAG_SRAM_WR_N),
							.oJTAG_SEL(oJTAG_SELECT),
							//	Control
						 	.iCLK(clk24),
							.iRST_n(reset_n),
							.oHOLD(oHOLD),
							.iHLDA(iHLDA));
`else
assign 	mJTAG_ADDR		=	18'b0;
assign	mJTAG_DATA_TO_HOST =16'bZ;
assign 	mJTAG_DATA_FROM_HOST=16'b0;
assign 	mJTAG_SELECT 	= 	1'b0;
assign 	mJTAG_SRAM_WR_N = 	1'b1;
`endif						
						
endmodule

// $Id$