module clockster(clk, clk24, clk18, ce12, ce6, ce3, ce3v, video_slice, pipe_ab, ce1m5);
input clk;
output clk24;
output clk18;
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
mclk24mhz vector_quartz(clk, clk24, clk18, lock);

always @(posedge clk24) begin
	if (initctr != 3) begin
		initctr <= initctr + 1'b1;
	end // latch
	else begin
`ifdef DOUBLE_BUFFER	
		qpipe_ab <= ctr[5]; 				// pipe a/b 2x slower
`else
		qpipe_ab <= ctr[4]; 
`endif		
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
