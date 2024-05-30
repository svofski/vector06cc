/* Copyright (c) 2018 Upi Tamminen, All rights reserved.
 * See the LICENSE file for more information */

module ram #(parameter
    ADDR_WIDTH = 16,
    DATA_WIDTH = 8,
    DEPTH = 1024,
    HEXFILE = "",
    DEBUG = 0)
(
    input wire clk,
    input wire cs,
    input wire [ADDR_WIDTH-1:0] addr, 
    input wire we,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out 
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

always @(posedge clk) begin
    if (cs) begin
        if (we) begin
            memory_array[addr] <= data_in;
            if (DEBUG) $display("@%04x<=%02x", addr, data_in);
        end
        else begin
            data_out <= memory_array[addr];
            if (DEBUG) $display("@%04x->%02x", addr, memory_array[addr]);
        end
    end
end

endmodule

//module ram16 #(parameter ADDR_WIDTH = 16, DEPTH = 1024, HEXFILE = "")
//(
//    input wire clk,
//    input wire cs,
//    input wire [ADDR_WIDTH-1:0] addr,
//    input wire [1:0] we,
//    input wire [15:0] data_in,
//    output reg [15:0] data_out
//);
//
//reg [7:0] memory_array_l 
//
module ram2 #(parameter
    ADDR_WIDTH = 16,
    DATA_WIDTH = 16,
    DEPTH = 1024,
    HEXFILE = "")
(
    input wire clk,
    input wire cs,
    input wire [ADDR_WIDTH-1:0] addr, 
    input wire [1:0] we,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out 
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

always @(posedge clk) begin
    if (cs) begin
        if (|we) begin
            if (we[0]) memory_array[addr][7:0] <= data_in[7:0];
            if (we[1]) memory_array[addr][15:8] <= data_in[15:8];
            //$display("@%04x<=%04x & %d%d", addr, data_in, we[1], we[0]);
        end
        else begin
            data_out <= memory_array[addr];
            //$display("@%04x->%02x", addr, memory_array[addr]);
        end
    end
end

endmodule
