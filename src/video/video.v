`default_nettype none

module video(
	clk24, 		// latched clocks
	ce12,		// 12mhz
	ce6,
	video_slice,
	pipe_ab,
 
	mode512,
	
	SRAM_DQ,	// SRAM data bus (input)
	SRAM_ADDR,	// SRAM address, output

	hsync, 
	vsync, 
	videoActive, 
	coloridx,
	realcolor_in,
	realcolor_out,
	retrace,
    video_scroll_reg,
	border_idx,
	testpin
);

parameter SCREENWIDTH = 10'd640;	// constants, don't even try using other values
//parameter SCREENHEIGHT = 10'd600;
parameter SCREENHEIGHT = 10'd584;

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
output 			videoActive;
output [3:0] 	coloridx;
input  [7:0]	realcolor_in;
output [7:0]	realcolor_out;
//output 			border;
output 			retrace;

input  [7:0]	video_scroll_reg;
input  [3:0]	border_idx;

// test pins
output [3:0] 	testpin;

reg[9:0] realx;  
reg[9:0] realy;

reg[2:0] scanxx_state;		// x-machine state
reg[2:0] scanyy_state;		// y-machine state
reg[9:0] scanxx;			// x-state timer/counter
reg[9:0] scanyy;			// y-state timer/counter

reg bordery;
wire borderx;
wire border;

reg videoActiveX;			// 1 == X is within visible area
reg videoActiveY;			// 1 == Y is within visible area
wire videoActive = videoActiveX & videoActiveY;

assign retrace = !videoActiveY;

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
`ifdef x800x600					
						scanyy <= 27;
`else
						scanyy <= 17 - 0;
`endif						
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
						scanyy <= 19 - 4;
						scanyy_state <= state3;
					end
			state3:
					begin
`ifdef x800x600					
						scanyy <= SCREENHEIGHT + 14;
`else
						scanyy <= SCREENHEIGHT + 4;
`endif						
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
							
						if (realy == 42) begin
							fb_row <= {video_scroll_reg, 1'b1};
							fb_row_count <= 511;
							bordery <= 0;
						end else if (realy == 0) begin
							fb_row <= 1;
						end
						
							
					end
			state1: // enter HSYNC PULSE
					begin 
						//scanxx <= 10'd56 - 1'b1; 
						scanxx <= 10'd56 - 1'b1; 
						scanxx_state <= state2;
					end
			state2:	// enter BACK PORCH + RIGHT BORDER
					begin
`ifdef x800x600					
						scanxx <= 10'd61 - 1'b1 - 32;
`else
						scanxx <= 10'd61 - 1'b1;
`endif						
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
		
end

wire [3:0] coloridx_modeless;

assign border = bordery | borderx;

framebuffer winrar(clk24, 
`ifdef DOUBLE_BUFFER
	ce6,
`else
	ce12, 
`endif
	video_slice, pipe_ab, fb_row[8:0], hsync, SRAM_DQ, SRAM_ADDR, coloridx_modeless, borderx/*, testpin*/);

reg [3:0] xcoloridx;

always @(coloridx_modeless or clk24) begin
	if (mode512) begin
		if (
`ifdef DOUBLE_BUFFER
		ce6
`else		
		ce12
`endif		
		)
			xcoloridx <= {2'b00, coloridx_modeless[2], coloridx_modeless[3]};
		else
			xcoloridx <= {2'b00, coloridx_modeless[1], coloridx_modeless[0]};
	end
	else
		xcoloridx <= coloridx_modeless;
end

`ifdef DOUBLE_BUFFER

wire [7:0] rc_a;
wire [7:0] rc_b;

wire wren_line1 = fb_row[1];
wire wren_line2 = ~fb_row[1];

reg reset_line;

always @(posedge clk24) begin
	reset_line <= fb_row[0] & !hsync;
end

assign testpin = {reset_line, wren_line1, reset_line, mode512};

rambuffer #(4)line1(.clk(clk24),
				.cerd(1),
				.cewr(ce12),
				.wren(wren_line1),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_a)
				);
				
rambuffer #(8)line2(.clk(clk24),
				.cerd(1),
				.cewr(ce12),
				.wren(wren_line2),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_b)
				);
				
//assign coloridx = wren_line1 ? ci_b : ci_a;
assign coloridx = border ? border_idx : xcoloridx;
//assign coloridx = border ? border_idx : border_idx;
assign realcolor_out = wren_line1 ? rc_b : rc_a;
`else

assign coloridx = xcoloridx;

`endif

	
endmodule


////////////////////////////////////////////////////////////////////////////




// $Id$
