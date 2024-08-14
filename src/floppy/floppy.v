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
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: floppy.v
//
// Floppy drive emulation toplevel
//
// --------------------------------------------------------------------

module floppy(
        clk, cpu_ce, reset_n, 
        // sd card signals
        sd_dat, sd_dat3, sd_cmd, sd_clk, 
        // uart comms
        `ifdef BUILTIN_UART
        uart_txd, 
        `else
        o_uart_send,
        o_uart_data,
        i_uart_busy,
        `endif
        
        // io ports
        hostio_addr,
        hostio_idata,
        hostio_odata,
        hostio_rd,
        hostio_wr,
        
        // keyboard input for osd menu
        keyboard_keys,
        
        // screen memory
        display_addr,
        display_data,
        display_rden,
        display_wren,
        display_idata,
        
        // return from OSD
        osd_command,
        
        // debug 
        green_leds, red_leds, debug, debugidata,
        host_hold
        );
        
parameter DISK_HAX = "../../../disk.hax";

parameter IOBASE = 16'hE000;
parameter PORT_MMCA= 0;
parameter PORT_SPDR= 1;
parameter PORT_SPSR= 2;
parameter PORT_JOY = 3;
parameter PORT_TXD = 4;
parameter PORT_RXD = 5;
parameter PORT_CTL = 6;

parameter PORT_TMR1 = 7;
parameter PORT_TMR2 = 8;

parameter PORT_CPU_REQUEST      = 9;
parameter PORT_CPU_STATUS       = 10;
parameter PORT_TRACK            = 11;
parameter PORT_SECTOR           = 12;

parameter PORT_LED = 16;
parameter PORT_OSD_COMMAND = 17;                // {F11,F12,HOLD}

input           clk;
input           cpu_ce;
input           reset_n;
input           sd_dat;
output  reg     sd_dat3;
output          sd_cmd;
output          sd_clk;
`ifdef BUILTIN_UART
output          uart_txd;
`else
output          o_uart_send;
output [7:0]    o_uart_data;
input           i_uart_busy;
`endif

// I/O interface to host system (Vector)
input   [2:0]   hostio_addr;
input   [7:0]   hostio_idata;
output  [7:0]   hostio_odata;
input           hostio_rd;
input           hostio_wr;

// keyboard interface
input   [5:0]   keyboard_keys;  // {reserved,left,right,up,down,enter}

// screen memory
output  [7:0]   display_addr;
output  [7:0]   display_data;
output          display_rden;
output          display_wren;
input   [7:0]   display_idata;

output reg[7:0] osd_command;
output reg[7:0] green_leds;

output  [7:0]   red_leds;
output  [7:0]   debug;
output  [7:0]   debugidata;
output          host_hold;

wire ce = 1'b1;

wire    [15:0]  cpu_ax;
wire            memwrx;
wire    [7:0]   cpu_dox;

wire    [15:0]  cpu_a = cpu_ax;

wire memwr = memwrx;
wire    [7:0]   cpu_do = cpu_dox;
reg     [7:0]   cpu_di;

wire [7:0]      wdport_track;
wire [7:0]      wdport_sector;
wire [7:0]      wdport_status;
wire [7:0]      wdport_cpu_request;
reg  [7:0]      wdport_cpu_status;

wire [9:0]      wd_ram_addr;
wire            wd_ram_rd;
wire            wd_ram_wr;      
wire [7:0]      wd_ram_odata;   // this is to write to ram



assign red_leds = {spi_wren,7'b0};
assign debug = wdport_status;
assign debugidata = {ce & bufmem_en, ce, hostio_rd, wd_ram_rd};

`define VHDL_6502
//`define LUDDES6502
//`define ARLET6502

// Workhorse 6502 CPU
`ifdef VHDL_6502
cpu65xx_en cpu(
                .clk(clk),
                .reset(~reset_n),
                .enable(ce & ~(wd_ram_rd|wd_ram_wr)),
                .nmi_n(1'b1),
                .irq_n(1'b1),
                .di(cpu_di),
                .do(cpu_dox),
                .addr(cpu_ax),
                .we(memwrx)
        );
`endif

`ifdef LUDDES6502
wire ready = /*ce & */ ~(wd_ram_rd|wd_ram_wr);
wire [15:0] cpu_ax_comb;
CPU6502(.clk(clk),
    .ce(1'b1),
    .reset(~reset_n),
    .irq(1'b0),
    .nmi(1'b0),
    .dout(cpu_dox),
    .aout(cpu_ax_comb),
    .DIN(cpu_di),
    .mr(cpu_memr),
    .mw(memrwx));

reg [15:0] cpu_ax_prev;
always @(posedge clk)
    if (ce) cpu_ax_prev <= cpu_ax_comb;
assign cpu_ax = cpu_ax_prev;
`endif


`ifdef ARLET6502

// this doesn't work on Gowin because of "Find logic loop" 
// apparently it has to do with how AB is formed in Arlet's 6502...
wire ready = /*ce & */ ~(wd_ram_rd|wd_ram_wr);
wire [15:0] cpu_ax_comb;
cpu cpu(.clk(clk),
    .clken(1'b1),
    .reset(~reset_n),
    .AB(cpu_ax_comb),
    .DI(cpu_di),
    .DO(cpu_dox),
    .WE(memwrx),
    .IRQ(1'b0),
    .NMI(1'b0),
    .RDY(ready)
);

reg [15:0] cpu_ax_prev;
always @(posedge clk)
    if (ce) cpu_ax_prev <= cpu_ax_comb;
assign cpu_ax = cpu_ax_prev;

`endif


// Main RAM, Low-mem, Buffer-mem, I/O ports to CPU connections
wire    [7:0]   ram_do;
wire    [7:0]   lowmem_do;
wire    [7:0]   bufmem_do;
reg     [7:0]   ioports_do;

// memory enables
wire vectors_en = &cpu_a[15:4];
wire lowmem_en = |cpu_a[15:9] == 0;
wire bufmem_en = (wd_ram_rd|wd_ram_wr) || (cpu_a >= 16'h200 && cpu_a < 16'h600);
wire rammem_en = cpu_a >= 16'h0800 && cpu_a < 16'h8000;
wire ioports_en= cpu_a >= IOBASE && cpu_a < IOBASE + 256;
wire osd_en = cpu_a >= IOBASE + 256 && cpu_a < IOBASE + 512;
wire osd_rd = cpu_ax_comb >= IOBASE + 256 && cpu_ax_comb < IOBASE + 512;

wire [5:0] memsel = {vectors_en, lowmem_en, bufmem_en, rammem_en, osd_en, ioports_en};

always @*
begin: _cpu_datain
        //case({&cpu_a[15:4], lowmem_en, bufmem_en, rammem_en, osd_en}) 
        case (memsel)
        6'b100000:       cpu_di <= (cpu_ax_prev[0] ? 8'h08:8'h00); // boot addr $0800
        6'b010000:       cpu_di <= lowmem_do;
        6'b001000:       cpu_di <= bufmem_do;
        6'b000100:       cpu_di <= ram_do;
        6'b000010:       cpu_di <= display_idata;
        6'b000001:       cpu_di <= ioports_do;
        default:         cpu_di <= 8'hff;
        endcase
end                                                     


assign display_addr = cpu_ax_comb[7:0];
assign display_data = cpu_do;
assign display_wren = osd_en & memwr;
assign display_rden = osd_en | osd_rd;

wire rammem_cs = cpu_ax_comb >= 16'h0800 && cpu_ax_comb < 16'h8000;

wire [14:0] rammem_a = cpu_ax_comb-16'h0800;
ram #(.ADDR_WIDTH(15),.DEPTH(16384), .HEXFILE(DISK_HAX)) 
flopramnik(
    .clk(clk),
    .cs(rammem_cs),
    .addr(rammem_a),
    .we(rammem_cs & memwr),
    .data_in(cpu_do),
    .data_out(ram_do)
);

wire lowmem_cs = |cpu_ax_comb[15:9] == 0;
wire lowmem_wr = lowmem_cs & memwr;
wire [8:0] lowmem_a = cpu_ax_comb[8:0];
ram #(.ADDR_WIDTH(9),.DEPTH(512)) zeropa(
    .clk(clk),
    .cs(lowmem_cs),
    .addr(lowmem_a),
    .we(lowmem_wr),
    .data_in(cpu_do),
    .data_out(lowmem_do));

wire [9:0]      bufmem_a = (wd_ram_rd|wd_ram_wr) ? wd_ram_addr : cpu_ax_comb - 10'h200;
wire            bufmem_wren = wd_ram_wr | memwr;
wire [7:0]      bufmem_di = wd_ram_wr ? wd_ram_odata : cpu_do;

wire bufmem_cs = (wd_ram_rd|wd_ram_wr) || (cpu_ax_comb >= 16'h200 && cpu_ax_comb < 16'h600);
ram #(.ADDR_WIDTH(10),.DATA_WIDTH(8),.DEPTH(1024)) bufpa(
    .clk(clk),
    .cs(bufmem_cs), // ??
    .addr(bufmem_a),
    .we(bufmem_cs & bufmem_wren),
    .data_in(bufmem_di),
    .data_out(bufmem_do));

/////////////////////
// CPU INPUT PORTS //
/////////////////////
always @* //@(posedge clk)
begin
    case (cpu_a)             
        IOBASE+PORT_CTL:        ioports_do <= {7'b0,uart_busy}; // uart status
        IOBASE+PORT_TMR1:       ioports_do <= timer1q;
        IOBASE+PORT_TMR2:       ioports_do <= timer2q;
        IOBASE+PORT_SPDR:       ioports_do <= spdr_do;
        IOBASE+PORT_SPSR:       ioports_do <= {7'b0,~spdr_dsr};
        IOBASE+PORT_CPU_REQUEST:
                                ioports_do <= wdport_cpu_request;
        IOBASE+PORT_TRACK:      ioports_do <= wdport_track;
        IOBASE+PORT_SECTOR:     ioports_do <= wdport_sector;
        
        IOBASE+PORT_JOY:        ioports_do <= keyboard_keys;
        default:                ioports_do <= 8'hFF;
    endcase
end

/////////////////////
// CPU OUTPUT PORTS //
/////////////////////
always @(posedge clk or negedge reset_n)
begin
    if (!reset_n) 
    begin
        green_leds <= 0;
        uart_state <= 3;
        uart_send <= 0;
        sd_dat3 <= 1;
    end
    else
    begin
        if (ce)
        begin
            if (memwr && cpu_ax_comb[15:8] == 8'hE0)
            begin
                //$display("writing to port %04x=%02x", cpu_ax_comb, cpu_do);

                if (cpu_ax_comb[7:0] == 8'h10) begin
                    green_leds <= cpu_do;
                end

                // E004: send data
                if (cpu_ax_comb[7:0] == PORT_TXD) begin
                    uart_data <= cpu_do;
                    uart_state <= 0;
                end

                // MMCA: SD/MMC card chip select
                if (cpu_ax_comb[7:0] == PORT_MMCA) begin
                    sd_dat3 <= cpu_do[0];
                end

                // CPU status return
                if (cpu_ax_comb[7:0] == PORT_CPU_STATUS) begin
                    wdport_cpu_status <= cpu_do;
                end

                if (cpu_ax_comb[7:0] == PORT_OSD_COMMAND) begin
                    osd_command <= cpu_do;
                end
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
    end
end

// trace
always @(posedge clk)
    if (rammem_cs)
    begin
        //if (rammem_a == 0)
        //    $display("rammem read @0000");
    end


//////////////////
// UART Console //
//////////////////
reg             uart_send;
reg  [7:0]      uart_data;
wire            uart_busy;
reg  [1:0]      uart_state = 3;

//`define VHDL_UART

`ifdef BUILTIN_UART

`ifdef VHDL_UART
TXD txda( 
        .clk(clk),
        .ld(uart_send),
        .data(uart_data),
        .TxD(uart_txd),
        .txbusy(uart_busy)
   );
`else

`ifdef SIMULATION
`define BAUDRATE 12000000
`else
`define BAUDRATE 115200
`endif

uart_interface #(.SYS_CLK(24000000),.BAUDRATE(`BAUDRATE)) uart0(
    .clk(clk),
    .reset(~reset_n),
    .cs(ce),
    .rs(1'b1),
    .we(uart_send),
    .din(uart_data),
    .uart_tx(uart_txd),
    .tx_busy(uart_busy));

`endif

`else

assign o_uart_send = uart_send;
assign o_uart_data = uart_data;
assign uart_busy = i_uart_busy;

`endif // BUILTIN_UART

////////////
// TIMERS //
////////////

wire [7:0] timer1q;
wire [7:0] timer2q;

wire timer1_wren = ce && cpu_ax_comb==(IOBASE+PORT_TMR1) && memwr;
wire timer2_wren = ce && cpu_ax_comb==(IOBASE+PORT_TMR2) && memwr;

timer100hz timer1(.clk(clk), .di(cpu_do), .wren(timer1_wren), .q(timer1q));
timer100hz timer2(.clk(clk), .di(cpu_do), .wren(timer2_wren), .q(timer2q));

//////////////////////
// SPI/SD INTERFACE //
//////////////////////

wire [7:0]      spdr_do;
wire            spdr_dsr;
wire            spi_wren = (ce && (cpu_ax_comb == (IOBASE+PORT_SPDR) && memwr));
spi sd0(.clk(clk),
        .ce(1'b1),
        .reset_n(reset_n),
        .mosi(sd_cmd),
        .miso(sd_dat),
        .sck(sd_clk),
        .di(cpu_do), 
        .wr(spi_wren), 
        .do(spdr_do), 
        .dsr(spdr_dsr)
        );

////////////
// WD1793 //
////////////

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
                                
                                // host i/o ports 
                                .rd(wd_rd), 
                                .wr(wd_wr), 
                                .addr(hostio_addr), 
                                .idata(hostio_idata), 
                                .odata(hostio_odata), 

                                // memory buffer interface
                                .buff_addr(wd_ram_addr), 
                                .buff_rd(wd_ram_rd), 
                                .buff_wr(wd_ram_wr), 
                                .buff_idata(bufmem_do),         // data read from ram
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
