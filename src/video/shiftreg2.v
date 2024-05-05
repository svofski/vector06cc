// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//              Copyright (C) 2007, Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Design File: shiftreg2.v
//
// A parallel-load 1-bit shift-out register with (semi) asynchronous load.
//
// --------------------------------------------------------------------

module shiftreg2(clk, ce, din, wr, shiftout);
input clk;
input ce;
input [7:0] din;
input wr;
output reg shiftout;

reg [7:0] data;

always @(posedge clk) begin
    if (wr) begin
        data <= {din[6:0],1'b0};
        shiftout <= din[7];
    end
    else begin 
        if (ce) begin
            shiftout <= data[7];
            data <= data << 1;
        end
    end
end

endmodule

// $Id$
