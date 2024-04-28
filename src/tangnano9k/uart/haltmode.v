`define UART_TX_V2 

module haltmode(
    input clk24,
    input rst_n,
    input uart_rx,
    output uart_tx,
    output [21:0] addr_o,     // ram address
    output [7:0] data_o,      // data
    output wr_o,              // write ram[addr_o] <= data_o
    output halt_o,            // halt the cpu
    output [11:0] fkeys_o     // fkeys
);

localparam CLK_FRE = 24;
localparam UART_FRE = 115200;

wire [7:0] rx_data;
wire rx_data_valid; // got data in receive reg
wire rx_data_ready = 1'b1; // ready to receive

reg [7:0] tx_data;
reg tx_data_valid;  // have data, send request
wire tx_data_ready; // ready to accept new data

localparam ST_INIT = 0;
localparam ST_START = 1;
localparam ST_RUN = 2;
localparam ST_HALT = 3;
localparam ST_RXHEX = 4;
localparam ST_ERROR = 5;

localparam ES_0 = 0;
localparam ES_1 = 1;
localparam ES_2 = 2;
localparam ES_3 = 3;
localparam ES_4 = 4;
localparam ES_5 = 5;
localparam ES_F11 = 6;
localparam ES_F12 = 7;

localparam HS_0 = 0;
localparam HS_1 = 1;
localparam HS_ERROR = 2;
localparam HS_ECHO = 3;

reg [3:0] state, state_p, state_h, state_hp, state_esc;

reg [11:0] fkeys;

assign fkeys_o = fkeys;

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk(clk24),
	.rst_n(rst_n),
	.rx_data(rx_data),
	.rx_data_valid(rx_data_valid),
	.rx_data_ready(rx_data_ready),
	.rx_pin(uart_rx)
);

`ifndef UART_TX_V2
uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk(clk24),
	.rst_n(rst_n),
	.tx_data(tx_data),
	.tx_data_valid(tx_data_valid),
	.tx_data_ready(tx_data_ready),
	.tx_pin(uart_tx)
);
`else
defparam tx.uart_freq=115200;
defparam tx.clk_freq=24_000_000;
`endif

`include "print.v"

assign print_clk = clk24;

//always @(posedge clk24) begin
//    if (rx_data_valid)
//    begin
//        tx_data <= rx_data;
//        tx_data_valid <= 1'b1;
//    end
//    else if(tx_data_valid && tx_data_ready)
//    begin
//        tx_data_valid <= 1'b0;
//    end
//end

assign halt_o = state == ST_HALT;

wire [7:0] ihex_data;
wire [21:0] ihex_addr;
wire ihex_error;
wire ihex_wr;

// interactor
always @(posedge clk24)
begin
    if (!rst_n)
    begin
        state <= ST_INIT;
        state_h <= HS_0;
        state_esc <= ES_0;
        fkeys <= 0;
    end
    else
    begin
        fkeys <= 0;

        if (state == ST_INIT) state <= ST_START;
        if (state == ST_START) state <= ST_RUN;    

        state_h <= HS_1;
        if (state == ST_HALT)
        begin
            if (ihex_error) state_h <= HS_ERROR;
        end

        if (rx_data_valid)
        begin
            state_h <= HS_ECHO;
            if (state == ST_RUN)
            begin
                if (state_esc == ES_0)
                    case (rx_data)
                        8'd3: // ctrl-c breaks into halt-mode
                        begin
                            state <= ST_HALT;
                            state_h <= HS_0;
                        end
                        8'd27:  // ESC
                            state_esc <= ES_1;
                    endcase
                else if (state_esc == ES_1)
                    case (rx_data)
                        "[":      state_esc <= ES_2; // ESC[n~ F-key  (11~ == F1, 23~ =F11, 24~i =F12
                        default:  state_esc <= ES_0; // unknown, reset
                    endcase
                else if (state_esc == ES_2)
                begin
                    case (rx_data)
                        "2": state_esc <= ES_3;
                        default: state_esc <= ES_0;
                    endcase
                end
                else if (state_esc == ES_3)
                begin
                    case (rx_data)
                        "3": state_esc <= ES_F11;   // ESC[23~
                        "4": state_esc <= ES_F12;   // ESC[24~
                        default: state_esc <= ES_0;
                    endcase
                end
                else if (state_esc == ES_F11)
                begin
                    if (rx_data == "~")
                        fkeys[10] <= 1'b1;
                    state_esc <= ES_0;
                end
                else if (state_esc == ES_F12)
                begin
                    if (rx_data == "~")
                        fkeys[11] <= 1'b1;
                    state_esc <= ES_0;
                end
                else
                begin
                    state_esc <= ES_0;
                end
            end
            else // state == ST_HALT
            case (rx_data)
                "c": state <= ST_RUN;
            endcase
        end
    end
end

// printer
always @(posedge clk24)
begin
    state_p <= state;
    state_hp <= state_h;
    if (state != state_p || state_h != state_hp)
    begin
        if (state == ST_INIT) `print("vector06cc debug probe. F11/F12 reset/restart; ^c ihex upload\n", STR);
        if (state == ST_RUN) `print("Running...\n", STR);
        if (state == ST_HALT) 
        begin
            if (state_h == HS_0) `print("Halt. Upload ihex, press c to continue\n", STR);
            // HS_1 keep quiet
            if (state_h == HS_ERROR) `print("Error\n", STR);
            if (state_h == HS_ECHO) `printc(rx_data == 8'd13 ? 8'd10 : rx_data);
        end
    end
end

intelhex_rx ihexrx(.clk_i(clk24), .ce_i(1'b1), .rst_n(rst_n), .data_i(rx_data),
    .rx_data_valid(rx_data_valid), 
    .addr_o(ihex_addr), .data_o(ihex_data), .wr_o(ihex_wr), 
    .error_o(ihex_error));

assign data_o = ihex_data;
assign addr_o = ihex_addr;
assign wr_o = ihex_wr;
assign error_o = ihex_error;

always @(posedge clk24) begin: _prompts

end
endmodule
