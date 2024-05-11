//`default_nettype none

// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: spi.v
//
// SPI host, mimics AVR SPI in its most basic mode
//
// --------------------------------------------------------------------

module spi(clk, ce, reset_n, mosi, miso, sck, di, wr, do, dsr);
input		clk;
input 		ce;
input		reset_n;
output	reg	mosi;
input		miso;
output		sck;

input [7:0]	di;
input		wr;

output[7:0]	do;
output reg	dsr;

reg [7:0]	shiftreg;
reg [7:0]	shiftski;

reg [1:0]	state = 0;
reg 		scken = 0;

assign sck = ~clk & scken;
assign do = shiftreg;

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		state <= 0;
		mosi <= 1'b0;
		dsr  <= 0;
		scken <= 0;
	end else begin
		if (ce) begin
			case (state)
			0:	begin
					if (wr) begin
						dsr <= 1'b0;
						state <= 1;
						shiftreg <= di;
						shiftski <= 8'b11111111;
					end
				end
			1: 	begin
					scken <= 1;
					mosi <= shiftreg[7];
					shiftreg <= {shiftreg[6:0],miso};
					shiftski <= {1'b0,shiftski[7:1]};
					
					if (|shiftski == 0) begin 
						state <= 2;
						scken <= 0;
					end
				end
			2:	begin
					mosi <= 1'b0; // shouldn't be necessary but a nice debug view
					dsr <= 1'b1;
					state <= 0;
					//scken <= 0;
				end
			default: ;
			endcase
		end
	end
end


endmodule

