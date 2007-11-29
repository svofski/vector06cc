// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 					Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: kvaz.v
//
// RAM disk memory mapper. This unit maps standard Vector-06C RAM disk
// into pages 1, 2, 3, 4 of SRAM address space. 
//
// --------------------------------------------------------------------
`default_nettype none

module kvaz(clk, clke, 
			reset,
            address, 
			select,
			data_in,
			stack, 
            memwr, memrd,
            bigram_addr,
			debug);
            
input			clk;
input			clke;
input 			reset;
input [15:0]	address;
input			select;
input [7:0]		data_in;
input			stack;
input			memwr;
input			memrd;
output reg[2:0]	bigram_addr;

output [7:0]	debug = {control_reg};

// control register
reg [7:0]		control_reg;

always @(posedge clk) begin
	if (reset) begin
		control_reg <= 0;
	end 
	else if (clke & select) begin
		control_reg <= data_in;
	end
end

// control register breakdown
wire [2:0] 		cr_ram_page 	= control_reg[1:0] + 1;
wire [2:0]		cr_stack_page 	= control_reg[3:2] + 1;
wire			cr_stack_on		= control_reg[4];
wire			cr_ram_on		= control_reg[5];


wire [3:0] adsel = address[15:12];

wire addr_sel = adsel == 4'hA | adsel == 4'hB | adsel == 4'hC | adsel == 4'hD;

wire ram_sel = cr_ram_on & addr_sel & (memwr|memrd);

wire stack_sel = cr_stack_on & stack & (memwr|memrd);

always @(stack,memrd,memwr) begin
	bigram_addr <= stack_sel ? cr_stack_page : ram_sel ? cr_ram_page : 3'b000;
end	

endmodule

// $Id$