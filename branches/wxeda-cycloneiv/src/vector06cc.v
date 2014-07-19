// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2009 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// SDRAM version and some other changes: Ivan Gorodetsky
//
// Design File: vector06cc.v
//
// Top-level design file of Vector-06C replica.
//
// Switches, as they are configured now:
//  SW1:SW0         red LED[7:0] display selector: 
//                      00: Data In
//                      01: Data Out
//                      11: registered Data Out
//
//  SW3:SW2         green LED group display selector
//                      00: registered CPU status word
//                      01: keyboard status/testpins
//                      10: RAM disk test pins
//                      11: WR_n, io_stack, SRAM_ADDR[17:15] (RAM disk page)
//
//  SW4         1 = PAL field phase alternate (should be on for normal tv's)
//  SW5         1 = CVBS composite output on VGA R,G,B pins 
//                  (connect them together and feed to tv)
//
//  SW6         unused
//  SW7         unused
//
//              These must be both "1" for normal operation:
//  KEY2:SW8                00: single-clock, tap clock by KEY[1]
//                  01: warp mode: between 6 and 12 MHz
//                  10: slow clock, code is executed at eyeballable speed
//                  11: normal Vector-06C speed, full compatibility mode
//
//  SW9         unused
//
// --------------------------------------------------------------------


`default_nettype none

// Undefine following for smaller/faster builds
`define WITH_CPU            
`define WITH_KEYBOARD
`define WITH_VI53
`define WITH_AY
//`define WITH_RSOUND
`define WITH_FLOPPY
`define WITH_OSD
`define WITH_SDRAM
`define FLOPPYLESS_HAX  // set FDC odata to $00 when compiling without floppy
`define WITH_TV         // WXEDA board has too few resources to switch modes in runtime
//`define WITH_COMPOSITE  // output composite video on VGA pins
//`define COMPOSITE_PWM   // use sigma-delta modulator on composite video out
`define WITH_SVIDEO 

module vector06cc(CLK48, 
    KEY[3:0], 
    DRAM_DQ,                //  SDRAM Data bus 16 Bits
    DRAM_ADDR,              //  SDRAM Address bus 12 Bits
    DRAM_LDQM,              //  SDRAM Low-byte Data Mask 
    DRAM_UDQM,              //  SDRAM High-byte Data Mask
    DRAM_WE_N,              //  SDRAM Write Enable
    DRAM_CAS_N,             //  SDRAM Column Address Strobe
    DRAM_RAS_N,             //  SDRAM Row Address Strobe
    DRAM_CS_N,              //  SDRAM Chip Select
    DRAM_BA_0,              //  SDRAM Bank Address 0
    DRAM_BA_1,              //  SDRAM Bank Address 0
    DRAM_CLK,               //  SDRAM Clock
    DRAM_CKE,               //  SDRAM Clock Enable

    VGA_HS,
    VGA_VS,
    VGA_R,
    VGA_G,
    VGA_B, 
    
    SVIDEO_Y,
    SVIDEO_C,

    PS2_CLK,
    PS2_DAT,

    ////////////////////    SD_Card Interface   ////////////////
    SD_DAT,                         //  SD Card Data
    SD_DAT3,                        //  SD Card Data 3
    SD_CMD,                         //  SD Card Command Signal
    SD_CLK,                         //  SD Card Clock

    ADDAT,
    ADCLK,
    ADCSn,
    BEEP,
    ///////////////////// USRAT //////////////////////
    UART_TXD,
    UART_RXD,
    
DS_EN1,
DS_EN3,
DS_EN2,
DS_EN4,

    
);
input           CLK48;
input [3:0]     KEY;

inout   [15:0]  DRAM_DQ;                //  SDRAM Data bus 16 Bits
output  [11:0]  DRAM_ADDR;              //  SDRAM Address bus 12 Bits
output          DRAM_LDQM;              //  SDRAM Low-byte Data Mask 
output          DRAM_UDQM;              //  SDRAM High-byte Data Mask
output          DRAM_WE_N;              //  SDRAM Write Enable
output          DRAM_CAS_N;             //  SDRAM Column Address Strobe
output          DRAM_RAS_N;             //  SDRAM Row Address Strobe
output          DRAM_CS_N;              //  SDRAM Chip Select
output          DRAM_BA_0;              //  SDRAM Bank Address 0
output          DRAM_BA_1;              //  SDRAM Bank Address 0
output          DRAM_CLK;               //  SDRAM Clock
output          DRAM_CKE;               //  SDRAM Clock Enable

/////// VGA
output          VGA_HS;
output          VGA_VS;
output  [4:0]   VGA_R;
output  [5:0]   VGA_G;
output  [4:0]   VGA_B;

output          SVIDEO_Y;
output          SVIDEO_C;

input           PS2_CLK;
input           PS2_DAT;

////////////////////    SD Card Interface   ////////////////////////
input           SD_DAT;                 //  SD Card Data            (MISO)
output          SD_DAT3;                //  SD Card Data 3          (CSn)
output          SD_CMD;                 //  SD Card Command Signal  (MOSI)
output          SD_CLK;                 //  SD Card Clock           (SCK)

output          UART_TXD;
input           UART_RXD;

output          BEEP;
output          ADCLK;
output          ADCSn;
input           ADDAT;

output DS_EN1, DS_EN3, DS_EN2, DS_EN4;

assign DS_EN1 = 1'b1;
assign DS_EN2 = 1'b1;
assign DS_EN3 = 1'b1;
assign DS_EN4 = 1'b1;


// CLOCK SETUP
wire mreset_n = KEY[0] & ~kbd_key_blkvvod;
wire mreset = !mreset_n;
wire clk24, clkAudio, clkpal4FSC;
wire ce12, ce6, ce6x, ce3, vi53_timer_ce, video_slice, pipe_ab;
wire clk60;
wire clk300;
wire clk_color_mod;

clockster clockmaker(
    .clk(CLK48), 
    .clk24(clk24), 
    .clkAudio(clkAudio), 
    .ce12(ce12), 
    .ce6(ce6),
    .ce6x(ce6x),
    .ce3(ce3), 
    .video_slice(video_slice), 
    .pipe_ab(pipe_ab), 
    .ce1m5(vi53_timer_ce),
    .clkpalFSC(clkpal4FSC),
    .clk60(clk60),
    .clk300(clk300),
    .clk_color_mod(clk_color_mod),
    );
    

wire tape_input;
soundcodec soundnik(
                    .clk24(clk24),
                    .pulses({vv55int_pc_out[0],vi53_out}), 
                    .ay_soundA(ay_soundA),  //
                    .ay_soundB(ay_soundB),  //
                    .ay_soundC(ay_soundC),  //
                    .rs_soundA(rs_soundA),  //
                    .rs_soundB(rs_soundB),  //
                    .rs_soundC(rs_soundC),  //
                    .covox(CovoxData),
                    .tapein(tape_input), 
                    .reset_n(mreset_n),
                    .o_adc_clk(ADCLK),
                    .o_adc_cs_n(ADCSn),
                    .i_adc_data_in(ADDAT),
                    .o_pwm(BEEP)
                   );

reg [15:0] slowclock;
always @(posedge clk24) if (ce3) slowclock <= slowclock + 1'b1;

reg  breakpoint_condition;

reg slowclock_enabled;
reg singleclock_enabled;
reg warpclock_enabled;
reg swkey2=1'b1;

always @(negedge KEY[2]) swkey2<=~swkey2;

always
    {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b000;
    
`ifdef WTFARP
always @(posedge clk24) 
//  case ({SW[9],SW[8]})//svofski
    case ({swkey2,SW[8]})
            // both down = tap on key 1
    2'b00:  {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b100;
            // both up = regular
    2'b11:  {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b000;
            // down/up == warp
    2'b01:  {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b001;
            // up/down = slow
    2'b10:  {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b010;
    default: {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b000;
    endcase
`endif
wire regular_clock_enabled = !slowclock_enabled & !singleclock_enabled & !breakpoint_condition;
wire singleclock;

//singleclockster keytapclock(clk24, singleclock_enabled, KEY[1], singleclock);

reg cpu_ce;
always @* 
    casex ({singleclock_enabled, slowclock_enabled, warpclock_enabled})
    3'b1xx:
        cpu_ce <= singleclock;
    3'bx1x:
        cpu_ce <= (slowclock == 0) & ce3;
    3'bxx1:
        cpu_ce <= ~ce12&~memcpubusy&~memvidbusy&~video_slice_my;
    3'b000:
        cpu_ce <= ce3;
    endcase

reg[1:0] vid_cnt;
reg video_slice_my,video_slice_mymy;
always @(posedge video_slice)   {vid_cnt,video_slice_mymy}<={vid_cnt+2'b1,!vid_cnt[1]&vid_cnt[0]};
always @(posedge clk24) video_slice_my<=video_slice_mymy&video_slice;

reg [15:0] clock_counter;
always @(posedge clk24) begin
    if (~RESET_n) 
        clock_counter <= 0;
    else if (cpu_ce & ~halt_ack) 
        clock_counter <= clock_counter + 1'b1;
end

/////////////////
// WAIT STATES //
/////////////////

// a very special waitstate generator
reg [4:0]   ws_counter = 0;
reg         ws_latch;
always @(posedge clk24) ws_counter <= ws_counter + 1'b1;

wire [3:0] ws_rom = ws_counter[4:1];
wire ws_cpu_time = ws_rom[3:1] == 3'b101;
wire ws_req_n = ~(DO[7] | ~DO[1]) | DO[4] | DO[6];  // == 0 when cpu wants cock

always @(posedge clk24) begin
    if (cpu_ce) begin
        if (SYNC & ~warpclock_enabled) begin
            // if this is not a cpu slice (ws_rom[2]) and cpu wants access, latch the ws flag
            if (~ws_req_n & ~ws_cpu_time) READY <= 0;
`ifdef WITH_BREAKPOINTS         
            if (singleclock) begin
                breakpoint_condition <= 0;
            end
            else if (A == 16'h0100) begin
                breakpoint_condition <= 1;
            end
`else
            breakpoint_condition <= 0;
`endif
        end
    end
    // reset the latch when it's time
    if (ws_cpu_time) begin
        READY <= 1;
    end
end



/////////////////
// DEBUG PINS  //
/////////////////
//assign GPIO_0[8:0] = {clk24, ce12, ce6, ce3, vi53_timer_ce, video_slice, clkpal4FSC, 1'b1, tv_test[0]};
//assign GPIO_0[7:0] = {clk24, ce12, ce6, ce3, vi53_timer_ce, video_slice, clkpal4FSC, clk60};

/////////////////
// CPU SECTION //
/////////////////
wire RESET_n = mreset_n & !blksbr_reset_pulse;
reg READY;
wire HOLD = osd_command_bushold | floppy_death_by_floppy;
wire INT = int_request;
wire INTE;
wire DBIN;
wire SYNC;
wire VAIT;
wire HLDA;
wire WR_n;

wire [15:0] VIDEO_A;
wire [15:0] A;
wire [7:0] DI;
wire [7:0] DO;


reg[7:0] status_word;
reg[9:0] gledreg;

wire [1:0] sw23 = {1'b0, 1'b0};

wire [7:0] kbd_keystatus = {kbd_mod_rus, kbd_key_shift, kbd_key_ctrl, kbd_key_rus, kbd_key_blksbr};

//assign LEDg = sw23 == 0 ? status_word 
//          : sw23 == 1 ? floppy_leds//{floppy_rden,floppy_odata[6:0]}//{kbd_keystatus} 
//          : sw23 == 2 ? floppy_status 
//          : {vi53_timer_ce, INT, interrupt_ack, 1'b0};

//assign LEDg = {clk24, clkpal4FSC, clk60, CLK48};
            
//SEG7_LUT_4 seg7display(HEX0, HEX1, HEX2, HEX3, /*SW[4] ? clock_counter :*/ A);


wire ram_read;
wire ram_write_n;
wire io_write;
wire io_stack;
wire io_read;
wire interrupt_ack;
wire halt_ack;
wire WRN_CPUCE = WR_n | ~cpu_ce;

`ifdef WITH_CPU
    T8080se CPU(RESET_n, clk24, cpu_ce, READY, HOLD, INT, INTE, DBIN, SYNC, VAIT, HLDA, WR_n, A, DI, DO);
wire inta_n;
    
    assign ram_read = status_word[7];
    assign ram_write_n = status_word[1];
    assign io_write = status_word[4];
    assign io_stack = status_word[2];
    assign io_read  = status_word[6];
    assign halt_ack = status_word[3];
    assign interrupt_ack = status_word[0];
`else
    assign WR_n = 1;
    assign DO = 8'h00;
    assign A = 16'hffff;
    assign ram_read = 0;
    assign ram_write_n = 1;
    assign io_write = 0;
    assign io_stack = 0;
    assign io_read  = 0;
    assign interrupt_ack = 1;
`endif

always @(posedge clk24) begin
    if (cpu_ce) begin
        if (WR_n == 0) gledreg[7:0] <= DO;
        if (SYNC) begin
            status_word <= DO;
        end 
        
        address_bus_r <= address_bus[7:0];
    end
end



//////////////
// MEMORIES //
//////////////

wire[7:0] ROM_DO;
bootrom bootrom(.address(A[10:0]),.clock(clk24),.q(ROM_DO));

reg [7:0] address_bus_r;    // registered address for i/o

reg rom_access;
always @(posedge clk24) begin
    if (disable_rom)
        rom_access <= 1'b0;
    else
        rom_access <= A < 2048;
end

assign DI=DI_;
reg[7:0] DI_;
always @*
 casex ({interrupt_ack,io_read,rom_access})
  3'b1xx:DI_<=8'hFF;
  3'b01x:DI_<=peripheral_data_in;
  3'b001:DI_<=ROM_DO;
  3'b000:DI_<=sram_data_in;
 endcase

wire [2:0]  ramdisk_page;
    
wire [15:0] address_bus = A;

reg[31:0] rdvidreg;
always @(posedge clk24) rdvidreg={rdvidreg[30:0],rdvid};

`ifdef WITH_SDRAM

assign DRAM_CLK=clk60;              //  SDRAM Clock
assign DRAM_CKE=1;                  //  SDRAM Clock Enable
wire[15:0] dramout,dramout2;
wire memcpubusy,memvidbusy,rdcpu_finished;
SDRAM_Controller ramd(
    .clk(clk60),                    //  Clock 60 MHz
    .reset(~RESET_n),               //  System reset
    .DRAM_DQ(DRAM_DQ),              //  SDRAM Data bus 16 Bits
    .DRAM_ADDR(DRAM_ADDR),          //  SDRAM Address bus 12 Bits
    .DRAM_LDQM(DRAM_LDQM),          //  SDRAM Low-byte Data Mask 
    .DRAM_UDQM(DRAM_UDQM),          //  SDRAM High-byte Data Mask
    .DRAM_WE_N(DRAM_WE_N),          //  SDRAM Write Enable
    .DRAM_CAS_N(DRAM_CAS_N),        //  SDRAM Column Address Strobe
    .DRAM_RAS_N(DRAM_RAS_N),        //  SDRAM Row Address Strobe
    .DRAM_CS_N(DRAM_CS_N),          //  SDRAM Chip Select
    .DRAM_BA_0(DRAM_BA_0),          //  SDRAM Bank Address 0
    .DRAM_BA_1(DRAM_BA_1),          //  SDRAM Bank Address 1
    .iaddr((rdvidreg[9])?{4'b0001,VIDEO_A[12:0],2'b00}:{ramdisk_page,A[15],A[12:0],A[14:13]}),
    .idata(DO),
    .rd(ram_read&DBIN&~rom_access),
    .we_n(ram_write_n|io_write|WR_n), 
    .odata(dramout),
    .odata2(dramout2),
    .memcpubusy(memcpubusy),
    .rdcpu_finished(rdcpu_finished),
    .memvidbusy(memvidbusy),
    .rdv(rdvidreg[9])
);
reg[7:0] sram_data_in;
always @(negedge rdcpu_finished) sram_data_in=dramout[7:0];

reg[31:0] vdata,vdata2,vdata3,vdata4;
always @(negedge memvidbusy)vdata<={dramout2,dramout};

`else
reg[31:0] vdata,vdata2,vdata3,vdata4;
wire memcpubusy = 0, memvidbusy = 0, rdcpu_finished = 1;
reg[7:0] sram_data_in;
`endif


wire [7:0]  kvaz_debug;
wire        ramdisk_control_write = address_bus_r == 8'h10 && io_write & ~WR_n;
kvaz ramdisk(
    .clk(clk24), 
    .clke(cpu_ce), 
    .reset(mreset),
    .address(address_bus),
    .select(ramdisk_control_write),
    .data_in(DO),
    .stack(io_stack), 
    .memwr(~ram_write_n), 
    .memrd(ram_read), 
    .bigram_addr(ramdisk_page),
    .debug(kvaz_debug)
);


///////////
// VIDEO //
///////////
wire [7:0]  video_scroll_reg = vv55int_pa_out;
reg [7:0]   video_palette_value;
reg [3:0]   video_border_index;
reg         video_palette_wren;
reg         video_mode512;

wire [3:0] coloridx;
wire retrace;           // 1 == retrace in progress

wire vga_vs;
wire vga_hs;


`ifdef WITH_TV
wire [1:0]      tv_mode = {KEY[3], 1'b1};
`else
wire [1:0]      tv_mode = {2'b00};
`endif

wire        tv_sync;
wire [4:0]  tv_luma;
wire [4:0]  tv_chroma;
wire [3:0]  tv_cvbs;
wire [7:0]  tv_test;

wire[3:0] border_idx_delayed;
border_delay#14(.clk(clk24), .ce(ce6), .i_borderindex(video_border_index), .o_delayed(border_idx_delayed));

video vidi(.clk24(clk24), .ce12(ce12), .ce6(ce6), .ce6x(ce6x), .clk4fsc(clkpal4FSC), .video_slice(video_slice), .pipe_ab(pipe_ab),
           .mode512(video_mode512), 
           .vdata(vdata),
           .vdata2(vdata2),
           .vdata3(vdata3),
           .vdata4(vdata4),
            .SRAM_ADDR(VIDEO_A), 

           .hsync(vga_hs), .vsync(vga_vs), 
           .osd_hsync(osd_hsync), .osd_vsync(osd_vsync),
           .coloridx(coloridx),
           .realcolor_in(realcolor2buf),
           .realcolor_out(realcolor),
           .retrace(retrace),
           .video_scroll_reg(video_scroll_reg),
           .border_idx(border_idx_delayed),
           //.testpin(GPIO_0[12:9]),
           .tv_sync(tv_sync),
           .tv_luma(tv_luma),
           .tv_chroma_o(tv_chroma),
           .tv_cvbs(tv_cvbs),
           .tv_test(tv_test),
           .tv_mode(tv_mode),
           .tv_osd_fg(osd_fg),
           .tv_osd_bg(osd_bg),
           .tv_osd_on(osd_active),
           .rdvid(rdvid)
            );
wire rdvid;
            
wire [7:0] realcolor;       // this truecolour value fetched from buffer directly to display
wire [7:0] realcolor2buf;   // this truecolour value goes into the scan doubler buffer

wire [3:0] paletteram_adr = (retrace/*|video_palette_wren*/) ? video_border_index : coloridx;

palette_ram paletteram(.address(paletteram_adr), 
                       .data(video_palette_value), 
                       .inclock(clk24), .outclock(clk24), 
                       .wren(video_palette_wren_delayed), 
                       .q(realcolor2buf));

reg [3:0] video_r;
reg [3:0] video_g;
reg [3:0] video_b;

wire [3:0] tv_out;

`ifdef WITH_COMPOSITE
    `ifdef COMPOSITE_PWM
        reg [4:0] cvbs_pwm;
        always @(posedge clk_color_mod)
            cvbs_pwm <= cvbs_pwm[3:0] + tv_cvbs[3:0];
        assign tv_out = {4{cvbs_pwm[4]}};
    `else
        assign tv_out = tv_luma[3:0];
    `endif
`else
    assign tv_out = 4'b0;
`endif

`ifdef WITH_SVIDEO
    reg [5:0] luma_pwm;
    reg [5:0] chroma_pwm;
    always @(posedge clk_color_mod) begin
        luma_pwm <= luma_pwm[4:0] + tv_luma[4:0];
        chroma_pwm <= chroma_pwm[4:0] + tv_chroma[4:0];
    end
    assign VGA_G[0] = luma_pwm[5];
    assign VGA_G[1] = chroma_pwm[5];
`endif

`ifdef WITH_COMPOSITE 
    assign VGA_R[4:1] = tv_out;
    assign VGA_G[5:2] = tv_out;
    assign VGA_B[4:1] = tv_out; 
`else
`ifdef WITH_VGA
    assign VGA_R[4:1] = video_r;
    assign VGA_G[5:2] = video_g;
    assign VGA_B[4:1] = video_b; 
`else
    assign VGA_R[4:1] = 4'b0;
    assign VGA_G[5:2] = 4'b0;
    assign VGA_B[4:1] = 4'b0; 
`endif    
`endif

assign VGA_VS= vga_vs;
assign VGA_HS= vga_hs;

wire [1:0]  lowcolor_b = {2{osd_active}} & {realcolor[7],1'b0};
wire        lowcolor_g = osd_active & realcolor[5];
wire        lowcolor_r = osd_active & realcolor[2];

wire [7:0]  overlayed_colour = osd_active ? osd_colour : realcolor;

always @(posedge clk24) begin
    video_r <= {overlayed_colour[2:0], lowcolor_r};
    video_g <= {overlayed_colour[5:3], lowcolor_g};
    video_b <= {overlayed_colour[7:6], lowcolor_b};
end


///////////
// RST38 //
///////////

// Retrace irq delay:
wire int_delay;
reg int_request;
wire int_rq_tick;
reg  int_rq_hist;

oneshot #(10'd28) retrace_delay(clk24, cpu_ce, retrace, int_delay);
oneshot #(10'd191) retrace_irq(clk24, cpu_ce, ~int_delay, int_rq_tick);

//assign int_rq_tick_inte = ~interrupt_ack & INTE & int_rq_tick;

always @(posedge clk24) begin
    int_rq_hist <= int_rq_tick;
    
    if (~int_rq_hist & int_rq_tick & INTE) 
        int_request <= 1;
    
    if (interrupt_ack)
        int_request <= 0;
end

///////////////////
// PS/2 KEYBOARD //
///////////////////
reg         kbd_mod_rus;
wire [7:0]  kbd_rowselect = ~vv55int_pa_out;
wire [7:0]  kbd_rowbits;
wire        kbd_key_shift;
wire        kbd_key_ctrl;
wire        kbd_key_rus;
wire        kbd_key_blksbr;
wire        kbd_key_blkvvod = kbd_key_blkvvod_phy | osd_command_f11;
wire        kbd_key_blkvvod_phy;
wire        kbd_key_scrolllock;
wire [5:0]  kbd_keys_osd;

`ifdef WITH_KEYBOARD
    vectorkeys kbdmatrix(
        .clkk(clk24), 
        .reset(~KEY[0]), 
        .ps2_clk(PS2_CLK), 
        .ps2_dat(PS2_DAT), 
        .mod_rus(kbd_mod_rus), 
        .rowselect(kbd_rowselect), 
        .rowbits(kbd_rowbits), 
        .key_shift(kbd_key_shift), 
        .key_ctrl(kbd_key_ctrl), 
        .key_rus(kbd_key_rus), 
        .key_blksbr(kbd_key_blksbr), 
        .key_blkvvod(kbd_key_blkvvod_phy),
        .key_bushold(kbd_key_scrolllock),
        .key_osd(kbd_keys_osd),
        .osd_active(scrollock_osd)
        );
`else
    assign kbd_rowbits = 8'hff;
    assign kbd_key_shift = 0;
    assign kbd_key_ctrl = 0;
    assign kbd_key_rus = 0;
    assign kbd_key_blksbr = 0;
    assign kbd_key_blkvvod_phy = 0;
    assign kbd_key_scrolllock = 0;
`endif



///////////////
// I/O PORTS //
///////////////

reg [7:0] peripheral_data_in;

// Priority encoder is a poor choice for bus selector, see case below, works much better
//
//always peripheral_data_in = ~vv55int_oe_n ? vv55int_odata :
//                          vi53_rden ? vi53_odata : 
//                          floppy_rden ? floppy_odata : 
//                          ~vv55pu_oe_n ? vv55pu_odata : 8'hFF;
always
    case ({ay_rden, ~vv55int_oe_n, vi53_rden, floppy_rden, vv55pu_rden}) 
        5'b10000: peripheral_data_in <= ay_odata;
        5'b01000: peripheral_data_in <= vv55int_odata;
        5'b00100: peripheral_data_in <= vi53_odata;
        5'b00010: peripheral_data_in <= floppy_odata;
        5'b00001: peripheral_data_in <= vv55pu_odata;
        default: peripheral_data_in <= 8'hFF;
    endcase

// Devices:
//   000xxxYY [a7:a0]
//      000: internal VV55
//      001: external VV55 (PU)
//      010: VI53 interval timer
//      011: internal:  00: palette data out
//                      01-11: joystick inputs
//      100: ramdisk bank switching
//      101: AY-3-8910, ports 14, 15 (00, 01)
//      110: FDC ($18-$1B)
//      111: FDC ($1C, secondary control reg)

reg [5:0] portmap_device;               
always portmap_device = address_bus_r[7:2];



///////////////////////
// vv55 #1, internal //
///////////////////////

wire        vv55int_sel = portmap_device == 3'b000;

wire [1:0]  vv55int_addr =  ~address_bus_r[1:0];
wire [7:0]  vv55int_idata = DO; 
wire [7:0]  vv55int_odata;
wire        vv55int_oe_n;

wire vv55int_cs_n = !(/*~ram_write_n &*/ (io_read | io_write) & vv55int_sel);
wire vv55int_rd_n = ~io_read;//~DBIN;
wire vv55int_wr_n = WR_n | ~cpu_ce;

reg [7:0]   vv55int_pa_in;
reg [7:0]   vv55int_pb_in;
reg [7:0]   vv55int_pc_in;

wire [7:0]  vv55int_pa_out;
wire [7:0]  vv55int_pb_out;
wire [7:0]  vv55int_pc_out;

wire vv55int_pa_oe_n;
wire vv55int_pb_oe_n;
wire vv55int_pc_oe_n;

I82C55 vv55int(
    vv55int_addr,
    vv55int_idata,
    vv55int_odata,
    vv55int_oe_n,
    
    vv55int_cs_n,
    vv55int_rd_n,
    vv55int_wr_n,
    
    vv55int_pa_in,
    vv55int_pa_out,
    vv55int_pa_oe_n,                // enable always
    
    vv55int_pb_in,                  // see keyboard
    vv55int_pb_out,
    vv55int_pb_oe_n,                // enable always
    
    vv55int_pc_in,
    vv55int_pc_out,
    vv55int_pc_oe_n,                // enable always
    
    mreset,     // active 1
    
    cpu_ce,
    clk24);

always @(posedge clk24) begin
    // port B
    video_border_index <= vv55int_pb_out[3:0];  // == palette address for out $0C

`ifdef WITH_CPU
    video_mode512 <= vv55int_pb_out[4];
`else
    video_mode512 <= 1'b0;
`endif
    // port C
    gledreg[9] <= vv55int_pc_out[3];        // RUS/LAT LED
end 

always @(kbd_rowbits) vv55int_pb_in <= ~kbd_rowbits;
always @(kbd_key_shift or kbd_key_ctrl or kbd_key_rus) begin
    vv55int_pc_in[5] <= ~kbd_key_shift;
    vv55int_pc_in[6] <= ~kbd_key_ctrl;
    vv55int_pc_in[7] <= ~kbd_key_rus;
end
always @(tape_input) vv55int_pc_in[4] <= tape_input;
always @* vv55int_pc_in[3:0] <= 4'b1111;


///////////////////////
// vv55 #2, PU       //
///////////////////////

wire        vv55pu_sel = portmap_device == 3'b001;

wire [1:0]  vv55pu_addr =   ~address_bus_r[1:0];
wire [7:0]  vv55pu_idata = DO;  
wire [7:0]  vv55pu_odata;
wire        vv55pu_oe_n;

wire vv55pu_cs_n = !(/*~ram_write_n &*/ (io_read | io_write) & vv55pu_sel);
wire vv55pu_rd_n = ~io_read;//~DBIN;
wire vv55pu_wr_n = WR_n | ~cpu_ce;
wire vv55pu_rden = io_read & vv55pu_sel;

reg [7:0]   vv55pu_pa_in;
reg [7:0]   vv55pu_pb_in;
reg [7:0]   vv55pu_pc_in;

wire [7:0]  vv55pu_pa_out;
wire [7:0]  vv55pu_pb_out;
wire [7:0]  vv55pu_pc_out;

wire vv55pu_pa_oe_n;
wire vv55pu_pb_oe_n;
wire vv55pu_pc_oe_n;

I82C55 vv55pu(
    vv55pu_addr,
    vv55pu_idata,
    vv55pu_odata,
    vv55pu_oe_n,

    vv55pu_cs_n,
    vv55pu_rd_n,
    vv55pu_wr_n,

    vv55pu_pa_in,
    vv55pu_pa_out,
    vv55pu_pa_oe_n,

    vv55pu_pb_in,
    vv55pu_pb_out,
    vv55pu_pb_oe_n,

    vv55pu_pc_in,
    vv55pu_pc_out,
    vv55pu_pc_oe_n,

    mreset,     // active 1

    cpu_ce,
    clk24);

reg[7:0]    CovoxData;
reg[7:0]    RSdataIn,RSctrl;
wire[7:0]   RSdataOut;
always @(posedge clk24) begin
    CovoxData <= vv55pu_pa_out;
    RSdataIn <= vv55pu_pb_out;
    RSctrl <= vv55pu_pc_out;
    vv55pu_pb_in <= RSdataOut;
end


////////////////////////////////
// 580VI53 timer: ports 08-0B //
////////////////////////////////
wire            vi53_sel = portmap_device == 3'b010;
wire            vi53_wren = ~WR_n & io_write & vi53_sel; 
wire            vi53_rden = io_read & vi53_sel;
wire    [2:0]   vi53_out;
wire    [7:0]   vi53_odata;
wire    [9:0]   vi53_testpin;

`ifdef WITH_VI53
pit8253 vi53(
            clk24, 
            cpu_ce, 
            vi53_timer_ce, 
            ~address_bus_r[1:0], 
            vi53_wren, 
            vi53_rden, 
            DO, 
            vi53_odata, 
            3'b111, 
            vi53_out, 
            vi53_testpin);
`endif


////////////////////////////
// Internal ports, $0C -- //
////////////////////////////
wire        iports_sel      = portmap_device == 3'b011;
wire        iports_write    = /*~ram_write_n &*/ io_write & iports_sel; // this repeats as a series of 3 _|||_ wtf

// port $0C-$0F: palette value out
wire iports_palette_sel = address_bus[1:0] == 2'b00;        // not used <- must be fixed some day


// simulate real Vector-06c K155RU2 (SN7489N)
// K155RU2 is asynchronous and remembers input value 
// for every address set while WR is active (0).
// Allegedly, real Vector-06c holds WR cycle for 
// approximately 3 pixel clocks
reg [3:0] palette_wr_sim;

always @(posedge clk24) begin
    if (iports_write & ~WR_n & cpu_ce) begin
        video_palette_value <= DO;
        palette_wr_sim <= 3;
    end 
    if (ce6 && |palette_wr_sim) palette_wr_sim <= palette_wr_sim - 1'b1;
end

always @*
    video_palette_wren <= |palette_wr_sim;

// delay palette_wren to match the real hw timings
reg [7:0] video_palette_wren_buf;
wire      video_palette_wren_delayed = video_palette_wren_buf[7];
always @(posedge clk24) begin
    if (ce12) video_palette_wren_buf <= {video_palette_wren_buf[6:0],video_palette_wren};
end



//////////////////////////////////
// Floppy Disk Controller ports //
//////////////////////////////////

wire [7:0]  osd_command;

wire        osd_command_bushold = osd_command[0];
wire        osd_command_f12     = osd_command[1];
wire        osd_command_f11     = osd_command[2];

wire [7:0]  floppy_leds;

wire        floppy_sel = portmap_device[2:1] == 2'b11; // both 110 and 111
wire        floppy_wren = ~WR_n & io_write & floppy_sel;
wire        floppy_rden  = io_read & floppy_sel;

wire        floppy_death_by_floppy;


`ifdef WITH_FLOPPY
wire [7:0]  floppy_odata;
wire [7:0]  floppy_status;

floppy flappy(
    .clk(clk24), 
    .ce(cpu_ce),  
    .reset_n(KEY[0]),       // to make it possible to change a floppy image, then press F11
    
    // sd card signals
    .sd_dat(SD_DAT), 
    .sd_dat3(SD_DAT3), 
    .sd_cmd(SD_CMD), 
    .sd_clk(SD_CLK), 
    
    // uart comms
    .uart_txd(UART_TXD),
    
    // io ports
    .hostio_addr({address_bus_r[2],~address_bus_r[1:0]}),
    .hostio_idata(DO),
    .hostio_odata(floppy_odata),
    .hostio_rd(floppy_rden),
    .hostio_wr(floppy_wren),
    
    // screen memory
    .display_addr(osd_address),
    .display_data(osd_data),
    .display_wren(osd_wren),
    .display_idata(osd_q),
    
    .keyboard_keys(kbd_keys_osd),
    
    .osd_command(osd_command),
    
    // debug 
    .green_leds(floppy_leds),
    //.red_leds(floppy_leds),
    .debug(floppy_status),
    .host_hold(floppy_death_by_floppy),
    );
    //green_leds, red_leds, debug, debugidata);

`else 
assign floppy_death_by_floppy = 0;
wire [7:0]  floppy_odata = 
`ifdef FLOPPYLESS_HAX
    8'h00;
`else
    8'hFF;
`endif  
wire [7:0]  floppy_status = 8'hff;
`endif



///////////////////////
// On-Screen Display //
///////////////////////
wire            osd_hsync, osd_vsync;   // provided by video.v
reg             osd_active;
reg [7:0]       osd_colour;
always @(posedge clk24)
    if (scrollock_osd & osd_bg) begin
        osd_active <= 1;
        osd_colour <= osd_fg ? 8'b11111110 : 8'b01011001;   // slightly greenish tint hopefully
    end else 
        osd_active <= 0;

wire            osd_fg;
wire            osd_bg;
wire            osd_wren;
wire[7:0]       osd_data;
wire[7:0]       osd_rq;
wire[7:0]       osd_address;

wire[7:0]       osd_q = osd_rq + 8'd32;

`ifdef WITH_OSD
textmode osd(
    .clk(clk24),
    .ce(tv_mode[0] ? ce12 : 1'b1),
    .vsync(osd_vsync),
    .hsync(osd_hsync),
    .pixel(osd_fg),
    .background(osd_bg),
    .address(osd_address),
    .data(osd_data - 8'd32),        // OSD encoding has 00 == 32
    .wren(osd_wren),
    .q(osd_rq)
    );
`else
assign osd_fg = 0;
assign osd_bg = 0;
assign osd_rq  = 0;
`endif



////////
// AY //
////////
wire [7:0]  ay_odata;

wire [7:0]  ay_soundA,ay_soundB,ay_soundC;
wire [7:0]  rs_soundA,rs_soundB,rs_soundC;

`ifdef WITH_AY
wire        ay_sel = portmap_device == 3'b101 && address_bus_r[1] == 0; // only ports $14 and $15
wire        ay_wren = ~WR_n & io_write & ay_sel;
wire        ay_rden = io_read & ay_sel;

reg [3:0] aycectr;
always @(posedge clk24) if (aycectr<14) aycectr <= aycectr + 1'd1; else aycectr <= 0;

ayglue shrieker(
                .clk(clk24),
                .ce(aycectr == 0),
                .reset_n(mreset_n), 
                .address(address_bus_r[0]),
                .data(DO), 
                .q(ay_odata),
                .wren(ay_wren),
                .rden(ay_rden),
                .soundA(ay_soundA),
                .soundB(ay_soundB),
                .soundC(ay_soundC),
                );              
`else
assign ay_soundA=8'b0;
assign ay_soundB=8'b0;
assign ay_soundC=8'b0;
assign ay_rden = 1'b0;
assign ay_odata = 8'hFF;
`endif

`ifdef WITH_RSOUND

ym2149 rsound(
    .DI(RSdataIn),
    .DO(RSdataOut),
    .BDIR(RSctrl[2]), 
    .BC(RSctrl[1]),
    .OUT_A(rs_soundA),
    .OUT_B(rs_soundB),
    .OUT_C(rs_soundC),
    .CS(1'b1),
    .ENA(aycectr == 0),
    .RESET(RSctrl[3]|~mreset_n),
    .CLK(clk24)
    );                
`else
assign rs_soundA=8'b0;
assign rs_soundB=8'b0;
assign rs_soundC=8'b0;
`endif

//////////////////
// Special keys //
//////////////////

wire    scrollock_osd;
wire    blksbr_reset_pulse;
wire    disable_rom;

specialkeys skeys(
                .clk(clk24), 
                .cpu_ce(cpu_ce),
                .reset_n(mreset_n), 
                .key_blksbr(KEY[3] == 1'b0 || kbd_key_blksbr == 1'b1 || osd_command_f12), 
                .key_osd(kbd_key_scrolllock),
                .o_disable_rom(disable_rom),
                .o_blksbr_reset(blksbr_reset_pulse),
                .o_osd(scrollock_osd)
                );
                
always gledreg[8] <= disable_rom;               

`ifdef WITH_I2C
I2C_AV_Config       u7(clk24,mreset_n,I2C_SCLK,I2C_SDAT);
`endif


endmodule
