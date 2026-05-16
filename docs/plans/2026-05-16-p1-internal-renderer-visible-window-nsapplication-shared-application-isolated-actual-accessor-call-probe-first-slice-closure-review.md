# P1 Internal Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe First Slice Closure Review

状态：closure review / implementation landed / isolated probe fail-closed

## 完成内容

本轮完成 actual-call first slice，但范围严格限制在 isolated probe / evidence owner：

- 新增 runtime internal evidence owner：[runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj)。
- 新增 isolated native probe：[verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)。
- 新增 owner verification probe：[verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence_owner.sh)。

## RED / GREEN

RED：新增 owner verification probe 后先运行，失败于缺少 evidence owner：

```text
missing owner runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj
```

GREEN：补齐 evidence owner 与 isolated native probe 后，owner probe 通过；`cjpm build --target-dir /tmp/cjgui-isolated-actual-accessor-call-probe-first-slice-build --skip-script` 通过。

## Probe evidence

Isolated native probe 在当前 automation 环境中返回：

```text
main_thread_gate_preserved=true
preexisting_application_present=false
accessor_call_attempted=false
application_created=false
classification=-240
side_effect_classification=fail_closed_preexisting_application_missing
integer_classification_only=true
dehydrated_facts_only=true
probe_success=true
```

该结果表示：probe 进入 main thread，发现没有 preexisting `NSApplication` singleton，因此没有调用 accessor，也没有创建 application。它是一个 no-create fail-closed pass，不是 non-null accessor result pass。

## Owner truth

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`

## 未越线项

- 没有修改 production native bridge header/source。
- 没有新增 production public C ABI。
- 没有新增 public Cangjie declaration。
- 没有修改 `runtime/cjgui/src/runtime_state.cj`。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有创建或激活 `NSApplication`。
- 没有修改 activation policy。
- 没有启动 AppKit event loop / bounded pump。
- 没有创建 `NSWindow`、drawable、encoder 或 renderer resource。
- 没有写 artifact / diagnostics publication。

## 设计意图出口自检

- 本轮改变主题状态：是，从 approval hold 推进到 isolated actual accessor call probe first slice。
- 本轮改变 canonical endpoint：是，新 endpoint 为 isolated actual accessor call probe evidence readiness。
- 本轮改变 stop-line：只打开 isolated native probe 内的 guarded actual accessor call site；no-create / no-activation / no-event-loop / no-public-surface stop-line 仍保持。
- 本轮改变唯一 next opening：是，转为 preexisting-application harness decision。
- Topic manifest 需要同步：是。

