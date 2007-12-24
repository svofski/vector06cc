`default_nettype none

`define noSIM

module floppywb(CLOCK_27, KEY[3:0], LEDr[9:0], LEDg[7:0], SW[9:0], HEX0, HEX1, HEX2, HEX3, 
		////////////////////	SRAM Interface		////////////////
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable

		////////////////////	SD_Card Interface	////////////////
		SD_DAT,							//	SD Card Data
		SD_DAT3,						//	SD Card Data 3
		SD_CMD,							//	SD Card Command Signal
		SD_CLK,							//	SD Card Clock
		
		///////////////////// USRAT //////////////////////
		UART_TXD,
		UART_RXD,
		
		GPIO_0
`ifdef SIM		
		,
		floppy_odata,
		floppy_debug,
		floppy_abus,
		debugidata, opcode		
`endif		
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

////////////////////	SD Card Interface	////////////////////////
input			SD_DAT;					//	SD Card Data 			(MISO)
output			SD_DAT3;				//	SD Card Data 3 			(CSn)
output			SD_CMD;					//	SD Card Command Signal	(MOSI)
output			SD_CLK;					//	SD Card Clock			(SCK)

output			UART_TXD;
input			UART_RXD;

output [12:0] 	GPIO_0;

`ifdef SIM
output	[7:0]	floppy_odata;
output	[7:0]	floppy_debug;
output	[15:0]	floppy_abus;
output	[7:0]	debugidata;
output	[7:0]	opcode;
`endif

// CLOCK SETUP
wire mreset_n = KEY[0];
wire mreset = !mreset_n;
wire clk24, clk18;
wire ce12, ce6, ce3, ce3v, vi53_timer_ce, video_slice, pipe_ab;

clockster clockmaker(
	.clk(CLOCK_27[0]), 
	.clk24(clk24), 
	.clk18(clk18), 
	.ce12(ce12), 
	.ce6(ce6),
	.ce3(ce3), 
	.ce3v(ce3v), 
	.video_slice(video_slice), 
	.pipe_ab(pipe_ab), 
	.ce1m5(vi53_timer_ce));


assign SRAM_ADDR = 0;
assign SRAM_OE_N = 1;
assign SRAM_CE_N = 1;
assign SRAM_WE_N = 1;
assign SRAM_UB_N = 1;
assign SRAM_LB_N = 1;
assign SRAM_DQ = 16'bZZZZZZZZZZZZZZZZ;

assign GPIO_0 = {ce12, ce6, ce3, ce3v, vi53_timer_ce, video_slice, pipe_ab};
//assign LEDg = floppy_odata;
//assign LEDr = floppy_abus;
assign floppy_idata = SRAM_DQ[7:0];
//assign SRAM_ADDR = floppy_abus;
//assign SRAM_WE_N = floppy_memwr;

wire	[15:0] 	floppy_abus;
wire	[7:0]	floppy_idata;
wire	[7:0]	floppy_odata;
wire			floppy_memwr;

reg [21:0] slowclock;
always @(posedge clk24) if (ce3v) slowclock <= slowclock + 1'b1;

`ifdef SIM
wire	floppy_ce = 1;
`else
wire	floppy_ce = SW[9] ? ce3v : &slowclock & ce3v;
`endif

floppy disk(
	.clk(clk24), 
	.ce(floppy_ce), 
	.reset_n(mreset_n), 
	.addr(floppy_abus), 
	.idata(floppy_idata), 
	.odata(floppy_odata), 
	.memwr(floppy_memwr), 
	.sd_dat(SD_DAT), 
	.sd_dat3(SD_DAT3), 
	.sd_cmd(SD_CMD), 
	.sd_clk(SD_CLK),
	.green_leds(LEDg),
	.red_leds(LEDr[7:0]),
	.uart_txd(UART_TXD),
`ifdef SIM	
	,
	.debug(floppy_debug),
	.debugidata(debugidata), 
	.opcode(opcode)
`endif	
	);

SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3, floppy_abus);

/*
reg uart_send;
reg [7:0] uart_data = 65;
wire uart_busy;
reg [1:0] uart_state = 0;


TXD txda( 
	.clk(clk24),
	.ld(uart_send),
	.data(uart_data),
	.TxD(UART_TXD),
	.txbusy(uart_busy)
   );

always @(posedge clk24) begin
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
				uart_state <= 0;
			end
		end
	3:	begin
		end
	endcase
end
*/
endmodule
