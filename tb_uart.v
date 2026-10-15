`timescale 1ns/1ps
// Self-checking loopback testbench: TX -> RX
module tb_uart;
    reg clk = 0, rst = 1, start = 0;
    reg [7:0] data_in = 0;
    wire line, busy, rx_valid;
    wire [7:0] rx_data;
    integer errors = 0;

    uart_tx #(.CLKS_PER_BIT(16)) u_tx (.clk(clk), .rst(rst), .start(start),
                                       .data(data_in), .tx(line), .busy(busy));
    uart_rx #(.CLKS_PER_BIT(16)) u_rx (.clk(clk), .rst(rst), .rx(line),
                                       .data(rx_data), .valid(rx_valid));

    always #5 clk = ~clk;   // 100 MHz

    task send_and_check(input [7:0] b);
        begin
            wait (!busy);
            @(posedge clk);
            data_in <= b; start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            wait (rx_valid);
            @(posedge clk);
            if (rx_data !== b) begin
                errors = errors + 1;
                $display("FAIL: sent %h, received %h", b, rx_data);
            end else $display("PASS: sent %h, received %h", b, rx_data);
        end
    endtask

    integer i;
    initial begin
        $dumpfile("uart.vcd"); $dumpvars(0, tb_uart);   // view in GTKWave
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);
        send_and_check(8'hA5);
        send_and_check(8'h3C);
        send_and_check(8'hFF);
        send_and_check(8'h00);
        for (i = 0; i < 20; i = i + 1) send_and_check($random);
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d TEST(S) FAILED", errors);
        $finish;
    end

    initial begin #5_000_000; $display("TIMEOUT"); $finish; end
endmodule
