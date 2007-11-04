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
