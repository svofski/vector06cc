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
// Design File: floppy.v
//
// Floppy drive emulation toplevel
//
// --------------------------------------------------------------------

module floppy(clk, ce, reset_n, addr, idata, odata, memwr, sd_dat, sd_dat3, sd_cmd, sd_clk, uart_txd, green_leds, red_leds, debug, debugidata, opcode);
parameter IOBASE = 16'hE000;
parameter PORT_TXD = 4;
parameter PORT_RXD = 5;
parameter PORT_CTL = 6;

input			clk;
input			ce;
input			reset_n;
output	[15:0]	addr = cpu_a;
input	[7:0]	idata;
output	[7:0]	odata = cpu_do;
output			memwr;
inout			sd_dat;
inout			sd_dat3;
inout			sd_cmd;
output			sd_clk;
output			uart_txd;
output reg[7:0]	green_leds;
output  [7:0] red_leds = cpu_di;
output	[7:0]	debug;
output	[7:0]	debugidata = prom_do;
output  [7:0]	opcode;

assign	sd_dat3 = 1'b1;

wire ready = 1'b1;

wire [15:0] cpu_a;
wire [7:0]	cpu_di;
wire [7:0]	cpu_do;

wire cpu_brk;

cpu65xx_en cpu(
		.clk(clk),
		.reset(~reset_n),
		.enable(ce),
		.nmi_n(1),
		.irq_n(1),

		.di(cpu_di),
		.do(cpu_do),
		.addr(cpu_a),
		.we(memwr),
		
		.brkActive(cpu_brk),
		.opcodeDebugOut(opcode),
	);

wire prom_sel = cpu_a[15:10] == 6'b111111;

wire [9:0] 	prom_addr = cpu_a[9:0];
wire [7:0]  prom_do;
wire [7:0]  ram_do;
wire [7:0] 	lowmem_do;
reg  [7:0]	ioports_do;

assign cpu_di = &cpu_a[15:4] ? (cpu_a[0] ? 8'h08:8'h00) // boot addr
							: lowmem_en ? lowmem_do 
							: rammem_en ? ram_do : ioports_do;

wire lowmem_en = |cpu_a[15:9] == 0;
wire rammem_en = cpu_a >= 16'h0800 && cpu_a < 16'h0800 + 32768;
wire ioports_en= cpu_a >= IOBASE && cpu_a < IOBASE + 256;

floppyram flopramnik(
	.address(cpu_a-16'h0800),
	//.inclocken(ce & rammem_en),
	.clock(~clk),
	.data(cpu_do),
	.wren(memwr),
	.q(ram_do)
	);

zeropage zeropa(
	.clk(~clk),
	.ce(ce & lowmem_en),
	.addr(cpu_a),
	.wren(memwr),
	.di(cpu_do),
	.q(lowmem_do));


/////////////////
// INPUT PORTS //
/////////////////
always @(negedge clk) begin
	case (cpu_a)		 
	IOBASE+PORT_CTL:	ioports_do <= {7'b0,uart_busy};	// uart status
	default:			ioports_do <= 8'hFF;
	endcase
end

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		green_leds <= 0;
		uart_state <= 3;
		uart_send <= 0;
	end else begin
		if (ce) begin
			if (memwr && cpu_a == 16'hE010) begin
				green_leds <= cpu_do;
			end
			
			// E004: send data
			if (memwr && cpu_a == IOBASE+PORT_TXD) begin
				uart_data <= cpu_do;
				uart_state <= 0;
			end
			
			// uart state machine
			case (uart_state) 
			0:	begin
					if (~uart_busy) begin
						uart_send <= 1;
						uart_state <= 1;
					end
				end
			1:	begin
					if (uart_busy) begin
						uart_send <= 0;
						uart_state <= 2;
					end
				end
			2:	begin
					if (~uart_busy) begin
						uart_data <= uart_data + 1;
						if (uart_data == 65+27) uart_data <= 65;
						uart_state <= 3;
					end
				end
			3:	begin
				end
			endcase
		end
	end
end


assign debug = {memwr};


reg uart_send;
reg [7:0] uart_data;
wire uart_busy;
reg [1:0] uart_state = 3;

TXD txda( 
	.clk(clk),
	.ld(uart_send),
	.data(uart_data),
	.TxD(uart_txd),
	.txbusy(uart_busy)
   );

endmodule

module zeropage(clk, ce, addr, wren, di, q);
input clk, ce;
input [8:0] addr;
input 		wren;
input [7:0]	di;
output[7:0]	q = ram[addr];

reg [7:0] ram[511:0];

always @(posedge clk) begin
	if (ce) begin
		if (wren) begin
			ram[addr] <= di;
		end 
	end
end

endmodule

