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
// Design File: framebuffer.v
//
// Vector-06C frame buffer. This module accesses bit planes sequentially,
// loads shift registers and shifts out bits by pixel. 
// Originally designed to work at VGA speed, later adopted for 2x slower
// speed of original Vector-06C for compatibility reasons.
//
// This version reads memory 2x more times than necessary.
//
// --------------------------------------------------------------------


`default_nettype none

////
//
// Frame Buffer
//
////
module framebuffer(clk24,ce12,ce_pixel,video_slice,pipe_abx,fb_row,hsync,vdata,vdata2,vdata3,vdata4,SRAM_ADDR,coloridx,borderx,testpin,rdvid);
input 			clk24;
input			ce12;
input 			ce_pixel;
input			video_slice;
input 			pipe_abx;		// pipe selector, should be fed from clockster

input [8:0]	fb_row;

input hsync;

input 	[31:0]	vdata;
input 	[31:0]	vdata2;
input 	[31:0]	vdata3;
input 	[31:0]	vdata4;
output	[15:0]	SRAM_ADDR;

output 	[3:0] 	coloridx;
output 	 		borderx;

output 	[5:0] 	testpin;

output rdvid=wr[0];


reg [3:0] wr;					// pipeline write pulses, derived from ax count

assign testpin[0] = wr[0];
assign testpin[1] = wr[1];
assign testpin[2] = wr[2];
assign testpin[3] = wr[3];
assign testpin[4] = pipe_abx;
assign testpin[5] = video_slice;


reg [4:0] column;				// byte column number

reg [1:0] ax;					// position counter for generating write pulses
									// same as video page number

	
reg [15:0] sram_addr;
wire [15:0] SRAM_ADDR;
assign SRAM_ADDR = sram_addr;

reg [1:0] borderdelay;
reg borderxreg;
assign borderx = borderdelay[0];
always @(posedge clk24) begin
	if (ce_pixel) begin
		borderdelay <= {borderxreg, borderdelay[1]};
	end
end

// enable update on ce12 preceding ce_pixel
wire video_en = video_slice & ce12 & !ce_pixel;

// video_slice occurs 4 times every 8 pixels
// but in SDRAM version it doesn't matter
always @(posedge clk24) begin
	if (video_en) begin
		if (ax == 2'b11) begin 
			if (!hsync & fb_row[0]) begin
				column <= 5'h1A; 
				borderxreg <= 1;
			end
			else column <= column + 1'b1;
			if (column == 0) borderxreg <= ~borderxreg;
		end
		sram_addr <= {1'b1,2'b0,column[4:0],fb_row[8:1]};
		ax <= ax + 1'b1;
		wr[0] <= ax == 2'b00;
		wr[1] <= ax == 2'b01;
		wr[2] <= ax == 2'b10;
		wr[3] <= ax == 2'b11;
	end 
	else begin
		wr <= 4'b0000;
	end
end

pipelinx pipdx_0(clk24, ce_pixel, pipe_abx, wr[3], vdata[7:0], coloridx[3]);
pipelinx pipdx_1(clk24, ce_pixel, pipe_abx, wr[3], vdata[15:8], coloridx[2]);
pipelinx pipdx_2(clk24, ce_pixel, pipe_abx, wr[3], vdata[23:16], coloridx[1]);
pipelinx pipdx_3(clk24, ce_pixel, pipe_abx, wr[3], vdata[31:24], coloridx[0]);


endmodule


////
//
// 2 shift registers, selectable by ab
// writeplz: async load
// clk/ce pushes the data out right
//
////
module pipelinx(clk, ce, ab, writeplz, din, bout);
input clk;
input ce;
input ab;
input writeplz;
input [7:0] din;
output bout;

wire bouta, boutb;
wire n_ab = !ab;
assign bout = ab ? boutb : bouta;	// curent bits of all 4 registers

shiftreg2 pipa(clk, ce & n_ab, din, writeplz & ab,   bouta);
shiftreg2 pipb(clk, ce & ab,   din, writeplz & n_ab, boutb);

endmodule
