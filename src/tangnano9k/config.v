
// Undefine following for smaller/faster builds
`define WITH_CPU            
`define WITH_VM80A
//`define WITH_T8080
`define WITH_KEYBOARD
//`define WITH_KEYBOARD_PS2         // -- ps/2 on gpio
//`define WITH_KEYBOARD_SERIAL        // -- debugprobe serial keyboard
`define WITH_KEYBOARD_HID
`define WITH_VI53
  //`define VI53_B2M                  // Bashkiria-2m wi53 by Dmitry Tselikov //(doesn't work)
  `define VI53_SORGELIG               // k580vi53 by Sorgelig
  //`define VI53_SVOFSKI              // original vi53
`define WITH_AY
//`define WITH_WM8978               // WM8978 audio codec (not implemented yet)
//`define WITH_RSOUND
`define PWM_STEREO

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
//`define SCAN_2_1
`define SCAN_5_3
//`define SCAN_7INCH

//`define WITH_SERIAL_PROBE

`define OSD_TOP_FB_ROW    9'd250   // more is higher above (200 is cursed)
`define OSD_HPOS          9'd170
`define OSD_TV_HALFLINE   275   // less is higher above
