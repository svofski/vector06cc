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
// Design File: rambuffer.v
//
// One-line RAM buffer for scan doubler.
//
// --------------------------------------------------------------------

`default_nettype none

module rambuffer(clk, cerd, cewr, wren, resetrd, resetwr, din, dout);
	input 		clk;
	input 		cerd;
	input 		cewr;
	input 		wren;
	input 		resetrd;
	input 		resetwr;
	input [7:0] din;
	output reg[7:0] dout;

reg [7:0] pixelram[1023:0];

wire [9:0] rdaddr;
wire [9:0] wraddr;

rdwrctr c1(clk, cerd, resetrd, rdaddr);
rdwrctr c2(clk, cewr, resetwr, wraddr);

wire [9:0] addr = wren ? wraddr : rdaddr;

always @(posedge clk) begin
	if (wren) begin
		pixelram[wraddr] <= din;
	end
	dout <= pixelram[rdaddr];
end

endmodule

module rdwrctr(clk, ce, reset, q);
input clk;
input ce;
input reset;
output [9:0] q;

/*
always @(posedge clk) begin
	if (ce) begin
		if (reset) 
			q <= 0;
		else
			q <= q + 1'b1;
	end
end
*/
lpm_counter ctr(.clock(clk), .clk_en(ce), .aclr(reset), .q(q));
defparam ctr.LPM_WIDTH = 10,
		 ctr.LPM_DIRECTION = "UP";

endmodule

// $Id$