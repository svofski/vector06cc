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
// Design File: clockster.v
//
// Vector-06C clock generator.
//
// --------------------------------------------------------------------

`default_nettype none

module clockster(clk, clk50, clk24, clk18, clk14, ce12, ce6, ce3, ce3v, video_slice, pipe_ab, ce1m5);
input  [1:0] 	clk;
input			clk50;
output clk24;
output clk18;
output clk14;
output ce12 = qce12;
output ce6 = qce6;
output ce3 = qce3;
output ce3v = qce3v;
output video_slice = qvideo_slice;
output pipe_ab = qpipe_ab;
output ce1m5 = qce1m5;

reg[5:0] ctr;
reg[4:0] initctr;
//wire[4:0] ctr_2 = ctr - 4;

reg qce12, qce6, qce3, qce3v, qvideo_slice, qpipe_ab, qce1m5;

wire lock;
wire clk13_93;
wire clk14_00;

mclk24mhz vector_quartz(clk[0], clk24, clk18, clk13_93, lock);


`ifdef TWO_PLL_OK
assign clk14 = clk14_00;
mclk14mhz ay_quartz(.inclk0(clk50), .c0(clk14_00));
`else
assign clk14 = clk13_93;
`endif

always @(posedge clk24) begin
	if (initctr != 3) begin
		initctr <= initctr + 1'b1;
	end // latch
	else begin
		qpipe_ab <= ctr[5]; 				// pipe a/b 2x slower
		qce12 <= ctr[0]; 					// pixel push @12mhz
		qce6 <= ctr[1] & ctr[0];			// pixel push @6mhz
		qce3 <= ctr[2] & !ctr[1] & ctr[0];
		qce3v <= ctr[2] & ctr[1] & !ctr[0];
		qvideo_slice <= !ctr[2];
		qce1m5 <= ctr[3] & ctr[2] & !ctr[1] & ctr[0];
		ctr <= ctr + 1'b1;
	end
end
endmodule

// $Id$
