//Legal Notice: (C)2006 Altera Corporation. All rights reserved. Your
//use of Altera Corporation's design tools, logic functions and other
//software and tools, and its AMPP partner logic functions, and any
//output files any of the foregoing (including device programming or
//simulation files), and any associated documentation or information are
//expressly subject to the terms and conditions of the Altera Program
//License Subscription Agreement or other applicable license agreement,
//including, without limitation, that your use is for the sole purpose
//of programming logic devices manufactured by Altera and sold by Altera
//or its authorized distributors.  Please refer to the applicable
//agreement for further details.

module AUDIO_DAC (// Audio Side
					oAUD_BCK,
					oAUD_DATA,
					oAUD_LRCK,
					iAUD_ADCDAT,
					oAUD_ADCLRCK,
					//	Control Signals
				    iCLK_18_4,
					iRST_N,
					pulses,
					linein);				

parameter	REF_CLK			=	18432000;	//	18.432	MHz
parameter	SAMPLE_RATE		=	48000;		//	48		KHz
parameter	DATA_WIDTH		=	16;			//	16		Bits
parameter	CHANNEL_NUM		=	2;			//	Dual Channel

parameter	SIN_SAMPLE_DATA	=	48;

////////////	Input Source Number	//////////////
parameter	SIN_SANPLE		=	0;
//	Audio Side
output			oAUD_DATA;
output			oAUD_LRCK;
output	reg		oAUD_BCK;
input			iAUD_ADCDAT;
output			oAUD_ADCLRCK;
//	Control Signals
input			iCLK_18_4;
input			iRST_N;
input	[15:0]	pulses;
output	[15:0]	linein;

//	Internal Registers and Wires
reg		[3:0]	BCK_DIV;
reg		[8:0]	LRCK_1X_DIV;
reg		[7:0]	LRCK_2X_DIV;
reg		[6:0]	LRCK_4X_DIV;
reg		[3:0]	SEL_Cont;
////////	DATA Counter	////////
reg		[5:0]	SIN_Cont;
////////////////////////////////////
reg		[DATA_WIDTH-1:0]	Sin_Out;
reg							LRCK_1X;
reg							LRCK_2X;
reg							LRCK_4X;

////////////	AUD_BCK Generator	//////////////
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		BCK_DIV		<=	0;
		oAUD_BCK	<=	0;
	end
	else
	begin
		if(BCK_DIV >= REF_CLK/(SAMPLE_RATE*DATA_WIDTH*CHANNEL_NUM*2)-1 )
		begin
			BCK_DIV		<=	0;
			oAUD_BCK	<=	~oAUD_BCK;
		end
		else
		BCK_DIV		<=	BCK_DIV+1;
	end
end
//////////////////////////////////////////////////
////////////	AUD_LRCK Generator	//////////////
always@(posedge iCLK_18_4 or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LRCK_1X_DIV	<=	0;
		LRCK_2X_DIV	<=	0;
		LRCK_4X_DIV	<=	0;
		LRCK_1X		<=	0;
		LRCK_2X		<=	0;
		LRCK_4X		<=	0;
	end
	else
	begin
		//	LRCK 1X
		if(LRCK_1X_DIV >= REF_CLK/(SAMPLE_RATE*2)-1 )
		begin
			LRCK_1X_DIV	<=	0;
			LRCK_1X	<=	~LRCK_1X;
		end
		else
		LRCK_1X_DIV		<=	LRCK_1X_DIV+1;
		//	LRCK 2X
		if(LRCK_2X_DIV >= REF_CLK/(SAMPLE_RATE*4)-1 )
		begin
			LRCK_2X_DIV	<=	0;
			LRCK_2X	<=	~LRCK_2X;
		end
		else
		LRCK_2X_DIV		<=	LRCK_2X_DIV+1;		
		//	LRCK 4X
		if(LRCK_4X_DIV >= REF_CLK/(SAMPLE_RATE*8)-1 )
		begin
			LRCK_4X_DIV	<=	0;
			LRCK_4X	<=	~LRCK_4X;
		end
		else
		LRCK_4X_DIV		<=	LRCK_4X_DIV+1;		
	end
end

assign	oAUD_LRCK	=	LRCK_1X;
assign 	oAUD_ADCLRCK=	oAUD_LRCK;
//////////////////////////////////////////////////
//////////	Sin LUT ADDR Generator	//////////////
always@(negedge LRCK_1X or negedge iRST_N)
begin
	if(!iRST_N)
	SIN_Cont	<=	0;
	else
	begin
		if(SIN_Cont < SIN_SAMPLE_DATA-1 )
		SIN_Cont	<=	SIN_Cont+1;
		else
		SIN_Cont	<=	0;
	end
end

//////////////////////////////////////////////////
//////////	16 Bits PISO MSB First	//////////////
always@(negedge oAUD_BCK or negedge iRST_N)
begin
	if(!iRST_N)
	SEL_Cont	<=	0;
	else
	SEL_Cont	<=	SEL_Cont+1;
end


reg [15:0] pulsebuf;
always @(negedge LRCK_1X) begin
	pulsebuf <= pulses;
end

assign	oAUD_DATA	=	pulsebuf[~SEL_Cont];//Sin_Out[~SEL_Cont];

assign linein = inputsample;
reg [15:0] inputsample;
reg [15:0] inputbuf;
always @(negedge oAUD_BCK) begin
	inputbuf[~SEL_Cont] <= iAUD_ADCDAT;
end

always @(negedge LRCK_1X) begin
	inputsample <= inputbuf;
end

//////////////////////////////////////////////////
////////////	Sin Wave ROM Table	//////////////
always@(SIN_Cont)
begin
    case(SIN_Cont)
    0  :  Sin_Out       <=      0       ;
    1  :  Sin_Out       <=      4276    ;
    2  :  Sin_Out       <=      8480    ;
    3  :  Sin_Out       <=      12539   ;
    4  :  Sin_Out       <=      16383   ;
    5  :  Sin_Out       <=      19947   ;
    6  :  Sin_Out       <=      23169   ;
    7  :  Sin_Out       <=      25995   ;
    8  :  Sin_Out       <=      28377   ;
    9  :  Sin_Out       <=      30272   ;
    10  :  Sin_Out      <=      31650   ;
    11  :  Sin_Out      <=      32486   ;
    12  :  Sin_Out      <=      32767   ;
    13  :  Sin_Out      <=      32486   ;
    14  :  Sin_Out      <=      31650   ;
    15  :  Sin_Out      <=      30272   ;
    16  :  Sin_Out      <=      28377   ;
    17  :  Sin_Out      <=      25995   ;
    18  :  Sin_Out      <=      23169   ;
    19  :  Sin_Out      <=      19947   ;
    20  :  Sin_Out      <=      16383   ;
    21  :  Sin_Out      <=      12539   ;
    22  :  Sin_Out      <=      8480    ;
    23  :  Sin_Out      <=      4276    ;
    24  :  Sin_Out      <=      0       ;
    25  :  Sin_Out      <=      61259   ;
    26  :  Sin_Out      <=      57056   ;
    27  :  Sin_Out      <=      52997   ;
    28  :  Sin_Out      <=      49153   ;
    29  :  Sin_Out      <=      45589   ;
    30  :  Sin_Out      <=      42366   ;
    31  :  Sin_Out      <=      39540   ;
    32  :  Sin_Out      <=      37159   ;
    33  :  Sin_Out      <=      35263   ;
    34  :  Sin_Out      <=      33885   ;
    35  :  Sin_Out      <=      33049   ;
    36  :  Sin_Out      <=      32768   ;
    37  :  Sin_Out      <=      33049   ;
    38  :  Sin_Out      <=      33885   ;
    39  :  Sin_Out      <=      35263   ;
    40  :  Sin_Out      <=      37159   ;
    41  :  Sin_Out      <=      39540   ;
    42  :  Sin_Out      <=      42366   ;
    43  :  Sin_Out      <=      45589   ;
    44  :  Sin_Out      <=      49152   ;
    45  :  Sin_Out      <=      52997   ;
    46  :  Sin_Out      <=      57056   ;
    47  :  Sin_Out      <=      61259   ;
	default	:
		   Sin_Out		<=		0		;
	endcase
end
//////////////////////////////////////////////////

endmodule
								
			
					

