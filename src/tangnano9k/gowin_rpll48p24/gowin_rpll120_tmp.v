//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.03 Education (64-bit)
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Sep 22 20:21:09 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_rPLL120 your_instance_name(
        .clkout(clkout), //output clkout
        .lock(lock), //output lock
        .clkin(clkin) //input clkin
    );

//--------Copy end-------------------