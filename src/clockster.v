// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                Copyright (C) 2007-2014 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
//
// Modified by Ivan Gorodetsky
// 
// Design File: clockster.v
//
// Vector-06C clock generator.
//
// --------------------------------------------------------------------

`default_nettype none

module clockster(
						clk50,
						clk24, clkAudio, ce12, ce6, ce6x, ce3, video_slice, pipe_ab, ce1m5, 
						clkpalFSC,
						clk48, clk96,
						clk_color_mod);
input           clk50;
output clk24=clkdiv[3];
output clk48=clkdiv[2];
output clk96=clkdiv[1];
//output clkAudio = qce12;
output clkAudio=aud_phase[23];
output ce12 = qce12;
output ce6 = qce6;
output ce6x = qce6x;
output ce3 = qce3;
output video_slice = qvideo_slice;
output pipe_ab = qpipe_ab;
output ce1m5 = qce1m5;
output clkpalFSC=pal_phase[23];
output clk_color_mod=clk384;

reg[5:0] ctr;
reg[4:0] initctr;

reg qce12, qce6, qce6x, qce3, qce3v, qvideo_slice, qpipe_ab, qce1m5;
wire clk384;

mclk24mhz vector_xtal(clk50, clk384);

// pal*16=70.9379 MHz from 383.3333 MHz
`define PHACC_WIDTH 24
`define PHACC_DELTA 3104715

reg [`PHACC_WIDTH-1:0] pal_phase;
wire [`PHACC_WIDTH-1:0] pal_phase_next;
assign pal_phase_next = pal_phase + `PHACC_DELTA;

reg [3:0] clkdiv;
always @(posedge clk384) begin
    pal_phase <= pal_phase_next;
	 clkdiv<=clkdiv+1;
end

// 12.288 MHz from 383.3333 MHz
`define PHACC_AUD 537805
reg [`PHACC_WIDTH-1:0] aud_phase;
wire [`PHACC_WIDTH-1:0] aud_phase_next;
assign aud_phase_next = aud_phase + `PHACC_AUD;

always @(posedge clk384) begin
    aud_phase <= aud_phase_next;
end

always @(posedge clk24) begin
    if (initctr != 3) begin
        initctr <= initctr + 1'b1;
    end // latch
    else begin
        qpipe_ab <= ctr[5];                 // pipe a/b 2x slower
        qce12 <= ctr[0];                    // pixel push @12mhz
        qce6 <= ctr[1] & ctr[0];            // pixel push @6mhz
        qce6x <= ctr[1] & ~ctr[0];          // pre-pixel push @6mhz

        qce3 <= ctr[2] & ctr[1] & !ctr[0]; //00100000 - svofski

        qvideo_slice <= !ctr[2];
        qce1m5 <= !ctr[3] & ctr[2] & ctr[1] & !ctr[0];
        ctr <= ctr + 1'b1;
    end
end
endmodule
