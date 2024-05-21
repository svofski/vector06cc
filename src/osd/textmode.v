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
// Design File: textmode.v
//
// Text mode video controller
//
// --------------------------------------------------------------------


//`default_nettype none

`define TILE_W 3'd6     // can only be <= 7
`define TILE_H 8'd8     // can only be 8 (probably 16, but then register widths must be adjusted)
`define WINDOW_W 8'd32
`define WINDOW_H 5'd8
`define WINDOW_PIXELW (`TILE_W*`WINDOW_W)
`define WINDOW_PIXELH (`TILE_H*`WINDOW_H)
`define LOG2TXT 8       // this many bits for text buffer addressing

module textmode(clk, ce, vsync, hsync, pixel, background, address, data, wren, rden, q,
                // debug stuff
                linebegin, textaddr, loadchar, tileaddr, tile_y, tileline, pixelreg);
input                   clk;
input                   ce;
input                   vsync;
input                   hsync;

output                  pixel;// = background & pixxel;
output                  background;

input [`LOG2TXT-1:0]    address;
input [7:0]             data;
input                   wren;
input                   rden;
output[7:0]             q;

// stuff for debug
output      linebegin;
output[7:0] textaddr;
output      loadchar;
output[9:0] tileaddr;
output[2:0] tile_y;

output[`TILE_W-1:0] tileline;
output [`TILE_W-1:0] pixelreg;

assign pixel = background & pixxel;

wire [2:0]  tile_y;
wire        loadchar;
wire [`LOG2TXT-1:0] textaddr;
reg  [`TILE_W-1:0] pixelreg;
reg         pixxel;

textmode_counter tcu(
            .clk(clk),
            .ce(ce),
            .linebegin(~hsync),
            .framebegin(~vsync),
            .tile_y(tile_y),
            .loadchar(loadchar),
            .textaddr(textaddr),
            .video_enable(background)
            );

wire [7:0]  charcode;
//screenbuffer ram0(            
//          .clock(clk),
//          .data_b(data),
//          .address_a(textaddr),
//          .address_b(address),
//          .wren_b(wren),
//          .q_a(charcode),
//          .q_b(q));

vram #(.ADDR_WIDTH(8), .DATA_WIDTH(8), .DEPTH(256), .HEXFILE("testtext.hax")) vram
    (.clk(clk), 
     .cs(1'b1),
     .addr_a(textaddr),
     .addr_b(address),
     .we_b(wren),
     .rd_b(rden),
     .data_in(data),
     .dout_a(charcode),
     .dout_b(q));


wire        invert = charcode[7];
wire [9:0]  tileaddr = tile_y != (`TILE_H-1)  ? {charcode[6:0], 3'b000} - charcode[6:0] + tile_y : 10'b0; 
//wire [`TILE_W-2:0]  tileline;

// character rom is 512x5, 8 quintets per tile, 64 tiles total
rom #(.ADDR_WIDTH(10),.DATA_WIDTH(5),.DEPTH(1024),.ROM_FILE("e5x7.hax"))
chrom0(.clk(clk),
    .cs(1'b1),
    .addr(tileaddr),
    .data_out(tileline));
    
wire [`TILE_W-1:0] poxels = loadchar ? {invert,(invert ? ~tileline : tileline)} : {pixelreg[`TILE_W-2:0],1'b0};

always @(posedge clk) begin
    if (ce) begin
        pixelreg <= poxels;
        pixxel <= pixelreg[`TILE_W-1];
    end
end

endmodule


module textmode_counter(clk, ce, linebegin, framebegin, textaddr, video_enable, text_x, text_y, loadchar, tile_y);

input       clk;
input       ce;
input       linebegin;
input       framebegin;

output[`LOG2TXT-1:0]textaddr;   // address of current character in text buffer
output [4:0]        text_y;
output[7:0]         text_x;
output              loadchar;// = tile_x == 0;
output[2:0]         tile_y;
output  reg         video_enable;

reg [4:0]           text_y;
reg [7:0]           text_x;
reg [4:0]           line_counter;   // line counter
reg [2:0]           tile_x;     // pixel x position relative to current tile start
reg [2:0]           tile_y;

reg [2:0]           tile_xinv;

assign loadchar = tile_x == 0;

wire [2:0]          wNextTileX = tile_x + 1'b1;
wire [`LOG2TXT-1:0] wNextTextX = text_x + (wNextTileX == 2);

// "scanline doubler" of sorts
reg linediv;
always @(posedge clk) begin
    if (framebegin)
        linediv <= 0;
    else if (ce && (state == 2)) 
        linediv <= linediv + 1'b1;
end


reg [`LOG2TXT-1:0]  text_base;      // current line begins here

assign textaddr = text_base + text_x;

reg [1:0] state;

always @(posedge clk) begin
    if (framebegin) begin
        text_y <= 0;
        tile_x <= 0;
        tile_y <= 0;
        text_base <= 0;
        state <= 0;
        text_x <= 0;
        line_counter <= `WINDOW_H;
    end
    else
    if (ce) begin 
        case (state)
        0,1: if (linebegin | state == 1) begin
                state <= 1;
                
                if (state == 1) video_enable <= 1;

                text_x <= wNextTextX;
                tile_x <= wNextTileX == `TILE_W ? 0 : wNextTileX;
                
                if (wNextTileX == 1 && wNextTextX == `WINDOW_W) begin
                    state <= 2;
                end
                
            end
        2:
            begin
                // be prepared (tm) for the next line
                text_x <= 0;
                tile_x <= 0;
                video_enable <= 0;
                
                tile_y <= tile_y + linediv;
                if (tile_y == `TILE_H-1) begin
                    text_base <= text_base + (linediv ? 8'h0 : `WINDOW_W);
                    line_counter <= line_counter - linediv; 
                    state <= {2{(line_counter - linediv == 0)}}; // 3 or 0
                end 
                else state <= 0;
                
            end
        3:  ; // dead end, wait until reset/framebegin
        endcase
    end
end

endmodule
