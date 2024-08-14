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
// Design File: hidmatrix.v
//
// Adapt HID keyboard state to v06c bus.
//
// --------------------------------------------------------------------

module hid_keyboard_matrix(
    input           clk,
    input           reset,
    input    [63:0] matrix,           // main keyboard matrix, active high
    input     [7:0] modkeys,          // mod keys (see uarthid.v)
    input     [7:0] i_rowselect,      // from vv55 row select
    output    [7:0] o_rowbits,        // to vv55 active bits

    input           i_mod_rus,        // RUS LED

    output          o_key_shift,
    output          o_key_ctrl,
    output          o_key_rus,
    output          o_key_blksbr,
    output          o_key_blkvvod,
    output          o_key_bushold,
    output    [5:0] o_key_osd,        // {?, left, right, up, down, enter}
    input           i_osd_active
);

// i_rowselect is active 1, rowbits active 1
wire [7:0] rows [0:7];
assign rows[7] = matrix[(0 + 1) * 8 - 1:0 * 8];
assign rows[6] = matrix[(1 + 1) * 8 - 1:1 * 8]; 
assign rows[5] = matrix[(2 + 1) * 8 - 1:2 * 8];
assign rows[4] = matrix[(3 + 1) * 8 - 1:3 * 8];
assign rows[3] = matrix[(4 + 1) * 8 - 1:4 * 8];
assign rows[2] = matrix[(5 + 1) * 8 - 1:5 * 8];
assign rows[1] = matrix[(6 + 1) * 8 - 1:6 * 8];
assign rows[0] = matrix[(7 + 1) * 8 - 1:7 * 8];

reg [7:0] rowbits;
assign o_rowbits = rowbits;

always @(posedge clk)
begin
    if (reset) 
        rowbits <= 8'h00;
    else
        rowbits <=
              ({8{i_rowselect[0]}} & rows[0])
            | ({8{i_rowselect[1]}} & rows[1]) 
            | ({8{i_rowselect[2]}} & rows[2]) 
            | ({8{i_rowselect[3]}} & rows[3]) 
            | ({8{i_rowselect[4]}} & rows[4]) 
            | ({8{i_rowselect[5]}} & rows[5]) 
            | ({8{i_rowselect[6]}} & rows[6]) 
            | ({8{i_rowselect[7]}} & rows[7]);
end

localparam VVOD = 0;
localparam SBROS = 1;
localparam OSDKEY = 2;
localparam PAUSEKEY = 3;
localparam SS = 5;
localparam US = 6;
localparam RUSLAT = 7;

assign o_key_shift = modkeys[SS];
assign o_key_ctrl  = modkeys[US];
assign o_key_rus   = modkeys[RUSLAT];
assign o_key_blkvvod = modkeys[VVOD];
assign o_key_blksbr = modkeys[SBROS];
assign o_key_bushold = modkeys[OSDKEY];

// map arrow keys and Enter to OSD joystick
assign o_key_osd = {6{i_osd_active}} & {rows[0][4],rows[0][6],rows[0][5],rows[0][7],rows[0][2]};

endmodule



