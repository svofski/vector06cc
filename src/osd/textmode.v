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

module textmode(
    input                 clk,
    input                 ce,
    input                 vsync,
    input                 hsync,
    
    output                pixel,// = background & pixxel,
    output                background,
    
    input [`LOG2TXT-1:0]  osd_addr,
    input [15:0]          osd_data,
    input [1:0]           osd_wren,
    input                 osd_rden,
    output[15:0]          osd_q,
    
    // stuff for debug
    output                linebegin,
    output [7:0]          textaddr,
    output                loadchar,
    output [9:0]          tileaddr,
    output [2:0]          tile_y,
    
    output[`TILE_W-1:0]   tileline,
    output [`TILE_W-1:0]  pixelreg);

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

vram_r8w16 #(.ADDR_WIDTH(8), .DEPTH(256)) vram
    (.clk(clk), 
     .cs(1'b1),
      // -- video --
     .addr_a(textaddr),
     .dout_a(charcode),
     // -- cpu --
     .addr_b(osd_addr),
     .rden_b(osd_rden),
     .wren_b(osd_wren),
     .data_in(osd_data),
     .dout_b(osd_q));


wire        invert = charcode[7];
wire [9:0]  tileaddr = tile_y != (`TILE_H-1)  ? {charcode[6:0], 3'b000} - charcode[6:0] + tile_y : 10'b0; 

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


module textmode_counter
    (input       clk,
     input       ce,
     input       linebegin,
     input       framebegin,
     
     output[`LOG2TXT-1:0]textaddr,   // address of current character in text buffer
     output [4:0]        text_y,
     output[7:0]         text_x,
     output              loadchar,// = tile_x == 0;
     output[2:0]         tile_y,
     output  reg         video_enable);

reg [4:0]           text_y;
reg [7:0]           text_x;
reg [4:0]           line_counter;   // line counter
reg [2:0]           tile_x;     // pixel x position relative to current tile start
reg [2:0]           tile_y;

reg [2:0]           tile_xinv;

assign loadchar = tile_x == 0;

wire [2:0]          wNextTileX = tile_x + 1'b1;
wire [`LOG2TXT-1:0] wNextTextX = text_x + (wNextTileX == 2);

// "scanline tripler" of sorts
reg [2:0] linedivreg;

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
        video_enable <= 0;

        linedivreg <= 3'b001;
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
                    video_enable <= 0;
                end
                
            end
        2:
            begin
                // be prepared (tm) for the next line
                text_x <= 0;
                tile_x <= 0;
                
                state <= 0;
                linedivreg <= {linedivreg[1:0], linedivreg[2]};
                if (linedivreg[2])
                begin
                    tile_y <= tile_y + 1'b1;
                    if (tile_y + 1'b1 == `TILE_H)
                    begin
                        text_base <= text_base + `WINDOW_W;
                        line_counter <= line_counter - 1'b1;
                        if (line_counter - 1'b1 == 0)
                            state <= 3;   // end of frame
                    end
                end
            end
        3:  ; // dead end, wait until reset/framebegin
        endcase
    end
end

endmodule
