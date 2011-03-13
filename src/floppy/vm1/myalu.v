// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C) 2005 Alex Freed, 2008 Viacheslav Slavinsky
// Based on original POP-11 design by Prof.Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 ALU
// --------------------------------------------------------
// April 19, 2010: svo: rol/ror output V = C^N, where C and N are as set after the operation
//                      sxt bit mask 0110 (V is cleared)

module adder(A, B, CI, SUM, CO, VO); 
   input  CI; 
   input [15:0] A; 
   input [15:0] B; 
   output [15:0] SUM; 
   output   CO,VO; 
   wire     tmp;
   wire [14:0]  tmp1;
   wire c1,c2;

   assign   {c1,tmp1} = A[14:0] + B[14:0] + CI;      
   assign   {c2,tmp} = A[15] + B[15] + c1;

   assign   SUM = {tmp,tmp1};   
   assign   CO  = c2;
   assign   VO  = c1 ^ c2;
    
endmodule

module adder8(A, B, CI, SUM, CO, VO); 
   input  CI; 
   input [7:0] A; 
   input [7:0] B; 
   output [7:0] SUM; 
   output   CO,VO; 
   wire     tmp;
   wire [6:0]   tmp1;
   wire     c1,c2;
   
   assign   {c1,tmp1} = A[6:0] + B[6:0] + CI;      
   assign   {c2,tmp} = A[7] + B[7] + c1;

   assign   SUM = {tmp,tmp1};   
   assign   CO  = c2;
   assign   VO  = c1 ^ c2;
    
endmodule

module myalu(in1,in2,ni,ci,mbyte,final_result,ccmask,final_flags, 
         add, adc,sub,sbc,inc2,dec2, inc,dec, clr,
         com,neg,tst,ror,rol,asr,asl,sxt,mov,cmp,
         bit_,bic,bis,exor,swab,
         cc                                         // mystery output, never used
         );
   
   input [15:0] in1;
   input [15:0] in2;
   input    ni,ci,mbyte;
   input    add, adc,sub,sbc,inc2,dec2,inc,dec, clr,com,neg;
   input    tst,ror,rol,asr,asl,sxt,mov,cmp,bit_,bic,bis,exor,swab;
    
   output [3:0] final_flags;
   output [3:0] ccmask;
   
   output   cc;
 
   output [15:0] final_result;   

   reg [15:0]   X;
   reg [15:0]   Y;
   reg      _ci;
   reg  [3:0] flags;
   reg  [3:0] xflags;
   
   wire [15:0]  adder_result;
   wire [7:0]   adder_8_result;

   wire     co,v,z,n,co8,v8,z8,n8;
   wire     use_adder;
   
   reg [15:0]   res;
   wire [15:0]  bit_res;
   
   
   adder adder(X,Y,_ci, adder_result, co,v);
   adder8 adder8(X[7:0],Y[7:0],_ci, adder_8_result, co8,v8);
//(add|adc|sub|sbc|clr|com|neg|test|ror|rol|asr|asl|cmp)? 4'hf:
   assign ccmask = (inc2|dec2)? 4'b0000:
      (sxt)? 4'b0110:
      (inc|dec|mov|bit_|bic|bis )? 4'b1110:
      (exor )? 4'b1110:
       4'b1111; // all the rest

   assign cc = (add| adc|sub|sbc|inc|dec| clr|com|neg|
        tst|ror|rol|asr|asl|sxt|mov|cmp|bit_|bic|bis|exor|swab);
    
   

   assign z= (adder_result == 0);
   assign z8= (adder_8_result == 0);
   assign n = adder_result[15];
   assign n8 = adder_8_result[7];
   
   assign final_result = (use_adder)? (cmp? 0: adder_result): res;
   assign final_flags = (use_adder)? flags: xflags;
   assign use_adder = (add | adc | sub | sbc | inc | dec |inc2 |dec2 |neg|cmp );
   assign bit_res = in1 & in2;
 
  
//   assign     Y = in2;
//   assign     X = add?in1:0;
//   assign     _ci = add?0:ci;
//   assign     flags=  {n,z,v,co};
   wire   zero16,zero8;
   assign zero16 = (res==0);
   assign zero8 = (res[7:0] == 0);

   wire   zero16_1,zero8_1;
   assign zero16_1 = (in2==0);
   assign zero8_1 = (in2[7:0] == 0);
   

    always @* begin
        case (1'b1)   // synthesis parallel_case 
        clr: begin
                res = 0;
                xflags = 4'b0100;
            end
   
        com: begin
                res = ~in2;
                if(mbyte)
                    xflags = { ~in2[7],zero8, 2'b01};
                else
                    xflags = { ~in2[15],zero16, 2'b01};
            end

        tst: begin
                res = 0;
                if(mbyte)
                    xflags = {in2[7], zero8_1, 2'b00};
                else
                    xflags = {in2[15], zero16_1, 2'b00};
            end
            
        ror: begin
                if(mbyte) begin
                    res = {8'b0, ci, in2[7:1]};
                    xflags = {res[7], zero8, res[7]^in2[0],in2[0]}; // nzvc
                end
                else begin
                    res = {ci, in2[15:1]};
                    xflags = {res[15], zero16, res[15]^in2[0],in2[0]};           
                end
            end
            
        rol: begin
                if(mbyte) begin
                    res = {8'b0, in2[6:0], ci};
                    xflags = {res[7], zero8, res[7]^in2[7], in2[7]};
                 end
                 else begin
                    res = { in2[14:0],ci};
                    xflags = { res[15],zero16, res[15]^in2[15],in2[15]};         
                 end
            end
            
        asr: begin
                if(mbyte) begin
                        res = {8'b0,in2[7], in2[7:1]};
                        xflags = { res[7],zero8, in2[0]^in2[7],in2[0]};
                end
                else begin
                        res = { in2[15],in2[15:1]};
                        xflags = { res[15],zero16, in2[0]^in2[15],in2[0]};
                end
            end
            
        asl: begin
                if(mbyte) begin
                    res = {8'b0,in2[6:0], 1'b0};
                    xflags = { res[7],zero8, in2[6]^in2[7],in2[7]};
                end
                else begin
                    res = { in2[14:0],1'b0};
                    xflags = { res[15],zero16, in2[14]^in2[15],in2[15]};
                end
            end
            
        sxt: begin
                if(ni)
                    res = 16'hffff;
                else
                    res = 16'b0;
                //xflags = { 1'b0,~ni,2'b0};
                xflags = {ni, ~ni, 1'b0, ci};
            end
            
        mov: begin
                if(mbyte) begin
                    res =  in2[7]?{8'hff, in2[7:0]}:{8'h00,in2[7:0]};
                    xflags = { res[7],zero8, 2'b0};
                end
                else begin
                    res = in2;
                    xflags = { res[15],zero16, 2'b0};          
                end
            end
  
        bit_: begin
                res = 0; 
                if(mbyte)
                    xflags = {bit_res[7], (bit_res[7:0]==0)?1'b1:1'b0, 2'b0};
                else
                    xflags = {bit_res[15], (bit_res[15:0]==0)?1'b1:1'b0, 2'b0};
            end
            
        bic: begin
                res = in1 & ~in2; 
                if(mbyte)
                    xflags = {res[7], (res[7:0]==0)?1'b1:1'b0, 2'b0};
                else
                    xflags =  {res[15], (res[15:0]==0)?1'b1:1'b0, 2'b0};
            end
            
        bis: begin
                res = in1 | in2; 
                if(mbyte)
                    xflags = {res[7] ,(res[7:0]==0)?1'b1:1'b0  ,2'b0};
                else
                    xflags =  {res[15] ,(res[15:0]==0)?1'b1:1'b0  ,2'b0};
            end
            
        exor: begin
                res = in1 ^ in2; 
                xflags =  {res[15], (res[15:0]==0)?1'b1:1'b0, 2'b0};
            end
            
        swab: begin
                res = {in2[7:0], in2[15:8]}; 
                xflags =  {res[7], (res[7:0]==0)?1'b1:1'b0, 2'b0};
            end

        default: 
            begin
                res = 0;
                xflags = 0;
            end
        endcase
             
      
   end // always @ *
   

    always @* begin
        case (1'b1)     // synthesis parallel_case 
        add: begin
                X <= in1;    
                Y <= in2;
                _ci <= 0;
                flags <=  {n,z,v,co};   
            end 

        adc: begin
                X <= 0;    
                Y <= in2;
                _ci <= ci;
                if(mbyte) begin
                    flags <=  {n8,z8,v8,co8};
                end   
                else  begin
                    flags <=  {n,z,v,co};
                end
            end
      
        sub: begin
                X <= ~in1;    
                Y <= in2;
                _ci <= 1;
                flags <=  {n,z,v,~co};         
            end
      
        sbc: begin
                X <= 16'hFFFF;    
                Y <= in2;
                _ci <= ~ci;
                if(mbyte) begin
                    flags <=  {n8,z8,v8,~co8};
                end   
                else  begin
                    flags <=  {n,z,v,~co};
                end
            end 
    
        inc2: begin
                 X <= 2;     
                 Y <= in2;
                 _ci <= 0;
                 flags <=  0;
              end 
    
        dec2: begin
                 X <= in2;
                 Y <= 'hfffe;
                 _ci <= 0;
                 flags <=  0;
              end 
    
        inc: begin
                 X <= 0;     
                 Y <= in2;
                 _ci <= 1;
                 if(mbyte) begin
                    flags <=  {n8,z8,v8,1'b0};
                 end   
                 else  begin
                    flags <=  {n,z,v,1'b0};
                 end
              end 
    
        dec: begin
                 X <= 'hffff;    
                 Y <= in2;
                 _ci <= 0;
                 if(mbyte) begin
                    flags <=  {n8,z8,v8,1'b0};
                 end   
                 else  begin
                    flags <=  {n,z,v,1'b0};
                 end
              end
               
        neg: begin
                 X <= 'h0000;    
                 Y <= ~in2;
                 _ci <= 1;
                 if(mbyte) begin
                    flags <=  {n8,z8,v8,~co8};
                 end   
                 else  begin
                    flags <=  {n,z,v,~co};
                 end
              end // if (neg)

        cmp: begin
                 X <= ~in1;
                 Y <= in2;
                     _ci <= 1'b1;
                 if(mbyte) begin
                    flags <=  {n8,z8,v8,~co8};
                 end   
                 else  begin
                    flags <=  {n,z,v,~co};
                 end

              end
      
        default:     
               begin
                 X <= 'h0000;    
                 Y <= 'h0000;
                 _ci <= 0;
                 flags <= 4'b0;
              end
        endcase
    end
endmodule   
   

