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
// Design File: pit8253.v
//
// This module approximates Intel 8253 interval timer. Only modes that can
// be useful for sound generation are implemented. Gate input is not used.
// Modes 1 and 5 are not implemented at all. This model is far from being
// optimal, probably can be heavily optimized if counter units are
// implemented in RTL level.
//
// The compatibility with the real 8253 is only verified as much as is 
// necessary for the software that requires the timer. Signal set/hold
// times are pretty poor, too, probably functional only up to 20MHz tops.
//
// --------------------------------------------------------------------

`default_nettype none

module pit8253(clk, ce, tce, a, wr, rd, din, dout, gate, out, testpin, tpsel, intq0, counter_load);
	input 			clk;		// i: i/o clock
	input 			ce;			// i: i/o clock enable
	input 			tce;		// i: timer clock enable, one for all 3 timers
	input [1:0] 	a;			// i: address bus
	input 			wr;			// i: data write
	input 			rd;			// i: data read
	input [7:0] 	din;		// i: data input bus
	output reg[7:0] dout;		// o: data output bus
	input [2:0] 	gate;		// i: gate inputs, NOT USED
	output [2:0] 	out;		// o: timer outputs
	output [9:0] 	testpin;	// o: test pins
	input 			tpsel;		// i: test pin group selector
	output [15:0]	intq0;
	output [15:0] 	counter_load;
	
wire	[7:0] 	q0;
wire	[7:0]	q1;
wire	[7:0]	q2;

reg		[5:0]	cword0;
reg		[5:0]	cword1;
reg		[5:0]	cword2;

reg 	[2:0] cwsel;
reg 	[3:0] sel;
wire 	[3:0] wren;
wire	[3:0] rden;

always @(a) 
	case(a)
		2'b00:	sel <= 4'b0001;
		2'b01:	sel <= 4'b0010;
		2'b10:	sel <= 4'b0100;
		2'b11:	sel <= 4'b1000;
	endcase

assign wren = {4{wr}} & sel;
assign rden = {4{rd}} & sel;

always @(din) begin
	case (din[7:6]) 
	2'b00:	cwsel <= 3'b001;
	2'b01:	cwsel <= 3'b010;
	2'b10:	cwsel <= 3'b100;
	2'b11:	cwsel <= 3'b000;
	endcase
end

wire [9:0] testpin0;
wire [9:0] testpin1;
assign testpin = tpsel ? testpin0 : testpin1;

//assign dout = rden[0] ? q0 : rden[1] ? q1 : rden[2] ? q2 : 0;
always @(rden,q0,q1,q2) 
	case (rden) 
		3'b001:	dout <= q0;
		3'b010:	dout <= q1;
		3'b100:	dout <= q2;
		default:dout <= 0;
	endcase

pit8253_counterunit cu0(clk, ce, tce, din, wren[3] & cwsel[0], din, wren[0], rden[0], q0, gate[0], out[0], testpin0, intq0, counter_load);
pit8253_counterunit cu1(clk, ce, tce, din, wren[3] & cwsel[1], din, wren[1], rden[1], q1, gate[1], out[1]);
pit8253_counterunit cu2(clk, ce, tce, din, wren[3] & cwsel[2], din, wren[2], rden[2], q2, gate[2], out[2], testpin1);

endmodule

module pit8253_counterunit(clk, ce, tce, cword, cwset, d, wren, rden, dout, gate, out, testpins, value, counter_load, nextvalue);
	input	clk;			// whatever main clk
	input	ce;				// bus clock enable, e.g. 3MHz
	input	tce;			// timer clock enable, e.g. 1.5MHz
	input 	[5:0] cword;	// control word from top sans counter select: 6 bits
	input	cwset;			// control word set
	input	[7:0] d;		// data in for load
	input	wren;			// data load enable
	input	rden;			// data read enable
	output	[7:0] dout;	// read value
	input	gate;			// gate pin
	output	out;			// out pin according to mode

	output [9:0] testpins;
	output [15:0] value = counter_q;
	output [15:0] counter_load;
	output [15:0] nextvalue;
	
assign testpins = {counter_wren, counter_clock_enable, 1'b0, counter_loaded, counter_starting, rl_mode, cw_mode};

parameter M0 = 3'd0, M1 = 3'd1, M2 = 3'd2, M3 = 3'd3, M4 = 3'd4, M5 = 3'd5;
parameter                       M2X= 3'd6, M3X= 3'd7; // according to OKI datasheet these modes are x10 and x11

reg		outreg;
assign 	out = outreg;

// control word breakdown
reg  [5:0] 	cwreg;
wire [2:0] 	cw_mode = cwreg[3:1];
wire 		bcd_mode = cwreg[0];
wire [1:0]	rl_mode	 = cwreg[5:4];

// gate sampler (unused)
reg			gate_sampled;
reg			gate_rising;
reg			gate_falling;
always @(posedge clk) begin
	if (ce) begin
		gate_sampled <= gate;
		gate_rising  <= gate & !gate_sampled;
		gate_falling <= !gate & gate_sampled;
	end
end

// counter load value
reg [15:0] 	counter_load;

// counter count 
wire[15:0] 	counter_q;

// counter load value overwrite enable (from host)
reg 		counter_wren_wr; 

						   /* study GATE for GATE-d systems, a gatelesss hack */
wire 		counter_wren = ((cw_mode != M1 && cw_mode != M5) & counter_wren_wr);

// let the counter auto-reload inself in modes M2,M2X,M3,M3X
wire 		autoreload = (cw_mode[1:0] == M3) || (cw_mode[1:0] == M2); 

pit8253_downcounter dctr(clk, counter_clock_enable, cw_mode[1:0] == M3, autoreload, outreg, counter_load, counter_wren, counter_q, nextvalue);

// software stop by loading
reg 		loading_stopper;
always @(counter_loading,cw_mode) loading_stopper <= (cw_mode == M0 || cw_mode == M4) & counter_loading;

// master, total, final grand enable
wire counter_clock_enable = tce & counter_loaded & !loading_stopper;

reg			loading_msb;	// for rl=3: 0: next 8-bit value will be lsb, 1: msb

reg 		counter_starting;
reg 		counter_loaded;
reg 		counter_loading;


// latching command written: counter value latch enable
wire read_latch_e = cword[5:4] == 2'b00;

// readhelper decides what to do with latching read, lsb/msb modes etc
readhelper rbus(.clk(clk), .ce(tce), .rden(rden), .rl_mode(rl_mode), .cwset(cwset), .latch_e(read_latch_e), .counter_q(counter_q), .q(dout));


always @(posedge clk) begin
	if (cwset) begin
		if (cword[5:4] != 2'b00) begin
			loading_msb <= 0;	// reset the doorstopper
			counter_loaded <= 0;
			counter_loading <= 0;
			cwreg <= cword;
			case (cword[3:1]) 
				M0:	// interrupt, 1-time, start count on load or gate
					begin
						outreg <= 1'b0;
					end
				M1:	// programmable one-shot on gate rising edge; NOT IMPLEMENTED
					begin
						outreg <= 1'b1;
					end
				M2, M2X:	// rate generator, start couting on load (or gate rising edge, not supported)
					begin
						outreg <= 1'b1;
					end
				M3, M3X: // square waveform generator
					begin
						outreg <= 1'b1;
					end
				M4:	// software trigger strobe
					begin
						outreg <= 1'b1;
					end
				M5:	// hardware trigger strobe (NOT IMPLEMENTED)
					begin
						outreg <= 1'b1;
					end
				default:
					begin
						outreg <= 1'b1;
					end
			endcase		
		end
	end
	
	// load
	if (wren & ce) begin
		case (rl_mode)
		2'b01:	begin
					counter_load[7:0] <= d;
					counter_starting <= 1;
					counter_wren_wr <= 1;
				end
		2'b10: 	begin
					counter_load[15:8] <= d;
					counter_starting <= 1;
					counter_wren_wr <= 1;
				end
		2'b11:	begin
					if (loading_msb) begin
						counter_load[15:8] <= d;
						counter_starting <= 1;
						counter_loading <= 0;
						counter_wren_wr <= ~counter_loaded;
					end	else begin
						counter_load[7:0] <= d;
						counter_loaded <= ((cw_mode == M1) || (cw_mode == M5) || (cw_mode[1] == 1))  ? counter_loaded : 0; // don't stop during reload in M2, M3
						counter_loading <= 1;
					end
						
					loading_msb <= ~loading_msb;
				end
		2'b00:  ; // illegal state
		endcase
	end

	// reset counter_wren on next tce
	if (tce & counter_wren) begin
		counter_wren_wr <= 0;
	end

	// enable counting on next tce
	if (tce & counter_starting) begin
		counter_loaded <= 1;
		counter_starting <= 0;
	end
	
	if (tce) begin
		case (cw_mode) 
			M0:	begin
					if (counter_q == 16'd1) begin	// 1 locks the counter so the terminal count is 0
						// counter_loaded <= 0; -- not! the counter continues counting
						outreg <= 1;
					end
				end
				
			M1:; // M1: NOT IMPLEMENTED, no gate, no reloads
			
			M2,M2X:	begin
					// technically we should trigger/reload on 1
					// but we need to do this up front to be ready
					// by the next clk/tce
					if (counter_q == 16'd2) begin
						outreg <= 0;
					end else begin
						outreg <= 1;
					end
				end
			M3,M3X:	begin
					if (counter_q == 16'd2) begin
						outreg <= ~outreg;
					end 
				end
			M4:	begin
					if (counter_q == 16'd0) begin
						outreg <= 0;
					end else
						outreg <= 1; // reset out on next cycle
				end
			M5: ; // M5 NOT IMPLEMENTED, no gate, just roll
			default:;
		endcase
	end
	
end
endmodule

// State-driven read dispatcher. 
// Latched value is stored here. 
// LSB/MSB read is decided upon here.
module readhelper(input clk, input ce, input rden, input cwset, input latch_e, input [1:0] rl_mode, input [15:0] counter_q, output reg [7:0] q);

reg [2:0] read_state;
reg	[15:0] latched_q;
reg read_msb;

wire [7:0] r_lsb = rl_mode == 2'b10 ? counter_q[15:8] : counter_q[7:0];
wire [7:0] r_msb = rl_mode == 2'b01 ? counter_q[7:0]  : counter_q[15:8];


always @*
	case (read_msb)
	0:	q <= read_state == 0 ? r_lsb : latched_q[7:0];
	1: 	q <= read_state == 0 ? r_msb : latched_q[15:8];
	endcase

always @(posedge clk)
	if (cwset && latch_e) latched_q <= counter_q;

always @(posedge clk)
	if (ce) begin
		if (cwset) begin
			read_msb <= 0;
			if (latch_e) begin
				read_state <= 2;
			end
			else
				read_state <= 0;
		end 
		else begin
			if (rden) begin
				case (read_state) 
				0:	read_state <= 0;
				1: 	read_state <= 0;
				2:	read_state <= 1;
				endcase
							
				read_msb <= ~read_msb;
			end 
		end
	end
endmodule


module pit8253_downcounter(clk, ce, halfmode, autoreload, o, d, wren, q, nextout);
	input clk;
	input ce;
	input halfmode;	// for square wave gen
	input autoreload;
	input o;		// current state of out for M3
	input [15:0] d;
	input wren;
	output [15:0] q;
	output [15:0] nextout = next;

reg  [15:0] counter;

reg wrlatch;

wire [15:0] next = counter - (~halfmode ? 16'd1 : counter[0] == 1'b0 ? 16'd2 : o ? 1 : 3);

assign q = counter;

always @(posedge clk) begin
	if (wren) begin
		counter <= d;
	end else if (ce) begin
		counter <= (autoreload & ~|next) ? d : next;
	end
end


endmodule

// $Id$
