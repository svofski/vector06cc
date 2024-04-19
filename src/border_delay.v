// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                Copyright (C) 2007-2009 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Authors: Ivan Gorodetsky, Viacheslav Slavinsky, http://sensi.org/~svo
//
// Design File: border_delay.v
//
// --------------------------------------------------------------------

//`default_nettype none

module border_delay(input wire clk, input wire ce, input wire[3:0] i_borderindex, output wire[3:0] o_delayed);
parameter DELAY = 10;
    reg[DELAY-1:0] bob[3:0];
    always @(posedge clk)
        if (ce)
        begin
            bob[0] <= {bob[0][DELAY-2:0], i_borderindex[0]};
            bob[1] <= {bob[1][DELAY-2:0], i_borderindex[1]};
            bob[2] <= {bob[2][DELAY-2:0], i_borderindex[2]};
            bob[3] <= {bob[3][DELAY-2:0], i_borderindex[3]};
        end
    assign o_delayed = {bob[3][DELAY-1], bob[2][DELAY-1], bob[1][DELAY-1], bob[0][DELAY-1]};
endmodule

