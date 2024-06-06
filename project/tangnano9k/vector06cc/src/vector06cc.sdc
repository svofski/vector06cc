//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4 Education
//Created Time: 2024-05-12 02:20:04
create_clock -name clk_psram_p -period 13.889 -waveform {0 6.944} [get_nets {clk_psram_p}]
create_clock -name clk_psram -period 13.889 -waveform {0 6.944} [get_nets {clk_psram}]
create_clock -name XTAL_27MHZ -period 37.037 -waveform {0 18.518} [get_ports {XTAL_27MHZ}]
create_clock -name clk24 -period 41.667 -waveform {0 20.834} [get_nets {clk24}]
