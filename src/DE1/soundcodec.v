module soundcodec(clk18, pulses, tapein, reset_n, oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK);
input	clk18;
input	[3:0] pulses;
output	tapein;
input	reset_n;
output	oAUD_BCK;
output	oAUD_DATA;
output	oAUD_LRCK;
input	iAUD_ADCDAT;
output	oAUD_ADCLRCK;

reg [8:0] decimator;
always @(posedge clk18) decimator <= decimator + 1;

wire ma_ce = decimator == 0;


wire [15:0] linein;
reg [15:0] ma_pulse;

reg [7:0] pulses_sample[0:3];

// sample * 16
wire [5:0] m04 = {pulses[0], 4'b0};
wire [5:0] m14 = {pulses[1], 4'b0};
wire [5:0] m24 = {pulses[2], 4'b0};
wire [5:0] m34 = {pulses[3], 4'b0};

reg [7:0] sum;

always @(posedge clk18) begin
	if (ma_ce) begin
		pulses_sample[3] <= pulses_sample[2];
		pulses_sample[2] <= pulses_sample[1];
		pulses_sample[1] <= pulses_sample[0];
		pulses_sample[0] <= m04 + m14 + m24 + m34;
		
		sum <= pulses_sample[0] + pulses_sample[1] + pulses_sample[2] + pulses_sample[3];
		ma_pulse <= {sum[7:2], 8'b0};
	end
end

assign tapein = linein > 8192;

AUDIO_DAC audiodac(oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK, clk18, reset_n, ma_pulse, linein);		

endmodule
