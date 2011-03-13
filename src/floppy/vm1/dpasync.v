// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008 Viacheslav Slavinsky
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 Data Path
// --------------------------------------------------------

`include "instr.h"

module datapath_async(clk, ce, clkdbi, cedbi, reset_n, dbi, dbo, dba, opcode, psw, ctrl, alucc, taken, PC, ALU1, ALUOUT, SRC, DST, Rtest);
input			clk, ce, clkdbi, cedbi, reset_n;
input 	[15:0]	dbi;
output reg[15:0]dbo;
output reg[15:0]dba;
output	[15:0]	opcode;
output	[15:0]	psw;

input	[127:0]	ctrl;

output	[3:0]	alucc;
output			taken;

output [15:0]	PC;
output [15:0]	ALU1, SRC, DST;
output [15:0]	ALUOUT;
output [143:0] 	Rtest;

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


reg	 [15:0]	R[0:7];

wire [15:0] PC = R[7];
wire [15:0] SP = R[6];

reg			OPC_BYTE;
reg  [14:0]	OPC;
reg	 [15:0]	REGin;
reg  [15:0] DST;
reg  [15:0] SRC;
reg  [15:0] ADR;
reg  [15:0] ALU1, ALU2;
reg	 [15:0]	REGsel;

reg	 [2:0]	priority;
reg			trapbit;
reg			fn, fz, fv, fc;

assign	opcode = {OPC_BYTE,OPC};

assign 	psw = {priority,trapbit,fn,fz,fv,fc};


reg taken; // latch

reg [15:0] dbi_r;

always @(posedge clkdbi) 
    if (cedbi) 
        dbi_r <= dbi;

always @* //@(ctrl[`CCTAKEN])
    taken = 	( ({OPC_BYTE,OPC[10:9]}==0)                             )|
				( ({OPC_BYTE,OPC[10:9]}==1) & (~OPC[8] ^ fz )           )|
				( ({OPC_BYTE,OPC[10:9]}==2) & (~OPC[8] ^ (fn^fv) )      )|
				( ({OPC_BYTE,OPC[10:9]}==3) & (~OPC[8] ^ ((fn^fv)|fz) ) )|
				( ({OPC_BYTE,OPC[10:9]}==4) & (~OPC[8] ^ fn )           )|
				( ({OPC_BYTE,OPC[10:9]}==5) & (~OPC[8] ^ (fc|fz) )      )|
				( ({OPC_BYTE,OPC[10:9]}==6) & (~OPC[8] ^ fv )           )|
				( ({OPC_BYTE,OPC[10:9]}==7) & (~OPC[8] ^ fc )           );


// = ALU1
always @* case (1'b1) // synopsys parallel_case 
	ctrl[`PCALU1]:		ALU1 <= PC;
	ctrl[`SPALU1]:		ALU1 <= SP;
	ctrl[`DSTALU1]:		ALU1 <= DST;
	ctrl[`SRCALU1]:		ALU1 <= SRC;
	ctrl[`SELALU1]:		ALU1 <= REGsel;
	ctrl[`PSWALU1]:		ALU1 <= psw;
	default:			ALU1 <= 16'b0; // unsure
	endcase

// = ALU2
always @* case (1'b1) // synopsys parallel_case
	ctrl[`DSTALU2]: ALU2 <= DST;
	ctrl[`SRCALU2]: ALU2 <= SRC;
	ctrl[`OFS8ALU2]: ALU2 <= { {7{opcode[7]}}, opcode[7:0], 1'b0};
	ctrl[`OFS6ALU2]: ALU2 <= { opcode[5:0], 1'b0 };
	default:		ALU2 <= 16'b0;  // unsure
	endcase
	
// = REGsel	
always @*
	case (1'b1) // synopsys parallel_case
	ctrl[`REGSEL]: 	REGsel <= R[OPC[2:0]];
	ctrl[`REGSEL2]:	REGsel <= R[OPC[8:6]];
	//default:		REGsel <= 16'b0; // unsure
	endcase

// = REGin
always @* case (1'b1) // synopsys parallel_case
	ctrl[`ALUREG]:	REGin <= alu_out;
	ctrl[`DSTREG]:	REGin <= DST;
	ctrl[`SRCREG]:	REGin <= SRC;
	ctrl[`ADRREG]:	REGin <= ADR;
	ctrl[`PCREG]:	REGin <= R[7];
	ctrl[`DBIREG]:	REGin <= dbi_r;
	//default:		REGin <= 16'b0; // unsure
	endcase

// = dba
always @* case (1'b1) // synopsys parallel_case
	ctrl[`DBAPC]:	dba <= PC;
	ctrl[`DBASP]:	dba <= SP;
	ctrl[`DBADST]:	dba <= DST;
	ctrl[`DBASRC]:  dba <= SRC;
	ctrl[`DBAADR]:	dba <= ADR;
	default:		dba <= 16'h0; // a must
	endcase

// = dbo
always @* case (1'b1) // synopsys parallel_case
	ctrl[`DBOSEL]:	dbo <= REGsel;
	ctrl[`DBODST]:	dbo <= DST;
	ctrl[`DBOSRC]:	dbo <= SRC;
	ctrl[`DBOADR]:	dbo <= ADR;	
	default:		dbo <= 16'b0; // unsure
	endcase
	
// @ opcode
always @* 
	if (!reset_n) {OPC_BYTE,OPC} <= 16'b0;
	else begin
	    if (ctrl[`SETOPC]) $display("set OPC to %o->", dbi_r);
		case (1'b1) 
		ctrl[`SETOPC]:		begin
                            OPC <= dbi_r[14:0];
                            OPC_BYTE <= dbi_r[15];
                            end
		ctrl[`ODDREG]:    	begin
                            OPC <= {OPC[14:7],~OPC[6],OPC[5:0]};          
                            OPC_BYTE <= ctrl[`RESET_BYTE]?1'b0 : OPC_BYTE;
                            end
		ctrl[`CHANGE_OPR]:	begin
                            OPC <= {OPC[14:12],OPC[5:0],OPC[11:6]};	      
                            OPC_BYTE <= ctrl[`RESET_BYTE]?1'b0 : OPC_BYTE;
                            end
		ctrl[`RESET_BYTE]: 	OPC_BYTE <= 1'b0;
		endcase
	end



// @ R, SP, PC = xx
always @*
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
	end else begin
		if (ctrl[`ALUPC]) 	R[7] <= alu_out;
		if (ctrl[`DBIPC]) 	R[7] <= dbi_r;
		if (ctrl[`SETPCROM])R[7] <= 16'o 100000;
		if (ctrl[`FPPC])	R[7] <= R[5];
		if (ctrl[`SELPC])	R[7] <= REGsel;
		if (ctrl[`ADRPC])	R[7] <= ADR;
		if (ctrl[`ALUSP])	R[6] <= alu_out;
		if (ctrl[`DBIFP])	R[5] <= dbi_r;
		if (ctrl[`SETREG])	R[OPC[2:0]] <= REGin;
		if (ctrl[`SETREG2]) R[OPC[8:6]] <= REGin;
		
	end
	
	
// @ ADR, SRC, DST
always @* 
	if (~reset_n) begin
		ADR <= 0;
		DST <= 0;
		SRC <= 0;
	end
	else begin
		case (1'b1) // synopsis parallel_case
		ctrl[`SELADR]:	ADR <= REGsel;
		ctrl[`DSTADR]:	ADR <= DST;
		ctrl[`SRCADR]:	ADR <= SRC;
		ctrl[`CLRADR]:	ADR <= 0;
		endcase
		
		if (ctrl[`SAVE_STAT]) begin
				ADR <= PC;
				DST <= psw;
			end
			
		case (1'b1) // synopsis parallel_case
		ctrl[`DBIDST]:	DST <= dbi_r;
		ctrl[`ALUDST]:	DST <= alu_out;
		ctrl[`ALUDSTB]:	DST <= OPC_BYTE ? {DST[15:8],alu_out[7:0]} : alu_out;
		ctrl[`SELDST]:	DST <= REGsel;
		//ctrl[`PSWDST]:  DST <= psw[7:0];
		endcase
		
		case (1'b1) // synopsis parallel_case
		ctrl[`DBISRC]:  SRC <= dbi_r;
		ctrl[`ALUSRC]:	SRC <= alu_out;
		ctrl[`SELSRC]:	SRC <= REGsel;
		
		ctrl[`BUSERR]:	SRC <= `TRAP_BUS;
		ctrl[`SEGERR]:	SRC <= `TRAP_SEG;
		ctrl[`ERR]:		SRC <= `TRAP_ERR;
		ctrl[`BPT]:		SRC <= `TRAP_BPT;
		ctrl[`EMT]:		SRC <= `TRAP_EMT;
		ctrl[`IOT]:		SRC <= `TRAP_IOT;
		ctrl[`SVC]:		SRC <= `TRAP_SVC;
		endcase
	end

// @ ps
always @* 
	if (~reset_n) begin
        priority <= 0;
        trapbit <= 0;
	end else begin
		case (1'b1) // synopsys parallel_case
		ctrl[`DBIPS], 	
		ctrl[`VECTORPS]:
			{priority,trapbit,fn,fz,fv,fc} <= dbi_r[7:0];
			
		ctrl[`DSTPSW]:
			{priority,fn,fz,fv,fc} <= {DST[7:5],DST[3:0]};
			
		ctrl[`TSTSRC]:
			{fn,fz} <= {SRC[15],~|SRC};
		
		ctrl[`TSTSRCADR]:
			fz <= ~|SRC && ~|ADR;
			
		ctrl[`ALUCC]: begin
				if (alu_ccmask[3]) 	fn <= alu_ccout[3];
				if (alu_ccmask[2]) 	fz <= alu_ccout[2];
				if (alu_ccmask[1]) 	fv <= alu_ccout[1];
				if (alu_ccmask[0])	fc <= alu_ccout[0];
			end
		ctrl[`CCSET]: begin
				if (OPC[3])	fn <= OPC[4];
				if (OPC[2]) fz <= OPC[4];
				if (OPC[1]) fv <= OPC[4];
				if (OPC[0]) fc <= OPC[4];
			end
		ctrl[`SPL]:	priority <= OPC[2:0];
		endcase
	end

//assign alucc = alu_ccout; //ctrl[`CCGET] ? alu_ccout : 4'b0;

reg [3:0] alucc;
always @*
        if (ctrl[`CCGET]) alucc <= alu_ccout;

wire 			alu_ni, alu_ci, alu_bi;
wire 	[15:0]	alu_out;
wire	[3:0]	alu_ccmask;
wire	[3:0]	alu_ccout;

assign	alu_ni = fn;
assign  alu_ci = fc;
assign	alu_bi = OPC_BYTE;

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
    .bit (ctrl[`BIT ]),
	.bic (ctrl[`BIC ]),
	.bis (ctrl[`BIS ]),
	.exor(ctrl[`EXOR]),
	.swab(ctrl[`SWAB])
	//.cc  (ctrl[`CC  ])
	);         
               
endmodule
        