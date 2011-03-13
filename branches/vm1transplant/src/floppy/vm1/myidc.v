// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008 Viacheslav Slavinsky
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 Instruction Decoder
// --------------------------------------------------------

`default_nettype none
`include "opc.h"

module idc (
        idc_opc , 
        unused , 
        cco , 
        bra , 
        nof ,
        rsd , 
        dop , 
        sop , 
        op_decoded );


   input [15:0] idc_opc;
   
   output   unused;
   output   cco;
   output   bra;
   output   nof;
   output   rsd;
   output   dop;
   output   sop;
 
   output   [`IDC_NOPS:0] op_decoded;

   wire [2:0]   double_op;
   wire [5:0]   single_op;
   wire     byte_flag;
   wire     branches;
   wire     not_double;
    
   assign   byte_flag =  idc_opc[15];   
   assign   double_op =  idc_opc[14:12];
   assign   single_op =  idc_opc[11:6];

   assign   not_double = (double_op == 3'b000);
   
   wire     dmov = (double_op == 3'b001);
   wire     dcmp = (double_op == 3'b010);
   wire     dbit = (double_op == 3'b011);
   wire     dbic = (double_op == 3'b100);
   wire     dbis = (double_op == 3'b101);
   wire     dadd = (double_op == 3'b110) & ~byte_flag ;
   wire     dsub = (double_op == 3'b110) & byte_flag ;


   wire     dswab = (not_double & (single_op == 3) & ~byte_flag);
   wire     djmp = not_double & (single_op == 1) & ~byte_flag;
   wire     drts = not_double & (single_op == 'o02) & ~byte_flag & 
        (idc_opc[5:3] == 0);
   wire     dspl = not_double & (single_op == 'o02) & ~byte_flag &
        (idc_opc[5:3] == 3'o3);
   
   assign   branches = not_double & (single_op == 3) & byte_flag;   

   wire     dclr = not_double & (single_op == 'o050);
   wire     dcom = not_double & (single_op == 'o051);
   wire     dinc = not_double & (single_op == 'o052);
   wire     ddec = not_double & (single_op == 'o053);
   wire     dneg = not_double & (single_op == 'o054);
   wire     dadc = not_double & (single_op == 'o055);
   wire     dsbc = not_double & (single_op == 'o056);
   wire     dtst = not_double & (single_op == 'o057);   
   wire     dror = not_double & (single_op == 'o060);
   wire     drol = not_double & (single_op == 'o061);
   wire     dasr = not_double & (single_op == 'o062);
   wire     dasl = not_double & (single_op == 'o063);

   wire     dmark = ~byte_flag & not_double & (single_op == 'o064);
   wire     dmfpi = ~byte_flag & not_double & (single_op == 'o065); // not on VM1
   wire     dmtpi = ~byte_flag & not_double & (single_op == 'o066); // not on VM1
   wire     dsxt  = ~byte_flag & not_double & (single_op == 'o067);   
   

   wire     drtt = (idc_opc[15:0])==({1'b0,15'b000000000000110});
   wire     dreset = (idc_opc[15:0])==({1'b0,15'b000000000000101});
   wire     diot = (idc_opc[15:0])==({1'b0,15'b000000000000100});
   wire     dbpt = (idc_opc[15:0])==({1'b0,15'b000000000000011});
   wire     drti = (idc_opc[15:0])==({1'b0,15'b000000000000010});
   wire     diwait = (idc_opc[15:0])==({1'b0,15'b000000000000001});
   wire     dhalt = (idc_opc[15:0])==({1'b0,15'b000000000000000});
   wire     dnop = (idc_opc[15:0])==(16'o0240);

   wire     djsr = (idc_opc[15:9])==(7'o04);

   
   
   assign   sop = ~(double_op == 3'b000) & ~nof;

   // svo added bra, used to give false positive on BMI  (tested on 100742)
   assign   dop = ((double_op == 3'b000) & ~(nof|bra|cco))  
        | djmp | djsr | drts
        | dclr |  dcom | dinc | ddec | dneg | dadc | dsbc | dtst |  dror
        | drol | dasr |  dasl | dmfpi | dmtpi;
      
        
   assign   nof = unused | drtt | dreset | diot | dbpt | drti | diwait | dhalt | 
               dtrap | dnop | dspl | dmark | dsob |demt ;

   assign   cco = ((idc_opc[15:4])==({{1'b0,9'b000000010},2'b10}))
   &(|(idc_opc[3:0])) | (idc_opc[15:4])==({{1'b0,9'b000000010},2'b11});
   
   assign   bra = ((idc_opc[15:11])==({{1'b0,3'b000},1'b0}))
   &(|(idc_opc[10:8])) | (idc_opc[15:11])==({{1'b1,3'b000},1'b0});

   wire     dexor = (idc_opc[15:9] == 'o074);
   
   assign   rsd = dexor;
   wire     dmtps = (idc_opc[15:6])==({1'b1,9'b000110100});
   wire     dmfps = byte_flag & not_double & (single_op == 'o067);
   //assign     dsub =  idc_opc[15:12]=={1'b1,3'b110};
   wire   dtrap = ((idc_opc[15:9])==({1'b1,6'b000100}))&(idc_opc[8]);
   wire   demt =    ((idc_opc[15:9])==({1'b1,6'b000100}))&(~idc_opc[8]);
   wire     dsob = (idc_opc[15:9])==({1'b0,6'b111111});


   assign   unused =
                idc_opc[15:9] == 'o 107     ||
                //idc_opc[15:6] == 'o 1067  ||  MTPS
                //idc_opc[15:6] == 'o 1064  ||  MFPS
                idc_opc[15:9] == 'o 076     ||
                (idc_opc[15:9] == 'o 075 && idc_opc[8:6] != 0) ||
                idc_opc[15:5] == {9'o750,1'b1} || 
                idc_opc[15:9] == 'o 007 ||
                idc_opc[15:3] == 'o 00021 ||
                idc_opc[15:3] == 'o 00022 ||
                
                idc_opc[15:0] == 'o 000007 ||   // MFPT    
                idc_opc[15:3] == 'o 00001 ||    // opcodes 000010 through 000037 unused on VM1
                idc_opc[15:3] == 'o 00002 ||
                idc_opc[15:3] == 'o 00003 ||
                idc_opc[15:12] == 'o17 ||                       // 017xxxx don't exist
                ((idc_opc[15:12] == 'o07) && !(dexor | dsob));  // 074xxxx: EXOR, 077xxxx: SOB, others are not implemented
                


   assign   op_decoded[`dmfps ] = dmfps ;
   assign   op_decoded[`dmtps ] = dmtps ;
   assign   op_decoded[`dspl  ] = dspl  ;
   assign   op_decoded[`dsub  ] = dsub  ;
   assign   op_decoded[`dtrap ] = dtrap ;
   assign   op_decoded[`demt  ] = demt  ;
   assign   op_decoded[`dsob  ] = dsob  ;
   assign   op_decoded[`dexor ] = dexor ;
   assign   op_decoded[`dadd  ] = dadd  ;
   assign   op_decoded[`dbis  ] = dbis  ;
   assign   op_decoded[`dbic  ] = dbic  ;
   assign   op_decoded[`dbit  ] = dbit  ;
   assign   op_decoded[`dcmp  ] = dcmp  ;
   assign   op_decoded[`dmov  ] = dmov  ;
   assign   op_decoded[`dsxt  ] = dsxt  ;
   assign   op_decoded[`dmtpi ] = dmtpi ;
   assign   op_decoded[`dmfpi ] = dmfpi ;
   assign   op_decoded[`dmark ] = dmark ;
   assign   op_decoded[`dasl  ] = dasl  ;
   assign   op_decoded[`dasr  ] = dasr  ;
   assign   op_decoded[`drol  ] = drol  ;
   assign   op_decoded[`dror  ] = dror  ;
   assign   op_decoded[`dtst  ] = dtst  ;
   assign   op_decoded[`dsbc  ] = dsbc  ;
   assign   op_decoded[`dadc  ] = dadc  ;
   assign   op_decoded[`dneg  ] = dneg  ;
   assign   op_decoded[`ddec  ] = ddec  ;
   assign   op_decoded[`dinc  ] = dinc  ;
   assign   op_decoded[`dcom  ] = dcom  ;
   assign   op_decoded[`dclr  ] = dclr  ;
   assign   op_decoded[`djsr  ] = djsr  ;
   assign   op_decoded[`dswab ] = dswab ;
   assign   op_decoded[`dnop  ] = dnop  ;
   assign   op_decoded[`drts  ] = drts  ;
   assign   op_decoded[`djmp  ] = djmp  ;
   assign   op_decoded[`drtt  ] = drtt  ;
   assign   op_decoded[`dreset] = dreset;
   assign   op_decoded[`diot  ] = diot  ;
   assign   op_decoded[`dbpt  ] = dbpt  ;
   assign   op_decoded[`drti  ] = drti  ;
   assign   op_decoded[`diwait] = diwait;
   assign   op_decoded[`dhalt ] = dhalt ;
                                  
                                
endmodule // myidc              
                            