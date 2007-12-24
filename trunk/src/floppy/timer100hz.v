`default_nettype none

module timer100hz(clk, di, wren, q);
parameter MCLKFREQ = 24000000;

input 			clk;
input [7:0]		di;
input			wren;
output reg[7:0]	q;

reg [17:0] timerctr;
wire hz100 = timerctr == 0;

always @(posedge clk) begin
	if (timerctr == 0) 
		timerctr <= MCLKFREQ/100;
	else
		timerctr <= timerctr - 1;
end

always @(posedge clk or posedge wren) begin
	if (wren) begin
		q <= di;
	end 
	else if (q != 0 && hz100) q <= q - 1'b1;
end

endmodule

