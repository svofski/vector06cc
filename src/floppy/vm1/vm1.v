// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008-2010 Viacheslav Slavinsky 
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// 1801VM1 CPU Interface Module
// --------------------------------------------------------


`default_nettype none

`include "opc.h"
`include "instr.h"

module vm1(clk, 
           ce,
           reset_n,
           data_i,
           data_o,
           addr_o,

           error_i,      

           usermode_i,  // latched during IAKO or RTI/RTT: 1 = user
           
           RPLY,        // i: reply to DIN or DOUT
           DIN,         // o: data in
           DOUT,        // o: data out
           WTBT,        // o: byteio op/odd address
           
           VIRQ,        // i: vector interrupt request
           IRQ1,        // i: console interrupt
           IRQ2,        // i: trap to 0100
           IRQ3,        // i: trap to 0270
           
           IAKO,        // o: interrupt ack, DIN requests vector
           
           DMR,         // i: DMA request
           DMGO,        // o: DMA offer
           SACK,        // i: DMA active
           
           INIT,        // o: peripheral INIT
           
           SEL1,        // o: 177716 i/o -- no REPLY needed
           SEL2,        // o: 177714 i/o -- no REPLY needed
           
           IFETCH,      // o: indicates IF0
           

           dati,
           dato,
           error_bus,
           OPCODE,
           PC,
           ALU1,
           ALUOUT, SRC, DST,
           ALUCC,
           idccat,
           psw,
           op_decoded,      
           test_control,
           test_bus,
           //dpcmd,
`ifdef WITH_RTEST   
           Rtest,
`endif           
           taken
           );

input           clk;
input           ce;
input           reset_n;
`ifdef TESTBENCH
output   [15:0]  data_i;
output           RPLY;        // i: reply to DIN or DOUT
`else
input   [15:0]  data_i;
input           RPLY;        // i: reply to DIN or DOUT
`endif
output  [15:0]  data_o;
output  [15:0]  addr_o;
input           error_i;
input           usermode_i;
output          DIN;         // o: data in
output          DOUT;        // o: data out
output          WTBT;        // o: byteio op/odd address
           
input           VIRQ;        // i: vector interrupt request
input           IRQ1;        // i: console interrupt
input           IRQ2;        // i: trap to 0100
input           IRQ3;        // i: trap to 0270
           
output          IAKO;        // o: interrupt ack, DIN requests vector
           
input           DMR;         // i: DMA request
output          DMGO;        // o: DMA offer
input           SACK;        // i: DMA active
           
output          INIT;        // o: peripheral INIT
           
output          SEL1;        // o: 177716 i/o -- no REPLY needed
output          SEL2;        // o: 177714 i/o -- no REPLY needed
output          IFETCH;
output          dati, dato;
output          error_bus;
output  [15:0]  PC;
output  [15:0]  ALU1;
output  [15:0]  ALUOUT, SRC, DST;
output  [7:0]   test_control;
output  [7:0]   test_bus;
output  [3:0]   ALUCC;
output  [7:0]   idccat;
output  [15:0]  psw;
output          taken;
output  [15:0]  OPCODE;
//output  [127:0] dpcmd;
`ifdef WITH_RTEST   
output  [143:0] Rtest;
`endif

assign ALUCC = alucc;
assign idccat = {idc_unused,idc_cco,idc_bra,idc_nof,idc_rsd,idc_dop,idc_sop};
assign taken = dp_taken;
assign OPCODE = opcode;

wire    [127:0]         dpcmd;
wire    [15:0]          opcode;
output  [`IDC_NOPS:0]   op_decoded;
wire                    idc_cco, idc_bra, idc_nof, idc_rsd, idc_dop, idc_sop, idc_unused;
wire    [15:0]          psw;
wire    [3:0]           alucc;
wire                    dp_taken;
wire                    error_bus;

wire    ctl_ce = ce,
        dp_ce = ce;
wire    dp_clk  = clk;
wire    dbi_clk = clk;
wire    cedbi = ce;

wire    error_to_control = error_bus | error_i;


wire    virq_masked = ~psw[7] & VIRQ;

control11 controlr(
    .clk(clk), 
    .ce(ctl_ce),
    .reset_n(reset_n), 
    .dpcmd(dpcmd),
    .ierror(error_to_control),
    .ready_i(RPLY),
    .dati_o(DIN),
    .dato_o(DOUT),
    .mbyte(WTBT),
    .ifetch(IFETCH),
    .psw(psw),
    .irq_in(virq_masked),
    .iako(IAKO),
    .dp_taken(dp_taken),
    .dp_alucc(alucc),
    .dp_opcode(opcode),
    .idcop(op_decoded),
    .idc_cco(idc_cco), .idc_bra(idc_bra), .idc_nof(idc_nof), 
    .idc_rsd(idc_rsd), .idc_dop(idc_dop), .idc_sop(idc_sop), .idc_unused(idc_unused),
    .initq(initq),
    .test(test_control));

idc idcr(
    .idc_opc(opcode), 
    .unused(idc_unused), 
    .cco(idc_cco), 
    .bra(idc_bra), 
    .nof(idc_nof),
    .rsd(idc_rsd), 
    .dop(idc_dop), 
    .sop(idc_sop), 
    .op_decoded(op_decoded));

datapath dp(
    .clk(dp_clk),
    .ce(dp_ce),
    .clkdbi(dbi_clk),
    .cedbi(cedbi),
    .reset_n(reset_n),
    .dbi(data_i), 
    .din_active(DIN),
    .dbo(data_o),
    .dba(addr_o),
    .opcode(opcode),
    .psw(psw),
    .usermode_i(usermode_i),
    .ctrl(dpcmd),
    .alucc(alucc),
    .taken(dp_taken),
    .PC(PC),
    .ALU1(ALU1),
    .ALUOUT(ALUOUT),
    .SRC(SRC),
    .DST(DST)
`ifdef WITH_RTEST   
    , .Rtest(Rtest)
`endif  
    );
    
assign test_bus = {DIN|DOUT,DIN,DOUT,RPLY,error_i,error_bus,DIN,DOUT};

reg [7:0] initctr;
wire      initq;
always @(posedge clk) begin
    if (ce) begin
        if (initq) initctr <= 10;
        if (initctr != 0) initctr <= initctr - 1'b1;
    end
end

assign INIT = initctr != 0;

endmodule

