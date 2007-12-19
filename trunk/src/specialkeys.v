`default_nettype none

module specialkeys(clk, cpu_ce, reset_n, key_blksbr, key_bushold, o_disable_rom, o_blksbr_reset, o_bushold);
input 		clk;
input		cpu_ce;
input		reset_n;
input		key_blksbr;
input		key_bushold;
output	reg	o_disable_rom;
output		o_blksbr_reset;
output	reg	o_bushold;

// BLK+SBR
reg		rst0toggle = 0;
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		o_disable_rom <= 0;
		rst0toggle <= 0;
	end
	else begin
		if (key_blksbr) begin
			o_disable_rom <= 1;
			rst0toggle <= 1;
		end
		else rst0toggle <= 0;
	end 
end

oneshot blksbr(clk, cpu_ce, rst0toggle, o_blksbr_reset);


// BUS HOLD: ScrollLock
reg key_bushold_x = 0;
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		o_bushold <= 0;
		key_bushold_x <= 0;
	end 
	else begin
		key_bushold_x <= key_bushold;
		if (key_bushold & ~key_bushold_x) 
			o_bushold <= ~o_bushold;
	end
end


endmodule
