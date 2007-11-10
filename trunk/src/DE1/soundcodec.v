module soundcodec(clk18, pulses, reset_n, oAUD_BCK, oAUD_DATA, oAUD_LRCK);
input	clk18;
input	[3:0] pulses;
input	reset_n;
output	oAUD_BCK;
output	oAUD_DATA;
output	oAUD_LRCK;

reg [6:0] decimator;
always @(posedge clk18) decimator <= decimator + 1;

wire ma_ce = decimator == 0;

reg [15:0] ma_pulse;

reg [19:0] pulses_sample[0:3];

wire [4:0] m04 = {2'b00,pulses[0],2'b00};
wire [4:0] m14 = {2'b00,pulses[1],2'b00};
wire [4:0] m24 = {2'b00,pulses[2],2'b00};
wire [4:0] m34 = {2'b00,pulses[3],2'b00};

reg [4:0] sumA;
reg [4:0] sumB;
reg [4:0] sumC;
reg [4:0] sumD;

always @(posedge clk18) begin
	if (ma_ce) begin
		pulses_sample[3] <= pulses_sample[2];
		pulses_sample[2] <= pulses_sample[1];
		pulses_sample[1] <= pulses_sample[0];
		pulses_sample[0] <= {m34,m24,m14,m04};
		
		sumA <= pulses_sample[0][4:0] + pulses_sample[1][4:0] + pulses_sample[2][4:0] + pulses_sample[3][4:0];
		sumB <= pulses_sample[0][9:5] + pulses_sample[1][9:5] + pulses_sample[2][9:5] + pulses_sample[3][9:5];
		sumC <= pulses_sample[0][14:10]+pulses_sample[1][14:10]+pulses_sample[2][14:10]+pulses_sample[3][14:10];
		sumD <= pulses_sample[0][19:15]+pulses_sample[1][19:15]+pulses_sample[2][19:15]+pulses_sample[3][19:15];
		
		ma_pulse <= {1'b0,sumA[4:2], 1'b0,sumB[4:2], 1'b0,sumC[4:2], 1'b0,sumD[4:2]};
	end
end

AUDIO_DAC audiodac(oAUD_BCK, oAUD_DATA, oAUD_LRCK, clk18, reset_n, ma_pulse);		

endmodule
