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
// Design File: wd1793.v
//
// This is not actually a wd1793, it needs external things like CPU
// and memory buffer. The top lefel is located in floppy.v
//
// --------------------------------------------------------------------


// In Vector, addresses are inverted, as usual
//                  WD		VECTOR
//COMMAND/STATUS	000		011	
//DATA 				011		000
//TRACK				001		010
//SECTOR			010		001
 
module wd1793(clk, clken, reset_n, 

				// host interface
				rd, wr, addr, idata, odata, 

				// memory buffer interface
				buff_addr, 
				buff_rd, 
				buff_wr, 
				buff_idata, 
				buff_odata,
				
				// workhorse interface
				oTRACK,
				oSECTOR,
				oSTATUS,
				oCPU_REQUEST,
				iCPU_STATUS,
				
				irq,
				drq,
				wtf
		);
				
parameter CPU_REQUEST_READ 		= 8'h10;
parameter CPU_REQUEST_WRITE  	= 8'h20;
parameter CPU_REQUEST_READADDR  = 8'h30;

parameter CPU_REQUEST_NOP		= 8'h40;
parameter CPU_REQUEST_ACK		= 8'h80;
parameter CPU_REQUEST_FAIL		= 8'hC0;
				
parameter A_COMMAND	= 3'b000;
parameter A_STATUS	= 3'b000;
parameter A_TRACK 	= 3'b001;
parameter A_SECTOR	= 3'b010;
parameter A_DATA	= 3'b011;
parameter A_CTL2	= 3'b111; // $1C: bit0 = drive #, bit2 = head#

parameter SBIT_BUSY 	= 	0;	// command is being executed
parameter BV_BUSY		=	8'h01;
parameter SBIT_READONLY	=   6;	// the disk is write protected
parameter BV_READONLY	= 	8'h40;
parameter SBIT_NOTREADY	= 	7;	// drive not ready/door open
parameter BV_NOTREADY	= 	8'h80;

// Command group 1
parameter SBIT_INDEX 	= 	1;	// index mark detected
parameter SBIT_TRACK0 	=	2;	// head home
parameter SBIT_CRCERR	= 	3;	// crc boo
parameter SBIT_SEEKERR	= 	4;	// seek failed
parameter SBIT_HEADLOAD	=	5;	// head loaded

// from EMUlib
parameter BV_DRQ      	= 8'h02;    /* Data request pending              */
parameter BV_LOSTDATA 	= 8'h04;    /* Data has been lost (missed DRQ)   */
parameter BV_ERRCODE 	= 8'h18;    /* Error code bits:                  */
parameter BV_BADDATA  	= 8'h08;    /* 1 = bad data CRC                  */
parameter BV_NOTFOUND 	= 8'h10;    /* 2 = sector not found              */
parameter BV_BADID    	= 8'h18;    /* 3 = bad ID field CRC              */
parameter BV_DELETED  	= 8'h20;    /* Deleted data mark (when reading)  */
parameter BV_WRFAULT  	= 8'h20;    /* Write fault (when writing)        */

parameter SBIT_DRQ		= 1;
parameter SBIT_NOTFOUND = 4;

parameter STATE_READY 		= 0;
parameter STATE_WAIT_WHREAD	= 1;
parameter STATE_WAITACK		= 2;
parameter STATE_RESET		= 3;
parameter STATE_BYTEFETCH   = 4;
parameter STATE_BYTEFETCX	= 5;
parameter STATE_WAIT_WHWRITE =6;
parameter STATE_NEXTADDRFETCH=7;
parameter STATE_WRITE_1		= 8;
parameter STATE_WRITE_2		= 9;
parameter STATE_WRITESECT	= 10;

parameter SECTOR_SIZE 		= 1024;
parameter SECTORS_PER_TRACK	= 5;

input 				clk;
input				clken;
input				reset_n;
input				rd;
input				wr;
input [2:0]			addr;
input [7:0] 		idata;
output reg[7:0] 	odata;

// sector buffer access signals
output	reg [9:0]	buff_addr;
output	reg			buff_rd;
output	reg			buff_wr;
input 		[7:0]	buff_idata;
output	    [7:0]	buff_odata = wdstat_datareg;

output 	[7:0]		oTRACK = disk_track;
output  [7:0]		oSECTOR = wdstat_sector;
output  [7:0]		oSTATUS = wdstat_status;
output	reg [7:0]	oCPU_REQUEST;
input		[7:0]	iCPU_STATUS;

output				irq = wdstat_irq;
output				drq = s_drq;

output				wtf = watchdog_bark;


reg [7:0] 	wdstat_track;
reg [7:0]	wdstat_sector;
wire [7:0]	wdstat_status;
reg	[7:0]	wdstat_datareg;
reg 		wdstat_stepdirection;
reg			wdstat_multisector;
reg			wdstat_irq;
reg			wdstat_side;
reg			wdstat_drive;

reg	[7:0]	disk_track;		// "real" heads position

reg [10:0]	data_rdlength;

reg [3:0]	state;

// expression used to calculate the next track
wire 	    wStepDir   = idata[6] ? idata[5] : wdstat_stepdirection;
wire [7:0]  wNextTrack = wStepDir ? disk_track - 1 : disk_track + 1;

wire [10:0]	wRdLengthMinus1 = data_rdlength - 1'b1;
wire [10:0]	wBuffAddrPlus1  = buff_addr + 1'b1;

wire 	wReadSuccess = (state == STATE_WAIT_WHREAD) & iCPU_STATUS[0] & iCPU_STATUS[1];
wire	wReadAByte = (state == STATE_READY) & rd & (addr == A_DATA) & (data_rdlength != 0);

wire	watchdog_set = wReadSuccess | wReadAByte;
wire	watchdog_bark;

watchdog	dogbert(.clk(clk), .clken(clken), .cock(watchdog_set), .q(watchdog_bark));

// common status bits
reg		s_readonly, s_ready, s_crcerr;
reg		s_headloaded, s_seekerr, s_track0, s_index;  // mode 1
reg		s_lostdata, s_wrfault; 				 // mode 2,3

reg		[1:0]	s_drq_busy;
wire			s_drq = s_drq_busy[1];
wire			s_busy = s_drq_busy[0];

always @(disk_track) s_track0 <= disk_track == 0;

reg 	cmd_mode;

reg 	[3:0] read_timer;

assign  wdstat_status = cmd_mode == 0 ? 	
	{~s_ready, s_readonly, s_headloaded, s_seekerr, s_crcerr, s_track0,   s_index, s_busy} :
	{~s_ready, s_readonly, s_wrfault,    s_seekerr, s_crcerr, s_lostdata, s_drq,   s_busy};

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		wdstat_multisector <= 0;
		wdstat_stepdirection <= 0;
		disk_track <= 8'hff;
		wdstat_track <= 0;
		wdstat_sector <= 0;
		{wdstat_side,wdstat_drive} <= 2'b00;
		data_rdlength <= 0;
		buff_addr <= 0;
		{buff_rd,buff_wr} <= 0;
		oCPU_REQUEST <= CPU_REQUEST_ACK;
		odata <= 8'b0;
		wdstat_multisector <= 1'b0;
		state <= STATE_READY;
		cmd_mode <= 1'b0;
		{s_ready, s_readonly, s_headloaded, s_seekerr, s_crcerr, s_index} <= 0;
		{s_wrfault, s_lostdata} <= 0;
		s_drq_busy <= 2'b00;
	end else if (clken) begin
		s_ready <= ~iCPU_STATUS[3];	// cpu will clear bit 3 only when fdd image is loaded
		
		buff_wr <= 0; 
		
		// REGISTER READ ACCESS
		if (rd) case (addr)
				A_TRACK:	odata <= wdstat_track;
				A_SECTOR:	odata <= wdstat_sector;
				A_STATUS:	odata <= wdstat_status;
				A_CTL2:		odata <= {5'b11111,wdstat_side,1'b0,wdstat_drive};
				A_DATA:		begin
								odata <= wdstat_datareg;
								if (state == STATE_READY) begin
									if (s_drq) begin
										//odata <= buff_idata; // for test try this: buff_addr[7:0];
										
										// reset drq until next byte is read, nothing is lost
										s_drq_busy <= 2'b01;
										s_lostdata <= 1'b0;
										
										if (wRdLengthMinus1 == 0) begin
											// enable CPU
											buff_rd <= 0;
											
											// either read the next sector, or stop if this is track end
											if (wdstat_multisector && wdstat_sector <= SECTORS_PER_TRACK) begin
												wdstat_sector <= wdstat_sector + 1'b1;
												oCPU_REQUEST <= CPU_REQUEST_READ | wdstat_side;
												wdstat_irq <= 1'b0;
												s_drq_busy <= 2'b01;

												state <= STATE_WAIT_WHREAD;
											end else begin
												wdstat_irq <= 1'b1;
												wdstat_multisector <= 1'b0;
												s_drq_busy <= 2'b00;
											end
										end else begin
											// everything is okay, fetch next byte
											state <= STATE_NEXTADDRFETCH;
										end
									end
								end
							end
				default:;
				endcase
				
				
		if (wr) 
			case (addr)
				A_TRACK:	begin
								if (!s_busy) begin
									wdstat_track <= idata;
								end 
							end
				A_SECTOR:	begin
								if (!s_busy) begin
									wdstat_sector <= idata;
								end 
							end
				A_CTL2:		begin
								wdstat_side <= idata[2];
								wdstat_drive <= idata[0];
							end
				A_COMMAND:	begin
								if (idata[7:4] == 4'hD) begin
									// interrupt
									state <= STATE_RESET;
								end
								else
								if (state == STATE_READY) begin
									cmd_mode <= idata[7];	// for wdstat_status
									
									case (idata[7:4]) 
									4'h0: 	// RESTORE
										begin
											
											// head load as specified, index, track0
											s_headloaded <= idata[3];
											s_index <= 1'b1;
											wdstat_track <= 0;
											disk_track <= 0;

											// some programs like it when FDC gets busy for a while
											s_drq_busy <= 2'b01;
											oCPU_REQUEST <= CPU_REQUEST_NOP | idata[7:4];
											state <= STATE_WAITACK;
										end
									4'h1:	// SEEK
										begin
											// rdlength/wrlength?  -- no idea so far
											// set real track to datareg
											disk_track <= wdstat_datareg; //wdstat_track;
											s_headloaded <= idata[3];
											s_index <= 1'b1;
											
											// some programs like it when FDC gets busy for a while
											s_drq_busy <= 2'b01;
											oCPU_REQUEST <= CPU_REQUEST_NOP | idata[7:4];
											state <= STATE_WAITACK;
										end
									4'h2,	// STEP
									4'h3,	// STEP & UPDATE
									4'h4,	// STEP-IN
									4'h5,	// STEP-IN & UPDATE
									4'h6,	// STEP-OUT
									4'h7:	// STEP-OUT & UPDATE
										begin
											// if direction is specified, store it for the next time
											if (idata[6] == 1) begin 
												wdstat_stepdirection <= idata[5]; // 0: forward/in
											end 
											
											// perform step 
											disk_track <= wNextTrack;
													
											// update TRACK register too if asked to
											if (idata[4]) begin
												wdstat_track <= wNextTrack;
											end
												
											s_headloaded <= idata[3];
											s_index <= 1'b1;

											// some programs like it when FDC gets busy for a while
											s_drq_busy <= 2'b01;
											oCPU_REQUEST <= CPU_REQUEST_NOP | idata[7:4];
											state <= STATE_WAITACK;
										end
									4'h8, 4'h9: // READ SECTORS
										// seek data
										// 4: m:	0: one sector, 1: until the track ends
										// 3: S: 	SIDE
										// 2: E:	some 15ms delay
										// 1: C:	check side matching?
										// 0: 0
										begin
											// now i'm confused, it seems that side is specified in secondary control register
											// while it's also specified in bit 3 of command.. and matching, too.. 
											// probably some dino poo
											oCPU_REQUEST <= CPU_REQUEST_READ | {wdstat_drive,wdstat_side};// idata[3]; 

											s_drq_busy <= 2'b01;
											{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
											
											wdstat_multisector <= idata[4];
											data_rdlength <= SECTOR_SIZE;
											state <= STATE_WAIT_WHREAD;
										end
									4'hA, 4'hB: // WRITE SECTORS
										begin
											//oCPU_REQUEST <= CPU_REQUEST_WRITE | {wdstat_drive,wdstat_side};
											s_drq_busy <= 2'b11;
											{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
											wdstat_multisector <= idata[4];
											
											data_rdlength <= SECTOR_SIZE;
											buff_addr <= 0;

											state <= STATE_WRITESECT;
										end								
									4'hC:	// READ ADDRESS
										begin
											// track, side, sector, sector size code, 2-byte checksum (crc?)
											oCPU_REQUEST <= CPU_REQUEST_READADDR | {wdstat_drive,wdstat_side};
											
											s_drq_busy <= 2'b01;
											{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
											
											wdstat_multisector <= 1'b0;
											state <= STATE_WAIT_WHREAD;
											data_rdlength <= 6;
										end
									4'hE,	// READ TRACK
									4'hF:	// WRITE TRACK
										;
									default:;
									endcase
								end
							end
				A_DATA:		begin
								wdstat_datareg <= idata; 

								if (state == STATE_WRITESECT) begin
									s_drq_busy <= 2'b01;			// busy, clear drq
									s_lostdata <= 1'b0;
									
									state <= STATE_WRITE_1;
									/*
									if (wRdLengthMinus1 == 0) begin
										if (wdstat_multisector && wdstat_sector <= SECTORS_PER_TRACK) begin
										end else begin
											wdstat_irq <= 1'b1;
											wdstat_multisector <= 1'b0;
											
											// flush data
											oCPU_REQUEST <= CPU_REQUEST_WRITE | wdstat_side;
											state <= STATE_WAIT_WHWRITE;
										end
									end else begin
										s_drq_busy <= 2'b01;				// request next byte
									end
									*/
								end
							end
				default:;
			endcase

		// NORMAL OPERATION
		case (state) 
		STATE_NEXTADDRFETCH:
			begin
				// increment data pointer, decrement byte count
				buff_addr <= wBuffAddrPlus1;
				data_rdlength <= wRdLengthMinus1;
				state <= STATE_BYTEFETCH;
			end
		// skip a few cycles before asserting drq 
		STATE_BYTEFETCH:
			begin
				read_timer <= 4'b1111;
				state <= STATE_BYTEFETCX;
				s_drq_busy <= 2'b01;
				buff_rd <= 1;
			end
			
		STATE_BYTEFETCX:
			begin
				if (read_timer != 0) 
					read_timer <= read_timer - 1'b1;
				else begin
					s_lostdata <= 1'b0;
					s_drq_busy <= 2'b11;
					wdstat_datareg <= buff_idata;
					state <= STATE_READY;
				end
			end
			
		// write
		STATE_WRITE_1:
			begin
				buff_wr <= 1'b1;
				state <= STATE_WRITE_2;
			end
			
		STATE_WRITE_2:
			begin
				buff_wr <= 1'b0;
				// increment data pointer, decrement byte count
				buff_addr <= wBuffAddrPlus1;
				data_rdlength <= wRdLengthMinus1;
				
				if (wRdLengthMinus1 == 0) begin
					// flush data
					oCPU_REQUEST <= CPU_REQUEST_WRITE | wdstat_side;
					state <= STATE_WAIT_WHWRITE;
				end else begin
					s_drq_busy <= 2'b11;		// request next byte
					state <= STATE_WRITESECT;
				end				
			end
			
		STATE_RESET:
			begin
				s_drq_busy <= 2'b00;
				{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
				oCPU_REQUEST <= CPU_REQUEST_ACK;
				state <= STATE_READY;
			end
		
		// Initial state
		STATE_READY:
			begin
				// lose data if not requested in time
				if (s_drq && watchdog_bark) begin
					s_lostdata <= 1'b1;
					s_drq_busy <= 2'b01;
					state <= data_rdlength != 0 ? STATE_NEXTADDRFETCH : STATE_RESET;
				end
			end
			
		STATE_WAIT_WHREAD:
			begin
				// s_ready == 0 means that in fact SD card was removed or some 
				// other kind of unrecoverable error has happened
				if (~s_ready || (iCPU_STATUS[1:0] == 2'b01)) begin
					// FAIL
					oCPU_REQUEST <= CPU_REQUEST_ACK;
					s_seekerr <= 1'b1;
					s_crcerr <= iCPU_STATUS[2];
					s_drq_busy <= 2'b00;
					
					wdstat_irq <= 1;
					state <= STATE_READY;
				end else if (iCPU_STATUS[1:0] == 2'b11) begin
					oCPU_REQUEST <= CPU_REQUEST_ACK;
					wdstat_irq <= 0;
					buff_addr <= 0;
					
					state <= STATE_BYTEFETCH;
				end
			end
			
		STATE_WAIT_WHWRITE:
			begin
				if (~s_ready || (iCPU_STATUS[1:0] == 2'b01)) begin
					oCPU_REQUEST <= CPU_REQUEST_ACK;
				
					s_seekerr <= 1'b1;
					s_crcerr <= iCPU_STATUS[2];
					
					s_drq_busy <= 2'b00;
					wdstat_irq <= 1;
					state <= STATE_READY;
				end else if (iCPU_STATUS[1:0] == 2'b11) begin
					oCPU_REQUEST <= CPU_REQUEST_ACK;
					wdstat_irq <= 0;
					s_drq_busy <= 2'b00;
					state <= STATE_READY;
				end
			end
			
		STATE_WAITACK:
			begin
				if (iCPU_STATUS[0]) begin
					oCPU_REQUEST <= CPU_REQUEST_ACK;
					
					s_drq_busy <= 2'b00;
					wdstat_irq <= 1;
					state <= STATE_READY;
				end
			end
		endcase
	end
end

endmodule

module watchdog(clk, clken, cock, q);
parameter TIME = 255;
//parameter TIME = 65535;
input clk, clken;
input cock;
output q = timer == 0;

reg [15:0] timer;

always @(posedge clk or posedge cock) begin
	if (cock) begin
		timer <= TIME;
	end
	else if (clken) begin
		if (timer != 0) timer <= timer - 1'b1;
	end
end
endmodule
