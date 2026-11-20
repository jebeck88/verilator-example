#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

verilator --binary --timing --assert \
    --top-module counter_tb \
    rtl/counter.sv tb/counter_tb.sv

./obj_dir/Vcounter_tb
