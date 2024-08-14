module keymatrix_ram(
    input clk, 
    input [2:0] addr, 
    input wr,
    input [7:0] data_i,
    output reg [7:0] data_o);

reg [7:0] data [0:7];

always @(posedge clk)
begin
    if (wr)
        data[addr] <= data_i;
    else
        data_o <= data[addr];
end

`ifdef TESTBENCH
wire [63:0] datawires = {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]};
`endif

endmodule


