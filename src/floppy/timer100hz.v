//`default_nettype none
// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: timer100hz.v
//
// A simple tick-tock timer with async load. 
// Used as a peripheral for the floppy CPU.
//
// --------------------------------------------------------------------

module timer100hz(clk, di, wren, q);
parameter MCLKFREQ = 24000000;

input 			clk;
input [7:0]		di;
input			wren;
output reg[7:0]	q;

reg [17:0] timerctr;

wire hz100 = timerctr == 0;

always @(posedge clk) begin
	if (timerctr == 0) 
		timerctr <= MCLKFREQ/100;
	else
		timerctr <= timerctr - 1'b1;
end

always @(posedge clk) begin
	if (wren) begin
		q <= di;
                $display("timer100hz wr q<=%d", di);
	end 
	else if (q != 0 && hz100) q <= q - 1'b1;
end

endmodule

