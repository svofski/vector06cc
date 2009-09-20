`default_nettype none

// ====================================================================
//                        VECTOR-06C FPGA REPLICA
//
//             Copyright (C) 2007,2008 Viacheslav Slavinsky
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
// This module approximates the inner workings of a WD1793 floppy disk
// controller to some minimal extent. Track read/write operations
// are not supported, other ops are mimicked only barely enough.
//
// Actual image file data is being read/written by the workhorse 
// CPU (see floppy.v). This module only issues requests to read 
// or write sectors.
// --------------------------------------------------------------------


// In Vector, addresses are inverted, as usual
//                  WD		VECTOR
//COMMAND/STATUS	000		011	
//DATA 				011		000
//TRACK				001		010
//SECTOR			010		001
//CTL2						111 
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
input 				clk;			/* clock: e.g. 24MHz		*/
input				clken;			/* clock enable: e.g. 3MHz 	*/
input				reset_n;		/* async reset				*/
input				rd;				/* i/o read					*/
input				wr;				/* i/o write				*/
input [2:0]			addr;			/* i/o port addr			*/
input [7:0] 		idata;			/* i/o data	in				*/
output reg[7:0] 	odata;			/* i/o data out				*/

// Sector buffer access signals
output	reg [9:0]	buff_addr;		/* buffer RAM address		*/
output	reg			buff_rd;		/* buffer RAM read enable	*/
output	reg			buff_wr;		/* buffer RAM write enable	*/
input 		[7:0]	buff_idata;		/* buffer RAM data input 	*/
output	    [7:0]	buff_odata = wdstat_datareg;    /* output	*/

// Workhorse CPU interface
output 		[7:0]	oTRACK = disk_track;		/* TRACK		*/
output 		[7:0]	oSECTOR = wdstat_sector;	/* SECTOR		*/
output  	[7:0]	oSTATUS = wdstat_status;	/* STATUS		*/
output	reg [7:0]	oCPU_REQUEST;				/* COMMAND req  */
input		[7:0]	iCPU_STATUS;				/* STATUS return*/

output				irq = s_busy;
output				drq = s_drq;
output				wtf = state == STATE_DEAD;

// Workhorse CPU request codes
parameter CPU_REQUEST_READ 		= 8'h10;
parameter CPU_REQUEST_WRITE  	= 8'h20;
parameter CPU_REQUEST_READADDR  = 8'h30;
parameter CPU_REQUEST_NOP		= 8'h40;
parameter CPU_REQUEST_ACK		= 8'h80;
parameter CPU_REQUEST_FAIL		= 8'hC0;
				
// Register addresses				
parameter A_COMMAND	= 3'b000;
parameter A_STATUS	= 3'b000;
parameter A_TRACK 	= 3'b001;
parameter A_SECTOR	= 3'b010;
parameter A_DATA	= 3'b011;
parameter A_CTL2	= 3'b111; 		/* port $1C: bit0 = drive #, bit2 = head# */

// States
parameter STATE_READY 		= 0;	/* Initial, idle, sector data read */
parameter STATE_WAIT_CPUREAD= 1;	/* CPU: wait until read operation completes -> STATE_READ_2/STATE_READY */
parameter STATE_WAIT_CPU	= 2;	/* NOP operation wait -> STATE_READY */
parameter STATE_ABORT		= 3;	/* Abort current command ($D0) -> STATE_READY */
parameter STATE_READ_2   	= 4;	/* Buffer-to-host: wait before asserting DRQ -> STATE_READ_3 */
parameter STATE_READ_3		= 5;	/* Buffer-to-host: load data into reg, assert DRQ -> STATE_READY */
parameter STATE_WAIT_CPUWRITE=6;	/* CPU: wait until write operation completes -> STATE_READY */
parameter STATE_READ_1		= 7;	/* Buffer-to-host: increment data pointer, decrement byte count -> STATE_READ_2*/
parameter STATE_WRITE_1		= 8;	/* Host-to-buffer: wr = 1 -> STATE_WRITE_2 */
parameter STATE_WRITE_2		= 9;	/* Host-to-buffer: wr = 0, next addr -> STATE_WRITESECT/STATE_WAIT_CPUWRITE */
parameter STATE_WRITESECT	= 10;	/* Host-to-buffer: wait data from host -> STATE_WRITE_1 */
parameter STATE_READSECT	= 11;	/* Buffer-to-host */

parameter STATE_ENDCOMMAND2 = 13;	/* -> STATE_READY */
parameter STATE_ENDCOMMAND	= 14;	/* All commands end here -> STATE_ENDCOMMAND2 */
parameter STATE_DEAD		= 15;	/* Total cessation, for debugging */

// Fixed parameters that should be variables
parameter SECTOR_SIZE 		= 11'd1024;
parameter SECTORS_PER_TRACK	= 8'd5;



// State variables
reg  [7:0] 	wdstat_track;
reg  [7:0]	wdstat_sector;
wire [7:0]	wdstat_status;
reg	 [7:0]	wdstat_datareg;
reg  [7:0]	wdstat_command;			/* command register 					*/
reg			wdstat_pending;			/* command loaded, pending execution	*/
reg 		wdstat_stepdirection;	/* last step direction 					*/
reg			wdstat_multisector;		/* indicates multisector mode			*/
reg			wdstat_side;			/* current side							*/
reg			wdstat_drive;			/* current drive						*/

reg  [3:0]	boo;					/* CPU_REQUEST_ACK lsb for diagnostics  */
reg	 [7:0]	disk_track;				/* "real" heads position 				*/
reg  [10:0]	data_rdlength;			/* this many bytes to transfer during read/write ops */
reg  [3:0]	state;					/* teh state 							*/

// common status bits
reg			s_readonly, s_ready, s_crcerr;
reg			s_headloaded, s_seekerr, s_track0, s_index;  /* mode 1   */
reg			s_lostdata, s_wrfault; 				 		 /* mode 2,3 */

// Command mode 0/1 for status register
reg 		cmd_mode;

// DRQ/BUSY are always going together
reg	[1:0]	s_drq_busy;
wire		s_drq = s_drq_busy[1];
wire		s_busy = s_drq_busy[0];

// Timer for keeping DRQ pace
reg [3:0] 	read_timer;

always @(disk_track) begin: _track0
	s_track0 <= disk_track == 0;
end

// Reusable expressions
wire 	    wStepDir   = idata[6] ? idata[5] : wdstat_stepdirection;
wire [7:0]  wNextTrack = wStepDir ? disk_track - 1 : disk_track + 1;

wire [10:0]	wRdLengthMinus1 = data_rdlength - 1'b1;
wire [10:0]	wBuffAddrPlus1  = buff_addr + 1'b1;

wire 		wReadSuccess = (state == STATE_WAIT_CPUREAD) & iCPU_STATUS[0] & iCPU_STATUS[1];
wire		wReadAByte = (state == STATE_READY) & rd & (addr == A_DATA) & (data_rdlength != 0);

// Status register
assign  wdstat_status = cmd_mode == 0 ? 	
	{~s_ready, s_readonly, s_headloaded, s_seekerr, s_crcerr, s_track0,   s_index, s_busy | wdstat_pending} :
	{~s_ready, s_readonly, s_wrfault,    s_seekerr, s_crcerr, s_lostdata, s_drq,   s_busy | wdstat_pending};
	
// Watchdog	
//wire		watchdog_set = wReadSuccess | wReadAByte;
reg			watchdog_set;

wire		watchdog_bark;
watchdog	dogbert(.clk(clk), .clken(clken), .cock(watchdog_set), .q(watchdog_bark));

always @*
	case (addr)
		A_TRACK:	odata <= wdstat_track;
		A_SECTOR:	odata <= wdstat_sector;
		A_STATUS:	odata <= wdstat_status;
		A_CTL2:		odata <= {5'b11111,wdstat_side,1'b0,wdstat_drive};
		A_DATA:		odata <= wdstat_datareg;
		default:	odata <= 8'hff;
	endcase
	

always @(posedge clk or negedge reset_n) begin: _wdmain
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
		//odata <= 8'b0;
		wdstat_multisector <= 1'b0;
		state <= STATE_READY;
		cmd_mode <= 1'b0;
		{s_ready, s_readonly, s_headloaded, s_seekerr, s_crcerr, s_index} <= 0;
		{s_wrfault, s_lostdata} <= 0;
		s_drq_busy <= 2'b00;
		wdstat_pending <= 0;
		watchdog_set <= 0;
	end else if (state == STATE_DEAD) begin
		s_drq_busy <= 2'b11;
		s_seekerr <= 1;
		s_wrfault <= 1;
		s_readonly <= 1;
		s_crcerr <= 1;
		oCPU_REQUEST <= CPU_REQUEST_FAIL;
	end else if (clken) begin
		s_ready <= ~iCPU_STATUS[3];	// cpu will clear bit 3 only when fdd image is loaded
		
		buff_wr <= 0; 
		
		/* Register read operations */
		if (rd) 
			case (addr)
				//A_TRACK:	odata <= wdstat_track;
				//A_SECTOR:	odata <= wdstat_sector;
				A_STATUS:	begin
				//				odata <= wdstat_status;
								s_index <= 0; 			// clear s_index after it's read once
							end
				//A_CTL2:		odata <= {5'b11111,wdstat_side,1'b0,wdstat_drive};
				//A_DATA:		begin
				//				odata <= wdstat_datareg;
				//				// see STATE_READSECT below
				//			end
				default:;
			endcase
				
		/* Register write operations */
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
									cmd_mode <= 0;
									
									if (state != STATE_READY) 
										state <= STATE_ABORT;
									else
										{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
										
								end else begin
									if (wdstat_pending) begin
										wdstat_sector <= idata;
										wdstat_track  <= {2'b00,s_drq_busy,state};
										state <= STATE_DEAD;
									end else begin
										wdstat_command <= idata;
										wdstat_pending <= 1;
									end
								end
							end
				A_DATA:		begin
								wdstat_datareg <= idata; 
								// see STATE_WRITESECT below
							end
				default:;
			endcase

		//////////////////////////////////////////////////////////////////
		// Generic state machine is described below, but some important //
		// transitions are defined within the read/write section.       //
		//////////////////////////////////////////////////////////////////

		/* Data transfer: buffer to host. Read stage 1: increment address */
		case (state) 
		
		/* Idle state or buffer to host transfer */
		STATE_READY:
			begin
				// handle command
				if (wdstat_pending) begin
					wdstat_pending <= 0;
					cmd_mode <= wdstat_command[7];		// keep cmd_mode for wdstat_status
					
					case (wdstat_command[7:4]) 
					4'h0: 	// RESTORE
						begin
							// head load as specified, index, track0
							s_headloaded <= wdstat_command[3];
							s_index <= 1'b1;
							wdstat_track <= 0;
							disk_track <= 0;

							// some programs like it when FDC gets busy for a while
							s_drq_busy <= 2'b01;
							oCPU_REQUEST <= CPU_REQUEST_NOP | wdstat_command[7:4];
							state <= STATE_WAIT_CPU;
						end
					4'h1:	// SEEK
						begin
							// set real track to datareg
							disk_track <= wdstat_datareg; 
							s_headloaded <= wdstat_command[3];
							s_index <= 1'b1;
							
							// get busy 
							s_drq_busy <= 2'b01;
							oCPU_REQUEST <= CPU_REQUEST_NOP | wdstat_command[7:4];
							state <= STATE_WAIT_CPU;
						end
					4'h2,	// STEP
					4'h3,	// STEP & UPDATE
					4'h4,	// STEP-IN
					4'h5,	// STEP-IN & UPDATE
					4'h6,	// STEP-OUT
					4'h7:	// STEP-OUT & UPDATE
						begin
							// if direction is specified, store it for the next time
							if (wdstat_command[6] == 1) begin 
								wdstat_stepdirection <= wdstat_command[5]; // 0: forward/in
							end 
							
							// perform step 
							disk_track <= wNextTrack;
									
							// update TRACK register too if asked to
							if (wdstat_command[4]) begin
								wdstat_track <= wNextTrack;
							end
								
							s_headloaded <= wdstat_command[3];
							s_index <= 1'b1;

							// some programs like it when FDC gets busy for a while
							s_drq_busy <= 2'b01;
							oCPU_REQUEST <= CPU_REQUEST_NOP | wdstat_command[7:4];
							state <= STATE_WAIT_CPU;
						end
					4'h8, 4'h9: // READ SECTORS
						// seek data
						// 4: m:	0: one sector, 1: until the track ends
						// 3: S: 	SIDE
						// 2: E:	some 15ms delay
						// 1: C:	check side matching?
						// 0: 0
						begin
							// side is specified in the secondary control register ($1C)
							oCPU_REQUEST <= CPU_REQUEST_READ | {wdstat_drive,wdstat_side};

							s_drq_busy <= 2'b01;
							{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
							
							wdstat_multisector <= wdstat_command[4];
							data_rdlength <= SECTOR_SIZE;
							state <= STATE_WAIT_CPUREAD;
						end
					4'hA, 4'hB: // WRITE SECTORS
						begin
							s_drq_busy <= 2'b11;
							{s_wrfault,s_seekerr,s_crcerr,s_lostdata} <= 0;
							wdstat_multisector <= wdstat_command[4];
							
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
							state <= STATE_WAIT_CPUREAD;
							data_rdlength <= 6;
						end
					4'hE,	// READ TRACK
					4'hF:	// WRITE TRACK
							s_drq_busy <= 2'b00;
					default:s_drq_busy <= 2'b00;
					endcase
				end
			end

		STATE_READ_1:
			begin
				// increment data pointer, decrement byte count
				buff_addr <= wBuffAddrPlus1;
				data_rdlength <= wRdLengthMinus1;
				state <= STATE_READ_2;
			end
		/* Data transfer: buffer to host. Read stage 2: clear DRQ and wait a little bit */
		STATE_READ_2:
			begin
				watchdog_set <= 1;
				read_timer <= 4'b1111;
				state <= STATE_READ_3;
				s_drq_busy <= 2'b01;
				buff_rd <= 1;
			end
		/* Data transfer: buffer to host. Read stage 3: assert DRQ, output data byte.*/
		STATE_READ_3:
			begin
				if (read_timer != 0) 
					read_timer <= read_timer - 1'b1;
				else begin
					watchdog_set <= 0;
					s_lostdata <= 1'b0;
					s_drq_busy <= 2'b11;
					wdstat_datareg <= buff_idata;
					state <= STATE_READSECT;
				end
			end
		
		STATE_READSECT:
			begin
				// lose data if not requested in time
				//if (s_drq && watchdog_bark) begin
				//	s_lostdata <= 1'b1;
				//	s_drq_busy <= 2'b01;
				//	state <= data_rdlength != 0 ? STATE_READ_1 : STATE_ABORT;
				//end

				if (watchdog_bark || (rd && addr == A_DATA && s_drq)) begin
					// reset drq until next byte is read, nothing is lost
					s_drq_busy <= 2'b01;
					s_lostdata <= watchdog_bark;
					
					if (wRdLengthMinus1 == 0) begin
						// enable CPU
						buff_rd <= 0;
						
						// either read the next sector, or stop if this is track end
`ifdef WITH_MULTISECTOR
						if (wdstat_multisector && wdstat_sector <= SECTORS_PER_TRACK) begin
							wdstat_sector <= wdstat_sector + 1'b1;
							oCPU_REQUEST <= CPU_REQUEST_READ | wdstat_side;
							s_drq_busy <= 2'b01;

							state <= STATE_WAIT_CPUREAD;
						end else begin
							// end
							wdstat_multisector <= 1'b0;
`endif							
							//s_drq_busy <= 2'b00;
							boo <= 1;
							state <= STATE_ENDCOMMAND;
`ifdef WITH_MULTISECTOR
						end
`endif							
					end else begin
						// everything is okay, fetch next byte
						state <= STATE_READ_1;
					end
				end
			end
			
		/* Data transfer: host to buffer. Wait data from host (see write op to A_DATA) */
		STATE_WRITESECT:
			begin
				if (wr && addr == A_DATA) begin
					s_drq_busy <= 2'b01;			// busy, clear drq
					s_lostdata <= 1'b0;
					
					state <= STATE_WRITE_1;
				end
			end
			
		/* Data transfer: host to buffer stage 1 */
		STATE_WRITE_1:
			begin
				buff_wr <= 1'b1;
				state <= STATE_WRITE_2;
			end
			
		/* Data transfer: host to buffer stage 2 */
		STATE_WRITE_2:
			begin
				buff_wr <= 1'b0;
				// increment data pointer, decrement byte count
				buff_addr <= wBuffAddrPlus1;
				data_rdlength <= wRdLengthMinus1;
								
				if (wRdLengthMinus1 == 0) begin
					// Flush data --
					oCPU_REQUEST <= CPU_REQUEST_WRITE | wdstat_side;
					state <= STATE_WAIT_CPUWRITE;
				end else begin
					s_drq_busy <= 2'b11;		// request next byte
					state <= STATE_WRITESECT;
				end				
			end
			
		/* Abort current operation ($D0) */
		STATE_ABORT:
			begin
				data_rdlength <= 0;
				wdstat_pending <= 0;
				boo <= 2;
				state <= STATE_ENDCOMMAND;
			end
			
		/* Wait for a READ operation to complete */
		STATE_WAIT_CPUREAD:
			begin
				// s_ready == 0 means that in fact SD card was removed or some 
				// other kind of unrecoverable error has happened
				if (iCPU_STATUS[3] || (iCPU_STATUS[1:0] == 2'b01)) begin
					// FAIL
					s_seekerr <= 1'b1;
					s_crcerr <= iCPU_STATUS[2];
					//s_drq_busy <= 2'b00;
					
					boo <= 3;
					state <= STATE_ENDCOMMAND;
				end else if (iCPU_STATUS[1:0] == 2'b11) begin
					//oCPU_REQUEST <= CPU_REQUEST_ACK;
					buff_addr <= 0;
					
					state <= STATE_READ_2;
				end
			end
			
		/* Wait for a WRITE operation to complete */
		STATE_WAIT_CPUWRITE:
			begin
				if (iCPU_STATUS[3] || (iCPU_STATUS[1:0] == 2'b01)) begin
					s_wrfault <= iCPU_STATUS[2];
					boo <= 4;
					state <= STATE_ENDCOMMAND;
				end else if (iCPU_STATUS[1:0] == 2'b11) begin
`ifdef WITH_MULTISECTOR					
					if (wdstat_multisector && wdstat_sector <= SECTORS_PER_TRACK) begin
						wdstat_sector <= wdstat_sector + 1'b1;
						s_drq_busy <= 2'b11;
						data_rdlength <= SECTOR_SIZE;
						buff_addr <= 0;
						state <= STATE_WRITESECT;
					end else begin
`endif					
						boo <= 5;
						state <= STATE_ENDCOMMAND;
`ifdef WITH_MULTISECTOR					
					end
`endif					
				end 
				else s_drq_busy <= 2'b00;
			end

		/* Wait for a NOP operation to complete */
		STATE_WAIT_CPU:
			begin
				if (iCPU_STATUS[0]) begin
					boo <= 6;
					//s_drq_busy <= 2'b00;
					state <= STATE_ENDCOMMAND;
				end
			end			
			
		/* End any command. Provide boo code in CPU_REQUEST LSB */
		STATE_ENDCOMMAND:
			begin
				oCPU_REQUEST <= {CPU_REQUEST_ACK[7:4], boo};
				state <= STATE_ENDCOMMAND2;
			end

		STATE_ENDCOMMAND2:
			begin
				if (iCPU_STATUS == 0) begin
					oCPU_REQUEST <= 0;
					state <= STATE_READY;
					s_drq_busy <= 2'b00;
				end
			end
		endcase
	end
end
endmodule

// start ticking when cock goes down
module watchdog(clk, clken, cock, q);
parameter TIME = 16'd2048; // 2048 seems to work better than expected 100 (32us).. why?
input clk, clken;
input cock;
output q = timer == 0;

reg [15:0] timer;

always @(posedge clk) begin
	if (cock) begin
		timer <= TIME;
	end
	else if (clken) begin
		if (timer != 0) timer <= timer - 1'b1;
	end
end
endmodule
