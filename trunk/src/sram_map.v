module sram_map(SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N, memwr_n, abus, dout, din);
output [14:0] 	SRAM_ADDR;
inout  [15:0] 	SRAM_DQ;
output 			SRAM_WE_N;
output 			SRAM_UB_N;
output 			SRAM_LB_N;
input			memwr_n;
input  [15:0]	abus;
input  [7:0]	dout;
output [7:0]	din;

assign SRAM_ADDR = abus[15:1];
assign SRAM_UB_N = ~abus[0];
assign SRAM_LB_N = abus[0];
assign SRAM_WE_N = memwr_n;

wire [7:0] effective_do = memwr_n ? 8'bZZZZZZZZ : dout;

assign SRAM_DQ[7:0]  = abus[0] ? 8'bZZZZZZZZ : effective_do;
assign SRAM_DQ[15:8] = abus[0] ? effective_do : 8'bZZZZZZZZ;

assign din = abus[0] ? SRAM_DQ[15:8] : SRAM_DQ[7:0];

endmodule

// $Id$
