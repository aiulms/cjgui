#!/usr/bin/env zsh
set -eo pipefail
runtime_dir="$(cd "$(dirname "$0")/../.." && pwd)"
output_dir="${CJGUI_PREPARATION_REUSE_CJ_TMPDIR:-/private/tmp/pharos-e-r3-perf51-perf-reuse-evidence/cj-runtime}"
target_dir="${CJGUI_PREPARATION_REUSE_CJ_TARGET:-/private/tmp/pharos-e-r3-perf51-perf-reuse-evidence/cjpm-target}"
mkdir -p "$output_dir" "$target_dir"
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
set -u
export CJGUI_OWNER_PHASE_TRACE=1
export CJGUI_NATIVE_CLANG_FLAGS_APPEND=-DCJGUI_INTERNAL_TESTING
set +e
(cd "$runtime_dir" && cjpm test --target-dir "$target_dir" --filter \
  cangjieWindowViewportRefreshRunsThePreparedReuseBridge --show-all-output --no-capture-output \
  --no-progress) >"$output_dir/cjpm-test.log" 2>&1
exit_code=$?
set -e
cat "$output_dir/cjpm-test.log"
if (( exit_code != 0 )); then
  exit "$exit_code"
fi
if ! grep -q 'PREPARATION_REUSE_CJ_WINDOW accepted=' "$output_dir/cjpm-test.log"; then
  echo 'prepared reuse Cangjie window test did not emit its accepted-scene marker' >&2
  exit 1
fi
if ! grep -Eq 'kind=observation_scalar .*span=[1-9][0-9]* phase=preparation_declarations_reused' \
  "$output_dir/cjpm-test.log"; then
  echo 'prepared reuse was not observed in the native owner-trace scalar' >&2
  exit 1
fi
python3 - "$output_dir/cjpm-test.log" <<'PY'
import pathlib
import re
import sys

log = pathlib.Path(sys.argv[1]).read_text(errors="replace")
mutations = sorted({int(value) for value in re.findall(
    r"PREPARATION_REUSE_STRING_CASE mutation=(\d+)", log)})
if mutations != list(range(1, 9)):
    raise SystemExit(f"Cangjie normal-window string mutations missing: {mutations}")
copied = re.findall(
    r"kind=observation_scalar .*span=([1-9][0-9]*) phase=preparation_declarations_copied", log)
reused = re.findall(
    r"kind=observation_scalar .*span=([1-9][0-9]*) phase=preparation_declarations_reused", log)
if len(copied) < 8 or len(reused) < 8:
    raise SystemExit(f"expected per-candidate native copy/reuse evidence; copied={len(copied)} reused={len(reused)}")
print("PREPARATION_REUSE_CJ_STRINGS all_eight_mutations_and_copy_fallbacks=PASS")
PY
echo 'PREPARATION_REUSE_CJ_WINDOW_TRACE reused_count=positive result=PASS'
