#!/usr/bin/env python3
"""Read current production functions; replay small offline counterexamples.

No HDC/UI/network calls. Only /tmp and this evidence directory are written.
The Cangjie harness preserves the production bind method verbatim, replacing
its collaborators with minimal doubles; it is not a complete window test.
"""
import ast
import hashlib
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile
import types

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SCRIPT = ROOT / 'runtime/cjgui/platforms/ohos/scripts/verify_thermo_shared_lifecycle.py'
REGION = ROOT / 'runtime/cjgui/src/composable_ui_generated_region.cj'
SYNC = ROOT / 'runtime/cjgui/platforms/ohos/scripts/sync_platform.sh'


def driver_and_sync():
    tree = ast.parse(SCRIPT.read_text())
    funcs = ast.Module(body=[n for n in tree.body if isinstance(n, ast.FunctionDef)], type_ignores=[])
    ns = {'re': re, 'time': types.SimpleNamespace(sleep=lambda _: None), 'json': json}
    ns['tc'] = types.SimpleNamespace(_m=types.SimpleNamespace(
        hilog_rows=lambda: ['D 9999 unrelated terminal=INSTALLED']))
    exec(compile(funcs, str(SCRIPT), 'exec'), ns)
    wrong = ns['rows_for']('1234')
    old = ['D 1234 proxy mounted key=old_mount field=hand-scroll-note',
           'D 1234 ime selection confirmed [0,4) rc=0 (shared lifecycle)',
           'D 1234 ime proxy selection terminal=INSTALLED reason=caret_confirmed target=[0,4) mount=old_mount']
    ns['tc']._m.hilog_rows = lambda: old + [
        'D 1234 ime proxy selection terminal=INSTALLED reason=caret_confirmed target=[8,8) mount=unrelated_mount']
    stale, _ = ns['wait_confirmed']('1234', len(old), True, 1)
    commands = []

    def fake_run(argv, **kw):
        commands.append(argv)
        return types.SimpleNamespace(returncode=32, stdout='[Fail] mapping already exists', stderr='')

    with tempfile.TemporaryDirectory(prefix='cjgui-h-review-driver-') as d:
        ns.update(subprocess=types.SimpleNamespace(run=fake_run), HDC='hdc-stub',
                  BUNDLE='test.bundle', OUT=Path(d))
        ns['thermo_pid'] = lambda: '1234'
        ns['tc'].tap_semantic = lambda _: None
        main_exit = ns['main']()
    cleanup = [c for c in commands if c[1:3] == ['fport', 'rm']]
    result = {
        'scope': 'Offline current-function replay; no HDC, UI, or device calls',
        'input_sha256': hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),
        'wrong_pid_fallback': {'expected': [], 'actual': wrong, 'bug_reproduced': bool(wrong)},
        'old_confirmation_after_unrelated_new_terminal': {
            'expected': None, 'actual': stale, 'bug_reproduced': stale == (0, 4)},
        'failed_forward_creation_cleanup': {
            'creation_returncode': 32, 'main_exit': main_exit, 'cleanup_commands': cleanup,
            'bug_reproduced': bool(cleanup)},
    }
    text = SYNC.read_text()
    start = text.index('rsync -a --delete --exclude', text.index('# 5) 共享应用'))
    end = text.index('\n# 消费方附加依赖', start)
    with tempfile.TemporaryDirectory(prefix='cjgui-h-review-sync-') as d:
        dest = Path(d) / 'thermostat_application/src'
        shutil.copytree(ROOT / 'labs/ohos_thermo_app/entry/thermostat_application/src', dest)
        before = 'func applyTextEdit' in (dest / 'thermostat_generated_region.cj').read_text()
        env = os.environ.copy()
        env.update(APP_SRC=str(ROOT / 'runtime/cjgui/examples/thermostat_application/src'),
                   MODULE=d, APP_DIR_NAME='thermostat_application')
        proc = subprocess.run(['bash', '-c', text[start:end]], env=env, capture_output=True, text=True)
        after = 'func applyTextEdit' in (dest / 'thermostat_generated_region.cj').read_text()
        result['canonical_sync'] = {
            'scope': 'Actual rsync block from sync_platform.sh; temporary destination',
            'exit': proc.returncode, 'bridge_provider_before': before,
            'bridge_provider_after': after, 'bug_reproduced': before and not after,
            'stderr': proc.stderr,
        }
    (OUT / 'driver-and-sync.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    return result


HARNESS = r'''
package review
let CJGUI_COMPOSABLE_UI_EVENT_FOCUS: Int64 = 31
func internalRendererWindowLog(value: String): Unit { let _ = value }
class Node {
    public let nodeId: Int64
    public let semanticId: String
    public let nodeKind: Int64
    public let fieldId = "note"
    public let operationActionName = "SET_NOTE"
    public let resourceId: Int64 = 9801
    public let operationResourceId: Int64 = 9801
    public init(id: Int64, semantic: String, kind: Int64) {
        nodeId = id; semanticId = semantic; nodeKind = kind
    }
}
class Field {
    public let fieldId = "note"
    public let editorKind = "TEXT"
    public let writeActionName = "SET_NOTE"
    public let resourceId: Int64 = 9801
}
class Catalog { public func fieldFor(id: String): ?Field { return Some(Field()) } }
class Binding { public func rangeTextEditSupported(id: String): Bool { return true } }
class CjguiGeneratedFieldRangeSession { public init(b: Binding, id: String) {} }
class Window {
    public var node: Int64 = -1
    public var semantic: String = ""
    public var binds: Int64 = 0
    public func bindRangeTextSession(id: Int64, semanticId: String,
        source: CjguiGeneratedFieldRangeSession, sink: CjguiGeneratedFieldRangeSession,
        resource: Int64, kind: Int64): Int64 {
        node = id; semantic = semanticId; binds += 1
        return binds
    }
}
class CjguiComposableUiEvent {
    public let node: Node
    public let eventKind: Int64 = 31
    public init(n: Node) { node = n }
}
class Gate {
    private let catalog = Catalog()
    private let binding = Binding()
    private let attachedWindow: ?Window
    private var rangeSessionNodeId: Int64 = -1
    private var rangeSessionFieldId: String = ""
    private var rangeSessionWriterOperation: String = ""
    private var rangeSessionFieldResource: Int64 = -1
    public init(window: Window) { attachedWindow = Some(window) }
    public func focus(node: Node): Unit { bindFieldRangeSessionIfFocused(CjguiComposableUiEvent(node)) }
__PRODUCTION_METHOD__
}
main(): Int64 {
    let w = Window()
    let g = Gate(w)
    let a = Node(942, "field-A", 7)
    g.focus(a)
    println("positive_initial_node=${w.node} binds=${w.binds}")
    g.focus(a)
    println("positive_idempotent_binds=${w.binds}")
    let b = CjguiGeneratedFieldRangeSession(Binding(), "other")
    let _ = w.bindRangeTextSession(313, "other-owner", b, b, 123, 7)
    g.focus(a)
    println("return_to_A_expected=942 actual=${w.node} binds=${w.binds}")
    let w2 = Window()
    let g2 = Gate(w2)
    g2.focus(a)
    g2.focus(Node(942, "replacement-semantic", 7))
    println("semantic_rebind_expected=replacement-semantic actual=${w2.semantic} binds=${w2.binds}")
    return 0
}
'''


def binding_replay():
    text = REGION.read_text()
    start = text.index('    private func bindFieldRangeSessionIfFocused(')
    end = text.index('\n    public func capabilitiesPayload()', start)
    method = text[start:end]
    source = HARNESS.replace('__PRODUCTION_METHOD__', method)
    (OUT / 'binding-harness.cj').write_text(source)
    cjc = shutil.which('cjc')
    result = {'scope': 'Current production bind method verbatim; minimal window/provider doubles',
              'input_sha256': hashlib.sha256(REGION.read_bytes()).hexdigest()}
    if not cjc:
        result['status'] = 'compiler_unavailable'
    else:
        with tempfile.TemporaryDirectory(prefix='cjgui-h-review-binding-') as d:
            exe = Path(d) / 'binding-replay'
            compiled = subprocess.run([cjc, str(OUT / 'binding-harness.cj'), '-Woff', 'all', '-o', str(exe)],
                                      text=True, capture_output=True)
            result['compile_exit'] = compiled.returncode
            result['compile_output'] = compiled.stdout + compiled.stderr
            if compiled.returncode == 0:
                run = subprocess.run([str(exe)], text=True, capture_output=True)
                result.update(exit=run.returncode, stdout=run.stdout, stderr=run.stderr)
                result['lost_binding_reproduced'] = 'return_to_A_expected=942 actual=313' in run.stdout
                result['semantic_rebind_skipped'] = 'semantic_rebind_expected=replacement-semantic actual=field-A' in run.stdout
    (OUT / 'binding-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    return result


def ticket_replay():
    test = ROOT / 'runtime/cjgui/platforms/ohos/scripts/test_s2_identity_handoff_native.py'
    ctx = runpy.run_path(str(test))
    source = ctx['SOURCE'].read_text()
    parts = [ctx['PREFIX']]
    for key in ('push_end', 'take', 'begin', 'finish', 'sync'):
        parts.append(ctx['extract_method'](source, ctx['SIGNATURES'][key]))
    parts.append(r'''
int main() {
  Session s; active=&s;
  SceneNode n; n.pod.nodeId=107; n.pod.resourceId=1;
  n.semanticId="body"; n.value="abc";
  s.accepted.push_back(n);
  beginEditingOnNodeLocked(s,n);
  const auto context=s.editingContextId;
  std::cout << "positive_healthy=" << (takeEditingContextLocked(context)!=nullptr) << "\n";
  // Exactly the state constructed by the current production test's case 6a.
  s.acceptedPaintTicketId=4; s.acceptedProjectionVersion=4; s.accepted.clear();
  syncEditingBufferAfterAcceptedSceneLocked(&s);
  std::cout << "after_old_ticket_accepted_nodes=" << s.accepted.size()
            << " live=" << s.editingContextLive
            << " input_context_accepted=" << (takeEditingContextLocked(context)!=nullptr) << "\n";
  return 0;
}
''')
    (OUT / 'ticket-harness.cpp').write_text('\n'.join(parts))
    result = {'scope': 'Current extracted production functions, reproducing existing test case 6a; actual submit-path reachability NOT established',
              'input_sha256': hashlib.sha256(ctx['SOURCE'].read_bytes()).hexdigest()}
    with tempfile.TemporaryDirectory(prefix='cjgui-h-review-ticket-') as d:
        exe = Path(d) / 'ticket-replay'
        c = subprocess.run(['clang++', '-std=c++17', str(OUT / 'ticket-harness.cpp'), '-o', str(exe)], capture_output=True, text=True)
        result.update(compile_exit=c.returncode, compile_output=c.stdout+c.stderr)
        if c.returncode == 0:
            p = subprocess.run([str(exe)], capture_output=True, text=True)
            result.update(exit=p.returncode, stdout=p.stdout, stderr=p.stderr)
    (OUT / 'ticket-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    return result


if __name__ == '__main__':
    print(json.dumps({'driver': driver_and_sync(), 'binding': binding_replay(), 'ticket': ticket_replay()}, ensure_ascii=False, indent=2))
