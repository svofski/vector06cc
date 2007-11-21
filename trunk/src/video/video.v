`default_nettype none

module video(
	clk24, 		// latched clocks
	ce12,		// 12mhz
	video_slice,
	pipe_ab,
 
	mode512,
	
	SRAM_DQ,	// SRAM data bus (input)
	SRAM_ADDR,	// SRAM address, output

	hsync, 
	vsync, 
	videoActive, 
	coloridx,
	border,
	retrace,
    video_scroll_reg,
	testpin
);

parameter SCREENWIDTH = 10'd640;	// constants, don't even try using other values
//parameter SCREENHEIGHT = 10'd600;
parameter SCREENHEIGHT = 10'd584;//10'd576;

// input clocks
input 			clk24;
input 			ce12;
input 			video_slice;
input 			pipe_ab;

input 			mode512;			// 1 for 512x256 video mode

// RAM access
input [7:0] 	SRAM_DQ;
output[15:0]	SRAM_ADDR;

// video outputs
output 			hsync;
output 			vsync;
output 			videoActive;
output [3:0] 	coloridx;
output 			border;
output 			retrace;

input  [7:0]	video_scroll_reg;

// test pins
output [1:0] 	testpin;

reg[9:0] realx;  
reg[9:0] realy;

reg[2:0] scanxx_state;		// x-machine state
reg[2:0] scanyy_state;		// y-machine state
reg[9:0] scanxx;			// x-state timer/counter
reg[9:0] scanyy;			// y-state timer/counter

reg bordery;
wire borderx;
assign border = bordery | borderx;

reg videoActiveX;			// 1 == X is within visible area
reg videoActiveY;			// 1 == Y is within visible area
wire videoActive = videoActiveX & videoActiveY;
wire retrace = !videoActiveY;
reg pre_xstart, pre_xend;

parameter state0 = 3'b000, state1 = 3'b001, state2 = 3'b010, state3 = 3'b011, state4 = 3'b100;

assign hsync = !(scanxx_state == state2);
assign vsync = !(scanyy_state == state2);


reg scanyy_minus;			// todo: investigate if this is still necessary


//
// framebuffer variables
//

//wire [7:0] vertical_scroll_offset = 8'hff;
reg [8:0] fb_row;			// fb row
reg [8:0] fb_row_count;

always @(posedge clk24) begin
		if (scanyy == 0) begin 
			case (scanyy_state)
			state0:
					begin
						scanyy <= 1 + 24 - 8 + 24 - 14;
						scanyy_state <= state1;
						videoActiveY <= 0;
					end
			state1: // HSYNC
					begin
						scanyy <= 5;
						scanyy_state <= state2;
					end
			state2: // BACK PORCH + TOP BORDER
					begin
						scanyy <= 19;
						scanyy_state <= state3;
					end
			state3:
					begin
						scanyy <= SCREENHEIGHT + 14;
						scanyy_state <= state0;
						videoActiveY <= 1;
						realy <= 0;
					end
			default:
					begin
						scanyy_state <= state0;
					end
			endcase
		end 
		else if (scanyy_minus) begin
			scanyy_minus <= 1'b0;
			scanyy <= scanyy - 1'b1;
		end

		if (scanxx == 0) begin	
			case (scanxx_state) 
			state0: // enter FRONT PORCH + LEFT BORDER
					begin 
						// here, commented out is time correction for different clock rate
						//scanxx <= 10'd11 /*+ 10'd74*/ - 1'b1;		
						scanxx <= 10'd11 - 1'b1;
						scanxx_state <= state1;
						scanyy_minus <= 1'b1;
						videoActiveX <= 1'b0;
						realy <= realy + 1'b1;
						fb_row <= fb_row - 1'b1;
						if (fb_row_count != 0) begin
							fb_row_count <= fb_row_count - 1'b1;
						end 
							else bordery <= 1;
					end
			state1: // enter HSYNC PULSE
					begin 
						//scanxx <= 10'd56 - 1'b1; 
						scanxx <= 10'd56 - 1'b1; 
						scanxx_state <= state2;
					end
			state2:	// enter BACK PORCH + RIGHT BORDER
					begin
						scanxx <= 10'd61 - 1'b1 - 32;
						scanxx_state <= state3;
					end
			state3:	// enter VISIBLE AREA
					begin
						pre_xstart <= 1'b1;
						videoActiveX <= 1'b1;
						realx <= 9'b0;
						scanxx <= SCREENWIDTH - 1'b1 - 1'b1; // borrow one from state4
						scanxx_state <= state4;
					end
			state4:
					begin
						pre_xend <= 1'b1;
						//scanxx <= 0;
						scanxx_state <= state0;
					end
			default: 
					begin
						scanxx_state <= state0;
					end
			endcase
		end 
		else scanxx <= scanxx - 1'b1;
		
		if (pre_xstart != 0) pre_xstart <= pre_xstart - 1'b1;
		if (pre_xend != 0) pre_xend <= pre_xend - 1'b1;

		if (videoActiveX) begin
			realx <= realx + 1'b1;
		end
		
		if (realy == 32) begin
			fb_row <= {video_scroll_reg, 1'b1};
			fb_row_count <= 511;
			bordery <= 0;
		end
end

wire [3:0] coloridx_modeless;
framebuffer winrar(clk24, ce12, video_slice, pipe_ab, fb_row[8:1], hsync, SRAM_DQ, SRAM_ADDR, coloridx_modeless, borderx, testpin);

reg [3:0] coloridx;
always @(coloridx_modeless or clk24) begin
	if (mode512) begin
		if (ce12)
			coloridx <= {2'b00, coloridx_modeless[2], coloridx_modeless[3]};
		else
			coloridx <= {2'b00, coloridx_modeless[1], coloridx_modeless[0]};
	end
	else
		coloridx <= coloridx_modeless;
end
	
endmodule


////////////////////////////////////////////////////////////////////////////




// $Id$
