#!/usr/bin/env python3
"""Presentation 提交票据的离线反例：抽取真实快照窗口票据类与纯复核函数。

只抽取 `CjguiPresentationHitTicket`（命名票据：显示来源/场景/绑定/身份同一
快照）与 `verifyPresentationHitTicket`（复核＋冻结正文换算），不抽窗口、不碰
设备。形状覆盖指导原定五项：多字节换算、owner 推进、同 id 换绑/ABA、纯几何
新帧及合法正控；变异证明每处门真实生效（去任一门或改换算，对应用例必红）。
"""
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
SNAPSHOT = HERE.parent / 'snapshot' / 'src'
WINDOW = SNAPSHOT / 'composable_ui_window.cj'


def balanced(source, start):
    opening = source.index('{', start)
    depth = 0
    for i in range(opening, len(source)):
        if source[i] == '{':
            depth += 1
        elif source[i] == '}':
            depth -= 1
            if depth == 0:
                return source[start:i + 1]
    raise ValueError('unbalanced production source')


def harness(red=None):
    source = WINDOW.read_text()
    cls_marker = 'public class CjguiPresentationHitTicket {'
    assert source.count(cls_marker) == 1, 'ticket class drift'
    cls = balanced(source, source.index(cls_marker))
    fn_marker = 'public func verifyPresentationHitTicket('
    assert source.count(fn_marker) == 1, 'verify func drift'
    fn = balanced(source, source.index(fn_marker))
    result = 'package cjgui\n' + cls + '\n' + fn + '\n'
    if red is not None:
        old, new = RED_GUARDS[red]
        assert result.count(old) == 1, (red, result.count(old))
        result = result.replace(old, new, 1)
    return result


RED_GUARDS = {
    # 去绑定门：ABA（同文同景不同绑定）会被误接受。
    'binding': ('ticket.bindingEpoch != currentBinding', 'false'),
    # 去显示正文门：D 推进会被误接受，旧坐标贴当前版本。
    'text': ('ticket.displayText != currentText', 'false'),
    # 去镜像正文门：旧显示/新正文（D 仍 éA、M 已 AB/v2）会被误接受登记到 v2。
    'mirror-text': ('ticket.mirrorText != currentMirrorText', 'false'),
    # 去镜像版本门：同字节新版本（M 正文同、版本 1→3）会被误接受。
    'mirror-version': ('ticket.mirrorVersion != currentMirrorVersion', 'false'),
    # 去场景门：纯几何新帧会被误接受。
    'scene': ('ticket.sceneVersion != currentScene', 'false'),
    # 改换算（按字节数当单位）：emoji 4 字节会被算成 4 单位而非 2。
    'units': ('units += if (width >= 4) { 2 } else { 1 }', 'units += 1'),
}


def run(red=None):
    with tempfile.TemporaryDirectory(prefix='cjgui-ohos-presentation-submit-') as tmp:
        root = Path(tmp)
        subprocess.run(['cjpm', 'init', '--name', 'cjgui', '--type=static'],
                       cwd=root, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        src = root / 'src'
        for p in src.glob('*.cj'):
            p.unlink()
        (src / 'window_extract.cj').write_text(harness(red))
        (src / 'presentation_submit_snapshot_test.cj').write_text(
            (HERE / 'fixtures' / 'presentation_submit_snapshot_test.cj').read_text())
        p = subprocess.run(['cjpm', 'test', '--no-color', '--no-progress'],
                           cwd=root, capture_output=True, text=True)
        sys.stdout.write(p.stdout)
        sys.stderr.write(p.stderr)
        return p.returncode


if __name__ == '__main__':
    clean = run()
    if clean:
        sys.exit(clean)
    if '--selftest' in sys.argv:
        for red in RED_GUARDS:
            code = run(red)
            print(f'[negative-control:{red}] exit={code}')
            if code == 0:
                sys.exit(1)
    print('PASS real snapshot ticket class + pure submit verifier')
