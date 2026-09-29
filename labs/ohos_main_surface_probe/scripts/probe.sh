#!/usr/bin/env bash
# 主窗口 Surface 探针：构建 / 安装 / 启动 / 取证。
#
# 独立实验，不依赖 runtime/cjgui 的构建入口，也不改写任何现有 HAP。
# 用法：
#   bash scripts/probe.sh build
#   bash scripts/probe.sh install
#   bash scripts/probe.sh start [probeLevel] [frame]
#   bash scripts/probe.sh logs
#   bash scripts/probe.sh shot <name>
#   bash scripts/probe.sh all [probeLevel] [frame]
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
LAB="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$LAB/../.." && pwd)"

DEVECO_STUDIO_HOME="${DEVECO_STUDIO_HOME:-/Applications/DevEco-Studio.app}"
HDC="${HDC:-$DEVECO_STUDIO_HOME/Contents/sdk/default/openharmony/toolchains/hdc}"
DEVECO_CLI="${DEVECO_CLI:-$HOME/.local/bin/devecocli}"

BUNDLE="com.example.ohosmainsurfaceprobe"
ABILITY="EntryAbility"
TAG_FILTER='MainSurfaceProbe'

ART_ROOT="$LAB/artifacts/run"
RUN_ID="${RUN_ID:-run_$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="$ART_ROOT/$RUN_ID"
HAP="$LAB/entry/build/default/outputs/default/entry-default-unsigned.hap"

mkdir -p "$RUN_DIR"

log() { echo "[probe] $*"; }

cmd_build() {
  log "build (hvigor/devecocli)"
  ( cd "$LAB" && "$DEVECO_CLI" build --build-mode debug ) 2>&1 | tee "$RUN_DIR/build_$RUN_ID.log" | tail -25
  if [ ! -f "$HAP" ]; then
    log "FAIL: 未生成 HAP: $HAP"
    return 1
  fi
  HAP_SHA="$(shasum -a 256 "$HAP" | awk '{print $1}')"
  HAP_SIZE="$(stat -f '%z' "$HAP")"
  echo "$HAP_SHA" > "$RUN_DIR/hap_sha256.txt"
  echo "hap=$HAP sha256=$HAP_SHA bytes=$HAP_SIZE" | tee "$RUN_DIR/hap_identity.txt"
}

cmd_install() {
  "$HDC" list targets | tee "$RUN_DIR/targets.txt"
  "$HDC" install -r "$HAP" 2>&1 | tee "$RUN_DIR/install.txt"
}

cmd_start() {
  local level="${1:-0}"
  local frame="${2:--1}"
  local cand="${3:-2}"
  local extra=""
  if [ "$level" != "-1" ]; then extra="--pi probeLevel $level"; fi
  if [ "$frame" != "-1" ]; then extra="$extra --pi frame $frame"; fi
  extra="$extra --pi probeCandidate $cand"
  if [ -n "${ROTATE:-}" ]; then extra="$extra --pi rotate $ROTATE"; fi
  if [ -n "${NO_ARKTS_TRANSPARENCY:-}" ]; then extra="$extra --pi arktsTransparency 0"; fi
  "$HDC" shell "hilog -r" >/dev/null 2>&1
  "$HDC" shell "aa force-stop $BUNDLE" >/dev/null 2>&1
  sleep 1
  log "aa start level=$level frame=$frame candidate=$cand"
  # shellcheck disable=SC2086
  "$HDC" shell "aa start -a $ABILITY -b $BUNDLE $extra" 2>&1 | tee "$RUN_DIR/aa_start.txt"
  sleep 6
  local pid
  pid="$("$HDC" shell "pidof $BUNDLE" 2>/dev/null | tr -d '\r' | head -1)"
  log "pid=$pid"
  echo "$pid" > "$RUN_DIR/pid.txt"
}

cmd_logs() {
  local out="$RUN_DIR/hilog_$RUN_ID.txt"
  "$HDC" shell "hilog -x 2>/dev/null | grep -a '$TAG_FILTER'" > "$out" || true
  log "logs -> $out ($(wc -l < "$out" | tr -d ' ') lines)"
  tail -40 "$out"
}

cmd_shot() {
  local name="${1:-shot}"
  local dev="/data/local/tmp/probe_${name}.jpeg"
  "$HDC" shell "snapshot_display -f $dev" >/dev/null 2>&1
  "$HDC" file recv "$dev" "$RUN_DIR/${name}.jpeg" >/dev/null 2>&1
  log "screenshot -> $RUN_DIR/${name}.jpeg"
  ls -l "$RUN_DIR/${name}.jpeg" 2>/dev/null
}

cmd_all() {
  local level="${1:-0}"
  log "RUN_DIR=$RUN_DIR"
  cmd_install || return 1
  cmd_start "$level" "${2:--1}" || return 1
  sleep 3
  cmd_logs
  cmd_shot "l${level}"
}

case "${1:-}" in
  build)   cmd_build ;;
  install) cmd_install ;;
  start)   shift; cmd_start "$@" ;;
  logs)    cmd_logs ;;
  shot)    shift; cmd_shot "$@" ;;
  all)     shift; cmd_all "$@" ;;
  *) echo "用法: $0 {build|install|start [level] [frame]|logs|shot <name>|all [level] [frame]}"; exit 2 ;;
esac
