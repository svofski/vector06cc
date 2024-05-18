/* Copyright (c) 2018 Upi Tamminen, All rights reserved.
 * See the LICENSE file for more information */

module rom #(parameter
    ADDR_WIDTH = 16,
    DATA_WIDTH = 8,
    DEPTH = 1024,
    ROM_FILE = "foo.hex")
(
    input wire clk,
    input wire cs,
    input wire [ADDR_WIDTH-1:0] addr, 
    output reg [DATA_WIDTH-1:0] data_out 
);

reg [DATA_WIDTH-1:0] memory_array [0:DEPTH-1]; 

initial begin
    $readmemh(ROM_FILE, memory_array);
end

always @(posedge clk) begin
    if (cs) begin
        data_out <= memory_array[addr];
    end
end

endmodule
