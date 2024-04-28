// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
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


//`default_nettype none

// Undefine following for smaller/faster builds
`define WITH_CPU            
//`define WITH_KEYBOARD
//`define WITH_VI53
//`define WITH_AY
//`define WITH_RSOUND
//`define WITH_FLOPPY
//`define WITH_OSD
//`define WITH_SDRAM
`define WITH_PSRAM      // Tang Nano 9K GW1N-NR9 Q88P
`define FLOPPYLESS_HAX  // set FDC odata to $00 when compiling without floppy
//`define WITH_TV         // WXEDA board has too few resources to switch modes in runtime
//`define WITH_COMPOSITE  // output composite video on VGA pins
//`define COMPOSITE_PWM   // use sigma-delta modulator on composite video out
//`define WITH_SVIDEO 
`define WITH_VGA
`define WITH_SERIAL_PROBE

module vector06cc(
    input wire XTAL_27MHZ,
    input wire SYS_RESETN,
    input wire BUTTON,


    output	wire		LCD_CLK,
    output	wire		LCD_HSYNC,
    output	wire		LCD_VSYNC,
    output	wire 		LCD_DEN,
    output	wire [4:0]	LCD_R,
    output	wire [5:0]	LCD_G,
    output	wire [4:0]	LCD_B,


    //////////////////    SD Card Interface   ////////////////////////
//    input           SD_DAT,                 //  SD Card Data            (MISO)
//    output          SD_DAT3,                //  SD Card Data 3          (CSn)
//    output          SD_CMD,                 //  SD Card Command Signal  (MOSI)
//    output          SD_CLK,                 //  SD Card Clock           (SCK)

    output              UART_TX,
    input               UART_RX,

    output reg [5:0] LED,

    // PSRAM interface magic ports
    output wire [1:0] O_psram_ck,       // Magic ports for PSRAM to be inferred
    output wire [1:0] O_psram_ck_n,
    inout  wire [1:0] IO_psram_rwds,
    inout  wire [15:0] IO_psram_dq,
    output wire [1:0] O_psram_reset_n,
    output wire [1:0] O_psram_cs_n
);


// temporary stubs for nonexistent outputs
wire BEEP; 

wire  delayed_reset_n;

// CLOCK SETUP
wire mreset_n = delayed_reset_n & ~kbd_key_blkvvod;
wire mreset = !mreset_n;
wire clk24, clkAudio, clk48, clk48p;
wire ce12, ce6, ce6x, ce3, vi53_timer_ce, video_slice, pipe_ab;
wire clkpal4FSC = 0;    // no PAL modulator
wire clk_color_mod = 0; // no PAL color 

wire clk_psram, clk_psram_p;

clockster clockmaker(
    .clk27(XTAL_27MHZ),     // input xtal, 27 mhz on fhtagn nano 9k
    .clk48(clk48),          // PSRAM clock
    .clk48p(clk48p),        // PSRAM clock 90 deg
    .clk24(clk24),          // master clock
    .clk_psram(clk_psram),
    .clk_psram_p(clk_psram_p),
    .clkAudio(clkAudio),
    .ce12(ce12), 
    .ce6(ce6),              // tv pixel clock
    .ce6x(ce6x),
    .ce3(ce3),              // cpu 
    .video_slice(video_slice), 
    .pipe_ab(pipe_ab), 
    .ce1m5(vi53_timer_ce)
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
                    .o_pwm(BEEP)
                   );

reg [15:0] slowclock;
always @(posedge clk24) if (ce3) slowclock <= slowclock + 1'b1;

reg  breakpoint_condition;

reg slowclock_enabled;
reg singleclock_enabled;
reg warpclock_enabled;

always @*
    {singleclock_enabled, slowclock_enabled, warpclock_enabled} = 3'b000;
    
wire singleclock;

reg cpu_ce;
always @* 
    casex ({singleclock_enabled, slowclock_enabled, warpclock_enabled, breakpoint_condition})
    4'bxxx1:
        cpu_ce <= 1'b0;
    4'b1xx0:
        cpu_ce <= singleclock;
    4'bx1x0:
        cpu_ce <= (slowclock == 0) & ce3;
    4'bxx10:
        cpu_ce <= ~ce12&~memcpubusy&~memvidbusy&~video_slice_my;
    4'b0000:
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
    if (~RESET_n)
        breakpoint_condition <= 1'b0;
    else
    begin
        breakpoint_condition <= halt_halt;
        if (cpu_ce) begin
            if (SYNC & ~warpclock_enabled) begin
                // if this is not a cpu slice (ws_rom[2]) and cpu wants access, latch the ws flag
                //if (~ws_req_n & ~ws_cpu_time) READY <= 0;
                READY <= 0; //### the above looks overcomplicated
`ifdef WITH_BREAKPOINTS         
                if (singleclock) begin
                    breakpoint_condition <= halt_halt;
                end
                else if (A == 16'h0100) begin
                    breakpoint_condition <= 1'b1;
                end
`else
                breakpoint_condition <= halt_halt;
`endif
            end
        end
        // reset the latch when it's time
        if (ws_cpu_time) begin
            READY <= 1;
        end
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
wire ram_read_pre;
wire ram_write_n;
wire io_write;
wire io_stack;
wire io_stack_pre;
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

    // early signals
    assign ram_read_pre = SYNC & DO[7] & ~rom_access;
    assign io_stack_pre = SYNC & DO[2];

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

wire cpu_m1 = SYNC & DO[5];
always @(posedge clk24) begin
    //if (cpu_ce) begin
    //    if (WR_n == 0) gledreg[7:0] <= DO;
    //    if (SYNC) begin
    //        status_word <= DO;
    //    end 
    //    
    //    address_bus_r <= address_bus[7:0];
    //end
    if (cpu_ce) begin
        if (WR_n == 0) gledreg[7:0] <= DO;
        if (SYNC) begin
            status_word <= DO;
        end 
    end
        
    if (SYNC)
        address_bus_r <= address_bus[7:0];
end

//always @(posedge clk24)
//    if (cpu_ce)
//        LED[5:0] <= status_word[5:0];


//////////////
// MEMORIES //
//////////////

wire[7:0] ROM_DO;
//bootrom bootrom(.address(A[10:0]),.clock(clk24),.q(ROM_DO));

bootrom bootrom(
    .ad(A[10:0]),   //input [10:0] ad
    .dout(ROM_DO),  //output [7:0] dout
    .clk(clk24),    //input clk
    .oce(1'b1),     //input oce
    .ce(1'b1),      //input ce
    .reset(1'b0)    //input reset
);


reg [7:0] address_bus_r;    // registered address for i/o

reg rom_access;
always @(posedge clk24) begin
    if (disable_rom)
        rom_access <= 1'b0;
    else
        rom_access <= A < 2048;
end

//
// painful debug stuff
//--------------fml--------------
//

reg [7:0] prev_opcode, opcode;
reg [9:0] opcode_addr, prev_opcode_addr;
reg breakfuck;
reg ded_3ded;

always @(posedge clk24)
begin
    if (~SYS_RESETN)
        ded_3ded <= 1'b0;

    breakfuck <= 0;


    if (cpu_m1 && cpu_ce)
    begin
        prev_opcode <= opcode;
        prev_opcode_addr <= opcode_addr;

        opcode <= DI;
        opcode_addr <= A;

        if (A == 16'h3ded)
            ded_3ded <= 1'b1;
    end
    if (prev_opcode == 8'hc2 && prev_opcode_addr == 10'h03ec && opcode != 8'h77)
        breakfuck <= 1;

end

//
//--------------fml--------------
//

assign DI=DI_;
reg[7:0] DI_;
always @*
 casex ({interrupt_ack,io_read,rom_access})
  3'b1xx:DI_<=8'hFF;
  3'b01x:DI_<=peripheral_data_in;
  3'b001:DI_<=ROM_DO;
  3'b000:DI_<=sram_data_in;
 endcase

 //---kvazwashere---
wire [15:0] address_bus = A;


`ifdef WITH_SDRAM
reg[31:0] rdvidreg;
always @(posedge clk24) rdvidreg={rdvidreg[30:0],rdvid};

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
    .iaddr((rdvidreg[9])?{4'b0001,VIDEO_A[12:0],2'b00}:{ramdisk_addr,A[15],A[12:0],A[14:13]}),
    .idata(DO),
    .rd(ram_read&DBIN&~rom_access),
    .we_n(ram_write_n|io_write|WR_n), 
    .odata(dramout),                // [15:0] odata
    .odata2(dramout2),              // [15:0] odata2
    .memcpubusy(memcpubusy),
    .rdcpu_finished(rdcpu_finished),
    .memvidbusy(memvidbusy),
    .rdv(rdvidreg[9])
);
reg[7:0] sram_data_in;
always @(negedge rdcpu_finished) sram_data_in=dramout[7:0];

reg[31:0] vdata;
always @(negedge memvidbusy) vdata<={dramout2,dramout};

`elsif WITH_PSRAM

assign O_psram_reset_n = SYS_RESETN;

wire[15:0] dramout,dramout2;
wire psram_busy;
wire memcpubusy, memvidbusy, rdcpu_finished;

//wire psram_rd_cpu = ram_read_pre; //ram_read & DBIN & ~rom_access;
reg psram_rd_cpu;
always @(posedge clk24)
    psram_rd_cpu <= ram_read_pre;

wire psram_wr_cpu_pre = SYNC & ~(DO[1] | DO[4]); // unregistered raw_write_n and iowr
reg psram_wr_cpu;

always @(posedge clk24)
    if (ce3) psram_wr_cpu <= psram_wr_cpu_pre;

reg[63:0] rdvidreg;
always @(posedge clk_psram) rdvidreg={rdvidreg[62:0],rdvid};

wire psram_rd_vid = rdvidreg[30]; 


// ---------- haltmode write access ----------------

reg psram_busy_r; // psram_busy registered
reg halt_wr_r;    // haltmode write request registered
reg halt_wr_cmd;  // psram command to write haltmode data

always @(posedge clk24)
begin
    if (!SYS_RESETN)
        {psram_busy_r, halt_wr_r, halt_wr_cmd} <= 3'b000;
    psram_busy_r <= psram_busy;

    halt_wr_cmd <= 1'b0;

    if (halt_wr)
        halt_wr_r <= 1'b1;

    if (halt_wr_r & psram_busy_r & ~psram_busy) // falling psram_busy
        {halt_wr_cmd, halt_wr_r} <= 2'b10;  // write cmd, clear reg
end

// -----------------------------------------------------


wire [21:0] halt_a_mangled = 
    {halt_addr[21:16], halt_addr[15],halt_addr[12:0],halt_addr[14:13]};

wire [21:0] cpu_a_mangled = {ramdisk_addr,A[15],A[12:0],A[14:13]};

// this is wrong because rdvid address can be used with halt_wr
wire [21:0] psram_addr = 
    halt_halt ? halt_a_mangled :
    psram_rd_vid ? {4'b0001,VIDEO_A[12:0],2'b00} : cpu_a_mangled;

reg psram_rd_cpu_d, psram_wr_cpu_d;
always @(posedge clk_psram) begin
    psram_wr_cpu_d <= psram_wr_cpu;   // sample wr edge
    psram_rd_cpu_d <= psram_rd_cpu;   // sample rd edge
end

wire psram_rd_cpu_posedge = psram_rd_cpu & ~psram_rd_cpu_d;

wire psram_rd_cmd = psram_rd_cpu_posedge;// | psram_rd_vid; 
wire psram_wr_cmd = (psram_wr_cpu & ~psram_wr_cpu_d) | halt_wr_cmd;

wire [7:0] psram_di = halt_wr_cmd ? halt_do : DO;

// this is almost an exact copy of CPU/STACK: 
// from the start of SYNC+STACK until SYNC without STACK
reg io_stack_long;
always @(posedge clk_psram)
begin
    if (io_stack_pre) io_stack_long <= 1'b1;
    if (SYNC & ~io_stack_pre) io_stack_long <= 1'b0;
end


localparam PSRAM_FREQ = 72_000_000;
localparam PSRAM_LATENCY = 3;
PsramController #(
    .FREQ(PSRAM_FREQ),
    .LATENCY(PSRAM_LATENCY)
) mem_ctrl(
    .clk(clk_psram),
    .clk_p(clk_psram_p), 
    .resetn(SYS_RESETN), 
    .resetn_o(delayed_reset_n),     // psram controller dictates system reset
    .read(psram_rd_cmd),    // sampled edge (from cpu)
    .write(psram_wr_cmd),   // sampled edge (from cpu)
    .byte_write(1'b1),      // always bytes
    .rdv(psram_rd_vid),     // video access
    .addr(psram_addr), 
    .din({psram_di, psram_di}),
    .dout(dramout), 
    .dout2(dramout2), 
    .busy(psram_busy),

    .memcpubusy(memcpubusy),
    .memvidbusy(memvidbusy),
    .rdcpu_finished(rdcpu_finished),

    // PSRAM i/o
    .O_psram_ck(O_psram_ck),
    .IO_psram_rwds(IO_psram_rwds), 
    .IO_psram_dq(IO_psram_dq),
    .O_psram_cs_n(O_psram_cs_n)
);

reg psram_busy_p;

//address[0] ? dout[15:8] : dout[7:0]
reg[7:0] sram_data_in;
//always @(negedge rdcpu_finished) sram_data_in = psram_addr[0] ? dramout[15:8] : dramout[7:0];

always @(negedge rdcpu_finished) 
    sram_data_in <= cpu_a_mangled[0] ? dramout[15:8] : dramout[7:0];

//always @(posedge clk_psram_p) 
//    if (rdcpu_finished) sram_data_in = psram_addr[0] ? dramout[15:8] : dramout[7:0];


reg[31:0] vdata;
//always @(negedge memvidbusy_rd)vdata<={dramout2,dramout};
always @(negedge memvidbusy) vdata <= {dramout2, dramout};


`else

// nothing
reg[31:0] vdata;
wire memcpubusy = 0, memvidbusy = 0, rdcpu_finished = 1;
reg[7:0] sram_data_in;

`endif

////////////////////
// 8x BARKAR KVAZ //
////////////////////

wire [5:0]  ramdisk_addr;

multikvaz mkvaz(
    .clk24(clk24),
    .clke(cpu_ce),
    .reset(mreset), 
    .address_r(address_bus_r), // registered bus for i/o ports
    .data(DO),
    .iowr(io_write & ~WR_n),

    .address(address_bus),    // proper addr bus for memory select logic
    .stack(io_stack_long),
    .ramdisk_addr(ramdisk_addr));


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
wire video_lcd_clk;
wire video_lcd_den;

`ifdef WITH_TV
wire [1:0]      tv_mode = {~KEY[2], 1'b1};
`else
wire [1:0]      tv_mode = {2'b00};
`endif

wire        tv_sync;
wire [4:0]  tv_luma;
wire [4:0]  tv_chroma;
wire [4:0]  tv_cvbs;
wire [7:0]  tv_test;

wire[3:0] border_idx_delayed;
border_delay #(.DELAY(14)) bdly(.clk(clk24), .ce(ce6), .i_borderindex(video_border_index), .o_delayed(border_idx_delayed));

wire rdvid;
wire [7:0] realcolor;       // this truecolour value fetched from buffer directly to display
wire [7:0] realcolor2buf;   // this truecolour value goes into the scan doubler buffer

wire [14:0] bgr555;

video vidi(.clk24(clk24), 
            .ce12(ce12), 
            .ce6(ce6), 
            .ce6x(ce6x), 
            .clk4fsc(clkpal4FSC), 
            .reset_n(mreset_n),
            .video_slice(video_slice), 
            .pipe_ab(pipe_ab),
            .mode512(video_mode512), 
            .vdata(vdata),
            .SRAM_ADDR(VIDEO_A), 

            .hsync(vga_hs), .vsync(vga_vs),
            .lcd_clk_o(video_lcd_clk),
            .lcd_den_o(video_lcd_den), 

            .osd_hsync(osd_hsync), .osd_vsync(osd_vsync),
            .coloridx(coloridx),
            .realcolor_in(realcolor2buf),
            .realcolor_out(realcolor),      // TODO: add this line to other versions, it was lost!
            .bgr555_out(bgr555),            // same as realcolor_out but 5:5:5 components
            .retrace(retrace),
            .video_scroll_reg(video_scroll_reg),
`ifdef START1200
            .border_idx(4'b0),
`else
            .border_idx(border_idx_delayed),
`endif
				
            .tv_sync(tv_sync),
            .tv_luma(tv_luma),
            .tv_chroma_o(tv_chroma),
            .tv_cvbs(tv_cvbs),
            .tv_test(tv_test),
            .tv_mode(tv_mode),
            .tv_osd_fg(osd_fg),
            .tv_osd_bg(osd_bg),
            .tv_osd_on(osd_active),
            .rdvid_o(rdvid)
            );

`ifdef START1200
wire[7:0] color1200;
palette_rom (
                       .address({video_mode512,video_border_index,retrace?4'b0:coloridx}), 
                       .clock(clk24),
                       .q(color1200));
assign {realcolor2buf[7:4],realcolor2buf[2:1],realcolor2buf[3],realcolor2buf[0]}={~color1200[5:0],2'b00};
`else

wire [3:0] paletteram_adr = (retrace/*|video_palette_wren*/) ? video_border_index : coloridx;
//palette_ram (.address(paletteram_adr), 
//                       .data(video_palette_value), 
//                       .inclock(clk24), .outclock(clk24), 
//                       .wren(video_palette_wren_delayed), 
//                       .q(realcolor2buf));

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

palette_ram ru2tru(
    .ad(paletteram_adr),              //input [3:0] ad
    .din(video_palette_value),        //input [7:0] din
    .dout(realcolor2buf),             //output [7:0] dout
    .clk(clk24),                      //input clk
    .oce(1'b1),                       //input oce
    .ce(1'b1),                        //input ce
    .reset(1'b0),                     //input reset
    .wre(video_palette_wren_delayed)  //input wre
);

`endif

wire [1:0]  lowcolor_b = {2{osd_active}} & {realcolor[7],1'b0};
wire        lowcolor_g = osd_active & realcolor[5];
wire        lowcolor_r = osd_active & realcolor[2];

wire [7:0]  overlayed_colour = osd_active ? osd_colour : realcolor;

reg [3:0] video_r;
reg [3:0] video_g;
reg [3:0] video_b;

always @(posedge clk24) begin
    video_r <= {overlayed_colour[2:0], lowcolor_r};
    video_g <= {overlayed_colour[5:3], lowcolor_g};
    video_b <= {overlayed_colour[7:6], lowcolor_b};
end

`ifdef VIDEOMOD
videomod videomod(.clk_color_mod(clk_color_mod),
    .video_r(video_r), .video_g(video_g), .video_b(video_b),
    .vga_hs(vga_hs), .vga_vs(vga_vs),
    .lcd_clk_i(video_lcd_clk), .lcd_den_i(video_lcd_den),
    .lcd_clk_o(LCD_CLK), .lcd_den_o(LCD_DEN),
    .tv_cvbs(tv_cvbs), .tv_luma(tv_luma), .tv_chroma(tv_chroma),
    .VGA_HS(LCD_HSYNC), .VGA_VS(LCD_VSYNC),
    .VGA_R(LCD_R[4:1]), .VGA_G(LCD_G[5:2]), .VGA_B(LCD_B[4:1]),
    .S_VIDEO_Y(LCD_G[0]), .S_VIDEO_C(LCD_G[1]));
`else
assign LCD_CLK = video_lcd_clk;
assign LCD_DEN = video_lcd_den;
assign LCD_HSYNC = vga_hs;
assign LCD_VSYNC = vga_vs;
// FIX this for OSD!
//assign LCD_R[4:1] = video_r;
//assign LCD_G[5:2] = video_g;
//assign LCD_B[4:1] = video_b;
assign LCD_R[4:0] = bgr555[4:0];
assign LCD_G[5:1] = bgr555[9:5];
assign LCD_B[4:0] = bgr555[14:10];

`endif
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
    
    //if (interrupt_ack)
    //    int_request <= 0;
    if ((int_request & ~int_rq_tick) | interrupt_ack)
        int_request <= 0;
end


///////////////////
// PS/2 KEYBOARD //
///////////////////
reg         kbd_mod_rus;
wire [7:0]  kbd_rowbits;
wire        kbd_key_shift;
wire        kbd_key_ctrl;
wire        kbd_key_rus;
wire        kbd_key_blksbr;
wire        kbd_key_blkvvod = kbd_key_blkvvod_phy | osd_command_f11;
wire        kbd_key_blkvvod_phy;
wire        kbd_key_scrolllock;
wire [5:0]  kbd_keys_osd;

//wire osd_command_f11 = 0; // temporary while everything is disabled

`ifdef WITH_KEYBOARD

wire [7:0]  kbd_rowselect; = ~vv55int_pa_out;

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
always @*
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
always @* portmap_device = address_bus_r[7:2];



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


`ifdef OLD_82C55
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
`else
assign vv55int_oe_n = vv55int_cs_n;
k580vv55 vv55int(
    .reset(mreset),
    .clk_sys(clk24),
    .addr(vv55int_addr),
    .we_n(vv55int_wr_n | vv55int_cs_n),
    .idata(vv55int_idata),
    .odata(vv55int_odata),
    .ipa(vv55int_pa_in),
    .opa(vv55int_pa_out),
    .ipb(vv55int_pb_in),
    .opb(vv55int_pb_out),
    .ipc(vv55int_pc_in),
    .opc(vv55int_pc_out));

`endif

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
`else
assign vi53_out = 3'b000;
assign vi53_odata = 8'h00;
assign vi53_testpin = 9'h000;
`endif


////////////////////////////
// Internal ports, $0C -- //
////////////////////////////
wire        iports_sel      = portmap_device == 3'b011;
wire        iports_write    = /*~ram_write_n &*/ io_write & iports_sel; // this repeats as a series of 3 _|||_ wtf

// port $0C-$0F: palette value out
wire iports_palette_sel = address_bus[1:0] == 2'b00;        // not used <- must be fixed some day



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
wire        ay_rden;
wire        ay_wren;
wire        ay_sel;

wire [7:0]  ay_soundA,ay_soundB,ay_soundC;
wire [7:0]  rs_soundA,rs_soundB,rs_soundC;

`ifdef WITH_AY
assign      ay_sel = portmap_device == 3'b101 && address_bus_r[1] == 0; // only ports $14 and $15
assign      ay_wren = ~WR_n & io_write & ay_sel;
assign      ay_rden = io_read & ay_sel;

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
assign RSdataOut = 8'b0;
`endif

// button debounce

//wire button_debounced;
//oneshot #(16'hffff) button_debounce(clk24, cpu_ce, ~BUTTON, button_debounced);
reg [23:0] debounce_ctr;
reg        debounce_on;
reg        button_debounced;
always @(posedge clk24)
begin
    if (~SYS_RESETN)
        {debounce_on, button_debounced} <= 2'b00;
    else
    if (vi53_timer_ce) begin
      button_debounced <= 1'b0;
      if (!debounce_on)
      begin
          if (~BUTTON)
          begin
              debounce_ctr <= 24'hffffff;
              debounce_on <= 1'b1;
              button_debounced <= 1'b1;
          end
      end
      else
      begin
          debounce_ctr <= debounce_ctr - 1'b1;
          if (debounce_ctr == 0)
              debounce_on <= 1'b0;
      end
    end
end

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
                .key_blksbr(button_debounced || kbd_key_blksbr == 1'b1 || osd_command_f12), 
                .key_osd(kbd_key_scrolllock),
                .o_disable_rom(disable_rom),
                .o_blksbr_reset(blksbr_reset_pulse),
                .o_osd(scrollock_osd)
                );
                
always @* gledreg[8] <= disable_rom;               

`ifdef WITH_I2C
I2C_AV_Config       u7(clk24,mreset_n,I2C_SCLK,I2C_SDAT);
`endif


`ifdef WITH_SERIAL_PROBE

wire [21:0] halt_addr;
wire [7:0] halt_do;
wire halt_wr;
wire halt_halt;

haltmode debugger(.clk24(clk24), .rst_n(delayed_reset_n),
    .uart_rx(UART_RX), .uart_tx(UART_TX),
    .addr_o(halt_addr), .data_o(halt_do), .wr_o(halt_wr),
    .halt_o(halt_halt)
);

always @(posedge clk24)
    LED[5:0] <= {cpu_m1, ~halt_addr[4:0]};



`endif


endmodule
