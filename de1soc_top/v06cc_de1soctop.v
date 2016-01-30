
//`define ENABLE_HPS

module v06cc_de1soctop(

      ///////// ADC /////////
      inout              ADC_CS_N,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      ///////// AUD /////////
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,

      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// FAN /////////
      output             FAN_CTRL,

      ///////// FPGA /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// GPIO /////////
      inout     [35:0]         GPIO_0,
		inout     [35:0]         GPIO_1,
 

      ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5,

`ifdef ENABLE_HPS
      ///////// HPS /////////
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout       [3:0]  HPS_FLASH_DATA,
      output             HPS_FLASH_DCLK,
      output             HPS_FLASH_NCSO,
      inout       [1:0]  HPS_GPIO,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_I2C2_SCLK,
      inout              HPS_I2C2_SDAT,
      inout              HPS_I2C_CONTROL,
      inout              HPS_KEY,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP,
`endif /*ENABLE_HPS*/

      ///////// IRDA /////////
      input              IRDA_RXD,
      output             IRDA_TXD,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,

      ///////// PS2 /////////
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// TD /////////
      input              TD_CLK27,
      input      [7:0]  TD_DATA,
      input             TD_HS,
      output             TD_RESET_N,
      input             TD_VS,


      ///////// VGA /////////
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS
);

`default_nettype none

wire clkVGA;
vector06cc(
			.clk50mhz(CLOCK_50),
			.KEY(KEY[3:0]),
			.LEDr(LEDR[9:0]),
//			.LEDg(LEDG[7:0]),
			.SW(SW[9:0]),
			.HEX0(HEX0),
			.HEX1(HEX1),
			.HEX2(HEX2),
			.HEX3(HEX3), 

        .DRAM_DQ(DRAM_DQ[15:0]),                        //  SDRAM Data bus 16 Bits
        .DRAM_ADDR(DRAM_ADDR[11:0]),                      //  SDRAM Address bus 12 Bits
        .DRAM_LDQM(DRAM_LDQM),                      //  SDRAM Low-byte Data Mask 
        .DRAM_UDQM(DRAM_UDQM),                      //  SDRAM High-byte Data Mask
        .DRAM_WE_N(DRAM_WE_N),                      //  SDRAM Write Enable
        .DRAM_CAS_N(DRAM_CAS_N),                     //  SDRAM Column Address Strobe
        .DRAM_RAS_N(DRAM_RAS_N),                     //  SDRAM Row Address Strobe
        .DRAM_CS_N(DRAM_CS_N),                      //  SDRAM Chip Select
        .DRAM_BA_0(DRAM_BA[0]),                      //  SDRAM Bank Address 0
        .DRAM_BA_1(DRAM_BA[1]),                      //  SDRAM Bank Address 0
        .DRAM_CLK(DRAM_CLK),                       //  SDRAM Clock
        .DRAM_CKE(DRAM_CKE),                       //  SDRAM Clock Enable

        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_R(VGA_R[7:4]),
        .VGA_G(VGA_G[7:4]),
        .VGA_B(VGA_B[7:4]), 

        ////////////////////    I2C     ////////////////////////////
        .I2C_SDAT(FPGA_I2C_SDAT),                       //  I2C Data
        .I2C_SCLK(FPGA_I2C_SCLK),                       //  I2C Clock

        .AUD_BCLK(AUD_BCLK), 
        .AUD_DACDAT(AUD_DACDAT), 
        .AUD_DACLRCK(AUD_DACLRCK),
        .AUD_XCK(AUD_XCK),
        .AUD_ADCLRCK(AUD_ADCLRCK),
        .AUD_ADCDAT(AUD_ADCDAT),

        .PS2_CLK(PS2_CLK),
        .PS2_DAT(PS2_DAT),

/*		  
        ////////////////////    USB JTAG link   ////////////////////
        .TDI(TDI),                            // CPLD -> FPGA (data in)
        .TCK(TCK),                            // CPLD -> FPGA (clk)
        .TCS(TCS),                            // CPLD -> FPGA (CS)
        .TDO(TDO),                            // FPGA -> CPLD (data out)
*/
        ////////////////////    SD_Card Interface   ////////////////
        .SD_DAT(GPIO_1[26]),                         //  SD Card Data
        .SD_DAT3(GPIO_1[32]),                        //  SD Card Data 3
        .SD_CMD(GPIO_1[28]),                         //  SD Card Command Signal
        .SD_CLK(GPIO_1[30]),                         //  SD Card Clock
/*		  
        ///////////////////// USRAT //////////////////////
        .UART_TXD(UART_TXD),
        .UART_RXD(UART_RXD),
*/
        // TEST PIN
        .GPIO_0(GPIO_0[35:0]),
		  
		  .clk96(clkVGA)
);

assign VGA_BLANK_N=1'b1;
assign VGA_CLK=clkVGA;
assign VGA_SYNC_N=1'b0;
assign VGA_R[3:0]=4'b0;
assign VGA_G[3:0]=4'b0;
assign VGA_B[3:0]=4'b0;


endmodule
