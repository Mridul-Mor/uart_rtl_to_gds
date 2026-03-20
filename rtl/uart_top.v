module uart_top (
    input        clk,
    input        rst_n,
    input        start,
    input  [7:0] tx_data,
    input        rx,
    output       tx,
    output [7:0] rx_data,
    output       rx_valid,
    output       busy
);

uart_tx tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(tx_data),
    .tx(tx),
    .busy(busy)
);

uart_rx rx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rx(rx),
    .data_out(rx_data),
    .valid(rx_valid)
);

endmodule