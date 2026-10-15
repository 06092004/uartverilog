// UART receiver: 8N1, mid-bit sampling, 2-FF input synchronizer
module uart_rx #(parameter CLKS_PER_BIT = 16)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid       // 1-clock pulse when a byte is received
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] state;
    reg [15:0] cnt;
    reg [2:0] idx;
    reg rx_s1, rx_s2;

    always @(posedge clk) begin
        rx_s1 <= rx; rx_s2 <= rx_s1;   // synchronizer (avoids metastability)
        if (rst) begin
            state <= IDLE; valid <= 1'b0; cnt <= 0; idx <= 0; data <= 8'h00;
            rx_s1 <= 1'b1; rx_s2 <= 1'b1;
        end else case (state)
            IDLE: begin
                valid <= 1'b0; cnt <= 0; idx <= 0;
                if (rx_s2 == 1'b0) state <= START;
            end
            START: if (cnt == (CLKS_PER_BIT-1)/2) begin   // middle of start bit
                        cnt <= 0;
                        if (rx_s2 == 1'b0) state <= DATA; else state <= IDLE;
                   end else cnt <= cnt + 1;
            DATA: if (cnt == CLKS_PER_BIT-1) begin
                        cnt <= 0; data[idx] <= rx_s2;
                        if (idx == 3'd7) state <= STOP; else idx <= idx + 1;
                  end else cnt <= cnt + 1;
            STOP: if (cnt == CLKS_PER_BIT-1) begin
                        cnt <= 0; valid <= 1'b1; state <= IDLE;
                  end else cnt <= cnt + 1;
        endcase
    end
endmodule
