module uart_tx (
    input        clk,
    input        rst_n,
    input        start,
    input  [7:0] data_in,
    output reg   tx,
    output reg   busy
);

parameter BAUD_DIV = 5208;

reg [12:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [9:0]  shift_reg;
reg        transmitting;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx           <= 1'b1;
        busy         <= 1'b0;
        baud_cnt     <= 0;
        bit_cnt      <= 0;
        transmitting <= 0;
    end
    else begin
        if (!transmitting && start) begin
            shift_reg    <= {1'b1, data_in, 1'b0};
            transmitting <= 1;
            busy         <= 1;
            baud_cnt     <= 0;
            bit_cnt      <= 0;
        end
        else if (transmitting) begin
            if (baud_cnt == BAUD_DIV - 1) begin
                baud_cnt  <= 0;
                tx        <= shift_reg[0];
                shift_reg <= {1'b1, shift_reg[9:1]};
                bit_cnt   <= bit_cnt + 1;
                if (bit_cnt == 9) begin
                    transmitting <= 0;
                    busy         <= 0;
                end
            end
            else begin
                baud_cnt <= baud_cnt + 1;
            end
        end
    end
end

endmodule