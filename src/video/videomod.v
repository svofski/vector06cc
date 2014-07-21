// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2009 Viacheslav Slavinsky
//
// This core is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// Video outputs, modulated and regular
//
// --------------------------------------------------------------------


`default_nettype none

module videomod(
    input clk_color_mod,

    input [3:0] video_r,
    input [3:0] video_g,
    input [3:0] video_b,
    input       vga_hs,
    input       vga_vs,
    input [4:0] tv_cvbs,
    input [4:0] tv_luma,
    input [4:0] tv_chroma,
    input [1:0] tv_mode,

    output VGA_HS,
    output VGA_VS,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output S_VIDEO_Y,
    output S_VIDEO_C,
    output CVBS
);


wire [3:0] tv_out;

`ifdef WITH_COMPOSITE
    `ifdef COMPOSITE_PWM
        reg [5:0] cvbs_pwm;
        always @(posedge clk_color_mod)
            cvbs_pwm <= cvbs_pwm[4:0] + tv_cvbs[4:0];
        assign tv_out = {4{cvbs_pwm[5]}};
    `else
        assign tv_out = tv_cvbs[4:1];
    `endif
`else
    assign tv_out = 4'b0;
`endif

`ifdef WITH_SVIDEO
    reg [5:0] luma_pwm;
    reg [5:0] chroma_pwm;
    always @(posedge clk_color_mod) begin
        luma_pwm <= luma_pwm[4:0] + tv_luma[4:0];
        chroma_pwm <= chroma_pwm[4:0] + tv_chroma[4:0];
    end
    assign S_VIDEO_Y = luma_pwm[5];
    assign S_VIDEO_C = chroma_pwm[5];
`endif

`ifdef WITH_COMPOSITE 
    `ifdef WITH_VGA
        assign VGA_R = tv_mode[0] ? tv_out : video_r;
        assign VGA_G = tv_mode[0] ? tv_out : video_g;
        assign VGA_B = tv_mode[0] ? tv_out : video_b;
    `else
        assign VGA_R = tv_out;
        assign VGA_G = tv_out;
        assign VGA_B = tv_out; 
    `endif
`else
    `ifdef WITH_VGA
        assign VGA_R = video_r;
        assign VGA_G = video_g;
        assign VGA_B = video_b;
    `else
        assign VGA_R = 4'b0;
        assign VGA_G = 4'b0;
        assign VGA_B = 4'b0; 
    `endif
`endif

assign VGA_VS = vga_vs;
assign VGA_HS = vga_hs;

endmodule
