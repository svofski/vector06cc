//`default_nettype none

// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky
// 
// Design File: floppy.v
//
// Floppy drive emulation toplevel
//
// --------------------------------------------------------------------

module floppy_neo430(
    input           clk,
    input           cpu_ce,
    input           reset_n,

    // -- sd card --
    input           sd_dat,
    output reg      sd_dat3,
    output          sd_cmd,
    output          sd_clk,
    
    // -- uart console --
    output          o_uart_send,
    output [7:0]    o_uart_data,
    input           i_uart_busy,
    
    // I/O interface to host system (Vector-06c)
    input   [2:0]   hostio_addr,
    input   [7:0]   hostio_idata,
    output  [7:0]   hostio_odata,
    input           hostio_rd,
    input           hostio_wr,
    
    // -- keyboard interface --
    input   [5:0]   keyboard_keys,  // {reserved,left,right,up,down,enter}
    
    // -- osd screen memory -- 
    output  [7:0]   o_osd_addr,
    output  [15:0]  o_osd_data,
    output          o_osd_rden,
    output  [1:0]   o_osd_wren,
    input   [15:0]  i_osd_data,
    
    output reg[7:0] osd_command,
    
    output          host_hold,

    // -- ROM / EDD loader support --
    output          o_rom_hold,   // holds the cpu while loading happens
    output  [15:0]  o_rom_addr,   // regular addr
    output   [5:0]  o_rom_page,   // for kvaz loading (e.g. from .edd files)
    output   [7:0]  o_rom_data,   // rom/edd file data
    output          o_rom_wr,     // write strobe

    // -- WAV sample --
    output   [7:0]  o_wav_sample  // wav player sample
);
        
parameter DISK_HAX = "../../../disk_neo430.hax";

parameter IOBASE = 16'hFF00;
parameter PORT_MMCA= 0;
parameter PORT_SPDR= 8'hA6;
parameter PORT_SPSR= 8'hA4;
parameter PORT_JOY = 2;
parameter PORT_TXD = 4;
parameter PORT_RXD = 5; // meh but unused anyway
parameter PORT_CTL = 6;

parameter PORT_TMR1 = 8;
parameter PORT_TMR2 = 10;

parameter PORT_CPU_REQUEST      = 12;
parameter PORT_CPU_STATUS       = 14;
parameter PORT_TRACK            = 16;
parameter PORT_SECTOR           = 18;

parameter PORT_LED              = 20;
parameter PORT_OSD_COMMAND      = 22;               // {ROMHOLD,F11,F12,HOLD}

parameter PORT_ROM_PAGE         = 24;               // romload_addr[21:16]
parameter PORT_ROM_ADDR         = 26;               // romload_addr[15:0]     --- word access only
parameter PORT_ROM_DATA         = 28;               // romload_data, generate write strobe to o_rom_wr
parameter PORT_WAVCTL           = 30;               // wav playback control

wire ce = 1'b1;


wire [7:0]  wdport_track;
wire [7:0]  wdport_sector;
wire [7:0]  wdport_status;
wire [7:0]  wdport_cpu_request;
reg  [7:0]  wdport_cpu_status;

wire [9:0]  wd_ram_addr;
wire        wd_ram_rd;
wire        wd_ram_wr;      
wire [7:0]  wd_ram_odata;   // this is to write to ram

wire        cpu_memrd;
wire        cpu_imwe;
wire [1:0]  cpu_memwr;
wire [15:0] cpu_addr;
wire [15:0] cpu_do16;
reg  [15:0] cpu_di16;
wire [3:0]  cpu_irq = 4'b0000;

wire [15:0] imem_do16;
wire [15:0] dmem_do16;
wire [15:0] ioports_do16;

wire imem_sel = cpu_addr < 12*1024;       // 12K imem
wire dmem_sel = cpu_addr[15:12] == 4'hC;  // dmem   $c000-$c3ff
wire bmem_sel = cpu_addr[15:12] == 4'hD;  // bufmem $d000-$d3ff byte-accessible
wire osdmem_sel = cpu_addr[15:12] == 4'hE;// osd display
wire sysconfig_sel = &cpu_addr[15:4];     // $fff0..$ffff

wire ioports_sel = &cpu_addr[15:8] & ~&cpu_addr[7:4];       // $ff00..$ffef


reg [15:0] sysconfig_do;
always @(posedge clk)
begin: _sysconfig
  if (sysconfig_sel & cpu_memrd)
      case (cpu_addr[3:0])
          4'h0: sysconfig_do <= 16'h0000;    // cpuid
          4'h2: sysconfig_do <= 16'h0000;    // sys features
          4'h6: sysconfig_do <= 12*1024;     // imem size in bytes
          4'hA: sysconfig_do <= 16'd2048;    // 2K dmem
          default: sysconfig_do <= 16'h0000;
      endcase
  else
      sysconfig_do <= 16'h0000;
end

always @*
    cpu_di16 <= imem_do16 | dmem_do16 | bmem_do16 | sysconfig_do | ioports_do16 | omem_do16;

//reg cpu_memrd_r;
//always @(posedge clk)
//    cpu_memrd_r <= cpu_memrd;

wire [15:0] cpu_addr_x;
//reg [15:0] cpu_addr_r = 0;
//always @(negedge clk)
//    if (cpu_memrd || |cpu_memwr) cpu_addr_r <= cpu_addr;
assign cpu_addr = cpu_addr_x;

neo430_cpu_std_logic 
//#(.BOOTLD_USE(0), .IMEM_AS_ROM(1)) 
neo430cpu
       (.clk_i(clk),
        .rst_i(reset_n),
        .mem_rd_o(cpu_memrd),
        .mem_imwe_o(cpu_imwe),
        .mem_wr_o(cpu_memwr),
        .mem_addr_o(cpu_addr_x),
        .mem_data_o(cpu_do16),
        .mem_data_i(cpu_di16),
        .irq_i(cpu_irq));

reg   imem_memrd_r;
wire  imem_memrd = imem_sel & cpu_memrd;
always @(posedge clk)
    imem_memrd_r <= imem_memrd;
wire [15:0] imem_do16_x;
assign imem_do16 = imem_memrd_r ? imem_do16_x : 16'h0000;
ram #(.ADDR_WIDTH(14), .DATA_WIDTH(16), .DEPTH(12*1024/2), .HEXFILE(DISK_HAX)) 
imem(
    .clk(clk),
    .cs(imem_memrd),
    .addr(cpu_addr[14:1]),
    .we(imem_sel & |cpu_memwr),
    .data_in(cpu_do16),
    .data_out(imem_do16_x)
);

reg   dmem_memrd_r;
wire  dmem_memrd = dmem_sel & cpu_memrd;
always @(posedge clk) dmem_memrd_r <= dmem_memrd;

wire  [1:0] dmem_memwr = {dmem_sel,dmem_sel} & cpu_memwr;

wire [15:0] dmem_do16_x;
assign dmem_do16 = dmem_memrd_r ? dmem_do16_x : 16'h0000;
wire [9:0] dmem_addr = cpu_addr[10:1];
ram2 #(.ADDR_WIDTH(10), .DATA_WIDTH(16), .DEPTH(1024))
dmem(
    .clk(clk),
    .cs(dmem_memrd | |dmem_memwr),
    .addr(dmem_addr),
    .we(dmem_memwr),
    .data_in(cpu_do16),
    .data_out(dmem_do16_x)
);

////////////////////////////////////////
// sound player (e.g. wav tape loader)
////////////////////////////////////////
// 24e6/512 = 46875 (/500 to get 48000)
// 2 ping-pong buffers in bufmem
// competing with wd_ram_addr/wd_ram_rd for reading
// competing with cpu when cpu writes data
// 
// wd_ram... is irrelevant because floppy would be inactive (ideally the
// controller should report not ready or something)
//
// cpu accesses are rare, but it's hard to be sure when to access
// next clock after imem_memrd seems to be always free


reg [8:0] wav_addr = 0;
reg [7:0] wav_sample = 0;

assign  o_wav_sample = wav_sample;

wire  bus_free = ~(cpu_memrd | |cpu_memwr | bmem_sel);
//wire bus_free = ~bmem_sel;

reg   [1:0] wav_read_rq = 0;  // read access request

// PORT_WAVCTL write access
// bit 1: A/B
// bit 0: enable
wire  wavctl_sel  = ioports_sel & cpu_addr[7:0] == PORT_WAVCTL;
wire  wavctl_wr   = wavctl_sel & cpu_memwr[0];

wire  [8:0] wav_addr_next = wav_addr + 1'b1;

reg   [3:0] wavctl = 0;
wire        wav_playback_en = wavctl[0];
wire        wav_playback_ab = wavctl[1];
wire  [1:0] wav_rate        = wavctl[3:2];

//reg [9:0] div1k = 0;
//always @(posedge clk) div1k <= div1k + 1'b1;
//
//wire      ce_wav48 = &div1k[8:0];
//wire      ce_wav24 = &div1k[9:0];

reg   [10:0] divsr = 0;
wire  [10:0] divsr_next = divsr + 1'b1;

localparam TOP_22050 = 24_000_000 / 22050;
localparam TOP_44100 = 24_000_000 / 44100;
localparam TOP_48000 = 24_000_000 / 48000;

always @(posedge clk)
begin
    divsr <= divsr_next;
    casez (wav_rate)
        2'b00:  if (divsr_next == TOP_44100) divsr <= 0;
        2'b01:  if (divsr_next == TOP_22050) divsr <= 0;
        2'b1?:  if (divsr_next == TOP_48000) divsr <= 0;
    endcase
end

wire ce_wav = divsr == 0;

always @(posedge clk)
begin
    if (~reset_n)
    begin
        wav_addr <= 0;
        wav_sample <= 0;
        wavctl <= 0;
    end

    if (ce_wav & wav_playback_en) 
    begin
        wav_addr <= wav_addr_next;    // advance sample pos and set read req
        wav_read_rq <= {2'b01};
        if (wav_addr_next == 0) wavctl[1] <= ~wavctl[1]; // switch a/b
    end

    // start/stop playback
    if (wavctl_wr)
    begin
        wavctl <= cpu_do16[2:0];
        wav_addr <= 0;
    end

    if (wav_read_rq[0] & bus_free) 
    begin
        wav_read_rq <= 2'b10;            // reset read rq and register sample
    end

    if (wav_read_rq[1])
    begin
        wav_read_rq <= 2'b00;
        wav_sample <= bmem_do8;
    end
end


// 00 x
// 01 0
// 10 1
// 11 x
wire [9:0] wav_ram_addr = {wav_playback_ab, wav_addr};
wire       wav_ram_rd = wav_read_rq[0] & bus_free;

////////////////////////////////////
// bufmem $d000-$d3ff sector buffer
////////////////////////////////////

wire bmem_cs = (wd_ram_rd|wd_ram_wr) || bmem_sel || wav_ram_rd;
reg bmem_memrd_r;
wire bmem_memrd = bmem_sel & cpu_memrd;
always @(posedge clk) bmem_memrd_r <= bmem_memrd;

//wire [9:0] bmem_addr = (wd_ram_rd|wd_ram_wr) ? wd_ram_addr : cpu_addr[9:0];
wire [9:0] bmem_addr =
    (wd_ram_rd|wd_ram_wr) ? wd_ram_addr : wav_ram_rd ? wav_ram_addr : cpu_addr[9:0];

wire [1:0] bmem_cpu_memwr = {bmem_sel,bmem_sel} & cpu_memwr;
wire [1:0] bmem_wd_memwr = {wd_ram_wr & wd_ram_addr[0], wd_ram_wr & ~wd_ram_addr[0]};
wire [1:0] bmem_memwr = bmem_cpu_memwr | bmem_wd_memwr;

wire [7:0] bmem_l_do_x;
wire [7:0] bmem_h_do_x;
wire [15:0] bmem_do16_x = {bmem_h_do_x, bmem_l_do_x};
wire [15:0] bmem_do16 = bmem_memrd_r ? bmem_do16_x : 16'h0000;
wire [7:0] bmem_do8 = bmem_addr[0] ? bmem_h_do_x : bmem_l_do_x;

wire [7:0] bmem_l_di = wd_ram_wr ? wd_ram_odata : cpu_do16[7:0];
wire [7:0] bmem_h_di = wd_ram_wr ? wd_ram_odata : cpu_do16[15:8];

ram #(.ADDR_WIDTH(9), .DEPTH(512), .DEBUG(0))
  buf0l(.clk(clk),
      .cs(bmem_cs),
      .addr(bmem_addr[9:1]),
      .we(bmem_memwr[0]),
      .data_in(bmem_l_di),
      .data_out(bmem_l_do_x));

ram #(.ADDR_WIDTH(9), .DEPTH(512))
  buf0h(.clk(clk),
      .cs(bmem_cs),
      .addr(bmem_addr[9:1]),
      .we(bmem_memwr[1]),
      .data_in(bmem_h_di),
      .data_out(bmem_h_do_x));

///////////////////////////
// OSD external mem
///////////////////////////
assign o_osd_addr = cpu_addr[7:0];
assign o_osd_data = cpu_do16;
assign o_osd_wren = {osdmem_sel, osdmem_sel} & cpu_memwr;
assign o_osd_rden = osdmem_sel & cpu_memrd; // $e000

reg omem_memrd_r;
always @(posedge clk) omem_memrd_r <= o_osd_rden;

wire [15:0] omem_do16 = omem_memrd_r ? i_osd_data : 16'h0000;


////////////
// TIMERS //
////////////

wire timer1_sel = ioports_sel & cpu_addr[7:0] == PORT_TMR1;
wire timer2_sel = ioports_sel & cpu_addr[7:0] == PORT_TMR2;

wire [7:0] timer1q;
wire [7:0] timer2q;

wire timer1_wren = timer1_sel & cpu_memwr[0];
wire timer2_wren = timer2_sel & cpu_memwr[0];

timer100hz timer1(.clk(clk), .di(cpu_do16[7:0]), .wren(timer1_wren), .q(timer1q));
timer100hz timer2(.clk(clk), .di(cpu_do16[7:0]), .wren(timer2_wren), .q(timer2q));

//////////////////////
// SPI/SD INTERFACE //
//////////////////////

wire spdr_sel = ioports_sel & cpu_addr[7:0] == PORT_SPDR;
wire spdr_memwr = spdr_sel & cpu_memwr[0];

wire [7:0]      spdr_do;
wire            spdr_dsr;   // status bit
wire [7:0]      spsr = {7'h0, ~spdr_dsr};

spi sd0(.clk(clk),
        .ce(1'b1),
        .reset_n(reset_n),
        .mosi(sd_cmd),
        .miso(sd_dat),
        .sck(sd_clk),
        .di(cpu_do16[7:0]), 
        .wr(spdr_memwr), 
        .do(spdr_do), 
        .dsr(spdr_dsr)
        );


//////////////////
// UART Console //
//////////////////
assign o_uart_send = uart_send;
assign o_uart_data = uart_data;
wire uart_busy = i_uart_busy;

wire uart_txd_sel = ioports_sel & cpu_addr[7:0] == PORT_TXD;
wire uart_ctl_sel = ioports_sel & cpu_addr[7:0] == PORT_CTL;

wire  uart_txd_memwr = uart_txd_sel & cpu_memwr[0];

reg [7:0] uart_data;
reg       uart_send;
reg [1:0] uart_state = 3;

always @(posedge clk)
begin: _uart_tx
    if (!reset_n)
        {uart_send, uart_state} <= {1'b0, 2'd3};

    if (uart_txd_memwr) 
    begin
        uart_data <= cpu_do16[7:0];
        uart_state <= 0;
    end

    // uart state machine
    case (uart_state) 
        0:
        if (~uart_busy)
        begin
            uart_send <= 1;
            uart_state <= 1;
        end
        1:
        if (uart_busy)
        begin
            uart_send <= 0;
            uart_state <= 2;
        end
        2:
        if (~uart_busy)
        begin
            uart_data <= uart_data + 1;
            if (uart_data == 65+27) uart_data <= 8'd65;
            uart_state <= 3;
        end
        3:;
    endcase             
end

////////////////////
// SD Card CS/DAT3
////////////////////
wire mmca_sel = ioports_sel & cpu_addr[7:0] == PORT_MMCA;
wire mmca_memwr = mmca_sel & cpu_memwr[0];
always @(posedge clk)
begin: _sddat
    if (~reset_n)
        sd_dat3 <= 1'b1;

    // MMCA: SD/MMC card chip select
    if (mmca_memwr) sd_dat3 <= cpu_do16[0];
end

/////////////////////
// OSD COMMAND
/////////////////////
wire osdcmd_sel = ioports_sel & cpu_addr[7:0] == PORT_OSD_COMMAND;
wire osdcmd_memwr = osdcmd_sel & cpu_memwr[0];
always @(posedge clk)
begin: _osdcmd
    if (~reset_n)
        osd_command <= 8'h00;
    if (osdcmd_memwr) osd_command <= cpu_do16[7:0];
end

/////////////////////
// ROMLOAD 
/////////////////////
wire romload_pagesel    = ioports_sel & cpu_addr[7:0] == PORT_ROM_PAGE;
wire romload_addrsel    = ioports_sel & cpu_addr[7:1] == (PORT_ROM_ADDR >> 1); // word access
wire romload_datasel    = ioports_sel & cpu_addr[7:0] == PORT_ROM_DATA;

wire  romload_page_wr = romload_pagesel & cpu_memwr[0];   // byte
wire  romload_addr_wr = romload_addrsel & |cpu_memwr;     // word
wire  romload_data_wr = romload_datasel & cpu_memwr[0];   // byte

reg   [5:0] romload_page = 0;
reg  [15:0] romload_addr = 0;
reg   [7:0] romload_data = 0;
reg         romload_wr = 0;

always @(posedge clk)
begin: _romloadwr
    if (~reset_n)
        {romload_page, romload_addr, romload_data, romload_wr} <= 0;
    else
    begin
        romload_wr <= 1'b0;
        if (romload_page_wr) romload_page <= cpu_do16[7:0];
        if (romload_addr_wr) romload_addr <= cpu_do16;
        if (romload_data_wr) {romload_wr, romload_data} <= {1'b1, cpu_do16[7:0]};
    end
end

/////////////////////
// CPU INPUT PORTS //
/////////////////////
reg [15:0] ioports_do16_x;
always @*
begin
    case (cpu_addr[7:0])             
        PORT_CTL:       ioports_do16_x <= {8'h0,7'b0,uart_busy}; // uart status
        PORT_TMR1:      ioports_do16_x <= {8'h0, timer1q}; 
        PORT_TMR2:      ioports_do16_x <= {8'h0, timer2q}; 
        PORT_SPDR:      ioports_do16_x <= {8'h0, spdr_do};  // spi rx
        PORT_SPSR:      ioports_do16_x <= {8'h0, spsr};     // spi status
        PORT_CPU_REQUEST: ioports_do16_x <= {8'h0, wdport_cpu_request};
        PORT_TRACK:     ioports_do16_x <= {8'h0, wdport_track};
        PORT_SECTOR:    ioports_do16_x <= {8'h0, wdport_sector};
        PORT_JOY:       ioports_do16_x <= {8'h0, keyboard_keys};
        PORT_WAVCTL:    ioports_do16_x <= {8'h0, 6'b0, wav_playback_ab, wav_playback_en};
        default:        ioports_do16_x <= 16'h0;
    endcase
end

// gate ioports_do16_x to ioports_do16 right on time
reg ioports_memrd_r;
wire ioports_memrd = ioports_sel & cpu_memrd;
always @(posedge clk) ioports_memrd_r <= ioports_memrd;
assign ioports_do16 = ioports_memrd_r ? ioports_do16_x : 16'h0000;


////////////
// WD1793 //
////////////

// floppy cpu status to vector-06c
wire wdport_cpu_status_sel = ioports_sel & cpu_addr[7:0] == PORT_CPU_STATUS;
wire wdport_cpu_status_memwr = wdport_cpu_status_sel & cpu_memwr[0];
always @(posedge clk)
begin: _wdport_cpu_status
    if (~reset_n)
        wdport_cpu_status <= 8'h00;
    if (wdport_cpu_status_memwr)
        wdport_cpu_status <= cpu_do16[7:0];
end

////////////////
// ROM LOADER //
////////////////

assign o_rom_hold = osd_command[3];
assign o_rom_addr = romload_addr;
assign o_rom_page = romload_page;
assign o_rom_data = romload_data;
assign o_rom_wr   = romload_wr;

// here's how 1793's registers are mapped in Vector-06c
// 00011xxx
//      000             $18     Data
//          001         $19     Sector
//              010             $1A             Track
//              011             $1B             Command/Status
//              100             $1C             Control                         Write only

wire wd_rd = cpu_ce & hostio_rd;
wire wd_wr = cpu_ce & hostio_wr;

wd1793 vg93(
    .clk(clk), 
    .clken(ce), 
    .reset_n(reset_n),
    
    // host (vector-06c) i/o ports 
    .rd(wd_rd), 
    .wr(wd_wr), 
    .addr(hostio_addr), 
    .idata(hostio_idata), 
    .odata(hostio_odata), 
    
    // memory buffer interface
    .buff_addr(wd_ram_addr), 
    .buff_rd(wd_ram_rd), 
    .buff_wr(wd_ram_wr), 
    .buff_idata(bmem_do8),         // data read from ram
    .buff_odata(wd_ram_odata),      // data to write to ram
    
    // workhorse interface
    .oTRACK(wdport_track),
    .oSECTOR(wdport_sector),
    .oSTATUS(wdport_status),
    .oCPU_REQUEST(wdport_cpu_request),
    .iCPU_STATUS(wdport_cpu_status),
    
    .wtf(host_hold)
    );
endmodule
