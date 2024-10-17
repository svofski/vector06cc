// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky
// 
// Design File: video.v
//
// Video subsystem: 
//      - VGA refresh generator 
//      - frame buffer
//      - scan doubler
// The palette ram is external. coloridx should be connected to
// the palette RAM address bus, realcolor_in must be connected to 
// the palette RAM output.
//
// --------------------------------------------------------------------


//`default_nettype none

//`define SCAN_2_1  // less BRAM usage
//`define SCAN_5_3    // scale down and skip HSYNC pulses 288 * 5 / 3 = 480
//`define SCAN_7INCH  // scale down by making lcd lines slower, 5 LCD lines per 6 vga lines

module video(
    clk24,               // clock 24mhz
    ce12,               // 12mhz clock enable for vga-scan (buffer->vga)
    ce6,                // 6mhz  clock enable for pal-scan (ram->buffer)
    ce6x,
    reset_n,
    video_slice,        // video time slice, not cpu time
    pipe_ab,            // pipe_ab for register pipeline
 
    mode512,            // 1 == 512 pixels/line mode
    
    vdata,              // video data input [31:0]

    SRAM_ADDR,          // SRAM address, output

    hsync,              // VGA hsync
    vsync,              // VGA vsync

    lcd_clk_o,
    lcd_den_o,
    lcd_hsync_o,           // scaled hsync for 480-line lcd
    lcd_vsync_o,

    
    osd_hsync,
    osd_vsync,
    
    coloridx,           // output:  palette ram address
    realcolor_in,       // input:   real colour value from palette ram
    realcolor_out,      // output:  real colour value --> vga
    bgr555_out,         // output:  bgr 555
    retrace,            // output:  out of scan area, for interrupt request
    video_scroll_reg,   // input:   line where display starts
    border_idx,         // input:   border colour index
    testpin,
    
    clk4fsc,
    tv_mode,
    tv_sync,
    tv_luma,
    tv_chroma_o,
    tv_cvbs,
    tv_test,
    tv_osd_fg,
    tv_osd_bg,
    tv_osd_on,
    rdvid_o
);

parameter V_SYNC = 0;
parameter V_REF  = 8;

// input clocks
input           clk24;
input           ce12;
input           ce6;
input           ce6x;
input           reset_n;
input           video_slice;
input           pipe_ab;

input           mode512;            // 1 for 512x256 video mode

// RAM access
input [31:0]   vdata;
output [15:0]  SRAM_ADDR;

// video outputs
output          hsync;
output          vsync;
output          lcd_clk_o;
output          lcd_den_o;
output          lcd_hsync_o;
output          lcd_vsync_o;

output          osd_hsync;
output          osd_vsync;
output  [3:0]   coloridx;
input   [7:0]   realcolor_in;
output  [7:0]   realcolor_out;
output [14:0]   bgr555_out;
output          retrace;

input  [7:0]    video_scroll_reg;
input  [3:0]    border_idx;

// tv
input           clk4fsc;
input  [1:0]    tv_mode;            // tv_mode[1] = alternating fields
                                    // tv_mode[0] = tv mode
output tv_sync;
output reg[7:0]     tv_luma;        // CVBS output, TV sync included
output reg[7:0]     tv_chroma_o;
output reg[7:0]     tv_cvbs;
output [7:0]        tv_test;

reg signed [7:0]    tv_chroma;

// test pins
output [3:0]   testpin;

input tv_osd_fg;
input tv_osd_bg;
input tv_osd_on;
output rdvid_o;

wire bordery;               // y-border active, from module vga_refresh
wire borderx;               // x-border active, from module framebuffer
wire border = bordery | borderx;                
wire videoActive;

wire    [8:0]   fb_row;
wire    [8:0]   fb_row_count;

wire            tvhs, tvhs2, tvvs;

wire    [3:0] coloridx_modeless;

assign tvhs = tvhs2 | fb_row[0];

// gated signals for line 6
wire hsync_raw, vsync_raw;
wire lcd_den_raw, lcd_clk_raw;
wire [9:0] lcd_y;
wire       lcd_newline;

reg hsync_gate;
reg clock_gate;
`ifdef SCAN_7INCH
assign hsync = hsync_raw;
assign vsync = vsync_raw;// & !(fb_row > 255 || fb_row <= 260);
assign lcd_den_o = lcd_den_raw;
always @* hsync_gate <= 1'b1;
always @* clock_gate <= 1'b1;
`else
assign hsync = hsync_raw | ~hsync_gate;
assign vsync = vsync_raw;// & !(fb_row > 255 || fb_row <= 260);
assign lcd_den_o = lcd_den_raw & hsync_gate;
`endif
assign lcd_clk_o = lcd_clk_raw & clock_gate;

vga_refresh     refresher(
                            .clk24(clk24),
                            .lcd_clk_o(lcd_clk_raw),
                            .lcd_den_o(lcd_den_raw),
                            .lcd_hsync_o(lcd_hsync_o),
                            .lcd_vsync_o(lcd_vsync_o),
                            .lcd_y(lcd_y),
                            .lcd_newline_o(lcd_newline),
                            .hsync(hsync_raw),
                            .vsync(vsync_raw),
                            .videoActive(videoActive),
                            .bordery(bordery),
                            .retrace(retrace),
                            .video_scroll_reg(video_scroll_reg),
                            .fb_row(fb_row),
                            .fb_row_count(fb_row_count),
                            .tvhs(tvhs2),
                            .tvvs(tvvs)
                        );


// interface to the framebuffer memory: vdata[SRAM_ADDR] -> coloridx_modeless
framebuffer     winrar(
                            .clk24(clk24),
                            .ce12(ce12),
                            .ce_pixel(ce6),
                            .video_slice(video_slice), .pipe_abx(pipe_ab),
                            .fb_row(fb_row[8:0]),
                            .hsync(hsync),

                            .vdata(vdata),
                             
                            .SRAM_ADDR(SRAM_ADDR),
                            .coloridx(coloridx_modeless),
                            .borderx(borderx),
                            .rdvid_o(rdvid_o)
                        );
                        
reg     [3:0] xcoloridx;

// It's possible to switch to @(posedge) and if(ce6x), which goes ahead of ce6x by 1/8
// but then there's a little problem with TV out, because it's unbuffered: 
// leftmost column gets half-pixels from the right column. 
//
// 2024: on tang nano 9k negedge fails to latch the right colors in time 
// (capture ce12, ce6, xcoloridx to see). 
`define FHTAGN
`ifdef FHTAGN
reg [1:0] switch;
always @(posedge clk24)
    switch <= switch + 1;

always @(negedge clk24) begin 
    if (mode512) begin
        //if (ce6)
        if (switch[1])
            xcoloridx <= {coloridx_modeless[3], coloridx_modeless[2], 2'b00};
        else
            xcoloridx <= {2'b00, coloridx_modeless[1], coloridx_modeless[0]};
    end
    else
        xcoloridx <= coloridx_modeless;
end
`else
always @(negedge clk24) begin
    if (mode512) begin
        if (ce6)
            xcoloridx <= {coloridx_modeless[3], coloridx_modeless[2], 2'b00};
        else
            xcoloridx <= {2'b00, coloridx_modeless[1], coloridx_modeless[0]};
    end
    else
        xcoloridx <= coloridx_modeless;
end
`endif

// coloridx is an output port, address of colour in the palette ram
assign coloridx = border ? border_idx : xcoloridx;


// scan multiplier: write counter reset
reg reset_line;
always @(posedge clk24)
    reset_line <= fb_row[0] & !hsync;

wire resetrd;

always @* clock_gate <= 1'b1; // it's useless, yes, don't touch this line


//         _________
// ________         __________ fb_row[0]
// _______ ________ __________ vga hsync  ~resetrd (fast)
//        _        _
//                 _
// ________________ _________  reset_line  resetwr (slow)

`ifdef SCAN_2_1
assign testpin = {reset_line, wren_line1, reset_line, mode512};
// realcolor_out what actually goes to VGA DAC
assign realcolor_out = videoActive ? (wren_line1 ? rc_b : rc_a) : 8'b0;

assign bgr555_out = videoActive ? 
    (wren_line1 ? bgr233to555(rc_b) : bgr233to555(rc_a)) : 8'b0;


wire [7:0] rc_a;
wire [7:0] rc_b;

wire wren_line1 = fb_row[1];
wire wren_line2 = ~fb_row[1];

always @* hsync_gate <= 1'b1;

// probe by sabotage: <400 vsync breaks, <503 breaks <504 ok
//always @* hsync_gate <= hsync_ctr < 504;

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
`endif

`ifdef SCAN_5_3 

reg [5:0] div6sr; // running 1 with period of 6 lines
reg [4:0] div5sr; // running 1 with period of 5 lines
reg [1:0] fb_row_r; // [0] = fast vga lines, [1] = slow v06c/tv lines

reg wr_group;   // which group of 3 line buffers to write to

wire [2:0] wren_line_a = div6sr[2:0];
wire [2:0] wren_line_b = div6sr[5:3];
wire [7:0] rc_a [2:0];
wire [7:0] rc_b [2:0];

always @(posedge clk24)
begin
    fb_row_r <= fb_row[1:0];

    if (!vsync)
    begin
        div6sr <= 1'b1;   // write a/b 3 + 3 lines
        div5sr <= 1'b1;   // read line
    end

    // fast read 5 lines, 6th linger
    if (fb_row[0] != fb_row_r[0])
        div5sr <= {div5sr[3:0], 1'b0};

    // slow/write 6 lines
    if (fb_row[1] != fb_row_r[1])
    begin
        div6sr <= {div6sr[4:0], div6sr[5]};
        // reset read sr every 3 lines
        if (div6sr[5] | div6sr[2])  // 1 moving to [0] or [3]
            div5sr <= 1'b1;
    end
end

// hsync_gate: 0, 1, 2, 3, 4 -> 1, 5 -> 0
always @*
    hsync_gate <= (|div5sr) | retrace | (hsync_ctr > 495);

assign resetrd = !hsync;

`endif

`ifdef SCAN_7INCH
// 288 * 5 / 3 = 480
// write 3 A lines slowly, while reading 5 lines from 3 B lines
// write 3 B lines slowly, while reading 5 lines from 3 A lines

reg [5:0] div6sr; // running 1 with period of 6 lines (3+3), see wren_line_[b2b1b0a2a1a0]
reg [4:0] div5sr; // running 1 for 5 fast lines, 0, reset to 1
reg [1:0] fb_row_r; // [0] = fast vga lines, [1] = slow v06c/tv lines

reg wr_group;   // which group of 3 line buffers to write to

wire [2:0] wren_line_a = div6sr[2:0];
wire [2:0] wren_line_b = div6sr[5:3];
wire [7:0] rc_a [2:0];
wire [7:0] rc_b [2:0];

reg       vsync_r = 0;

always @(posedge clk24)
begin
    fb_row_r <= fb_row[1:0];
    vsync_r <= vsync;

    if (vsync && !vsync_r)
    begin
        div6sr <= 6'b1;   // write a/b 3 + 3 lines
        div5sr <= 5'b1;   // read line
    end

    else
    begin

    // fast read 5 lcd lines, skip 6th (display 576 * 5/6 = 480 lines)
    //if (fb_row[0] != fb_row_r[0])
    //    div5sr <= {div5sr[3:0], div5sr[4]};
    if (lcd_newline)
        div5sr <= {div5sr[3:0], div5sr[4]};

    // slow write: 1 tv line = 2 vga lines
    if (fb_row[1] != fb_row_r[1])
    begin
        div6sr <= {div6sr[4:0], div6sr[5]};
        // reset read sr every 3 lines
        //if (div6sr[5] | div6sr[2])  // 1 moving to [0] or [3]
        //    div5sr <= 5'b1;
    end

    end
end

// fine adjust center on the screen
oneshot #(30) osadj(.clk(clk24), .ce(1'b1), .trigger(lcd_hsync_o), .q(resetrd));
`endif

wire cerd = clock_gate;

rambuffer line_a_0(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_a[0]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_a[0]));
rambuffer line_a_1(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_a[1]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_a[1]));
rambuffer line_a_2(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_a[2]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_a[2]));

rambuffer line_b_0(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_b[0]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_b[0]));
rambuffer line_b_1(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_b[1]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_b[1]));
rambuffer line_b_2(.clk(clk24),
                .cerd(cerd),
                .cewr(ce12),
                .wren(wren_line_b[2]),
                .resetrd(resetrd),
                .resetwr(reset_line),
                .din(realcolor_in),
                .dout(rc_b[2]));

reg [14:0] read_a;
reg [14:0] read_b;

wire [14:0] amix [4:0];
wire [14:0] bmix [4:0];

// mix 7+7+6
pipmix4 ma1(clk24, rc_a[0], rc_a[0], rc_a[0], rc_a[0], bmix[0]);    
pipmix4 ma2(clk24, rc_a[0], rc_a[0], rc_a[0], rc_a[1], bmix[1]);
pipmix4 ma3(clk24, rc_a[1], rc_a[1], rc_a[1], rc_a[1], bmix[2]);
pipmix4 ma4(clk24, rc_a[1], rc_a[1], rc_a[2], rc_a[2], bmix[3]);
pipmix4 ma5(clk24, rc_a[2], rc_a[2], rc_a[2], rc_a[2], bmix[4]);
                           
pipmix4 mb1(clk24, rc_b[0], rc_b[0], rc_b[0], rc_b[0], amix[0]);    
pipmix4 mb2(clk24, rc_b[0], rc_b[0], rc_b[0], rc_b[1], amix[1]);
pipmix4 mb3(clk24, rc_b[1], rc_b[1], rc_b[1], rc_b[1], amix[2]);
pipmix4 mb4(clk24, rc_b[1], rc_b[1], rc_b[2], rc_b[2], amix[3]);
pipmix4 mb5(clk24, rc_b[2], rc_b[2], rc_b[2], rc_b[2], amix[4]);

// fallback nothingburger: line repeat 1/2/2
//pipmix4 ma1(clk24, rc_a[0], rc_a[0], rc_a[0], rc_a[0], amix[0]);    
//pipmix4 ma2(clk24, rc_a[1], rc_a[1], rc_a[1], rc_a[1], amix[1]);
//pipmix4 ma3(clk24, rc_a[1], rc_a[1], rc_a[1], rc_a[1], amix[2]);
//pipmix4 ma4(clk24, rc_a[2], rc_a[2], rc_a[2], rc_a[2], amix[3]);
//pipmix4 ma5(clk24, rc_a[2], rc_a[2], rc_a[2], rc_a[2], amix[4]);
//
//pipmix4 mb1(clk24, rc_b[0], rc_b[0], rc_b[0], rc_b[0], bmix[0]);    
//pipmix4 mb2(clk24, rc_b[1], rc_b[1], rc_b[1], rc_b[1], bmix[1]);
//pipmix4 mb3(clk24, rc_b[1], rc_b[1], rc_b[1], rc_b[1], bmix[2]);
//pipmix4 mb4(clk24, rc_b[2], rc_b[2], rc_b[2], rc_b[2], bmix[3]);
//pipmix4 mb5(clk24, rc_b[2], rc_b[2], rc_b[2], rc_b[2], bmix[4]);

always @*
    casex (div5sr)
        5'b00001: read_a <= amix[0];  // [0]                  3/3 0/3
        5'b00010: read_a <= amix[1];  // [0]*0.4 + [1]*0.6    2/4 2/4
        5'b00100: read_a <= amix[2];  // [1]*0.8 + [2]*0.2    3/4 1/4
        5'b01000: read_a <= amix[3];  // [1]*0.2 + [2]*0.8    1/4 3/4
        5'b10000: read_a <= amix[4];  // [2]*0.6 + [3]*0.4    2/4 2/4
        default:  read_a <= 0;
    endcase

always @*
    casex (div5sr)
        5'b00001: read_b <= bmix[0];  // [0]
        5'b00010: read_b <= bmix[1];  // [0]*0.4 + [1]*0.6
        5'b00100: read_b <= bmix[2];  // [1]*0.8 + [2]*0.2
        5'b01000: read_b <= bmix[3];  // [1]*0.2 + [2]*0.8
        5'b10000: read_b <= bmix[4];  // [2]*0.6 + [3]*0.4
        default:  read_b <= 0;
    endcase

wire [7:0] smallcolor_a = {read_a[14:13], read_a[9:7], read_a[4:2]};
wire [7:0] smallcolor_b = {read_b[14:13], read_b[9:7], read_b[4:2]};

assign realcolor_out = videoActive ? (|wren_line_a ? smallcolor_a : smallcolor_b) : 8'b0;

`ifdef SCAN_5_3
assign bgr555_out = videoActive ? (|wren_line_a ? read_a : read_b) : 8'b0;
`endif

`ifdef SCAN_7INCH
assign bgr555_out = (|wren_line_a ? read_a : read_b);
`endif

// hsync counter for debug /////////////////
reg [9:0] hsync_ctr;
reg hsync_rr;
always @(posedge clk24)
begin
    hsync_rr <= hsync;
    if (!hsync && hsync_rr) // negedge hsync
        hsync_ctr <= hsync_ctr + 1'b1;
    if (!vsync)
        hsync_ctr <= 0;
end
////////////////////////////////////////////
                
// osd
reg osd_vsync, osd_hsync;
reg         osd_xdelaybuf;
wire        osd_xdelay;
wire        osd_xtrigger;

`ifdef SCAN_7INCH
assign osd_xtrigger = lcd_newline;//lcd_hsync_o; // -- both kinda work
`else
assign osd_xtrigger = tv_mode[0] ? tvhs_local : hsync;
`endif

oneshot #(`OSD_HPOS) lineos0(.clk(clk24),
    .ce(1'b1),
    .trigger(osd_xtrigger),
    .q(osd_xdelay));

always @(posedge clk24)
begin
    `ifdef SCAN_7INCH
    osd_xdelaybuf <= osd_xdelay;
    osd_vsync <= ~(lcd_y == `OSD_TOP_FB_ROW);
    //osd_hsync <= osd_xdelay;
    if (~osd_xdelay & osd_xdelaybuf)
        osd_hsync <= 1'b0;
    if (ce6 & ~osd_hsync)
        osd_hsync <= 1'b1;
    `else
    osd_vsync <= tv_mode[0] ? ~(tv_halfline == `OSD_TV_HALFLINE) : ~(fb_row_count == `OSD_TOP_FB_ROW);
    if (~tv_mode[0] | ce6) begin
        osd_xdelaybuf <= osd_xdelay;
        osd_hsync <= ~(osd_xdelaybuf & ~osd_xdelay);
    end
    `endif
end

// tv

// copypasta from the main module, needs to be interned probably
wire [1:0]  lowcolor_b = {2{tv_osd_on}} & {realcolor_in[7],1'b0};
wire        lowcolor_g =      tv_osd_on & realcolor_in[5];
wire        lowcolor_r =      tv_osd_on & realcolor_in[2];

wire [7:0]  osd_colour = tv_osd_fg ? 8'b11111110 : 8'b01011001;

wire [7:0]  overlayed_colour = tv_osd_on ? osd_colour : realcolor_in;

wire [3:0] truecolor_R = {overlayed_colour[2:0], lowcolor_r};
wire [3:0] truecolor_G = {overlayed_colour[5:3], lowcolor_g};
wire [3:0] truecolor_B = {overlayed_colour[7:6], lowcolor_b};


// PAL frame sync
assign tv_sync  = fieldzone ? fieldsync : tvhs_local; 


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
    
    if (tv_halfline <= 4)                           fieldsync <= ~broadsync_window;
    else if (tv_halfline <= 9 || tv_halfline >= 618) fieldsync <= ~narrowsync_window;
    else begin
        fieldzone <= 1'b0;
    end
end

wire [5:0] cvbs_unclamped = V_REF + tvY[4:0] - $signed(tv_chroma[4:1]);
wire [4:0] cvbs_clamped = cvbs_unclamped[4:0];

wire [4:0] luma_unclamped = V_REF + tvY;
wire [4:0] luma_clamped = luma_unclamped[4:0];

wire [4:0] chroma_clamped;
chroma_shift crshift(.chroma_in(tv_chroma), .chroma_out(chroma_clamped));

always @* 
    casex ({tv_sync,tv_colorburst,tv_blank})
    3'b0xx: tv_cvbs <= V_SYNC;
    3'b111: tv_cvbs <= V_REF + 2 - tv_sin[7:6]; 
    3'b101: tv_cvbs <= V_REF;
    default:tv_cvbs <= cvbs_clamped; 
    endcase

always @* 
    casex ({tv_sync,tv_blank})
    2'b0x: tv_luma <= V_SYNC;
    2'b11:  tv_luma <= V_REF;
    default:tv_luma <= luma_clamped; 
    endcase

always @* 
    casex ({tv_sync,tv_colorburst,tv_blank})
    3'b0xx: tv_chroma_o <= 16;
    3'b111: tv_chroma_o <= 12 + tv_sin[7:5]; 
    3'b101: tv_chroma_o <= 16;
    default:tv_chroma_o <= chroma_clamped; 
    endcase
    
    
always @*
    case ({tv_halfline[1]^pal_fieldalt,tv_phase0[3:0]})
    0:  tv_chroma <= tvUV[0];
    1:  tv_chroma <= tvUV[1];
    2:  tv_chroma <= tvUV[2];
    3:  tv_chroma <= tvUV[3];
    4:  tv_chroma <= tvUV[4];
    5:  tv_chroma <= tvUV[5];
    6:  tv_chroma <= tvUV[6];
    7:  tv_chroma <= tvUV[7];
    8:  tv_chroma <= tvUV[8];
    9:  tv_chroma <= tvUV[9];
    10: tv_chroma <= tvUV[10];
    11: tv_chroma <= tvUV[11];
    12: tv_chroma <= tvUV[12];
    13: tv_chroma <= tvUV[13];
    14: tv_chroma <= tvUV[14];
    15: tv_chroma <= tvUV[15];
    
    16: tv_chroma <= tvUW[0];
    17: tv_chroma <= tvUW[1];
    18: tv_chroma <= tvUW[2];
    19: tv_chroma <= tvUW[3];
    20: tv_chroma <= tvUW[4];
    21: tv_chroma <= tvUW[5];
    22: tv_chroma <= tvUW[6];
    23: tv_chroma <= tvUW[7];
    24: tv_chroma <= tvUW[8];
    25: tv_chroma <= tvUW[9];
    26: tv_chroma <= tvUW[10];
    27: tv_chroma <= tvUW[11];
    28: tv_chroma <= tvUW[12];
    29: tv_chroma <= tvUW[13];
    30: tv_chroma <= tvUW[14];
    31: tv_chroma <= tvUW[15];
    endcase

// These are the colourburst phases that correspond
// to 270 and 135 degrees (180+/-45) in alternating
// lines.
//
// In the reality of this encoder, they correspond to 
// 0 and 90 degrees.
reg [3:0] tv_phase  = 0;
reg [3:0] tv_phase0 = 1;

// Field counter is kept for alternating the phase between fields,
// which is necessary for correct colour detail (stripes for example).
// Some TV tuners do not like field alternation and this is why
// it is kept optional.
reg [2:0] tv_fieldctr;
wire pal_fieldalt = tv_mode[1] & tv_fieldctr[0];

reg         tv_colorburst;
reg         tv_blank;

always @(posedge clk4fsc) begin
    tv_phase <= tv_phase + 1;
    tv_phase0 <= tv_phase0 + 1;
end 

wire [8:0] tv_sin00;
wire [8:0] tv_sin90;
wire [8:0] tv_sin = tv_halfline[1]^pal_fieldalt ? tv_sin00 : tv_sin90;
sinrom sinA(tv_phase0[3:1], tv_sin00);
sinrom sinB(tv_phase[3:1], tv_sin90);

assign tv_test[0] = tv_sin[7];

wire [7:0] tvY;
wire [13:0] tvY1;
wire [13:0] tvY2;
wire [13:0] tvY3;

wire signed [13:0] tvUV[15:0];
wire signed [13:0] tvUW[15:0];

// These coefficients are taken from eMSX. Scaling
// is done differently here, but only relative relation
// between the coefficients is really important.
// Perfect world's luminance,  Y = 0.299*R + 0.587*G + 0.114*B
assign tvY1 = 8'h18 * truecolor_R; 
assign tvY2 = 8'h2f * truecolor_G; 
assign tvY3 = 8'h09 * truecolor_B; 

wire [13:0] tvY_ = tvY1 + tvY2 + tvY3;
//assign tvY = tvY_[13:7]; 
assign tvY = tvY_[12:6]; 
                      

// UV encoding matrix
// Normally U = 0.492(B-Y) and V = 0.877(R-Y)
// So U and V are still functions of (R,G,B) and all coefficients can be precalculated
// For encoding, we can expand these expressions already multiplied by sin/cos: Usin(wt) +/- Vcos(wt)
//
// Since we can't keep colourburst phase at 180+/-45 degrees, the correction
// is made in coefficient calculation:
//     for V phase of +90, 5/8*2pi is subtracted
//     for V phase of -90, 3/8*2pi is subtracted
// This keeps phase relation between U,V and colourburst vectors even.
//
// See tools/pal.py for the program that derives these coefficients.
//


// phase = +90 degrees


uvsum #( +49, -41,  -7) (truecolor_R, truecolor_G, truecolor_B, tvUV[0]);
uvsum #( +40, -46,  +5) (truecolor_R, truecolor_G, truecolor_B, tvUV[1]);
uvsum #( +26, -45, +18) (truecolor_R, truecolor_G, truecolor_B, tvUV[2]);
uvsum #(  +7, -36, +29) (truecolor_R, truecolor_G, truecolor_B, tvUV[3]);
uvsum #( -11, -22, +34) (truecolor_R, truecolor_G, truecolor_B, tvUV[4]);
uvsum #( -29,  -5, +35) (truecolor_R, truecolor_G, truecolor_B, tvUV[5]);
uvsum #( -42, +12, +30) (truecolor_R, truecolor_G, truecolor_B, tvUV[6]);
uvsum #( -49, +29, +20) (truecolor_R, truecolor_G, truecolor_B, tvUV[7]);
uvsum #( -49, +41,  +7) (truecolor_R, truecolor_G, truecolor_B, tvUV[8]);
uvsum #( -40, +46,  -5) (truecolor_R, truecolor_G, truecolor_B, tvUV[9]);
uvsum #( -26, +45, -18) (truecolor_R, truecolor_G, truecolor_B, tvUV[10]);
uvsum #(  -7, +36, -29) (truecolor_R, truecolor_G, truecolor_B, tvUV[11]);
uvsum #( +11, +22, -34) (truecolor_R, truecolor_G, truecolor_B, tvUV[12]);
uvsum #( +29,  +5, -35) (truecolor_R, truecolor_G, truecolor_B, tvUV[13]);
uvsum #( +42, -12, -30) (truecolor_R, truecolor_G, truecolor_B, tvUV[14]);
uvsum #( +49, -29, -20) (truecolor_R, truecolor_G, truecolor_B, tvUV[15]);

uvsum #( -49, +41,  +7) (truecolor_R, truecolor_G, truecolor_B, tvUW[0]);
uvsum #( -49, +29, +20) (truecolor_R, truecolor_G, truecolor_B, tvUW[1]);
uvsum #( -42, +12, +30) (truecolor_R, truecolor_G, truecolor_B, tvUW[2]);
uvsum #( -29,  -5, +35) (truecolor_R, truecolor_G, truecolor_B, tvUW[3]);
uvsum #( -11, -22, +34) (truecolor_R, truecolor_G, truecolor_B, tvUW[4]);
uvsum #(  +7, -36, +29) (truecolor_R, truecolor_G, truecolor_B, tvUW[5]);
uvsum #( +26, -45, +18) (truecolor_R, truecolor_G, truecolor_B, tvUW[6]);
uvsum #( +40, -46,  +5) (truecolor_R, truecolor_G, truecolor_B, tvUW[7]);
uvsum #( +49, -41,  -7) (truecolor_R, truecolor_G, truecolor_B, tvUW[8]);
uvsum #( +49, -29, -20) (truecolor_R, truecolor_G, truecolor_B, tvUW[9]);
uvsum #( +42, -12, -30) (truecolor_R, truecolor_G, truecolor_B, tvUW[10]);
uvsum #( +29,  +5, -35) (truecolor_R, truecolor_G, truecolor_B, tvUW[11]);
uvsum #( +11, +22, -34) (truecolor_R, truecolor_G, truecolor_B, tvUW[12]);
uvsum #(  -7, +36, -29) (truecolor_R, truecolor_G, truecolor_B, tvUW[13]);
uvsum #( -26, +45, -18) (truecolor_R, truecolor_G, truecolor_B, tvUW[14]);
uvsum #( -40, +46,  -5) (truecolor_R, truecolor_G, truecolor_B, tvUW[15]);

endmodule

module uvsum(input wire signed [7:0] R, input wire signed [7:0] G, input wire signed [7:0] B, output wire signed [7:0] uvsum);
parameter signed c1 = 49,c2 = -41, c3 = -7;

wire signed [13:0] c01 = c1 * R;
wire signed [13:0] c02 = c2 * G;
wire signed [13:0] c03 = c3 * B;

wire signed [13:0] s = c01 + c02 + c03;
//assign uvsum = s[11:5];  // -- bright but overflows in a couple of places
//assign uvsum = s[12:6];  // -- dim but full coverage
assign uvsum = s[13:7] + s[12:6];

endmodule

module sinrom(input wire [2:0] adr, output reg [7:0] s); 
always @*
    case (adr)
    7:  s <= 218;
    6:  s <= 255;
    5:  s <= 255;
    4:  s <= 218;
    3:  s <= 91;
    2:  s <= 0;
    1:  s <= 0;
    0:  s <= 91;
    endcase
endmodule

module chroma_shift(input wire [7:0] chroma_in, output reg [4:0] chroma_out);
    always @*
        chroma_out <= 16 + chroma_in;
endmodule


// dumb mix = a + b + c + d
// input components are bgr233, output mix is bgr555
module mix4(input clk, input [7:0] a, input [7:0] b, input [7:0] c, input [7:0] d, output [14:0] mix);

wire [4:0] rsum  = a[2:0] + b[2:0] + c[2:0] + d[2:0] + 1; 
wire [4:0] gsum  = a[5:3] + b[5:3] + c[5:3] + d[5:3] + 1;
wire [3:0] bsum4 = a[7:6] + b[7:6] + c[7:6] + d[7:6] + 1;
wire [4:0] bsum = {bsum4, 1'b0};

assign mix = {bsum, gsum, rsum};

endmodule


// pipelined mix = a + b + c + d in 3 stages
// input components are bgr233, output mix is bgr555
// s1 = a + b
// s2 = s1 + c
// s3 = s2 + d + 1
module pipmix4(input clk, input [7:0] a, input [7:0] b, input [7:0] c, input [7:0] d, output [14:0] mix);

reg [4:0] rp [2:0];
reg [4:0] gp [2:0];
reg [4:0] bp [2:0];

reg [7:0] aq [1:0];
reg [7:0] bq [1:0];
reg [7:0] cq [1:0];
reg [7:0] dq [1:0];

always @(posedge clk)
begin
    aq[1] <= aq[0]; aq[0] <= a;
    bq[1] <= bq[0]; bq[0] <= b;
    cq[1] <= cq[0]; cq[0] <= c;
    dq[1] <= dq[0]; dq[0] <= d;


    rp[0] <= a[2:0] + b[2:0];               // stage 0
    rp[1] <= rp[0]  + cq[0][2:0];           // stage 1
    rp[2] <= rp[1]  + dq[1][2:0] + 1'b1;    // stage 2

    gp[0] <= a[5:3] + b[5:3];
    gp[1] <= gp[0]  + cq[0][5:3];
    gp[2] <= gp[1]  + dq[1][5:3] + 1'b1;

    bp[0] <= a[7:6] + b[7:6];
    bp[1] <= bp[0]  + cq[0][7:6];
    bp[2] <= bp[1]  + dq[1][7:6] + 1'b1;
end

assign mix = {bp[2][3:0],1'b0, gp[2], rp[2]};

endmodule

function [14:0] bgr233to555(input [7:0] a);

bgr233to555 = {a[7:6],3'b0,
               a[5:3],2'b0,
               a[2:0],2'b0};

endfunction

////////////////////////////////////////////////////////////////////////////




// $Id$
