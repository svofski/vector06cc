// ====================================================================
//                          VECTOR-06C FPGA REPLICA
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
// Design File: scan2matrix.v
//
// Convert PS/2 scancodes into Vector-06C keyboard matrix coordinates.
//
// --------------------------------------------------------------------

module scan2matrix(
    input                   c,
    input [7:0]             scancode,
    input                   mod_shift,
    input                   mod_rus,
    output  reg[2:0]        qrow,
    output  reg[2:0]        qcol,
    output  reg             qshift,
    output  reg             qerror);

wire[7:0] kr_none;
wire[7:0] kr_shift;

krom1 kromkrom1(c, 1'b1, scancode, kr_none);
krom2 kromshift(c, 1'b1, scancode, kr_shift);

always @*
    if (mod_shift) begin
        qrow   <=  kr_shift[6:4];
        qcol   <=  kr_shift[2:0];
        qshift <=  kr_shift[7];
        qerror <=  &kr_shift;
    end 
    else 
    begin
        qrow   <=  kr_none[6:4];
        qcol   <=  kr_none[2:0];
        qshift <=  kr_none[7];
        qerror <=  &kr_none;
    end

endmodule


module krom1(input clk, input en, input [7:0] addr, output reg [7:0] q); /*synthesis syn_romstyle=block_rom*/

reg [7:0] data [255:0];

integer i;
always @(posedge clk)
begin
    for (i = 0; i < 255; i = i + 1)
        data[i] <= 8'hff;
    
    /*F5*/  data[8'h3 ] <=  8'h17;
    /*F3*/  data[8'h4 ] <=  8'h15;
    /*F1*/  data[8'h5 ] <=  8'h13;
    /*F2*/  data[8'h6 ] <=  8'h14;
    /*F4*/  data[8'hC ] <=  8'h16;
    /*TAB*/ data[8'hD ] <=  8'h00;
    /*ALT*/ data[8'h11] <= 8'h01; // PS
    /*Q*/   data[8'h15] <= 8'h61;
    /*1!*/  data[8'h16] <= 8'h21;
    /*Z*/   data[8'h1A] <= 8'h72;
    /*S*/   data[8'h1B] <= 8'h63;
    /*A*/   data[8'h1C] <= 8'h41;
    /*W*/   data[8'h1D] <= 8'h67;
    /*2@*/  data[8'h1E] <= 8'h22;
    /*C*/   data[8'h21] <= 8'h43;
    /*X*/   data[8'h22] <= 8'h70;
    /*D*/   data[8'h23] <= 8'h44;
    /*E*/   data[8'h24] <= 8'h45;
    /*4$*/  data[8'h25] <= 8'h24;
    /*3#*/  data[8'h26] <= 8'h23;
    /*]*/   data[8'h29] <= 8'h77;
    /*V*/   data[8'h2A] <= 8'h66;
    /*F*/   data[8'h2B] <= 8'h46;
    /*T*/   data[8'h2C] <= 8'h64;
    /*R*/   data[8'h2D] <= 8'h62;
    /*5%*/  data[8'h2E] <= 8'h25;
    /*N*/   data[8'h31] <= 8'h56;
    /*B*/   data[8'h32] <= 8'h42;
    /*H*/   data[8'h33] <= 8'h50;
    /*G*/   data[8'h34] <= 8'h47;
    /*Y*/   data[8'h35] <= 8'h71;
    /*6^*/  data[8'h36] <= 8'h26;
    /*M*/   data[8'h3A] <= 8'h55;
    /*J*/   data[8'h3B] <= 8'h52;
    /*U*/   data[8'h3C] <= 8'h65;
    /*7&*/  data[8'h3D] <= 8'h27;
    /*8**/  data[8'h3E] <= 8'h30;
    /*,<*/  data[8'h41] <= 8'h34;
    /*K*/   data[8'h42] <= 8'h53;
    /*I*/   data[8'h43] <= 8'h51;
    /*O*/   data[8'h44] <= 8'h57;
    /*0)*/  data[8'h45] <= 8'h20;
    /*9(*/  data[8'h46] <= 8'h31;
    /*.>*/  data[8'h49] <= 8'h36;
    /*/?*/  data[8'h4A] <= 8'h37;
    /*L*/   data[8'h4B] <= 8'h54;
    /*;:*/  data[8'h4C] <= 8'h33;
    /*P*/   data[8'h4D] <= 8'h60;
    /*-_*/  data[8'h4E] <= 8'h35;
    /*'"*/  data[8'h52] <= 8'hA7;          //+
    /*[*/   data[8'h54] <= 8'h73;
    /*=+*/  data[8'h55] <= 8'hB5;          //+
    /*ENTR*/data[8'h5A] <= 8'h02;
    /*]*/   data[8'h5B] <= 8'h75;
    /*\*/   data[8'h5D] <= 8'h74;
    /*BS*/  data[8'h66] <= 8'h03;
    /*LT*/  data[8'h6B] <= 8'h04;
    /*HOME*/data[8'h6C] <= 8'h10;
    /*DEL*/ data[8'h71] <= 8'h11;
    /*DN*/  data[8'h72] <= 8'h07;
    /*RT*/  data[8'h74] <= 8'h06;
    /*UP*/  data[8'h75] <= 8'h05;
    /*ESC*/ data[8'h76] <= 8'h12;
    /*`~*/  data[8'h0E] <= 8'hC0;          //+
end

always @(posedge clk)
    if (en)
        q <= data[addr];

`ifdef FECK
always @(posedge clk)
    if (en)
    case (addr)
        default:  q <=      8'hFF;
    /*F5*/  8'h3: q <=      8'h17;
    /*F3*/  8'h4: q <=      8'h15;
    /*F1*/  8'h5: q <=      8'h13;
    /*F2*/  8'h6: q <=      8'h14;
    /*F4*/  8'hC: q <=      8'h16;
    /*TAB*/ 8'hD: q <=      8'h00;
    /*ALT*/ 8'h11: q <=     8'h01; // PS
    /*Q*/   8'h15: q <=     8'h61;
    /*1!*/  8'h16: q <=     8'h21;
    /*Z*/   8'h1A: q <=     8'h72;
    /*S*/   8'h1B: q <=     8'h63;
    /*A*/   8'h1C: q <=     8'h41;
    /*W*/   8'h1D: q <=     8'h67;
    /*2@*/  8'h1E: q <=     8'h22;
    /*C*/   8'h21: q <=     8'h43;
    /*X*/   8'h22: q <=     8'h70;
    /*D*/   8'h23: q <=     8'h44;
    /*E*/   8'h24: q <=     8'h45;
    /*4$*/  8'h25: q <=     8'h24;
    /*3#*/  8'h26: q <=     8'h23;
    /*]*/   8'h29: q <=     8'h77;
    /*V*/   8'h2A: q <=     8'h66;
    /*F*/   8'h2B: q <=     8'h46;
    /*T*/   8'h2C: q <=     8'h64;
    /*R*/   8'h2D: q <=     8'h62;
    /*5%*/  8'h2E: q <=     8'h25;
    /*N*/   8'h31: q <=     8'h56;
    /*B*/   8'h32: q <=     8'h42;
    /*H*/   8'h33: q <=     8'h50;
    /*G*/   8'h34: q <=     8'h47;
    /*Y*/   8'h35: q <=     8'h71;
    /*6^*/  8'h36: q <=     8'h26;
    /*M*/   8'h3A: q <=     8'h55;
    /*J*/   8'h3B: q <=     8'h52;
    /*U*/   8'h3C: q <=     8'h65;
    /*7&*/  8'h3D: q <=     8'h27;
    /*8**/  8'h3E: q <=     8'h30;
    /*,<*/  8'h41: q <=     8'h34;
    /*K*/   8'h42: q <=     8'h53;
    /*I*/   8'h43: q <=     8'h51;
    /*O*/   8'h44: q <=     8'h57;
    /*0)*/  8'h45: q <=     8'h20;
    /*9(*/  8'h46: q <=     8'h31;
    /*.>*/  8'h49: q <=     8'h36;
    /*/?*/  8'h4A: q <=     8'h37;
    /*L*/   8'h4B: q <=     8'h54;
    /*;:*/  8'h4C: q <=     8'h33;
    /*P*/   8'h4D: q <=     8'h60;
    /*-_*/  8'h4E: q <=     8'h35;
    /*'"*/  8'h52: q <=     8'hA7;          //+
    /*[*/   8'h54: q <=     8'h73;
    /*=+*/  8'h55: q <=     8'hB5;          //+
    /*ENTR*/8'h5A: q <=     8'h02;
    /*]*/   8'h5B: q <=     8'h75;
    /*\*/   8'h5D: q <=     8'h74;
    /*BS*/  8'h66: q <=     8'h03;
    /*LT*/  8'h6B: q <=     8'h04;
    /*HOME*/8'h6C: q <=     8'h10;
    /*DEL*/ 8'h71: q <=     8'h11;
    /*DN*/  8'h72: q <=     8'h07;
    /*RT*/  8'h74: q <=     8'h06;
    /*UP*/  8'h75: q <=     8'h05;
    /*ESC*/ 8'h76: q <=     8'h12;
    /*`~*/  8'h0E: q <=     8'hC0;          //+
    endcase
`endif
endmodule



module krom2(input clk, input en, input [7:0] addr, output reg[7:0] q); /*synthesis syn_romstyle=block_rom*/

reg [7:0] data [255:0];

integer i;
always @(posedge clk)
begin
    for (i = 0; i < 255; i = i + 1)
        data[i] <= 8'hff;

    /*F5*/  data[8'h3 ] <=  8'h17;
    /*F3*/  data[8'h4 ] <=  8'h15;
    /*F1*/  data[8'h5 ] <=  8'h13;
    /*F2*/  data[8'h6 ] <=  8'h14;
    /*F4*/  data[8'hC ] <=  8'h16;
    /*TAB*/ data[8'hD ] <=  8'h00;
    /*ALT*/ data[8'h11] <= 8'h01; // PS
    /*Q*/   data[8'h15] <= 8'h61;
    /*1!*/  data[8'h16] <= 8'h21;
    /*Z*/   data[8'h1A] <= 8'h72;
    /*S*/   data[8'h1B] <= 8'h63;
    /*A*/   data[8'h1C] <= 8'h41;
    /*W*/   data[8'h1D] <= 8'h67;
    /*2@*/  data[8'h1E] <= 8'hC0;          //x-shift
    /*C*/   data[8'h21] <= 8'h43;
    /*X*/   data[8'h22] <= 8'h70;
    /*D*/   data[8'h23] <= 8'h44;
    /*E*/   data[8'h24] <= 8'h45;
    /*4$*/  data[8'h25] <= 8'h24;
    /*3#*/  data[8'h26] <= 8'h23;
    /*]*/   data[8'h29] <= 8'h77;
    /*V*/   data[8'h2A] <= 8'h66;
    /*F*/   data[8'h2B] <= 8'h46;
    /*T*/   data[8'h2C] <= 8'h64;
    /*R*/   data[8'h2D] <= 8'h62;
    /*5%*/  data[8'h2E] <= 8'h25;
    /*N*/   data[8'h31] <= 8'h56;
    /*B*/   data[8'h32] <= 8'h42;
    /*H*/   data[8'h33] <= 8'h50;
    /*G*/   data[8'h34] <= 8'h47;
    /*Y*/   data[8'h35] <= 8'h71;
    /*6^*/  data[8'h36] <= 8'hF6;          // x-shift
    /*M*/   data[8'h3A] <= 8'h55;
    /*J*/   data[8'h3B] <= 8'h52;
    /*U*/   data[8'h3C] <= 8'h65;
    /*7&*/  data[8'h3D] <= 8'h26;
    /*8**/  data[8'h3E] <= 8'h32;
    /*,<*/  data[8'h41] <= 8'h34;
    /*K*/   data[8'h42] <= 8'h53;
    /*I*/   data[8'h43] <= 8'h51;
    /*O*/   data[8'h44] <= 8'h57;
    /*0)*/  data[8'h45] <= 8'h31;
    /*9(*/  data[8'h46] <= 8'h30;
    /*.>*/  data[8'h49] <= 8'h36;
    /*/?*/  data[8'h4A] <= 8'h37;
    /*L*/   data[8'h4B] <= 8'h54;
    /*;:*/  data[8'h4C] <= 8'hB2;  // x-shift
    /*P*/   data[8'h4D] <= 8'h60;
    /*-_*/  data[8'h4E] <= 8'h03;  // underscore
    /*'"*/  data[8'h52] <= 8'h22;  // +
    /*[*/   data[8'h54] <= 8'h73;
    /*=+*/  data[8'h55] <= 8'h33;
    /*ENTR*/data[8'h5A] <= 8'h02;
    /*]*/   data[8'h5B] <= 8'h75;
    /*\*/   data[8'h5D] <= 8'h74;
    /*BS*/  data[8'h66] <= 8'h03;
    /*LT*/  data[8'h6B] <= 8'h04;
    /*HOME*/data[8'h6C] <= 8'h10;
    /*DEL*/ data[8'h71] <= 8'h11;
    /*DN*/  data[8'h72] <= 8'h07;
    /*RT*/  data[8'h74] <= 8'h06;
    /*UP*/  data[8'h75] <= 8'h05;
    /*ESC*/ data[8'h76] <= 8'h12;
    /*`~*/  data[8'h0E] <= 8'h76;
end

always @(posedge clk)
    if (en)
        q <= data[addr];

`ifdef FECK
always @(posedge clk)
    if (en)
    case (addr)
        default:  q <=      8'hFF;
    /*F5*/  8'h3: q <=      8'h17;
    /*F3*/  8'h4: q <=      8'h15;
    /*F1*/  8'h5: q <=      8'h13;
    /*F2*/  8'h6: q <=      8'h14;
    /*F4*/  8'hC: q <=      8'h16;
    /*TAB*/ 8'hD: q <=      8'h00;
    /*ALT*/ 8'h11: q <=     8'h01; // PS
    /*Q*/   8'h15: q <=     8'h61;
    /*1!*/  8'h16: q <=     8'h21;
    /*Z*/   8'h1A: q <=     8'h72;
    /*S*/   8'h1B: q <=     8'h63;
    /*A*/   8'h1C: q <=     8'h41;
    /*W*/   8'h1D: q <=     8'h67;
    /*2@*/  8'h1E: q <=     8'hC0;          //x-shift
    /*C*/   8'h21: q <=     8'h43;
    /*X*/   8'h22: q <=     8'h70;
    /*D*/   8'h23: q <=     8'h44;
    /*E*/   8'h24: q <=     8'h45;
    /*4$*/  8'h25: q <=     8'h24;
    /*3#*/  8'h26: q <=     8'h23;
    /*]*/   8'h29: q <=     8'h77;
    /*V*/   8'h2A: q <=     8'h66;
    /*F*/   8'h2B: q <=     8'h46;
    /*T*/   8'h2C: q <=     8'h64;
    /*R*/   8'h2D: q <=     8'h62;
    /*5%*/  8'h2E: q <=     8'h25;
    /*N*/   8'h31: q <=     8'h56;
    /*B*/   8'h32: q <=     8'h42;
    /*H*/   8'h33: q <=     8'h50;
    /*G*/   8'h34: q <=     8'h47;
    /*Y*/   8'h35: q <=     8'h71;
    /*6^*/  8'h36: q <=     8'hF6;          // x-shift
    /*M*/   8'h3A: q <=     8'h55;
    /*J*/   8'h3B: q <=     8'h52;
    /*U*/   8'h3C: q <=     8'h65;
    /*7&*/  8'h3D: q <=     8'h26;
    /*8**/  8'h3E: q <=     8'h32;
    /*,<*/  8'h41: q <=     8'h34;
    /*K*/   8'h42: q <=     8'h53;
    /*I*/   8'h43: q <=     8'h51;
    /*O*/   8'h44: q <=     8'h57;
    /*0)*/  8'h45: q <=     8'h31;
    /*9(*/  8'h46: q <=     8'h30;
    /*.>*/  8'h49: q <=     8'h36;
    /*/?*/  8'h4A: q <=     8'h37;
    /*L*/   8'h4B: q <=     8'h54;
    /*;:*/  8'h4C: q <=     8'hB2;  // x-shift
    /*P*/   8'h4D: q <=     8'h60;
    /*-_*/  8'h4E: q <=     8'h03;  // underscore
    /*'"*/  8'h52: q <=     8'h22;  // +
    /*[*/   8'h54: q <=     8'h73;
    /*=+*/  8'h55: q <=     8'h33;
    /*ENTR*/8'h5A: q <=     8'h02;
    /*]*/   8'h5B: q <=     8'h75;
    /*\*/   8'h5D: q <=     8'h74;
    /*BS*/  8'h66: q <=     8'h03;
    /*LT*/  8'h6B: q <=     8'h04;
    /*HOME*/8'h6C: q <=     8'h10;
    /*DEL*/ 8'h71: q <=     8'h11;
    /*DN*/  8'h72: q <=     8'h07;
    /*RT*/  8'h74: q <=     8'h06;
    /*UP*/  8'h75: q <=     8'h05;
    /*ESC*/ 8'h76: q <=     8'h12;
    /*`~*/  8'h0E: q <=     8'h76;
    endcase
`endif

endmodule


// $Id$
