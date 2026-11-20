module counter_tb;

logic clk;
logic rst_n;
logic [7:0] count;

counter dut (
    .clk(clk),
    .rst_n(rst_n),
    .count(count)
);

assert property (
    @(posedge clk)
    disable iff (!rst_n)
    $past(rst_n) |-> count == ($past(count) + 8'd1)
);

// Clock generation
initial begin
    clk = 0;

    forever #5
        clk = ~clk;
end

initial begin

    rst_n = 0;

    #20;

    rst_n = 1;

    repeat (20)
        @(posedge clk);

    @(negedge clk);

    assert(count == 20)
        else $fatal("Count mismatch");

    $display("PASS");

    $finish;

end

endmodule
