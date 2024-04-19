// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2016 Viacheslav Slavinsky
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
//      - VGA refresh generator 
//      - frame buffer
//      - scan doubler
// The palette ram is external. coloridx should be connected to
// the palette RAM address bus, realcolor_in must be connected to 
// the palette RAM output.
//
// --------------------------------------------------------------------


//`default_nettype none

module video(
    clk24,               // clock 24mhz
    ce12,               // 12mhz clock enable for vga-scan (buffer->vga)
    ce6,                // 6mhz  clock enable for pal-scan (ram->buffer)
    ce6x,
    video_slice,        // video time slice, not cpu time
    pipe_ab,            // pipe_ab for register pipeline
 
    mode512,            // 1 == 512 pixels/line mode
    
    vdata,              // video data input [31:0]

    SRAM_ADDR,          // SRAM address, output

    hsync,              // VGA hsync
    vsync,              // VGA vsync

    lcd_clk_o,
    lcd_den_o,

    
    osd_hsync,
    osd_vsync,
    
    coloridx,           // output:  palette ram address
    realcolor_in,       // input:   real colour value from palette ram
    realcolor_out,      // output:  real colour value --> vga
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
input wire          clk24;
input wire          ce12;
input wire          ce6;
input wire          ce6x;
input wire          video_slice;
input wire          pipe_ab;

input wire          mode512;          // 1 for 512x256 video mode

// RAM access
input wire [31:0]   vdata;
output wire [15:0]  SRAM_ADDR;

// video outputs
output wire         hsync;
output wire         vsync;
output wire         lcd_clk_o;
output wire         lcd_den_o;

output              osd_hsync;
output              osd_vsync;
output wire [3:0]   coloridx;
input  wire [7:0]   realcolor_in;
output wire [7:0]   realcolor_out;
output wire         retrace;

input wire [7:0]    video_scroll_reg;
input wire [3:0]    border_idx;

// tv
input wire          clk4fsc;
input wire [1:0]    tv_mode;        // tv_mode[1] = alternating fields
                                    // tv_mode[0] = tv mode
output wire         tv_sync;
output reg[7:0]     tv_luma;        // CVBS output, TV sync included
output reg[7:0]     tv_chroma_o;
output reg[7:0]     tv_cvbs;
output wire [7:0]   tv_test;

reg signed [7:0]    tv_chroma;

// test pins
output wire [3:0]   testpin;

input wire          tv_osd_fg;
input wire          tv_osd_bg;
input wire          tv_osd_on;
output wire         rdvid_o;

wire bordery;               // y-border active, from module vga_refresh
wire borderx;               // x-border active, from module framebuffer
wire border = bordery | borderx;                
wire videoActive;

wire    [8:0]   fb_row;
wire    [8:0]   fb_row_count;

wire            tvhs, tvhs2, tvvs;

wire    [3:0] coloridx_modeless;

assign tvhs = tvhs2 | fb_row[0];

vga_refresh     refresher(
                            .clk24(clk24),
                            .lcd_clk_o(lcd_clk_o),
                            .lcd_den_o(lcd_den_o),
                            .hsync(hsync),
                            .vsync(vsync),
                            .videoActive(videoActive),
                            .bordery(bordery),
                            .retrace(retrace),
                            .video_scroll_reg(video_scroll_reg),
                            .fb_row(fb_row),
                            .fb_row_count(fb_row_count),
                            .tvhs(tvhs2),
                            .tvvs(tvvs)
                        );


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
reg osd_vsync, osd_hsync;

reg         osd_xdelaybuf;

wire        osd_xdelay;

oneshot #(9'd200) lineos0(.clk(clk24), .ce(1'b1), .trigger(tv_mode[0] ? tvhs_local : hsync), .q(osd_xdelay));

always @(posedge clk24) begin
    osd_vsync = tv_mode[0] ? ~(tv_halfline == 275) : ~(fb_row_count == 128);

    if (~tv_mode[0] | ce6) begin
        osd_xdelaybuf <= osd_xdelay;
        osd_hsync <= ~(osd_xdelaybuf & ~osd_xdelay);
    end
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




////////////////////////////////////////////////////////////////////////////




// $Id$
