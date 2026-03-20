`timescale 1ns/1ps

module uart_tx_tb;

reg        clk, rst_n, start;
reg  [7:0] data_in;
wire       tx, busy;

uart_tx uut (
    .clk(clk), .rst_n(rst_n),
    .start(start), .data_in(data_in),
    .tx(tx), .busy(busy)
);

always #10 clk = ~clk;

task send_byte;
    input [7:0] byte_val;
    begin
        data_in = byte_val;
        start   = 1;
        #20 start = 0;
        wait(busy == 1);
        wait(busy == 0);
        #500;
    end
endtask

initial begin
    $dumpfile("uart_tx.vcd");
    $dumpvars(0, uart_tx_tb);

    clk = 0; rst_n = 0; start = 0; data_in = 8'h00;
    #100 rst_n = 1;
    #100;

    $display("Sending MRIDUL...");
    send_byte(8'h4D); // 'M'
    send_byte(8'h52); // 'R'
    send_byte(8'h49); // 'I'
    send_byte(8'h44); // 'D'
    send_byte(8'h55); // 'U'
    send_byte(8'h4C); // 'L'

    $display("MRIDUL transmitted successfully!");
    #2000;
    $finish;
end

endmodule