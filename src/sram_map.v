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
// Design File: sram_map.v
//
// Maps linear 64K x 8 address space into 32K x 16 address space 
//
// --------------------------------------------------------------------

`default_nettype none

module sram_map(SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N, memwr_n, abus, dout, din, ramdisk_page, 
				jtag_addr, jtag_din, jtag_do, jtag_jtag, jtag_nwe);
output [17:0] 	SRAM_ADDR;
inout  reg[15:0] 	SRAM_DQ;
output 			SRAM_WE_N;
output 			SRAM_UB_N;
output 			SRAM_LB_N;
input			memwr_n;
input  [15:0]	abus;
input  [7:0]	dout;
output [7:0]	din;
input  [2:0]	ramdisk_page;

input	[17:0]	jtag_addr;
input	[15:0]	jtag_din;
output	[15:0]	jtag_do = SRAM_DQ;//16'hc3e0;//
input			jtag_jtag;
input			jtag_nwe;

assign SRAM_ADDR = jtag_jtag ? jtag_addr : {ramdisk_page, abus[15:1]};
assign SRAM_UB_N = jtag_jtag ? 1'b0 : ~abus[0];
assign SRAM_LB_N = jtag_jtag ? 1'b0 : abus[0];
assign SRAM_WE_N = jtag_jtag ? jtag_nwe : memwr_n;

always 
	if (jtag_jtag & ~jtag_nwe) 
		SRAM_DQ[15:0] <= jtag_din;
	else if (~memwr_n)
		SRAM_DQ[15:0] <= abus[0] ? {dout, 8'bZZZZZZZZ} : {8'bZZZZZZZZ, dout};
	else
		SRAM_DQ[15:0] <= 16'bZZZZZZZZZZZZZZZZ;
	
assign din = abus[0] ? SRAM_DQ[15:8] : SRAM_DQ[7:0];

endmodule

// $Id$