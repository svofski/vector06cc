module oneshot(clk, ce, trigger, q);
parameter CLOCKS = 8'd16;
input 		clk;
input 		ce;
input 		trigger;
output reg 	q;

reg [7:0] n_shot;
reg trigsample;

always @(posedge clk) begin
	if (ce) begin
		trigsample <= trigger;
		if (~trigsample & trigger) begin
			q <= 1'b1;
			n_shot <= CLOCKS;
		end else begin
			if (q) n_shot <= n_shot - 1'b1;
			if (n_shot == 0) q <= 1'b0;
		end
	end
end
endmodule

// $Id$
