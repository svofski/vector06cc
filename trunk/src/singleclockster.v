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
// Design File: singleclockster.v
//
// Generate single CPU clocks for key-tapped code execution.
//
// --------------------------------------------------------------------

`default_nettype none

module singleclockster(clk24, singleclock_enabled, n_key, singleclock);
input 		clk24;
input 		singleclock_enabled;
input 		n_key;
output reg 	singleclock;

reg key1_nreleased;
always @(posedge clk24) begin
	if (singleclock_enabled) begin
		if (n_key == 1'b0) begin
			if (!key1_nreleased) begin
				singleclock <= 1;
				key1_nreleased <= 1;
			end
		end
		else key1_nreleased <= 0;
		
		if (singleclock) singleclock <= 0;
	end
end

endmodule

// $Id$
