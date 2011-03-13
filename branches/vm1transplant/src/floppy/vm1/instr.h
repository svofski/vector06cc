`define INC2            1
`define DEC2            2  
`define INC             3  
`define DEC             4  
`define CLR             5  
`define COM             6  
`define NEG             7  
`define ADC             8  
`define SBC             9  
`define TST             10 
`define ROR             11  
`define ROL             12 
`define ASR             13  
`define ASL             14  
`define SXT             15  
`define MOV             16  
`define CMP             17  
`define BIT             18  
`define BIC             19  
`define BIS             20 
`define ADD             21  
`define SUB             22  
`define EXOR            23  
`define SWAB            24  
`define MMU             25
            
`define SETOPC          26
`define DBIDST          27
`define DBISRC          28
`define DBIPC           29
`define DBIREG          30
`define DBIPS           31
`define DBAPC           32
`define DBASP           33
`define DBADST          34
`define DBASRC          35
`define DBAADR          36
`define DBOSEL          37
`define DBODST          38
`define DBOSRC          39
`define DBOADR          40
`define PCALU1          41
`define SPALU1          42
`define DSTALU1         43
`define SRCALU1         44
`define DSTALU2         45
`define SRCALU2         46
`define ADRALU1         47
`define OFS8ALU2        48
`define OFS6ALU2        49
`define SELALU1         50
`define REGSEL          51
`define REGSEL2         52
`define SETREG          53
`define SETREG2         54
`define ALUREG          55
`define DSTREG          56
`define PCREG           57
`define SRCREG          58
`define ADRREG          59
`define ALUPC           60
`define ALUSP           61
`define ALUDST          62
`define ALUDSTB         63
`define ALUSRC          64
`define ALUCC           65
`define SELDST          66
`define SELSRC          67
`define SELADR          68
`define SELPC           69
`define DSTADR          70
`define SRCADR          71
`define ADRPC           72
`define SAVE_STAT       73
`define FPPC            74
`define DBIFP           75
`define SETPCROM        76
   
`define CHANGE_OPR      77
`define CHANGE_MODE     78
`define KERNEL_MODE     79
`define RESET_BYTE      80
`define VECTORPS        81
`define CCCLR           82
`define CCSET           83
`define CCTAKEN         84

`define BUSERR          85
`define ERR             86
`define BPT             87
`define EMT             88
`define IOT             89
`define SVC             90
`define SEGERR          91
`define SPL             92
`define CCGET           93
`define CLRADR          94
`define ODDREG          95
`define MUL             96
`define ASH             97
`define ASHC            98
        
`define DIV             99
`define DIV_END         100
`define DIV_INI0        101
`define DIV_INI1        102
`define DIV_INI2        103
`define DIV_FIN0        104
`define DIV_FIN1        105
`define TSTSRC          106
`define TSTSRCADR       107
`define CC		        108

`define PSWALU1		109
`define DSTPSW		110

`define MODEIN		111
`define MODESWAP	112	

`define TRAP_BUS 16'o 00004
`define TRAP_ERR 16'o 00010
`define TRAP_BPT 16'o 00014
`define TRAP_IOT 16'o 00020
`define TRAP_POW 16'o 00024
`define TRAP_EMT 16'o 00030
`define TRAP_SVC 16'o 00034
`define TRAP_SEG 16'o 00250

                