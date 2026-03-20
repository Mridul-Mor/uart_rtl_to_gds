module uart_rx (
    input        clk,
    input        rst_n,
    input        rx,
    output reg [7:0] data_out,
    output reg       valid
);

parameter BAUD_DIV  = 5208;
parameter HALF_BAUD = BAUD_DIV / 2;

reg [12:0] baud_cnt;
reg [3:0]  bit_cnt;
reg [7:0]  shift_reg;

localparam IDLE    = 2'd0;
localparam START   = 2'd1;
localparam DATA    = 2'd2;
localparam STOP    = 2'd3;

reg [1:0] state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state     <= IDLE;
        data_out  <= 0;
        valid     <= 0;
        baud_cnt  <= 0;
        bit_cnt   <= 0;
        shift_reg <= 0;
    end
    else begin
        valid <= 0;

        case (state)
            IDLE: begin
                if (!rx) begin
                    state    <= START;
                    baud_cnt <= 0;
                end
            end

            START: begin
                if (baud_cnt == HALF_BAUD - 1) begin
                    baud_cnt <= 0;
                    bit_cnt  <= 0;
                    state    <= DATA;
                end
                else baud_cnt <= baud_cnt + 1;
            end

            DATA: begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt  <= 0;
                    shift_reg <= {rx, shift_reg[7:1]};
                    bit_cnt   <= bit_cnt + 1;
                    if (bit_cnt == 7)
                        state <= STOP;
                end
                else baud_cnt <= baud_cnt + 1;
            end

            STOP: begin
                if (baud_cnt == BAUD_DIV - 1) begin
                    baud_cnt <= 0;
                    data_out <= shift_reg;
                    valid    <= 1;
                    state    <= IDLE;
                end
                else baud_cnt <= baud_cnt + 1;
            end
        endcase
    end
end

endmodule