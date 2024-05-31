
// Undefine following for smaller/faster builds
`define WITH_CPU            
//`define WITH_VM80A
`define WITH_T8080
`define WITH_KEYBOARD
//`define WITH_KEYBOARD_PS2         // -- ps/2 on gpio
`define WITH_KEYBOARD_SERIAL        // -- debugprobe serial keyboard
//`define WITH_VI53
//`define WITH_AY
//`define WITH_RSOUND
`define WITH_FLOPPY
`define WITH_OSD
//`define WITH_SDRAM
`define WITH_PSRAM      // Tang Nano 9K GW1N-NR9 Q88P
//`define FLOPPYLESS_HAX  // set FDC odata to $00 when compiling without floppy
//`define WITH_TV         // WXEDA board has too few resources to switch modes in runtime
//`define WITH_COMPOSITE  // output composite video on VGA pins
//`define COMPOSITE_PWM   // use sigma-delta modulator on composite video out
//`define WITH_SVIDEO 
`define WITH_VGA
`define WITH_SERIAL_PROBE
