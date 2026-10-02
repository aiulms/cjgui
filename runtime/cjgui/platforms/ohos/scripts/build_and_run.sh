#!/usr/bin/env bash
# CJGUI 鸿蒙后端：同步 → 渲染器 → 构建 → 闭包校验 → 安装 → 启动断言 → 取证。
#
# 失败语义：
#  - 任一必需库缺失、HAP 缺失、启动断言不成立 → 非零退出（环境阻塞与产品失败
#    分开：环境阻塞单独打印 ENV-BLOCK，产品失败打印 PRODUCT-FAIL）。
#  - 断言只认本轮日志：先清空设备日志缓冲再启动，旧日志不能冒充本轮成功。
#
# 用法： bash build_and_run.sh <LAB_ROOT> [--no-emulator-start] [--run-id <id>]
# 负对照（必须产出失败，用于证明闸门有效）：
#   CJGUI_NEGATIVE_MISSING_LIB=libnope.so   闭包校验必须 FAIL
#   CJGUI_NEGATIVE_NO_START=1               启动断言必须 FAIL（旧日志不得假绿）
#   CJGUI_NEGATIVE_NO_RELINK=1              重链不变量必须 FAIL（app.so 用过旧渲染器）
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLATFORM/../../../.." && pwd)"
# 第一个位置参数若是裸路径才是 LAB；以 '-' 开头的都是选项（避免把 --flag 当目录）。
if [ $# -gt 0 ] && [ "${1#-}" = "$1" ]; then
  LAB="$1"
  shift
else
  LAB="$REPO_ROOT/labs/ohos_cjgui_app"
fi
source "$HERE/env.sh"

NO_START=0
RUN_ID=""
VERIFY_TRANSPORT=0
TEST_GATES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --no-emulator-start) NO_START=1 ;;
    --verify-transport) VERIFY_TRANSPORT=1 ;;
    --test-gates) TEST_GATES=1 ;;
    --run-id) RUN_ID="${2:?--run-id 需要值}"; shift ;;
    *) echo "未知参数: $1"; exit 2 ;;
  esac
  shift
done

# 变体身份必须显式、可核对。两个维度相互独立，可同时开：
#  - verify-transport：把 transport/verify 编入 src-dir（测试控制帧可用）
#  - test-gates：渲染器以 -DCJGUI_OHOS_TEST_GATES 编译（时序闸门可用）
# 普通产物不含该文件与该符号；测试产物才注册/生效。两种产物不能混作同一身份。
if [ "$VERIFY_TRANSPORT" = "1" ]; then
  export CJGUI_TRANSPORT_VERIFY=1
else
  unset CJGUI_TRANSPORT_VERIFY
fi
if [ "$TEST_GATES" = "1" ]; then
  GATE_RENDERER_ARG="--test-gates"
else
  GATE_RENDERER_ARG=""
fi
if [ "$VERIFY_TRANSPORT" = "1" ] && [ "$TEST_GATES" = "1" ]; then
  BUILD_VARIANT="verify-transport+test-gates"
elif [ "$VERIFY_TRANSPORT" = "1" ]; then
  BUILD_VARIANT="verify-transport"
elif [ "$TEST_GATES" = "1" ]; then
  BUILD_VARIANT="test-gates"
else
  BUILD_VARIANT="normal"
fi
if [ "$TEST_GATES" = "1" ]; then
  export CJGUI_TEST_GATES=1
fi
echo "BUILD_VARIANT=$BUILD_VARIANT"

# A1 §5 闸门参数：按住首帧 Flush 的时长与次数。默认 4000ms / 1 次——
# 超过渲染等待上限 2000ms，首帧必然超时成 PENDING，且只卡这一次，窗口
# 能继续推进到 Accepted（这才是可观测的 Pending→Accepted，而不是停在 Pending）。
GATE_HOLD_MS="${CJGUI_TEST_GATE_FLUSH_HOLD_MS:-4000}"
GATE_HOLD_COUNT="${CJGUI_TEST_GATE_FLUSH_HOLD_COUNT:-1}"

ARTIFACTS="$REPO_ROOT/labs/ohos_cangjie_smoke/artifacts/cjgui-backend"
mkdir -p "$ARTIFACTS/build" "$ARTIFACTS/run" "$ARTIFACTS/screenshots"
[ -n "$RUN_ID" ] || RUN_ID="run_$(date +%Y%m%d_%H%M%S)"
RUN_DIR="$ARTIFACTS/run/$RUN_ID"
mkdir -p "$RUN_DIR"
LOG="$RUN_DIR/build_$RUN_ID.log"
echo "RUN_ID=$RUN_ID"

echo "== 0/7 平台指纹 + 同步消费方源码 =="
bash "$HERE/fingerprint.sh"
# 消费方同步钩子（CJGUI_CONSUMER_SYNC）：独立产品需要的同步不止框架平台一份
# （还要搬共享包、生成产品依赖清单），由消费方提供一个脚本一次做完。钩子存在
# 时用它替代框架的 sync_platform 调用，避免「入口再同步一次把产品清单覆盖回
# 默认值」——这正是 2026-09-29 复核记录的必要返工第一条。
if [ -n "${CJGUI_CONSUMER_SYNC:-}" ]; then
  echo "  消费方同步钩子: $CJGUI_CONSUMER_SYNC"
  bash "$CJGUI_CONSUMER_SYNC"
else
  bash "$HERE/sync_platform.sh" "$LAB"
fi
if [ "$TEST_GATES" = "1" ]; then
  export CJGUI_TEST_GATES=1
  # 第九次复核 B：host 侧闸门/夹具 define 必须进入 hvigor CMake（renderer.a
  # 由 build_renderer.sh 注入，host_bridge 由本入口幂等注入 lab CMakeLists）。
  for cm in "$LAB/entry/src/main/cpp/CMakeLists.txt"; do
    if [ -f "$cm" ] && ! grep -q "CJGUI_OHOS_TEST_GATES" "$cm"; then
      sed -i.bak 's/add_library(entry SHARED/add_compile_definitions(CJGUI_OHOS_TEST_GATES)\nadd_library(entry SHARED/' "$cm"
      rm -f "$cm.bak"
    fi
  done
fi


echo "== 0b/7 编译宿主渲染器静态库 =="
# shellcheck disable=SC2086  # GATE_RENDERER_ARG 为空时不应产生空参数
bash "$HERE/build_renderer.sh" "$LAB" $GATE_RENDERER_ARG

echo "== 0c/7 强制重链（cjpm 不感知 .a 变化）=="
# 实测结论：只删 cjpm 的增量账本（.dep-cache/.cjpm-history）**不会**触发重链
# （libcjgui_app.so 的 sha256 不变）；必须删掉链接产物本身才会重新链接。
# 因此这里只失效 libcjgui_app.so 的一组产物（可枚举，通常 4 个），
# 不做 intermediates 目录递归删除；「是否真的用了当前渲染器」另用 mtime
# 不变量断言（见下面 1c 步），不靠删文件数量赌运气。
RENDERER_LIB="$LAB/entry/oh_renderer/libcjgui_ohos_renderer.a"
[ -f "$RENDERER_LIB" ] || { echo "PRODUCT-FAIL 缺少渲染器静态库: $RENDERER_LIB"; exit 1; }
INVALIDATED=0
if [ "${CJGUI_NEGATIVE_NO_RELINK:-0}" = "1" ]; then
  echo "  负对照：跳过失效（预期 1c 重链不变量失败）"
else
  while IFS= read -r f; do
    rm -f "$f"
    INVALIDATED=$((INVALIDATED + 1))
  done < <(find "$LAB/entry/build" -name 'libcjgui_app.so' -type f 2>/dev/null)
  echo "  失效 libcjgui_app.so 产物 $INVALIDATED 个"
fi

echo "== 1/7 构建（hvigor 仓颉+C++ 混合管线）=="
# devecocli 必须在项目根（含 build-profile.json5）内执行，否则直接报
# 「Not in a valid project directory」。LAB 已是绝对路径，cd 不影响后续步骤。
cd "$LAB"
if ! "$DEVECO_CLI" build --build-mode debug >"$LOG" 2>&1; then
  echo "PRODUCT-FAIL 构建失败；日志: ${LOG}"
  tail -40 "$LOG"
  exit 1
fi
grep -E "BUILD SUCCESSFUL|Finished" "$LOG" | tail -2 || true

echo "== 1b/7 按产物重算仓颉运行时库闭包并重打包 =="
bash "$HERE/package_runtime_libs.sh" "$LAB"
if ! "$DEVECO_CLI" build --build-mode debug >>"$LOG" 2>&1; then
  echo "PRODUCT-FAIL 二次构建失败；日志: ${LOG}"
  tail -40 "$LOG"
  exit 1
fi

HAP="$LAB/entry/build/default/outputs/default/entry-default-unsigned.hap"
# devecocli 返回时大 HAP 可能仍在落盘（实测 33MB 包在返回后数秒才完成写入），
# 有界等待而非立即失败；超时才是真失败。
HAP_WAIT=0
while [ ! -f "${HAP}" ] && [ "${HAP_WAIT}" -lt 20 ]; do
  sleep 2
  HAP_WAIT=$((HAP_WAIT + 2))
done
if [ ! -f "${HAP}" ]; then
  echo "PRODUCT-FAIL 未找到 HAP: ${HAP}（等待 ${HAP_WAIT}s 后仍不存在）"
  exit 1
fi
HAP_SHA="$(shasum -a 256 "$HAP" | awk '{print $1}')"
echo "HAP: $HAP ($(du -h "$HAP" | cut -f1)) sha256=$HAP_SHA"
cp "$HAP" "$ARTIFACTS/build/entry-default-unsigned-last.hap"
echo "$HAP_SHA" > "$RUN_DIR/hap_sha256.txt"

echo "== 1c/7 重链不变量：app.so 必须不早于本轮渲染器静态库 =="
APP_LINK_SO="$(find "$LAB/entry/build" -path '*release/cjgui_app/libcjgui_app.so' -type f | head -1)"
if [ -z "$APP_LINK_SO" ]; then
  echo "PRODUCT-FAIL 未生成 libcjgui_app.so 链接产物（强制重链无效）"
  exit 1
fi
APP_SO_MTIME="$(stat -f '%m' "$APP_LINK_SO")"
RENDERER_MTIME="$(stat -f '%m' "$RENDERER_LIB")"
if [ "$APP_SO_MTIME" -lt "$RENDERER_MTIME" ]; then
  if [ "${CJGUI_NEGATIVE_NO_RELINK:-0}" = "1" ]; then
    echo "NEGATIVE-CONTROL OK：跳过失效时重链不变量按预期失败"
    exit 0
  fi
  echo "PRODUCT-FAIL libcjgui_app.so 早于渲染器静态库：本次 HAP 可能用了旧渲染器"
  echo "  app.so=$APP_LINK_SO mtime=$APP_SO_MTIME"
  echo "  renderer.a=$RENDERER_LIB mtime=$RENDERER_MTIME"
  exit 1
fi
if [ "${CJGUI_NEGATIVE_NO_RELINK:-0}" = "1" ]; then
  echo "NEGATIVE-CONTROL FAIL：跳过失效却仍通过重链不变量（闸门无效）"
  exit 1
fi
echo "  OK   app.so 不早于 renderer.a（mtime ${APP_SO_MTIME} >= ${RENDERER_MTIME}）"
echo "renderer_lib=$(shasum -a 256 "$RENDERER_LIB" | awk '{print $1}')" >> "$RUN_DIR/hap_sha256.txt"
echo "app_link_so=$APP_LINK_SO mtime=$APP_SO_MTIME" >> "$RUN_DIR/hap_sha256.txt"

echo "== 2/7 依赖闭包校验（实际 NEEDED + 系统库白名单，缺一即失败）=="
# 负对照变量统一：CJGUI_NEGATIVE_MISSING_LIB 翻译成闭包脚本认识的
# CJGUI_EXTRA_REQUIRED_LIBS（追加一个必然不存在的库名）。
if [ -n "${CJGUI_NEGATIVE_MISSING_LIB:-}" ]; then
  export CJGUI_EXTRA_REQUIRED_LIBS="${CJGUI_EXTRA_REQUIRED_LIBS:-$CJGUI_NEGATIVE_MISSING_LIB}"
fi
# E.3：应用自身库名随 CJGUI_APP_DIR_NAME 参数化（库名 = libcjgui_<目录名>；
# 独立消费者不再被写死为设置计数示例的库名，默认值保持原状）。
# 2026-09-29 返工：显式 CJGUI_APP_PKG_LIB 优先——产品模块的包名与目录名不必
# 同名（例如目录 pharos_mark_application / 包 libpharos_mark_ohos_application.so），
# 由目录名推导出的名字会把正确的产品库判成 MISS。
APP_PKG_LIB_FOR_CLOSURE="${CJGUI_APP_PKG_LIB:-libcjgui_${CJGUI_APP_DIR_NAME:-settings_counter_application}.so}"
if ! CJGUI_APP_PKG_LIB="$APP_PKG_LIB_FOR_CLOSURE" \
    bash "$HERE/verify_hap_closure.sh" "$HAP" "$RUN_DIR/closure_$RUN_ID.txt"; then
  if [ -n "${CJGUI_NEGATIVE_MISSING_LIB:-}" ]; then
    echo "NEGATIVE-CONTROL OK：缺库时闭包校验按预期失败"
    exit 0
  fi
  echo "PRODUCT-FAIL 依赖闭包不完整"
  exit 1
fi

# 断言函数：只接受本轮日志（缓冲已清空）。
# 双档语义（第八次复核链1/Q3）：
#  - 真实渲染档：surface 发布 → owner 进入 Phase B（host started; pumping turns）
#    且必须见场景提交（present frame ok）。
#  - 未分类的 Surface 在 Phase A 暂时等待；这条日志不能决定最终档位。
#  - 替身服务档须另见 KnownShimNoRef 与 published=0，才接受 owner 服务。
assert_started() {
  local logfile="$1"
  local want_pid="${2:-}"
  local ok=0
  if grep -q "host started; pumping turns" "$logfile"; then
    # Surface 可能在 Phase A 暂时未发布；以之后的真实渲染结论为准。
    if [ -n "$want_pid" ] && [ "$want_pid" != "unknown" ]; then
      if grep "host started; pumping turns" "$logfile" | awk '{print $3}' | grep -qx "$want_pid"; then
        echo "  OK   marker 归属本轮 PID（pid=${want_pid}）"
      else
        echo "  FAIL owner marker 的 PID 不是本轮实例（期望 pid=${want_pid}，属旧实例残留）"
        ok=1
      fi
    fi
    echo "  OK   owner 启动（host started; pumping turns）"
    if grep -q "present frame ok" "$logfile"; then
      echo "  OK   场景提交（present frame ok）"
    else
      echo "  FAIL 缺场景提交日志"
      ok=1
    fi
  elif grep -qE "surface pending; owner service active|stand-in serving" "$logfile"; then
    # 确认最终分类后才接受无渲染 owner 服务。
    if [ -n "$want_pid" ] && [ "$want_pid" != "unknown" ]; then
      if grep -E "surface pending; owner service active|stand-in serving" "$logfile" | awk '{print $3}' | grep -qx "$want_pid"; then
        echo "  OK   marker 归属本轮 PID（pid=${want_pid}）"
      else
        echo "  FAIL owner marker 的 PID 不是本轮实例（期望 pid=${want_pid}，属旧实例残留）"
        ok=1
      fi
    fi
    if grep -q "capability=KnownShimNoRef" "$logfile"; then
      echo "  OK   已确认 KnownShimNoRef，owner 保持服务"
    else
      echo "  FAIL 等待期未确认 KnownShimNoRef"
      ok=1
    fi
    if grep -q "published=0" "$logfile"; then
      echo "  OK   surface 未发布（published=0）"
    else
      echo "  FAIL 替身档缺明确不发布证据（published=0）"
      ok=1
    fi
  else
    echo "  FAIL 缺 owner 启动日志（渲染档 host started / 无 Surface 档 owner service 均未出现）"
    ok=1
  fi
  if grep -q "app_main_cangjie: ingress registered" "$logfile"; then
    echo "  OK   宿主导入仓颉入口（CJGUI 核心装载）"
  else
    echo "  FAIL 缺仓颉入口装载日志"
    ok=1
  fi
  return $ok
}

# 变体断言（B1/E/A1§5）：产物身份必须与构建变体一致。
#  - verify-transport：测试变体**必须**有接缝注册日志与一次性凭据；普通产物
#    **必须缺**接缝（缺 = 预期，出现 = 能力被编入，FAIL）。
#  - test-gates：测试变体**必须**受理闸门（rc=0）并**真的按住过** Flush；
#    普通产物若被显式请求闸门，**必须**如实返回 rc=-1 且绝不出现按住日志。
#    两个维度各自独立判定，互不掩蔽。
assert_variant() {
  local logfile="$1"
  local ok=0
  case "$BUILD_VARIANT" in
    *verify-transport*)
      if grep -q "transport verify seam: present" "$logfile"; then
        echo "  OK   测试产物已注册验证接缝"
      else
        echo "  FAIL 测试产物未注册验证接缝"
        ok=1
      fi
      if grep -q "verify seam armed token=" "$logfile"; then
        echo "  OK   测试产物发出一次性凭据"
      else
        echo "  FAIL 测试产物未发出凭据"
        ok=1
      fi
      ;;
    *)
      if grep -q "transport verify seam: absent (normal product)" "$logfile"; then
        echo "  OK   普通产物无验证接缝（seam absent）"
      else
        echo "  FAIL 普通产物缺 'seam absent' 证据（闸门可能被编入）"
        ok=1
      fi
      if grep -q "transport verify seam: present" "$logfile"; then
        echo "  FAIL 普通产物出现了验证接缝注册（能力不该被编入）"
        ok=1
      fi
      ;;
  esac

  case "$BUILD_VARIANT" in
    *test-gates*)
      if grep -qE "test gate set request ms=[0-9]+ count=-?[0-9]+ rc=0" "$logfile"; then
        echo "  OK   测试产物受理闸门请求（rc=0）"
      else
        echo "  FAIL 测试产物未受理闸门请求（缺 rc=0 证据）"
        ok=1
      fi
      # 仅受理不够：渲染档必须**真的**在生产 Flush 路径上按住过，否则闸门
      # 是空壳。替身档（KnownShimNoRef 拒绝发布，published=0）无渲染、无
      # Flush 可按住——受理 rc=0 即可，不得以「未按住」否认闸门接线。
      if grep -q "published=0" "$logfile" && grep -q "capability=KnownShimNoRef" "$logfile"; then
        echo "  OK   替身档无渲染：闸门受理即足够（无 Flush 可按住）"
      elif grep -q "test gate holding flush ms=" "$logfile"; then
        echo "  OK   闸门确实按住了生产 Flush"
      else
        echo "  FAIL 闸门只被请求、从未按住 Flush（时序注入未生效）"
        ok=1
      fi
      ;;
    *)
      if grep -q "test gate set request" "$logfile"; then
        if grep -qE "test gate set request .* rc=-1" "$logfile"; then
          echo "  OK   普通产物如实拒绝闸门请求（rc=-1，能力不可用）"
        else
          echo "  FAIL 普通产物未如实拒绝闸门请求"
          ok=1
        fi
        if grep -q "test gate holding flush" "$logfile"; then
          echo "  FAIL 普通产物出现了闸门按住（时序被测试能力污染）"
          ok=1
        else
          echo "  OK   普通产物无任何闸门按住"
        fi
      fi
      ;;
  esac
  return $ok
}

# E 负对照（E.1）：「只有接缝日志、缺 owner/present/入口装载」必须被启动断言
# 拒绝。用真实断言函数跑一份伪造日志：断言函数若被掩蔽或放行，负对照报 FAIL。
if [ "${CJGUI_NEGATIVE_SEAM_ONLY:-0}" = "1" ]; then
  echo "== 负对照：仅接缝日志（预期启动断言失败）=="
  FAKE_LOG="$RUN_DIR/seam_only_log_$RUN_ID.txt"
  {
    echo "transport verify seam: present"
    echo "verify seam armed token=negative-control"
  } > "$FAKE_LOG"
  SEAM_ONLY_FAILURES=0
  assert_started "$FAKE_LOG" || SEAM_ONLY_FAILURES=1
  assert_variant "$FAKE_LOG" || SEAM_ONLY_FAILURES=1
  if [ "$SEAM_ONLY_FAILURES" = "1" ]; then
    echo "NEGATIVE-CONTROL OK：仅接缝日志无法满足启动断言"
    exit 0
  fi
  echo "NEGATIVE-CONTROL FAIL：仅接缝日志竟通过启动断言（断言掩蔽仍在）"
  exit 1
fi

echo "== 3/7 设备检查与安装 =="
if [ "$NO_START" = "0" ]; then
  bash "$HERE/start_emulator.sh"
fi
"$HDC" list targets | tee "$RUN_DIR/targets_$RUN_ID.txt"
"$HDC" install -r "$HAP" | tee "$RUN_DIR/install_$RUN_ID.txt"
# 安装替换是异步生效的（实测：install 返回后立即启动，进程可能还跑旧镜像
# ——旧 verify 镜像的接缝注册冒充本轮 normal 产物）。先停旧进程并给系统
# 一小段完成镜像切换的时间，再启动本轮实例。
BUNDLE_NAME="$(grep -oE '"bundleName"\s*:\s*"[^"]+"' "$LAB/AppScope/app.json5" | sed 's/.*"\([^"]*\)"$/\1/' | head -1)"
ABILITY_NAME="$(grep -oE '"name"\s*:\s*"[^"]*Ability"' "$LAB/entry/src/main/module.json5" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
if [ -z "$BUNDLE_NAME" ] || [ -z "$ABILITY_NAME" ]; then
  echo "PRODUCT-FAIL 无法从目标工程解析应用身份：bundle='$BUNDLE_NAME' ability='$ABILITY_NAME'（lab=$LAB）"
  exit 1
fi
# D（触摸包指导接续）：构建、安装、启动、PID 与断言共用同一应用身份。
# env 默认值来自设置示例；目标工程不符（如 thermo）时以目标工程为准。
# 显式覆盖（CJGUI_APP_BUNDLE/CJGUI_APP_ABILITY）与目标工程不一致 → 具名失败，
# 不允许「构建 thermo、启动设置、断言成功」。
if [ "${CJGUI_APP_BUNDLE_SET:-0}" = "1" ] && [ "$CJGUI_APP_BUNDLE" != "$BUNDLE_NAME" ]; then
  echo "PRODUCT-FAIL 显式 CJGUI_APP_BUNDLE=$CJGUI_APP_BUNDLE 与目标工程 bundle=$BUNDLE_NAME 不一致（lab=$LAB）"
  exit 1
fi
if [ "${CJGUI_APP_ABILITY_SET:-0}" = "1" ] && [ "$CJGUI_APP_ABILITY" != "$ABILITY_NAME" ]; then
  echo "PRODUCT-FAIL 显式 CJGUI_APP_ABILITY=$CJGUI_APP_ABILITY 与目标工程 ability=$ABILITY_NAME 不一致（lab=$LAB）"
  exit 1
fi
CJGUI_APP_BUNDLE="$BUNDLE_NAME"
CJGUI_APP_ABILITY="$ABILITY_NAME"
echo "  应用身份: bundle=$CJGUI_APP_BUNDLE ability=$CJGUI_APP_ABILITY"
"$HDC" shell "aa force-stop $BUNDLE_NAME" >/dev/null 2>&1 || true
sleep 2

echo "== 4/7 启动本轮实例（先清空日志缓冲，旧日志不能冒充本轮）=="
# E 返工：清日志的真实结果要被记录，不能写常量 cleared_before_launch=1 冒充成功。
# E.2：启动标识与时间戳在**启动之前**落账（先前的 launch_ts 在启动/等待/取日志
# 之后生成，只是附记）。LAUNCH_ID 与 PID/HAP/日志区间一起构成本轮身份。
LAUNCH_ID="$(uuidgen 2>/dev/null || date +%s%N)"
LAUNCH_TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
echo "launch_id=$LAUNCH_ID"
echo "launch_ts=$LAUNCH_TS"
STALE_LOG_MODE=0
if [ "${CJGUI_NEGATIVE_STALE_LOG:-0}" = "1" ]; then
  # 负对照：不清缓冲、不启动。缓冲里留着旧实例的 marker，断言必须因
  # PID 绑定不符而拒绝——证明旧实例日志不能满足本轮断言。
  echo "负对照：保留旧实例日志、不启动（预期 PID 绑定拒绝旧 marker）"
  STALE_LOG_MODE=1
  LOG_CLEARED="skipped(stale-negative)"
else
  LOG_CLEARED="failed"
  if "$HDC" shell "hilog -r" >/dev/null 2>&1; then
    LOG_CLEARED="ok"
  fi
fi
echo "  hilog clear: $LOG_CLEARED"
if [ "$LOG_CLEARED" != "ok" ] && [ "$STALE_LOG_MODE" != "1" ]; then
  echo "PRODUCT-FAIL 清空日志缓冲失败：本轮日志起点不可信，启动断言不能作为证据"
  exit 1
fi
if [ "$STALE_LOG_MODE" = "1" ]; then
  PID=""
elif [ "${CJGUI_NEGATIVE_NO_START:-0}" != "1" ]; then
  # A1 §5：闸门命令经启动参数进入应用（应用内唯一测试控制路径）。
  # 普通变体也在显式请求时带上——那时转发必然返回 -1，正好作为
  # 「普通产物没有闸门能力」的行为负控，而不是靠推断。
  AA_GATE_ARGS=""
  if [ "$TEST_GATES" = "1" ]; then
    AA_GATE_ARGS="--pi cjguiTestGateFlushHoldMs $GATE_HOLD_MS --pi cjguiTestGateFlushHoldCount $GATE_HOLD_COUNT"
  elif [ "${CJGUI_TEST_GATE_REQUEST_ON_NORMAL:-0}" = "1" ]; then
    AA_GATE_ARGS="--pi cjguiTestGateFlushHoldMs $GATE_HOLD_MS --pi cjguiTestGateFlushHoldCount 1"
  fi
  echo "  aa start 附加参数: ${AA_GATE_ARGS:-<无>}"
  # shellcheck disable=SC2086
  "$HDC" shell "aa force-stop $CJGUI_APP_BUNDLE; aa start -a $CJGUI_APP_ABILITY -b $CJGUI_APP_BUNDLE $AA_GATE_ARGS"
  sleep 8
  PID="$("$HDC" shell "pidof $CJGUI_APP_BUNDLE" 2>/dev/null | tr -d '\r' | head -1)"
  echo "本轮应用 PID=${PID:-未取到}"
  echo "pid=${PID:-unknown}" > "$RUN_DIR/pid_$RUN_ID.txt"
else
  echo "负对照：不启动新实例（预期启动断言失败）"
  "$HDC" shell "aa force-stop $CJGUI_APP_BUNDLE" >/dev/null 2>&1 || true
  sleep 2
fi

echo "== 5/7 本轮日志与启动断言 =="
"$HDC" shell "hilog -x 2>/dev/null | grep -aE 'CjguiHost|CjguiApp|CjguiCore|CjguiRenderer|CjguiTransport'" \
  > "$RUN_DIR/runlog_$RUN_ID.txt" || true
tail -40 "$RUN_DIR/runlog_$RUN_ID.txt" || true

ASSERT_LOG="$RUN_DIR/startup_assert_$RUN_ID.txt"
echo "$BUILD_VARIANT" > "$RUN_DIR/variant_$RUN_ID.txt"
# E 返工：断言函数逐项收集失败。旧写法 `{ f1; f2; } || ASSERT_FAILED=1` 只看
# 最后一条命令的退出码——f1 失败会被 f2 成功覆盖（掩蔽）。现在每个断言
# 单独落账，任一失败都进 ASSERT_FAILED。
ASSERT_FAILURES=0
{
  echo "run_id=$RUN_ID"
  echo "hap_sha256=$HAP_SHA"
  echo "build_variant=$BUILD_VARIANT"
  echo "log_cleared=$LOG_CLEARED"
  echo "launch_pid=${PID:-unknown}"
  echo "launch_id=$LAUNCH_ID"
  echo "launch_ts=$LAUNCH_TS"
  if [ "$STALE_LOG_MODE" = "1" ]; then
    assert_started "$RUN_DIR/runlog_$RUN_ID.txt" "1" || ASSERT_FAILURES=1
  else
    assert_started "$RUN_DIR/runlog_$RUN_ID.txt" "${PID:-}" || ASSERT_FAILURES=1
  fi
  assert_variant "$RUN_DIR/runlog_$RUN_ID.txt" || ASSERT_FAILURES=1
} > "$ASSERT_LOG" 2>&1
if [ "$ASSERT_FAILURES" != "0" ]; then
  ASSERT_FAILED=1
fi
cat "$ASSERT_LOG"

if [ "${ASSERT_FAILED:-0}" = "1" ]; then
  if [ "${CJGUI_NEGATIVE_NO_START:-0}" = "1" ]; then
    echo "NEGATIVE-CONTROL OK：未启动实例时启动断言按预期失败"
    exit 0
  fi
  if [ "$STALE_LOG_MODE" = "1" ]; then
    echo "NEGATIVE-CONTROL OK：旧实例 marker 因 PID 绑定不符被拒绝"
    exit 0
  fi
  echo "PRODUCT-FAIL 启动断言失败（本轮真的没有跑起来）"
  exit 1
fi

if [ "${CJGUI_NEGATIVE_NO_START:-0}" = "1" ]; then
  echo "NEGATIVE-CONTROL FAIL：未启动却断言通过（闸门无效）"
  exit 1
fi

echo "== 6/7 源码清单（最终产物身份）=="
bash "$HERE/source_manifest.sh" "$LAB" "$RUN_DIR/source_manifest_$RUN_ID.txt"

echo "== 7/7 完成。run_dir=$RUN_DIR"
