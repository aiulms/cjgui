#!/usr/bin/env python3
"""`verify_r1_pre_permission_replay.py` 的离线判别力反例（无设备、无生产写入）。

目的：在跑设备之前，用合成 hilog 证明该驱动的**归属与 Flush 判据**在退化时会被
拒绝，而不是带着已知错误的判据试跑。原函数从生产文件**原样提取**（AST），设备、
时间与子进程边界是显式内存替身；本文件不导入设备、不修改生产语义。

覆盖的判据（每条都有 GREEN 正控 + 变异 RED）：
  1. 日志扫描按**本轮 PID** 归属（同 session、别的 PID 的票不计）；
  2. 日志扫描按**本轮 session** 归属（同 PID、别的 session 的票不计）；
  3. `accepted-swap` **不得**冒充真实 Flush 入口（`flush hold enter/exit`）；
  4. `decide_held_ticket`（窗口逐票）：集合非空、每票恰一行、每票终态 `(7,4)`、每票未 Flush；
  5. `partition_hold_window` / `remint_within_bound`：W/U 分割与重铸计数上界；
  6. `ensure_forward` 归属：子进程退出码非 0 时**不得**取得清理权；读列表 rc≠0 不
     认领；无 `Forwardport result:OK` 回执不认领；复查必须**同一行**
     `(target, tcp:PORT, tcp:REMOTE)` 精确相等——跨行（28865→7999 配用户 7856→7856）、
     同端口异 target 一律具名拒绝；`release_forward` 只在清理前重验仍匹配时才 rm，
     映射变化即跳过且零 `rm`（用户自有映射保留）；
  7. `trigger_present` 失败必须具名传播，不得吞异常当成功；
  8. `decide_t2_ordering`（真实 T2 顺序，round7-B）：判据**只**比四个真实边界序号
     `enter(T1) < enqueue(T2) < exit(T1) <= claim(T2)`（同一个进程内单调原子计数器，
     跨 C++/仓颉同域）；hilog 行序与毫秒时间戳都不参与。T1 按「入队那一刻仍在等待」
     配对，多于一张即歧义。业务终态唯一且与回包版本同源；缺任一真实边界行一律具名
     未验，绝不因 CONTROL 可响应或"没有 Flush"放行。

退出码 0 = 全部 GREEN 正控通过且每条 RED 变异都被检出。
"""
import ast
import math
import sys
from pathlib import Path
from types import SimpleNamespace

ROOT = Path(__file__).resolve().parents[5]
TOOL = ROOT / "runtime/cjgui/platforms/ohos/scripts/verify_r1_pre_permission_replay.py"

THIS_PID = "27682"
FOREIGN_PID = "9876"      # 别的实例：同 session、别的 PID（只应由 PID 归属排除）
THIS_SESSION = "1"
FOREIGN_SESSION = "99"    # 别的会话：同 PID、别的 session（只应由 session 归属排除）

RESULTS = []


def note(msg):
    print(msg, flush=True)


def record(name, ok, detail=""):
    RESULTS.append((name, bool(ok)))
    note(f"   {'OK  ' if ok else 'FAIL'} {name} {detail}")
    return ok


# ---- 合成 hilog（含本轮 + 两类外来行） ----------------------------------------
LOGS = {
    "verify seam armed token=": "\n".join([
        "10-03 01:22:27.656 27682 27860 I A00000/CjguiTransportVerify: verify seam armed token=t392fb72",
        "10-03 01:22:27.900 9876 9877 I A00000/CjguiTransportVerify: verify seam armed token=tFOREIGN",
    ]),
    "image-lease stage=accepted-swap": "\n".join([
        "10-03 01:22:31.738 27682 27860 I A00000/CjguiRenderer: image-lease stage=accepted-swap seq=1 session=1 ticket=1 cause=commit oldProjection=0 newProjection=1 rows=0 omitted=0 wrapped=0",
        "10-03 01:22:31.777 27682 27860 I A00000/CjguiRenderer: image-lease stage=accepted-swap seq=2 session=1 ticket=2 cause=commit oldProjection=1 newProjection=2 rows=0 omitted=0 wrapped=0",
        "10-03 01:22:31.999 9876 9877 I A00000/CjguiRenderer: image-lease stage=accepted-swap seq=1 session=1 ticket=456 cause=commit oldProjection=0 newProjection=1 rows=0 omitted=0 wrapped=0",
        "10-03 01:22:32.100 27682 27860 I A00000/CjguiRenderer: image-lease stage=accepted-swap seq=3 session=99 ticket=777 cause=commit oldProjection=0 newProjection=1 rows=0 omitted=0 wrapped=0",
    ]),
    "flush hold ": "\n".join([
        "10-03 01:22:31.763 27682 27862 W A00000/CjguiRenderer: flush hold enter gen=1 session=1 ticket=2",
        "10-03 01:22:31.764 27682 27862 W A00000/CjguiRenderer: flush hold exit gen=1 session=1 ticket=2",
        "10-03 01:22:31.900 9876 9877 W A00000/CjguiRenderer: flush hold enter gen=1 session=1 ticket=456",
        "10-03 01:22:32.200 27682 27862 W A00000/CjguiRenderer: flush hold enter gen=1 session=99 ticket=777",
    ]),
    "present terminal ": "\n".join([
        "10-03 01:22:31.778 27682 27860 I A00000/CjguiRenderer: present terminal session=1 ticket=2 status=0 phase=3",
        "10-03 01:22:31.950 9876 9877 I A00000/CjguiRenderer: present terminal session=1 ticket=456 status=0 phase=3",
        "10-03 01:22:32.300 27682 27860 I A00000/CjguiRenderer: present terminal session=99 ticket=777 status=0 phase=3",
    ]),
    "configure refused: pending ticket=": "\n".join([
        "10-03 01:22:40.000 27682 27860 W A00000/CjguiRenderer: configure refused: pending ticket=9 settled=0",
        "10-03 01:22:40.100 9876 9877 W A00000/CjguiRenderer: configure refused: pending ticket=456 settled=0",
    ]),
}


def fake_hdc(*args):
    cmd = args[-1] if args else ""
    for pat, text in LOGS.items():
        if f"grep -a '{pat}'" in cmd:
            return text
    return ""


def load(names, scope, mutation=None, assigns=()):
    src = TOOL.read_text()
    if mutation is not None:
        old, new = mutation
        assert src.count(old) == 1, f"变异锚点不唯一/缺失: {old!r} ({src.count(old)})"
        src = src.replace(old, new)
    tree = ast.parse(src)
    nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
    assert {n.name for n in nodes} == set(names), (names, {n.name for n in nodes})
    # 模块级常量（如 MAP_ROW）也逐字从生产提取：改名/改判据即缺锚点，harness 报错。
    for name in assigns:
        found = [n for n in tree.body if isinstance(n, ast.Assign)
                 and any(isinstance(t, ast.Name) and t.id == name for t in n.targets)]
        assert len(found) == 1, f"expected one production constant {name}, found {len(found)}"
        nodes.extend(found)
    exec(compile(ast.Module(body=nodes, type_ignores=[]), str(TOOL), "exec"), scope)
    return scope


def scan_scope(mutation=None):
    import re
    scope = {"re": re, "hdc": fake_hdc, "BOUND_PID": THIS_PID, "BOUND_SESSION": THIS_SESSION}
    return load({"scoped_lines", "app_pid", "read_token", "committed_tickets",
                 "flush_boundary_tickets", "ticket_terminals", "refused_tickets"},
                scope, mutation)


def expect_scan(scope, tag):
    """GREEN：三类扫描都必须只认本轮 PID/session 的票（1/2），外来 456/777 一律不计。"""
    ok = True
    ok &= record(f"{tag}: accepted-swap 只含本轮票", scope["committed_tickets"]() == {1, 2},
                 f"got {sorted(scope['committed_tickets']())}")
    ok &= record(f"{tag}: Flush 边界只含本轮票", scope["flush_boundary_tickets"]() == ({2}, {2}),
                 f"got {scope['flush_boundary_tickets']()}")
    ok &= record(f"{tag}: 终态只含本轮票（按行保留）",
                 scope["ticket_terminals"]() == {2: [(0, 3)]},
                 f"got {scope['ticket_terminals']()}")
    ok &= record(f"{tag}: 具名拒绝只含本轮票", scope["refused_tickets"]() == {"9"},
                 f"got {sorted(scope['refused_tickets']())}")
    ok &= record(f"{tag}: token 取自本轮 PID", scope["read_token"]() == "t392fb72",
                 f"got {scope['read_token']()!r}")
    return ok


def expect_decide(scope, tag):
    """GREEN：许可前 hold 窗口的逐票判据（多票、逐票 (7,4)、逐票未 Flush）。"""
    ok = True
    good = {4: [(7, 4)], 5: [(7, 4)]}
    v = scope["decide_held_ticket"](good, set())
    ok &= record(f"{tag}: 合格窗口（多票、逐票 (7,4)、未 Flush）通过",
                 v["nonempty"] and v["unique_terminal"] and v["cancelled_signature"]
                 and v["never_flushed"] and v["t1"] == 4, str(v))
    vb = scope["decide_held_ticket"](good, {5})
    ok &= record(f"{tag}: 窗口票进入 Flush 边界被判负", vb["never_flushed"] is False, str(vb))
    vs = scope["decide_held_ticket"]({4: [(0, 3)]}, set())
    ok &= record(f"{tag}: 窗口票 status=0 被判负", vs["cancelled_signature"] is False, str(vs))
    vd = scope["decide_held_ticket"]({4: [(7, 4), (7, 4)]}, set())
    ok &= record(f"{tag}: 同一票两行终态被判负", vd["unique_terminal"] is False, str(vd))
    ve = scope["decide_held_ticket"]({}, set())
    ok &= record(f"{tag}: 空窗口被判负（反假绿承重墙）", ve["nonempty"] is False, str(ve))
    return ok


def expect_partition(scope, tag):
    """GREEN：W/U 分割与重铸上界。"""
    ok = True
    w, u = scope["partition_hold_window"]({4: [(7, 4)], 14: [(0, 3)], 15: [(0, 3)]}, {14, 15})
    ok &= record(f"{tag}: W 只含 U 之前的窗口票", set(w) == {4} and u == 14, f"(W={sorted(w)} U={u})")
    w2, u2 = scope["partition_hold_window"]({4: [(7, 4)]}, set())
    ok &= record(f"{tag}: 无释放后 Flush ⇒ U=None,W=∅", u2 is None and w2 == {}, f"(W={w2} U={u2})")
    ok &= record(f"{tag}: |W| 在 waitFor 上界内通过", scope["remint_within_bound"](10, 24.0) is True)
    ok &= record(f"{tag}: |W| 超上界被判负", scope["remint_within_bound"](40, 24.0) is False)
    return ok


def decide_t2_scope(mutation=None):
    import re
    scope = {"re": re}
    return load({"decide_t2_ordering", "wait_enter_seq", "wait_exit_seq", "enqueue_seq",
                 "claim_seq", "open_wait_tickets"}, scope, mutation)


def _t2_rows(claim_early=False):
    """一条有序 hilog 流，带 round7-B 的四个真实边界序号。

    序号：enter(T1)=100，enqueue(T2)=150，exit(T1)=200，claim(T2)=210。默认顺序＝
    等待**先**返回、T2 **后**分发（真实 owner 串行的唯一合法次序）。`present terminal`
    仍打印（结算证据），但**不**参与顺序判定。"""
    enter = f"{TS} I A00000/CjguiRenderer: present wait enter session=1 ticket=4 seq=100"
    enq = (f"{TS} I A00000/CjguiTransport: transport-cost stage=enqueue instance=i "
           f"requestId=900123 op=REPLACE_RANGE seq=150 bytes=120")
    exit_ = f"{TS} W A00000/CjguiRenderer: present wait exit session=1 ticket=4 status=7 seq=200"
    claim = (f"{TS} I A00000/CjguiTransport: transport-cost stage=owner-claim "
             f"instance=i requestId=900123 op=REPLACE_RANGE queueUs=41 seq=210")
    term = f"{TS} I A00000/CjguiRenderer: present terminal session=1 ticket=4 status=7 phase=4"
    # claim_early：**序号**上 claim 早于 exit（claim_seq=120 < exit_seq=200），制造
    # 「提前分发」。注意必须改**序号**而不是行序——判据只比序号，行序重排不该影响
    # 结论（这正是 round7-B 不用 hilog 行序的理由；把行序当变量来构造反例等于回到
    # 旧语义）。
    if claim_early:
        claim = (f"{TS} I A00000/CjguiTransport: transport-cost stage=owner-claim "
                 f"instance=i requestId=900123 op=REPLACE_RANGE queueUs=41 seq=120")
    return [enter, enq, exit_, claim, term]


def expect_t2(scope, tag):
    """GREEN：四个真实边界序号方向正确 + 业务终态唯一。"""
    good_resp = ("PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND RESULT\nAPPLIED true\nCONFLICT false\n"
                 "VERSION_BEFORE 7\nVERSION_AFTER 8\nREASON applied\nEND")
    archive_one = [{"t": 1.0, "dir": "request", "raw": "INVOKE 7 REPLACE_RANGE 1 4"},
                   {"t": 2.0, "dir": "response", "raw": good_resp}]
    owner_before = (7, "61" * 7)
    owner_after_ok = (8, "58" + "61" * 7)
    rows = _t2_rows()
    ok, why, facts = scope["decide_t2_ordering"](4, 900123, rows, archive_one, good_resp,
                                                 owner_before, owner_after_ok)
    ok0 = record(f"{tag}: 合法四边界（enter<enqueue<exit<=claim）通过",
                 ok and "dispatched_after_return" in why, f"({why})")
    ok0 &= record(f"{tag}: 四个边界序号都进了 facts",
                  (facts.get("t1_enter_seq"), facts.get("t2_enqueue_seq"),
                   facts.get("t1_exit_seq"), facts.get("t2_claim_seq")) == (100, 150, 200, 210),
                  str(facts))
    # ① 入队在 T1 进入等待之前 ⇒ 不在等待区间内。
    before = [f"{TS} I A00000/CjguiTransport: transport-cost stage=enqueue instance=i "
              f"requestId=900123 op=REPLACE_RANGE seq=90 bytes=120"] + rows
    ok1, why1, _ = scope["decide_t2_ordering"](4, 900123, before, archive_one, good_resp)
    ok0 &= record(f"{tag}: 入队早于 enter 被判负", ok1 is False
                  and why1 == "t2_not_enqueued_inside_t1_wait_window", why1)
    # ② 入队在 T1 等待返回之后。
    after = [r for r in rows if "stage=enqueue" not in r] + [
        f"{TS} I A00000/CjguiTransport: transport-cost stage=enqueue instance=i "
        f"requestId=900123 op=REPLACE_RANGE seq=250 bytes=120"]
    ok2, why2, _ = scope["decide_t2_ordering"](4, 900123, after, archive_one, good_resp)
    ok0 &= record(f"{tag}: 入队晚于 exit 被判负", ok2 is False
                  and why2 == "t2_enqueued_after_t1_wait_return", why2)
    # ③ 分发早于等待返回。
    ok3, why3, _ = scope["decide_t2_ordering"](4, 900123, _t2_rows(claim_early=True),
                                               archive_one, good_resp)
    ok0 &= record(f"{tag}: claim 早于 exit 被判负", ok3 is False
                  and why3 == "t2_dispatched_before_t1_wait_return", why3)
    # ③b 行序重排不改变结论：判据只比序号，hilog 行序是接收序不是因果序。
    shuffled = list(reversed(rows))
    ok3b, why3b, _ = scope["decide_t2_ordering"](4, 900123, shuffled, archive_one, good_resp,
                                                 owner_before, owner_after_ok)
    ok0 &= record(f"{tag}: 行序倒置不改变结论（判据不依赖 hilog 行序）", ok3b is True, why3b)
    # ④ 缺任一真实边界行一律具名未验。
    for name, drop, want in [
        ("缺 enter", "present wait enter", "t1_wait_enter_boundary_row_missing"),
        ("缺 exit", "present wait exit", "t1_wait_exit_boundary_row_missing"),
        ("缺 enqueue", "stage=enqueue", "t2_enqueue_boundary_row_missing"),
        ("缺 claim", "stage=owner-claim", "t2_dispatch_claim_row_missing"),
    ]:
        subset = [r for r in rows if drop not in r]
        okx, whyx, _ = scope["decide_t2_ordering"](4, 900123, subset, archive_one, good_resp)
        ok0 &= record(f"{tag}: {name} ＝具名未验", okx is False and whyx == want, whyx)
    # ⑤ 身份缺失与读请求冒充写。
    ok4, why4, _ = scope["decide_t2_ordering"](4, None, rows, archive_one, good_resp)
    ok0 &= record(f"{tag}: 入队身份缺失＝具名未验", ok4 is False
                  and why4 == "t2_enqueue_identity_missing", why4)
    ok5, why5, _ = scope["decide_t2_ordering"](None, 900123, rows, archive_one, good_resp)
    ok0 &= record(f"{tag}: T1 票号缺失＝具名未验", ok5 is False
                  and why5 == "t1_ticket_identity_missing", why5)
    read_rows = [r.replace("op=REPLACE_RANGE", "op=READ") for r in rows]
    ok6, why6, _ = scope["decide_t2_ordering"](4, 900123, read_rows, archive_one, good_resp,
                                               owner_before, owner_after_ok)
    ok0 &= record(f"{tag}: 读请求冒充写判负", ok6 is False
                  and why6 == "t2_enqueue_not_write_operation", why6)
    # ⑥ T1 配对：入队那一刻仍在等待的票；两张同时在等即歧义。
    ok0 &= record(f"{tag}: 入队时唯一在等的票＝T1", scope["open_wait_tickets"](rows, 150) == {4},
                  str(scope["open_wait_tickets"](rows, 150)))
    amb = rows + [f"{TS} I A00000/CjguiRenderer: present wait enter session=1 ticket=5 seq=120",
                  f"{TS} W A00000/CjguiRenderer: present wait exit session=1 ticket=5 status=7 seq=190"]
    ok0 &= record(f"{tag}: 两张票同时在等＝歧义集合", scope["open_wait_tickets"](amb, 150) == {4, 5},
                  str(scope["open_wait_tickets"](amb, 150)))
    # ⑦ 业务终态判据全部保留。
    ok7, why7, _ = scope["decide_t2_ordering"](4, 900123, rows, archive_one + [
        {"t": 2.5, "dir": "response", "raw": good_resp}], good_resp)
    ok0 &= record(f"{tag}: 业务终态两行＝不唯一判负", ok7 is False and "not_unique" in why7, why7)
    ok8, why8, _ = scope["decide_t2_ordering"](4, 900123, rows, archive_one, good_resp,
                                               owner_before, (9, "61" * 8))
    ok0 &= record(f"{tag}: 回包版本与读回不同源判负", ok8 is False
                  and why8 == "t2_business_terminal_owner_version_mismatch", why8)
    ok9, why9, _ = scope["decide_t2_ordering"](4, 900123, rows, archive_one, "KIND OK\n")
    ok0 &= record(f"{tag}: 无 APPLIED true 回包判负", ok9 is False
                  and why9 == "t2_business_terminal_not_applied", why9)
    ok10, why10, _ = scope["decide_t2_ordering"](4, 900123, rows, archive_one, good_resp,
                                                 owner_before, (8, "61" * 7 + "62"))
    ok0 &= record(f"{tag}: 同长度错全文判负", ok10 is False
                  and why10 == "t2_full_owner_bytes_mismatch", why10)
    jump_resp = good_resp.replace("VERSION_AFTER 8", "VERSION_AFTER 12")
    ok11, why11, _ = scope["decide_t2_ordering"](4, 900123, rows,
                                                 [{"t": 1.0, "dir": "response", "raw": jump_resp}],
                                                 jump_resp, owner_before,
                                                 (12, "58" + owner_before[1]))
    ok0 &= record(f"{tag}: 版本跳跃（+4）判负", ok11 is False
                  and why11.startswith("t2_version_not_exactly_one"), why11)
    return ok0


TS = "10-03 04:11:02.100 27682 27860"


def decide_scope(mutation=None):
    return load({"decide_held_ticket", "partition_hold_window", "remint_within_bound"},
                {"math": math}, mutation)



def main():
    failures = 0
    note("== GREEN 正控（当前生产函数原样提取）==")
    if not expect_scan(scan_scope(), "GREEN"): failures += 1
    if not expect_decide(decide_scope(), "GREEN"): failures += 1
    if not expect_partition(decide_scope(), "GREEN"): failures += 1
    if not expect_t2(decide_t2_scope(), "GREEN"): failures += 1

    # 正控：转发归属（读列表 rc0 + 本轮无映射 + 创建 rc0 且明确回执 + 同一行三元组
    # 复查匹配）与触发成功。`hdc_run` 是**子进程边界**替身，判据本身逐字来自生产。
    OUR_ROW = "127.0.0.1:5555    tcp:28865 tcp:7856    [Forward]"
    USER_ROW = "127.0.0.1:5555    tcp:7856 tcp:7856    [Forward]"

    def forward_scope(listing, create_rc=0, create_out="Forwardport result:OK\n",
                      list_rc=0, mutation=None):
        """`listing` 既可是字符串（每次 `fport ls` 同值），也可是按调用次序的列表。"""
        calls = []
        state = {"ls": 0}

        def _run(args, **kw):
            args = list(args)
            calls.append(args)
            if "rm" in args:
                state["removed"] = True
                return SimpleNamespace(stdout="", returncode=0, stderr="")
            if "ls" in args:
                # round7-B：`release_forward` 在 rm 之后**复查映射**，映射仍在就
                # 具名未清理完成。替身必须建模「rm 真的生效」，否则正向清理永远红。
                if state.get("removed"):
                    return SimpleNamespace(stdout="", returncode=list_rc, stderr="")
                seq = listing if isinstance(listing, list) else [listing]
                out = seq[min(state["ls"], len(seq) - 1)]
                state["ls"] += 1
                return SimpleNamespace(stdout=out, returncode=list_rc, stderr="")
            return SimpleNamespace(stdout=create_out, returncode=create_rc, stderr="")

        scope = {"re": __import__("re"), "subprocess": SimpleNamespace(run=_run),
                 "HDC": "unused", "PORT": 28865, "REMOTE_PORT": 7856,
                 "FORWARD_TARGET": "127.0.0.1:5555", "FORWARD_OWNED": [], "calls": calls}
        return load({"hdc_run", "forward_rows", "ensure_forward", "release_forward",
                     "hdc_target_args"},
                    scope, mutation, assigns=("MAP_ROW",))

    fs = forward_scope(["", OUR_ROW])
    ok, why = fs["ensure_forward"]()
    if not record("GREEN: 转发创建（rc0+回执+同一行三元组）取得清理权",
                  ok and why == "created+verified", why):
        failures += 1
    if not record("GREEN: 清理按本轮三元组精确移除", fs["release_forward"]() == "removed",
                  str(fs["calls"])):
        failures += 1
    unowned = forward_scope("")
    if not record("GREEN: 未创建时绝不释放（清理权未取得）",
                  unowned["release_forward"]() == "not_owned_skipped"
                  and not any("rm" in c for c in unowned["calls"]), str(unowned["calls"])):
        failures += 1

    # B 反例 1（跨行误判）：28865→7999 与用户 7856→7856 同列表。把两个不同行的字段
    # 拼成"本轮映射"曾返回 created+verified；现在必须具名拒绝、不取得清理权、零 rm。
    cross = forward_scope([f"{USER_ROW}\n127.0.0.1:5555    tcp:28865 tcp:7999    [Forward]",
                           f"{USER_ROW}\n{OUR_ROW}"])
    ok1, why1 = cross["ensure_forward"]()
    if not record("B跨行: 28865→7999＋用户7856→7856 不取得清理权",
                  ok1 is False and why1.startswith("forward_other_or_old_mapping"), why1):
        failures += 1
    if not record("B跨行: 拒绝后清理不动用户映射（零 rm）",
                  cross["release_forward"]() == "not_owned_skipped"
                  and not any("rm" in c for c in cross["calls"]), str(cross["calls"])):
        failures += 1

    # B 反例 2（同端口异 target）：local/remote 都对，但属于别的设备 target。
    other = forward_scope(["", "192.0.2.7:5555    tcp:28865 tcp:7856    [Forward]"])
    ok2, why2 = other["ensure_forward"]()
    if not record("B异target: 复查行 target 不同则不取得清理权",
                  ok2 is False and why2.startswith("forward_mapping_mismatch"), why2):
        failures += 1
    if not record("B异target: 拒绝后零 rm",
                  not any("rm" in c for c in other["calls"]), str(other["calls"])):
        failures += 1

    # B 反例 3（清理前映射变化）：创建时匹配、清理前被换掉 ⇒ 跳过并具名，不删新映射。
    changed = forward_scope(["", OUR_ROW, f"{USER_ROW}\n127.0.0.1:5555    tcp:28865 tcp:7999    [Forward]"])
    changed["ensure_forward"]()
    del changed["calls"][:]
    why3 = changed["release_forward"]()
    if not record("B映射变化: 清理前重验失败即跳过并具名",
                  why3.startswith("cleanup_skipped_mapping_changed"), why3):
        failures += 1
    if not record("B映射变化: 跳过时不发出任何 rm",
                  not any("rm" in c for c in changed["calls"]), str(changed["calls"])):
        failures += 1

    # B 反例 4（读列表失败）：rc≠0 时不能把"没读到"当成"没有映射"进而认领。
    unreadable = forward_scope("", list_rc=1)
    ok4, why4 = unreadable["ensure_forward"]()
    if not record("B读列表失败: rc1 不认领、不创建",
                  ok4 is False and why4.startswith("forward_list_failed_rc")
                  and not any("rm" in c for c in unreadable["calls"]), why4):
        failures += 1

    # B 反例 5（无明确回执）：rc0 但 stdout 无 `Forwardport result:OK` ⇒ 不取得清理权。
    no_receipt = forward_scope(["", OUR_ROW], create_out="")
    ok5, why5 = no_receipt["ensure_forward"]()
    if not record("B无回执: rc0＋无 Forwardport result:OK 不认领",
                  ok5 is False and why5.startswith("forward_no_receipt"), why5):
        failures += 1

    good_m = SimpleNamespace(read_all=lambda p: (1, ""), agent_replace=lambda *a: None)
    fs2 = load({"trigger_present"}, {"m": good_m, "PORT": 28865})
    ok2, d2 = fs2["trigger_present"]()
    if not record("GREEN: 触发成功返回 (True, ...)", ok2 is True, d2):
        failures += 1

    note("== RED 变异（每条都必须被检出）==")
    RED = [
        ("M1 去掉 PID 归属",
         ("if len(ln.split()) >= 3 and ln.split()[2] == BOUND_PID)", "if True)"),
         "scan"),
        ("M2 accepted 去 session 过滤",
         ('            if m.group(1) == BOUND_SESSION}', "            if True}"),
         "scan"),
        ("M3 Flush 边界去 session 过滤",
         ('        if m.group(2) != BOUND_SESSION:\n            continue\n',
          '        if False:\n            continue\n'),
         "scan"),
        ("M4 终态去 session 过滤",
         ('        if m.group(1) != BOUND_SESSION:\n            continue\n',
          '        if False:\n            continue\n'),
         "scan"),
        ("M5 accepted-swap 冒充 Flush 入口",
         ('        (enter if m.group(1) == "enter" else exit_).add(int(m.group(3)))',
          '        (enter if m.group(1) == "enter" else exit_).add(int(m.group(3)))\n'
          '    for m in re.finditer(r"session=(\\d+) ticket=(\\d+) cause=commit", scoped_lines("image-lease stage=accepted-swap")):\n'
          '        if m.group(1) == BOUND_SESSION:\n            enter.add(int(m.group(2)))'),
         "scan"),
        ("M6 窗口逐票未 Flush 恒真",
         ("    never_flushed = all(t not in boundary_after for t in tickets)",
          "    never_flushed = True"),
         "decide"),
        ("M7 窗口票取消签名恒真",
         ("    cancelled_signature = all(hold_terminals[t] == [(7, 4)] for t in tickets)",
          "    cancelled_signature = True"),
         "decide"),
        ("M8 窗口票唯一终态恒真",
         ("    unique_terminal = all(len(hold_terminals[t]) == 1 for t in tickets)",
          "    unique_terminal = True"),
         "decide"),
        ("M9 窗口非空恒真（反假绿承重墙）",
         ('        "nonempty": len(tickets) > 0,', '        "nonempty": True,'),
         "decide"),
        ("M10 W/U 分割忽略 U 上界",
         ("    w = {t: new_terms[t] for t in new_terms if u is not None and t < u}",
          "    w = {t: new_terms[t] for t in new_terms}"),
         "partition"),
        ("M11 重铸上界恒真",
         ("    return count <= math.ceil(window_seconds * 1000.0 / 2000.0) + 2",
          "    return True"),
         "partition"),
        # T2 顺序判据的三处承重墙（round7-B：四个真实边界序号）：任一条被放宽，
        # GREEN 的合法链就不能再区分「入队不在等待内」与「提前分发」。
        ("M14 分发早于等待返回仍放行",
         ('    if ci < xi:\n        return False, "t2_dispatched_before_t1_wait_return", facts',
          '    if False:\n        return False, "t2_dispatched_before_t1_wait_return", facts'),
         "t2"),
        ("M15 入队区间不检（入队早于 enter 也算区间内）",
         ('    if not ei < enq:\n        return False, "t2_not_enqueued_inside_t1_wait_window", facts',
          '    if False:\n        return False, "t2_not_enqueued_inside_t1_wait_window", facts'),
         "t2"),
        ("M18 入队晚于 exit 仍放行",
         ('    if not enq < xi:\n        return False, "t2_enqueued_after_t1_wait_return", facts',
          '    if False:\n        return False, "t2_enqueued_after_t1_wait_return", facts'),
         "t2"),
        ("M16 业务终态唯一性不检",
         ('    if len(applied_responses) != 1:\n'
          '        return False, f"t2_business_terminal_not_unique:{len(applied_responses)}", facts',
          '    if len(applied_responses) < 1:\n'
          '        return False, f"t2_business_terminal_not_unique:{len(applied_responses)}", facts'),
         "t2"),
        ("M17 缺 owner-claim 行时当作已分发（CONTROL 可响应冒充分发证据）",
         ('    if ci is None:\n        return False, "t2_dispatch_claim_row_missing", facts',
          "    if ci is None:\n        ci = 10 ** 9"),
         "t2"),
        # T1 配对必须**如实返回全部**在等票：调用方靠「多于一张即歧义」拒绝。
        # 把集合截成一张＝把歧义藏起来。
        ("M19 T1 配对截成单张（歧义被藏）",
         ("        if enter < at_seq < exit_:\n            out.add(ticket)",
          "        if enter < at_seq < exit_ and not out:\n            out.add(ticket)"),
         "t2"),
    ]
    for name, mutation, kind in RED:
        try:
            if kind == "scan":
                still_green = expect_scan(scan_scope(mutation), name)
            elif kind == "decide":
                still_green = expect_decide(decide_scope(mutation), name)
            elif kind == "t2":
                still_green = expect_t2(decide_t2_scope(mutation), name)
            else:
                still_green = expect_partition(decide_scope(mutation), name)
        except AssertionError as e:
            note(f"   FAIL {name}: 变异锚点缺失（harness 需修）: {e}")
            failures += 1
            continue
        if not record(f"{name} 被检出", not still_green, "(变异后 GREEN 仍通过 = 未检出)"):
            failures += 1

    # round6-B：rm 回执失败具名（不报 removed）；--target 缺失时设备命令拒绝。
    rm_ls_state = {"n": 0}

    def _rmfail_run(args, **kw):
        args = list(args)
        if "rm" in args:
            return SimpleNamespace(stdout="[Fail] not found", returncode=1, stderr="")
        if "ls" in args:
            rm_ls_state["n"] += 1
            # 首次（创建前）无映射；复查（创建后）出现本轮映射。
            out = "" if rm_ls_state["n"] == 1 else OUR_ROW
            return SimpleNamespace(stdout=out, returncode=0, stderr="")
        return SimpleNamespace(stdout="Forwardport result:OK\n", returncode=0, stderr="")

    rmfail = forward_scope(["", OUR_ROW])
    rmfail["subprocess"] = SimpleNamespace(run=_rmfail_run)
    ok_rm, _why_rm = rmfail["ensure_forward"]()
    rel_rm = rmfail["release_forward"]()
    if not record("B rm 回执: 创建成功后 rm rc1+[Fail] 具名失败",
                  ok_rm is True and rel_rm.startswith("cleanup_rm_failed_rc=1"), rel_rm):
        failures += 1
    notarget = forward_scope(["", OUR_ROW])
    notarget["FORWARD_TARGET"] = ""
    try:
        notarget["ensure_forward"]()
        nt = "no_error"
    except RuntimeError as e:
        nt = str(e)
    if not record("B 无显式 target: 设备命令具名拒绝",
                  nt.startswith("hdc target not configured"), nt):
        failures += 1
    if not record("B 无显式 target: 未发出任何设备命令",
                  notarget["calls"] == [], str(notarget["calls"])):
        failures += 1

    # M12：ensure_forward 忽略退出码 / 复查只认端口（跨行拼接）
    fs3 = forward_scope("", create_rc=32, create_out="Forwardport result:OK\n")
    ok3, why3 = fs3["ensure_forward"]()
    if not record("M12 变异前：rc32 已不取得清理权（当前实现正确）", ok3 is False, why3):
        failures += 1
    fs4 = forward_scope(["", "127.0.0.1:5555    tcp:28865 tcp:7999    [Forward]"],
                        mutation=('    if forward_rows(again.stdout, PORT) != expect:',
                                  '    if not any(r[1] == PORT for r in forward_rows(again.stdout, PORT)):'))
    ok4, why4 = fs4["ensure_forward"]()
    if not record("M12 复查只认端口、跨行拼 remote 被检出（错映射仍认领）",
                  ok4 is True and why4 == "created+verified", why4):
        failures += 1
    fs4b = forward_scope(["", OUR_ROW], create_rc=32,
                         create_out="Forwardport result:OK\n",
                         mutation=('    if r.returncode != 0:\n'
                                   '        return False, f"forward_fail_rc={r.returncode}:{blob[:160]}"\n', ''))
    ok4b, why4b = fs4b["ensure_forward"]()
    if not record("M12 去掉退出码守卫被检出（rc32 仍取得清理权）", ok4b is True, why4b):
        failures += 1

    # M13：trigger_present 吞异常
    bad_m = SimpleNamespace(read_all=lambda p: (1, ""),
                            agent_replace=lambda *a: (_ for _ in ()).throw(RuntimeError("boom")))
    fs5 = load({"trigger_present"}, {"m": bad_m, "PORT": 28865},
               ('        return False, f"replace ERR {e!r}"', '        return True, f"replace SWALLOWED {e!r}"'))
    ok5, d5 = fs5["trigger_present"]()
    if not record("M13 吞异常被检出（失败返回 True）", ok5 is True, d5):
        failures += 1

    note(f"== 结果 failures={failures}  正控/变异共 {len(RESULTS)} 项")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
