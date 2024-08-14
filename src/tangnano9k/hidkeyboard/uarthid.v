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
// Author: Viacheslav Slavinsky
// 
// Design File: uarthid.v
//
// Receive the entire state of v06c keyboard matrix on a UART pin
// 10 bytes: 0xAC [modkeys] [R0] [R1] [R2] [R3] [R4] [R5] [R6] [R7]
//
// Everything is active high, nothing pressed == 0
//
// 7 6 5 4 3 2 1 0
// | | | : | | | +--- VVOD
// | | | : | | +----- SBROS
// | | | : | +------- OSD (ScrollLock)
// | | | : +--------- PAUSE
// | | | + -- -- -- - ???
// | | +------------- SS
// | +--------------- US
// +----------------- RUS/LAT
//
// Matrix scan:
// [7:0] rowselect from v06c
// [7:0] o_rowbits to v06c
// --------------------------------------------------------------------

module uarthid
#(
    parameter CLK_FRE = 24,         // clock frequency (MHz)
    parameter BAUD_RATE = 115200    // serial baud rate
)
(
    input          clk,
    input          reset,
    input          uart_rx,
    input    [7:0] i_rowselect,
    output   [7:0] o_rowbits,

    input          i_mod_rus,

    output         o_key_shift,
    output         o_key_ctrl,
    output         o_key_rus,
    output         o_key_blksbr,
    output         o_key_blkvvod,
    output         o_key_bushold,
    output   [5:0] o_key_osd,
    input          i_osd_active,

    output   [7:0] o_debug
);

wire  [7:0] rx_data;              // data from hid adapter
wire        rx_data_valid;        // rx_data contains received byte
wire        rx_data_ready = 1'b1; // always ready to receive

uart_rx#(.CLK_FRE(CLK_FRE),.BAUD_RATE(BAUD_RATE)) uart_rx_hid
(
    .clk(clk),
    .rst_n(~reset),
    .rx_data(rx_data),
    .rx_data_valid(rx_data_valid),
    .rx_data_ready(rx_data_ready),
    .rx_pin(uart_rx)
);

localparam MATRIX_BITS = 8 * 9;   // keyboard matrix is 8 bytes, plus 1 for modkeys, total of 72 bits

reg [MATRIX_BITS - 1: 0] packet;   // 9 bytes
reg [MATRIX_BITS - 1: 0] packet_r; // valid packet


wire [63:0] matrix  = packet_r[63:0];
wire  [7:0] modkeys = packet_r[71:64];


localparam ST_WAIT =    10'b0_0000_0000_1;

reg  [9:0] state;
wire [9:0] nextstate = {state[8:0],state[9]};

wire [MATRIX_BITS - 1: 0] nextpacket = {packet[MATRIX_BITS-8-1:0], rx_data};

always @(posedge clk)
begin
    if (reset) 
    begin
        packet <= 72'h0;
        packet_r <= 72'h0;
        state <= ST_WAIT;
    end
    else
    begin
        if (rx_data_valid) 
        begin
            state <= nextstate;
            case (state)
                ST_WAIT:    if (rx_data != 8'hac) state <= ST_WAIT;   // packet id
                default:    begin
                                packet <= nextpacket;
                                if (nextstate == ST_WAIT) packet_r <= nextpacket;
                            end
            endcase
        end
    end
end

reg [7:0] debug_r;
assign o_debug = debug_r;

always @(posedge clk)
    debug_r <= modkeys;

hid_keyboard_matrix hidkbdmatrix(
    .clk(clk),
    .reset(reset),
    .matrix(matrix),
    .modkeys(modkeys),
    .i_rowselect(i_rowselect),        // <- VV55 PA
    .o_rowbits(o_rowbits),            // -> VV55 PB

    .i_mod_rus(i_mod_rus),            // ?? probably unused

    .o_key_shift(o_key_shift),
    .o_key_ctrl(o_key_ctrl),
    .o_key_rus(o_key_rus),            // F6/npi?
    .o_key_blksbr(o_key_blksbr),      // F12
    .o_key_blkvvod(o_key_blkvvod),    // F11
    .o_key_bushold(o_key_bushold),    // keyboard pause
    .o_key_osd(o_key_osd),            // grey arrows if i_osd_active
    .i_osd_active(i_osd_active)       // indicates that osd is active
);

endmodule
