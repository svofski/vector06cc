module oneshot(clk, ce, trigger, q);
parameter CLOCKS = 8'd16;
input 		clk;
input 		ce;
input 		trigger;
output reg 	q;

reg [7:0] n_shot;
always @(posedge clk) begin
	if (ce) begin
		if (trigger) begin
			if (n_shot == 8'd0) begin 
				q <= 1;
			end
		end
		else n_shot <= 8'd0;
		
		if (q) n_shot <= n_shot + 1'b1;
		if (n_shot == CLOCKS) q <= 1'b0;
	end
end
endmodule
