module counter_tb;

// Test bench signals
logic clk;
logic rst_n;
logic [7:0] count;

// Instantaiate the DUT
counter dut (
    .clk(clk),
    .rst_n(rst_n),
    .count(count)
);

// Assertion on count when not in reset
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

// Test sequence
initial begin

    apply_reset();

    assert(count == 0);

    step(1);
    assert(count == 1);

    step(9);
    assert(count == 10);

    step(245);
    assert(count == 255);

    step(1);
    assert(count == 0);

    step(4);
    assert(count == 4);    

    apply_reset();

    assert(count == 0);

    $display("PASS");
    $finish;

end

// Task for advancing simulation by n clock cycles
task automatic step(int n = 1);
begin
    // Apply n clock cycles
    repeat(n)
        @(posedge clk);
                
    // Now wait for the next falling edge of clk
    // before checking assertions
    @(negedge clk);
end
endtask

// Task for applying reset
task automatic apply_reset();
begin
    // Apply reset for 2 clock cycles
    rst_n = 0;
    @(posedge clk);
    @(posedge clk);
    // Wait for falling edge of clk
    @(negedge clk);   
    // Release reset
    rst_n = 1;
end
endtask

endmodule
