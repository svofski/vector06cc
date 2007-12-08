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
// Design File: video.v
//
// Video subsystem: 
//		- VGA refresh generator	
//		- frame buffer
//		- scan doubler
// The palette ram is external. coloridx should be connected to
// the palette RAM address bus, realcolor_in must be connected to 
// the palette RAM output.
//
// --------------------------------------------------------------------


`default_nettype none

module video(
	clk24, 				// clock
	ce12,				// 12mhz clock enable for vga-scan (buffer->vga)
	ce6,				// 6mhz  clock enable for pal-scan (ram->buffer)
	video_slice,		// video time slice, not cpu time
	pipe_ab,			// pipe_ab for register pipeline
 
	mode512,			// 1 == 512 pixels/line mode
	
	SRAM_DQ,			// SRAM data bus (input)
	SRAM_ADDR,			// SRAM address, output

	hsync, 				// VGA hsync
	vsync, 				// VGA vsync
	
	coloridx,			// output: 	palette ram address
	realcolor_in,		// input:  	real colour value
	realcolor_out,		// output: 	real colour value --> vga
	retrace,			// output: 	out of scan area, for interrupt request
    video_scroll_reg,	// input: 	line where display starts
	border_idx,			// input: 	border colour index
	testpin
);

// input clocks
input 			clk24;
input 			ce12;
input			ce6;
input 			video_slice;
input 			pipe_ab;

input 			mode512;			// 1 for 512x256 video mode

// RAM access
input [7:0] 	SRAM_DQ;
output[15:0]	SRAM_ADDR;

// video outputs
output 			hsync;
output 			vsync;
output [3:0] 	coloridx;
input  [7:0]	realcolor_in;
output [7:0]	realcolor_out;
output 			retrace;

input  [7:0]	video_scroll_reg;
input  [3:0]	border_idx;

// test pins
output [3:0] 	testpin;

wire bordery;				// y-border active, from module vga_refresh
wire borderx;				// x-border active, from module framebuffer
wire border = bordery | borderx;				
wire videoActive;

wire	[8:0]	fb_row;

vga_refresh 	refresher(
							.clk24(clk24),
							.hsync(hsync),
							.vsync(vsync),
							.videoActive(videoActive),
							.bordery(bordery),
							.retrace(retrace),
							.video_scroll_reg(video_scroll_reg),
							.fb_row(fb_row)
						);


framebuffer 	winrar(
							.clk24(clk24), 
							.ce_pixel(ce6),
							.video_slice(video_slice), .pipe_abx(pipe_ab), 
							.fb_row(fb_row[8:0]), 
							.hsync(hsync), 
							.SRAM_DQ(SRAM_DQ), .SRAM_ADDR(SRAM_ADDR), 
							.coloridx(coloridx_modeless), 
							.borderx(borderx)
						);

reg 	[3:0] xcoloridx;
wire 	[3:0] coloridx_modeless;

always @(coloridx_modeless or clk24) begin
	if (mode512) begin
		if (ce6)
			xcoloridx <= {2'b00, coloridx_modeless[2], coloridx_modeless[3]};
		else
			xcoloridx <= {2'b00, coloridx_modeless[1], coloridx_modeless[0]};
	end
	else
		xcoloridx <= coloridx_modeless;
end

// coloridx is an output port, address of colour in the palette ram
assign coloridx = border ? border_idx : xcoloridx;

// realcolor_out what actually goes to VGA DAC
assign realcolor_out = videoActive ? (wren_line1 ? rc_b : rc_a) : 8'b0;


wire [7:0] rc_a;
wire [7:0] rc_b;

wire wren_line1 = fb_row[1];
wire wren_line2 = ~fb_row[1];

reg reset_line;
always @(posedge clk24) begin
	reset_line <= fb_row[0] & !hsync;
end

assign testpin = {reset_line, wren_line1, reset_line, mode512};

rambuffer line1(.clk(clk24),
				.cerd(1),
				.cewr(ce12),
				.wren(wren_line1),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_a)
				);
				
rambuffer line2(.clk(clk24),
				.cerd(1),
				.cewr(ce12),
				.wren(wren_line2),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_b)
				);
				
endmodule


////////////////////////////////////////////////////////////////////////////




// $Id$
