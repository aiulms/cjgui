#!/usr/bin/env zsh

# Process-level acceptance for the document file binding.  It uses its own
# temporary directory and never reads or writes a user-selected document.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
PROBE_DIR="$(mktemp -d -t cjgui-document-file-process)"
PROBE_BIN="$PROBE_DIR/shared_text_document_file_process_probe"

cleanup() {
  rm -rf "$PROBE_DIR"
}
trap cleanup EXIT

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "shared document file process probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

set +u
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
set -u

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/probe/shared_text_document_file_process_probe.cj" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core \
  -o "$PROBE_BIN"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"

existing="$PROBE_DIR/existing.txt"
gate="$PROBE_DIR/continue"
"$PROBE_BIN" save "$existing" "baseline" > "$PROBE_DIR/seed.out"
rg -qx 'saved' "$PROBE_DIR/seed.out"

"$PROBE_BIN" open-wait-save "$existing" "second process" "$gate" > "$PROBE_DIR/waiter.out" &
waiter_pid=$!
for attempt in {1..100}; do
  if rg -qx 'READY' "$PROBE_DIR/waiter.out"; then
    break
  fi
  sleep 0.02
done
rg -qx 'READY' "$PROBE_DIR/waiter.out"
"$PROBE_BIN" open-save "$existing" "first process" > "$PROBE_DIR/writer.out"
rg -qx 'saved' "$PROBE_DIR/writer.out"
mkdir "$gate"
wait "$waiter_pid"
rg -qx 'external_file_conflict' "$PROBE_DIR/waiter.out"
rg -qx 'first process' "$existing"

new_target="$PROBE_DIR/new-target.txt"
"$PROBE_BIN" save "$new_target" "first contender" > "$PROBE_DIR/first.out" &
first_pid=$!
"$PROBE_BIN" save "$new_target" "second contender" > "$PROBE_DIR/second.out" &
second_pid=$!
wait "$first_pid"
wait "$second_pid"
first_result="$(<"$PROBE_DIR/first.out")"
second_result="$(<"$PROBE_DIR/second.out")"
if [[ "$first_result" != 'saved' && "$second_result" != 'saved' ]]; then
  echo "shared document file process probe: no contender saved" >&2
  exit 3
fi
if [[ "$first_result" == 'saved' && "$second_result" == 'saved' ]]; then
  echo "shared document file process probe: both contenders saved" >&2
  exit 4
fi
rg -qx 'first contender|second contender' "$new_target"
echo "shared document file process probe: two-process stale-save and new-target coordination passed"
