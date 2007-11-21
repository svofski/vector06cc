`default_nettype none

//`define DOUBLE_BUFFER
`define WITH_CPU
`define WITH_KEYBOARD
`define WITH_VI53

module vector06cc(CLOCK_27, KEY[3:0], LEDr[9:0], LEDg[7:0], SW[9:0], HEX0, HEX1, HEX2, HEX3, 
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

		// TEST PIN
		GPIO_0
);
input [1:0]		CLOCK_27;
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

output [10:0] 	GPIO_0;


// CLOCK SETUP
wire mreset_n = KEY[0];
wire mreset = !mreset_n;
wire clk24, clk18;
wire ce12, ce3, ce3v, vi53_timer_ce, video_slice, pipe_ab;

clockster clockmaker(CLOCK_27[0], clk24, clk18, ce12, ce3, ce3v, video_slice, pipe_ab, vi53_timer_ce);

assign AUD_XCK = clk18;
wire tape_input;
soundcodec soundnik(clk18, {vm55int_pc_out[0],vi53_out}, tape_input, mreset_n, AUD_BCLK, AUD_DACDAT, AUD_DACLRCK, AUD_ADCDAT, AUD_ADCLRCK);

reg [15:0] slowclock;
always @(posedge clk24) if (ce3) slowclock <= slowclock + 1'b1;

wire slowclock_enabled  =SW[8] == 1'b0;
wire singleclock_enabled=SW[9] == 1'b0;
wire regular_clock_enabled = !slowclock_enabled & !singleclock_enabled;
wire singleclock;

singleclockster keytapclock(clk24, singleclock_enabled, KEY[1], singleclock);

wire cpu_ce 	= singleclock_enabled ? singleclock : slowclock_enabled ? (slowclock == 0) & ce3 : ce3;


/////////////////
// DEBUG PINS  //
/////////////////
assign GPIO_0[3:0] = {cpu_ce, WR_n, vi53_sel, io_write};
assign GPIO_0[7:4] = {vi53_wren, vi53_out};
assign GPIO_0[8] = clk24;

/////////////////
// CPU SECTION //
/////////////////
wire RESET_n = mreset_n & !blksbr_reset_pulse;
reg READY;
wire HOLD = 0;
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
//assign LEDg = SW[2] ? status_word : {vm55int_pb_out[3:0],video_palette_value[3:0]};
wire [1:0] sw23 = {SW[3],SW[2]};

wire [7:0] kbd_keystatus = {kbd_mod_rus, kbd_key_shift, kbd_key_ctrl, kbd_key_rus, kbd_key_blksbr};

assign LEDg = sw23 == 0 ? status_word : sw23 == 1 ? {kbd_keystatus} : sw23 == 2 ? kvaz_debug : {WR_n, io_stack, SRAM_ADDR[17:15]};
SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3, A);


wire ram_read;
wire ram_write_n;
wire io_write;
wire io_stack;
wire io_read;
wire interrupt_ack;
wire WRN_CPUCE = WR_n | ~cpu_ce;

`ifdef WITH_CPU
	T8080se CPU(RESET_n, clk24, cpu_ce, READY, HOLD, INT, INTE, DBIN, SYNC, VAIT, HLDA, WR_n, A, DI, DO);
	assign ram_read = status_word[7];
	assign ram_write_n = status_word[1];
	assign io_write = status_word[4];
	assign io_stack = status_word[2];
	assign io_read  = status_word[6];
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
			READY <= ~(DO[7] | ~DO[4]);			// insert one wait state on every cycle, it seems to be close to the original
		end 
		else READY <= 1;
		
		address_bus_r <= address_bus[7:0];
	end
end



//////////////
// MEMORIES //
//////////////

wire[7:0] ROM_DO;
lpm_rom0 bootrom(A[11:0], clk24, ROM_DO);


assign SRAM_CE_N = 0;
assign SRAM_OE_N = !rom_access && !ram_write_n && !video_slice;

reg [7:0] address_bus_r;	// registered address for i/o

wire [15:0] address_bus = video_slice & regular_clock_enabled ? VIDEO_A : A;

wire rom_access = (!disable_rom) & (A < 2048);
wire [7:0] sram_data_in;
assign DI = interrupt_ack ? 8'hFF : io_read ? peripheral_data_in : rom_access ? ROM_DO : sram_data_in;

wire [2:0]	ramdisk_page;

sram_map sram_map(SRAM_ADDR[14:0], SRAM_DQ, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N, WRN_CPUCE | ram_write_n | io_write, address_bus, DO, sram_data_in);
assign SRAM_ADDR[17:15] = video_slice ? 3'b000 : ramdisk_page;

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
reg	[7:0] 	video_scroll_reg;
reg [3:0] 	video_palette_address;
reg [7:0] 	video_palette_value;
reg [3:0]	video_border_index;
reg			video_palette_wren;
reg			video_mode512;

wire [3:0] coloridx;
wire border;
wire videoActive;
wire retrace;		// 1 == retrace in progress

video vidi(clk24, ce12, video_slice, pipe_ab,
		   video_mode512, 
		   sram_data_in, VIDEO_A, 
		   VGA_HS, VGA_VS, videoActive, coloridx, border,
		   retrace,
		   video_scroll_reg,
		   GPIO_0[10:9]);
		
wire [7:0] realcolor;		

wire [3:0] paletteram_adr = (retrace|video_palette_wren) ? video_palette_address : border ? video_border_index : coloridx;
palette_ram paletteram(paletteram_adr, video_palette_value, clk24, clk24, video_palette_wren, realcolor);

reg [3:0] video_r;
reg [3:0] video_g;
reg [3:0] video_b;

assign VGA_R = video_r;
assign VGA_G = video_g;
assign VGA_B = video_b;

always @(posedge clk24) begin
	video_r <= !videoActive ? 4'b0 : {realcolor[2:0], 1'b0};
	video_g <= !videoActive ? 4'b0 : {realcolor[5:3], 1'b0};
	video_b <= !videoActive ? 4'b0 : {realcolor[7:6], 2'b00};
end


///////////
// RST38 //
///////////
wire int_request;

oneshot retrace_irq(clk24, cpu_ce, retrace, int_request);


///////////////////
// PS/2 KEYBOARD //
///////////////////
reg 		kbd_mod_rus;
reg	 [7:0]	kbd_rowselect;
wire [7:0]	kbd_rowbits;
wire 		kbd_key_shift;
wire		kbd_key_ctrl;
wire		kbd_key_rus;
wire		kbd_key_blksbr;

`ifdef WITH_KEYBOARD
	vectorkeys kbdmatrix(clk24, mreset, PS2_CLK, PS2_DAT, 
		kbd_mod_rus, 
		kbd_rowselect, 
		kbd_rowbits, 
		kbd_key_shift, kbd_key_ctrl, kbd_key_rus, kbd_key_blksbr);
`else
	assign kbd_rowbits = 8'hff;
	assign kbd_key_shift = 0;
	assign kbd_key_ctrl = 0;
	assign kbd_key_rus = 0;
	assign kbd_key_blksbr = 0;
`endif

///////////////
// I/O PORTS //
///////////////

reg [7:0] peripheral_data_in;
always peripheral_data_in = ~vm55int_oe_n ? vm55int_odata :
							vi53_rden ? vi53_odata : 8'h00;


// Devices:
//   000xxxYY [a7:a0]
//  	000: internal VM55
//		001: external (parport) VM55
//		010: VI53 interval timer
//		011: internal: 	00: palette data out
//						01-11: joystick inputs
//		100: ramdisk bank switching
//		110,111: FDC ports

reg [5:0] portmap_device;				
always portmap_device = address_bus_r[7:2];

///////////////////////
// VM55 #1, internal //
///////////////////////

wire		vm55int_sel = portmap_device == 3'b000;

wire [1:0] 	vm55int_addr = 	~address_bus_r[1:0];
wire [7:0] 	vm55int_idata = DO;	
wire [7:0] 	vm55int_odata;
wire		vm55int_oe_n;

wire vm55int_cs_n = !(/*~ram_write_n &*/ (io_read | io_write) & vm55int_sel);
wire vm55int_rd_n = ~io_read;//~DBIN;
wire vm55int_wr_n = WR_n | ~cpu_ce;

reg [7:0]	vm55int_pa_in;
reg [7:0]	vm55int_pb_in;
reg [7:0]	vm55int_pc_in;

wire [7:0]	vm55int_pa_out;
wire [7:0]	vm55int_pb_out;
wire [7:0]	vm55int_pc_out;

wire [7:0] vm55int_pa_oe_n;
wire [7:0] vm55int_pb_oe_n;
wire [7:0] vm55int_pc_oe_n;

I82C55 vm55int(
	vm55int_addr,
	vm55int_idata,
	vm55int_odata,
	vm55int_oe_n,
	
	vm55int_cs_n,
	vm55int_rd_n,
	vm55int_wr_n,
	
	vm55int_pa_in,
	vm55int_pa_out,
	vm55int_pa_oe_n,				// enable always
	
	vm55int_pb_in,					// see keyboard
	vm55int_pb_out,
	vm55int_pb_oe_n,				// enable always
	
	vm55int_pc_in,
	vm55int_pc_out,
	vm55int_pc_oe_n,				// enable always
	
	mreset, 	// active 1
	
	cpu_ce,
	clk24);

always @(posedge clk24) begin
	//if (cpu_ce) begin
		// port A
		if (retrace) begin
			kbd_rowselect <= ~vm55int_pa_out;
		end
		else begin
			video_scroll_reg <= vm55int_pa_out;
		end
		
		// port B
		if (retrace) begin
			video_palette_address <= vm55int_pb_out[3:0];
		end
		else begin
			video_border_index <= vm55int_pb_out[3:0];
`ifdef WITH_CPU
			video_mode512 <= vm55int_pb_out[4];
`else
			video_mode512 <= 1'b0;
`endif
		end

		// port C
		gledreg[9] <= vm55int_pc_out[3];		// RUS/LAT LED
	//end
end	

always @(kbd_rowbits) vm55int_pb_in <= ~kbd_rowbits;
always @(kbd_key_shift or kbd_key_ctrl or kbd_key_rus) begin
	vm55int_pc_in[5] <= ~kbd_key_shift;
	vm55int_pc_in[6] <= ~kbd_key_ctrl;
	vm55int_pc_in[7] <= ~kbd_key_rus;
end
always @(tape_input) vm55int_pc_in[4] <= tape_input;


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
wire iports_palette_sel = address_bus[1:0] == 2'b00;

always @(posedge clk24) begin
	if (iports_write & ~WR_n & cpu_ce) begin
		video_palette_value <= DO;
		video_palette_wren <= 1'b1;
	end 
	else 
		video_palette_wren <= 1'b0;
end

///////////////////
// BLK+SBR: KEY3 //
///////////////////
reg 	disable_rom = 0;
reg		rst0toggle = 0;
wire	blksbr_reset_pulse;
always @(posedge clk24) begin
	if (mreset) begin
		disable_rom <= 0;
		rst0toggle <= 0;
		gledreg[8] <= 0;
	end
	else if (cpu_ce) begin
		if (KEY[3] == 1'b0 || kbd_key_blksbr == 1'b1) begin
			disable_rom <= 1;
			rst0toggle <= 1;
			gledreg[8] <= 1;
		end
		else rst0toggle <= 0;
	end 
end
oneshot blksbr(clk24, cpu_ce, rst0toggle, blksbr_reset_pulse);

I2C_AV_Config 		u7(clk24,mreset_n,I2C_SCLK,I2C_SDAT);

endmodule


// $Id$