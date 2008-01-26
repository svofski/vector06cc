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
// Design File: vectorkeys.v
//
// Keyboard interface. This module maps PS/2 keyboard keypresses
// and releases into a keyboard matrix model used in Vector-06C.
// 
// Can be optimized space-wise by reducing the giant rowbits
// expression into a sequential process. 
//
// See http://www.quadibloc.com/comp/scan.htm
// for information about why shift key is being de-pressed and pressed 
// when grey arrows are pressed
//
// --------------------------------------------------------------------



`default_nettype none
module vectorkeys(clkk, reset, ps2_clk, ps2_dat, mod_rus, rowselect, rowbits, key_shift, key_ctrl, key_rus, key_blksbr, key_blkvvod, key_bushold, key_osd, osd_active);
input 				clkk;
input 				reset;
input 				ps2_clk;
input 				ps2_dat;

input				mod_rus;		// RUS on

input [7:0]			rowselect;		// PA output inverted
output[7:0] 		rowbits;		// PB input  inverted
output				key_shift;
output 				key_ctrl;
output				key_rus;
output				key_blksbr;
output				key_blkvvod;
output				key_bushold;
output reg[5:0] 	key_osd;
input				osd_active;

// for testing
//output[3:0] lastrownum;
//output[7:0]	lastrowbits;

reg 		ps2rden;
wire 		ps2dsr;
wire [7:0] 	ps2q;
ps2k ps2driver(clkk, reset, ps2_clk, ps2_dat, ps2rden, ps2q, ps2dsr);

reg 		qey_shift = 0;
reg			key_ctrl = 0;
reg 		key_rus = 0;
reg			key_blksbr = 0;
reg			key_blkvvod = 0;
reg			key_bushold = 0;

wire [2:0]	matrix_row;
wire [2:0]	matrix_col;
wire		matrix_shift;
wire		neo_raw;			// not in matrix
wire		neo = osd_active | neo_raw;
wire [7:0]	decoded_col;

scan2matrix scan2xy(clkk, ps2q, saved_ps2_shift|qey_shift, mod_rus, matrix_row, matrix_col, matrix_shift, neo_raw);

assign 	key_shift = qey_shift ^ qmatrix_shift; 
reg		qmatrix_shift;
reg		saved_ps2_shift;	// when a key requiring shift-play is pressed, shift
							// flag must be remembered until its release, otherwise
							// wrong release code is detected

keycolumndecoder column_dc(matrix_col,decoded_col);


wire	saved_shift;			// grey arrow keys send break-shift code and then make shift after release
reg		saved_shift_trigger;

reg		[8:0] slow_ce_ctr;
always 	@(posedge clkk) slow_ce_ctr <= slow_ce_ctr + 1'b1;
wire	slow_ce = slow_ce_ctr == 0;
oneshot #(255) shitshot(clkk, slow_ce, saved_shift_trigger, saved_shift);

reg [3:0] state = 0;
reg [7:0] keymatrix[0:7];
reg [7:0] tmp;

always @(posedge clkk) begin
	if (reset) begin
		keymatrix[0] <= 0;
		keymatrix[1] <= 0;
		keymatrix[2] <= 0;
		keymatrix[3] <= 0;
		keymatrix[4] <= 0;
		keymatrix[5] <= 0;
		keymatrix[6] <= 0;
		keymatrix[7] <= 0;
		qey_shift <= 0;
		key_ctrl  <= 0;
		key_rus	  <= 0;
		key_blksbr <= 0;
		key_blkvvod <= 0;
		key_bushold <= 0;
		key_osd <= 0;
		saved_shift_trigger <= 0;
		state <= 0;
	end 
	else begin
		case (state)
		0: begin
				//matrix_row <= rowaddr;
				state <= 10;
			end
		10:	begin
				//ledr[0] <= 0;
				if (ps2dsr) begin
					ps2rden <= 1;
					state <= 1;
				end
			end
		1:	begin
				state <= 2;
				ps2rden <= 0;
			end
		2:	state <= 3;
			
		3:	begin
				ps2rden <= 0;
				if (ps2q == 8'hF0) begin
					state <= 5;
				end
				else begin
					tmp <= keymatrix[matrix_row];
					state <= 4;
				end
			end
			
		4:	begin
				case(ps2q)
					8'h12:	qey_shift <= 1;
					8'h59:	qey_shift <= 1;
					8'h14:	key_ctrl  <= 1;
					8'h58:	key_rus	  <= 1;
					8'h78:	key_blkvvod <= 1;
					8'h07:	key_blksbr<= 1;	// F12
					8'h7E:	key_bushold <= 1;
					// special treatment of grey arrow keys
					8'hE0:	;// do nada plz
					default: begin
							case (ps2q) 
								8'h75,8'h72,8'h6b,8'h74: qey_shift <= saved_shift;
							endcase
							
							case (ps2q) 
								8'h75:	key_osd[2] <= osd_active;
								8'h72:  key_osd[1] <= osd_active;
								8'h6b:	key_osd[4] <= osd_active;
								8'h74:  key_osd[3] <= osd_active;
								8'h5a:	key_osd[0] <= osd_active;
							endcase
							
							if (!neo) begin
								keymatrix[matrix_row] <= tmp | decoded_col;
								qmatrix_shift <= qmatrix_shift | matrix_shift;
								if (matrix_shift) saved_ps2_shift <= qey_shift;
							end
						end
				endcase
				saved_shift_trigger	<= 0;
				state <= 0;
			end
			
		5:	begin
				//ledr[0] <= 1;
				if (ps2dsr) begin
					ps2rden <= 1;
					state <= 6;
				end
			end
			
		6:	begin
				ps2rden <= 0;
				state <= 7;
			end
			
		7:	state <= 8;
		
		8:	begin
				tmp <= keymatrix[matrix_row];
				state <= 9;
			end
			
		9:	begin
				case(ps2q)
					8'h12,8'h59: 
						begin 
							qey_shift <= 0; 
							saved_shift_trigger <= 1'b1; 
						end
					8'h14:	key_ctrl  <= 0;
					8'h58:	key_rus	  <= 0;
					8'h78:	key_blkvvod <= 0;
					8'h07:	key_blksbr<= 0;
					8'h7E:	key_bushold <= 0;
					8'hE0:	;// do nada plz
					default: 
						begin
							case (ps2q) 
								8'h75:	key_osd[2] <= 0;
								8'h72:  key_osd[1] <= 0;
								8'h6b:	key_osd[4] <= 0;
								8'h74:  key_osd[3] <= 0;
								8'h5a:	key_osd[0] <= 0;
							endcase
						
							if (!neo) begin
								keymatrix[matrix_row] <=  tmp & ~decoded_col;
								if (saved_ps2_shift & matrix_shift) saved_ps2_shift <= 1'b0;
								qmatrix_shift <= 1'b0;
							end
						end
				endcase
				state <= 0;
			end
		endcase
	end
end

// This is really dumb, together with the rest of code above 
// it unrolls into humongous structure, but it works and it is readable.
reg  [7:0] 	rowbits;
always @(posedge clkk) begin
	rowbits <= 
		  (rowselect[0] ? keymatrix[0] : 0)
		| (rowselect[1] ? keymatrix[1] : 0)
		| (rowselect[2] ? keymatrix[2] : 0)
		| (rowselect[3] ? keymatrix[3] : 0)
		| (rowselect[4] ? keymatrix[4] : 0)
		| (rowselect[5] ? keymatrix[5] : 0)
		| (rowselect[6] ? keymatrix[6] : 0)
		| (rowselect[7] ? keymatrix[7] : 0);
end

endmodule



module keycolumndecoder(d,q);
input [2:0] d;
output reg[7:0] q;

always begin
	case (d)
	3'b000:	q <= 8'b00000001;
	3'b001: q <= 8'b00000010;
	3'b010: q <= 8'b00000100;
	3'b011: q <= 8'b00001000;
	3'b100: q <= 8'b00010000;
	3'b101: q <= 8'b00100000;
	3'b110: q <= 8'b01000000;
	3'b111: q <= 8'b10000000;
	endcase
end
endmodule


// $Id$
