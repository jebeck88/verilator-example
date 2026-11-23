# RTL Development Tools and Steps

## Goal

Develop FPGA designs using modern SystemVerilog RTL and SystemVerilog testbenches without getting buried in UVM complexity or spending hours manually inspecting waveforms.

The objective is:

```text
Write RTL
    ↓
Write testbench
    ↓
Simulate
    ↓
Assertions identify failures
    ↓
Use waveforms only when debugging
```

---

# Recommended Toolchain

## Windows Setup with WSL2 and Ubuntu

On Windows, this project runs Verilator and its Linux build tools inside Ubuntu on WSL2. WSL2 is a Windows-managed Linux environment; this setup does not use Docker or a dev container. VS Code can remain open in Windows while commands run in an Ubuntu terminal. Windows drives are available in Ubuntu under `/mnt`, so for example `D:\projects\my-project` is `/mnt/d/projects/my-project`.

Install the environment:

1. In PowerShell, install WSL and Ubuntu:

   ```powershell
   wsl --install -d Ubuntu-24.04
   ```

   Restart Windows if prompted, then launch Ubuntu and create a Linux username and password.
2. In the Ubuntu terminal, install Verilator and the supporting tools:

   ```bash
   sudo apt update
   sudo apt install -y verilator build-essential gtkwave
   verilator --version
   ```

   `build-essential` provides the compiler and build utilities. GTKWave is optional and is used to view waveforms.
3. In Ubuntu, change to the project directory using its `/mnt/<drive>/...` path before running simulations.

## Editor

### VS Code

Recommended extensions:

- Verilog-HDL/SystemVerilog support
- Git integration
- Makefile support

---

## Simulator

### Verilator

Use Verilator as the primary simulator.

Advantages:

- Free
- Fast
- Open source
- Good SystemVerilog support
- Excellent linting
- Suitable for FPGA development

### Build and Run the Testbench

Run these commands in the Ubuntu terminal, from the project directory:

```bash
./scripts/run_tests.sh
```

The script builds `counter_tb` with timing and assertions enabled, then runs it. It prints `PASS` if the test succeeds; a compile error or failed assertion returns a nonzero exit status. Verilator writes generated build files to `obj_dir/`.

When adding testbenches, update `scripts/run_tests.sh` to build and run each one.

---

## Waveform Viewer

### GTKWave

Use only when needed.

Waveforms should become a debugging tool rather than the primary verification mechanism.

The test script enables Verilator's VCD tracing and writes `counter_tb.vcd` in the
repository root. From the Ubuntu/WSL terminal, run:

```bash
./scripts/run_tests.sh
gtkwave counter_tb.vcd
```

In GTKWave, expand `counter_tb` in the signal browser, select signals such as
`clk`, `async_rst_n`, `rst_n`, and `count`, then add them to the waveform pane
(double-clicking a signal also adds it). Use **Zoom Fit** to see the full
simulation. The VCD file is overwritten each time the test script runs.

Workflow:

```text
Test fails
    ↓
Assertion reports failure
    ↓
Open waveform
    ↓
Investigate root cause
```

---

## Version Control

### Git

Keep:

```text
rtl/
tb/
sim/
scripts/
docs/
```

under version control.

---

# Development Process

## Step 1 - Write Synthesizable RTL

Example:

```systemverilog
module counter (
    input  logic clk,
    input  logic rst_n,
    output logic [7:0] count
);

always_ff @(posedge clk)
begin
    if (!rst_n)
        count <= 0;
    else
        count <= count + 1;
end

endmodule
```

Focus on:

- always_ff
- always_comb
- logic
- enumerated state machines
- clean synchronous design

---

## Step 2 - Write a Simple Testbench

Instantiate the DUT.

Generate clocks.

Generate resets.

Drive inputs.

Check outputs.

Example:

```systemverilog
module counter_tb;

logic clk;
logic rst_n;
logic [7:0] count;

counter dut (
    .clk(clk),
    .rst_n(rst_n),
    .count(count)
);

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

    assert(count == 20)
        else $fatal("Count mismatch");

    $display("PASS");

    $finish;

end

endmodule
```

Do not start with UVM.

For most FPGA projects, simple self-checking testbenches are sufficient.

---

# Step 3 - Make the Testbench Self-Checking

Bad:

```text
Run simulation
Open waveform
Look for bug
```

Good:

```text
Run simulation
Assertion fails
Fix bug
```

The testbench should automatically determine whether the design passes or fails.

Example:

```systemverilog
assert(count == expected_value);
```

---

# Step 4 - Add SystemVerilog Assertions

Example:

```systemverilog
assert property (
    @(posedge clk)
    disable iff (!rst_n)
    $past(rst_n) |-> count == ($past(count) + 8'd1)
);
```

Assertions encode design intent.

They eliminate a large amount of manual waveform inspection.

Whenever practical:

```text
Express requirements as assertions.
```

---

# Step 5 - Run Regression Tests

Maintain multiple testbenches.

Example:

```text
tb/

counter_basic_tb.sv

counter_reset_tb.sv

counter_overflow_tb.sv
```

Each test validates one aspect of behavior.

Run the current counter test with:

```bash
./scripts/run_tests.sh
```

As the project gains testbenches, add them to `scripts/run_tests.sh` so one command runs the full regression.

The complete `scripts/run_tests.sh` script is:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

verilator --binary --timing --assert \
    --top-module counter_tb \
    rtl/counter.sv tb/counter_tb.sv

./obj_dir/Vcounter_tb
```

---

# Using Waveforms Correctly

Old workflow:

```text
Waveforms are the primary debugging tool.
```

Modern workflow:

```text
Assertions are primary.
Waveforms are secondary.
```

Preferred workflow:

```text
Run simulation
    ↓
Assertion failure
    ↓
Open waveform
    ↓
Find root cause
```

Waveforms should answer:

> Why did the assertion fail?

not:

> Is the design broken?

---

# Things To Avoid Initially

Avoid learning these until a real need exists:

- UVM
- Sequence items
- Factories
- Scoreboards
- Constrained random verification
- Verification frameworks with large class hierarchies

These are valuable in large ASIC projects but add significant complexity to a solo FPGA effort.

---

# Recommended Learning Order

1. SystemVerilog RTL
2. Verilator
3. Self-checking testbenches
4. SystemVerilog assertions
5. Git-based regression testing
6. GTKWave debugging
7. Python/cocotb (optional)
8. UVM (only if a project genuinely requires it)

---

# Philosophy

The job of the testbench is not to generate waveforms.

The job of the testbench is to determine whether the design is correct.

Waveforms are for diagnosing failures.

Assertions are for detecting failures.

The most productive workflow is:

```text
Write RTL
Write testbench
Write assertions
Run simulation
Fix failures
Repeat
```