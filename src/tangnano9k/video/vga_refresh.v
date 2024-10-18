// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//            Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
//
// Modified by Ivan Gorodetsky
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

`default_nettype wire

module vga_refresh(
    input           clk24,
    output          lcd_clk_o,
    output          lcd_den_o,
    output          lcd_hsync_o,
    output          lcd_vsync_o,
    output  [9:0]   lcd_x_o,
    output  [9:0]   lcd_y_o,
    output          hsync,
    output          vsync,
    output          lcd_newline_o,   // single clock lcd hsync (+)
    output          vga_newline_o,   // single clock vga hsync (+)
    output          tv_newline_o,    // single clock tv hsync  (+)
    output          loadscroll_o,
    output          YPbPrvsync,
    output          videoActive,
    output          bordery,
    output          retrace,
    input   [7:0]   video_scroll_reg,
    output  [8:0]   fb_row,
    output  [8:0]   fb_row_count,
    output          tvhs,
    output          tvvs,
    output  [9:0]   tvx,
    output  [9:0]   tvy);

// total = 624
// visible = (16 + 256 + 16)*2 = 288*2 = 576
// rest = 624-576 = 48

parameter VISIBLEWIDTH = 10'd640;   
parameter SCREENHEIGHT = 10'd576;
parameter VISIBLEHEIGHT = SCREENHEIGHT - 2*2*16;
parameter SCROLLLOAD_X = 112;   // when on line 0 scroll register is copied into the line counter

reg videoActiveX = 0;           // 1 == X is within visible area
reg videoActiveY = 0;           // 1 == Y is within visible area
wire videoActive = videoActiveX & videoActiveY;

assign retrace = !videoActiveY;
assign hsync = !(scanxx_state == state2);
assign vsync = !(scanyy_state == state2);
assign YPbPrvsync = !((scanyy_state == state1)&&(scanyy>10'd10));

//assign tvhs = !((tvx > (0)) && (tvx < (96)));
assign tvhs = !(tvx > 800-96);
//assign tvvs = !(tvy < 6);
assign tvvs = !(tvy == 623 && tvx == 800-96);

reg[9:0] tvx = 0;
reg[9:0] tvy = 0;

reg[9:0] realx = 0;  
reg[9:0] realy = 0;

reg[2:0] scanxx_state = 0;      // x-machine state
reg[2:0] scanyy_state = 0;      // y-machine state
reg[9:0] scanxx = 0;            // x-state timer/counter
reg[9:0] scanyy = 0;            // y-state timer/counter

reg bordery = 0;
//
// framebuffer variables
//
reg [8:0] fb_row = 0;           // fb row
reg [8:0] fb_row_count = 0;


//assign lcd_den_o = videoActive;
reg lcd_active_x;
assign lcd_clk_o = clk24;


parameter state0 = 3'b000, state1 = 3'b001, state2 = 3'b010, state3 = 3'b011, state4 = 3'b100, state5 = 3'b101, state6 = 3'b110, state7 = 3'b111;

reg [7:0] testreg = 0;
reg [6:0] testreg2 = 0;

assign loadscroll_o = scanyy_state == state5 && realx == SCROLLLOAD_X && scanyy == VISIBLEHEIGHT;

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

    // begin lcd data clock even earlier in the middle of hsync pulse
    if (scanxx_state == state2 && scanxx == 20 )
        lcd_active_x <= 1'b1;

    if (scanxx == 0) begin  
        case (scanxx_state) 
            state0: // enter FRONT PORCH
            begin 
                scanxx <= 10'd11 - 1'b1;
                scanyy <= scanyy - 1'b1;

                scanxx_state <= state1;
                videoActiveX <= 1'b0;
                lcd_active_x <= 1'b0;

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
            state2: // enter BACK PORCH
            begin
                scanxx <= 10'd61 - 1'b1;
                scanxx_state <= state3;
                //lcd_active_x <= 1'b1; // start early to offset the picture to the right
            end
            state3: // enter VISIBLE AREA
            begin
                videoActiveX <= 1'b1;
                realx <= 9'b0;
                scanxx <= VISIBLEWIDTH - 1'b1 - 1'b1; // borrow one from state4
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
    else 
        scanxx <= scanxx - 1'b1;

    // load scroll register at this precise moment
    if (loadscroll_o) begin
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

// New plan for LCD HSYNC 
//
//  1     2     3     4     5     6     1
//  H.....H.....H.....H.....H.....H.....H..   624 lines hsync (576 visible)
//  L......L......L......L.......L......L..   520 lines hsync (576 visible down to 480)
//
//  vga time = 768
//  lcd time = 768 + 768/5, dither extra time as 153+154+153+154+154
//
//  new signals: lcd_hsync_o, lcd_vsync_o
reg [4:0] lcd_line = 0;
reg [9:0] lcd_time = 0; // time in pixelclocks 0..(768+153)
reg       vsync_r = 0;

reg [9:0] sim_lcd_line = 0;
integer sim_vga_line = 0;

reg sim_hsync_r = 0;

reg [9:0] lcd_visible_time = 0;

reg lcd_newline = 0;
assign lcd_newline_o = lcd_newline;

reg vga_hsync_r = 0;
always @(posedge clk24) vga_hsync_r <= hsync;
assign vga_newline_o = vga_hsync_r && ~hsync;

reg tv_hsync_r = 0;
always @(posedge clk24) tv_hsync_r <= tvhs;
assign tv_newline_o = tv_hsync_r && ~tvhs;

always @(posedge clk24)
begin
    vsync_r <= vsync;
    lcd_time <= lcd_time + 1'b1;
    lcd_newline <= 1'b0;

    //if (!vsync && vsync_r)
    if (vsync && !vsync_r)
    begin
        lcd_line <= 5'b00001; // counts lcd lines with period 5
        lcd_time <= 0;
        //$display("counts: lcd_line=%d vga_line=%d", sim_lcd_line, sim_vga_line);
        sim_lcd_line <= 0;
        sim_vga_line <= 0;
    end

    if (lcd_time + 1'b1 == lcd_visible_time)
    begin
        lcd_line <= {lcd_line[3:0],lcd_line[4]};
        lcd_time <= 0;
        sim_lcd_line <= sim_lcd_line + 1;
        lcd_newline <= 1'b1;

        case ({lcd_line[3:0],lcd_line[4]})
            5'b00001: lcd_visible_time <= 768 + 153;
            5'b00010: lcd_visible_time <= 768 + 154;
            5'b00100: lcd_visible_time <= 768 + 153;
            5'b01000: lcd_visible_time <= 768 + 154;
            5'b10000: lcd_visible_time <= 768 + 154;
        endcase
    end

    sim_hsync_r <= hsync;
    if (hsync && !sim_hsync_r)
    begin
        sim_vga_line <= sim_vga_line + 1;
        $display("HSYNC vga_line=%d lcd_line=%d VS=%d",
            sim_vga_line, sim_lcd_line, !vsync);
    end

end

reg lcd_hsync_r = 0;
always @(posedge clk24) 
    lcd_hsync_r <= ~(lcd_time >= 11 && lcd_time < (11+56)) | ~vsync;

reg lcd_den_r = 0;
always @(posedge clk24)
    lcd_den_r = lcd_time >= (11 + 56)
    && (lcd_time < lcd_visible_time - 9) // 9 shows boot on both, 7 stops working on 7"
            && (sim_lcd_line >= 23) && (sim_lcd_line < 503);

assign lcd_vsync_o = vsync;
assign lcd_hsync_o = lcd_hsync_r;
`ifdef SCAN_7INCH
assign lcd_den_o = lcd_den_r;
`else
assign lcd_den_o = videoActiveY && lcd_active_x;
`endif

assign lcd_y_o = sim_lcd_line - 23;
assign lcd_x_o = lcd_time;

endmodule

// $Id$
