#!/usr/bin/env bash
# runtime/cjgui/platforms/linux/scripts/linux_guest.sh
#
# 宿主（macOS）侧的 Linux 工作流驱动：把权威源码同步到来宾、写平台 cjpm.toml、
# 构建 native sidecar、构建仓颉侧、按需运行。
#
# 复用规则（AGENTS.md 产物容量）：来宾只保留一份可复用工作目录
# (~/cjgui-linux)，每轮覆盖同步而不是新建目录；不复制 target/、artifacts/。
#
# 用法：
#   linux_guest.sh sync          仅同步源码 + 写平台 toml
#   linux_guest.sh sidecar       只构建 native sidecar
#   linux_guest.sh build         同步 + sidecar + cjpm build
#   linux_guest.sh undefined     构建并收集未定义符号（不链接成功也要出清单）
#   linux_guest.sh run [args...] 在来宾 X11 会话里运行消费者
#   linux_guest.sh shell         打开一个来宾 shell
set -euo pipefail

GUEST="${CJGUI_LINUX_GUEST:-oeuser@10.211.55.4}"
GUEST_ROOT="${CJGUI_LINUX_ROOT:-/home/oeuser/cjgui-linux}"
SDK_ENV='source ~/cangjie-dl/cangjie/envsetup.sh >/dev/null 2>&1'
GCC_LIB_DIR="${CJGUI_LINUX_GCC_LIB_DIR:-/usr/lib/gcc/aarch64-openEuler-linux/12}"
LINK_OPTIONS="--gc-sections -L$GCC_LIB_DIR -lvulkan -lxcb -lX11 -lX11-xcb -lxkbcommon -lfreetype -lharfbuzz -lfontconfig -lm -lpthread -ldl"
EXTRA_LDFLAGS="${CJGUI_LINUX_EXTRA_LDFLAGS:-}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
runtime_dir="$(cd "$script_dir/../../.." && pwd)"
repo_root="$(cd "$runtime_dir/.." && pwd)"
linux_dir="$runtime_dir/platforms/linux"

ssh_run() { ssh -o BatchMode=yes "$GUEST" "$@"; }

# 来宾上可能有多个写者共用一个源码根。cjpm 的 build 必须串行，否则 .a/.cjo 会互相
# 覆盖（实测症状：target 里只有 .cjo 没有 .a，链接报找不到 -l<package>）。
guest_build() {
  local cmd="$1"
  ssh_run "flock -w 1800 /tmp/cjgui-guest-build.lock -c $(printf '%q' "$cmd")"
}

apply_platform_toml() {
  local dest="$GUEST_ROOT/runtime/cjgui"
  ssh_run "cat > '$dest/cjpm.toml' <<'EOF'
[package]
cjc-version = \"1.1.3\"
name = \"cjgui\"
version = \"0.0.0\"
output-type = \"static\"
src-dir = \"src\"
link-option = \"$LINK_OPTIONS $EXTRA_LDFLAGS\"

[dependencies]
cjgui_shared_operation_core = { path = \"./shared_operation_core\" }

[ffi.c]
cjgui_internal_renderer = { path = \"./native/lib\" }
EOF
cat > '$dest/examples/range_text_window_app/cjpm.toml' <<'EOF'
[package]
cjc-version = \"1.1.3\"
name = \"cjgui_range_text_window_app\"
version = \"0.0.0\"
output-type = \"executable\"
src-dir = \"src\"
compile-option = \"-O1\"
link-option = \"$LINK_OPTIONS $EXTRA_LDFLAGS\"

[dependencies]
cjgui = { path = \"../..\" }

[ffi.c]
cjgui_internal_renderer = { path = \"./.cjgui/native/lib\" }
EOF
echo platform-toml-written"
}

do_sync() {
  # 消费者编译闭包 = lib_cjgui_source_set.sh 的命名集合（与 Windows 冻结包一致）。
  # 不要把 src/ 整目录搬过去：那会把 macOS 专用的 Metal 桥源码一起编进来，
  # 于是链接期会凭空多出数百个 native_bridge 符号需求（本阶段实测：113 vs 146）。
  local filelist
  filelist="$(mktemp)"
  ( cd "$runtime_dir" && zsh -c 'source native/scripts/lib_cjgui_source_set.sh; cjgui_framework_source_names true' ) > "$filelist"
  # --files-from 模式下 --delete 不会清掉清单外的旧文件（实测会把上次整目录同步的
  # 440 个 .cj 留在来宾），所以目录由脚本完全拥有：先清空再放闭包。
  ssh_run "rm -rf '$GUEST_ROOT/runtime/cjgui/src' && mkdir -p '$GUEST_ROOT/runtime/cjgui/src' '$GUEST_ROOT/runtime/cjgui/native' '$GUEST_ROOT/runtime/cjgui/examples/range_text_window_app' '$GUEST_ROOT/runtime/cjgui/platforms' '$GUEST_ROOT/runtime/cjgui/shared_operation_core'"
  rsync -az --delete --files-from="$filelist" "$runtime_dir/src/" "$GUEST:$GUEST_ROOT/runtime/cjgui/src/"
  rm -f "$filelist"
  rsync -az --delete --exclude 'target/' --exclude '*_test.cj' \
    "$runtime_dir/shared_operation_core/" "$GUEST:$GUEST_ROOT/runtime/cjgui/shared_operation_core/"
  rsync -az "$runtime_dir/native/" "$GUEST:$GUEST_ROOT/runtime/cjgui/native/" \
    --include '*/' --include '*.h' --exclude '*'
  rsync -az --delete --exclude 'target/' --exclude '.cjgui/' --exclude 'build-script-cache/' \
    "$runtime_dir/examples/range_text_window_app/" \
    "$GUEST:$GUEST_ROOT/runtime/cjgui/examples/range_text_window_app/"
  rsync -az --delete "$linux_dir/" "$GUEST:$GUEST_ROOT/runtime/cjgui/platforms/linux/"
  # build.cj 是 cjpm 的构建前钩子（平台分派 sidecar 构建），必须一起过去，
  # 否则普通 `cjpm build`（不带 --skip-script）在来宾上没有钩子。
  rsync -az "$runtime_dir/build.cj" "$GUEST:$GUEST_ROOT/runtime/cjgui/build.cj"
  # 消费者 src 里带 *_test.cj 的同包文件按需保留：Linux 上它们与主包一起编译。
  apply_platform_toml
}

do_sidecar() {
  ssh_run "bash '$GUEST_ROOT/runtime/cjgui/platforms/linux/scripts/build_sidecar.sh'"
}

do_build() {
  do_sync
  do_sidecar
  guest_build "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui' && cjpm build -j8 2>&1 | tail -40"
}

do_undefined() {
  do_sync
  # 用一个空档案骗过 ffi.c 的存在性检查，让链接器把所有缺失符号报全。
  ssh_run "mkdir -p '$GUEST_ROOT/runtime/cjgui/native/lib' && : > '$GUEST_ROOT/runtime/cjgui/native/lib/libcjgui_internal_renderer.a'"
  guest_build "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui' && cjpm build --skip-script -j8 2>&1 | tail -20"
  ssh_run "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui/examples/range_text_window_app' && mkdir -p .cjgui/native/lib && : > .cjgui/native/lib/libcjgui_internal_renderer.a && cjpm build --skip-script -j8 2>&1 | grep -oE 'undefined (symbol|reference)[^,]*|cjgui_[A-Za-z0-9_]+' | sort -u | head -400"
}

do_run() {
  ssh_run "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui/examples/range_text_window_app' && DISPLAY=\${DISPLAY:-:0} RANGE_TEXT_TIMING=1 ./target/release/bin/main $*"
}

do_linkprobe() {
  do_sync
  ssh_run "mkdir -p '$GUEST_ROOT/runtime/cjgui/native/lib' && : > '$GUEST_ROOT/runtime/cjgui/native/lib/libcjgui_internal_renderer.a'"
  guest_build "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui' && cjpm build --skip-script -j8 > /tmp/cj.log 2>&1; echo cjgui_exit=\$?"
  guest_build "$SDK_ENV; cd '$GUEST_ROOT/runtime/cjgui/examples/range_text_window_app' && mkdir -p .cjgui/native/lib && : > .cjgui/native/lib/libcjgui_internal_renderer.a && rm -rf target && cjpm build --skip-script -j8 > /tmp/ex.log 2>&1; echo app_exit=\$?"
  ssh_run "grep -oE 'undefined reference to [^ ]+' /tmp/ex.log | sed \"s/undefined reference to //\" | tr -d \"'\" | sort -u > /tmp/undef.txt; wc -l /tmp/undef.txt; head -400 /tmp/undef.txt"
}

case "${1:-build}" in
  linkprobe) shift; do_linkprobe ;;
  sync) shift; do_sync ;;
  sidecar) shift; do_sidecar ;;
  build) shift; do_build ;;
  undefined) shift; do_undefined ;;
  run) shift; do_run "$@" ;;
  shell) shift; exec ssh -o BatchMode=yes "$GUEST" "$@" ;;
  *) echo "unknown verb: $1" >&2; exit 2 ;;
esac
