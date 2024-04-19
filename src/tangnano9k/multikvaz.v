module multikvaz(
    input clk24,
    input clke,
    input reset,
    input [15:0] address_r,
    input [7:0] data,
    input iowr,

    input [15:0] address,
    input stack,

    output [5:0] ramdisk_addr
);


wire [1:0] rdpage [7:0];
wire [7:0] rdsel;

reg [3:0] ramdisk_num;
reg [1:0] ramdisk_page;

always @*
begin
    casex (rdsel)
        8'b00000000:  {ramdisk_num, ramdisk_page} <= {4'b0000, 2'b00};
        8'b00000001:  {ramdisk_num, ramdisk_page} <= {4'b0001, rdpage[0]};
        8'b00000010:  {ramdisk_num, ramdisk_page} <= {4'b0010, rdpage[1]};
        8'b00000100:  {ramdisk_num, ramdisk_page} <= {4'b0011, rdpage[2]};
        8'b00001000:  {ramdisk_num, ramdisk_page} <= {4'b0100, rdpage[3]};
        8'b00010000:  {ramdisk_num, ramdisk_page} <= {4'b0101, rdpage[4]};
        8'b00100000:  {ramdisk_num, ramdisk_page} <= {4'b0110, rdpage[5]};
        8'b01000000:  {ramdisk_num, ramdisk_page} <= {4'b0111, rdpage[6]};
        8'b10000000:  {ramdisk_num, ramdisk_page} <= {4'b1000, rdpage[7]};
    default:          {ramdisk_num, ramdisk_page} <= 0;
    endcase
end


// 4 bits disk num 1..8 + 2 bits page
wire [5:0]  ramdisk_addr = {ramdisk_num, ramdisk_page};


wire [7:0] ramdisk_cw_wr;

assign ramdisk_cw_wr[0] = address_r == 8'h10 && iowr;
assign ramdisk_cw_wr[1] = address_r == 8'h11 && iowr;
assign ramdisk_cw_wr[2] = address_r == 8'h20 && iowr;
assign ramdisk_cw_wr[3] = address_r == 8'h21 && iowr;
assign ramdisk_cw_wr[4] = address_r == 8'h40 && iowr;
assign ramdisk_cw_wr[5] = address_r == 8'h41 && iowr;
assign ramdisk_cw_wr[6] = address_r == 8'h80 && iowr;
assign ramdisk_cw_wr[7] = address_r == 8'h81 && iowr;

reg [15:0] address_bus_kvaz;
always @(posedge clk24)
    address_bus_kvaz <= address;

genvar kv;
generate
    for (kv = 0; kv < 8; kv = kv + 1)
    begin
        kvaz ramdisk(
            .clk(clk24), 
            .clke(clke), 
            .reset(reset),
            .address(address_bus_kvaz),
            .select(ramdisk_cw_wr[kv]),
            .data_in(data),
            .stack(stack),
            .page(rdpage[kv]),
            .kvaz_sel(rdsel[kv]));
    end
endgenerate

endmodule
