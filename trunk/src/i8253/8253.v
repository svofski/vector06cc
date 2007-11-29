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
// --------------------------------------------------------------------

`default_nettype none


module pit8253(clk, ce, tce, a, wr, rd, din, dout, gate, out, testpin, tpsel);
	input 			clk;		// i: i/o clock
	input 			ce;			// i: i/o clock enable
	input 			tce;		// i: timer clock enable, one for all 3 timers
	input [1:0] 	a;			// i: address bus
	input 			wr;			// i: data write
	input 			rd;			// i: data read
	input [7:0] 	din;		// i: data input bus
	output[7:0] 	dout;		// o: data output bus
	input [2:0] 	gate;		// i: gate inputs, NOT USED
	output [2:0] 	out;		// o: timer outputs
	output [9:0] 	testpin;	// o: test pins
	input 			tpsel;		// i: test pin group selector

wire	[7:0] 	q0;
wire	[7:0]	q1;
wire	[7:0]	q2;

reg		[5:0]	cword0;
reg		[5:0]	cword1;
reg		[5:0]	cword2;

reg [3:0] wren;
reg [3:0] rden;
reg [2:0] cwsel;

always @(wr) begin
	if (wr) 
		case (a)
		2'b00:	wren <= 4'b0001;
		2'b01:	wren <= 4'b0010;
		2'b10:	wren <= 4'b0100;
		2'b11:	wren <= 4'b1000;	// cw
		endcase
	else
		wren <= 4'b0000;
end

always @(rd) begin
	if (rd) 
		case (a)
		2'b00:	rden <= 4'b0001;
		2'b01:	rden <= 4'b0010;
		2'b10:	rden <= 4'b0100;
		2'b11:	rden <= 4'b1000;	// cw
		endcase
	else
		rden <= 4'b0000;
end


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

assign dout = rden[0] ? q0 : rden[1] ? q1 : rden[2] ? q2 : 0;

pit8253_counterunit cu0(clk, ce, tce, din, wren[3] & cwsel[0], din, wren[0], rden[0], q0, gate[0], out[0], testpin0);
pit8253_counterunit cu1(clk, ce, tce, din, wren[3] & cwsel[1], din, wren[1], rden[1], q1, gate[1], out[1]);
pit8253_counterunit cu2(clk, ce, tce, din, wren[3] & cwsel[2], din, wren[2], rden[2], q2, gate[2], out[2], testpin1);

endmodule

module pit8253_counterunit(clk, ce, tce, cword, cwset, d, wren, rden, dout, gate, out, testpins);
	input	clk;			// whatever main clk
	input	ce;				// bus clock enable, e.g. 3MHz
	input	tce;			// timer clock enable, e.g. 1.5MHz
	input 	[5:0] cword;	// control word from top sans counter select: 6 bits
	input	cwset;			// control word set
	input	[7:0] d;		// data in for load
	input	wren;			// data load enable
	input	rden;			// data read enable
	output	reg[7:0] dout;	// read value
	input	gate;			// gate pin
	output	out;			// out pin according to mode

	output [9:0] testpins;

assign testpins = {read_msb, counter_loaded, counter_loading, rl_mode, cw_mode};

parameter M0 = 3'd0, M1 = 3'd1, M2 = 3'd2, M3 = 3'd3, M4 = 3'd4, M5 = 3'd5;

reg		outreg;
assign 	out = outreg;

// control word breakdown
reg  [5:0] 	cwreg;
wire [2:0] 	cw_mode = cwreg[3:1];
wire 		bcd_mode = cwreg[0];
wire [1:0]	rl_mode	 = cwreg[5:4];

// gate sampler
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

//reg 		counter_ena;
reg [15:0] 	counter_load;
reg 		counter_wren;
wire[15:0] 	counter_q;
//reg			halfmode;

reg [15:0]	read_latch; 		// latched value
reg [1:0]	read_msb;			// double-byte read mode


pit8253_downcounter dctr(clk, counter_clock_enable, cw_mode == M3, outreg, counter_load, counter_wren, counter_q);

// master, total, final grand enable
wire counter_clock_enable = tce & /*counter_ena &*/ counter_loaded & !loading_stopper;

reg			loading_msb;	// for rl=3: 0: next 8-bit value will be lsb, 1: msb

reg counter_loaded;
reg counter_loading;

reg loading_stopper;
always @(counter_loading) loading_stopper <= (cw_mode == M0 || cw_mode == M4) & counter_loading;

always @(posedge clk) begin
	if (cwset) begin
		if (cword[5:4] == 2'b00) begin
			read_msb <= 3;
			read_latch <= counter_q;
			dout <= 8'b0;
		end else begin
			loading_msb <= 0;	// reset the doorstopper
			counter_loaded <= 0;
			counter_loading <= 0;
			cwreg <= cword;
			read_msb <= 0;
			read_latch <= 0;
			case (cword[3:1]) 
				M0:	// interrupt, 1-time, start count on load or gate
					begin
						outreg <= 1'b0;
					end
				M1:	// programmable one-shot on gate rising edge; NOT IMPLEMENTED
					begin
						outreg <= 1'b1;
					end
				M2:	// rate generator, start couting on load (or gate rising edge, not supported)
					begin
						outreg <= 1'b1;
					end
				M3: // square waveform generator
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
					counter_loaded <= 1;
					counter_wren <= 1;
				end
		2'b10: 	begin
					counter_load[15:8] <= d;
					counter_loaded <= 1;
					counter_wren <= 1;
				end
		2'b11:	begin
					if (loading_msb) begin
						counter_load[15:8] <= d;
						counter_loaded <= 1;
						counter_loading <= 0;
						counter_wren <= 1;
					end	else begin
						counter_load[7:0] <= d;
						counter_loaded <= 0;
						counter_loading <= 1;
					end
						
					loading_msb <= ~loading_msb;
				end
		2'b00:  ; // illegal state
		endcase
	end
	
	// read
	if (rden & ce) begin
		case (read_msb) 
			3: 	begin
					dout <= read_latch[7:0];
					read_msb <= 2;
				end
			2: 	begin
					dout <= read_latch[15:8];
					read_msb <= 0;
				end
			1: 	begin
					dout <= counter_q[15:8];
					read_msb <= 0;
				end
			0:
				case (rl_mode)
					2'b01:	begin
								dout <= counter_q[7:0];
							end
					2'b10:  begin
								dout <= counter_q[15:8];
							end
					2'b11:	begin
								read_msb <= 1;
								dout <= counter_q[7:0];
							end
				endcase
		endcase
	end
	
	// reset counter_wren on next tce
	if (tce & counter_wren) begin
		counter_wren <= 0;
	end
	
	if (tce) begin
		case (cw_mode) 
			M0:	begin
					if (counter_q == 16'd0) begin
						counter_loaded <= 0;
						outreg <= 1;
					end
				end
			M1: ; // NOT IMPLEMENTED
			M2:	begin
					if (counter_q == 16'd1) begin
						outreg <= 0;
						counter_wren <= 1;
					end else begin
						outreg <= 1;
					end
				end
			M3:	begin
					if (counter_q == 16'd2) begin
						//halfmode <= cw_mode == M3 ^ outreg;
						outreg <= ~outreg;
						counter_wren <= 1;
					end 
				end
			M4:	begin
					if (counter_q == 16'd0) begin
						outreg <= 0;
						counter_loaded <= 0;
					end else
						outreg <= 1; // reset out on next cycle
				end
			M5: ; // NOT IMPLEMENTED
			default:;
		endcase
	end
	
end
endmodule


module pit8253_downcounter(clk, ce, halfmode, o, d, wren, q);
	input clk;
	input ce;
	input halfmode;	// for square wave gen
	input o;		// current state of out for M3
	input [15:0] d;
	input wren;
	output [15:0] q;

reg  [15:0] counter;

wire [15:0] c_1 = counter - 16'd1;
wire [15:0] c_2 = counter - 16'd2;
wire [15:0] c_3 = counter - 16'd3;

wire [15:0] next = ~halfmode ? c_1 :
						counter[0] == 1'b0 ? c_2 : 
						o ? c_1 : c_3;
					

assign q = counter;

always @(negedge clk or posedge wren) begin
	if (wren) begin
		counter <= d;
	end 
	else if (ce) begin
		counter <= next;
	end
end
endmodule

// $Id$
