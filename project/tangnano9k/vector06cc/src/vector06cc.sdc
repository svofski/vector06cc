//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03  Education (64-bit)
//Created Time: 2024-10-20 22:02:07
create_clock -name XTAL_27MHZ -period 37.037 -waveform {0 18.518} [get_ports {XTAL_27MHZ}]
// WITH_HDMI
create_generated_clock -name clk120 -source [get_ports {XTAL_27MHZ}] -master_clock XTAL_27MHZ -divide_by 9 -multiply_by 40 -duty_cycle 50 [get_nets {clk_p5}]
create_generated_clock -name clk_psram -source [get_ports {XTAL_27MHZ}] -master_clock XTAL_27MHZ -divide_by 3 -multiply_by 8 -duty_cycle 50 [get_nets {clk_psram}]
create_generated_clock -name clk_psram_p -source [get_ports {XTAL_27MHZ}] -master_clock XTAL_27MHZ -divide_by 3 -multiply_by 8 -duty_cycle 50 -phase 135 [get_nets {clk_psram_p}]
create_generated_clock -name clk24 -source [get_nets{clk_p5}] -divide_by 5 [get_nets {clk24}] 

// clk_psram_p 90 -> 135 degree seems to be going in a more stable direction

// WITH_LCD
//...

