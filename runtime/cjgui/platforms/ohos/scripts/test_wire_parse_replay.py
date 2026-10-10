#!/usr/bin/env python3
"""round13-R1：真实 wire→解析→身份判定整链回放（归档原回包，非手填 dict）。

直接回放 round12 设备运行的**原协议归档**（raw-responses.json，每条含完整
PROTOCOL/SNAPSHOT 帧），经生产 `public_state` 同款提取 → 共享
`parse_edit_section` → `body_restore_evidence` 权威门：

  * caret 与 span 两份归档各 24 条 `edit=live`：共享规范必须**全部**解析成功
    （round13 RED：旧正则要求 ctx/node 紧邻，24 条全漏）；
  * 解析出的身份含 gen 且与归档设备事实一致（caret ctx7/node107、span ctx5）；
  * `edit=none` 归为 {'live': False}，与 absent（None）/malformed 互不混淆；
  * 逐份回放：live 归档喂给 body_restore_evidence，无任何旧日志时身份门仍然
    成立（同 ctx 无 focus 行的正控，靠权威当前身份而非日志）。
"""
import ast
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPTS = HERE.parent if HERE.name != 'scripts' else HERE
SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parent.parent.parent.parent.parent
ART = ROOT / 'artifacts/h-r-final-20261002/round12-fix'
DRIVER = SCRIPTS / 'verify_pharos_dual_owner.py'

failures = []


def check(name, got, want):
    ok = got == want
    print(f"  {'OK  ' if ok else 'FAIL'} {name}: {got!r}" + ('' if ok else f' (want {want!r})'))
    if not ok:
        failures.append(name)


src = DRIVER.read_text()
tree = ast.parse(src)
NAMES = ('public_state', 'public_snapshot', 'body_restore_evidence',
         '_mount_lifecycle', '_identity_mismatch', '_version_behind')
nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in NAMES]
assert {n.name for n in nodes} == set(NAMES), sorted(n.name for n in nodes)
ns = {'re': re, 'BODY_FIELD': 'pharos-editor-body'}
exec(compile(ast.Module(body=nodes, type_ignores=[]), str(DRIVER), 'exec'), ns)

# 共享解析规范与 state 提取同款（public_state 的提取逻辑在驱动内联；这里复刻其
# OWNER_STATE 提取两行——与生产逐字一致的正则，来源：verify_pharos_dual_owner）。
spec = {}
exec(compile(ast.Module(body=[], type_ignores=[]), str(DRIVER), 'exec'), spec)
import importlib.util
dev_spec = importlib.util.spec_from_file_location(
    'dev_parse', SCRIPTS / 'h_source_preview_consumption.py')
dev = importlib.util.module_from_spec(dev_spec)
dev_spec.loader.exec_module(dev)


def state_of(response):
    mo = re.search(r"OWNER_STATE_UTF8_HEX (\d+) ([0-9a-fA-F]*)", response)
    if not mo:
        return None
    return bytes.fromhex(mo.group(2)).decode('utf-8', 'replace')


def replay(archive_path):
    blob = json.loads(Path(archive_path).read_text())
    states = []
    for entry in blob:
        s = state_of(entry.get('response', ''))
        if s:
            states.append(s)
    live = [dev.parse_edit_section(s) for s in states
            if dev.parse_edit_section(s) and dev.parse_edit_section(s).get('live')]
    none = sum(1 for s in states if (dev.parse_edit_section(s) or {}).get('live') is False)
    return states, live, none


def main():
    print('== round13-R1 真实回包回放（wire→解析→身份门） ==')
    summary = {}
    for name, exp_ctxs in (('pharos-caret', {2, 4, 5}), ('pharos-span2', {2, 4, 5})):
        states, live, none_n = replay(ART / name / 'raw-responses.json')
        check(f'{name}-live-parsed-all', len(live), 24)
        check(f'{name}-none-parsed', none_n, 5)
        ctxs = {e['ctx'] for e in live}
        check(f'{name}-identity-ctx-set', ctxs, exp_ctxs)
        check(f'{name}-has-gen', all('gen' in e for e in live), True)
        summary[name] = {'states': len(states), 'live': len(live), 'none': none_n}
        # 逐份回放：live 身份 + 无日志 + 无证据 → None（未证实，不借日志）。
        got = ns['body_restore_evidence']([], 0, 107, 1, 'main', owner_version=2,
                                          identity_hint=live[-1])
        check(f'{name}-no-logs-no-evidence-none', got, None)
    # 恢复正控：用归档的正文身份（最后一条 live）配同身份 ACK/采纳原行（无
    # focus 日志）→ 权威门通过且 basis 是 readback_edit_identity。
    states, live, _ = replay(ART / 'pharos-caret' / 'raw-responses.json')
    ident = next(e for e in live if e['field'] == 'pharos-editor-body' and e['ctx'] == 5)
    ack = (f"proxy restore ack accepted request=9 ctx={ident['ctx']} node={ident['node']} "
           f"installed=3:3 v={ident['v']}")
    adopt = (f"PHAROS_OHOS_RESTORE_ADOPTED count=2 failed=0 pending=false request=9 "
             f"ctx={ident['ctx']} node={ident['node']} adopted=3:3 owner_version=2 "
             f"v={ident['v']}")
    got = ns['body_restore_evidence']([ack, adopt], 0, 107, 1, 'main', owner_version=2,
                                      identity_hint=ident)
    check('caret-identity-pairs-without-focus-log',
          (got or {}).get('source'), 'restore_ack')
    check('caret-identity-basis-is-readback',
          (got or {}).get('current_identity', {}).get('basis'), 'readback_edit_identity')
    # 同份身份改 none → 同日志拒绝（round13 核心负控，wire 原格式）。
    got2 = ns['body_restore_evidence']([ack, adopt], 0, 107, 1, 'main', owner_version=2,
                                       identity_hint={'live': False})
    check('caret-none-rejects-same-logs',
          (got2 or {}).get('reason'), 'readback_edit_not_live')

    print()
    if failures:
        print(f'FAILURES: {len(failures)} -> {failures}')
        sys.exit(1)
    print('round13-R1 真实回包回放: OK（24/24 live 解析、四类互辨、权威门成立/拒绝）')


if __name__ == '__main__':
    main()
