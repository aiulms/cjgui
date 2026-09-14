#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
runtime_dir="$(cd "$script_dir/../.." && pwd)"
sdkroot_path="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"

if [[ ! -d "$sdkroot_path" ]]; then
  echo "cjgui native sidecar: unavailable SDKROOT=$sdkroot_path" >&2
  exit 2
fi

output_dir="$runtime_dir/native/lib"
mkdir -p "$output_dir"
renderer_source="$runtime_dir/native/cjgui_internal_renderer.m"
renderer_header="$runtime_dir/native/cjgui_internal_renderer.h"
bridge_source="$runtime_dir/native/cjgui_native_bridge.m"
bridge_header="$runtime_dir/native/cjgui_native_bridge.h"
renderer_object="$output_dir/cjgui_internal_renderer.o"
bridge_object="$output_dir/cjgui_native_bridge.o"
archive="$output_dir/libcjgui_internal_renderer.a"
fingerprint_file="$output_dir/cjgui_internal_renderer_sidecar.fingerprint"
typeset -a compile_flags
compile_flags=(-fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong -mmacosx-version-min=12.0)
# Keep the package build hook aligned with the macOS application host.  A
# caller may explicitly add a temporary native compile flag for an isolated
# reproducer; it must reach the sidecar which cjpm links, and participate in
# the cache key.  Normal builds leave this input empty.
if [[ -n "${CJGUI_NATIVE_CLANG_FLAGS_APPEND:-}" ]]; then
  compile_flags+=( ${=CJGUI_NATIVE_CLANG_FLAGS_APPEND} )
fi
fingerprint="sdk=$sdkroot_path\nflags=${(j: :)compile_flags}\nrenderer=$renderer_source\nbridge=$bridge_source"

needs_rebuild=0
if [[ ! -f "$archive" || ! -f "$renderer_object" || ! -f "$bridge_object" || ! -f "$fingerprint_file" ||
      "$(< "$fingerprint_file")" != "$fingerprint" || "$sdkroot_path" -nt "$fingerprint_file" ]]; then
  needs_rebuild=1
fi
for input in "$renderer_source" "$renderer_header" "$bridge_source" "$bridge_header"; do
  if [[ "$input" -nt "$archive" ]]; then
    needs_rebuild=1
  fi
done

if (( ! needs_rebuild )); then
  exit 0
fi

clang "${compile_flags[@]}" -isysroot "$sdkroot_path" \
  -c "$renderer_source" \
  -o "$renderer_object"
clang "${compile_flags[@]}" -isysroot "$sdkroot_path" \
  -c "$bridge_source" \
  -o "$bridge_object"
ar rcs "$archive" "$renderer_object" "$bridge_object"
print -rn -- "$fingerprint" > "$fingerprint_file"
