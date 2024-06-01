/* Copyright (c) 2018 Upi Tamminen, All rights reserved.
 * See the LICENSE file for more information */

///////////////////////////////////////////////////////////////////////////////
// UART interface
///////////////////////////////////////////////////////////////////////////////

module uart_interface #(parameter
    SYS_CLK = 8000000,
    BAUDRATE = 115200
) (
    input               clk,
    input               reset,
    input               cs,
    input               rs, 
    input               we,
    input       [7:0]   din,
    output  reg [7:0]   dout,

    input               uart_rx,
    output              uart_tx,
    output              tx_busy
);

reg tx_start = 1'b0;
reg [7:0] tx_byte;
wire [7:0] rx_byte;

// edge detection for rx ready signal
wire uart_rx_ready; // signal from uart transceiver
reg [1:0] rx_ready_r = 2'b00;
wire rx_ready_posedge = rx_ready_r == 2'b01;
always @(posedge clk) rx_ready_r <= { rx_ready_r[0], uart_rx_ready };
reg rx_ready = 1'b0;

uart #(
    .SYS_CLK(SYS_CLK),
    .BAUDRATE(BAUDRATE)
) uart(
    .clk(clk),
    .reset(reset),
    .serial_out(uart_tx), // transmit data
    .tx_start(tx_start),
    .tx_byte(tx_byte),
    .tx_busy(tx_busy),
    .serial_in(uart_rx), // receive data (connect to UART_RX)
    .rx_byte(rx_byte),
    .rx_ready(uart_rx_ready)
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx_start <= 1'b0;
        tx_byte <= 8'd0;
    end
    else begin
        if (rx_ready_posedge) begin
            rx_ready <= 1'b1;
        end

        if (cs) begin
            if (we) case (rs)
                1'b0: // write to control register
                    begin
                        // nothing here
                    end
                1'b1: // transmitter data register
                    begin
                        if (!tx_busy) begin
                            tx_byte <= din;
                            tx_start <= 1'b1; // clear this somewhere
                            if (!tx_start) begin
                                $write("%c", tx_byte);
                                $fflush();
                            end
                        end
                    end
            endcase
            else begin

                // this may have been set by transmit, clear it
                tx_start <= 1'b0;

                case (rs)
                    1'b0: // status register
                        begin
                            dout <= { 6'b000000, !tx_busy, rx_ready };
                        end
                    1'b1: // receiver data register
                        begin
                            dout <= rx_byte;
                            rx_ready <= 1'b0;
                        end
                endcase
            end
        end
    end
end

endmodule

///////////////////////////////////////////////////////////////////////////////
// UART transceiver
///////////////////////////////////////////////////////////////////////////////

module uart #(parameter
    SYS_CLK = 50000000,
    BAUDRATE = 115200
) (
    input               clk,
    input               reset,

    // TX
    output  reg         serial_out = 1'b1,
    input               tx_start,
    input       [7:0]   tx_byte,
    output  reg         tx_busy = 1'b0,

    // RX
    input               serial_in,
    output  reg [7:0]   rx_byte = 8'd0,
    output  reg         rx_ready = 1'b0
);

localparam CLK_DIV = SYS_CLK / BAUDRATE; // max counter size
localparam
    IDLE    = 0,
    HALF    = 1,   // half-step for RX
    START   = 2,
    DATA    = 3,
    STOP1   = 4,
    STOP2   = 5;  // TX will have two stop bits

reg [12:0] txclock_counter = 0;
reg [12:0] rxclock_counter = 0;

reg [2:0] tx_state = IDLE;
reg [2:0] tx_bit_counter = 3'd0;

reg [2:0] rx_state = IDLE;
reg [2:0] rx_bit_counter = 3'd0;

// TX edge detect, signal supplied by user initiating transfer
reg [1:0] tx_start_r = 2'b00;

// RX edge detect, signal supplied by incoming data
reg [1:0] rx_start_r = 2'b00;

reg sampling = 1'b0;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        tx_state <= IDLE;
        tx_bit_counter <= 3'd0;
        tx_start_r <= 2'b00;
        rxclock_counter <= 0;
        txclock_counter <= 0;
    end
    else begin

        ///////////////////////////////////////////////////////////////////////
        // TX
        ///////////////////////////////////////////////////////////////////////

        // edge detection for activate signal
        tx_start_r <= { tx_start_r[0], tx_start };
        if (tx_start_r == 2'b01 && !tx_busy) begin
            txclock_counter <= 0;
            tx_state <= DATA;
            tx_busy <= 1'b1;
            serial_out <= 1'b0; // start bit
        end

        // transmit byte at 1x baud rate
        else if (txclock_counter == CLK_DIV-1) begin
            txclock_counter <= 0;

            case (tx_state)
                IDLE:
                    tx_busy <= 1'b0;
                DATA:
                    begin
                        //$display("data");
                        tx_bit_counter <= tx_bit_counter + 3'd1;
                        serial_out <= tx_byte[tx_bit_counter];
                        if (tx_bit_counter == 3'd7) begin
                            tx_state <= STOP1;
                            //$display("data->stop1");
                        end
                    end
                STOP1:
                    begin
                        serial_out <= 1'b1;
                        tx_state <= STOP2;
                        //$display("stop1->stop2");
                    end
                STOP2:
                    begin
                        serial_out <= 1'b1;
                        tx_state <= IDLE;
                        //$display("stop2->idle");
                    end
            endcase
        end
        else begin
            txclock_counter <= txclock_counter + 1'b1;
        end

        ///////////////////////////////////////////////////////////////////////
        // RX
        ///////////////////////////////////////////////////////////////////////

        rx_start_r <= { rx_start_r[0], serial_in };
        if (rx_state == IDLE && rx_start_r == 2'b10) begin
            sampling <= ~sampling;
            rxclock_counter <= CLK_DIV/2;
            rx_byte <= 8'd0;
            rx_state <= HALF;
            rx_ready <= 1'b0;
        end
        else if (rxclock_counter == CLK_DIV-1) begin
            case (rx_state)
                HALF:
                    begin
                        sampling <= ~sampling;
                        rx_state <= DATA;
                        rx_bit_counter <= 1'b0;
                    end
                DATA:
                    begin
                        sampling <= ~sampling;

                        rx_byte <= { serial_in, rx_byte[7:1] };
                        if (rx_bit_counter == 3'd7) begin
                            rx_state <= STOP1;
                        end
                        else begin
                            rx_bit_counter <= rx_bit_counter + 1'b1;
                        end
                    end
                STOP1:
                    begin
                        sampling <= ~sampling;
                        rx_state <= IDLE;
                        rx_ready <= 1'b1;
                    end
            endcase
            rxclock_counter <= 1'b0;
        end
        else begin
            rxclock_counter <= rxclock_counter + 1'b1;
        end
    end
end

endmodule
//
/////////////////////////////////////////////////////////////////////////////////
//// Simulation / Transceiver
/////////////////////////////////////////////////////////////////////////////////
//
//`timescale 1ns/1ns
//
//module uart_tb;
//
//`define SIMULATION 1
//
//reg         clk = 1'b0;
//reg         reset = 1'b1;
//reg         tx_start = 1'b0;
//reg [7:0]   tx_byte = 8'haa;
//wire [7:0]  rx_byte;
//wire        serial_out;
//wire        tx_busy;
//wire        rx_ready;
//
//uart DUT_TX(
//    .clk(clk),
//    .reset(reset),
//
//    .serial_out(serial_out),
//    .tx_start(tx_start),
//    .tx_byte(tx_byte),
//    .tx_busy(tx_busy),
//
//    .serial_in(),
//    .rx_byte(),
//    .rx_ready()
//);
//
//uart DUT_RX(
//    .clk(clk),
//    .reset(reset),
//
//    .serial_out(),
//    .tx_start(1'b0),
//    .tx_byte(),
//    .tx_busy(),
//
//    .serial_in(serial_out),
//    .rx_byte(rx_byte),
//    .rx_ready(rx_ready)
//);
//
//initial begin
//    #20000 reset <= 1'b0;
//    //byte <= 8'haa;
//    //byte <= 8'b10000001;
//    tx_byte <= 8'b01010101;
//    #50000 tx_start <= 1'b1;
//    #50000 tx_start <= 1'b0;
//end
//
//always @(posedge rx_ready) begin
//    $display("RX ready, byte: %x (%s)",
//        rx_byte, (rx_byte == tx_byte ? "OK" : "FAIL"));
//end
//
//always #10 clk <= ~clk;
//
//endmodule
//
/////////////////////////////////////////////////////////////////////////////////
//// Simulation / Interface
/////////////////////////////////////////////////////////////////////////////////
//
//`timescale 1ns/1ns
//
//module uart_interface_tb;
//
//`define SIMULATION 1
//
//reg         clk = 1'b0;
//reg         reset = 1'b1;
//
//reg [7:0]   tx_byte = 8'haa;
//wire [7:0]  rx_byte;
//
//wire        uart_tx;
//wire        uart_rx;
//reg         cs_tx;
//reg         cs_rx;
//reg         rs;
//reg         we;
//
//uart_interface DUT_TX(
//    .clk(clk),
//    .reset(reset),
//    .cs(cs_tx),
//    .rs(rs),
//    .we(we),
//    .din(tx_byte),
//    .dout(),
//
//    .uart_rx(),
//    .uart_tx(uart_tx)
//);
//
//uart_interface DUT_RX(
//    .clk(clk),
//    .reset(reset),
//    .cs(cs_rx),
//    .rs(rs),
//    .we(we),
//    .din(),
//    .dout(rx_byte),
//
//    .uart_rx(uart_tx),
//    .uart_tx()
//);
//
//initial begin
//    #20000 reset <= 1'b0;
//    cs_tx <= 1'b1;
//    tx_byte <= 8'b01010101;
//    we <= 1'b1;
//    rs <= 1'b1;
//end
//
//always #10 clk <= ~clk;
//
//endmodule
