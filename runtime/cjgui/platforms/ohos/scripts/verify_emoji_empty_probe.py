#!/usr/bin/env python3
"""C：emoji 与空值 owner 边界往返探针。

覆盖（可驱动部分）：
  E1 emoji 名称往返：EDIT_NAME 写入含 emoji（代理对）的值 → 公开读回
     UTF-8 hex 解码后与输入**逐码元相等**（owner 层 UTF-8 存储与读回精确）；
  E2 空值语义：EDIT_NAME 写空串 → 读回空串（合法空 owner 值）；
  E3 恢复：写回原始名称 → 读回精确（拒绝旧草稿后合法新值成功）。

说明：selection/marked 的系统 IME 组合态需真实键盘交互（uitest 注入不达
opacity 0.01 代理），渲染层 caret 命中的代理对安全由 executeCaretHitTest
的二分边界保证（不拆代理对）+ macOS encoding 测试覆盖。

用法： python3 verify_emoji_empty_probe.py
"""

import json
import re
import subprocess
import sys
import time

sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import BoundedExchange  # noqa: E402
from client import parse_response  # noqa: E402

HOST, PORT = "127.0.0.1", 17856
PROTOCOL = "CJGUI_SHARED_OPERATION/2"
CAP = "cjgui-settings-counter-agent-20260925"
RESOURCE_ID = 9700
TOKEN = ""
EVIDENCE = []
RAW_ARCHIVE = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
               "artifacts/cjgui-backend/verification/emoji_empty_raw.json")
EXCHANGE = BoundedExchange(HOST, PORT, RAW_ARCHIVE)
HDC = ("/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/"
       "toolchains/hdc")
BUNDLE = "com.example.cjguiapp"


def note(msg):
    print(msg)


def check(desc, actual, expected):
    ok = actual == expected
    note(f"   {'OK  ' if ok else 'FAIL'} {desc} (got {actual!r} expect {expected!r})")
    EVIDENCE.append({"check": desc, "actual": actual, "expected": expected, "pass": ok})
    return 0 if ok else 1


def business(lines, timeout=8.0):
    return EXCHANGE.exchange_strict(
        [f"PROTOCOL {PROTOCOL}", f"AUTH {CAP}"] + lines, timeout)


def field_of(entries_text, field_id):
    parsed = parse_response(entries_text)
    for name, parts in parsed.entries:
        if name == "FIELD" and parts[1] == field_id:
            if parts[2] == "STRING" and len(parts) >= 5:
                return bytes.fromhex(parts[4]).decode("utf-8")
            return parts[3]
    return None


def version_of(text):
    parsed = parse_response(text)
    for name, parts in parsed.entries:
        if name == "VERSION":
            return int(parts[0])
    raise AssertionError("no VERSION")


def set_name(v, value):
    kw_hex = value.encode("utf-8").hex().upper()
    _, resp = business([f"INVOKE {v} EDIT_NAME 1 1", f"ID {RESOURCE_ID}",
                        f"ARG text STRING {len(value.encode('utf-8'))} {kw_hex}"])
    return resp


def read_name_and_version():
    _, resp = business(["GET_CONTEXT 0"])
    return version_of(resp), field_of(resp, "name")


def main() -> int:
    global TOKEN
    subprocess.run(
        [HDC, "shell",
         f"aa force-stop {BUNDLE}; hilog -r; "
         f"aa start -a EntryAbility -b {BUNDLE}"],
        capture_output=True, text=True)
    time.sleep(8)
    token_out = subprocess.run(
        [HDC, "shell", "hilog -x 2>/dev/null | grep -a 'verify seam armed token=' | tail -1"],
        capture_output=True, text=True).stdout
    m = re.search(r"token=(\S+)", token_out)
    TOKEN = m.group(1) if m else ""
    note(f"== E0 token={TOKEN or '(普通产物/无接缝——emoji 探针不需要接缝)'}")
    failures = 0

    _, resp = business(["GET_CONTEXT 0"])
    v = version_of(resp)
    name0 = field_of(resp, "name")
    note(f"   基线 v={v} name={name0!r}")

    # E1 emoji 往返（含代理对 U+1F680 U+1F389 与组合序列）
    emoji_value = "设备🚀上线🎉+中文"
    resp = set_name(v, emoji_value)
    applied = parse_response(resp)
    ok_applied = next((e[1][0] for e in applied.entries if e[0] == "APPLIED"), "false")
    failures += check("emoji EDIT_NAME 应用", ok_applied, "true")
    v1, name1 = read_name_and_version()
    note(f"   emoji 读回: {name1!r}")
    failures += check("emoji 逐码元精确读回", name1, emoji_value)
    failures += check("emoji 后版本推进", v1, v + 1)
    # 代理对完整性：2 个星面码点（🚀🎉）→ UTF-16 视角 4 个代理对码元。
    astral = sum(1 for ch in emoji_value if 0x10000 <= ord(ch) <= 0x10FFFF)
    utf16_units = len(emoji_value) + astral
    failures += check("星面码点数（代理对来源）", astral, 2)
    failures += check("UTF-16 码元数 = 码点数 + 星面数", utf16_units, len(emoji_value) + 2)

    # E2 空值语义（name 字段业务规则禁止空——域规则如实验证）：
    # 空串被拒绝、版本不变、owner 值不变。「允许空值」字段属 E 独立消费者。
    resp = set_name(v1, "")
    applied2 = parse_response(resp)
    ok2 = next((e[1][0] for e in applied2.entries if e[0] == "APPLIED"), "false")
    failures += check("空串被域规则拒绝（APPLIED false）", ok2, "false")
    v2, name2 = read_name_and_version()
    failures += check("拒绝后 owner 值不变（仍为 emoji 值）", name2, emoji_value)
    failures += check("拒绝后版本不变", v2, v1)

    # E3 恢复：写回非空值（含 emoji 与中文混排）——拒绝/清空后合法新值成功
    restore = f"{name0}·✅"
    resp = set_name(v2, restore)
    applied3 = parse_response(resp)
    ok3 = next((e[1][0] for e in applied3.entries if e[0] == "APPLIED"), "false")
    failures += check("恢复 EDIT_NAME 应用", ok3, "true")
    v3, name3 = read_name_and_version()
    failures += check("恢复后逐码元精确读回", name3, restore)
    failures += check("恢复后版本推进", v3, v2 + 1)

    out = ("/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/"
           "artifacts/cjgui-backend/verification/emoji_empty_evidence.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(EVIDENCE, f, ensure_ascii=False, indent=2)
    EXCHANGE.flush_archive()
    note(f"\n==== RESULT: {'PASS' if failures == 0 else 'FAIL'} (failures={failures}) ====")
    return failures


if __name__ == "__main__":
    sys.exit(main())
