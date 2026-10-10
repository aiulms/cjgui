#!/usr/bin/env python3
"""Presentation 来源保存时机的常驻反例：走真实来源捕获/晋升→freeze→submit。

抽取真实生产代码（快照窗 decide/apply/freeze/submit/frozenScene、
票据/记录/复核/镜像快照类），只把场景/会话/FFI 命中换成替身（C stub 可控
场景代际；会话工具按已复核语义建模 owner 版本戳）。用例覆盖指导固定形状：
合法正控；M 在 freeze 前推进（无记录/有记录）；同字节先变；M 在 freeze 后
推进；PENDING 旧票污染；失败保旧；未声明变换；合法重发布；交互继承；
查询门存活。拒绝一律核零写。变异证明每处门真实生效；结构断言钉住接线点
（晋升只发生在两条成功路径，失败/交互路径无写入）。
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
SNAPSHOT = HERE.parent / 'snapshot' / 'src'
WINDOW = SNAPSHOT / 'composable_ui_window.cj'
TEXT_SESSION = SNAPSHOT / 'text_session.cj'
TEMPLATE = HERE / 'fixtures' / 'presentation_source_snapshot_harness.cj.txt'
DRIVER = HERE / 'fixtures' / 'presentation_source_cases.cj'
C_STUB = HERE / 'fixtures' / 'presentation_source_hit_stub.c'


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


def method(source, name):
    marker = f'    private func {name}('
    if source.count(marker) != 1:
        marker = f'    public func {name}('
    assert source.count(marker) == 1, name
    return balanced(source, source.index(marker)).replace(marker, f'    func {name}(', 1)


def klass(source, name):
    marker = f'public class {name} {{'
    assert source.count(marker) == 1, name
    return balanced(source, source.index(marker))


def freefunc(source, name):
    marker = f'public func {name}('
    assert source.count(marker) == 1, name
    return balanced(source, source.index(marker))


def assemble(red=None):
    wsource = WINDOW.read_text()
    methods = '\n'.join(method(wsource, n) for n in (
        'decideCandidatePresentationSource',
        'applyCandidatePresentationSource',
        'presentationSourceFactsEqual',
        'establishPresentationSourceAtBind',
        'frozenSceneGeneration',
        'freezePresentationHit',
        'submitPresentationSelection',
    ))
    types = '\n'.join([
        klass(wsource, 'CjguiPresentationSourceRecord'),
        klass(wsource, 'CjguiPresentationHitTicket'),
        freefunc(wsource, 'verifyPresentationHitTicket'),
        klass(TEXT_SESSION.read_text(), 'CjguiTextSessionMirrorSnapshot'),
    ])
    result = (TEMPLATE.read_text()
              .replace('// @METHODS', methods)
              .replace('// @TYPES', types))
    if red is not None:
        old, new = RED_GUARDS[red]
        assert result.count(old) == 1, (red, result.count(old))
        result = result.replace(old, new, 1)
    return result


RED_GUARDS = {
    # 去绑定复用：重绑不再沿用等价来源，重绑后首点选区无票据（B0/R2 形状失败）。
    'bind-establish': ('        applyCandidatePresentationSource(decision, record)',
                       '        applyCandidatePresentationSource(2, None)'),
    # 去直接映射门：未声明变换（D≠mirror）也会晋升来源。
    'mapping': ('if (node.value == mirror.text)', 'if (true)'),
    # 去镜像正文门：旧显示/新正文会被误接受登记。
    'mirror-text': ('ticket.mirrorText != currentMirrorText', 'false'),
    # 去镜像版本门：同字节新版本会被误接受。
    'mirror-version': ('ticket.mirrorVersion != currentMirrorVersion', 'false'),
}


def structural_guards():
    """接线断言：晋升只发生在两条成功路径；失败/回滚/交互路径无来源写入；
    结算不重读 live 会话镜像。"""
    wsource = WINDOW.read_text()
    checks = {
        # decide 调用点：tx 登记＋同步路径＋绑定建立，共 3 处调用＋1 定义。
        'decide-call-sites': (
            wsource.count('decideCandidatePresentationSource('), 4),
        # apply 调用点：异步成功＋同步成功＋绑定建立，共 3 处调用＋1 定义。
        'apply-call-sites': (
            wsource.count('applyCandidatePresentationSource('), 4),
        # accepted 记录写入点：仅 apply 内的晋升＋清除，共 2 处
        # （字段初始化不在此列；失败/回滚/交互路径无写入）。
        'accepted-record-writes': (
            len(re.findall(r'acceptedPresentationSource\s*=\s*(Some|None)', wsource)), 2),
        # apply 内部不得重读 live 会话/镜像（结算时重读即污染旧票来源）。
        'apply-reads-no-live-mirror': (
            balanced(wsource, wsource.index('    private func applyCandidatePresentationSource(')).count(
                'mirrorSnapshot'), 0),
        # 绑定建立调用点：定义＋bind 内调用，共 2 处（首点前已有依据）。
        'establish-call-sites': (
            wsource.count('establishPresentationSourceAtBind()'), 2),
    }
    bad = [f'{k}: got {v[0]}, want {v[1]}' for k, v in checks.items() if v[0] != v[1]]
    return bad


def run(red=None):
    with tempfile.TemporaryDirectory(prefix='cjgui-ohos-presentation-source-') as tmp:
        root = Path(tmp)
        lib = root / 'libhitstub.a'
        q = subprocess.run(['clang', '-c', str(C_STUB), '-o', str(root / 'hit.o')],
                           capture_output=True, text=True)
        if q.returncode != 0:
            print(q.stderr)
            return 2
        q = subprocess.run(['ar', 'rcs', str(lib), str(root / 'hit.o')],
                           capture_output=True, text=True)
        if q.returncode != 0:
            print(q.stderr)
            return 2
        src = assemble(red)
        (root / 'probe.cj').write_text(src + '\n' + DRIVER.read_text())
        p = subprocess.run(['cjc', str(root / 'probe.cj'), '-L', str(root),
                            '-lhitstub', '-o', str(root / 'probe')],
                           capture_output=True, text=True)
        if p.returncode != 0:
            print(p.stderr[-3000:])
            return 3
        p = subprocess.run([str(root / 'probe')], capture_output=True, text=True)
        sys.stdout.write(p.stdout)
        sys.stderr.write(p.stderr[-1000:] if p.stderr else '')
        return p.returncode


if __name__ == '__main__':
    bad = structural_guards()
    if bad:
        print('STRUCTURAL GUARD FAILED:', bad)
        sys.exit(4)
    print('structural-guards: ok')
    clean = run()
    if clean:
        sys.exit(clean)
    if '--selftest' in sys.argv:
        for red in RED_GUARDS:
            code = run(red)
            print(f'[negative-control:{red}] exit={code}')
            if code == 0:
                sys.exit(1)
    print('PASS real source capture/promote/freeze/submit')
