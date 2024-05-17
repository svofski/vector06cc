`timescale 1ns/10ps

`default_nettype none

module floppy_testbench;


reg clk=0;
reg reset = 0;
always #5 clk <= ~clk;

initial begin
    $dumpvars(0, floppy_testbench);

    #5 reset <= 1;
    #20 reset <= 0;

    #1000000 $finish;
end

wire    [15:0]  addr;
wire    [7:0]   idata = 0;
wire    [7:0]   odata;
wire            memwr, sd_dat, sd_dat3, sd_cmd, sd_clk, uart_txd;

// hostias
reg     [2:0]   hostio_addr = 0;
reg     [7:0]   hostio_idata = 0;
wire    [7:0]   hostio_odata;
reg             hostio_rd = 0;
reg             hostio_wr = 0;

wire [22:0] floppy_sdram_addr;
wire [7:0]  floppy_sdram_do;
wire [7:0]  floppy_sdram_di;
wire        floppy_sdram_read;
wire        floppy_sdram_write;
wire        floppy_sdram_busy;

wire    [5:0]   keyboard_keys;

reg [3:0] cereg = 4'b1;
always @(posedge clk)
    cereg <= {cereg[2:0], cereg[3]};
wire ce = 1'b1;//cereg[0];

floppy #(.DISK_HAX("disk.hax")) floppy0(
    .clk(clk),
    .cpu_ce(ce),
    .reset_n(~reset),
    //.addr(addr),
    //.idata(idata),
    //.odata(odata),
    //.memwr(memwr),

    .sd_dat(sd_dat),        // sd card signals
    .sd_dat3(sd_dat3),      // sd card signals
    .sd_cmd(sd_cmd),        // sd card signals
    .sd_clk(sd_clk),        // sd card signals
    .uart_txd(uart_txd),    // uart tx pin
    
    // I/O interface to host system (Vector-06C)
    .hostio_addr(hostio_addr),
    .hostio_idata(hostio_idata),
    .hostio_odata(hostio_odata),
    .hostio_rd(hostio_rd),
    .hostio_wr(hostio_wr),

    // keyboard interface
    .keyboard_keys(keyboard_keys)// {reserved,left,right,up,down,enter}
);

fakesd sdcard(.cs_n(sd_dat3), .clk(sd_clk), .mosi(sd_cmd), .miso(sd_dat));

reg [3:0] clk_counter = 0;
always @(posedge clk) clk_counter <= clk_counter + 1;
wire access_slot = clk_counter[3:0] == 4'b1111;

endmodule

module fakesd(input cs_n, input clk, input mosi, output miso);
reg [63:0] rxreg = 0;
reg [63:0] txreg = 64'h0;

integer bitcount;

assign miso = txreg[63];


always @(posedge cs_n)
    $display("bitcount=", bitcount);

always @(posedge clk)
    if (~cs_n) begin
        rxreg <= {rxreg[62:0],mosi};
        txreg <= {txreg[62:0],1'b1};
        bitcount <= bitcount + 1;
        if (rxreg[7:0] == 8'h95) txreg <= 64'hff01ffffffffffff;
        //$write("%d", miso);
    end
    else begin
        bitcount <= 0;
        //$display("reset");
        rxreg <= 0;
        txreg <= 64'h01ffffffffffffff;
        bitcount <= 0;
    end
endmodule

