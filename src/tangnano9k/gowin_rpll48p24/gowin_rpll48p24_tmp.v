//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.9 Beta-4 Education
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Thu Apr 11 02:56:00 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL48p24 your_instance_name(
        .clkout(clkout_o), //output clkout
        .clkoutp(clkoutp_o), //output clkoutp
        .clkoutd(clkoutd_o), //output clkoutd
        .clkin(clkin_i) //input clkin
    );

//--------Copy end-------------------
