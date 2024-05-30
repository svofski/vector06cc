/* Copyright (c) 2018 Upi Tamminen, All rights reserved.
 * See the LICENSE file for more information */

/* Port extension Copyright (c) 2024 Viacheslav Slavinsky, All rights reserved. */

module vram #(parameter
    ADDR_WIDTH = 16,
    DATA_WIDTH = 8,
    DEPTH = 1024,
    HEXFILE = "")
(
    input  clk,
    input  cs,
    input  [ADDR_WIDTH-1:0] addr_a, 
    input  [ADDR_WIDTH-1:0] addr_b, 
    input  we_b,
    input  rd_b,
    input  [DATA_WIDTH-1:0] data_in,
    output  [DATA_WIDTH-1:0] dout_a,
    output  [DATA_WIDTH-1:0] dout_b
);

reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1]; 
integer i;

initial begin
`ifdef SIMULATION
    for (i = 0; i < DEPTH; i = i + 1) memory_array[i] = 0;
`endif    
    if (HEXFILE != "") begin
        $readmemh(HEXFILE, memory_array);
        //for (i = 0; i < 256; i = i + 1) begin
        //    $write("%02x ", memory_array[i]);
        //end
    end
end

reg [DATA_WIDTH-1:0] dout_a_r, dout_b_r;
assign dout_a = dout_a_r;
assign dout_b = dout_b_r;

always @(posedge clk) begin
    if (cs) begin
        if (we_b) begin
            memory_array[addr_b] <= data_in;
            dout_a_r <= memory_array[addr_a];
            dout_b_r <= data_in;
            //dout_b <= memory_array[addr_b];
            //$display("@%04x<=%02x", addr, data_in);
        end
        else begin
            dout_a_r <= memory_array[addr_a];
            dout_b_r <= memory_array[addr_b];
            //$display("@%04x->%02x", addr, memory_array[addr]);
        end
    end
end

endmodule

// msp430-compatible osd vram
// port a provides read-only byte access
// port b provides read-write byte/word access
//
// DEPTH in bytes
module vram_r8w16 #(parameter ADDR_WIDTH = 16, DEPTH = 1024)
(
    input  clk,
    input  cs,

    input  [ADDR_WIDTH-1:0] addr_a,   // video address in bytes
    output  [7:0] dout_a,

    input  [ADDR_WIDTH-1:0] addr_b,   // cpu address in bytes
    input  rden_b,                    // cpu read enable, always words
    input  [1:0] wren_b,              // cpu write byte select
    input  [15:0] data_in,            // cpu data in 
    output  [15:0] dout_b             // cpu data out
);

reg [15:0] memory_array [0:DEPTH/2-1]; // words
reg [7:0] dout_a_r;     // data to video (bytes)
reg [15:0] dout_b_r;    // data to cpu (words)

assign dout_a = dout_a_r;
assign dout_b = dout_b_r;

wire [ADDR_WIDTH-2:0] waddr_a = addr_a[ADDR_WIDTH-1:1]; 
wire [ADDR_WIDTH-2:0] waddr_b = addr_b[ADDR_WIDTH-1:1];
always @(posedge clk)
    if (cs)
    begin
        if (|wren_b)
        begin
            // write from cpu
            if (wren_b[0]) memory_array[waddr_b][7:0] <= data_in[7:0];
            if (wren_b[1]) memory_array[waddr_b][15:8] <= data_in[15:8];
        end

        // cpu read
        if (rden_b)
            dout_b_r <= memory_array[waddr_b];

        // video read
        dout_a_r <= addr_a[0] ? memory_array[waddr_a][15:8] : memory_array[waddr_a][7:0];
    end

endmodule

module vram_rw8_rw16 #(parameter ADDR_WIDTH = 16, DEPTH = 1024)
(
    input clk,
    input cs,

    // -- port a: 16 bit r/w, supports byte writes
    input [ADDR_WIDTH-1:0] addr_a,
    input rden_a,
    input [1:0] wren_a,
    input [15:0] din_a,
    output reg [15:0] dout_a,

    // -- port b: 8 bit r/w
    input [ADDR_WIDTH-1:0] addr_b,
    input rden_b,
    input wren_b,
    input [7:0] din_b,
    output reg [7:0] dout_b
);

reg [15:0] memory_array [0:DEPTH/2-1]; // words

wire [ADDR_WIDTH-2:0] waddr_a = addr_a[ADDR_WIDTH-1:1];
wire [ADDR_WIDTH-2:0] waddr_b = addr_b[ADDR_WIDTH-1:1];

// --- port a ---
always @(posedge clk)
begin: _port_a
    if (cs)
    begin
        if (|wren_a)  // cpu write: word or byte
        begin
            if (wren_a[0]) memory_array[waddr_a][7:0] <= din_a[7:0];
            if (wren_a[1]) memory_array[waddr_a][15:8] <= din_a[15:8];
        end

        if (rden_a)
            dout_a <= memory_array[waddr_a];
    end
end

// --- port b ---
always @(posedge clk)
begin: _port_b
    if (cs)
    begin
        // --- port b ---
        if (wren_b)   // byte write
        begin
            if (addr_b[0])
                memory_array[waddr_b][15:8] <= din_b;
            else
                memory_array[waddr_b][7:0] <= din_b;
        end

        if (rden_b)
            dout_b <= addr_b[0] ? memory_array[waddr_b][15:8] : memory_array[waddr_b][7:0];
    end
end

endmodule
