#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${CJGUI_INTERACTION_SCHEDULING_NATIVE_COST_TMPDIR:-/private/tmp/cjgui-interaction-scheduling-native-cost}"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SHARED_CORE="$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core"
PROBE_SRC="$RUNTIME_DIR/probe/interaction_scheduling_native_cost_probe.cj"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

require_source_line() {
  local expected="$1"
  if ! rg -F -q "$expected" "$PROBE_SRC"; then
    print -u2 -- "interaction scheduling native-cost verifier: missing source line: $expected"
    exit 1
  fi
}

# Keep the standalone probe tied to the existing package-only timing and
# scalar native stats.  It must remain independent of the UDS verifier.
require_source_line "interactionPaintResolutionNanoseconds"
require_source_line "interactionPaintComparisonNanoseconds"
require_source_line "cjgui_internal_renderer_test_composable_scene_submission_stats"
require_source_line "native_configure_us="
require_source_line "native_set_us="
require_source_line "native_commit_us="
require_source_line "native_stage_submit_ns="
require_source_line "native_residual_ns="
require_source_line "native_next_drawable_us="
require_source_line "native_command_buffer_us="
require_source_line "native_encoder_cpu_us="
require_source_line "native_present_us="
require_source_line "native_commit_call_us="
require_source_line "native_readback_wait_us="
require_source_line "let small = runNodeCount(8)"
require_source_line "let medium = runNodeCount(128)"
require_source_line "let large = runNodeCount(960)"
if rg -F -q "CjguiSharedOperationExternalConnection" "$PROBE_SRC"; then
  print -u2 -- "interaction scheduling native-cost verifier: probe must not use UDS"
  exit 1
fi
mkdir -p "$OUTPUT_DIR/native"
LOG="$OUTPUT_DIR/result"
rm -f "$LOG"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_interaction_scheduling_native_cost.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" --import-path "$SHARED_CORE" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$PROBE_SRC" \
  -L "$SHARED_CORE" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_interaction_scheduling_native_cost \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/interaction_scheduling_native_cost_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/interaction_scheduling_native_cost_probe" | tee "$LOG"

python3 - "$LOG" <<'PY'
import math
import sys

path = sys.argv[1]
groups = {}
fields = (
    "interaction_resolution_ns",
    "interaction_compare_ns",
    "native_configure_us",
    "native_set_us",
    "native_commit_us",
    "native_stage_submit_ns",
    "native_residual_ns",
    "native_next_drawable_us",
    "native_command_buffer_us",
    "native_encoder_cpu_us",
    "native_present_us",
    "native_commit_call_us",
    "native_readback_wait_us",
)
for raw in open(path, encoding="utf-8"):
    line = raw.strip()
    if not line.startswith("CJGUI_NATIVE_COST_SAMPLE "):
        continue
    values = dict(item.split("=", 1) for item in line.split()[1:] if "=" in item)
    if values.get("valid") != "true":
        continue
    if values.get("native_readback_waited") != "0":
        raise SystemExit(f"interaction scheduling native-cost verifier: hot sample waited for readback nodes={values.get('nodes')}")
    nodes = int(values["nodes"])
    groups.setdefault(nodes, []).append({name: int(values[name]) for name in fields})

def percentile(values, fraction):
    ordered = sorted(values)
    if fraction == 0.50:
        return (ordered[14] + ordered[15]) // 2
    return ordered[math.ceil(len(ordered) * fraction) - 1]

for nodes in (8, 128, 960):
    samples = groups.get(nodes, [])
    if len(samples) != 30:
        raise SystemExit(f"interaction scheduling native-cost verifier: expected 30 valid samples nodes={nodes}, got {len(samples)}")
    for sample in samples:
        if any(sample[name] < 0 for name in fields):
            raise SystemExit(f"interaction scheduling native-cost verifier: negative scalar nodes={nodes}")
    report = [f"CJGUI_NATIVE_COST_REPORT nodes={nodes} samples=30"]
    for name in fields:
        report.append(f"{name}_p50={percentile([sample[name] for sample in samples], 0.50)}")
        report.append(f"{name}_p95={percentile([sample[name] for sample in samples], 0.95)}")
    print(" ".join(report))
PY

for nodes in 8 128 960; do
  rg "^CJGUI_NATIVE_COST_RESULT nodes=${nodes} samples=30 valid=true$" "$LOG"
done
rg '^CJGUI_NATIVE_COST_SUMMARY nodes=8,128,960 samples_per_node=30 .*valid=true$' "$LOG"
print -r -- "interaction scheduling native-cost verification: PASS nodes=8,128,960 samples=90 raw_stages=interaction_resolution,interaction_compare,native_configure,native_set,native_commit,native_stage_submit,native_residual,next_drawable,command_buffer,encoder_cpu,present,commit_call,readback_wait p50_p95=reported hot_readback_wait=0 residual_boundary=not_attributed_to_drawable_wait"
