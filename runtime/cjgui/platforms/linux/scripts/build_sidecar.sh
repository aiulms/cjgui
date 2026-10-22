#!/usr/bin/env bash
# Linux C ABI archive. Normal application builds always pass a private output.
# The no-argument location remains for the existing framework build.cj hook.
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
framework="$(cd "$script_dir/../../.." && pwd)"
output_dir="${CJGUI_LINUX_NATIVE_OUTPUT_DIR:-}"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --framework) framework="$2"; shift 2 ;;
    --output-dir) output_dir="$2"; shift 2 ;;
    *) echo "usage: build_sidecar.sh [--framework ROOT] [--output-dir PRIVATE_LIB_DIR]" >&2; exit 2 ;;
  esac
done
native_dir="$framework/platforms/linux/native"
header_dir="$framework/native"
output_dir="${output_dir:-$framework/native/lib}"
cc="${CJGUI_LINUX_CC:-cc}"
archiver="${CJGUI_LINUX_AR:-ar}"
mkdir -p "$output_dir"
# Direct sidecar invocations serialize too. The app runner separately holds its
# output-root lock from input preparation until cjpm and receipt publication.
exec 9>"$output_dir/.sidecar.lock"
flock -n 9 || { echo 'cjgui linux sidecar: output_busy' >&2; exit 2; }
archive="$output_dir/libcjgui_internal_renderer.a"
fingerprint_file="$output_dir/cjgui_linux_sidecar.fingerprint"
stack_cflags="$(pkg-config --cflags freetype2 harfbuzz fontconfig libpng)"
flags=(-O2 -g -std=c11 -Wall -Wextra -Wno-unused-parameter -fstack-protector-strong -fPIC)
while IFS= read -r -d '' flag; do flags+=("$flag"); done < <(
  python3 - "$stack_cflags" "${CJGUI_LINUX_CFLAGS:-}" <<'PY'
import shlex,sys
for text in sys.argv[1:]:
    for item in shlex.split(text): sys.stdout.buffer.write(item.encode()+b'\0')
PY
)
sources=("$native_dir"/*.c)
[ -f "${sources[0]}" ] || { echo "no Linux native sources: $native_dir" >&2; exit 2; }
compiler_version="$("$cc" --version)"
fingerprint="$(python3 - "$native_dir" "$header_dir/cjgui_internal_renderer.h" "$cc" "$compiler_version" "${flags[@]}" <<'PY'
from pathlib import Path
import hashlib,json,sys
native=Path(sys.argv[1]); files=sorted([*native.glob('*.c'),*native.glob('*.h'),Path(sys.argv[2])])
print(json.dumps({'format':2,'compiler':sys.argv[3],'compiler_version':sys.argv[4],
 'flags':sys.argv[5:],'files':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}},sort_keys=True))
PY
)"
if [ -f "$archive" ] && [ -f "$fingerprint_file" ] && [ "$(cat "$fingerprint_file")" = "$fingerprint" ]; then
  echo "cjgui linux sidecar: up to date -> $archive"
  exit 0
fi
work="$(mktemp -d "$output_dir/.sidecar-work.XXXXXX")"
trap 'rm -rf -- "${work:?}"' EXIT
objects=()
for source in "${sources[@]}"; do
  object="$work/$(basename "${source%.c}").o"
  "$cc" "${flags[@]}" -I"$native_dir" -I"$header_dir" -c "$source" -o "$object"
  objects+=("$object")
done
"$archiver" rcs "$work/libcjgui_internal_renderer.a" "${objects[@]}"
printf '%s' "$fingerprint" > "$work/fingerprint"
mv -f "$work/libcjgui_internal_renderer.a" "$archive"
mv -f "$work/fingerprint" "$fingerprint_file"
echo "cjgui linux sidecar: built ${#objects[@]} objects -> $archive"
