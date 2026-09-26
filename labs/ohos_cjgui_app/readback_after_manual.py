#!/usr/bin/env python3
"""人工核验后的一键读回归档（执行 AI 或用户均可运行）。"""
import sys, json
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/scripts")
sys.path.insert(0, "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/shared_operation_core")
from ohos_transport_probe_lib import BoundedExchange
from client import parse_response
EX = BoundedExchange("127.0.0.1", 17856, "")
_, resp = EX.exchange_strict(["PROTOCOL CJGUI_SHARED_OPERATION/2",
    "AUTH cjgui-settings-counter-agent-20260925", "GET_CONTEXT 0"], 8)
p = parse_response(resp)
ver = [e[1][0] for e in p.entries if e[0] == "VERSION"][0]
name = ""
for e in p.entries:
    if e[0] == "FIELD" and e[1][1] == "name" and e[1][2] == "STRING":
        name = bytes.fromhex(e[1][4]).decode("utf-8") if len(e[1]) >= 5 and e[1][4] != "-" else ""
print(f"owner name = {name!r}")
print(f"owner version = {ver}")
out = "/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_cangjie_smoke/artifacts/cjgui-backend/verification/selection_manual_evidence.md"
# 追加而非覆盖：证据主文件已由执行者归档，重复运行不得销毁既有记录。
with open(out, "a", encoding="utf-8") as f:
    f.write(f"\n## 读回追加（{name!r} v={ver}）\n\n")
    f.write(f"owner 公开读回如上（逐码元由用户比对其键入内容）。\n")
print(f"已追加读回到 {out}")
