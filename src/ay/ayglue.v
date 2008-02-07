module ayglue(clk, ce, reset_n, address, data, wren, rden, q, sound,odataoe);
input 			clk;
input			ce;
input			reset_n;
input 			address;		// port 14 (00) = data; port 15 (01) = address
input [7:0]		data;
input			wren;
input			rden;
output reg[7:0]	q;
output			odataoe;

output[7:0]	sound;

wire [7:0] 	odata;
wire 		odataoe;

always @(odata, odataoe) if (~odataoe) q <= odata;

reg [2:0] ctl;	// {I_BDIR,I_BC2,I_BC1}
always begin
		case ({address,wren,rden}) 
			3'b110:		ctl <= 3'b001;	// write addr
			3'b010:		ctl <= 3'b110;	// wr data
			3'b001:		ctl <= 3'b011;	// rd data
			default:	ctl <= 3'b000;
		endcase
end


YM2149 digeridoo(
  .I_DA(data),
  .O_DA(odata),
  .O_DA_OE_L(odataoe),

  .I_A9_L(0),
  .I_A8(1),
  .I_BDIR(ctl[2]), 
  .I_BC2(ctl[1]),
  .I_BC1(ctl[0]),
  .I_SEL_L(1), // something /16?

  .O_AUDIO(sound),

  .ENA(ce),
  .RESET_L(reset_n),
  .CLK(clk)
  );


endmodule
