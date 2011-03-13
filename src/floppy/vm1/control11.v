// =======================================================
// 1801VM1 SOFT CPU
// Copyright(C)2005 Alex Freed, 2008-2010 Viacheslav Slavinsky 
// Based on original POP-11 design (C)2004 Yoshihiro Iida
//
// Distributed under the terms of Modified BSD License
// ========================================================
// LSI-11 Control Chip
// --------------------------------------------------------

`default_nettype none
`include "instr.h"
`include "opc.h"

module     control11(clk, 
                ce, 
                reset_n, 
                dpcmd, 
                ierror, 
                ready_i, 
                dati_o,
                dato_o,
                mbyte, 
                dp_opcode,
                dp_taken,
                dp_alucc,
                psw,    
                ifetch,            
                irq_in,
                iako,
                idcop,
                idc_cco, 
                idc_bra, 
                idc_nof, 
                idc_rsd, 
                idc_dop, 
                idc_sop, 
                idc_unused,
                initq, 
                test);
                
input               clk;
input               ce;
input               reset_n;
output reg [127:0]  dpcmd;
input               ierror;
input               ready_i;
input               dp_taken;
input     [15:0]    dp_opcode;
input      [3:0]    dp_alucc;
input     [15:0]    psw;
output              ifetch;
input               irq_in;
output reg          iako;
input[`IDC_NOPS:0]  idcop;
output reg          dati_o, dato_o;
output reg          mbyte;
input               idc_cco, idc_bra, idc_nof, idc_rsd, idc_dop, idc_sop, idc_unused;
output reg          initq;

output        [7:0]    test;

assign test = state;

parameter [5:0]    BOOT_0 = 0,
                FS_IF0 = 1,
                FS_IF1 = 2,
                FS_ID0 = 3,
                FS_ID1 = 4,
                FS_OF0 = 5,
                FS_OF1 = 6,
                FS_OF2 = 7,
                FS_OF3 = 8, 
                FS_OF4 = 9,
                FS_BR0 = 10,
                FS_CC0 = 11,
        
                EX_0 = 16,
                EX_1 = 17,
                EX_2 = 18,
                EX_3 = 19,
                EX_4 = 20,
                EX_5 = 21,
                EX_6 = 22,
                EX_7 = 23,
                EX_8 = 24,
                
                WB_0 = 32,

                TRAP_1 = 49,
                TRAP_2 = 50,
                TRAP_3 = 51,  
                TRAP_4 = 52,
                TRAP_IRQ = 55,
                TRAP_SVC = 56
                
`ifdef VM1_WAITSTATES
                ,WAIT = 60
`endif
                ;

reg [5:0] state, next;

`ifdef VM1_WAITSTATES
reg [5:0] next_postponed;
`endif

parameter SRC_OP = 1'b0,
          DST_OP = 1'b1;

reg opsrcdst_to,    // comb
    opsrcdst_r;     // clocked reg

wire [1:0]   MODE = dp_opcode[5:4];
wire         INDR = dp_opcode[3];
wire         SPPC = dp_opcode[2] & dp_opcode[1];
wire     AUTO_INC = dp_opcode[4];
wire     AUTO_DEC = dp_opcode[5];
wire         BYTE = dp_opcode[15];
wire        TRACE = psw[4]; 

assign     ifetch = state == FS_IF0;

`define dp(x) dpcmd[x] = 1'b1

reg         rsub, rsub_r;       
reg         mbyte_r;            // registered value of (comb) mbyte

`ifdef VM1_WAITSTATES

// stretched ready
reg         ready_r;
always @(posedge clk or negedge reset_n)
    if (!reset_n) 
        ready_r <= 0;
    else begin
        ready_r <= ready_i ? ready_i : ce ? ready_i : ready_r;
    end
wire        ready = ready_r | ready_i;    

`else

wire        ready = ready_i;

`endif

reg        dato;
reg        dato_r;

parameter   di_com = 0, 
            di_of4 = 1, 
            di_of1 = 2, 
            di_t1 = 3, 
            di_t2 = 4, 
            di_last = 4;
            
reg [di_last:0]     datist;
reg [di_last:0]     datist_r;

wire       di_ready = datist_r[di_com] & ready;

function diready;
input s;
begin
    diready = datist_r[s] & ready;
end endfunction

task datain;
input s;
begin
    datist[s] = 1'b1;
end endtask


parameter   do_com = 0,
            do_t3 = 1,
            do_t4 = 2,
            do_last = 3;
            
reg [do_last:0]     datost;
reg [do_last:0]     datost_r;            
            
wire       do_ready = datost_r[do_com] & ready;

function doready;
input s;
begin
    doready = datost_r[s] & ready;
end endfunction

task dataout;
input s;
begin
    datost[s] = 1'b1;
end endtask

always @* begin
    dato_o = |datost;
    dati_o = |datist;
end

reg waiting;

// These states (or substates) never attempt a memory i/o.
// They do not require the REPLY signal to be cleared and
// they should not require extra WAIT states.
wire neverwait = 
                 (next == FS_ID0)          
               ||(next == FS_OF2) 
               //||((next == FS_OF1) && !(MODE == 2'b11)) -- why this one fails?
               ||((next == EX_0) && !(idcop[`drtt]|idcop[`drti]))  // only rtt and rti use RAM on EX0
                 ;

// async reset is necessary if clock stops on reset too
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
`ifdef VM1_WAITSTATES
        next_postponed <= BOOT_0;
`endif        
        state <= BOOT_0;
        datist_r <= 0;
        datost_r <= 0;
    end
    else if (ce) begin
        //$display("^state=%d->%d ce=%b", state, next, ce);
        
`ifdef VM1_WAITSTATES
        // if reply is high by the time of state switching, 
        // fall into the WAIT state, saving next.
        // when ready is released, continue using next_postponed.
        
        if (ready_i && ~waiting && state != next && ~neverwait) begin
            next_postponed <= next;
            state <= WAIT;
        end else begin
`endif        
            state <= next;
`ifdef VM1_WAITSTATES
        end
`endif        
        
        
        datist_r    <= datist;
        datost_r    <= datost;
        opsrcdst_r  <= opsrcdst_to;
        rsub_r      <= rsub;
        mbyte_r     <= mbyte;
    end
end

always @* begin
    begin

`ifdef VM1_WAITSTATES
        waiting = 1'b0;
`endif        
        datost = 0;
        datist = 0;
        
        dpcmd = 128'b0;
        initq = 1'b0;
        iako = 1'b0;
        
        opsrcdst_to = opsrcdst_r;
        mbyte = mbyte_r;
        rsub  = rsub_r;

        next = state;
        
        case (state)
`ifdef VM1_WAITSTATES
        WAIT:   begin 
                    waiting = 1'b1;
                    if (~ready) next <= next_postponed;
                end
`endif        
        BOOT_0: begin
                    `dp(`SETPCROM);
                    next = FS_IF0;
                end
        FS_IF0: begin 
                    `dp(`DBAPC);
                    mbyte = 0;
                    
                    if (~TRACE & irq_in)    
                        next = TRAP_IRQ;
                    else                                        // breakpoint if T, but not 
                    if (TRACE & ~idcop[`drtt]) begin            // if the last instruction was RTT
                        `dp(`BPT);    
                        next = TRAP_SVC;    
                    end 
                    else begin
                        if (ierror) begin
                            next = TRAP_SVC;
                            `dp(`BUSERR);
                        end else if (di_ready) begin
                            // accept data (opcode)
                            next = FS_ID0;
                            //$display("IF0: ready, state=%d next=%d ce=%d", state, next, ce);
                            `dp(`PCALU1);
                            `dp(`INC2);
                            `dp(`ALUPC);
                            `dp(`SETOPC);
                        end else begin
                            datain(di_com);
                        end
                    end
                end
                
                // Instruction Decode (3)
        FS_ID0:    begin
                    
                    if (idc_unused) begin
                        `dp(`ERR);
                        next = TRAP_SVC;
                    end else if (idc_rsd) begin
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = DST_OP;
                        next = FS_OF0;
                    end else if (idc_nof) begin
                        next = EX_0;
                    end else if (idc_cco) begin
                        next = FS_CC0;
                    end else if (idc_bra) begin
                        `dp(`CCTAKEN); // latch condition 
                        next = FS_BR0;
                    end else if (idc_sop) begin
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = SRC_OP;
                        next = FS_OF1;
                    end else if (idc_dop) begin
                        opsrcdst_to = DST_OP;
                        next = FS_OF1;
                    end
                    
                    if (idcop[`dadd]) begin
                        rsub = 1'b0;
                    end 
                    else if (idcop[`dsub]) begin
                        rsub = 1'b1; 
                        `dp(`RESET_BYTE);
                    end
                end
                
                // direct register read (5)
        FS_OF0:    begin
                    `dp(`REGSEL);
                    `dp(`SELSRC);
                    `dp(`CHANGE_OPR);
                    
                    next = FS_OF1;
                end
                
                // Operand Fetch #1 (6)
        FS_OF1: begin
                    //$display("FS_OF1: %b opsrcdst_r=%b to %b, ready=%b INDR=%b", MODE, opsrcdst_r, opsrcdst_to, di_ready, INDR);
                    case (MODE) 
                    2'b 00: begin
                            `dp(opsrcdst_r == SRC_OP ? `SELSRC : `SELDST);
                            `dp(`REGSEL); // load DST from selected reg on next clk
                            
                            if (INDR) next = FS_OF4;
                            else if (opsrcdst_r == DST_OP) begin 
                                next = EX_0;
                            end 
                            else if (opsrcdst_r == SRC_OP) begin
                                //$display("FS_OF1: SWITCH to DST_OP");
                                opsrcdst_to = DST_OP;
                                `dp(`CHANGE_OPR);
                                next = FS_OF1; // fetch other operand
                            end
                            end
                            
                    2'b 01: begin
                            // 01(0), 01(1): register autoincrement
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`INC);
                            if (~BYTE | (INDR|SPPC)) `dp(`INC2);
                            `dp(opsrcdst_r == SRC_OP ? `SELSRC : `SELDST);
                            next = FS_OF3;
                            end
                            
                    2'b 10: begin
                            `dp(`REGSEL); `dp(`SELALU1);
                            `dp(`ALUREG); `dp(`SETREG);
                            if (BYTE & ~(INDR|SPPC)) `dp(`DEC);
                            if (~BYTE | (INDR|SPPC)) `dp(`DEC2);
                            `dp(opsrcdst_r == SRC_OP ? `ALUSRC : `ALUDST);
                            next = FS_OF3;
                            end
                            
                    2'b 11: begin
                            //$display("FS_OF1:11 next=%d", next);
                            mbyte = 0;
                            `dp(`DBAPC);
                            if (ierror) begin
                                next = TRAP_SVC;        
                                `dp(`BUSERR);
                            end else if (diready(di_of1)) begin
                                `dp(`PCALU1); `dp(`INC2); `dp(`ALUPC);
                                `dp(opsrcdst_r == SRC_OP ? `DBISRC : `DBIDST);
                                next = FS_OF2;
                            end else begin
                                datain(di_of1);
                            end
                            
                            end
                    endcase
                end
                
                // Computes effective address in index mode (7)
        FS_OF2: begin 
                `dp(`REGSEL); `dp(`SELALU1); `dp(`ADD);
                if (opsrcdst_r == SRC_OP) begin 
                    `dp(`SRCALU2); `dp(`ALUSRC);
                end
                if (opsrcdst_r == DST_OP) begin
                    `dp(`DSTALU2); `dp(`ALUDST);
                end
                
                next = FS_OF3;
                end
                
                // First step memory read. Used by Auto-inc,dec,index mode. (8)
        FS_OF3: begin
                //$display("OF3 dati=%d datir=%d di_ready=%d opsrcdst=%b", dati, dati_r, di_ready, opsrcdst_r);
                `dp(opsrcdst_r == SRC_OP ? `DBASRC : `DBADST);
                mbyte = INDR ? 1'b0 : BYTE;
                if (ierror) begin
                    next = TRAP_SVC;
                    `dp(`BUSERR);
                end else if (di_ready) begin
                    if (opsrcdst_r == DST_OP) begin
                        //$display("OF3 end memory read DST");
                        `dp(`DBIDST); // load DST from DBI
                        `dp(`DSTADR); // load ADR from DST
                    end else begin
                        //$display("OF3 end memory read SRC");
                        `dp(`DBISRC); // load SRC from DBI
                        `dp(`SRCADR); // load ADR from SRC
                    end
                    
                    if (INDR) 
                        next = FS_OF4;
                    else if (opsrcdst_r == DST_OP) begin
                        next = EX_0;
                    end else begin
                        `dp(`CHANGE_OPR);
                        //$display("FS_OF3: SWITCH to DST_OP -> FS_OF1");
                        opsrcdst_to = DST_OP;
                        next = FS_OF1;
                    end
                end else begin
                    // initiate memory read
                    datain(di_com);
                end
                end
                
                // Deferred instruction (9)
        FS_OF4: begin
                mbyte = BYTE;
                if (opsrcdst_r == DST_OP) begin
                    `dp(`DBADST);
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end 
                    else if (diready(di_of4)) begin
                        `dp(`DSTADR);   // ADR <= DST @clk save loaded data into ADR
                        `dp(`DBIDST);   // DST <= DBI @ clk input data to DST
                        next = EX_0;
                    end else begin
                        // initiate memory read
                        datain(di_of4);
                    end
                end else begin        // SRC
                    `dp(`DBASRC);
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end
                    else if (diready(di_of4)) begin
                        `dp(`SRCADR); 
                        `dp(`DBISRC);
                        `dp(`CHANGE_OPR);
                        opsrcdst_to = DST_OP;
                        next = FS_OF1;
                    end else begin
                        datain(di_of4);
                    end
                end
                
                end
        
        FS_CC0:    begin
                    `dp(`CCSET);
                    
                    next = FS_IF0;
                    if (~TRACE & irq_in) next = TRAP_IRQ;
                    if (TRACE) begin `dp(`BPT);    next = TRAP_SVC; end
                end
                
        FS_BR0:    begin
                    if (dp_taken) begin
                        `dp(`PCALU1); `dp(`OFS8ALU2); 
                        `dp(`ADD); `dp(`ALUPC);
                    end
                    
                    next = FS_IF0;
                    if (~TRACE & irq_in) next = TRAP_IRQ;
                    if (TRACE) begin `dp(`BPT);    next = TRAP_SVC; end
                end
        // ifetch states end here
        
        // execution states
                
        EX_0,EX_1,EX_2,EX_3,EX_4,EX_5,EX_6,EX_7,EX_8:     
                begin
                    // set datapath to execute decoded instruction
                    case (1'b 1) // synopsys parallel_case
                    idcop[`dclr]: begin `dp(`DSTALU1); `dp(`CLR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dcom]: begin `dp(`DSTALU1); `dp(`COM); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dinc]: begin `dp(`DSTALU1); `dp(`INC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`ddec]: begin `dp(`DSTALU1); `dp(`DEC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dneg]: begin `dp(`DSTALU1); `dp(`NEG); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dadc]: begin `dp(`DSTALU1); `dp(`ADC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dsbc]: begin `dp(`DSTALU1); `dp(`SBC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dtst]: begin `dp(`DSTALU1); `dp(`TST); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dror]: begin `dp(`DSTALU1); `dp(`ROR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`drol]: begin `dp(`DSTALU1); `dp(`ROL); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dasr]: begin `dp(`DSTALU1); `dp(`ASR); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dasl]: begin `dp(`DSTALU1); `dp(`ASL); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dsxt]: begin `dp(`DSTALU1); `dp(`SXT); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    
                    idcop[`dmov]: begin `dp(`SRCALU1); `dp(`MOV); `dp(`ALUDST);  `dp(`ALUCC); next = WB_0; end
                    
                    idcop[`dcmp]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`CMP); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dbit]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIT); `dp(`ALUCC); next = FS_IF0; end
                    idcop[`dbic]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIC); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dbis]: begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`BIS); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dadd]: 
                                if (!rsub_r) begin
                                    `dp(`SRCALU1); `dp(`DSTALU2); `dp(`ADD); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; 
                                end else begin
                                    `dp(`SRCALU2); `dp(`DSTALU1); `dp(`SUB); `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; 
                                end
                    idcop[`dexor]:begin `dp(`SRCALU1); `dp(`DSTALU2); `dp(`EXOR);    `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end
                    idcop[`dswab]:begin `dp(`DSTALU1); `dp(`SWAB);    `dp(`ALUDSTB); `dp(`ALUCC); next = WB_0; end

                    idcop[`dnop]: begin next = FS_IF0; end
                    idcop[`djmp]: begin 
                                      if (MODE == 2'b00 && ~INDR) begin
                                          // can't  jump to a register
                                          next = TRAP_SVC;
                                          `dp(`BUSERR);
                                      end else begin
                                          `dp(`ADRPC); 
                                          next = FS_IF0; 
                                      end
                                  end

                    idcop[`dbpt]: begin `dp(`BPT); next = TRAP_SVC; end
                    idcop[`diot]: begin `dp(`IOT); next = TRAP_SVC; end
                    idcop[`demt]: begin `dp(`EMT); next = TRAP_SVC; end
                    idcop[`dtrap]:begin `dp(`SVC); next = TRAP_SVC; end

                    idcop[`dspl]: begin `dp(`SPL); next = FS_IF0; end
                    
                    idcop[`dreset]: begin initq = 1'b1; next = FS_IF0; end

                    idcop[`dhalt]: begin `dp(`BUSERR); next = TRAP_SVC; end // this will trap to 4 in VM1 (originally `dp(`HALT))

                    idcop[`diwait]: if (irq_in) next = FS_IF0; 
                                
                    
                    idcop[`dsob]: begin
                                    case (state) // synopsys parallel_case
                                    EX_0: begin
                                            `dp(`REGSEL2); `dp(`SELALU1); `dp(`DEC); `dp(`ALUREG); `dp(`SETREG2);
                                            `dp(`CCGET);
                                            next = EX_1;
                                          end
                                    EX_1: begin
                                            if (~dp_alucc[2]) begin
                                                `dp(`PCALU1); `dp(`OFS6ALU2); `dp(`SUB); `dp(`ALUPC);
                                            end
                                            next = FS_IF0;
                                          end
                                    endcase
                                  end
                                
                    // gruuu...
                    idcop[`djsr]: begin
                                    case (state)
                                    EX_0: begin
                                            if (MODE == 2'b00 && ~INDR) begin
                                                // can't jump to a register
                                                // trap must happen now, before return address is pushed
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end else begin
                                                `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                                                next = EX_1;
                                            end
                                          end
                                    EX_1: begin
                                            mbyte = 1'b0;
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (do_ready) begin
                                                `dp(`PCREG); `dp(`SETREG2);
                                                next = EX_2;
                                            end else begin
                                                dataout(do_com);
                                                `dp(`REGSEL2); `dp(`DBOSEL); `dp(`DBASP);
                                            end
                                          end
                                    EX_2: begin
                                              `dp(`ADRPC); 
                                              next = FS_IF0; 
                                          end
                                    endcase
                                  end
                                
                    idcop[`drts]: begin
                                    case (state)
                                    EX_0: begin
                                            `dp(`REGSEL); `dp(`SELPC);
                                            next = EX_1;
                                          end
                                    
                                    EX_1: begin
                                            mbyte = 1'b0;
                                            `dp(`DBASP);
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (di_ready) begin
                                                `dp(`DBIREG);   // REGin = DBI (comb)
                                                `dp(`SETREG);   // R[dst] = REGin (clk)
                                                
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                datain(di_com);
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`drtt],            
                    idcop[`drti]: begin
                                    `dp(`DBASP);
                                    case (state)
                                    EX_0: begin
                                            mbyte = 1'b0;
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end
                                            else if (di_ready) begin
                                                `dp(`DBIPC);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = EX_1;
                                            end else begin
                                                datain(di_com);
                                            end
                                          end
                                    EX_1: begin
                                            mbyte = 1'b0;
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end
                                            else if (di_ready) begin
                                                `dp(`DBIPS); 
                                                `dp(`MODEIN); // set usermode to usermode_i
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                datain(di_com);
                                            end
                                          end
                                    endcase
                                  end
                                
                    idcop[`dmark]:begin
                                    // gruuu..
                                    case (state)
                                    EX_0: begin
                                            // SP = PC + 2x(arg)
                                            `dp(`PCALU1); `dp(`OFS6ALU2); 
                                            `dp(`ADD); `dp(`ALUSP);
                                            `dp(`FPPC);
                                            next = EX_1;
                                          end
                                    EX_1: begin
                                            `dp(`DBASP);
                                            mbyte = 1'b0;
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (di_ready) begin
                                                `dp(`DBIFP);
                                                `dp(`SPALU1); `dp(`INC2); `dp(`ALUSP);
                                                next = FS_IF0;
                                            end else begin
                                                datain(di_com);
                                            end
                                          end
                                    endcase
                                  end
                    idcop[`dmtps]:begin // PSW <- ss
                                  `dp(`DSTPSW);
                                  next = FS_IF0;
                                  end
                    idcop[`dmfps]:begin // dd <- PSW, set flags
                                  `dp(`PSWALU1);
                                  `dp(`ALUDST); 
                                  `dp(`MOV); 
                                  `dp(`ALUCC);
                                  next = WB_0;
                                  end
                    idcop[`dmfpi]:begin 
                                  // move from previous instruction space
                                  case (state)
                                  EX_0: begin
                                        // fetch source
                                        `dp(`MODESWAP);
                                        next = EX_1;
                                        end
                                  EX_1: begin
                                            mbyte = 1'b0;
                                            if (dp_opcode[5:3] != 0) begin
                                                `dp(`DBADST); // was DBAADR
                                                // move from previous memory
                                                if (ierror) begin
                                                    `dp(`BUSERR);
                                                    `dp(`MODESWAP);
                                                    next = TRAP_SVC;
                                                 end else if (di_ready) begin
                                                    `dp(`MODESWAP);
                                                    `dp(`DBIDST);
                                                    next = EX_2;
                                                 end else begin
                                                    datain(di_com);
                                                 end
                                            end
                                            else begin
                                                // move from previous register
                                                `dp(`MODESWAP); // will switch on clk, so move from uSP will work
                                                `dp(`REGSEL);
                                                `dp(`SELDST);
                                                next = EX_2;
                                            end
                                        end
                                  EX_2: begin
                                            // back in kernel mode: mov dst, -(sp)
                                            `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                                            next = EX_3;
                                        end
                                  EX_3: begin
                                            mbyte = 1'b0;
                                            if (ierror) begin
                                                `dp(`BUSERR);
                                                next = TRAP_SVC;
                                            end 
                                            else if (do_ready) begin
                                                `dp(`SRCALU1); `dp(`ALUCC);
                                                next = FS_IF0;
                                            end else begin
                                                dataout(do_com);
                                                `dp(`DBODST); `dp(`DBASP);
                                            end
                                        end
                                  endcase
                                  end
                    idcop[`dmtpi]:begin
                                  end
                    endcase // idcop
                end // EX_*
                
        WB_0:     begin
                    if (dp_opcode[5:3] != 0) begin
                        if (ierror) begin
                            `dp(`BUSERR);
                            next = TRAP_SVC;
                        end
                        else if (do_ready) begin
                            // - dataout(do_com);
                            `dp(`DBODST); `dp(`DBAADR);

                            if (TRACE) begin
                                `dp(`BPT); 
                                next = TRAP_SVC;
                            end 
                            else if (irq_in) 
                                next = TRAP_IRQ;
                            else
                                next = FS_IF0;
                        end else begin
                            dataout(do_com);
                            mbyte = BYTE;
                            `dp(`DBODST); `dp(`DBAADR);
                            //$display("DBODST DBAADR: ADR=%o", dp.ADR);
                        end
                    end 
                    else begin
                        `dp(`DSTREG); `dp(`SETREG);
                        if (TRACE) begin
                            `dp(`BPT); 
                            next = TRAP_SVC;
                        end 
                        else if (irq_in) 
                            next = TRAP_IRQ;
                        else
                            next = FS_IF0;                        
                    end
                    
                end
        
            // it's a trap!
        TRAP_IRQ: begin
                    `dp(`RESET_BYTE); 
                    `dp(`SAVE_STAT);
                    `dp(`DBISRC);   // read interrupt vector from dbi
                    `dp(`MODEIN);   // set usermode to usermode_i
                    iako = 1'b1; 
                    mbyte = 1'b0;
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (di_ready) begin
                        next = TRAP_1;
                    end else begin
                        datain(di_com);
                    end
                  end
        
        TRAP_SVC: begin
                    `dp(`RESET_BYTE); 
                    `dp(`SAVE_STAT);
                    `dp(`MODEIN);   // set usermode to usermode_i: for EMT hooks
                    next = TRAP_1;
                  end
                
        TRAP_1:    begin
                    `dp(`DBASRC);    // trap vector
                    `dp(`DBIPC);
                    mbyte = 1'b0;
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (diready(di_t1)) begin
                        `dp(`SRCALU1); `dp(`INC2); `dp(`ALUSRC);
                        next = TRAP_2;
                    end else begin
                        datain(di_t1);
                    end
                end
                
        TRAP_2: begin
                    `dp(`DBASRC);     // vector+2/priority
                    `dp(`VECTORPS);
                    mbyte = 1'b0;
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (diready(di_t2)) begin
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                        next = TRAP_3;
                    end else begin
                        datain(di_t2);
                    end
                end
                
        TRAP_3:    begin
                    `dp(`DBODST); 
                    `dp(`DBASP);
                    mbyte = 1'b0;// Mr.Iida has BYTE here
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (doready(do_t3)) begin
                        `dp(`SPALU1); `dp(`DEC2); `dp(`ALUSP);
                        next = TRAP_4;
                    end else begin
                        dataout(do_t3);
                    end
                end
                
        TRAP_4: begin
                    `dp(`DBOADR); 
                    `dp(`DBASP);
                    if (ierror) begin
                        `dp(`BUSERR);
                        next = TRAP_SVC;
                    end else if (doready(do_t4)) begin
                        next = FS_IF0;
                    end else begin
                        dataout(do_t4);
                    end
                end
        endcase // state
    end
end


endmodule

