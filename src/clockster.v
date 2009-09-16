// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 				  Copyright (C) 2007-2009 Viacheslav Slavinsky
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

module clockster(clk, clk50, clk24, clk18, clk14, ce12, ce6, ce3, ce3v, video_slice, pipe_ab, ce1m5, clkpalFSC);
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
output clkpalFSC;

reg[5:0] ctr;
reg[4:0] initctr;

reg qce12, qce6, qce3, qce3v, qvideo_slice, qpipe_ab, qce1m5;

wire lock;
wire clk13_93;
wire clk14_00;
wire clk14_xx;

wire clk300x;
wire clk300;
wire clk70k9;

wire clk30;
wire clk28;

mclk24mhz vector_xtal(clk50, clk24, clk300, clk28, lock);

// Derive clock for PAL subcarrier: 4x 4.43361875
`define PHACC_WIDTH 32
`define PHACC_DELTA 253896634 

reg [`PHACC_WIDTH-1:0] pal_phase;
wire [`PHACC_WIDTH-1:0] pal_phase_next;
assign pal_phase_next = pal_phase + `PHACC_DELTA;
reg palclkreg;

always @(posedge clk300) begin
	pal_phase <= pal_phase_next;
end

ayclkdrv clkbufpalfsc(pal_phase[`PHACC_WIDTH-1], clkpalFSC);

// Make codec 18MHz
`define COPHACC_DELTA 15729
reg [15:0] cophacc;
wire [15:0] cophacc_next = cophacc + `COPHACC_DELTA;
always @(posedge clk300) cophacc <= cophacc_next;

ayclkdrv clkbuf18mhz(cophacc[15], clk18);


// phase accu doesn't work for AY, why?
//
// Make AY 14MHz 
//`define AYPHACC_DELTA 12233
//reg [15:0] ayphacc;
//wire [15:0] ayphacc_next = ayphacc + `AYPHACC_DELTA;
//always @(posedge clk300) ayphacc <= ayphacc_next;
//
//ayclkdrv clkbuf14mhz(ayphacc[15], clk14_xx);

reg[5:0] div300by21;
assign clk14 = clk14_xx; // 300/21 = 14.3MHz
always @(posedge clk300) begin
	div300by21 <= div300by21 + 1'b1;
	if (div300by21+1'b1 == 21) div300by21 <= 0;
end
ayclkdrv clkbuf14mhz(div300by21[4], clk14_xx);


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
