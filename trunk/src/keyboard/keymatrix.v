module keymatrix(clk, addr, d, wren, q);
input clk;
input [2:0] addr;
input [7:0] d;
input		wren;
output reg[7:0] q;

reg [7:0] km[0:7];

always q <= km[addr];

always @(posedge clk)
	if (wren)
		km[addr] <= d;

endmodule
