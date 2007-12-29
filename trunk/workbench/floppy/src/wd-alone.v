`default_nettype none

module wdalone(clk, reset_n, rd, wr, addr, idata, odata, buff_addr, buff_rd, buff_wr, buff_idata, buff_odata,
				track, sector, cpu_command, cpu_status, wd_status, wtf);
				
				
input	clk;
input	reset_n;
input	rd, wr;
input	[2:0]	addr;
input	[7:0]	idata;
output	[7:0]	odata;

output 	[8:0]	buff_addr;
output			buff_rd;
output			buff_wr;
input	[7:0]	buff_idata;
output	[7:0]	buff_odata;

output	[7:0]	track;
output	[7:0]	sector;
output	[7:0]	cpu_command;
input	[7:0]	cpu_status;
output	[7:0]	wd_status;
output			wtf;


wd1793 vg93(.clk(clk), .clken(1'b1), .reset_n(reset_n),
			.rd(rd), .wr(wr), .addr(addr), .idata(idata), .odata(odata),
			.buff_addr(buff_addr), .buff_rd(buff_rd), .buff_wr(buff_wr), .buff_idata(buff_idata), .buff_odata(buff_odata),
			.track(track), .sector(sector), .cpu_command(cpu_command), .cpu_status(cpu_status), .status(wd_status), 
			.wtf(wtf));
			
endmodule
			