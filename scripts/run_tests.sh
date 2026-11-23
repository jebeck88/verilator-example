#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

verilator --binary --timing --assert \
    --top-module counter_tb \
    rtl/counter.sv tb/tb_reset_sync.sv tb/counter_tb.sv

./obj_dir/Vcounter_tb
