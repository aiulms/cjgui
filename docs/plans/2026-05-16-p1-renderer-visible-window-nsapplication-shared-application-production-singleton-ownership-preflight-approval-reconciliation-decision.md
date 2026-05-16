# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Approval Reconciliation 决策

状态：decision / docs-only / production ownership approval not granted

## 本轮裁定

本轮选择 B：

- B：把本轮输入裁定为 production singleton ownership approval
  reconciliation；保持 approval hold，不打开 production singleton ownership preflight，
  不实现 production owner，不新增 runtime owner / native C ABI / production call site。

本轮不选择 A：把“继续”解释为 production singleton ownership approval。

本轮不选择 C：把 isolated throwaway singleton creation evidence 升级为 production
singleton ownership truth。

## 输入消歧

当前工作树和 automation memory 已由
[automation stage report 36](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-automation-stage-report-36.md)
推进到：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`

本轮用户输入仍带有较早 opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`

但该 opening 已由
[actual accessor side-effect audit branch manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-manifest.md)、
[actual accessor call preflight guard manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-manifest.md)、
[isolated actual accessor call probe first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-first-slice-manifest.md)
和
[throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)
接续并封账。

本轮用户同时要求不得直接实现 actual accessor call，并要求保持
main-thread confined、isolated / probe-first、no activation、no activation policy
mutation、no AppKit event loop、no bounded pump、no visible order、no drawable、no
render、no artifact publication、no public API、no `runtime_state.cj` write 与 no
`cjpm.toml` change。该输入不是 production singleton ownership approval。

## 当前上游

- Canonical endpoint：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness`
- Default draft：
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft()`
- Runtime input：
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`
- 上游 manifest：
  [throwaway creation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-throwaway-creation-probe-first-slice-manifest.md)

## 本轮允许结论

- `classification=241` 只说明 isolated native probe 在无 preexisting singleton 时调用
  accessor 会创建 throwaway singleton。
- `production_singleton_ownership_truth=false` 仍保持。
- 本轮只关闭 approval ambiguity，不改变 canonical endpoint、default draft、runtime
  input、owner truth 或 stop-line。
- 若未来要打开 production singleton ownership preflight，必须另有明确人工批准，
  并先定义 ownership source、lifecycle / teardown owner、headless / CI fail-closed
  route 与 publication denial。

## 本轮不授权项

不 production singleton ownership；不把 throwaway singleton 暴露给 runtime truth；
不新增 production actual accessor call site；不新增 production native C ABI；不创建或持有
`NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现
bounded pump；不 visible order；不创建 `NSWindow` / `NSView` / `CAMetalLayer`；不获取
drawable；不创建 command queue / command buffer / encoder；不 draw；不 `commit` /
`present`；不提交 GPU work；不执行 render；不写 artifact；不发布 diagnostics；不写
renderer state；不新增 public API；不修改 `runtime/cjgui/cjpm.toml` 或
`runtime/cjgui/src/runtime_state.cj`。

## GitNexus 预检

`impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceReadiness --repo cangjie-live-codelattice`
与
`impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationThrowawayCreationProbeEvidenceDraft --repo cangjie-live-codelattice`
均返回 target not found、UNKNOWN、0 impacted。

该结果只说明 registry graph 未覆盖近期新增符号，不能作为安全证明；本轮继续依赖源码读取、
owner/native probes、build、forbidden scan、protected path scan 与 manifest reachability
兜底。

## 下一边界

当前唯一 next opening 保持：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`

该 opening 仍需要人工明确批准或拒绝 production singleton ownership preflight；自动化在批准前不得实现 production owner。

## 设计意图出口自检

- 本轮是否改变主题状态：是，新增 production singleton ownership approval reconciliation。
- 本轮是否改变 canonical endpoint：否。
- 本轮是否改变 owner / truth / stop-line：truth 新增 approval not granted fact；stop-line 不放宽。
- 本轮是否改变唯一 next opening：否，仍是 production singleton ownership preflight approval decision。
- 是否需要同步 topic manifest：是。
