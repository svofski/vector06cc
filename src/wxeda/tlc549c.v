`default_nettype none

module tlc549c(
	input				clk24,

	input				adc_data_in,
	output reg	[7:0]   adc_data,
	output 				adc_clk,
	output reg			adc_cs_n
);
	
	reg	[7: 0]		adc_data_buf;
	
	reg	[3: 0]		cnt;
	reg				adc_clk_valid;
	reg				adc_cs_n_valid;

	reg 			clk_40k;
	
	parameter SP_DIV = 5'd25;  
	
	reg [3:0] clkdiv;
    reg clk_1m;
    wire ce_1m = clkdiv == 4'd0 && clk_1m;
    wire ce_2m = clkdiv == 4'd0;
	always@(posedge clk24) begin
        if (clkdiv + 1'b1 == 4'd12) begin
            clkdiv <= 0;
            clk_1m = !clk_1m;
        end
        else    
            clkdiv <= clkdiv + 1'b1;
    end
    
	
	reg [8:0] cnt1;
    wire ce_40k = cnt1 == 0 && clk_40k;

	always @(posedge clk24)
	begin
        if (ce_2m) begin
            if(cnt1 + 1'b1 == 9'd25) begin
                cnt1 <= 0;
                clk_40k = !clk_40k;
            end
            else
                cnt1 <= cnt1 + 1'b1;
        end

		//adc_clk_valid <= !((cnt == 0) | (cnt == 1) | (cnt == 10));
		//adc_cs_n <= !((cnt == 0) | (cnt == 10));

	end
    
	always@(posedge clk24)
        if (ce_1m) begin
            if(clk_40k == 0)
                cnt <= 0;
            else if(cnt == 10)
                cnt <= 10;
            else
                cnt <= cnt + 1'b1;
                
            adc_clk_valid <= !((cnt == 0) | (cnt == 1) | (cnt == 10));
            adc_cs_n <= (cnt == 0) | (cnt == 10);
		end
    
    	//assign adc_clk = adc_clk_valid ? clk_1m : 1'b0;
    assign adc_clk = clk_1m;

//	always@(posedge adc_clk)
//		if(adc_cs_n == 0)
//			adc_data_buf <= {adc_data_in, adc_data_buf[7:1]};
    always @(posedge clk24)
    begin
        if (ce_1m)
            adc_data_buf <= {adc_data_in, adc_data_buf[7:1]};
        if (ce_1m && ce_40k)
            adc_data <= adc_data_buf;
    end
endmodule
