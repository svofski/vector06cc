// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, https://caglrc.cc
//
// Design File: clockster.v
//
// Vector-06C clock generator for Tang Nano 9K board.
//
// --------------------------------------------------------------------

`default_nettype wire

module clockster(
    input  clk27,
    output clk24,       // main system clock
    output clk120,      // hdmi x5 clock
    output clkAudio,
    output clk_psram,   // psram 72mhz
    output clk_psram_p, // psram 72mhz second phase
    output ce12,
    output ce6,
    output ce6x,
    output ce3,
    output ce3f2,
    output video_slice,
    output pipe_ab,
    output ce1m5);


reg[5:0] ctr;
reg[4:0] initctr;

reg qce12, qce6, qce6x, qce3, qce3f2, qvideo_slice, qpipe_ab, qce1m5;

assign clkAudio = qce12;
assign ce12 = qce12;
assign ce6 = qce6;
assign ce6x = qce6x;
assign ce3 = qce3;
assign ce3f2 = qce3f2;
assign video_slice = qvideo_slice;
assign pipe_ab = qpipe_ab;
assign ce1m5 = qce1m5;

wire clk120, pll_lock120;

Gowin_rPLL120 your_momma120(
    .clkout(clk120),
    .clkin(clk27),
    .lock(pll_lock120));

Gowin_CLKDIV5 clk120to24(
    .clkout(clk24),
    .hclkin(clk120),
    .resetn(pll_lock120));

Gowin_rPLL72 your_momma2(
    .clkout(clk_psram),   //output clkout
    .clkoutp(clk_psram_p), //output clkoutp
    .clkin(clk27) //input clkin
);

always @(posedge clk24) begin
    if (initctr != 3) begin
        initctr <= initctr + 1'b1;
    end // latch
    else begin
        qpipe_ab <= ctr[5];                 // pipe a/b 2x slower
        qce12 <= ctr[0];                    // pixel push @12mhz
        qce6 <= ctr[1] & ctr[0];            // pixel push @6mhz
        qce6x <= ctr[1] & ~ctr[0];          // pre-pixel push @6mhz

        // 1 1 0
        // 1 1 1
        qce3 <= ctr[2] & ctr[1] & !ctr[0]; //00100000 - svofski
        qce3f2 <= ctr[2] & ctr[1] & ctr[0];

        qvideo_slice <= !ctr[2];
        qce1m5 <= !ctr[3] & ctr[2] & ctr[1] & !ctr[0];
        ctr <= ctr + 1'b1;
    end
end

endmodule
