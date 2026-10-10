#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
output_dir="${CJGUI_SELECTION_TRANSFER_CREATE_GATE_TMPDIR:-/private/tmp/cjgui-selection-transfer-create-production-gate}"
mkdir -p "$output_dir"

if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  sdkroot_path="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  sdkroot_path="$SDKROOT"
else
  sdkroot_path="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ ! -d "$sdkroot_path" ]]; then
  echo "selection transfer production gate: unavailable SDKROOT=$sdkroot_path" >&2
  exit 2
fi

probe="$runtime_dir/native/tests/selection_transfer_create_production_gate_test.m"
production_binary="$output_dir/selection_transfer_create_production_gate_test"
testing_binary="$output_dir/selection_transfer_create_testing_path_test"
build_log="$output_dir/build.log"
testing_build_log="$output_dir/testing-build.log"
run_log="$output_dir/run.log"
testing_run_log="$output_dir/testing-run.log"

# Deliberately omit CJGUI_INTERNAL_TESTING: this exercises the production ABI.
if ! clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 "$probe" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$production_binary" >"$build_log" 2>&1; then
  cat "$build_log" >&2
  exit 1
fi
if ! clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 "$probe" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$testing_binary" >"$testing_build_log" 2>&1; then
  cat "$testing_build_log" >&2
  exit 1
fi

if ! "$production_binary" >"$run_log" 2>&1; then
  cat "$run_log" >&2
  echo "selection transfer production gate: FAILED log=$run_log" >&2
  exit 1
fi
cat "$run_log"
grep -q 'selection_transfer_create_production failures=0' "$run_log" || {
  echo "selection transfer production gate: missing pass line log=$run_log" >&2
  exit 1
}
if ! "$testing_binary" >"$testing_run_log" 2>&1; then
  cat "$testing_run_log" >&2
  echo "selection transfer testing path: FAILED log=$testing_run_log" >&2
  exit 1
fi
cat "$testing_run_log"
grep -q 'selection_transfer_create_production failures=0' "$testing_run_log" || {
  echo "selection transfer testing path: missing pass line log=$testing_run_log" >&2
  exit 1
}
echo "selection transfer create gate: production=PASSED testing_path=PASSED production_log=$run_log testing_log=$testing_run_log"
