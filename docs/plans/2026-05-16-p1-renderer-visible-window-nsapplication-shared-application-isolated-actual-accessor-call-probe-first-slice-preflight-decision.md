# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe First Slice 预检决策

状态：preflight decision / isolated native probe first slice / fail-closed no-create

## 本轮裁定

本轮选择 A：

- A：接受人工批准，打开 actual-call first slice，但只落在 isolated native probe / evidence owner 范围。

本轮不选择 B：把批准扩展为 production native bridge、runtime FFI、public API 或 production C ABI。

本轮不选择 C：允许 probe 为了观察 non-null result 而创建新的 `NSApplication` singleton。

## 批准范围

本轮用户明确批准 actual-call first slice，但约束为：

- 只在 isolated native probe 中承载 `NSApplication.sharedApplication` actual accessor call。
- 只观察 accessor 是否可调用、返回是否非空、main-thread gate 是否保持。
- 只返回整数分类与 dehydrated facts。
- 必须 fail-closed，并记录 side-effect classification。
- 不创建或激活 `NSApplication`。
- 不修改 activation policy。
- 不启动 AppKit event loop / bounded pump。
- 不创建 `NSWindow` / visible order / drawable / renderer resource。
- 不写 artifact / diagnostics publication。
- 不新增 public API 或 production public C ABI。
- 不修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 实现路线

本轮 first slice 只允许两个写集：

- Runtime internal evidence owner：[runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_isolated_actual_accessor_call_probe_evidence.cj)
- Isolated native probe：[verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_isolated_actual_accessor_call_probe.sh)

实际 `sharedApplication` call 只出现在 isolated native probe 临时 Objective-C 源内。Probe 先读取 preexisting `NSApp` global 和 main-thread gate；只有在 preexisting singleton 已存在时才调用 accessor。若 `NSApp == nil`，probe 不调用 accessor，直接返回 fail-closed classification。

## 当前 canonical 状态

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- 上游 manifest：[approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-manifest.md)

## Side-effect classification

本轮 automation 环境没有 preexisting `NSApplication` singleton，因此 probe 结果应为：

- `main_thread_gate_preserved=true`
- `preexisting_application_present=false`
- `accessor_call_attempted=false`
- `application_created=false`
- `classification=-240`
- `side_effect_classification=fail_closed_preexisting_application_missing`

该结果证明 no-create guard 生效；它不证明 accessor 在已有 singleton 场景下一定返回 non-null。若未来要观察 non-null accessor result，需要外部提供 preexisting app singleton，或另行人工批准 throwaway creation probe。

## GitNexus 预检

Impact 使用 production registry 和 positional target：

```bash
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft --repo cangjie-live-codelattice
node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness --repo cangjie-live-codelattice
```

结果均为 target not found / `UNKNOWN` / `0 impacted`。该结果只说明 graph 未覆盖近期新增 owner，不能作为安全证明；本轮必须继续用源码读取、owner probe、isolated native probe、build、forbidden scan 与 manifest/docs 检查兜底。

## Stop-line

不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不创建 `NSWindow`；不 visible order；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 artifact；不发布 diagnostics；不写 renderer state；不返回 Class / id / pointer / handle；不新增 public API 或 production C ABI；不修改 `runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 下一边界

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preexisting-application harness decision`

下一段只能判断如何处理 preexisting singleton 缺口；不能自动批准 singleton creation。

