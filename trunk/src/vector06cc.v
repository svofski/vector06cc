// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: vector06cc.v
//
// Top-level design file of Vector-06C replica.
//
// Switches, as they are configured now:
//	SW1:SW0			red LED[7:0] display selector: 
// 						00:	Data In
//						01: Data Out
//						11: registered Data Out
//
// 	SW3:SW2			green LED group display selector
//						00:	registered CPU status word
//						01: keyboard status/testpins
//						10: RAM disk test pins
//						11: WR_n, io_stack, SRAM_ADDR[17:15] (RAM disk page)
//
//	SW4				HEX display
//						 0:	CPU address bus
//						 1: TState counter
//
//	SW6				disable tape in
//
//  SW5				not used
//
//	SW7				manual bus hold, recommended for SRAM <-> JTAG exchange operations
//
//					These must be 1 for normal operation:
//	SW8				slow clock, code is executed at eyeballable speed
//	SW9				single-clock, tap clock by KEY[1]
//			
//
// --------------------------------------------------------------------


`default_nettype none

// Undefine following for smaller/faster builds
`define WITH_CPU			
`define WITH_KEYBOARD
`define WITH_VI53
`define WITH_AY
`define WITH_FLOPPY
`define FLOPPYLESS_HAX	// set FDC odata to $00 when compiling without floppy
`define WITH_OSD
`define WITH_DE1_JTAG
`define JTAG_AUTOHOLD
`define TWO_PLL_OK 		// use second PLL to generate clean 14.0MHz for the AY, use 14.4MHz otherwise

module vector06cc(CLOCK_27, clk50mhz, KEY[3:0], LEDr[9:0], LEDg[7:0], SW[9:0], HEX0, HEX1, HEX2, HEX3, 
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		 
		VGA_HS,
		VGA_VS,
		VGA_R,
		VGA_G,
		VGA_B, 
		
		////////////////////	I2C		////////////////////////////
		I2C_SDAT,						//	I2C Data
		I2C_SCLK,						//	I2C Clock
		
		AUD_BCLK, 
		AUD_DACDAT, 
		AUD_DACLRCK,
		AUD_XCK,
		AUD_ADCLRCK,
		AUD_ADCDAT,

		PS2_CLK,
		PS2_DAT,

		////////////////////	USB JTAG link	////////////////////
		TDI,  							// CPLD -> FPGA (data in)
		TCK,  							// CPLD -> FPGA (clk)
		TCS,  							// CPLD -> FPGA (CS)
	    TDO,  							// FPGA -> CPLD (data out)

		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		
		///////////////////// USRAT //////////////////////
		UART_TXD,
		UART_RXD,

		// TEST PIN
		GPIO_0
);
input [1:0]		CLOCK_27;
input			clk50mhz;
input [3:0] 	KEY;
output [9:0] 	LEDr;
output [7:0] 	LEDg;
input [9:0] 	SW; 

output [6:0] 	HEX0;
output [6:0] 	HEX1;
output [6:0] 	HEX2;
output [6:0] 	HEX3;

////////////////////////	SRAM Interface	////////////////////////
inout	[15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output	[17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask 
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable

/////// VGA
output 			VGA_HS;
output 			VGA_VS;
output	[3:0] 	VGA_R;
output	[3:0] 	VGA_G;
output	[3:0] 	VGA_B;

////////////////////////	I2C		////////////////////////////////
inout			I2C_SDAT;				//	I2C Data
output			I2C_SCLK;				//	I2C Clock

inout			AUD_BCLK;
output			AUD_DACDAT;
output			AUD_DACLRCK;
output			AUD_XCK;

output			AUD_ADCLRCK;			//	Audio CODEC ADC LR Clock
input			AUD_ADCDAT;				//	Audio CODEC ADC Data


input			PS2_CLK;
input			PS2_DAT;

////////////////////	USB JTAG link	////////////////////////////
input  			TDI;					// CPLD -> FPGA (data in)
input  			TCK;					// CPLD -> FPGA (clk)
input  			TCS;					// CPLD -> FPGA (CS)
output 			TDO;					// FPGA -> CPLD (data out)

////////////////////	SD Card Interface	////////////////////////
input			SD_DAT;					//	SD Card Data 			(MISO)
output			SD_DAT3;				//	SD Card Data 3 			(CSn)
output			SD_CMD;					//	SD Card Command Signal	(MOSI)
output			SD_CLK;					//	SD Card Clock			(SCK)

output			UART_TXD;
input			UART_RXD;

output [12:0] 	GPIO_0;


// CLOCK SETUP
wire mreset_n = KEY[0] & ~kbd_key_blkvvod;
wire mreset = !mreset_n;
wire clk24, clk18, clk14;
wire ce12, ce6, ce3, ce3v, vi53_timer_ce, video_slice, pipe_ab;

clockster clockmaker(
	.clk(CLOCK_27), 
	.clk50(clk50mhz),
	.clk24(clk24), 
	.clk18(clk18), 
	.clk14(clk14),
	.ce12(ce12), 
	.ce6(ce6),
	.ce3(ce3), 
	.ce3v(ce3v), 
	.video_slice(video_slice), 
	.pipe_ab(pipe_ab), 
	.ce1m5(vi53_timer_ce));
	

assign AUD_XCK = clk18;
wire tape_input;
soundcodec soundnik(
					.clk18(clk18), 
					.pulses({vv55int_pc_out[0],vi53_out}), 
					.pcm(ay_sound),
					.tapein(tape_input), 
					.reset_n(mreset_n),
					.oAUD_XCK(AUD_XCK),
					.oAUD_BCK(AUD_BCLK), 
					.oAUD_DATA(AUD_DACDAT),
					.oAUD_LRCK(AUD_DACLRCK),
					.iAUD_ADCDAT(AUD_ADCDAT), 
					.oAUD_ADCLRCK(AUD_ADCLRCK),
				   );

reg [15:0] slowclock;
always @(posedge clk24) if (ce3) slowclock <= slowclock + 1'b1;

reg  breakpoint_condition;

wire slowclock_enabled  =SW[8] == 1'b0;
wire singleclock_enabled=SW[9] == 1'b0 || breakpoint_condition;
wire regular_clock_enabled = !slowclock_enabled & !singleclock_enabled & !breakpoint_condition;
wire singleclock;

singleclockster keytapclock(clk24, singleclock_enabled, KEY[1], singleclock);

wire cpu_ce 	= singleclock_enabled ? singleclock : slowclock_enabled ? (slowclock == 0) & ce3 : ce3;

reg [15:0] clock_counter;
always @(posedge clk24) begin
	if (~RESET_n) 
		clock_counter <= 0;
	else if (cpu_ce & ~halt_ack) 
		clock_counter <= clock_counter + 1'b1;
end

/////////////////
// WAIT STATES //
/////////////////

// a very special waitstate generator
reg [4:0] 	ws_counter;
reg 		ws_latch;
always @(posedge clk24) ws_counter <= ws_counter + 1'b1;
wire [3:0] ws_rom = ws_counter[4:1];
wire ws_cpu_time = ws_rom[2] & ws_rom[1] & ws_rom[3];
wire ws_req_n = ~(DO[7] | ~DO[1]) | DO[4] | DO[6];	// == 0 when cpu wants cock
//wire ws_req_n = ~(DO[7] | ~DO[1] | DO[4] | DO[6]); // enable waitstates for in/out

always @(posedge clk24) begin
	if (cpu_ce) begin
		if (SYNC) begin
			// if this is not a cpu slice (ws_rom[2]) and cpu wants access, latch the ws flag
			if (~ws_req_n & ~ws_cpu_time) begin
				READY <= 0;
			end
`ifdef WITH_BREAKPOINTS			
			if (singleclock) begin
                breakpoint_condition <= 0;
            end
			else if (A == 16'h0100) begin
                breakpoint_condition <= 1;
            end
`else
            breakpoint_condition <= 0;
`endif
		end 
	end
	// reset the latch when it's time
	if (ws_cpu_time) begin
		READY <= 1;
	end
end



/////////////////
// DEBUG PINS  //
/////////////////
assign GPIO_0[8:0] = {clk24, ce12, ce6, ce3, ce3v, video_slice, pipe_ab, vi53_timer_ce, pipe_ab};

/////////////////
// CPU SECTION //
/////////////////
wire RESET_n = mreset_n & !blksbr_reset_pulse;
reg READY;
wire HOLD = jHOLD | SW[7] | osd_command_bushold | floppy_death_by_floppy;
wire INT = int_request;
wire INTE;
wire DBIN;
wire SYNC;
wire VAIT;
wire HLDA;
wire WR_n;

wire [15:0] VIDEO_A;
wire [15:0] A;
wire [7:0] DI;
wire [7:0] DO;


reg[7:0] status_word;

reg[9:0] gledreg;

assign LEDr[7:0] = SW[0] == 0 ? DI : SW[1] == 0 ? DO : gledreg[7:0];
assign LEDr[9:8] = gledreg[9:8];
//assign LEDg = SW[2] ? status_word : {vv55int_pb_out[3:0],video_palette_value[3:0]};
wire [1:0] sw23 = {SW[3],SW[2]};

wire [7:0] kbd_keystatus = {kbd_mod_rus, kbd_key_shift, kbd_key_ctrl, kbd_key_rus, kbd_key_blksbr};

assign LEDg = sw23 == 0 ? status_word 
			: sw23 == 1 ? floppy_leds//{floppy_rden,floppy_odata[6:0]}//{kbd_keystatus} 
			: sw23 == 2 ? floppy_status 
			: {vi53_timer_ce, INT, interrupt_ack, mJTAG_SELECT, mJTAG_SRAM_WR_N, SRAM_ADDR[17:15]};
			
SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3, SW[4] ? clock_counter : A);


wire ram_read;
wire ram_write_n;
wire io_write;
wire io_stack;
wire io_read;
wire interrupt_ack;
wire halt_ack;
wire WRN_CPUCE = WR_n | ~cpu_ce;

`ifdef WITH_CPU
	T8080se CPU(RESET_n, clk24, cpu_ce, READY, HOLD, INT, INTE, DBIN, SYNC, VAIT, HLDA, WR_n, A, DI, DO);
	assign ram_read = status_word[7];
	assign ram_write_n = status_word[1];
	assign io_write = status_word[4];
	assign io_stack = status_word[2];
	assign io_read  = status_word[6];
	assign halt_ack = status_word[3];
	assign interrupt_ack = status_word[0];
`else
	assign WR_n = 1;
	assign DO = 8'h00;
	assign A = 16'hffff;
	assign ram_read = 0;
	assign ram_write_n = 1;
	assign io_write = 0;
	assign io_stack = 0;
	assign io_read  = 0;
	assign interrupt_ack = 1;
`endif

always @(posedge clk24) begin
	if (cpu_ce) begin
		if (WR_n == 0) gledreg[7:0] <= DO;
		if (SYNC) begin
			status_word <= DO;
			//READY <= ~(DO[7] | ~DO[1]) | DO[4];			// insert one wait state on every cycle, it seems to be close to the original
		end 
		//else READY <= 1;
		
		address_bus_r <= address_bus[7:0];
	end
end



//////////////
// MEMORIES //
//////////////

wire[7:0] ROM_DO;
lpm_rom0 bootrom(A[11:0], clk24, ROM_DO);


assign SRAM_CE_N = 0;
assign SRAM_OE_N = !rom_access && !ram_write_n && !video_slice && !mJTAG_SRAM_WR_N;

reg [7:0] address_bus_r;	// registered address for i/o

wire [15:0] address_bus = video_slice & regular_clock_enabled ? VIDEO_A : A;

wire rom_access = (!disable_rom) & (A < 2048);
wire [7:0] sram_data_in;
assign DI = interrupt_ack ? 8'hFF : io_read ? peripheral_data_in : rom_access ? ROM_DO : sram_data_in;

wire [2:0]	ramdisk_page;

sram_map sram_map(
	.SRAM_ADDR(SRAM_ADDR), 
	.SRAM_DQ(SRAM_DQ), 
	.SRAM_WE_N(SRAM_WE_N), 
	.SRAM_UB_N(SRAM_UB_N), 
	.SRAM_LB_N(SRAM_LB_N), 
	.memwr_n(WRN_CPUCE | ram_write_n | io_write), 
	.abus(address_bus), 
	.dout(DO), 
	.din(sram_data_in),
	.ramdisk_page(video_slice ? 3'b000 : ramdisk_page),
	.jtag_addr(mJTAG_ADDR),
	.jtag_din(mJTAG_DATA_FROM_HOST),
	.jtag_do(mJTAG_DATA_TO_HOST),
	.jtag_jtag(mJTAG_SELECT),
	.jtag_nwe(mJTAG_SRAM_WR_N));
	

wire [7:0] 	kvaz_debug;
wire		ramdisk_control_write = address_bus_r == 8'h10 && io_write & ~WR_n; 
kvaz ramdisk(
	.clk(clk24), 
	.clke(cpu_ce), 
	.reset(mreset),
	.address(address_bus),
	.select(ramdisk_control_write),
	.data_in(DO),
	.stack(io_stack), 
	.memwr(~ram_write_n), 
	.memrd(ram_read), 
	.bigram_addr(ramdisk_page),
	.debug(kvaz_debug)
);


///////////
// VIDEO //
///////////
wire [7:0] 	video_scroll_reg = vv55int_pa_out;
reg [7:0] 	video_palette_value;
reg [3:0]	video_border_index;
reg			video_palette_wren;
reg			video_mode512;

wire [3:0] coloridx;
wire retrace;			// 1 == retrace in progress

wire vga_vs;
wire vga_hs;


wire 		tv_mode = SW[5];

wire 		tv_sync;
wire [7:0] 	tv_luma;
wire [7:0]	tv_chroma;

video vidi(.clk24(clk24), .ce12(ce12), .ce6(ce6), .video_slice(video_slice), .pipe_ab(pipe_ab),
		   .mode512(video_mode512), 
		   .SRAM_DQ(sram_data_in), .SRAM_ADDR(VIDEO_A), 
		   .hsync(vga_hs), .vsync(vga_vs), 
		   .osd_hsync(osd_hsync), .osd_vsync(osd_vsync),
		   .coloridx(coloridx),
		   .realcolor_in(realcolor2buf),
		   .realcolor_out(realcolor),
		   .retrace(retrace),
		   .video_scroll_reg(video_scroll_reg),
		   .border_idx(video_border_index),
		   .testpin(GPIO_0[12:9]),
		   .tv_sync(tv_sync),
		   .tv_luma(tv_luma));
		
wire [7:0] realcolor;		// this truecolour value fetched from buffer directly to display
wire [7:0] realcolor2buf;	// this truecolour value goes into the scan doubler buffer

wire [3:0] paletteram_adr = (retrace/*|video_palette_wren*/) ? video_border_index : coloridx;

palette_ram paletteram(paletteram_adr, video_palette_value, clk24, clk24, video_palette_wren, realcolor2buf);

reg [3:0] video_r;
reg [3:0] video_g;
reg [3:0] video_b;

assign VGA_R = tv_mode ? tv_luma : video_r;
assign VGA_G = tv_mode ? 0       : video_g;
assign VGA_B = tv_mode ? 0       : video_b;
assign VGA_VS= tv_mode ? 0 		 : vga_vs;
assign VGA_HS= tv_mode ? tv_sync : vga_hs;

wire [1:0] 	lowcolor_b = {2{osd_active}} & {realcolor[7],1'b0};
wire 		lowcolor_g = osd_active & realcolor[5];
wire 		lowcolor_r = osd_active & realcolor[2];

wire [7:0] 	overlayed_colour = osd_active ? osd_colour : realcolor;

always @(posedge clk24) begin
	video_r <= {overlayed_colour[2:0], lowcolor_r};
	video_g <= {overlayed_colour[5:3], lowcolor_g};
	video_b <= {overlayed_colour[7:6], lowcolor_b};
end


///////////
// RST38 //
///////////

// Retrace irq delay:
// For 36 seems to be the best compromise. m@color looks great and Black Ice isn't too broken
// At 32, m@color demo starts showing horizontal stripes across the entire screen
// Now the real problem is: nobody knows how it's ought to look!
wire int_delay;
reg int_request;
wire int_rq_tick;
//wire int_rq_tick_inte;
reg  int_rq_hist;

// 36: sssshhh in the evolution pic, skynet does not pass (?)
// 34: no visible changes in m@color or b-ice, skynet passes, trr in evolution pic, pentium bug
// 33: trrr in skynet (evolution pic)
// 32: no visible changes in m@color, tv shifts left in b-ice (which is nice), skynet breaks+
// 31: trrrr between skynet parts, but passes with pentium bug
// 30: no visible changes in m@color, tv in b-ice as in 32, skynet passes with the usual pentium bug -- breaks
// 29: is the absolute limit, b-ice breaks
oneshot #(10'd33) retrace_delay(clk24, cpu_ce, retrace, int_delay);
oneshot #(10'd191) retrace_irq(clk24, cpu_ce, ~int_delay, int_rq_tick);

//assign int_rq_tick_inte = ~interrupt_ack & INTE & int_rq_tick;

always @(posedge clk24) begin
    int_rq_hist <= int_rq_tick;
    
    if (~int_rq_hist & int_rq_tick & INTE) 
        int_request <= 1;
    
    if (interrupt_ack)
        int_request <= 0;
end

//oneshot #(144) retrace_irq(clk24, 1, retrace, int_request);


///////////////////
// PS/2 KEYBOARD //
///////////////////
reg 		kbd_mod_rus;
wire [7:0]	kbd_rowselect = ~vv55int_pa_out;
wire [7:0]	kbd_rowbits;
wire 		kbd_key_shift;
wire		kbd_key_ctrl;
wire		kbd_key_rus;
wire		kbd_key_blksbr;
wire		kbd_key_blkvvod = kbd_key_blkvvod_phy | osd_command_f11;
wire		kbd_key_blkvvod_phy;
wire		kbd_key_scrolllock;
wire [5:0]	kbd_keys_osd;

`ifdef WITH_KEYBOARD
	vectorkeys kbdmatrix(
		.clkk(clk24), 
		.reset(~KEY[0]), 
		.ps2_clk(PS2_CLK), 
		.ps2_dat(PS2_DAT), 
		.mod_rus(kbd_mod_rus), 
		.rowselect(kbd_rowselect), 
		.rowbits(kbd_rowbits), 
		.key_shift(kbd_key_shift), 
		.key_ctrl(kbd_key_ctrl), 
		.key_rus(kbd_key_rus), 
		.key_blksbr(kbd_key_blksbr), 
		.key_blkvvod(kbd_key_blkvvod_phy),
		.key_bushold(kbd_key_scrolllock),
		.key_osd(kbd_keys_osd),
		.osd_active(scrollock_osd)
		);
`else
	assign kbd_rowbits = 8'hff;
	assign kbd_key_shift = 0;
	assign kbd_key_ctrl = 0;
	assign kbd_key_rus = 0;
	assign kbd_key_blksbr = 0;
	assign kbd_key_blkvvod_phy = 0;
	assign kbd_key_scrolllock = 0;
`endif



///////////////
// I/O PORTS //
///////////////

reg [7:0] peripheral_data_in;

// Priority encoder is a poor choice for bus selector, see case below, works much better
//
//always peripheral_data_in = ~vv55int_oe_n ? vv55int_odata :
//							vi53_rden ? vi53_odata : 
//							floppy_rden ? floppy_odata : 
//							~vv55pu_oe_n ? vv55pu_odata : 8'hFF;
always
	case ({ay_rden, ~vv55int_oe_n, vi53_rden, floppy_rden, vv55pu_rden}) 
		5'b10000: peripheral_data_in <= ay_odata;
		5'b01000: peripheral_data_in <= vv55int_odata;
		5'b00100: peripheral_data_in <= vi53_odata;
		5'b00010: peripheral_data_in <= floppy_odata;
		5'b00001: peripheral_data_in <= vv55pu_odata;
		default: peripheral_data_in <= 8'hFF;
	endcase

// Devices:
//   000xxxYY [a7:a0]
//  	000: internal VV55
//		001: external VV55 (PU)
//		010: VI53 interval timer
//		011: internal: 	00: palette data out
//						01-11: joystick inputs
//		100: ramdisk bank switching
//		101: AY-3-8910, ports 14, 15 (00, 01)
//		110: FDC ($18-$1B)
//      111: FDC ($1C, secondary control reg)

reg [5:0] portmap_device;				
always portmap_device = address_bus_r[7:2];



///////////////////////
// vv55 #1, internal //
///////////////////////

wire		vv55int_sel = portmap_device == 3'b000;

wire [1:0] 	vv55int_addr = 	~address_bus_r[1:0];
wire [7:0] 	vv55int_idata = DO;	
wire [7:0] 	vv55int_odata;
wire		vv55int_oe_n;

wire vv55int_cs_n = !(/*~ram_write_n &*/ (io_read | io_write) & vv55int_sel);
wire vv55int_rd_n = ~io_read;//~DBIN;
wire vv55int_wr_n = WR_n | ~cpu_ce;

reg [7:0]	vv55int_pa_in;
reg [7:0]	vv55int_pb_in;
reg [7:0]	vv55int_pc_in;

wire [7:0]	vv55int_pa_out;
wire [7:0]	vv55int_pb_out;
wire [7:0]	vv55int_pc_out;

wire [7:0] vv55int_pa_oe_n;
wire [7:0] vv55int_pb_oe_n;
wire [7:0] vv55int_pc_oe_n;

I82C55 vv55int(
	vv55int_addr,
	vv55int_idata,
	vv55int_odata,
	vv55int_oe_n,
	
	vv55int_cs_n,
	vv55int_rd_n,
	vv55int_wr_n,
	
	vv55int_pa_in,
	vv55int_pa_out,
	vv55int_pa_oe_n,				// enable always
	
	vv55int_pb_in,					// see keyboard
	vv55int_pb_out,
	vv55int_pb_oe_n,				// enable always
	
	vv55int_pc_in,
	vv55int_pc_out,
	vv55int_pc_oe_n,				// enable always
	
	mreset, 	// active 1
	
	cpu_ce,
	clk24);

always @(posedge clk24) begin
	// port B
	video_border_index <= vv55int_pb_out[3:0];	// == palette address for out $0C

`ifdef WITH_CPU
	video_mode512 <= vv55int_pb_out[4];
`else
	video_mode512 <= 1'b0;
`endif
	// port C
	gledreg[9] <= vv55int_pc_out[3];		// RUS/LAT LED
end	

always @(kbd_rowbits) vv55int_pb_in <= ~kbd_rowbits;
always @(kbd_key_shift or kbd_key_ctrl or kbd_key_rus) begin
	vv55int_pc_in[5] <= ~kbd_key_shift;
	vv55int_pc_in[6] <= ~kbd_key_ctrl;
	vv55int_pc_in[7] <= ~kbd_key_rus;
end
always @(tape_input, SW) vv55int_pc_in[4] <= ~SW[6] & tape_input;
always @* vv55int_pc_in[3:0] <= 4'b1111;


//////////////////////
// vv55 #1, fake PU //
//////////////////////
wire		vv55pu_sel = portmap_device == 3'b001;

wire [1:0] 	vv55pu_addr = 	~address_bus_r[1:0];
wire [7:0] 	vv55pu_idata = DO;	
wire [7:0] 	vv55pu_odata;

wire 		vv55pu_rden = io_read & vv55pu_sel;
wire 		vv55pu_wren = ~WR_n & io_write & vv55pu_sel;

fake8255 fakepaw0(
	.clk(clk24),
	.ce(cpu_ce),
	.addr(vv55pu_addr),
	.idata(DO),
	.odata(vv55pu_odata),
	.wren(vv55pu_wren),
	.rden(vv55pu_rden));



////////////////////////////////
// 580VI53 timer: ports 08-0B //
////////////////////////////////
wire			vi53_sel = portmap_device == 3'b010;
wire			vi53_wren = ~WR_n & io_write & vi53_sel; 
wire			vi53_rden = io_read & vi53_sel;
wire	[2:0] 	vi53_out;
wire	[7:0]	vi53_odata;
wire	[9:0]	vi53_testpin;

`ifdef WITH_VI53
pit8253 vi53(
			clk24, 
			cpu_ce, 
			vi53_timer_ce, 
			~address_bus_r[1:0], 
			vi53_wren, 
			vi53_rden, 
			DO, 
			vi53_odata, 
			3'b111, 
			vi53_out, 
			vi53_testpin);
`endif



////////////////////////////
// Internal ports, $0C -- //
////////////////////////////
wire		iports_sel 		= portmap_device == 3'b011;
wire		iports_write 	= /*~ram_write_n &*/ io_write & iports_sel; // this repeats as a series of 3 _|||_ wtf

// port $0C-$0F: palette value out
wire iports_palette_sel = address_bus[1:0] == 2'b00;		// not used <- must be fixed some day

always @(posedge clk24) begin
	if (iports_write & ~WR_n & cpu_ce) begin
		video_palette_value <= DO;
		video_palette_wren <= 1'b1;
	end 
	else 
		video_palette_wren <= 1'b0;
end



//////////////////////////////////
// Floppy Disk Controller ports //
//////////////////////////////////

wire [7:0]	osd_command;

wire		osd_command_bushold = osd_command[0];
wire		osd_command_f12		= osd_command[1];
wire		osd_command_f11		= osd_command[2];

wire [7:0]	floppy_leds;

wire		floppy_sel = portmap_device[2:1] == 2'b11; // both 110 and 111
wire		floppy_wren = ~WR_n & io_write & floppy_sel;
wire		floppy_rden  = io_read & floppy_sel;

wire		floppy_death_by_floppy;

`ifdef WITH_FLOPPY
wire [7:0]	floppy_odata;
wire [7:0]	floppy_status;

floppy flappy(
	.clk(clk24), 
	.ce(ce3v),  
	.reset_n(KEY[0]), 		// to make it possible to change a floppy image, then press F11
	
	// sd card signals
	.sd_dat(SD_DAT), 
	.sd_dat3(SD_DAT3), 
	.sd_cmd(SD_CMD), 
	.sd_clk(SD_CLK), 
	
	// uart comms
	.uart_txd(UART_TXD),
	
	// io ports
	.hostio_addr({address_bus_r[2],~address_bus_r[1:0]}),
	.hostio_idata(DO),
	.hostio_odata(floppy_odata),
	.hostio_rd(floppy_rden),
	.hostio_wr(floppy_wren),
	
	// screen memory
	.display_addr(osd_address),
	.display_data(osd_data),
	.display_wren(osd_wren),
	.display_idata(osd_q),
	
	.keyboard_keys(kbd_keys_osd),
	
	.osd_command(osd_command),
	
	// debug 
	.green_leds(floppy_leds),
	//.red_leds(floppy_leds),
	.debug(floppy_status),
	.host_hold(floppy_death_by_floppy),
	);
	//green_leds, red_leds, debug, debugidata);

`else 
assign floppy_death_by_floppy = 0;
wire [7:0]	floppy_odata = 
`ifdef FLOPPYLESS_HAX
	8'h00;
`else
	8'hFF;
`endif	
wire [7:0]	floppy_status = 8'hff;
`endif



///////////////////////
// On-Screen Display //
///////////////////////
wire			osd_hsync, osd_vsync; 	// provided by video.v
reg				osd_active;
reg	[7:0]		osd_colour;
always @(posedge clk24)
	if (scrollock_osd & osd_bg) begin
		osd_active <= 1;
		osd_colour <= osd_fg ? 8'b11111110 : 8'b01011001;	// slightly greenish tint hopefully
	end else 
		osd_active <= 0;

wire			osd_fg;
wire			osd_bg;
wire			osd_wren;
wire[7:0]		osd_data;
wire[7:0]		osd_rq;
wire[7:0]		osd_address;

wire[7:0]		osd_q = osd_rq + 8'd32;

`ifdef WITH_OSD
textmode osd(
	.clk(clk24),
	.ce(1'b1),
	.vsync(osd_vsync),
	.hsync(osd_hsync),
	.pixel(osd_fg),
	.background(osd_bg),
	.address(osd_address),
	.data(osd_data - 8'd32),		// OSD encoding has 00 == 32
	.wren(osd_wren),
	.q(osd_rq)
	);
`else
assign osd_fg = 0;
assign osd_bg = 0;
assign osd_rq  = 0;
`endif



////////
// AY //
////////
wire [7:0]	ay_odata;

`ifdef WITH_AY
wire		ay_sel = portmap_device == 3'b101 && address_bus_r[1] == 0; // only ports $14 and $15
wire		ay_wren = ~WR_n & io_write & ay_sel;
wire		ay_rden = io_read & ay_sel;
wire [7:0]	ay_sound;

reg [2:0] aycectr;
always @(posedge clk14) aycectr <= aycectr + 1'd1;

ayglue shrieker(.clk(clk14), 
				.ce(aycectr == 0),
				.reset_n(mreset_n), 
				.address(address_bus_r[0]),
				.data(DO), 
				.q(ay_odata),
				.wren(ay_wren),
				.rden(ay_rden),
				.sound(ay_sound));
`else
wire [7:0] 	ay_sound = 8'b0;
wire		ay_rden = 1'b0;
assign		ay_odata = 8'hFF;
`endif



//////////////////
// Special keys //
//////////////////

wire	scrollock_osd;
wire	blksbr_reset_pulse;
wire	disable_rom;

specialkeys skeys(
				.clk(clk24), 
				.cpu_ce(cpu_ce),
				.reset_n(mreset_n), 
				.key_blksbr(KEY[3] == 1'b0 || kbd_key_blksbr == 1'b1 || osd_command_f12), 
				.key_osd(kbd_key_scrolllock),
				.o_disable_rom(disable_rom),
				.o_blksbr_reset(blksbr_reset_pulse),
				.o_osd(scrollock_osd)
				);
				
always gledreg[8] <= disable_rom;				

I2C_AV_Config 		u7(clk24,mreset_n,I2C_SCLK,I2C_SDAT);

/////////////////
//   DE1 JTAG  //
/////////////////

// JTAG access to SRAM
wire [17:0]	mJTAG_ADDR;
wire [15:0]	mJTAG_DATA_TO_HOST,mJTAG_DATA_FROM_HOST;
wire		mJTAG_SRAM_WR_N;
wire 		mJTAG_SELECT;

wire		jHOLD;

jtag_top	tigertiger(
				.clk24(clk24),
				.reset_n(mreset_n),
				.oHOLD(jHOLD),
				.iHLDA(HLDA),
				.iTCK(TCK),
				.oTDO(TDO),
				.iTDI(TDI),
				.iTCS(TCS),
				.oJTAG_ADDR(mJTAG_ADDR),
				.iJTAG_DATA_TO_HOST(mJTAG_DATA_TO_HOST),
				.oJTAG_DATA_FROM_HOST(mJTAG_DATA_FROM_HOST),
				.oJTAG_SRAM_WR_N(mJTAG_SRAM_WR_N),
				.oJTAG_SELECT(mJTAG_SELECT)
				);

endmodule

///////////////////////
// Fake 8255 for PPI //
///////////////////////
module fake8255(clk, ce, addr, idata, odata, wren, rden);
input 		clk;
input 		ce;
input [1:0]	addr;
input [7:0]	idata;
output[7:0] odata;
input		wren;
input		rden;

assign odata = 8'h00;

/*
assign odata = fakepu_regs[addr];
reg [7:0] fakepu_regs[3:0];
always @(posedge clk24) if (ce) begin: _fake_pu
	if (vv55pu_wren) begin
		fakepu_regs[addr] = idata;
	end
end
*/
endmodule


// $Id$