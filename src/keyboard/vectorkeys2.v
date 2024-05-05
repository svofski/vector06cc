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
// Design File: vectorkeys.v
//
// Keyboard interface. This module maps PS/2 keyboard keypresses
// and releases into a keyboard matrix model used in Vector-06C.
// 
// Can be optimized space-wise by reducing the giant rowbits
// expression into a sequential process. 
//
// See http://www.quadibloc.com/comp/scan.htm
// for information about why shift key is being de-pressed and pressed 
// when grey arrows are pressed
//
// --------------------------------------------------------------------

`include "config.v"

//`default_nettype none
module vectorkeys(clkk, reset, ps2_clk, ps2_dat,
    ext_scancode_i, ext_scancode_ready_i,
    mod_rus, rowselect, rowbits, key_shift, key_ctrl, key_rus, key_blksbr, 
    key_blkvvod, key_bushold, key_osd, osd_active);
input                   clkk;
input                   reset;
input                   ps2_clk;
input                   ps2_dat;
input [7:0]             ext_scancode_i;         // from debug probe
input                   ext_scancode_ready_i;   // from debug probe

input                   mod_rus;                // RUS on

input [7:0]             rowselect;              // PA output inverted
output[7:0]             rowbits;                // PB input  inverted
output                  key_shift;
output                  key_ctrl;
output                  key_rus;
output                  key_blksbr;
output                  key_blkvvod;
output                  key_bushold;
output reg[5:0]         key_osd;
input                   osd_active;

reg             ps2rden;
wire            ps2dsr;
wire [7:0]      ps2q;

`ifdef WITH_KEYBOARD_PS2
ps2k ps2driver(clkk, reset, ps2_clk, ps2_dat, ps2rden, ps2q, ps2dsr);
`endif

`ifdef WITH_KEYBOARD_SERIAL
reg [7:0] ext_scancode_r;
reg       ext_dsr_r;

assign    ps2dsr = ext_dsr_r;
assign    ps2q = ext_scancode_r;

always @(posedge clkk)
begin
    if (reset)
        {ext_dsr_r, ext_scancode_r} <= 9'b0;
    if (ext_scancode_ready_i)
        {ext_dsr_r, ext_scancode_r} <= {1'b1, ext_scancode_i};
    if (ps2rden)
        ext_dsr_r <= 1'b0;
end

`endif

reg             qey_shift = 0;
reg             key_ctrl = 0;
reg             key_rus = 0;
reg             key_blksbr = 0;
reg             key_blkvvod = 0;
reg             key_bushold = 0;

wire [2:0]      matrix_row;             // row of decoded key
wire [2:0]      matrix_col;             // col of decoded key
wire            matrix_shift;
wire            neo_raw;                // not in matrix
wire            neo = osd_active | neo_raw;
wire [7:0]      decoded_col;

reg             qmatrix_shift;
reg             saved_ps2_shift;        // when a key requiring shift-play is pressed, shift
                                        // flag must be remembered until its release, otherwise
                                        // wrong release code is detected
assign  key_shift = (qey_shift|saved_ps2_shift) ^ qmatrix_shift; 

scan2matrix scan2xy(
    .c(clkk), 
    .scancode(ps2q), 
    .mod_shift(saved_ps2_shift|qey_shift), 
    .mod_rus(mod_rus), 
    .qrow(matrix_row), 
    .qcol(matrix_col),
    .qshift(matrix_shift), 
    .qerror(neo_raw));


keycolumndecoder column_dc1(matrix_col, decoded_col);


wire    saved_shift;                    // grey arrow keys send break-shift code and then make shift after release
reg     saved_shift_trigger;

reg [8:0] slow_ce_ctr;
always  @(posedge clkk) slow_ce_ctr <= slow_ce_ctr + 1'b1;
wire    slow_ce = slow_ce_ctr == 0;
oneshot #(255) shitshot(clkk, slow_ce, saved_shift_trigger, saved_shift);

reg [3:0] state = 0;
reg [7:0] tmp;

wire [2:0] kmaddr_wr = matrix_row;
reg [2:0] kmaddr_rd;


reg       km_wr;
reg [7:0] km_wrdata;
wire[7:0] km_data;

wire [2:0] km_addr = km_wr ? kmaddr_wr : kmaddr_rd;

keymatrix_ram km(.clk(clkk), 
    .addr(km_addr), 
    .wr(km_wr),
    .data_i(km_wrdata),
    .data_o(km_data));

always @(posedge clkk) 
begin
    if (reset)
    begin
        qey_shift    <= 0;
        key_ctrl     <= 0;
        key_rus      <= 0;
        key_blksbr   <= 0;
        key_blkvvod  <= 0;
        key_bushold  <= 0;
        key_osd      <= 0;
        saved_shift_trigger <= 0;
        state <= 0;
    end 
    else 
    begin
        //km_wr <= 1'b0;

        case (state)
            0: 
            begin
                state <= 10;
                km_wr <= 1'b0;
            end

            10: 
            if (ps2dsr)
            begin
                ps2rden <= 1;
                state <= 1;
            end

            1: 
            begin
                state <= 2;
                ps2rden <= 0;
            end

            2:
            begin
                state <= 3;
            end
            3:
            begin
                ps2rden <= 0;
                tmp <= km_data; // = keymatrix[matrix_row];
                if (ps2q == 8'hF0)    // break code
                    state <= 5;
                else 
                    state <= 4;
            end

            4:
            begin
                case(ps2q)
                    8'h12:  qey_shift <= 1;
                    8'h59:  qey_shift <= 1;
                    8'h14:  key_ctrl  <= 1;
                    8'h58:  key_rus   <= 1;
                    8'h78:  key_blkvvod <= 1;
                    8'h07:  key_blksbr<= 1; // F12
                    8'h7E:  key_bushold <= 1;
                    // special treatment of grey arrow keys
                    8'hE0:;
                    default: 
                        begin
                            case (ps2q) 
                                8'h75,8'h72,8'h6b,8'h74: qey_shift <= saved_shift;
                            endcase

                            case (ps2q) 
                                8'h75:  key_osd[2] <= osd_active;
                                8'h72:  key_osd[1] <= osd_active;
                                8'h6b:  key_osd[4] <= osd_active;
                                8'h74:  key_osd[3] <= osd_active;
                                8'h5a:  key_osd[0] <= osd_active;
                            endcase

                            if (!neo)
                            begin
                                //keymatrix[matrix_row] <= tmp | decoded_col;
                                km_wrdata <= tmp | decoded_col;
                                km_wr <= 1'b1;

                                qmatrix_shift <= qmatrix_shift | matrix_shift;
                                if (matrix_shift) saved_ps2_shift <= qey_shift;
                            end
                        end
                endcase
                saved_shift_trigger     <= 0;
                state <= 0;
            end

            5:  // break code
            if (ps2dsr)
            begin
                ps2rden <= 1;
                state <= 6;
            end

            6:
            begin
                ps2rden <= 0;
                state <= 7;
            end

            7:
            begin
                state <= 8;
            end

            8:
            begin
                tmp <= km_data; //keymatrix[matrix_row];
                state <= 9;
            end

            9:
            begin
                case(ps2q)
                    8'h12,8'h59: // LSHIFT, RSHIFT
                        begin 
                            qey_shift <= 1'b0;//saved_ps2_shift; 
                            saved_shift_trigger <= 1'b1; 
                        end
                    8'h14:  key_ctrl    <= 0;
                    8'h58:  key_rus     <= 0;
                    8'h78:  key_blkvvod <= 0;
                    8'h07:  key_blksbr  <= 0;
                    8'h7E:  key_bushold <= 0;
                    8'hE0:  ;// do nada plz
                    default: 
                        begin
                            case (ps2q) 
                                8'h75:  key_osd[2] <= 0;
                                8'h72:  key_osd[1] <= 0;
                                8'h6b:  key_osd[4] <= 0;
                                8'h74:  key_osd[3] <= 0;
                                8'h5a:  key_osd[0] <= 0;
                            endcase

                            if (!neo)
                            begin
                                //keymatrix[matrix_row] <=  tmp & ~decoded_col;
                                km_wrdata <= tmp & ~decoded_col;
                                km_wr <= 1'b1;

                                if (saved_ps2_shift & matrix_shift) 
                                    saved_ps2_shift <= 1'b0;
                                qmatrix_shift <= 1'b0;
                            end
                        end
                endcase
                state <= 0;
            end
        endcase
    end
end

reg  [7:0]      rowbits;

reg [2:0] kmaddr_rd = 0;
reg [7:0] accu;
always @(posedge clkk)
    if (state == 10)
    begin
        kmaddr_rd <= kmaddr_rd + 1'b1;
        if (kmaddr_rd == 3'h0)
        begin
            rowbits <= accu;
            accu <= rowselect[7] ? km_data : 8'h0;
        end
        else
            accu <= accu | (rowselect[kmaddr_rd - 1'b1] ? km_data : 8'h0);
    end

endmodule


module keycolumndecoder(d,q);
input [2:0] d;
output reg[7:0] q;

always @*
    case (d)
    3'b000: q <= 8'b00000001;
    3'b001: q <= 8'b00000010;
    3'b010: q <= 8'b00000100;
    3'b011: q <= 8'b00001000;
    3'b100: q <= 8'b00010000;
    3'b101: q <= 8'b00100000;
    3'b110: q <= 8'b01000000;
    3'b111: q <= 8'b10000000;
    endcase
endmodule


module keymatrix_ram(
    input clk, 
    input [2:0] addr, 
    input wr,
    input [7:0] data_i,
    output reg [7:0] data_o);

reg [7:0] data [0:7];

always @(posedge clk)
begin
    if (wr)
        data[addr] <= data_i;
    else
        data_o <= data[addr];
end

endmodule


// $Id$
