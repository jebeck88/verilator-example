module tb_reset_sync (
    input  logic clk,
    input  logic async_rst_n,
    output logic rst_n
);

// Dual rank FF's for reset synchronization
logic [1:0] reset_pipe;

always_ff @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n)
        // Asynchronous assertion of reset
        reset_pipe <= '0;
    else
        // Synchronous deassertion of reset
        reset_pipe <= {reset_pipe[0], 1'b1};
end

assign rst_n = reset_pipe[1];

endmodule
