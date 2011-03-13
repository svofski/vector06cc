// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008-2010 Viacheslav Slavinsky 
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 Data Path
// --------------------------------------------------------

`include "instr.h"

module datapath(clk, ce, clkdbi, cedbi, reset_n, dbi, din_active, dbo, dba, opcode, psw, ctrl, alucc, taken, PC, ALU1, ALUOUT, SRC, DST, usermode_i, Rtest);
input           clk, ce, clkdbi, cedbi, reset_n;
input   [15:0]  dbi;
input           din_active; // needed to select between registered/direct inputs
output reg[15:0]dbo;
output reg[15:0]dba;
output  [15:0]  opcode;
output  [15:0]  psw;

input   [127:0] ctrl;

output  [3:0]   alucc;
output          taken;

output [15:0]   PC;
output [15:0]   ALU1, SRC, DST;
output [15:0]   ALUOUT;
input           usermode_i;
output [143:0]  Rtest;

assign Rtest[15:0]      = R[0];
assign Rtest[31:16]     = R[1];
assign Rtest[47:32]     = R[2];
assign Rtest[63:48]     = R[3];
assign Rtest[79:64]     = R[4];
assign Rtest[95:80]     = R[5];
assign Rtest[111:96]    = R[6];
assign Rtest[127:112]   = R[7];
assign Rtest[143:128]   = psw; 

assign ALUOUT = alu_out;

// only uSP is real in the second bank
reg  [15:0] R[0:15];

wire [15:0] PC = R[7];
wire [15:0] SP = R[{usermode,3'o6}];

reg         OPC_BYTE;
reg  [14:0] OPC;
reg  [15:0] REGin;
reg  [15:0] DST;
reg  [15:0] SRC;
reg  [15:0] ADR;
reg  [15:0] ALU1, ALU2;
reg  [15:0] REGsel;

reg         usermode;
reg         prevmode;
reg  [2:0]  prio;
reg         trapbit;
reg         fn, fz, fv, fc;

assign  opcode = {OPC_BYTE,OPC};

assign  psw = {{2{usermode}},{2{prevmode}},4'b0000,prio,trapbit,fn,fz,fv,fc};


reg taken; // latch

// deliver dbi as soon as possible, but hold it for one more clock-enabled cycle
reg [15:0] dbi_reg;
always @(posedge clkdbi) 
    if (cedbi) 
        dbi_reg <= dbi;
        
//wire [15:0] dbi_r = din_active ? dbi : dbi_reg;
wire [15:0] dbi_r = dbi;

initial begin
 // $monitor("dbi_r=%o", dbi_r);
end

always @* //@(ctrl[`CCTAKEN])
    taken =     ( ({OPC_BYTE,OPC[10:9]}==0)                             )|
                ( ({OPC_BYTE,OPC[10:9]}==1) & (~OPC[8] ^ fz )           )|
                ( ({OPC_BYTE,OPC[10:9]}==2) & (~OPC[8] ^ (fn^fv) )      )|
                ( ({OPC_BYTE,OPC[10:9]}==3) & (~OPC[8] ^ ((fn^fv)|fz) ) )|
                ( ({OPC_BYTE,OPC[10:9]}==4) & (~OPC[8] ^ fn )           )|
                ( ({OPC_BYTE,OPC[10:9]}==5) & (~OPC[8] ^ (fc|fz) )      )|
                ( ({OPC_BYTE,OPC[10:9]}==6) & (~OPC[8] ^ fv )           )|
                ( ({OPC_BYTE,OPC[10:9]}==7) & (~OPC[8] ^ fc )           );


// = ALU1
always @* case (1'b1) // synopsys parallel_case 
    ctrl[`PCALU1]:      ALU1 <= PC;
    ctrl[`SPALU1]:      ALU1 <= SP;
    ctrl[`DSTALU1]:     ALU1 <= DST;
    ctrl[`SRCALU1]:     ALU1 <= SRC;
    ctrl[`SELALU1]:     ALU1 <= REGsel;
    ctrl[`PSWALU1]:     ALU1 <= {8'b0,psw[7:0]}; // don't expose usermode to BK software
    default:            ALU1 <= 16'b0; 
    endcase

// = ALU2
always @* case (1'b1) // synopsys parallel_case
    ctrl[`DSTALU2]: ALU2 <= DST;
    ctrl[`SRCALU2]: ALU2 <= SRC;
    ctrl[`OFS8ALU2]: ALU2 <= { {7{opcode[7]}}, opcode[7:0], 1'b0};
    ctrl[`OFS6ALU2]: ALU2 <= { opcode[5:0], 1'b0 };
    default:        ALU2 <= 16'b0;  
    endcase
    
// = REGsel 
always @*
    case (1'b1) 
    ctrl[`REGSEL]:  REGsel <= R[{(OPC[2:0] == 6) & usermode,OPC[2:0]}];  
    ctrl[`REGSEL2]: REGsel <= R[{(OPC[8:6] == 6) & usermode,OPC[8:6]}];
    default:        REGsel <= 16'b0; 
    endcase

// = REGin
always @* case (1'b1) 
    ctrl[`ALUREG]:  REGin <= alu_out;
    ctrl[`DSTREG]:  REGin <= DST;
    ctrl[`SRCREG]:  REGin <= SRC;
    ctrl[`ADRREG]:  REGin <= ADR;
    ctrl[`PCREG]:   REGin <= R[7];
    ctrl[`DBIREG]:  REGin <= dbi_r; 
    default:        REGin <= 16'b0; 
    endcase

// = dba
always @* case (1'b1) // synopsys parallel_case
    ctrl[`DBAPC]:   dba <= PC;
    ctrl[`DBASP]:   dba <= SP;
    ctrl[`DBADST]:  dba <= DST; 
    ctrl[`DBASRC]:  dba <= SRC;
    ctrl[`DBAADR]:  dba <= ADR;
    default:        dba <= 16'h0; 
    endcase

// = dbo
always @* case (1'b1) // synopsys parallel_case
    ctrl[`DBOSEL]:  dbo <= REGsel;
    ctrl[`DBODST]:  dbo <= DST;
    ctrl[`DBOSRC]:  dbo <= SRC;
    ctrl[`DBOADR]:  dbo <= ADR; 
    default:        dbo <= 16'b0; 
    endcase
    
// @ opcode
always @(posedge clk or negedge reset_n) 
    if (!reset_n) {OPC_BYTE,OPC} <= 16'b0;
    else if (ce) begin
        //if (ctrl[`SETOPC]) $display("set OPC to %o->", dbi_r);
        case (1'b1) 
        ctrl[`SETOPC]:      begin
                            OPC <= dbi_r[14:0];
                            OPC_BYTE <= dbi_r[15];
                            end
        ctrl[`ODDREG]:      begin
                            OPC <= {OPC[14:7],~OPC[6],OPC[5:0]};          
                            OPC_BYTE <= ctrl[`RESET_BYTE]?1'b0 : OPC_BYTE;
                            end
        ctrl[`CHANGE_OPR]:  begin
                            OPC <= {OPC[14:12],OPC[5:0],OPC[11:6]};       
                            OPC_BYTE <= ctrl[`RESET_BYTE]?1'b0 : OPC_BYTE;
                            end
        ctrl[`RESET_BYTE]:  OPC_BYTE <= 1'b0;
        endcase
    end



// @ R, SP, PC = xx
always @(posedge clk or negedge reset_n)
    if (~reset_n) begin
`ifdef SIM
        R[0] = 0;
        R[1] = 0;
        R[2] = 0;
        R[3] = 0;
        R[4] = 0;
        R[5] = 0;
        R[6] = 0;
        R[7] = 0;
`endif      
`ifdef TESTBENCH
        R[5] = 'o040032; // for simulation purposes
`endif
    end else 
    if (ce) begin
        if (ctrl[`ALUPC])   R[7] <= alu_out; 
        if (ctrl[`DBIPC])   R[7] <= dbi_r;
        if (ctrl[`SETPCROM]) R[7] <= 16'o 100000; 
        if (ctrl[`FPPC])    R[7] <= R[5];
        if (ctrl[`SELPC])   R[7] <= REGsel;
        if (ctrl[`ADRPC])   R[7] <= ADR; 
        if (ctrl[`ALUSP])   R[{usermode,3'o6}] <= alu_out;
        if (ctrl[`DBIFP])   R[5] <= dbi_r;
        if (ctrl[`SETREG])  R[{(OPC[2:0] == 6) & usermode,OPC[2:0]}] <= REGin; // selects user/kernel SP
        if (ctrl[`SETREG2]) R[{(OPC[8:6] == 6) & usermode,OPC[8:6]}] <= REGin; // selects user/kernel SP
        
    end
    
    
// @ ADR, SRC, DST
always @(posedge clk or negedge reset_n) 
    if (~reset_n) begin
        ADR <= 0;
        DST <= 0;
        SRC <= 0;
    end
    else if (ce) begin
        case (1'b1) // synopsis parallel_case
        ctrl[`SELADR]:  ADR <= REGsel;
        ctrl[`DSTADR]:  ADR <= DST; 
        ctrl[`SRCADR]:  ADR <= SRC;
        ctrl[`CLRADR]:  ADR <= 0;
        endcase
        
        if (ctrl[`SAVE_STAT]) begin
                ADR <= PC;
                DST <= {8'b0,psw[7:0]}; // don't expose usermode to BK software
            end
            
        case (1'b1) // synopsis parallel_case
        ctrl[`DBIDST]:  begin DST <= dbi_r;/* $display("DBIDST: DST=%o", dbi_r);*/ end
        ctrl[`ALUDST]:  DST <= alu_out;
        ctrl[`ALUDSTB]: DST <= OPC_BYTE ? {DST[15:8],alu_out[7:0]} : alu_out;
        ctrl[`SELDST]:  begin DST <= REGsel; /*$display("SELDST: DST <= %o", REGsel);*/ end
        //ctrl[`PSWDST]:  DST <= psw[7:0];
        endcase
        
        case (1'b1) // synopsis parallel_case
        ctrl[`DBISRC]:  begin SRC <= dbi_r; /*$display("DBISRC: SRC=%o",dbi_r);*/ end
        ctrl[`ALUSRC]:  begin SRC <= alu_out; /*$display("ALUSRC: src=%o", alu_out);*/ end
        ctrl[`SELSRC]:  begin SRC <= REGsel; /*$display("SELSRC: SRC <= %o", REGsel);*/ end
        
        ctrl[`BUSERR]:  SRC <= `TRAP_BUS;
        ctrl[`SEGERR]:  SRC <= `TRAP_SEG;
        ctrl[`ERR]:     SRC <= `TRAP_ERR;
        ctrl[`BPT]:     SRC <= `TRAP_BPT;
        ctrl[`EMT]:     SRC <= `TRAP_EMT;
        ctrl[`IOT]:     SRC <= `TRAP_IOT;
        ctrl[`SVC]:     SRC <= `TRAP_SVC;
        endcase
    end

always @(posedge clk or negedge reset_n) begin
    if (~reset_n) begin
        usermode <= 0;
        prevmode <= 0;
    end else if (ce) begin
        case (1'b1)
        ctrl[`MODEIN]: 
            begin
            usermode <= usermode_i;
            prevmode <= usermode_i != usermode ? usermode : prevmode;
            end
        ctrl[`MODESWAP]: 
            begin
            usermode <= prevmode;
            prevmode <= usermode;
            end
        endcase
    end
end

// @ ps
always @(posedge clk or negedge reset_n) 
    if (~reset_n) begin
        prio <= 0;
        trapbit <= 0;
    end else if (ce) begin
        case (1'b1) // synopsys parallel_case
        ctrl[`DBIPS],
        ctrl[`VECTORPS]:
                {prio,trapbit,fn,fz,fv,fc} <= dbi_r[7:0];
            
        ctrl[`DSTPSW]:
            {prio,fn,fz,fv,fc} <= {DST[7:5],DST[3:0]};
            
        ctrl[`TSTSRC]:
            {fn,fz} <= {SRC[15],~|SRC};
        
        ctrl[`TSTSRCADR]:
            fz <= ~|SRC && ~|ADR;
            
        ctrl[`ALUCC]: begin
                if (alu_ccmask[3])  fn <= alu_ccout[3];
                if (alu_ccmask[2])  fz <= alu_ccout[2];
                if (alu_ccmask[1])  fv <= alu_ccout[1];
                if (alu_ccmask[0])  fc <= alu_ccout[0];
            end
        ctrl[`CCSET]: begin
                if (OPC[3]) fn <= OPC[4];
                if (OPC[2]) fz <= OPC[4];
                if (OPC[1]) fv <= OPC[4];
                if (OPC[0]) fc <= OPC[4];
            end
        ctrl[`SPL]: prio <= OPC[2:0];
        endcase
    end

//assign alucc = alu_ccout; //ctrl[`CCGET] ? alu_ccout : 4'b0;

reg [3:0] alucc;
always @(posedge clk)
    if (ce)
        if (ctrl[`CCGET]) alucc <= alu_ccout;

wire            alu_ni, alu_ci, alu_bi;
wire    [15:0]  alu_out;
wire    [3:0]   alu_ccmask;
wire    [3:0]   alu_ccout;

assign  alu_ni = fn;
assign  alu_ci = fc;
assign  alu_bi = OPC_BYTE;

// ALU
myalu ALU(
    .in1(ALU2),
    .in2(ALU1),
    .ni(alu_ni),
    .ci(alu_ci),
    .mbyte(alu_bi),
    .final_result(alu_out),
    .ccmask(alu_ccmask),
    .final_flags(alu_ccout), 
    
    .add (ctrl[`ADD]), 
    .adc (ctrl[`ADC]),
    .sub (ctrl[`SUB]),
    .sbc (ctrl[`SBC]),
    .inc2(ctrl[`INC2]),
    .dec2(ctrl[`DEC2]), 
    .inc (ctrl[`INC ]),
    .dec (ctrl[`DEC ]), 
    .clr (ctrl[`CLR ]),
    .com (ctrl[`COM ]),
    .neg (ctrl[`NEG ]),
    .tst (ctrl[`TST ]),
    .ror (ctrl[`ROR ]),
    .rol (ctrl[`ROL ]),
    .asr (ctrl[`ASR ]),
    .asl (ctrl[`ASL ]),
    .sxt (ctrl[`SXT ]),
    .mov (ctrl[`MOV ]),
    .cmp (ctrl[`CMP ]),
    .bit_ (ctrl[`BIT ]),
    .bic (ctrl[`BIC ]),
    .bis (ctrl[`BIS ]),
    .exor(ctrl[`EXOR]),
    .swab(ctrl[`SWAB])
    //.cc  (ctrl[`CC  ])
    );         
               
endmodule
        