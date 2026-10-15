// UART transmitter: 8N1, FSM-based
module uart_tx #(parameter CLKS_PER_BIT = 16)(
    input  wire       clk,
    input  wire       rst,
    input  wire       start,      // pulse for 1 clock to send 'data'
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] state;
    reg [15:0] cnt;
    reg [2:0] idx;
    reg [7:0] shreg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; tx <= 1'b1; busy <= 1'b0; cnt <= 0; idx <= 0;
        end else case (state)
            IDLE: begin
                tx <= 1'b1; busy <= 1'b0; cnt <= 0; idx <= 0;
                if (start) begin
                    shreg <= data; busy <= 1'b1; tx <= 1'b0; state <= START;
                end
            end
            START: if (cnt == CLKS_PER_BIT-1) begin
                        cnt <= 0; tx <= shreg[0]; state <= DATA;
                   end else cnt <= cnt + 1;
            DATA: if (cnt == CLKS_PER_BIT-1) begin
                        cnt <= 0;
                        if (idx == 3'd7) begin tx <= 1'b1; state <= STOP; end
                        else begin idx <= idx + 1; tx <= shreg[idx + 1]; end
                  end else cnt <= cnt + 1;
            STOP: if (cnt == CLKS_PER_BIT-1) begin
                        cnt <= 0; busy <= 1'b0; state <= IDLE;
                  end else cnt <= cnt + 1;
        endcase
    end
endmodule
