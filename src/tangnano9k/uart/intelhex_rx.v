module intelhex_rx(
    input clk_i,
    input ce_i,
    input rst_n,
    input [7:0] data_i,
    input rx_data_valid,
    
    output [21:0] addr_o,
    output [7:0] data_o,
    output reg wr_o,
    output error_o);

localparam ST_IDLE = 0;     // wait for ':'
localparam ST_READBYTE = 1;
localparam ST_READADDR = 2;
localparam ST_BYTECOUNT = 3;
localparam ST_RECORDTYPE = 4;
localparam ST_DATA = 5;
localparam ST_CHECKSUM = 6;
localparam ST_SEGMENT = 7;
localparam ST_ERROR = 8;


reg [15:0] segment;
reg [15:0] addr;
reg [21:0] addr_r;

reg [3:0] state, next;

reg [3:0] charcnt;

reg [7:0] byteval;

reg [7:0] record_size;
reg [7:0] record_type;
reg [7:0] bytecount;
reg [7:0] checksum;

assign addr_o = addr_r;
assign data_o = byteval;

wire is_09 = data_i >= "0" && data_i <= "9";
wire is_af = data_i >= "A" && data_i <= "F";
wire valid_hex = is_09 || is_af;
wire [3:0] char2value = is_09 ? data_i - "0" : data_i - "A" + 4'd10;

assign error_o = state == ST_ERROR;

always @(posedge clk_i)
    if (!rst_n) begin
        state <= ST_IDLE;
        next <= ST_IDLE;
        segment <= 16'h0;
        addr <= 16'h0;
        byteval <= 0;
    end
    else if (ce_i) begin
            wr_o <= 1'b0;

            case (state)
            // waiting for the start symbol
            ST_IDLE:
                if (rx_data_valid) 
                begin
                    if (data_i == ":") 
                    begin 
                        charcnt <= 4'd2;  // expect 2 chars
                        bytecount <= 0;   // initial value 00
                        checksum <= 8'h00;
                        state <= ST_READBYTE; 
                        next <= ST_BYTECOUNT;
                    end
                end

            // read anything to byteval
            ST_READBYTE:
                if (rx_data_valid)
                begin
                    state <= ST_READBYTE;
                    if (valid_hex)
                    begin
                        byteval <= {byteval[3:0], char2value};
                        charcnt <= charcnt - 1'b1;
                        if (charcnt - 1'b1 == 4'd0)
                        begin
                            state <= next;
                            //$display("ST_READBYTE %02x next=%d", {byteval[3:0], char2value}, next);
                        end
                    end
                    else
                        state <= ST_ERROR;
                end

            ST_BYTECOUNT:
                begin
                    checksum <= checksum + byteval;
                    record_size <= byteval;
                    charcnt <= 4'd4;
                    state <= ST_READADDR;
                    $display("ST_BYTECOUNT: record_size=%02x", byteval);
                end

            ST_READADDR:
                if (rx_data_valid)
                begin
                    state <= ST_READADDR;
                    if (valid_hex)
                    begin
                        addr <= {addr[11:0], char2value};
                        charcnt <= charcnt - 1'b1;
                        if (charcnt - 1'b1 == 4'd0)
                        begin
                            // addr loaded, expect record type 2 chars
                            charcnt <= 4'd2;
                            record_type <= 8'h00;
                            state <= ST_READBYTE;
                            next <= ST_RECORDTYPE;

                            // checksum will be updated in ST_RECORDTYPE
                        end
                    end
                    else
                        state <= ST_ERROR;
                end

            ST_RECORDTYPE:
                begin
                    checksum <= checksum + addr[15:8] + addr[7:0] + byteval;
                    record_type <= byteval;
                    charcnt <= 4'd2;
                    state <= ST_READBYTE;
                    if (byteval == 8'h00)
                        next <= ST_DATA;
                    else if (byteval == 8'h02)
                        next <= ST_SEGMENT; // extended segment address
                    else if (byteval == 8'h01)
                        next <= ST_IDLE; // eof, who cares

                    $display("ST_RECORDTYPE: record_type=%02x addr=%02x", record_type, addr);
                end

            ST_DATA:
                begin
                    charcnt <= 4'd2;
                    state <= ST_READBYTE;
                    charcnt <= 4'd2;
                    checksum <= checksum + byteval;
                    wr_o <= 1'b1; // strobe data out (byteval)
                    addr_r <= {segment, 8'h00} + addr;
                    addr <= addr + 1'b1;
                    record_size <= record_size - 1'b1;

                    if (record_size - 1'b1 == 8'h00) begin
                        next <= ST_CHECKSUM;
                    end
                    //$display("ST_DATA: %02x cs=%02x", byteval, checksum + byteval);
                end

            ST_SEGMENT:
                begin
                    charcnt <= 4'd2;
                    state <= ST_READBYTE;
                    checksum <= checksum + byteval;

                    segment <= {segment[7:0], byteval};
                    record_size <= record_size - 1'b1;
                    if (record_size - 1'b1 == 8'h00) begin
                        $display("ST_SEGMENT: segment=%04x", {segment[7:0], byteval});
                        next <= ST_CHECKSUM;
                    end
                end

            ST_CHECKSUM:
                begin
                    state <= ST_IDLE;
                    checksum <= checksum + byteval;
                    if (checksum + byteval != 8'h00) 
                        state <= ST_ERROR;
                    $display("ST_CHECKSUM == %02x", checksum + byteval);
                end
            ST_ERROR:
                state <= ST_IDLE;
            
        endcase
    end
endmodule

