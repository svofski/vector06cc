`default_nettype none
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
				track,
				sector,
				status,
				cpu_command,
				cpu_status,
				
				irq,
				drq,
				wtf
		);
				
parameter CPU_COMMAND_READ 		= 8'h10;
parameter CPU_COMMAND_WRITE  	= 8'h20;
parameter CPU_COMMAND_ACK		= 8'h80;
				
parameter A_COMMAND	= 3'b000;
parameter A_STATUS	= 3'b000;
parameter A_TRACK 	= 3'b001;
parameter A_SECTOR	= 3'b010;
parameter A_DATA	= 3'b011;

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
parameter STATE_LOAD_RDDATA = 2;
parameter STATE_WAIT_WRDATA = 3;
parameter STATE_DATARDY		= 4;

parameter SECTOR_SIZE 		= 512;
parameter SECTORS_PER_TRACK	= 10;

input 				clk;
input				clken;
input				reset_n;
input				rd;
input				wr;
input [2:0]			addr;
input [7:0] 		idata;
output reg[7:0] 	odata;

// sector buffer access signals
output	reg [8:0]	buff_addr;
output	reg			buff_rd;
output	reg			buff_wr;
input 		[7:0]	buff_idata;
output	reg [7:0]	buff_odata;

output 	[7:0]		track = disk_track;
output  [7:0]		sector = wdstat_sector;
output  [7:0]		status = wdstat_status;
output	reg [7:0]	cpu_command;
input		[7:0]	cpu_status;

output				irq = wdstat_irq;
output				drq = wdstat_drq;

output	reg			wtf;


reg [7:0] 	wdstat_track;
reg [7:0]	wdstat_sector;
reg [7:0]	wdstat_status;
reg 		wdstat_stepdirection;
reg			wdstat_multisector;
reg			wdstat_irq;
reg			wdstat_drq;
reg			wdstat_side;

reg	[7:0]	disk_track;		// "real" heads position

reg [15:0]	data_rdlength;

reg [3:0]	state;

// expression used to calculate the next track
wire 	    wStepDir   = idata[6] ? idata[5] : wdstat_stepdirection;
wire [7:0]  wNextTrack = wStepDir ? disk_track - 1 : disk_track + 1;

wire [15:0]	wRdLengthMinus1 = data_rdlength - 1'b1;

always @(posedge clk or negedge reset_n) begin
	if (!reset_n) begin
		wdstat_multisector <= 0;
		wdstat_stepdirection <= 0;
		disk_track <= 8'hff;
		wdstat_track <= 0;
		wdstat_sector <= 0;
		wdstat_status <= 0;
		data_rdlength <= 0;
		buff_rd <= 0;
		buff_wr <= 0;
		buff_addr <= 0;
		cpu_command <= 0;
		odata <= 0;
		wdstat_multisector <= 0;
		state <= STATE_READY;
	end else if (clken) begin
		//if (buff_rd) begin
		//	odata <= buff_idata;
		//	buff_rd <= 0;
		//end

		case (state) 
		// Initial state
		STATE_READY:
			if (rd) begin
				case (addr)
				A_TRACK:	begin
							odata <= wdstat_track;
							end
				A_SECTOR:	begin
							odata <= wdstat_sector;
							end
				A_STATUS:	begin
							odata <= wdstat_status;
							end
				A_DATA:		begin
								if (data_rdlength == 0) begin
									// no data, we should be in STATE_DATARDY
								end 
								else if (rd && addr == A_DATA) begin
									odata <= buff_idata;
									buff_addr <= buff_addr + 1'b1;

									data_rdlength <= wRdLengthMinus1;
									if (wRdLengthMinus1 == 0) begin
										// either read the next sector, or stop if this is track end
										if (wdstat_multisector && wdstat_sector < SECTORS_PER_TRACK) begin
											wdstat_sector <= wdstat_sector + 1;
											cpu_command <= CPU_COMMAND_READ | wdstat_side;
											wdstat_drq <= 0;
											wdstat_irq <= 0;
											wdstat_status[SBIT_DRQ] <= 0;

											state <= STATE_WAIT_WHREAD;
										end else begin
											wdstat_drq <= 0;
											wdstat_irq <= 1;
											wdstat_multisector <= 0;
											wdstat_status[SBIT_BUSY] <= 0;
											wdstat_status[SBIT_DRQ]  <= 0;
										end
									end 
								end
							end
				default:;
				endcase
			end 
			else 
			if (wr) begin
				case (addr)
				A_TRACK:	begin
								if (!wdstat_status[SBIT_BUSY]) begin
									wdstat_track <= idata;
								end
							end
				A_SECTOR:	begin
								if (!wdstat_status[SBIT_BUSY]) begin
									wdstat_sector <= idata;
								end
							end
				A_COMMAND:	begin
							case (idata[7:4]) 
							4'h0: 	// RESTORE
								begin
									disk_track <= 0;
									// head load as specified, index, track0
									wdstat_status <=  { 2'b00, idata[3], 5'b00110};
									wdstat_track <= 0;
									wdstat_irq <= 1;
									wtf <= idata[3];
								end
							4'h1:	// SEEK
								begin
									// rdlength/wrlength?  -- no idea so far
									
									// set real track to registered value
									disk_track <= wdstat_track;
									wdstat_status <= {2'b00, idata[3], 2'b00, wdstat_track == 0, 2'b10};
									wdstat_irq <= 1;
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
										
									wdstat_status[SBIT_INDEX] <= 1'b1;
									wdstat_status[SBIT_TRACK0] <= ~|wNextTrack;
									wdstat_irq <= 1;
								end
							4'h8, 4'h9: // READ SECTORS
								// seek data
								// 4: m:	0: one sector, 1: until the track ends
								// 3: S: 	SIDE
								// 2: E:	some 15ms delay
								// 1: C:	check side matching?
								// 0: 0
								begin
									cpu_command <= CPU_COMMAND_READ | idata[3]; // side
									//wdstat_status[SBIT_BUSY] = 1'b1;
									wdstat_status <= BV_BUSY;
									wdstat_side <= idata[3];
									wdstat_multisector <= idata[4];
									state <= STATE_WAIT_WHREAD;
								end
							4'hA, 4'hB: // WRITE SECTORS
								;
							4'hC:	// READ ADDRESS
								;
							4'hE,	// READ TRACK
							4'hF:	// WRITE TRACK
								;
							default:;
							endcase
							end
				A_DATA:		begin
							end
				default:;
				endcase
			end
			
		STATE_WAIT_WHREAD:
			begin
				if (cpu_status[0] == 1'b1) begin
					cpu_command <= CPU_COMMAND_ACK;
					if (cpu_status[1]) begin
						// read successful
						wdstat_status[SBIT_DRQ] <= 1'b1;
						wdstat_drq <= 1;
						wdstat_irq <= 0;
						data_rdlength <= SECTOR_SIZE;
						buff_addr <= 0;
						buff_rd <= 1;
						state <= STATE_READY;
						//state <= STATE_LOAD_RDDATA;
					end else begin
						// read error
						//wdstat_status <= (wdstat_status & ~BV_ERRCODE) | BV_NOTFOUND;
						wdstat_status[SBIT_NOTFOUND] <= 1'b1;
						wdstat_irq <= 1;
						wdstat_drq <= 0;
						state <= STATE_READY;
					end
				end
			end
		endcase
	end
end

endmodule
