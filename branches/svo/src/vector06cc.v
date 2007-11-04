`default_nettype none

module vector06cc(clk50mhz, KEY[3:0], LEDr[9:0], LEDg[7:0], SW[9:0], HEX0, HEX1, HEX2, HEX3, 
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

		PS2_CLK,
		PS2_DAT,

		// TEST PIN
		GPIO_0
);
input clk50mhz;
input [3:0] KEY;
output [9:0] LEDr;
output [7:0] LEDg;
input [9:0] SW; 

output [6:0] HEX0;
output [6:0] HEX1;
output [6:0] HEX2;
output [6:0] HEX3;

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

input			PS2_CLK;
input			PS2_DAT;

output [10:0] GPIO_0;


// CLOCK SETUP
wire mreset_n = KEY[0];
wire mreset = !mreset_n;
wire clk24;
wire ce12, ce3, ce3v, cepipe1, cepipe2, video_slice, pipe_ab;

clockster clockmaker(clk50mhz, clk24, ce12, ce3, ce3v, video_slice, pipe_ab, cepipe1, cepipe2);


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
//assign GPIO_0[4:0] = {disable_rom, blksbr_reset_pulse, iports_palette_sel, cpu_ce, clk24};
assign GPIO_0[3:0] = {cpu_ce, vm55int_sel, io_read, io_write};
assign GPIO_0[7:4] = {blksbr_reset_pulse, kbd_rowselect[7], vm55int_cs_n, vm55int_oe_n};
assign GPIO_0[8] = clk24;

// CPU SECTION
wire RESET_n = mreset_n & !blksbr_reset_pulse;
wire READY = 1;
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
assign LEDg = sw23 == 0 ? status_word : sw23 == 1 ? {kbd_rowselect} : sw23 == 2 ? vm55int_pb_in : peripheral_data_in;
SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3, A);


T8080se CPU(RESET_n, clk24, cpu_ce, READY, HOLD, INT, INTE, DBIN, SYNC, VAIT, HLDA, WR_n, A, DI, DO);

wire ram_read = status_word[7];
wire ram_write_n = status_word[1];
wire io_write = status_word[4];
wire io_read  = status_word[6];
wire interrupt_ack = status_word[0];
wire WRN_CPUCE = WR_n | ~cpu_ce;
 
//// for CPU-less builds
//assign WR_n = 1;
//assign A = 16'hffff;
//wire ram_write_n = 1;

always @(posedge clk24) begin
	if (cpu_ce) begin
		if (WR_n == 0) gledreg[7:0] <= DO;
		if (SYNC) begin
			status_word <= DO;
		end
		address_bus_r <= address_bus[7:0];
	end
end



//
// MEMORIES
//

wire[7:0] ROM_DO;
lpm_rom0 bootrom(A[11:0], clk24, ROM_DO);


assign SRAM_CE_N = 0;
assign SRAM_OE_N = !rom_access && !ram_write_n && !video_slice;

wire [15:0] address_bus = video_slice & regular_clock_enabled ? VIDEO_A : A;

wire rom_access = (!disable_rom) & (A < 2048);
wire [7:0] sram_data_in;
assign DI = interrupt_ack ? 8'hFF : io_read ? peripheral_data_in : rom_access ? ROM_DO : sram_data_in;

//sram_map sram_map(SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N, WRN_BUFFERED /*WR_n | (~cpu_ce)*/, address_bus, DO, sram_data_in);
sram_map sram_map(SRAM_ADDR[14:0], SRAM_DQ, SRAM_WE_N, SRAM_UB_N, SRAM_LB_N, WRN_CPUCE | ram_write_n | io_write, address_bus, DO, sram_data_in);
assign SRAM_ADDR[17:15] = 3'b000;

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


wire int_request;

///////////
// RST38 //
///////////
oneshot retrace_irq(clk24, cpu_ce, retrace, int_request);
//always @(posedge clk24) begin
//	if (retrace) begin
//		int_request <= 1;
//	end
//	if (interrupt_ack) begin
//		int_request <= 0;
//	end
//end

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

vectorkeys (clk24, mreset, PS2_CLK, PS2_DAT, 
	kbd_mod_rus, 
	kbd_rowselect, 
	kbd_rowbits, 
	kbd_key_shift, kbd_key_ctrl, kbd_key_rus, kbd_key_blksbr);

///////////////
// I/O PORTS //
///////////////

reg [7:0] peripheral_data_in;
//always peripheral_data_in = (!vm55int_oe_n) ? vm55int_odata : 8'b0;
always peripheral_data_in = vm55int_oe_n ? 8'hFF : vm55int_odata;

//reg wr_n_io;
//always @(posedge clk24) begin
//	port0C_cs <= iports_write & iports_palette_sel;
//	if (cpu_ce & ~WR_n) 
//		wr_n_io <= 0;
//	else
//		wr_n_io <= 1;
//end



// Devices:
//   000xxxYY [a7:a0]
//  	000: internal VM55
//		001: external (parport) VM55
//		010: VI53 interval timer
//		011: internal: 	00: palette data out
//						01-11: joystick inputs
//		100: ramdisk bank switching
//		110,111: FDC ports

reg [7:0] address_bus_r;
//always @(posedge clk24) begin
//	if (io_read | io_write) address_bus_r <= address_bus[7:0];
//end

reg [2:0] portmap_device;				
always portmap_device = address_bus_r[4:2];

///////////////////////
// VM55 #1, internal //
///////////////////////

wire		vm55int_sel = portmap_device == 3'b000;

wire [1:0] 	vm55int_addr = 	~address_bus_r[1:0];
wire [7:0] 	vm55int_idata = DO;	
wire [7:0] 	vm55int_odata;
//reg  [7:0]	vm55int_odata_reg;
wire		vm55int_oe_n;

wire vm55int_cs_n = !(/*~ram_write_n &*/ (io_read | io_write) & vm55int_sel);
wire vm55int_rd_n = ~io_read;//~DBIN;
wire vm55int_wr_n = WR_n | ~cpu_ce;

//wire		vm55int_cs_n = !((io_read | io_write) & vm55int_sel & cpu_ce);
//wire		vm55int_rd_n = !(io_read & vm55int_sel);
//wire		vm55int_wr_n = !(io_write & vm55int_sel) | WRN_BUFFERED;

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
			video_palette_address <= vm55int_pb_out;
		end
		else begin
			video_border_index <= vm55int_pb_out[3:0];
			video_mode512 <= vm55int_pb_out[4];
		end

		// port C
		gledreg[9] <= vm55int_pc_out[3];		// RUS/LAT LED
	//end
end	

//always @(posedge clk24) vm55int_pb_in <= 8'hFF;
always @(kbd_rowbits) vm55int_pb_in <= ~kbd_rowbits;
always @(kbd_key_shift or kbd_key_ctrl or kbd_key_rus) begin
	vm55int_pc_in[5] <= ~kbd_key_shift;
	vm55int_pc_in[6] <= ~kbd_key_ctrl;
	vm55int_pc_in[7] <= ~kbd_key_rus;
end

//always @(vm55int_oe_n) if (!vm55int_oe_n) vm55int_odata_reg <= vm55int_odata;

////////////////////////////
// Internal ports, $0C -- //
////////////////////////////
wire		iports_sel 		= portmap_device == 3'b011;
wire		iports_write 	= ~ram_write_n & io_write & iports_sel; // this repeats as a series of 3 _|||_ wtf

// port $0C: palette value out
wire iports_palette_sel = address_bus[1:0] == 2'b00;

reg port0C_cs;
always @(posedge clk24) begin
	if (cpu_ce & SYNC) begin
		port0C_cs <= DO[4] && address_bus[7:2] == 6'h03; // $0C-$0F
	end
end

reg [1:0] vpwren_cnt;
always @(posedge clk24) begin
	if (port0C_cs & ~WR_n & cpu_ce) begin
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
	else if (cpu_ce && (KEY[3] == 1'b0 || kbd_key_blksbr == 1'b1)) begin
		disable_rom <= 1;
		rst0toggle <= 1;
		gledreg[8] <= 1;
	end 
	else 
		rst0toggle <= 0;
end
oneshot blksbr(clk24, cpu_ce, disable_rom, blksbr_reset_pulse);

I2C_AV_Config 		u7(clk24,mreset_n,I2C_SCLK,I2C_SDAT);

endmodule



