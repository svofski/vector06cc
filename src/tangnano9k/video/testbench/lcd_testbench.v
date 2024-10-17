`timescale 1ns/10ps

`default_nettype none

module lcd_testbench;

reg clk=0;
always #2 clk <= ~clk;

initial begin
    $dumpvars(0, r1);

    #2100000 $finish;
end

vga_refresh r1(.clk24(clk), .video_scroll_reg(8'hff));

endmodule
