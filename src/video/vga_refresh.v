// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 				  Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: vga_refresh.v
//
// VGA refresh signals generator. Also takes care of retrace, bordery, 
// videoActive signals and row counter for framebuffer/scan doubler.
//
// This version simulates a rather strange PAL mode with only 624
// lines. The original computer sacrificed standard compliance to allow
// some simplification and had 2x312 line scan instead of 312/313
// alternation.
//
// --------------------------------------------------------------------

`default_nettype none

module vga_refresh(clk24, hsync, vsync, videoActive, bordery, retrace, video_scroll_reg, fb_row, fb_row_count, tvhs, tvvs, tvx, tvy);
input			clk24;
output			hsync;
output			vsync;
output			videoActive;
output	reg		bordery;
output 			retrace;
input	[7:0]	video_scroll_reg;
output	[8:0]	fb_row;
output  [8:0]	fb_row_count;
output			tvhs, tvvs;
output  [9:0]	tvx,tvy;

// total = 624
// visible = (16 + 256 + 16)*2 = 288*2 = 576
// rest = 624-576 = 48

parameter SCREENWIDTH = 10'd640;	
parameter SCREENHEIGHT = 10'd576;
parameter VISIBLEHEIGHT = SCREENHEIGHT - 2*2*16;
parameter SCROLLLOAD_X = 112;	// when on line 0 scroll register is copied into the line counter

reg videoActiveX;			// 1 == X is within visible area
reg videoActiveY;			// 1 == Y is within visible area
wire videoActive = videoActiveX & videoActiveY;

assign retrace = !videoActiveY;
assign hsync = !(scanxx_state == state2);
assign vsync = !(scanyy_state == state2);

//assign tvhs = !((tvx > (0)) && (tvx < (96)));
assign tvhs = !(tvx > 800-96);
//assign tvvs = !(tvy < 6);
assign tvvs = !(tvy == 623 && tvx == 800-96);

reg[9:0] tvx;
reg[9:0] tvy;

reg[9:0] realx;  
reg[9:0] realy;

reg[2:0] scanxx_state;		// x-machine state
reg[2:0] scanyy_state;		// y-machine state
reg[9:0] scanxx;			// x-state timer/counter
reg[9:0] scanyy;			// y-state timer/counter

//
// framebuffer variables
//
reg [8:0] fb_row;			// fb row
reg [8:0] fb_row_count;



parameter state0 = 3'b000, state1 = 3'b001, state2 = 3'b010, state3 = 3'b011, state4 = 3'b100, state5 = 3'b101, state6 = 3'b110, state7 = 3'b111;

always @(posedge clk24) begin
		if (scanyy == 0) begin 
			case (scanyy_state)
			state0:
					begin
						scanyy <= 10'd21;
						scanyy_state <= state1;
						bordery <= 0;
						tvy <= 0;
						videoActiveY <= 0;
					end
			state1: // VSYNC
					begin
						scanyy <= 10'd5;
						scanyy_state <= state2;
					end
			state2: // BACK PORCH + TOP BORDER
					begin
						scanyy <= 10'd22;
						scanyy_state <= state3;
					end
			state3:
					begin
						scanyy <= 10'd32; // 16 * 2: top and bottom borders
						videoActiveY <= 1;
						realy <= 0;
						bordery <= 1;
						scanyy_state <= state4;
					end
			state4:
					begin
						scanyy <= VISIBLEHEIGHT;
						bordery <= 0;
						scanyy_state <= state5;
					end
			state5:
					begin
						//fb_row <= 1;
						scanyy <= 2 * (8'd16);
						bordery <= 1;
						scanyy_state <= state0;
					end
			default:
					begin
						scanyy_state <= state0;
					end
			endcase
		end 
		
		if (scanxx == 0) begin	
			case (scanxx_state) 
			state0: // enter FRONT PORCH + LEFT BORDER
					begin 
						scanxx <= 10'd11 - 1'b1;
						scanyy <= scanyy - 1'b1;

						scanxx_state <= state1;
						videoActiveX <= 1'b0;

						realy <= realy + 1'b1;
				
						fb_row <= fb_row - 1'b1;
						if (fb_row_count != 0) begin
							fb_row_count <= fb_row_count - 1'b1;
						end 
												
						tvx <= 0;
					end
			state1: // enter HSYNC PULSE
					begin 
						scanxx <= 10'd56 - 1'b1; 
						scanxx_state <= state2;
					end
			state2:	// enter BACK PORCH + RIGHT BORDER
					begin
						scanxx <= 10'd60;
						scanxx_state <= state3;
					end
			state3:	// enter VISIBLE AREA
					begin
						videoActiveX <= 1'b1;
						realx <= 9'b0;
						scanxx <= SCREENWIDTH - 1'b1 - 1'b1; // borrow one from state4
						scanxx_state <= state4;
					end
			state4:
					begin
						scanxx_state <= state0;
					end
			default: 
					begin
						scanxx_state <= state0;
					end
			endcase
		end 
		else scanxx <= scanxx - 1'b1;

		// load scroll register at this precise moment
		if (scanyy_state == state5 && realx == SCROLLLOAD_X && scanyy == VISIBLEHEIGHT) begin
			fb_row <= {video_scroll_reg, 1'b1};
			fb_row_count <= 511;
		end
		
		if (videoActiveX) begin
			realx <= realx + 1'b1;
		end
		
		if (scanxx_state == state0) 
			tvx <= 0;
		else 
			tvx <= tvx + 1;
			
		if (scanxx_state == state0) begin
			tvy <= tvy + 1;
		end
		
end

endmodule

// $Id$