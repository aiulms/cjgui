#!/usr/bin/env python3
"""探针命令面覆盖核对（离线）。

比对三方：
  A) 探针使用面：verify_surface_lifecycle_probe.py / verify_clipping_probe.py 中
     gate("OP ...") / control_map("OP ...") / stub_direct("OP ...") 使用的 OP；
  B) 传输实现面：ohos_transport_verify.cj 的 case "OP"（直连）与 publish 列表；
  C) 应用执行面：ohos_app.cj executeGateCommand 的 gateName 分支（publish 路径
     必须被 owner 真实执行——「发布不等于执行」的历史缺陷）。
判据：A ⊆ (B 直连 ∪ B 发布)；B 发布 ⊆ C 分支。任何缺口即 FAIL（防止只在
真机首次执行时才暴露的“命令从未存在”类缺陷）。
"""
import re
import sys

BASE = "/Users/jiangxuanyang/Desktop/cangjie"
PROBES = [
    f"{BASE}/runtime/cjgui/platforms/ohos/scripts/verify_surface_lifecycle_probe.py",
    f"{BASE}/runtime/cjgui/platforms/ohos/scripts/verify_clipping_probe.py",
]
TRANSPORT = f"{BASE}/runtime/cjgui/platforms/ohos/transport/verify/ohos_transport_verify.cj"
APP = f"{BASE}/labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj"

OP_USED_RE = re.compile(r'(?:gate|control_map|stub_direct)\("([A-Z_]+[A-Z0-9_]*)(?:\s[^"]*)?"')
CASE_RE = re.compile(r'case\s+"([A-Z_]+[A-Z0-9_]*)"')
APP_RE = re.compile(r'gateName(?:\.startsWith\()?\s*==?\s*"([A-Z_]+)"|gateName\.startsWith\("([A-Z_]+) ')

def used_ops():
    ops = set()
    for p in PROBES:
        with open(p, encoding="utf-8") as f:
            for m in OP_USED_RE.finditer(f.read()):
                ops.add(m.group(1))
    return ops

def transport_ops():
    direct, pub = set(), set()
    with open(TRANSPORT, encoding="utf-8") as f:
        text = f.read()
    # 直连 case（含 STUB_/GATE_ 直读）
    for m in CASE_RE.finditer(text):
        direct.add(m.group(1))
    # publish 列表：包含 STUB_ARM/HOLD/SESSION/GATE_* 的 |> 链
    for line in text.splitlines():
        if '=>' in line or '|' in line:
            for m in re.finditer(r'"([A-Z_]+[A-Z0-9_]*)"', line):
                pub.add(m.group(1))
    return direct, pub

def app_branches():
    ops = set()
    with open(APP, encoding="utf-8") as f:
        text = f.read()
    for m in re.finditer(r'gateName(?:\.startsWith\()?\s*==\s*"([A-Z0-9_]+)"', text):
        ops.add(m.group(1))
    for m in re.finditer(r'gateName\.startsWith\("([A-Z0-9_]+) "\)', text):
        ops.add(m.group(1) + " ")
    return ops

def main() -> int:
    used = used_ops()
    direct, pub = transport_ops()
    app = app_branches()
    # 归一：startsWith 前缀与精确名
    app_norm = {o.rstrip() for o in app}
    # 探针使用面须有实现（直连或发布）
    # 故意未知命令（NEG1 负控）不算缺口。
    intentional_unknown = {"GATE_NO_SUCH_OP_NEG1"}
    missing_impl = sorted(op for op in used
                          if op not in direct and op not in pub
                          and op not in intentional_unknown)
    # 发布面须有 owner 执行分支（前缀或精确）
    missing_exec = []
    for op in sorted(pub):
        if op in direct:
            continue
        if op in app_norm or any(op.startswith(a + "_") for a in app_norm):
            continue
        missing_exec.append(op)
    print(f"探针使用 OP 数: {len(used)}；传输直连: {len(direct)}；发布: {len(pub)}；应用分支: {len(app_norm)}")
    ok = True
    if missing_impl:
        print("FAIL 探针使用但无实现:", missing_impl)
        ok = False
    else:
        print("OK   探针全部 OP 有传输实现（直连或发布）")
    if missing_exec:
        print("FAIL 发布但无 owner 执行分支:", missing_exec)
        ok = False
    else:
        print("OK   发布 OP 全部有 owner 执行分支（发布=执行）")
    # 渲染分支专用 OP 的领出（真机首次执行清单）
    render_only = sorted(op for op in used
                         if op in {"GATE_HOLD_PERMIT_8000", "GATE_HOLD_CREATE_8000",
                                   "GATE_HOLD_CREATE_RET_8000", "GATE_HOLD_DRAW_8000",
                                   "GATE_HOLD_ADMIT_8000", "GATE_SIM_RETIRED",
                                   "GATE_SIM_CREATED", "GATE_DEQUEUE_HOLD_30000",
                                   "GATE_ACCEPT_THROW", "GATE_ROLLBACK_THROW",
                                   "GATE_THROW_CLEAR", "GATE_REJECT_NEXT",
                                   "GATE_FAIL_ACK_1", "GATE_A2_STATS"})
    print("真机首次执行面（渲染/交互分支）:", ", ".join(render_only) if render_only else "（无）")
    print("RESULT:", "PASS" if ok else "FAIL")
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
