//
// Author: Viacheslav Slavinsky
//

`default_nettype none

module ps2k(
	clk,
	reset,
	ps2_clk,
	ps2_data,
	rden,
	q,
	dsr,
	overflow);
input clk;
input reset;

input ps2_clk;
input ps2_data;

input rden;
output [7:0] q;
output reg dsr;
output overflow = watchdog;

wire watchdog;
reg watchdogtrig;
ps2watchdog ps2wd(clk, watchdogtrig, watchdog);

reg [7:0] qreg;

reg [1:0] state = 2'b00;

reg [4:0] sampledelay;
reg [1:0] samplebuf;
reg sample_ce;
always @(posedge clk) begin
	samplebuf <= {samplebuf[0], ps2_clk};
	sample_ce <= samplebuf[1] & ~samplebuf[0];
end

/*
assign dsr = wrptr != rdptr;
*/

reg [9:0] shiftreg;
reg [7:0] q;
reg [3:0] bitcount = 4'b0;

always @(posedge clk) begin
	if (reset) begin
		bitcount <= 4'b0;
		q <= 8'b0;
		state <= 2'b00;
		dsr <= 1'b0;
		watchdogtrig <= 0;
	end else begin
		case (state)
		2'b00: // must be a start bit == 0
			begin
				watchdogtrig <= 0;
				if (sample_ce) begin
					if (~ps2_data) begin
						bitcount <= 9;
						state <= 2'b01;
						watchdogtrig <= 1;
					end
					else state <= 2'b11;
				end
			end
		2'b01:
			begin
				if (sample_ce) begin
					shiftreg <= {ps2_data, shiftreg[9:1]};
					bitcount <= bitcount - 1'b1;
					if (bitcount == 0) state <= 2'b10;
				end 
				else begin
					if (watchdog) state <= 2'b11; // stuck
				end
			end
		2'b10:
			begin
				if (shiftreg[9] && (^shiftreg[8:0])==1'b1) begin
					qreg <= shiftreg[7:0];
					dsr <= 1'b1;
					state <= 2'b00;
				end
			end
		2'b11:
			begin
				state <= 2'b00;
			end
		endcase
		
		if (dsr & rden) begin
			q <= qreg;
			dsr <= 1'b0;
		end
		
	end
end

endmodule


module ps2watchdog(clk24, trig, watchdog);
input clk24;
input trig;
output reg watchdog;

reg [15:0] divctr;
always @(posedge clk24) begin
	if (divctr == 0 && trig) begin
		divctr <= 16'h7FFF;
	end
	if (divctr != 0) begin
		divctr <= divctr - 1'b1;
	end
	watchdog <= &(~divctr[15:1]) & divctr[0];
end

endmodule

