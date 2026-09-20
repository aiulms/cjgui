#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_VECTOR_CONSUMERS_TMPDIR:-/private/tmp/cjgui-composable-vector-consumers}"
if [[ ! -d "$SDKROOT_PATH" ]]; then
  print -u2 -- "vector consumers: unavailable SDKROOT=$SDKROOT_PATH"
  exit 2
fi
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"
rm -f "$OUTPUT_DIR/app.stdout.log" "$OUTPUT_DIR/app.stderr.log" "$OUTPUT_DIR/manifest"
STANDALONE_CONSUMER="$OUTPUT_DIR/framework_preview_vector_consumer.cj"
# The exported source is production-public. Build a separate test variant by
# inserting only the existing test seam and replacing the marked verification
# block; no private/native declaration is present in the source copied to a
# relocated preview.
awk '
BEGIN { in_variant = 0; in_result = 0; in_mixed_turn = 0 }
/^import std\.env\.\*$/ {
  print
  print "foreign {"
  print "    func cjgui_internal_renderer_test_activate_composable_point("
  print "        session: UInt64, pointX: Float32, pointY: Float32"
  print "    ): Int32"
  print "}"
  next
}
/^package cjgui_ui_only_starter$/ { print "package cjgui"; next }
/^[[:space:]]*import cjgui\.\*$/ { next }
/^[[:space:]]*\/\/ TEST_VARIANT_MIXED_TURN_BEGIN$/ {
  print
  print "        let mixedChartBefore = chart.ordinaryInputCount()"
  print "        let mixedChartStatus = unsafe {"
  print "            cjgui_internal_renderer_test_activate_composable_point(chartWindow.testSessionToken(), 40.0f32, 268.0f32)"
  print "        }"
  in_mixed_turn = 1
  next
}
/^[[:space:]]*\/\/ TEST_VARIANT_MIXED_TURN_END$/ {
  in_mixed_turn = 0
  print "        let turn = application.pumpOneTurn(turnBudgetMs: 4u32)"
  print "        let mixedInputThisTurn = mixedChartStatus == CJGUI_INTERNAL_RENDERER_OK && turn.isOpen &&"
  print "            readMarked(list) && chart.ordinaryInputCount() == mixedChartBefore + 1"
  print "        testVariantMixedInputSameTurn = testVariantMixedInputSameTurn || mixedInputThisTurn"
  print "        testVariantChartPointerApplied = testVariantChartPointerApplied ||"
  print "            (mixedChartStatus == CJGUI_INTERNAL_RENDERER_OK && chart.ordinaryInputCount() > 0)"
  print
  next
}
/^[[:space:]]*\/\/ TEST_VARIANT_BEGIN$/ {
  print
  print "    let sharedSession = sharedWindow.testSessionToken()"
  print "    let chartPointerApplied = testVariantChartPointerApplied && testVariantMixedInputSameTurn"
  print "    let oldPointStatus = unsafe {"
  print "        cjgui_internal_renderer_test_activate_composable_point(sharedSession, 172.0f32, 152.0f32)"
  print "    }"
  print "    let oldPointTurn = application.pumpOneTurn(turnBudgetMs: 4u32)"
  print "    let backgroundProtected = oldPointStatus == CJGUI_INTERNAL_RENDERER_OK && oldPointTurn.isOpen &&"
  print "        shared.backgroundPointerCount() == 1 && readMarked(list)"
  print "    let movedPointStatus = unsafe {"
  print "        cjgui_internal_renderer_test_activate_composable_point(sharedSession, 272.0f32, 212.0f32)"
  print "    }"
  print "    let movedPointTurn = application.pumpOneTurn(turnBudgetMs: 4u32)"
  print "    let afterMovedPoint = !readMarked(list)"
  print "    let restoredPointStatus = unsafe {"
  print "        cjgui_internal_renderer_test_activate_composable_point(sharedSession, 172.0f32, 152.0f32)"
  print "    }"
  print "    let restoredPointTurn = application.pumpOneTurn(turnBudgetMs: 4u32)"
  print "    let afterRestoredPoint = readMarked(list)"
  print "    let humanAction = chartPointerApplied && backgroundProtected &&"
  print "        movedPointStatus == CJGUI_INTERNAL_RENDERER_OK && movedPointTurn.isOpen &&"
  print "        restoredPointStatus == CJGUI_INTERNAL_RENDERER_OK && restoredPointTurn.isOpen"
  in_variant = 1
  next
}
/^[[:space:]]*\/\/ TEST_VARIANT_END$/ { in_variant = 0; print; next }
/^[[:space:]]*\/\/ TEST_VARIANT_RESULT_BEGIN$/ {
  print
  print "    let geometryMoved = backgroundProtected && afterMovedPoint && afterRestoredPoint &&"
  print "        geometryReadback == \"ellipse center=130,85 radius=24,20\""
  print "    let publicOnly = chartPointerApplied && idleStable && stateReadback == \"marked=true color=coral\" && geometryMoved"
  print "    let passed = externalApplied && externalTurn.isOpen && humanAction && afterRestoredPoint &&"
  print "        stateReadback == \"marked=true color=coral\" && geometryMoved && turns > 0"
  print "    println(\"CJGUI_VECTOR_PUBLIC_RESULT chart=1 external_marked=true external_readback_actions=${externalReadbackActions} human_action=${humanAction} human_readback=${afterRestoredPoint} state_readback=${stateReadback} geometry_readback=${geometryReadback} chart_pointer=${chartPointerApplied} mixed_same_turn=${testVariantMixedInputSameTurn} background_protected=${backgroundProtected} pointer_hit=${afterMovedPoint} geometry_moved=${geometryMoved} idle_stable=${idleStable} public_only=${publicOnly} turns=${turns} passed=${passed}\")"
  in_result = 1
  next
}
/^[[:space:]]*\/\/ TEST_VARIANT_RESULT_END$/ { in_result = 0; print; next }
{ if (!in_variant && !in_result && !in_mixed_turn) print }
' "$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj" >"$STANDALONE_CONSUMER"
! rg -q 'internalRenderer|cjgui_internal_renderer|testSessionToken|CJGUI_INTERNAL_TESTING|foreign[[:space:]]*\{|unsafe[[:space:]]*\{' \
  "$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj"
rg -q 'cjgui_internal_renderer_test_activate_composable_point|testSessionToken|CJGUI_INTERNAL_TESTING' "$STANDALONE_CONSUMER"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_vector_consumers.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_vector_graphics.cj" \
  "$RUNTIME_DIR/src/composable_vector_graphics_component.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$STANDALONE_CONSUMER" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core -L "$OUTPUT_DIR/native" -lcjgui_vector_consumers \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/vector_consumers"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/vector_consumers" --verify-vector >"$OUTPUT_DIR/app.stdout.log" 2>"$OUTPUT_DIR/app.stderr.log" &
APP_PID=$!
cleanup() {
  if kill -0 "$APP_PID" 2>/dev/null; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT HUP INT TERM

for attempt in {1..80}; do
  if rg -q '^CJGUI_VECTOR_PUBLIC_READY ' "$OUTPUT_DIR/app.stdout.log"; then break; fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
READY_LINE="$(rg '^CJGUI_VECTOR_PUBLIC_READY ' "$OUTPUT_DIR/app.stdout.log" | tail -n 1 || true)"
if [[ -z "$READY_LINE" ]]; then
  cat "$OUTPUT_DIR/app.stdout.log" >&2
  cat "$OUTPUT_DIR/app.stderr.log" >&2
  exit 20
fi
DESCRIPTOR="$(print -r -- "$READY_LINE" | sed -n 's/.*DESCRIPTOR_PATH \([^ ]*\) CHART_TARGET.*/\1/p')"
SHARED_TARGET="$(print -r -- "$READY_LINE" | sed -n 's/.*SHARED_TARGET \([^ ]*\)$/\1/p')"
if [[ -z "$DESCRIPTOR" || -z "$SHARED_TARGET" || ! -f "$DESCRIPTOR" ]]; then
  print -u2 -- "vector consumers: incomplete ready line: $READY_LINE"
  exit 21
fi

PYTHONPATH="$RUNTIME_DIR/shared_operation_core" python3 - "$DESCRIPTOR" "$SHARED_TARGET" <<'PY'
from pathlib import Path
import sys
import time
from client import SharedOperationClient, SharedOperationArgument

client = SharedOperationClient.from_descriptor(Path(sys.argv[1]), fragment_bytes=1)
target = sys.argv[2]
initial = client.get_context()
version = initial.integer("VERSION")
resource = next(row for row in initial.values("RESOURCE") if int(row[0]) == 7401)
# Read the concrete window projection before the external write. The public
# consumer is intentionally short-lived after its second human action, so
# taking this snapshot first avoids racing its normal close while still
# proving the external path targets a real projected field.
window = client.get_window_context(target)
fields = [row for row in window.values("WINDOW_FIELD_VALUE") if len(row) >= 8 and row[2] == "isMarked"]
geometry_fields = [row for row in window.values("WINDOW_FIELD_VALUE") if len(row) >= 8 and row[2] == "ellipseGeometry"]
if len(fields) != 1 or fields[0][5] != "STRING" or len(geometry_fields) != 1 or geometry_fields[0][5] != "STRING":
    raise SystemExit(f"vector projected field missing: {fields}")
geometry_before = bytes.fromhex(geometry_fields[0][7]).decode("utf-8")
result = client.invoke(version, "SET_MARKED", [7401], [SharedOperationArgument.boolean("isMarked", True)])
if result.kind != "RESULT" or not result.boolean("APPLIED"):
    raise SystemExit("authorized vector color write was not applied")
geometry_after = ""
for _ in range(40):
    updated = client.get_window_context(target)
    updated_fields = [row for row in updated.values("WINDOW_FIELD_VALUE")
                      if len(row) >= 8 and row[2] == "ellipseGeometry"]
    if updated_fields:
        geometry_after = bytes.fromhex(updated_fields[0][7]).decode("utf-8")
        if geometry_after == "ellipse center=130,85 radius=24,20":
            break
    time.sleep(0.01)
if geometry_after != "ellipse center=130,85 radius=24,20":
    raise SystemExit(f"external geometry projection did not converge: before={geometry_before!r} after={geometry_after!r}")
# The consumer holds its normal pointer sequence until this second public
# request has been accepted, leaving a full owner turn for the geometry-read
# response above to reach the client.
try:
    client.get_context()
except OSError:
    pass
print("CJGUI_VECTOR_EXTERNAL_READBACK resource=7401 field=isMarked marked=true geometry_before=" +
      geometry_before.replace(" ", "_") + " geometry_after=" + geometry_after.replace(" ", "_") +
      " window_target=" + target)
PY

for attempt in {1..120}; do
  if rg -q 'CJGUI_VECTOR_PUBLIC_RESULT .*passed=true' "$OUTPUT_DIR/app.stdout.log"; then break; fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then break; fi
  sleep 0.1
done
wait "$APP_PID"
APP_STATUS=$?
cat "$OUTPUT_DIR/app.stdout.log"
cat "$OUTPUT_DIR/app.stderr.log" >&2
SOURCE_HASH="$(shasum -a 256 "$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj" | awk '{print $1}')"
TEST_VARIANT_HASH="$(shasum -a 256 "$STANDALONE_CONSUMER" | awk '{print $1}')"
BINARY_HASH="$(shasum -a 256 "$OUTPUT_DIR/vector_consumers" | awk '{print $1}')"
{
  print -r -- 'format=1'
  print -r -- "app_status=$APP_STATUS"
  print -r -- "production_source_sha256=$SOURCE_HASH"
  print -r -- "test_variant_sha256=$TEST_VARIANT_HASH"
  print -r -- "binary_sha256=$BINARY_HASH"
  print -r -- "descriptor=$DESCRIPTOR"
  print -r -- "shared_target=$SHARED_TARGET"
  print -r -- "app_stdout=$OUTPUT_DIR/app.stdout.log"
  print -r -- "app_stderr=$OUTPUT_DIR/app.stderr.log"
} >"$OUTPUT_DIR/manifest"
if [[ "$APP_STATUS" -ne 0 ]] || ! rg -q 'CJGUI_VECTOR_PUBLIC_RESULT .*chart=1 .*external_marked=true .*human_action=true .*human_readback=true .*chart_pointer=true .*mixed_same_turn=true .*background_protected=true .*pointer_hit=true .*geometry_moved=true .*passed=true' "$OUTPUT_DIR/app.stdout.log"; then
  print -u2 -- "vector consumers: failed manifest=$OUTPUT_DIR/manifest"
  exit 22
fi
print -- "CJGUI_VECTOR_CONSUMERS_VERIFY passed=true manifest=$OUTPUT_DIR/manifest"
