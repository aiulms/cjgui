#!/usr/bin/env zsh
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="$(xcrun --sdk macosx --show-sdk-path)"
output_dir="${CJGUI_PREPARATION_REUSE_TMPDIR:-/private/tmp/pharos-e-r3-perf51-preparation-reuse}"
mkdir -p "$output_dir"
python3 - "$runtime_dir/src/composable_ui_window.cj" <<'PY'
import pathlib
import sys

source = pathlib.Path(sys.argv[1]).read_text()
start = source.index("private func preparedStringsEqual(")
end = source.index("\n    private func freezePreparedNode", start)
body = source[start:end]
required = (
    "previousLabel == currentLabel",
    "previous.value == currentValue",
    "previous.semanticId == current.semanticId",
    "nativeSemanticBindingKey(previous) == nativeSemanticBindingKey(current)",
    "previous.semanticKey == current.semanticKey",
    "previous.semanticParentKey == current.semanticParentKey",
    "previous.semanticLabel == current.semanticLabel",
    "encodePreparedLayoutRuns(previous) == currentRuns",
)
missing = [fact for fact in required if fact not in body]
if missing:
    raise SystemExit("prepared declaration string proof missing: " + "; ".join(missing))
print("prepare_reuse case=all_eight_accepted_string_values_compared_exactly result=PASS")
PY
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$sdkroot_path" -mmacosx-version-min=12.0 \
  "$runtime_dir/native/tests/composable_preparation_reuse_test.m" \
  "$runtime_dir/native/cjgui_native_bridge.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$output_dir/composable_preparation_reuse_test" >"$output_dir/build.log" 2>&1 || {
    tail -80 "$output_dir/build.log"
    exit 1
  }
"$output_dir/composable_preparation_reuse_test"
