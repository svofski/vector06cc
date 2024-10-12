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

module I2C_AV_Config (
    //  Host Side
    input       iCLK,
    input       iRST_N,
    //  I2C Side
    output      I2C_SCLK,
    inout       I2C_SDAT
    );

localparam WM8978_ADDR = 8'h1A;

//  Internal Registers/Wires
reg [15:0]  mI2C_CLK_DIV;
reg [23:0]  mI2C_DATA;
reg         mI2C_CTRL_CLK;
reg         mI2C_GO;
wire        mI2C_END;
wire        mI2C_ACK;
reg [15:0]  LUT_DATA;
reg [4:0]   LUT_INDEX;
reg [1:0]   mSetup_ST;

//  Clock Setting
parameter   CLK_Freq    =   50000000;   //  50  MHz
parameter   I2C_Freq    =   20000;      //  20  KHz
//  LUT Data Number
parameter   LUT_SIZE    =   11;
//  Audio Data Index
parameter   Dummy_DATA  =   0;
parameter   SET_LIN_L   =   1;
parameter   SET_LIN_R   =   2;
parameter   SET_HEAD_L  =   3;
parameter   SET_HEAD_R  =   4;
parameter   A_PATH_CTRL =   5;
parameter   D_PATH_CTRL =   6;
parameter   POWER_ON    =   7;
parameter   SET_FORMAT  =   8;
parameter   SAMPLE_CTRL =   9;
parameter   SET_ACTIVE  =   10;

/////////////////////   I2C Control Clock   ////////////////////////
always@(posedge iCLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        mI2C_CTRL_CLK   <=  0;
        mI2C_CLK_DIV    <=  0;
    end
    else
    begin
        if( mI2C_CLK_DIV    < (CLK_Freq/I2C_Freq) )
        mI2C_CLK_DIV    <=  mI2C_CLK_DIV+1'b1;
        else
        begin
            mI2C_CLK_DIV    <=  0;
            mI2C_CTRL_CLK   <=  ~mI2C_CTRL_CLK;
        end
    end
end
////////////////////////////////////////////////////////////////////
I2C_Controller  u0  (   .CLOCK(mI2C_CTRL_CLK),      //  Controller Work Clock
                        .I2C_SCLK(I2C_SCLK),        //  I2C CLOCK
                        .I2C_SDAT(I2C_SDAT),        //  I2C DATA
                        .I2C_DATA(mI2C_DATA),       //  DATA:[SLAVE_ADDR,SUB_ADDR,DATA]
                        .GO(mI2C_GO),               //  GO transforrrrr
                        .END(mI2C_END),             //  END transforrrrr
                        .ACK(mI2C_ACK),             //  ACK
                        .RESET(iRST_N)  );
////////////////////////////////////////////////////////////////////
//////////////////////  Config Control  ////////////////////////////
always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
    if(!iRST_N)
    begin
        LUT_INDEX   <=  0;
        mSetup_ST   <=  0;
        mI2C_GO     <=  0;
    end
    else
    begin
        if(LUT_INDEX<LUT_SIZE)
        begin
            case(mSetup_ST)
            0:  begin
                    mI2C_DATA   <=  {WM8978_ADDR, LUT_DATA};
                    mI2C_GO     <=  1;
                    mSetup_ST   <=  1;
                end
            1:  begin
                    if(mI2C_END)
                    begin
                        if(!mI2C_ACK)
                        mSetup_ST   <=  2;
                        else
                        mSetup_ST   <=  0;                          
                        mI2C_GO     <=  0;
                    end
                end
            2:  begin
                    LUT_INDEX   <=  LUT_INDEX+1'b1;
                    mSetup_ST   <=  0;
                end
            endcase
        end
    end
end
////////////////////////////////////////////////////////////////////
/////////////////////   Config Data LUT   //////////////////////////    
// data = {reg_addr[6:0],regval[8],regval[7:0]}
always
begin
    case(LUT_INDEX)
        01:   LUT_DATA    <=  regval(0,0); // soft reset
        02:   LUT_DATA    <=  regval(1, 9'h9b);   // R1, OUT4MIXEN, MICEN (MIC), BIASEN, VMIDSEL[1:0]
        03:   LUT_DATA    <=  regval(2, 9'h1B0);  // R2, ROUT1, LOUT1, BOOSTENR, BOOSTENL   
        04:   LUT_DATA    <=  regval(3, 9'h16C);  // R3, OUT4EN, LOUT2EN, ROUT2EN, RMIXEN, LMIXEN 
        05:   LUT_DATA    <=  regval(6, 0);       // R6, MCLK is external
        06:   LUT_DATA    <=  regval(43, 1<<4);   // R43, INVROUT2 "Mute input to INVROUT2 mixer"
        07:   LUT_DATA    <=  regval(47,1<<8);    // R47, PGABOOSTL, MIC boost L
        08:   LUT_DATA    <=  regval(48,1<<8);    // R48, PGABOOSTR, MIC boost R
        09:   LUT_DATA    <=  regval(49,1<<1);    // R49, TSDEN thermal shutdown enable
        10:   LUT_DATA    <=  regval(10,1<<3);    // R10, DACOSR 128x oversampling
        11:   LUT_DATA    <=  regval(14,1<<3);    // R14, ADCOSR 128x oversampling
        default     :   LUT_DATA    <=  16'h0000;
    endcase
end
////////////////////////////////////////////////////////////////////
endmodule

function regval(input [6:0] regaddr, input [8:0] value);
    regval = {regaddr, value};
endfunction
