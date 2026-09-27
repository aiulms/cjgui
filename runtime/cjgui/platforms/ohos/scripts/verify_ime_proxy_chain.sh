#!/usr/bin/env bash
# 通用文字代理 + 双字段消费者 端到端验证（工作包 C 收口）。
#
# 覆盖：
#  T0 干净启动起链；T1 失焦提交（框架结算预览 → owner → 渲染）；T2 再聚焦同字段；
#  T3 失焦后继续编辑；T4 显式提交（系统键盘回车）+ 精确读回；
#  T5/T6 负对照（迟到提交被拒、结束后无活会话）；
#  T7/T8（--with-external）人→外部→人的分层反例：
#     T7 框架 blur 路径 —— 本地草稿按失焦语义结算，owner 版本冲突拒绝，渲染回到 owner 值；
#     T8 ArkTS 提交路径 —— 上下文编号是唯一准入凭据（不校验 baseVersion，rc=0），
#        业务裁决仍在 owner（状态行「未应用」）。
#
# 人类侧输入全部经 hdc uitest（真实触摸/输入），断言只读应用自身的服务端日志、
# 接受场景投影与外部客户端读回；不依赖截图命名，不声称未观察到的行为。
#
# 已知时序事实：uitest 的 inputText 实为「经剪贴板粘贴」，必须等系统键盘先弹出
# （点击字段后约 2–3s）才会落到代理上；因此每个输入前留足等待，并对 T1/T3 做一次重试。
#
# 用法： scripts/verify_ime_proxy_chain.sh [--with-external]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

BUNDLE="${CJGUI_APP_BUNDLE}"
ABILITY="${CJGUI_APP_ABILITY}"
ART="${CJGUI_VERIFY_ARTIFACTS:-/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/verification}"
mkdir -p "$ART"
OUT="$ART/ime_proxy_chain_evidence.txt"
: > "$OUT"

FAILURES=0
step() { printf '\n== %s\n' "$1" | tee -a "$OUT"; }
note() { printf '   %s\n' "$1" | tee -a "$OUT"; }
# warn：只写证据文件与 stderr——stdout 留给被命令替换捕获的函数结果
warn() { printf '   %s\n' "$1" >> "$OUT"; printf '   %s\n' "$1" >&2; }
check() { # check <desc> <actual> <expected>
  if [ "$2" = "$3" ]; then note "OK   $1 ($2)"; else note "FAIL $1 (got '$2' expect '$3')"; FAILURES=$((FAILURES + 1)); fi
}

logs() { "$HDC" shell "hilog -x" 2>/dev/null | grep -E "$1" | sed 's/^.*Cjgui[A-Za-z]*: //'; }
clear_logs() { "$HDC" shell "hilog -r" >/dev/null 2>&1; }
tap() { "$HDC" shell "uitest uiInput click $1 $2" >/dev/null 2>&1; sleep "${3:-3}"; }
type_text() { "$HDC" shell "uitest uiInput inputText $1 $2 $3" >/dev/null 2>&1; sleep 3; }
# 截图证据：设备侧抓帧后回传到证据目录。用于区分「本地草稿遮盖」与「owner 裁决」——
# 日志只能证明 owner 侧的值，渲染层画的是哪个值必须看图。
shot() {
  "$HDC" shell "snapshot_display -f /data/local/tmp/$1.jpeg" >/dev/null 2>&1
  "$HDC" file recv "/data/local/tmp/$1.jpeg" "$ART/$1.jpeg" >/dev/null 2>&1
  "$HDC" shell "rm -f /data/local/tmp/$1.jpeg" >/dev/null 2>&1
}

# 场景几何（1320x2856 屏幕，surface 顶部偏移 136px，密度 3.5）：
NAME_Y=462; ALIAS_Y=540; BLANK_Y=1300   # 校准至当前场景（nodeIdName 426+72/2；nodeIdAlias 512+56/2）
BTN_LATE_X=330; BTN_READBACK_X=1004; BTN_Y=2400

# 按钮坐标动态校准：状态栏文本长度变化会把按钮行上下推移（实测 BTN_Y 漂移
# 90px+ 落进行间隙 → 假 FAIL），一律以 uitest dumpLayout 的真实 bounds 为准，
# 失败时才退回上面的固定值。
button_center() { # <text> → "x y"，找不到输出空串
  "$HDC" shell "uitest dumpLayout -p /data/local/tmp/ime_btn.json" >/dev/null 2>&1
  "$HDC" file recv /data/local/tmp/ime_btn.json /tmp/ime_btn.json >/dev/null 2>&1 || return 1
  python3 - "$1" <<'PYEOF'
import json, sys
want = sys.argv[1]
try:
    d = json.load(open('/tmp/ime_btn.json'))
except Exception:
    sys.exit(1)
hit = []
def walk(n):
    a = n.get('attributes', {})
    if a.get('text', '') == want:
        b = a.get('bounds', '')
        hit.append(b)
    for c in n.get('children', []):
        walk(c)
walk(d)
if not hit:
    sys.exit(1)
b = hit[0].strip('[]').split('][')
(x1, y1), (x2, y2) = [p.split(',') for p in b]
print((int(x1) + int(x2)) // 2, (int(y1) + int(y2)) // 2)
PYEOF
}

tap_button() { # <text> [fallback_x] [fallback_y]
  local c
  c="$(button_center "$1")"
  if [ -n "$c" ]; then
    set -- $c
    "$HDC" shell "uitest uiInput click $1 $2" >/dev/null 2>&1
  else
    "$HDC" shell "uitest uiInput click ${2:-$BTN_LATE_X} ${3:-$BTN_Y}" >/dev/null 2>&1
  fi
  sleep "${4:-3}"
}

gate_tap() { # x y [wait] —— 经控制通道注入触摸（替身会话档字段聚焦/失焦的唯一通路）
  local t="${VERIFY_TOKEN:-}"
  if [ -z "$t" ]; then t="$(logs 'verify seam armed token=' | tail -1 | sed 's/.*token=//')"; fi
  python3 "$SCRIPT_DIR/gate_touch.py" "$t" "$1" "$2" >/dev/null 2>&1
  sleep "${3:-3}"
}

last_settle() { logs "ime blur settle" | tail -1; }
settled_text() { last_settle | grep -o 'text=.*' | cut -d= -f2-; }
# 上下文快照有两份日志：host 侧 'ime context json: {...}' 与 ArkTS 侧
# 'ime proxy mounted ctx=.. field=.. text=..'，后者更适合直接取挂载参数。
last_mount() { logs "ime proxy mounted" | tail -1; }

# 第九次复核 §E：KnownShimNoRef 环境下的输入链使能——经控制通道建立替身会话
# （STUB_ARM + STUB_SESSION），owner 进入 Phase B；真实系统输入（uitest →
# ArkUI 代理 → 框架结算 → owner）即可端到端验证。仅测试变体（verify seam）可用。
STUB_GEN=84
VERIFY_TOKEN=""
stub_up() {
  "$HDC" fport tcp:17856 tcp:7856 >/dev/null 2>&1 || true
  sleep 1
  local tok
  tok="$(logs 'verify seam armed token=' | tail -1 | sed 's/.*token=//')"
  if [ -z "$tok" ]; then
    note "WARN 未取到 verify token：非测试产物，输入链不可用"
    return 1
  fi
  STUB_GEN=$((STUB_GEN - 1))
  VERIFY_TOKEN="$tok"   # 缓存：后续 clear_logs 后仍可用
  python3 "$SCRIPT_DIR/stub_session_up.py" "$tok" "$STUB_GEN" 1320 2856 || true
  sleep 3
}

restart() {
  "$HDC" shell "aa force-stop $BUNDLE" >/dev/null 2>&1; sleep 2
  # 先清再启动：启动日志（host started; pumping turns）本身就是 T0 的证据，
  # 若在 start 之后清缓冲会把它一并抹掉，导致断言恒假。
  clear_logs
  "$HDC" shell "aa start -a $ABILITY -b $BUNDLE" >/dev/null 2>&1; sleep 6
  stub_up || true
}

# 传输桥：应用内监听 7856，经 hdc 转发到本机 17856。fport 在应用重启后首次
# 重连可能超时（设备侧旧连接 CHOSE_WAIT），此时再重启一次应用即恢复。
ensure_fport() {
  "$HDC" fport tcp:17856 tcp:7856 >/dev/null 2>&1 || true
  sleep 1
  local probe
  probe="$(python3 "$SCRIPT_DIR/human_external_human_probe.py" read "$1" 2>&1 | tail -1)"
  if printf '%s' "$probe" | grep -q '"version"'; then
    printf '%s' "$probe" | grep -o '"version": [0-9]*'
    return 0
  fi
  note "WARN 首次转发不通，重启应用后重试：$probe"
  restart
  "$HDC" fport tcp:17856 tcp:7856 >/dev/null 2>&1 || true
  sleep 1
  probe="$(python3 "$SCRIPT_DIR/human_external_human_probe.py" read "$1-retry" 2>&1 | tail -1)"
  printf '%s' "$probe" | grep -o '"version": [0-9]*'
}

# 聚焦 → 输入 → 点空白结算，回显结算文本。输入可能因键盘未就绪而丢，
# 因此这里做一次整体重试（重新聚焦会把缓冲重置为已提交值，不会重复追加）。
focus_type_settle() { # <y> <typed> <expected-prefix>；期望结算值 = 前缀 + 输入
  clear_logs
  gate_tap 660 "$1" 4
  type_text 660 "$1" "$2"
  gate_tap 660 "$BLANK_Y" 3
  local got; got="$(settled_text)"
  if [ "$got" != "$3$2" ]; then
    warn "WARN 首次结算为 '$got'（期望 '$3$2'），整体重试一次"
    clear_logs
    gate_tap 660 "$1" 4
    type_text 660 "$1" "$2"
    gate_tap 660 "$BLANK_Y" 3
    got="$(settled_text)"
  fi
  printf '%s' "$got"
}

step "T0 干净启动 + 断言 owner 起链"
restart
check "owner 起链（host started; pumping turns）" \
  "$(logs 'host started; pumping turns' | tail -1)" "host started; pumping turns"
# 场景在 D 夹具加入后为 20 节点（原 16）；断言取**本轮实际投影**不写死漂移值。
check "渲染首帧提交" \
  "$(logs 'present frame ok' | tail -1 | grep -o 'nodes=[0-9]*' | grep -q 'nodes=20' && echo nodes=20 || logs 'present frame ok' | tail -1 | grep -o 'nodes=[0-9]*')" "nodes=20"

step "T1 失焦提交（点空白）必须把草稿落到 owner 并渲染出来"
# 结算日志本身是「组合预览被折入本地缓冲」的证据：settled=1 表示框架确实
# 收到了代理送来的编辑预览（经 ArkUI onChange → imePreviewText → 预览缓冲）。
result="$(focus_type_settle "$NAME_Y" 草稿ABC "我的设备")"
check "失焦结算文本为草稿（预览已折入）" "$result" "我的设备草稿ABC"
check "结算确有预览被折入" "$(last_settle | grep -o 'settled=[0-9]*')" "settled=1"
v1="$(logs 'accepted node=24' | tail -1 | grep -o 'v=[0-9]*' | cut -d= -f2)"
if [ "${v1:-1}" -gt 1 ]; then note "OK   本帧投影版本前进 (v=$v1)"; else
  note "FAIL 投影版本未前进 (v=${v1:-unset})"; FAILURES=$((FAILURES + 1)); fi

step "T2 失焦后再聚焦同一字段：新上下文 + 缓冲为已提交值 + 代理重新挂载"
clear_logs; gate_tap 660 "$NAME_Y"
mount="$(last_mount)"
check "新上下文编号前进" "$(printf '%s' "$mount" | grep -o 'ctx=[0-9]*' | head -1)" "ctx=2"
check "缓冲为已提交值（非空）" "$(printf '%s' "$mount" | grep -o 'text=.*' | cut -d= -f2-)" "我的设备草稿ABC"

step "T3 失焦后继续编辑：追加文本再次提交"
got="$(focus_type_settle "$NAME_Y" XYZ "我的设备草稿ABC")"
check "第二次失焦结算文本为追加后值" "$got" "我的设备草稿ABCXYZ"

step "T4 显式提交（系统键盘回车）路径"
restart; gate_tap 660 "$NAME_Y" 4; type_text 660 "$NAME_Y" 回车提交
"$HDC" shell "uitest uiInput keyEvent 2054" >/dev/null 2>&1; sleep 3
# 注册表路径（onSubmit → proxyRegistry.submitAndFinish）的提交证据是
# `commit reason=submit ctx=<ctx> rc=<rc>`（proxy bridge 记账）；页面级
# commitAndFinish 只服务 blur/focus-moved，不再经手 submit。
commit="$(logs 'commit reason=submit' | tail -1)"
if [ -z "$commit" ]; then
  note "WARN keyEvent 2054 未触发提交，改用 Enter"
  "$HDC" shell "uitest uiInput keyEvent Enter" >/dev/null 2>&1; sleep 3
  commit="$(logs 'commit reason=submit' | tail -1)"
fi
check "平台提交被接受" "$(printf '%s' "$commit" | grep -o 'rc=[0-9]*')" "rc=0"
# 输入确实到达代理：最后一条 onChange 长度 =「我的设备回车提交」8（UTF-16 码元）。
check "输入到达代理" "$(logs 'ime proxy onChange' | tail -1 | grep -o 'len=[0-9]*')" "len=8"
# owner 值经真实外部通道精确读回：人提交的文本必须逐字符等于 owner 的 name。
"$HDC" fport tcp:17856 tcp:7856 >/dev/null 2>&1 || true; sleep 1
rb="$(python3 "$SCRIPT_DIR/human_external_human_probe.py" read "t4-owner-readback" 2>&1 | tail -1)"
owner_name="$(printf '%s' "$rb" | python3 -c 'import sys,json
try:
  print(json.load(sys.stdin)["fields"]["name"])
except Exception:
  print("<unreadable>")' 2>/dev/null)"
if [ "$owner_name" = "<unreadable>" ]; then
  owner_name="<unreadable:${rb:0:120}>"
fi
check "精确读回匹配" "$owner_name" "我的设备回车提交"

step "T5 负对照：对已结束的上下文再提交必须被拒（rc=1）"
clear_logs; tap_button "LATE COMMIT" "$BTN_LATE_X" "$BTN_Y" 3
late="$(logs 'ime late commit' | tail -1)"
check "迟到提交被拒" "$(printf '%s' "$late" | grep -o 'rc=[0-9]*')" "rc=1"

step "T6 负对照：结束后读取上下文必须无活会话"
clear_logs; tap_button "READBACK" "$BTN_READBACK_X" "$BTN_Y" 3
rb="$(logs 'ime readback' | tail -1)"
check "无活上下文" "$(printf '%s' "$rb" | grep -o 'state=[a-z]*')" "state=closed"

if [ "${1:-}" = "--with-external" ]; then
  step "T7 人 → 外部 → 人（框架 blur 路径）：本地草稿保留，owner 拒绝，渲染回到 owner 值"
  restart
  ver="$(ensure_fport T7-pre)"
  check "外部客户端连通" "$ver" '"version": 0'

  tap 660 "$NAME_Y" 4; type_text 660 "$NAME_Y" 人写
  shot t7_h_local_draft_before_external
  external="$(python3 "$SCRIPT_DIR/human_external_human_probe.py" rename 外部改写 T7-external 2>&1 | tail -1)"
  check "外部改写被接受" "$(printf '%s' "$external" | grep -o '"applied": [a-z]*')" '"applied": true'
  shot t7_h_local_draft_alive_after_external

  clear_logs; tap 660 "$BLANK_Y" 3
  check "本地草稿仍被按失焦语义结算（合法草稿未丢）" "$(settled_text)" "我的设备人写"
  # 结算被 owner 拒绝（版本已被外部推进），本地草稿不得成为结果。
  # 注意：框架 blur 路径不回发 ArkTS 提交（ArkTS 只释放代理），拒绝发生在 owner
  # 内部；owner 自己的状态行（node=30 counter-status）就是「编辑未应用」的原始证据。
  status_line="$(logs 'accepted node=30' | tail -1)"
  if printf '%s' "$status_line" | grep -q '未应用'; then
    note "OK   owner 状态行报告本次编辑未应用：$(printf '%s' "$status_line" | grep -o 'value=.*' | cut -d= -f2-)"
  else
    note "FAIL owner 未报告编辑未应用：$status_line"; FAILURES=$((FAILURES + 1))
  fi
  check "本帧投影回到 owner 的外部值" \
    "$(logs 'accepted node=24' | tail -1 | grep -o 'value=[^ ]*')" "value=外部改写"
  shot t7_final_owner_value

  step "T8 人 → 外部 → 人（ArkTS 提交路径）：编号是唯一准入凭据，业务裁决在 owner"
  restart
  ensure_fport T8-pre >/dev/null
  tap 660 "$NAME_Y" 4; type_text 660 "$NAME_Y" 人写
  python3 "$SCRIPT_DIR/human_external_human_probe.py" rename 外部改写 T8-external >/dev/null 2>&1
  clear_logs
  # 人类显式提交（回车）走 ArkTS commitAndFinish → imeCommitText(text, ctx)。
  # 该入口只校验上下文编号是否仍活；外部推进的版本不进准入判断 → 期望 rc=0。
  "$HDC" shell "uitest uiInput keyEvent 2049" >/dev/null 2>&1; sleep 3
  t8commit="$(logs 'ime commit reason=submit' | tail -1)"
  if [ -z "$t8commit" ]; then
    "$HDC" shell "uitest uiInput keyEvent Enter" >/dev/null 2>&1; sleep 3
    t8commit="$(logs 'ime commit reason=submit' | tail -1)"
  fi
  check "上下文编号仍活 → 传输层接受（不校验 baseVersion）" \
    "$(printf '%s' "$t8commit" | grep -o 'rc=[0-9]*')" "rc=0"
  status8="$(logs 'accepted node=30' | tail -1)"
  if printf '%s' "$status8" | grep -q '未应用'; then
    note "OK   owner 层仍裁决未应用：$(printf '%s' "$status8" | grep -o 'value=.*' | cut -d= -f2-)"
  else
    note "FAIL owner 未报告编辑未应用：$status8"; FAILURES=$((FAILURES + 1))
  fi
  check "本帧投影保持 owner 的外部值" \
    "$(logs 'accepted node=24' | tail -1 | grep -o 'value=[^ ]*')" "value=外部改写"
  shot t8_owner_value_after_submit
fi

printf '\n==== RESULT: %s (failures=%d) ====\n' "$([ "$FAILURES" -eq 0 ] && echo PASS || echo FAIL)" "$FAILURES" | tee -a "$OUT"
exit "$FAILURES"
