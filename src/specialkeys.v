`default_nettype none

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
// Design File: specialkeys.v
//
// Handler of 
//		BLK+SBR (F12, reset with boot rom jettisoned)
//		HOLD	ScrollLock, bus hold trigger
// --------------------------------------------------------------------


module specialkeys(clk, cpu_ce, reset_n, key_blksbr, key_osd, osd_command, o_disable_rom, o_blksbr_reset, o_osd);
input 		clk;
input		cpu_ce;
input		reset_n;
input		key_blksbr;
input		key_osd;
input [7:0] osd_command;		// {F11,F12,HOLD}
output	reg	o_disable_rom;
output		o_blksbr_reset;
output	reg	o_osd;

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


// ScrollLock
reg key_osd_x = 0;
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		o_osd <= 0;
		key_osd_x <= 0;
	end 
	else begin
		key_osd_x <= key_osd;
		if (key_osd & ~key_osd_x) 
			o_osd <= ~o_osd;
	end
end


endmodule
