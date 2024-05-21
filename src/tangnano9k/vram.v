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

`ifdef SINGLEPORT

wire [ADDR_WIDTH-1:0] sel_addr;
wire [7:0] do;

assign dout_b = rd_b ? do : 8'h00;
assign dout_a = rd_b ? 8'h00 : do;

assign sel_addr = (we_b|rd_b) ? addr_b : addr_a;

ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH), .HEXFILE(HEXFILE))
  ram0(.clk(clk), .cs(cs), .addr(sel_addr), .we(we_b), .data_in(data_in), .data_out(do));

`else

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
`endif

endmodule
