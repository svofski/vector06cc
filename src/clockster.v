module clockster(clk50mhz, clk24, clk18, ce12, ce3, ce3v, video_slice, pipe_ab, ce1m5);
input clk50mhz;
output clk24;
output clk18;
output ce12 = qce12;
output ce3 = qce3;
output ce3v = qce3v;
output video_slice = qvideo_slice;
output pipe_ab = qpipe_ab;
output ce1m5 = qce1m5;

reg[4:0] ctr;
reg[4:0] initctr;
//wire[4:0] ctr_2 = ctr - 4;

reg qce12, qce3, qce3v, qvideo_slice, qpipe_ab, qce1m5;

wire clk24_90, lock;
mclk24mhz vector_quartz(clk50mhz, clk24, clk18, lock);

always @(posedge clk24) begin
	if (initctr != 3) begin
		initctr <= initctr + 1'b1;
	end // latch
	else begin
		qce12 <= ctr[0];
		qce3 <= ctr[2] & !ctr[1] & ctr[0];
		qce3v <= ctr[2] & ctr[1] & !ctr[0];
		qvideo_slice <= !ctr[2];
		qpipe_ab <= ctr[4];
		qce1m5 <= ctr[3] & ctr[2] & !ctr[1] & ctr[0];
		//qcepipe1 <= !ctr[2] & (clk24 & !ctr[0]);
		//qcepipe2 <= !ctr[2] & (clk24 & ctr[0]);
		ctr <= ctr + 1'b1;
	end
end
endmodule

// $Id$
