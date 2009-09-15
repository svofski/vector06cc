// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007,2008 Viacheslav Slavinsky
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
	
	osd_hsync,
	osd_vsync,
	
	coloridx,			// output: 	palette ram address
	realcolor_in,		// input:  	real colour value
	realcolor_out,		// output: 	real colour value --> vga
	retrace,			// output: 	out of scan area, for interrupt request
    video_scroll_reg,	// input: 	line where display starts
	border_idx,			// input: 	border colour index
	testpin,
	
	clk4fsc,
	tv_sync,
	tv_luma,
	tv_chroma,
	tv_test,
);

parameter V_SYNC = 0;
parameter V_REF  = 4;

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
output			osd_hsync;
output			osd_vsync;
output [3:0] 	coloridx;
input  [7:0]	realcolor_in;
output [7:0]	realcolor_out;
output 			retrace;

input  [7:0]	video_scroll_reg;
input  [3:0]	border_idx;

// tv
input			clk4fsc;
output 			tv_sync;
output reg[7:0] tv_luma;
output reg[7:0]	tv_chroma;
output [7:0]    tv_test;

// test pins
output [3:0] 	testpin;

wire bordery;				// y-border active, from module vga_refresh
wire borderx;				// x-border active, from module framebuffer
wire border = bordery | borderx;				
wire videoActive;

wire	[8:0]	fb_row;
wire	[8:0]	fb_row_count;

wire 			tvhs, tvhs2, tvvs;

assign tvhs = tvhs2 | fb_row[0];

vga_refresh 	refresher(
							.clk24(clk24),
							.hsync(hsync),
							.vsync(vsync),
							.videoActive(videoActive),
							.bordery(bordery),
							.retrace(retrace),
							.video_scroll_reg(video_scroll_reg),
							.fb_row(fb_row),
							.fb_row_count(fb_row_count),
							.tvhs(tvhs2),
							.tvvs(tvvs),
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

always @(negedge clk24) begin
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
				.cerd(1'b1),
				.cewr(ce12),
				.wren(wren_line1),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_a)
				);
				
rambuffer line2(.clk(clk24),
				.cerd(1'b1),
				.cewr(ce12),
				.wren(wren_line2),
				.resetrd(!hsync),
				.resetwr(reset_line),
				.din(realcolor_in),
				.dout(rc_b)
				);
				
// osd
reg	osd_vsync, osd_hsync;

reg 		osd_xdelaybuf;
wire		osd_xdelay;
oneshot	#(10'd128) lineos0(.clk(clk24), .ce(1'b1), .trigger(hsync), .q(osd_xdelay));
always @(posedge clk24) begin
	osd_vsync = ~(fb_row_count == 128);

	osd_xdelaybuf <= osd_xdelay;
	osd_hsync <= ~(osd_xdelaybuf & ~osd_xdelay);
end


// tv

wire [3:0] truecolor_R = {realcolor_in[2:0], 1'b0};
wire [3:0] truecolor_G = {realcolor_in[5:3], 1'b0};
wire [3:0] truecolor_B = {realcolor_in[7:6], 2'b0};

// PAL frame sync
assign tv_sync  = fieldzone ? fieldsync : tvhs_local; // tvvs;

reg [10:0] tv_halfline;
reg [10:0] tv_pixel;
reg [11:0] tv_absel;

wire tvhs_local = ~(tv_absel < 114);

reg tvvs_x;
always @(posedge clk24) begin
	tvvs_x <= tvvs;

	tv_pixel <= tv_pixel + 1;
	
	tv_absel <= tv_absel + 1;
	
	if (tvvs_x & ~tvvs) tv_fieldctr <= tv_fieldctr + 1'b1;

	if (tv_absel + 1 == 768*2 || (tvvs_x & ~tvvs)) tv_absel <= 0;

	if (tv_pixel + 1 == 768 || (tvvs_x & ~tvvs)) tv_pixel <= 0;

	if (tv_pixel + 1 == 768) tv_halfline <= tv_halfline + 1;

	if (tvvs_x & ~tvvs) tv_halfline <= 0;

	tv_blank <= (tv_absel < 249) || (tv_absel > 1536-40) || fieldzone;

	tv_colorburst <= (tv_absel > 114+24 && tv_absel < 114+24+75);

end

wire broadsync_window = tv_pixel < 768-113;
wire narrowsync_window = tv_pixel < 56;
wire normalsync_window = tv_pixel < 114;

reg fieldsync;
reg fieldzone;
always @* begin
	fieldzone <= 1'b1;
	fieldsync <= 1'b1;
	
	if (tv_halfline <= 4) 							fieldsync <= ~broadsync_window;
	else if (tv_halfline <= 9 || tv_halfline >= 618) fieldsync <= ~narrowsync_window;
	else begin
		fieldzone <= 1'b0;
	end
end

wire [4:0] unclamped = V_REF + tvY + tv_chroma;
wire [3:0] clamped = unclamped[4] ? 4'hF : unclamped[3:0];

always @* 
	casex ({tv_sync,tv_colorburst,tv_blank})
	3'b0xx: tv_luma <= V_SYNC;
	3'b111:	tv_luma <= tv_sin[7] ? (V_REF-1) : (V_REF+1); 
	3'b101:	tv_luma <= V_REF;
	default:tv_luma <= clamped; 
	endcase
	
	
always @*
	case ({tv_halfline[1]^tv_fieldctr[0],tv_phase0[1:0]})
	0: 	tv_chroma <= tvUV_0;
	1:	tv_chroma <= tvUV_1;
	2:  tv_chroma <= tvUV_2;
	3:	tv_chroma <= tvUV_3;
	4:	tv_chroma <= tvUW_0;
	5:	tv_chroma <= tvUW_1;
	6:	tv_chroma <= tvUW_2;
	7:	tv_chroma <= tvUW_3;
	endcase

reg [2:0] tv_phase  = 0;
reg [2:0] tv_phase0 = 1;
reg [2:0] tv_fieldctr;

reg 		tv_colorburst;
reg			tv_blank;

always @(posedge clk4fsc) begin
	tv_phase <= tv_phase + 1;
	tv_phase0 <= tv_phase0 + 1;
end	

wire [8:0] tv_sin00;
wire [8:0] tv_sin90;
wire [8:0] tv_sin = tv_halfline[1]^tv_fieldctr[0] ? tv_sin00 : tv_sin90;
sinrom sinA(tv_phase0[1:0], tv_sin00);
sinrom sinB(tv_phase[1:0], tv_sin90);

assign tv_test[0] = tv_sin[7];

wire [7:0] tvY;
wire [13:0] tvY1;
wire [13:0] tvY2;
wire [13:0] tvY3;

wire [13:0] tvUV_0;
wire [13:0] tvUV_1;
wire [13:0] tvUV_2;
wire [13:0] tvUV_3;

wire [13:0] tvUW_0;
wire [13:0] tvUW_1;
wire [13:0] tvUW_2;
wire [13:0] tvUW_3;								   
								   // as per eMSX
assign tvY1 = 8'h18 * truecolor_R; // hex(0.299*(2*0.714*256/3.3)*0.72*16) = $17.D
assign tvY2 = 8'h2f * truecolor_G; // hex(0.587*(2*0.714*256/3.3)*0.72*16) = $2E.D
assign tvY3 = 8'h09 * truecolor_B; // hex(0.114*(2*0.714*256/3.3)*0.72*16) = $09.1

wire [13:0] tvY_ = tvY1 + tvY2 + tvY3;
assign tvY = tvY_[13:7]; // must be in the range 0..9

                      
// -5/-3 is okayest of most
uvsum #( +37,  -3, -33) uvsum0(truecolor_R, truecolor_G, truecolor_B, tvUV_0);
uvsum #( +34, -46, +12) uvsum1(truecolor_R, truecolor_G, truecolor_B, tvUV_1);
uvsum #( -37,  +3, +33) uvsum2(truecolor_R, truecolor_G, truecolor_B, tvUV_2);
uvsum #( -34, +46, -12) uvsum3(truecolor_R, truecolor_G, truecolor_B, tvUV_3);

uvsum #( -34, +46, -12) uwsum1(truecolor_R, truecolor_G, truecolor_B, tvUW_0);
uvsum #( -37,  +3, +33) uwsum2(truecolor_R, truecolor_G, truecolor_B, tvUW_1);
uvsum #( +34, -46, +12) uwsum3(truecolor_R, truecolor_G, truecolor_B, tvUW_2);
uvsum #( +37,  -3, -33) uwsum4(truecolor_R, truecolor_G, truecolor_B, tvUW_3);
endmodule

module uvsum(input[7:0] R, input [7:0] G, input [7:0] B, output [7:0] uvsum);
parameter c1,c2,c3;

wire [13:0] c01 = c1 * R;
wire [13:0] c02 = c2 * G;
wire [13:0] c03 = c3 * B;

assign uvsum = c01[13:7] + c02[13:7] + c03[13:7];

endmodule

module sinrom(input [2:0] adr, output reg [7:0] s); // 4 angles
always @*
	case (adr[1:0])
	0:	s <= 255;
	1:	s <= 255;
	2:	s <= 0;
	3:	s <= 0;
	endcase
endmodule




////////////////////////////////////////////////////////////////////////////




// $Id$
