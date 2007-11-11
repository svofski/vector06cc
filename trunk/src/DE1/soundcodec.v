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
always @(posedge clk18) decimator <= decimator + 1'd1;

wire ma_ce = decimator == 0;


wire [15:0] linein;			// comes from codec
reg [15:0] ma_pulse;		// goes to codec

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

AUDIO_DAC audiodac(oAUD_BCK, oAUD_DATA, oAUD_LRCK, iAUD_ADCDAT, oAUD_ADCLRCK, clk18, reset_n, ma_pulse, linein);		

reg [15:0] level_avg;
reg [7:0] lowest;
reg [7:0] highest;
reg [7:0] abs_low;
reg [7:0] abs_high;

wire [7:0] line8in = linein[15:8];

// a really slow counter to adjust min/max envelopes
reg [15:0] slowcount;
always @(posedge oAUD_LRCK) begin
	slowcount <= slowcount + 1'd1;
end

wire [15:0] acc_plus = level_avg + line8in;

wire [7:0] h_l_diff = abs_high - abs_low;

reg [7:0] the_middle;

always @(negedge oAUD_LRCK or negedge reset_n) begin
	if (!reset_n) begin
		abs_low <= 127;
		abs_high <= 128;
		level_avg <= 127;
	end else begin
		if (line8in < abs_low) 	abs_low <= line8in;
		if (line8in > abs_high) abs_high <= line8in;
		
		if (slowcount == 0 && abs_low < level_avg) abs_low <= abs_low + 1'd1;
		if (slowcount == 0 && abs_high > level_avg) abs_high <= abs_high - 1'd1;
		
		level_avg <= acc_plus[15:1];
		
		the_middle <= abs_low + h_l_diff[7:1];
	end
end

assign tapein = line8in > the_middle;

endmodule
