#!/usr/bin/env python3
"""thermo 页面（ArkTS 薄壳）恢复就绪规则的离线形状反例。

为什么需要这一套：`entry/src/main/ets/pages/Index.ets` 里「落点安装」的就绪判据
此前**没有任何离线消费者**（scripts 下无一读取该文件），于是同一类缺陷反复回到
生产：读数相等就当已安装、`setTimeout(250)` 用时间代替绑定、组件复用时控制器绑在
空对象上。设备一轮只能告出「哪条腿红了」，改完是否真的不再靠时间/相等求绿，必须有
能在合码前跑的门。

判据只钉**机制形状**（就绪事实必须是共享生命周期的 attach；相等读数不得独立成证；
代理控件的结构性身份必须是挂载键），不钉文案、不钉时长。每条都用变异反例证明它真的
有判别力：把生产改回旧写法，对应断言必须红。
"""
import re
import unittest

from pathlib import Path

PAGE = Path('/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_thermo_app/'
            'entry/src/main/ets/pages/Index.ets')


def source() -> str:
    return PAGE.read_text(encoding='utf-8')


def block_around(text: str, anchor: str, back: int = 900, fwd: int = 700) -> str:
    """锚点所在的可读窗口。锚点缺失即视为判据不成立（调用方断言非空）。"""
    at = text.find(anchor)
    if at < 0:
        return ''
    return text[max(0, at - back):at + fwd]


def function_body(text: str, signature: str) -> str:
    """类成员函数的**本体**（到下一个同级 `private ` 为止）。

    为什么不用固定窗口：就绪门与紧随其后的 `observeSelection` 含**字面相同**的过期
    判据，按字符窗口取体会把邻居读进来——变异掉门里的判据后，邻居那份仍让断言通过，
    负控就成了假绿（本轮实测踩到）。函数边界才是唯一诚实的截取依据。
    """
    at = text.find(signature)
    if at < 0:
        return ''
    nxt = text.find('\n  private ', at + len(signature))
    end = len(text) if nxt < 0 else nxt
    # 连同签名行一起返回：签名本身也是被审判的形状（名字/入参）。
    return text[at:end]


def replace_in_function(text: str, signature: str, old: str, new: str) -> str:
    """只在目标函数体内替换，保证变异落在被审判的那一处、不是同形邻居。"""
    at = text.find(signature)
    assert at >= 0, f'function missing: {signature}'
    body = function_body(text, signature)
    assert old in body, f'mutation target missing in {signature}: {old}'
    start = text.index(body)
    return text[:start] + body.replace(old, new, 1) + text[start + len(body):]


class ThermoArktsRestoreReadinessTest(unittest.TestCase):
    # 变异前后整份页面相差无几，diff 全量打印会把日志撑爆（一轮实测 140KB+）。
    maxDiff = 200

    # ---- 判据本体（text 参数化，便于变异复用同一套判定） ----

    def _assert_attach_gated_equal_read(self, text: str) -> None:
        """相等读数短路必须与**该挂载的 attach 事实**同乘。

        未 attach 时 `getSelection()` 读到残留或默认 (0,0) 也能与目标相等，据此 ACK
        true 就是把「没有观测」当成「已安装」——本轮 ctx=3 的八张票正是从这里来的。
        """
        guard = block_around(text, 'ime restore already installed')
        self.assertIn(anchor := 'ime restore already installed', text,
                      'equality short-circuit vanished: judgement unreachable')
        self.assertIn('isAttachedTo(mount)', guard,
                      'equal selection read ACKs without the mount attach fact')
        # 相等条件仍须在（不是靠删掉短路的另一半来「修」）。
        self.assertRegex(guard, r'observedStart\s*===\s*start\s*&&\s*observedEnd\s*===\s*end',
                         'equality pair removed instead of gated')

    def _assert_no_duration_wait_for_install(self, text: str) -> None:
        """无正文恢复的安装入口必须走就绪门，不得由固定时长决定。"""
        self.assertNotIn('}, 250)', text,
                         'fixed 250ms wait still decides when to install the caret')
        self.assertIn('this.installSelectionWhenAttached(task);', text,
                      'restore install path is not behind the readiness gate')

    def _assert_readiness_gate_body(self, text: str) -> None:
        """就绪门本体：过期任务不再抢装、attach 达成才安装、否则按生命周期重探。"""
        body = function_body(text, 'private installSelectionWhenAttached(')
        self.assertTrue(body, 'installSelectionWhenAttached is gone')
        self.assertIn('task.terminal', body, 'gate ignores task terminality (stale install)')
        self.assertIn('this.proxyRestoreTask !== task', body,
                      'gate does not verify the task is still the active one')
        self.assertIn('this.proxyRegistry.isCurrent(task.mount)', body,
                      'gate does not verify the mount is still current')
        self.assertIn('isAttachedTo(task.mount)', body,
                      'gate installs without the attach fact')
        at_attach = body.find('isAttachedTo(task.mount)')
        at_install = body.find('this.beginSelectionPhase(task);')
        self.assertTrue(0 <= at_attach < at_install,
                        'beginSelectionPhase is not gated by attach (order inverted)')
        self.assertIn('setTimeout((): void => this.installSelectionWhenAttached(task)', body,
                      'readiness is never re-polled: a single check is a time wait in disguise')

    def _assert_proxy_structural_identity(self, text: str) -> None:
        """代理 TextInput 的 ForEach 键必须是挂载结构身份：键变即销毁重建，新节点在
        **构造**时绑定当前 controller。复用同一可空挂载会让新控制器绑在一个没有对应
        节点的 id 上（`Request focus id can not found` / `JSTextEditableController is NULL`）。"""
        build = block_around(text, 'ForEach(this.liveProxyMounts()', back=120, fwd=600)
        self.assertTrue(build, 'proxy TextInput is no longer a keyed ForEach')
        self.assertIn('this.liveProxyMounts()', build, 'ForEach source is not the derived list')
        self.assertIn('m.key.describe()', build, 'ForEach key is not the mount structural identity')
        self.assertIn('if (this.imeCtx !== 0)', text,
                      'build block no longer opens on the editing context')

    # ---- 正控：生产原文必须同时满足四条 ----

    def test_production_page_satisfies_all_readiness_rules(self) -> None:
        text = source()
        self._assert_attach_gated_equal_read(text)
        self._assert_no_duration_wait_for_install(text)
        self._assert_readiness_gate_body(text)
        self._assert_proxy_structural_identity(text)

    # ---- 变异反例：改回旧写法，对应判据必须红 ----

    def _assert_mutation_detected(self, mutate, assertion) -> None:
        mutated = mutate(source())
        self.assertNotEqual(mutated, source(), 'mutation did not apply (stale anchor)')
        with self.assertRaises(AssertionError):
            assertion(mutated)

    def test_equality_without_attach_is_detected(self) -> None:
        def mutate(text: str) -> str:
            return text.replace('observedStart === start && observedEnd === end &&\n'
                                 '        this.selectionLifecycle.isAttachedTo(mount)',
                                 'observedStart === start && observedEnd === end', 1)
        self._assert_mutation_detected(mutate, self._assert_attach_gated_equal_read)

    def test_duration_wait_install_is_detected(self) -> None:
        def mutate(text: str) -> str:
            return text.replace('this.installSelectionWhenAttached(task);',
                                 'setTimeout(() => {\n'
                                 '      this.beginSelectionPhase(task);\n'
                                 '    }, 250);', 1)
        self._assert_mutation_detected(mutate, self._assert_no_duration_wait_for_install)

    def test_gate_installing_without_attach_is_detected(self) -> None:
        def mutate(text: str) -> str:
            return text.replace('if (this.selectionLifecycle.isAttachedTo(task.mount)) {',
                                'if (true) {', 1)
        self._assert_mutation_detected(mutate, self._assert_readiness_gate_body)

    def test_gate_ignoring_expiry_is_detected(self) -> None:
        def mutate(text: str) -> str:
            return replace_in_function(
                text, 'private installSelectionWhenAttached(',
                'task.terminal || this.proxyRestoreTask !== task ||\n'
                "      !this.proxyRegistry.isCurrent(task.mount)",
                'false')
        self._assert_mutation_detected(mutate, self._assert_readiness_gate_body)

    def test_reused_nullable_mount_is_detected(self) -> None:
        def mutate(text: str) -> str:
            return text.replace(
                'ForEach(this.liveProxyMounts(), (m: CjguiTextProxyMount) => {\n'
                '          this.proxyTextInput(m)\n'
                '        }, (m: CjguiTextProxyMount) => m.key.describe())',
                'if (this.imeMount !== null) {\n'
                '          this.proxyTextInput(this.imeMount)\n'
                '        }', 1)
        self._assert_mutation_detected(mutate, self._assert_proxy_structural_identity)

    # ---- 反回归：本轮明确保留的机制不得被「顺手清理」掉 ----

    def test_preserved_mechanisms_are_still_declared(self) -> None:
        text = source()
        # 共享生命周期仍是 attach 的唯一置位者；页面不得自建 attach 事实。
        self.assertIn('this.selectionLifecycle.requestAttach(', text,
                      'page no longer routes attach through the shared lifecycle')
        self.assertIn('this.selectionLifecycle.invalidateAttachmentFor(', text,
                      'retired mounts no longer invalidate the attachment fact')
        # 恢复事务的具名让位仍在（撤掉它会把接管变成无声清槽）。
        self.assertIn("'restore_task_took_over'", text)
        self.assertRegex(text, r'armRestoreDeadline\(task,\s*1500\)')

    def test_hap_mirror_of_thermostat_controller_is_identical(self) -> None:
        """HAP 编译的是 `entry/thermostat_application/` 这份**镜像**，不是 examples。

        真实踩过的坑：`sync_platform.sh` 同步 `entry/cjgui`（框架）却**不同步**
        `entry/thermostat_application`（示例产品）。只改 examples 时设备侧编出来的
        还是没有新方法的旧控制器，构建直接报 `… is not a member of class`。
        镜像与源必须逐字节相同，否则本轮的采纳事实消费者根本没进包。
        """
        example = Path('/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/'
                       'thermostat_application/src/thermostat_app.cj')
        mirrored = Path('/Users/jiangxuanyang/Desktop/cangjie/labs/ohos_thermo_app/'
                        'entry/thermostat_application/src/thermostat_app.cj')
        self.assertEqual(example.read_text(encoding='utf-8'),
                         mirrored.read_text(encoding='utf-8'),
                         'HAP thermostat mirror diverged from examples source')


if __name__ == '__main__':
    unittest.main(verbosity=2)
