`default_nettype none

////
//
// Frame Buffer
//
////
module framebuffer(clk24, ce12, video_slice, pipe_abx, fb_row, hsync, SRAM_DQ, SRAM_ADDR, coloridx, borderx, testpin);
input 			clk24;
input 			ce12;
input			video_slice;
input 			pipe_abx;		// pipe selector, should be fed from clockster

input	[8:0]	fb_row;

input hsync;

input 	[7:0]	SRAM_DQ;
output	[15:0]	SRAM_ADDR;

output 	[3:0] 	coloridx;
output 	 		borderx;

output 	[5:0] 	testpin;

assign testpin[0] = wr[0];
assign testpin[1] = wr[1];
assign testpin[2] = wr[2];
assign testpin[3] = wr[3];
assign testpin[4] = pipe_abx;
assign testpin[5] = video_slice;


reg [5:0]	column;				// byte column number

reg [2:0] ax;					// position counter for generating write pulses
								// advances on every clk24 when normal scanning speed
								// advances on every clk24/2 when double scan buffer is used
	
reg [3:0] wr;					// pipeline write pulses, derived from ax count
wire [15:0] SRAM_ADDR;

assign SRAM_ADDR = sram_addr;
reg [15:0] sram_addr;

reg borderxreg;
assign borderx = borderdelay[0];
reg [4:0] borderdelay;
always @(posedge clk24) begin
	if (ce12) begin
		borderdelay <= {borderxreg, borderdelay[4:1]};
	end
end

always @(posedge clk24) begin
	if (video_slice) begin
		if (ax == 3'b111) begin 
			if (!hsync & fb_row[0]) begin
				column <= /*5'h1A*/ 6'b111111-6'd11; 
				borderxreg <= 1;
			end
			else column <= column + 2'b01;
			if (column == 0) borderxreg <= ~borderxreg;
		end
		sram_addr <= {1'b1,ax[2:1],column[5:1],fb_row[8:1]};
		ax <= ax + 1'b1;
		wr[0] <= ax == (3'b000  + 3'b000);
		wr[1] <= ax == (3'b010  + 3'b000);
		wr[2] <= ax == (3'b100  + 3'b000);
		wr[3] <= ax == (3'b110  + 3'b000);
	end else begin
		wr <= 4'b0000;
	end
end

pipelinx pipdx_0(clk24, ce12, pipe_abx, wr[0], SRAM_DQ, coloridx[3]);
pipelinx pipdx_1(clk24, ce12, pipe_abx, wr[1], SRAM_DQ, coloridx[2]);
pipelinx pipdx_2(clk24, ce12, pipe_abx, wr[2], SRAM_DQ, coloridx[1]);
pipelinx pipdx_3(clk24, ce12, pipe_abx, wr[3], SRAM_DQ, coloridx[0]);


endmodule


////
//
// 2 shift registers, selectable by ab
// writeplz: async load
// clk/ce pushes the data out right
//
////
module pipelinx(clk, ce, ab, writeplz, din, bout);
input clk;
input ce;
input ab;
input writeplz;
input [7:0] din;
output bout = ab ? boutb : bouta;	// curent bits of all 4 registers

wire n_ab = !ab;
wire bouta, boutb;

shiftreg2 pipa(clk, ce & n_ab, din, writeplz & ab,   bouta);
shiftreg2 pipb(clk, ce & ab,   din, writeplz & n_ab, boutb);

endmodule


module rambuffer(clk, cerd, cewr, wren, resetrd, resetwr, din, dout);
parameter FUCK = 4;
input clk;
input cerd;
input cewr;
input wren;
input resetrd;
input resetwr;
input [7:0] din;
output reg[7:0] dout;

reg [7:0] pixelram[1023:0];

wire [9:0] rdaddr;
wire [9:0] wraddr;

rdwrctr c1(clk, cerd, resetrd, rdaddr);
rdwrctr c2(clk, cewr, resetwr, wraddr);

wire [9:0] addr = wren ? wraddr : rdaddr;

always @(posedge clk) begin
	if (wren) begin
		pixelram[wraddr] <= din;
	end
	dout <= pixelram[rdaddr];
end

endmodule

module rdwrctr(clk, ce, reset, q);
input clk;
input ce;
input reset;
output [9:0] q;

/*
always @(posedge clk) begin
	if (ce) begin
		if (reset) 
			q <= 0;
		else
			q <= q + 1'b1;
	end
end
*/
lpm_counter ctr(.clock(clk), .clk_en(ce), .aclr(reset), .q(q));
defparam ctr.LPM_WIDTH = 10,
		 ctr.LPM_DIRECTION = "UP";

endmodule

