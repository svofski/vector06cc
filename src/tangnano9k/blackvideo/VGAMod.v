// Based on Tang Nano 9K LCD example
// Generates HS/VS/DE for the 800x480 LCD RGB panel, nothing else
// can be used to blank out the screen
module VGAMod (
    input CLK,
    input nRST,

    input PixelClk,

    output LCD_DE,
    output LCD_HSYNC,
    output LCD_VSYNC
);

    reg [15:0] PixelCount;
    reg [15:0] LineCount;

    localparam V_BackPorch = 16'd0;  //6
    localparam V_Pluse = 16'd5;
    localparam HightPixel = 16'd480;
    localparam V_FrontPorch = 16'd45;  //62

    localparam H_BackPorch = 16'd182;
    localparam H_Pluse = 16'd1;
    localparam WidthPixel = 16'd800;
    localparam H_FrontPorch = 16'd210;

    parameter BarCount = 16;  // RGB565
    localparam Width_bar = WidthPixel / 16;

    localparam PixelForHS = WidthPixel + H_BackPorch + H_FrontPorch;
    localparam LineForVS = HightPixel + V_BackPorch + V_FrontPorch;

    always @(posedge PixelClk or negedge nRST) begin
        if (!nRST) begin
            LineCount  <= 16'b0;
            PixelCount <= 16'b0;
        end else if (PixelCount == PixelForHS) begin
            PixelCount <= 16'b0;
            LineCount  <= LineCount + 1'b1;
        end else if (LineCount == LineForVS) begin
            LineCount  <= 16'b0;
            PixelCount <= 16'b0;
        end else PixelCount <= PixelCount + 1'b1;
    end

    reg [9:0] Data_R;
    reg [9:0] Data_G;
    reg [9:0] Data_B;

    always @(posedge PixelClk or negedge nRST) begin
        if (!nRST) begin
            Data_R <= 9'b0;
            Data_G <= 9'b0;
            Data_B <= 9'b0;
        end
    end
    assign  LCD_HSYNC = (( PixelCount >= H_Pluse)&&( PixelCount <= (PixelForHS-H_FrontPorch))) ? 1'b0 : 1'b1;
    assign LCD_VSYNC = (((LineCount >= V_Pluse) && (LineCount <= (LineForVS - 0)))) ? 1'b0 : 1'b1;

    assign  LCD_DE = (  ( PixelCount >= H_BackPorch )&&
                        ( PixelCount <= PixelForHS-H_FrontPorch ) &&
                        ( LineCount >= V_BackPorch ) &&
                        ( LineCount <= LineForVS-V_FrontPorch-1 ))  ? 1'b1 : 1'b0;
endmodule
