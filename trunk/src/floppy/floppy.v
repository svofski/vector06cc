`default_nettype none

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
// Design File: floppy.v
//
// Floppy drive emulation toplevel
//
// --------------------------------------------------------------------

module floppy(clk, ce, reset_n, addr, idata, odata, memwr_n, sd_dat, sd_dat3, sd_cmd, sd_clk);
input			clk;
input			ce;
input			reset_n;
output	[15:0]	addr = cpu_a;
input	[7:0]	idata;
output	[7:0]	odata = cpu_do;
output			memwr_n;
inout			sd_dat;
inout			sd_dat3;
inout			sd_cmd;
output			sd_clk;

assign	sd_dat3 = 1'b1;

wire ready = 1'b1;
wire cpu_m1_n;
wire cpu_mreq_n;
wire cpu_iorq_n;
wire cpu_rd_n;
wire cpu_wr_n;
wire cpu_halt_n;

wire [15:0] cpu_a;
wire [7:0]	cpu_di = idata;
wire [7:0]	cpu_do;

T80sef cpushnik(
	.RESET_n(reset_n),
	.CLK_n(clk),
	.CLKEN(ce),
	.WAIT_n(ready),
	.INT_n(1'b1),
	.NMI_n(1'b1),
	.BUSRQ_n(1'b1),
	.M1_n(cpu_m1_n),
	.MREQ_n(cpu_mreq_n),
	.IORQ_n(cpu_iorq_n),
	.RD_n(cpu_rd_n),
	.WR_n(cpu_wr_n),
	.HALT_n(cpu_halt_n),
	.A(cpu_a),
	.DI(cpu_di),
	.DO(cpu_do)
	);

endmodule
