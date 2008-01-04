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
output	[7:0]	buff_idata;
output	[7:0]	buff_odata;

output	[7:0]	track;
output	[7:0]	sector;
output	[7:0]	cpu_command;
input	[7:0]	cpu_status;
output	[7:0]	wd_status;
output			wtf;

wire	[7:0]	buff_idata;

wd1793 vg93(.clk(clk), .clken(1'b1), .reset_n(reset_n),
			.rd(rd), .wr(wr), .addr(addr), .idata(idata), .odata(odata),
			.buff_addr(buff_addr), .buff_rd(buff_rd), .buff_wr(buff_wr), 
			.buff_idata(buff_idata), .buff_odata(buff_odata),
			.oTRACK(track), 
			.oSECTOR(sector), 
			.oCPU_REQUEST(cpu_command), 
			.iCPU_STATUS(cpu_status), 
			.oSTATUS(wd_status), 
			.wtf(wtf));

fake_ram fauxpaw(
	.address(buff_addr),
	.data(buff_odata),
	.inclock(~clk), .outclock(clk),
	.wren(buff_wr),
	.q(buff_idata));
			
endmodule


			
module fake_ram(
	address,
	data,
	inclock,
	outclock,
	wren,
	q);

	input	[3:0]  address;
	input	[7:0]  data;
	input	  inclock;
	input	  outclock;
	input	  wren;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	altsyncram	altsyncram_component (
				.wren_a (wren),
				.clock0 (inclock),
				//.clock1 (outclock),
				.address_a (address),
				.data_a (data),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.init_file = "FAUXPAW.HEX",
		altsyncram_component.intended_device_family = "Cyclone II",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 16,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.ram_block_type = "M4K",
		altsyncram_component.widthad_a = 4,
		altsyncram_component.width_a = 8,
		altsyncram_component.width_byteena_a = 1;

endmodule
			