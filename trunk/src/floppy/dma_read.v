`default_nettype none

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
// Design File: dma_read.v
//
// DMA controller that can pump 512-byte blocks of raw SPI data to a buffer.
// Buffer address is loaded in iaddr when nblocks input is nonzero.
// A nonzero nblocks value on input initiates transfer (ready == 0). 
// While ready == 0, nothing is allowed to access data and address busses.
// --------------------------------------------------------------------

module dma_read(clk, ce, reset_n, iaddr, oaddr, odata, owren, nblocks, ready, ospi_data, ispi_data, ospi_wr, ispi_dsr, debug);

parameter IDLE=0, BUSY=1, BLOCK=2, OVER=3, NBYTE=4;

input 				clk;			// clock
input				ce;				// clock enable
input				reset_n;		// reset

input  [15:0] 		iaddr;			// this addr latched as start of the buffer when beginning transfer
output reg [15:0] 	oaddr;			// output address bus
output reg[7:0]		odata;			// output data (direct from SPI controller)
output reg			owren;			// RAM write strobe (positive)

input	[3:0]		nblocks;		// input: this is the amount of 512-byte blocks to transfer
									// 		  a non-zero value initiates transfer
output				ready = !busy;	// when 0, the controller has exclusive access to busses

output	[7:0]		ospi_data = 8'hFF;	// this is poked into SPI for data reception
input	[7:0]		ispi_data;		// SPI data input, routed directly to odata output
output	reg			ospi_wr;		// SPI transfer initiator
input				ispi_dsr;		// SPI data ready
output  [7:0]		debug = {rblocks,state};

reg [3:0] rblocks;

reg [15:0]  addrbase;
reg [9:0]  bytectr;

reg [3:0] state;

reg		busy;

always odata <= ispi_data;

always @(posedge clk) 
	if (~reset_n) begin
		busy <= 0;
		rblocks <= 0;
		ospi_wr <= 0;
		owren <= 0;
		state <= IDLE;
	end else if (ce) 
	begin
		case (state)
		IDLE:	
			begin
				if (nblocks != 0) begin
					rblocks <= nblocks;
					busy <= 1;
					addrbase <= iaddr;
					oaddr <= iaddr;
					bytectr <= 512;
					state <= NBYTE;
				end
			end
		NBYTE:
			begin
				ospi_wr <= 1;
				owren <= 0;
				state <= BUSY;
			end
		BUSY:
			begin
				ospi_wr <= 0;
				if (ispi_dsr) begin
					owren <= 1'b1;
					oaddr <= addrbase + (512 - bytectr);
					bytectr <= bytectr - 1'b1;
					
					if (0 == bytectr - 1'b1) 
						state <= BLOCK;		// roll over to next block or end of line
					else 
						state <= NBYTE; 	// initiate next byte
						
				end 
			end
		BLOCK:
			begin
				owren <= 0;
				bytectr <= 512;
				if (rblocks - 1 != 0) begin
					rblocks <= rblocks - 1;
					state <= NBYTE;
				end
				else begin
					state <= OVER;
				end
			end
		OVER: 
			begin
				busy <= 0;
				state <= IDLE;
				owren <= 0;
				ospi_wr <= 0;
				rblocks <= 0;
			end
		endcase
	end

endmodule

