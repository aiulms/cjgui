#!/usr/bin/env bash
# 把框架拥有的鸿蒙平台源码同步进一个消费方（lab）模块。
#
# 框架是唯一写入者：核心快照、共享 ABI 头、宿主/桥/渲染器与 CMakeLists 都
# 从 runtime/cjgui/platforms/ohos 复制；lab 只消费，不再自带实现副本。
#
# 用法： bash sync_platform.sh <LAB_ROOT>
#   LAB_ROOT 默认 <repo>/labs/ohos_cjgui_app
#
# 删除范围仅限 lab 内的生成目录（核心/应用/宿主副本），用于避免快照换代后
# 残留旧文件造成混合版本。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLATFORM/../../../.." && pwd)"
LAB="${1:-$REPO_ROOT/labs/ohos_cjgui_app}"
MODULE="$LAB/entry"
SNAPSHOT="$PLATFORM/snapshot"
HOST="$PLATFORM/host"

[ -d "$MODULE" ] || { echo "缺少消费方模块: $MODULE"; exit 1; }
[ -f "$PLATFORM/FINGERPRINT.txt" ] || { echo "缺少平台指纹: $PLATFORM/FINGERPRINT.txt"; exit 1; }
FINGERPRINT="$(cat "$PLATFORM/FINGERPRINT.txt")"
SHORT="${FINGERPRINT:0:12}"

# 1) 核心包 + 共享操作核心（来自快照）
#    用 rsync 镜像而不是「先 rm -rf 再复制」：只删除真正多出来的文件，
#    既避免误删范围过大，也不会在构建中途把整个源码树清空。
mkdir -p "$MODULE/cjgui/src" "$MODULE/shared_operation_core/src"
rsync -a --delete --exclude 'target' --exclude 'build' "$SNAPSHOT/src/" "$MODULE/cjgui/src/"
rsync -a --delete --exclude 'target' --exclude 'build' "$SNAPSHOT/shared_operation_core/src/" "$MODULE/shared_operation_core/src/"

# 2) 宿主/桥/渲染器 + CMakeLists（框架拥有）
#    --delete：cpp/ 只承载框架拥有的文件，快照换代后旧文件必须消失，
#    否则会出现混合版本（旧 ohos_renderer.cpp 与新桥同时编译）。
mkdir -p "$MODULE/src/main/cpp"
rsync -a --delete --exclude '*.o' --exclude '*.a' "$HOST/" "$MODULE/src/main/cpp/"

# 3) 共享 ABI 头（快照是权威副本）
cp "$SNAPSHOT/cjgui_internal_renderer.h" "$MODULE/src/main/cpp/cjgui_internal_renderer.h"

# 4) 生成 ohos 目标的包清单（去 darwin 框架、补 ohos 目标段）
cat > "$MODULE/cjgui/cjpm.toml" <<'TOML'
[package]
  cjc-version = "1.1.3"
  compile-option = "--dy-std"
  description = "CJGUI core (ohos snapshot)"
  name = "cjgui"
  output-type = "static"
  src-dir = "./src"
  target-dir = ""
  version = "1.0.0"

[dependencies]
  cjgui_shared_operation_core = { path = "../shared_operation_core" }

[profile]
  [profile.build]
    incremental = true
    lto = ""
  [profile.customized-option]
    debug = "-g -Woff all -Won apilevel-check"
    release = "--fast-math -O2 -s -Woff all -Won apilevel-check"
  [profile.test]

[target.aarch64-linux-ohos]
  compile-option = "-B \"${DEVECO_CANGJIE_HOME}/build-tools/third_party/llvm/bin\" -B \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/aarch64-linux-ohos\" --sysroot \"${DEVECO_OH_NATIVE_HOME}/sysroot\""
[target.aarch64-linux-ohos.bin-dependencies]
  path-option = ["${AARCH64_LIBS}", "${AARCH64_MACRO_LIBS}", "${AARCH64_KIT_LIBS}"]
  package-option = {}
TOML

cat > "$MODULE/shared_operation_core/cjpm.toml" <<'TOML'
[package]
  cjc-version = "1.1.3"
  name = "cjgui_shared_operation_core"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"

[target.aarch64-linux-ohos]
  compile-option = "-B \"${DEVECO_CANGJIE_HOME}/build-tools/third_party/llvm/bin\" -B \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos\" -L \"${DEVECO_OH_NATIVE_HOME}/llvm/lib/aarch64-linux-ohos\" --sysroot \"${DEVECO_OH_NATIVE_HOME}/sysroot\""
[target.aarch64-linux-ohos.bin-dependencies]
  path-option = ["${AARCH64_LIBS}", "${AARCH64_MACRO_LIBS}", "${AARCH64_KIT_LIBS}"]
  package-option = {}
TOML

# 5) 共享应用（runtime/cjgui/examples 是唯一来源，macOS 与鸿蒙同源）
# E.3：应用源码目录可由公共入口参数化（CJGUI_APP_SRC），默认仍是共享示例。
# 第六次复核第 5 项：目录名与仓颉包名同步参数化（CJGUI_APP_DIR_NAME /
# CJGUI_APP_PKG_NAME）——独立消费者不再被写死为设置计数示例的私有包名；
# 默认值保持原状，既有构建不受影响。
APP_SRC="${CJGUI_APP_SRC:-$REPO_ROOT/runtime/cjgui/examples/settings_counter_application/src}"
APP_DIR_NAME="${CJGUI_APP_DIR_NAME:-settings_counter_application}"
APP_PKG_NAME="${CJGUI_APP_PKG_NAME:-cjgui_settings_counter_application}"
[ -d "$APP_SRC" ] || { echo "缺少共享应用源码: $APP_SRC"; exit 1; }
mkdir -p "$MODULE/$APP_DIR_NAME/src"
# Cangjie unit tests live beside the application source for local `cjpm test`.
# They are not part of either normal HarmonyOS consumer's runtime package.
rsync -a --delete --exclude 'target' --exclude 'build' --exclude '*_test.cj' \
  "$APP_SRC/" "$MODULE/$APP_DIR_NAME/src/"
cat > "$MODULE/$APP_DIR_NAME/cjpm.toml" <<TOML
[package]
  cjc-version = "1.1.3"
  name = "${APP_PKG_NAME}"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"

[dependencies]
  cjgui = { path = "../cjgui" }
  cjgui_shared_operation_core = { path = "../shared_operation_core" }

[target.aarch64-linux-ohos]
  compile-option = "-B \"\${DEVECO_CANGJIE_HOME}/build-tools/third_party/llvm/bin\" -B \"\${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"\${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\" -L \"\${DEVECO_OH_NATIVE_HOME}/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos\" -L \"\${DEVECO_OH_NATIVE_HOME}/llvm/lib/aarch64-linux-ohos\" --sysroot \"\${DEVECO_OH_NATIVE_HOME}/sysroot\""
[target.aarch64-linux-ohos.bin-dependencies]
  path-option = ["\${AARCH64_LIBS}", "\${AARCH64_MACRO_LIBS}", "\${AARCH64_KIT_LIBS}"]
  package-option = {}
TOML

# 5) 可选传输桥（框架拥有；消费方只声明依赖，不自带实现副本）
#
#   transport/src/    生产实现（总是同步）
#   transport/verify/ 验证接缝源码。它**总是**同步进 src-dir，但所有声明都由条件编译
#     `@When[cjgui_transport_verify == "on"]` 门控；下面生成的 cjpm.toml 决定该 cfg
#     的字面值。普通产物编入的是**空文件**，@C 符号不存在 → 宿主桥 dlsym 取不到 →
#     永不注册。这就是 B1 要求的「普通 HAP 不编入该能力」。
TRANSPORT="$PLATFORM/transport"
if [ -d "$TRANSPORT/src" ]; then
  mkdir -p "$MODULE/ohos_transport/src"
  rsync -a --delete --exclude 'target' --exclude 'build' "$TRANSPORT/src/" "$MODULE/ohos_transport/src/"
  VERIFY_CFG="off"
  VERIFY_STATE="not-compiled"
  if [ "${CJGUI_TRANSPORT_VERIFY:-0}" = "1" ]; then
    VERIFY_CFG="on"
    VERIFY_STATE="compiled"
  fi
  if [ -d "$TRANSPORT/verify" ]; then
    rsync -a --exclude 'target' --exclude 'build' "$TRANSPORT/verify/" "$MODULE/ohos_transport/src/"
  fi
  cat > "$MODULE/ohos_transport/cjpm.toml" <<TOML
[package]
  cjc-version = "1.1.3"
  compile-option = "--dy-std -Woff unused --cfg=\\"cjgui_transport_verify=${VERIFY_CFG}\\""
  name = "cjgui_ohos_transport"
  version = "0.0.0"
  output-type = "static"
  src-dir = "src"

[target.aarch64-linux-ohos]
  compile-option = "-B \\"\${DEVECO_CANGJIE_HOME}/build-tools/third_party/llvm/bin\\" -B \\"\${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\\" -L \\"\${DEVECO_OH_NATIVE_HOME}/sysroot/usr/lib/aarch64-linux-ohos\\" -L \\"\${DEVECO_OH_NATIVE_HOME}/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos\\" -L \\"\${DEVECO_OH_NATIVE_HOME}/llvm/lib/aarch64-linux-ohos\\" --sysroot \\"\${DEVECO_OH_NATIVE_HOME}/sysroot\\""
[target.aarch64-linux-ohos.bin-dependencies]
  path-option = ["\${AARCH64_LIBS}", "\${AARCH64_MACRO_LIBS}", "\${AARCH64_KIT_LIBS}"]
  package-option = {}
TOML
  # C：公共文字代理模板（框架拥有 → 消费工程 ets 目录）
  mkdir -p "$MODULE/src/main/ets/proxy"
  rsync -a --exclude 'target' --exclude 'build' "$PLATFORM/arkts/" "$MODULE/src/main/ets/proxy/"

  echo "  传输桥: 已同步（验证接缝 ${VERIFY_STATE}: cjgui_transport_verify=${VERIFY_CFG}）"
  echo "cjgui_transport_verify=${VERIFY_CFG}" > "$MODULE/ohos_transport/.verify_variant"
fi

# 6) 记录参与编译的源清单（与平台指纹一起构成冻结输入证据）
#    只保留当前指纹的清单：多份共存会让人误以为旧指纹也是有效输入。
find "$MODULE" -maxdepth 1 -name 'cjgui_sync_*.manifest' ! -name "cjgui_sync_$SHORT.manifest" -delete 2>/dev/null || true
{
  echo "platform_fingerprint=$FINGERPRINT"
  echo "synced_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  find "$MODULE/cjgui/src" "$MODULE/shared_operation_core/src" "$MODULE/$APP_DIR_NAME/src" \
    "$MODULE/src/main/cpp" "$MODULE/ohos_transport/src" -type f | sort | while read -r f; do
    shasum -a 256 "$f"
  done
} > "$MODULE/cjgui_sync_$SHORT.manifest"

echo "同步完成（平台指纹: ${FINGERPRINT}）"
echo "  lab=$LAB"
echo "  核心 .cj: $(find "$MODULE/cjgui" "$MODULE/shared_operation_core" -name '*.cj' | grep -v _test.cj | wc -l | tr -d ' ')  宿主源码: $(ls "$MODULE/src/main/cpp"/*.cpp "$MODULE/src/main/cpp"/*.c 2>/dev/null | wc -l | tr -d ' ')"
