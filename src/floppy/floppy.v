`default_nettype none

// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                Copyright (C) 2007,2008 Viacheslav Slavinsky
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

module floppy(
	clk, ce, reset_n, 
	// sram interface (reserved)
	addr, idata, odata, memwr, 
	// sd card signals
	sd_dat, sd_dat3, sd_cmd, sd_clk, 
	// uart comms
	uart_txd, 
	
	// io ports
	hostio_addr,
	hostio_idata,
	hostio_odata,
	hostio_rd,
	hostio_wr,
	
	// keyboard input for osd menu
	keyboard_keys,
	
	// screen memory
	display_addr,
	display_data,
	display_wren,
	display_idata,
	
	// return from OSD
	osd_command,
	
	// debug 
	green_leds, red_leds, debug, debugidata);
	
parameter IOBASE = 16'hE000;
parameter PORT_MMCA= 0;
parameter PORT_SPDR= 1;
parameter PORT_SPSR= 2;
parameter PORT_JOY = 3;
parameter PORT_TXD = 4;
parameter PORT_RXD = 5;
parameter PORT_CTL = 6;

parameter PORT_TMR1 = 7;
parameter PORT_TMR2 = 8;

parameter PORT_CPU_REQUEST	= 9;
parameter PORT_CPU_STATUS	= 10;
parameter PORT_TRACK		= 11;
parameter PORT_SECTOR		= 12;

parameter PORT_DMA_MSB = 14;	// spi dma target address msb
parameter PORT_DMA_LSB = 15;	// spi dma target address lsb

parameter PORT_LED = 16;
parameter PORT_OSD_COMMAND = 17;		// {F11,F12,HOLD}

input			clk;
input			ce;
input			reset_n;
output	[15:0]	addr = cpu_a;
input	[7:0]	idata;
output	[7:0]	odata = cpu_do;
output			memwr;
input			sd_dat;
output	reg		sd_dat3;
output			sd_cmd;
output			sd_clk;
output			uart_txd;

// I/O interface to host system (Vector)
input	[2:0]	hostio_addr;
input	[7:0]	hostio_idata;
output  [7:0]	hostio_odata;
input			hostio_rd;
input			hostio_wr;

// keyboard interface
input	[5:0]	keyboard_keys;	// {reserved,left,right,up,down,enter}

// screen memory
output	[7:0]	display_addr;
output 	[7:0]	display_data;
output			display_wren;
input   [7:0]	display_idata;

output reg[7:0] osd_command;
output reg[7:0]	green_leds;

output  [7:0]	red_leds = {spi_wren,dma_debug[6:0]};
output	[7:0]	debug = wdport_status;
output	[7:0]	debugidata = {ce & bufmem_en, ce, hostio_rd, wd_ram_rd};

wire [15:0] cpu_ax;
wire		memwrx;
wire [7:0]	cpu_dox;

wire [15:0] cpu_a = dma_ready ? cpu_ax  : dma_oaddr;
assign		memwr = dma_ready ? memwrx  : dma_memwr;
wire [7:0]	cpu_do = dma_ready ? cpu_dox: dma_odata;
reg  [7:0]	cpu_di;

cpu65xx_en cpu(
		.clk(clk),
		.reset(~reset_n),
		.enable(ce & ~(wd_ram_rd|wd_ram_wr|~dma_ready)),
		.nmi_n(1'b1),
		.irq_n(1'b1),
		.di(cpu_di),
		.do(cpu_dox),
		.addr(cpu_ax),
		.we(memwrx)
	);


wire [7:0]  ram_do;
wire [7:0] 	lowmem_do;
wire [7:0]	bufmem_do;
reg  [7:0]	ioports_do;

always begin: _cpu_datain
	case({&cpu_a[15:4], lowmem_en, bufmem_en, rammem_en, osd_en}) 
	5'b10000:	cpu_di <= (cpu_a[0] ? 8'h08:8'h00);
	5'b01000:	cpu_di <= lowmem_do;
	5'b00100:	cpu_di <= bufmem_do;
	5'b00010:	cpu_di <= ram_do;
	5'b00001:	cpu_di <= display_idata;
	default:	cpu_di <= ioports_do;
	endcase
end							

wire lowmem_en = |cpu_a[15:9] == 0;
wire bufmem_en = (wd_ram_rd|wd_ram_wr) || (cpu_a >= 16'h200 && cpu_a < 16'h600);
wire rammem_en = cpu_a >= 16'h0800 && cpu_a < 16'h8000;
wire ioports_en= cpu_a >= IOBASE && cpu_a < IOBASE + 256;
wire osd_en = cpu_a >= IOBASE + 256 && cpu_a < IOBASE + 512;

assign display_addr = cpu_a[7:0];
assign display_data = cpu_do;
assign display_wren = osd_en & memwr;


floppyram flopramnik(
	.address(cpu_a-16'h0800),
	//.inclocken(ce & rammem_en),
	.clock(~clk),
	.data(cpu_do),
	.wren(memwr),
	.q(ram_do)
	);

ram512x8a zeropa(
	.clock(~clk),
	.clken(ce & lowmem_en),
	.address(cpu_a),
	.wren(memwr),
	.data(cpu_do),
	.q(lowmem_do));

//wire	[15:0]	dma_oaddr;
//wire	[7:0]	dma_odata;
//wire			dma_owren;


wire [9:0]	bufmem_addr = (wd_ram_rd|wd_ram_wr) ? wd_ram_addr : cpu_a - 16'h200;
wire 		bufmem_wren = wd_ram_wr | memwr;
wire [7:0]	bufmem_di = wd_ram_wr ? wd_ram_odata : cpu_do;

ram1024x8a bufpa(
	.clock(~clk),
	.clken(ce & bufmem_en),
	.address(bufmem_addr),
	.wren(bufmem_wren),
	.data(bufmem_di),
	.q(bufmem_do));

/////////////////////
// CPU INPUT PORTS //
/////////////////////
always @(negedge clk) begin
	case (cpu_a)		 
	IOBASE+PORT_CTL:	ioports_do <= {7'b0,uart_busy};	// uart status
	IOBASE+PORT_TMR1:	ioports_do <= timer1q;
	IOBASE+PORT_TMR2:	ioports_do <= timer2q;
	IOBASE+PORT_SPDR:	ioports_do <= spdr_do;
	IOBASE+PORT_SPSR:	ioports_do <= {7'b0,~spdr_dsr};
	IOBASE+PORT_CPU_REQUEST:
						ioports_do <= wdport_cpu_request;
	IOBASE+PORT_TRACK:	ioports_do <= wdport_track;
	IOBASE+PORT_SECTOR:	ioports_do <= wdport_sector;
	
	IOBASE+PORT_JOY:	ioports_do <= keyboard_keys;
	default:			ioports_do <= 8'hFF;
	endcase
end

/////////////////////
// CPU OUTPUT PORTS //
/////////////////////
always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		green_leds <= 0;
		uart_state <= 3;
		uart_send <= 0;
		sd_dat3 <= 1;
	end else begin
		if (ce) begin
			if (memwr && cpu_a[15:8] == 8'hE0) begin
				if (cpu_a[7:0] == 8'h10) begin
					green_leds <= cpu_do;
				end
				
				// E004: send data
				if (cpu_a[7:0] == PORT_TXD) begin
					uart_data <= cpu_do;
					uart_state <= 0;
				end
				
				// MMCA: SD/MMC card chip select
				if (cpu_a[7:0] == PORT_MMCA) begin
					sd_dat3 <= cpu_do[0];
				end
				
				// CPU status return
				if (cpu_a[7:0] == PORT_CPU_STATUS) begin
					wdport_cpu_status <= cpu_do;
				end
				
				if (cpu_a[7:0] == PORT_OSD_COMMAND) begin
					osd_command <= cpu_do;
				end
				
				// DMA
				if (cpu_a[7:0] == PORT_DMA_MSB) dma_msb <= cpu_do;
				if (cpu_a[7:0] == PORT_DMA_LSB) dma_lsb <= cpu_do;
				
				if (cpu_a[7:0] == PORT_SPSR) begin
					dma_blocks <= cpu_do[7:4];
				end 
			end
			else dma_blocks <= 4'h0;
			
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

////////////
// TIMERS //
////////////

wire [7:0] timer1q;
wire [7:0] timer2q;

timer100hz timer1(.clk(clk), .di(cpu_do), .wren(ce && cpu_a==(IOBASE+PORT_TMR1) && memwr), .q(timer1q));
timer100hz timer2(.clk(clk), .di(cpu_do), .wren(ce && cpu_a==(IOBASE+PORT_TMR2) && memwr), .q(timer2q));

//////////////////////
// SPI/SD INTERFACE //
//////////////////////

wire [7:0] 	spdr_do;
wire		spdr_dsr;
wire		spi_wren = (ce && (cpu_a == (IOBASE+PORT_SPDR) && memwr)) || dma_spiwr;
spi sd0(.clk(clk),
		.ce(1'b1),
		.reset_n(reset_n),
		.mosi(sd_cmd),
		.miso(sd_dat),
		.sck(sd_clk),
		.di(dma_ready ? cpu_do : dma_spido), 
		.wr(spi_wren), 
		.do(spdr_do), 
		.dsr(spdr_dsr)
		);

reg 	[7:0] 	dma_lsb, dma_msb;
wire	[15:0]	dma_oaddr;
wire	[7:0]	dma_odata;
wire			dma_memwr;
reg		[3:0]	dma_blocks;
wire			dma_ready;
wire	[7:0]	dma_spido;
wire			dma_spiwr;
wire	[7:0]	dma_debug;

dma_rw pump0(
		.clk(clk), 
		.ce(ce), 
		.reset_n(reset_n), 
		.iaddr({dma_msb,dma_lsb}),
		.oaddr(dma_oaddr), 
		.odata(dma_odata),
		.idata(cpu_di), 
		.owren(dma_memwr), 
		.nblocks(dma_blocks), 
		.ready(dma_ready), 
		.ospi_data(dma_spido), 
		.ispi_data(spdr_do), 
		.ospi_wr(dma_spiwr), 
		.ispi_dsr(spdr_dsr),
		.debug(dma_debug));

////////////
// WD1793 //
////////////

// here's how 1793's registers are mapped in Vector-06c
// 00011xxx
//      000		$18 	Data
//	    001		$19 	Sector
//		010		$1A		Track
//		011		$1B		Command/Status
//		100		$1C		Control				Write only

wire [7:0]	wdport_track;
wire [7:0]  wdport_sector;
wire [7:0]	wdport_status;
wire [7:0]	wdport_cpu_request;
reg	 [7:0]	wdport_cpu_status;

wire [9:0]	wd_ram_addr;
wire 		wd_ram_rd;
wire		wd_ram_wr;	
wire [7:0]	wd_ram_odata;	// this is to write to ram


wd1793 vg93(
				.clk(clk), 
				.clken(ce), 
				.reset_n(reset_n),
				
				// host i/o ports 
				.rd(hostio_rd), 
				.wr(hostio_wr), 
				.addr(hostio_addr), 
				.idata(hostio_idata), 
				.odata(hostio_odata), 

				// memory buffer interface
				.buff_addr(wd_ram_addr), 
				.buff_rd(wd_ram_rd), 
				.buff_wr(wd_ram_wr), 
				.buff_idata(bufmem_do), 	// data read from ram
				.buff_odata(wd_ram_odata), 	// data to write to ram
				
				// workhorse interface
				.oTRACK(wdport_track),
				.oSECTOR(wdport_sector),
				.oSTATUS(wdport_status),
				.oCPU_REQUEST(wdport_cpu_request),
				.iCPU_STATUS(wdport_cpu_status)
				);
endmodule

// lower memory:
// 	0000 zeropage  
// 	0100 stack				___ lowmem1
// 	0200 buffer
// 	0600 <end of lowmem> 	___ lowmem2
module ram512x8(clk, ce, addr, wren, di, q);
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

