// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//              Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Barkar kvaz support added by Ivan Gorodetsky
//
// Design File: kvaz.v
//
// RAM disk memory mapper. This unit maps standard Vector-06C RAM disk
// into pages 1, 2, 3, 4 of SRAM address space. 
//
// --------------------------------------------------------------------
//`default_nettype wire

module kvaz(clk, clke, 
    reset,
    address, 
    select,
    data_in,
    stack, 
    page,
    kvaz_sel);
            
input			clk;
input			clke;
input 			reset;
input [15:0]	        address;
input			select;
input [7:0]		data_in;
input			stack;
output [1:0]	        page;
output                  kvaz_sel;

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
wire [1:0] cr_ram_page     = control_reg[1:0];
wire [1:0] cr_stack_page   = control_reg[3:2];
wire       cr_stack_on     = control_reg[4];


wire [3:0] adsel = address[15:12];

//wire ram_sel = adsel == 4'hA | adsel == 4'hB | adsel == 4'hC | adsel == 4'hD; //standard
wire ram_sel = 
    (((adsel == 4'hA) | (adsel == 4'hB) | (adsel == 4'hC) | (adsel == 4'hD)) & control_reg[5]) | 
    (((adsel == 4'h8) | (adsel == 4'h9)) & control_reg[6]) |
    (((adsel == 4'hE) | (adsel == 4'hF)) & control_reg[7]);//Barkar

wire stack_sel = cr_stack_on & stack;

assign kvaz_sel = stack_sel | ram_sel;
assign page = stack_sel ? cr_stack_page : ram_sel ? cr_ram_page : 2'b00;

endmodule

// $Id$
