module ayglue(clk, ce, reset_n, address, data, wren, rden, q, soundA,soundB,soundC,odataoe);
input 			clk;
input			ce;
input			reset_n;
input 			address;		// port 14 (00) = data; port 15 (01) = address
input [7:0]		data;
input			wren;
input			rden;
output reg[7:0]	q;
output			odataoe;

output[7:0]	soundA;
output[7:0]	soundB;
output[7:0]	soundC;

wire [7:0] 	odata;
wire 		odataoe;


reg [2:0] ctl;	// {I_BDIR,I_BC2,I_BC1}
always begin
		case ({address,wren,rden}) 
			3'b110:		ctl <= 3'b111;	// write addr
			3'b010:		ctl <= 3'b110;	// wr data
			3'b001:		ctl <= 3'b011;	// rd data
			default:	ctl <= 3'b010;
		endcase
end

//ay8910 digeridoo(
ym2149 digeridoo(
  .DI(data),
  .DO(q),
  .BDIR(ctl[2]), 
  .BC(ctl[0]),
  .OUT_A(soundA),
  .OUT_B(soundB),
  .OUT_C(soundC),
  .CS(1'b1),
  .ENA(ce),
  .RESET(~reset_n),
  .CLK(clk)
  );


endmodule
