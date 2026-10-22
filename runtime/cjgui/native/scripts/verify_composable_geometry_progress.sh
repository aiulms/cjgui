#!/usr/bin/env zsh
# Explicit testing archive; --lifecycle-only selects the existing first-frame/close contract.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
OUTPUT_DIR="${CJGUI_GEOMETRY_PROGRESS_TMPDIR:-/private/tmp/cjgui-geometry-progress}"
mkdir -p "$OUTPUT_DIR"
OWNER="$OUTPUT_DIR/.cjgui-geometry-owner"
if [[ -f "$OWNER" && "$(< "$OWNER")" != "$RUNTIME_DIR" ]]; then
  print -u2 'geometry progress: output belongs to another runtime'; exit 2
fi
if [[ ! -f "$OWNER" && -e "$OUTPUT_DIR/composable_geometry_progress_test" ]]; then
  print -u2 'geometry progress: refusing an unowned executable'; exit 2
fi
print -rn -- "$RUNTIME_DIR" > "$OWNER"
mkdir "$OUTPUT_DIR/build.lock" || { print -u2 'geometry progress: output is in use'; exit 2; }
EXECUTABLE="$OUTPUT_DIR/composable_geometry_progress_test"
cleanup() { rm -f "$EXECUTABLE"; rmdir "$OUTPUT_DIR/build.lock"; }
trap cleanup EXIT
trap 'exit 130' HUP INT TERM
NORMAL_ARCHIVE="$RUNTIME_DIR/native/lib/libcjgui_internal_renderer.a"
NORMAL_BEFORE="$(shasum -a 256 "$NORMAL_ARCHIVE" | awk '{print $1}')"
CJ_GUI_SDKROOT="$SDKROOT_PATH" zsh "$SCRIPT_DIR/build_cjgui_internal_renderer_sidecar.sh" --testing > "$OUTPUT_DIR/native-build.log" 2>&1
ARCHIVE="$RUNTIME_DIR/native/testing/lib/libcjgui_internal_renderer.a"
clang -DCJGUI_INTERNAL_TESTING -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules \
  -fstack-protector-strong -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/tests/composable_geometry_progress_test.m" "$ARCHIVE" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -Wl,-t -o "$EXECUTABLE" > "$OUTPUT_DIR/build.log" 2>&1
python3 - "$RUNTIME_DIR" "$OUTPUT_DIR" "$ARCHIVE" "$EXECUTABLE" "$NORMAL_BEFORE" "$@" <<'PY'
from pathlib import Path
import hashlib,json,subprocess,sys,tarfile
runtime, output, archive, executable = map(Path,sys.argv[1:5])
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
normal=runtime/'native/lib/libcjgui_internal_renderer.a'
record={'native_archive':str(archive),'native_sha256':digest(archive),'executable_sha256':digest(executable),'mode':sys.argv[6:] or ['full_legacy_geometry']}
inputs=[p for p in (runtime/'native').iterdir() if p.suffix in ['.m','.h']]
inputs += [runtime/'native/tests/composable_geometry_progress_test.m',runtime/'native/scripts/verify_composable_geometry_progress.sh',runtime/'native/scripts/build_cjgui_internal_renderer_sidecar.sh']
record['sources']={str(p.relative_to(runtime)):digest(p) for p in inputs}
with tarfile.open(output/'source-inputs.tar.xz','w:xz') as a:
 for p in inputs:a.add(p,arcname=str(p.relative_to(runtime)))
assert str(archive)+'(cjgui_internal_renderer.o)' in (output/'build.log').read_text()
try:
 with (output/'result.log').open('wb') as log:
  rc=subprocess.run([str(executable),*sys.argv[6:]],stdout=log,stderr=subprocess.STDOUT,timeout=20).returncode
 record['exit_code']=rc
finally:
 record['normal_archive_before']=sys.argv[5];record['normal_archive_after']=digest(normal)
 record['normal_archive_unchanged']=record['normal_archive_before']==record['normal_archive_after']
 record['source_changes']=[name for name,value in record['sources'].items() if digest(runtime/name)!=value]
 (output/'identity.json').write_text(json.dumps(record,indent=2)+'\n')
assert record['normal_archive_unchanged'] and not record['source_changes']
raise SystemExit(rc)
PY
cat "$OUTPUT_DIR/result.log"
print "geometry progress: selected check passed output=$OUTPUT_DIR"
