#!/usr/bin/env bash
# runtime/cjgui/platforms/linux/scripts/build_sidecar.sh
#
# 在 Linux 上构建 CJGUI 内部 C ABI 的 native sidecar：
#   platforms/linux/native/*.c  ->  native/lib/libcjgui_internal_renderer.a
#
# 与 macOS 的 build_cjgui_internal_renderer_sidecar.sh 对应：产物路径、
# 指纹缓存语义一致（输入变了才重编），但编译器、头文件与依赖是 Linux 系统库。
#
# 环境变量：
#   CJGUI_LINUX_CC         覆盖编译器（默认 cc）
#   CJGUI_LINUX_CFLAGS     追加编译参数（参与缓存键）
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
linux_dir="$(cd "$script_dir/.." && pwd)"
runtime_dir="$(cd "$linux_dir/../.." && pwd)"
native_dir="$linux_dir/native"
output_dir="$runtime_dir/native/lib"
archive="$output_dir/libcjgui_internal_renderer.a"
fingerprint_file="$output_dir/cjgui_linux_sidecar.fingerprint"

cc="${CJGUI_LINUX_CC:-cc}"
extra_flags="${CJGUI_LINUX_CFLAGS:-}"
# 系统文字栈的头文件不在默认搜索路径里（freetype 在 /usr/include/freetype2、
# harfbuzz 在 /usr/include/harfbuzz），用 pkg-config 取；取不到时退回已知路径。
if command -v pkg-config >/dev/null 2>&1; then
  stack_cflags="$(pkg-config --cflags freetype2 harfbuzz fontconfig 2>/dev/null || true)"
fi
if [ -z "${stack_cflags:-}" ]; then
  stack_cflags="-I/usr/include/freetype2 -I/usr/include/harfbuzz"
fi
flags="-O2 -g -std=c11 -Wall -Wextra -Wno-unused-parameter -fstack-protector-strong -fPIC $stack_cflags"

sources=()
for src in "$native_dir"/*.c; do
  [ -e "$src" ] || continue
  sources+=("$src")
done

if [ "${#sources[@]}" -eq 0 ]; then
  echo "cjgui linux sidecar: no native sources under $native_dir" >&2
  exit 2
fi

mkdir -p "$output_dir"

fingerprint="cc=$cc
flags=$flags $extra_flags
sources=${sources[*]}
header=$runtime_dir/native/cjgui_internal_renderer.h"

needs_rebuild=0
if [ ! -f "$archive" ] || [ ! -f "$fingerprint_file" ]; then
  needs_rebuild=1
elif [ "$(cat "$fingerprint_file")" != "$fingerprint" ]; then
  needs_rebuild=1
fi
if [ "$runtime_dir/native/cjgui_internal_renderer.h" -nt "$archive" ]; then
  needs_rebuild=1
fi
for src in "${sources[@]}"; do
  if [ "$src" -nt "$archive" ]; then needs_rebuild=1; fi
done
if [ "$needs_rebuild" -eq 0 ]; then
  echo "cjgui linux sidecar: up to date -> $archive"
  exit 0
fi

objects=()
for src in "${sources[@]}"; do
  obj="$output_dir/$(basename "${src%.c}").o"
  # shellcheck disable=SC2086
  "$cc" $flags $extra_flags \
    -I"$native_dir" -I"$runtime_dir/native" \
    -c "$src" -o "$obj"
  objects+=("$obj")
done

rm -f "$archive"
ar rcs "$archive" "${objects[@]}"
printf '%s' "$fingerprint" > "$fingerprint_file"
echo "cjgui linux sidecar: built ${#objects[@]} objects -> $archive"
