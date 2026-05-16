# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Side-Effect Audit 分支收束与下一 Actual-Call Preflight 决策

状态：branch closure decision / docs-only / no actual accessor call

## 本轮裁定

本轮选择 A + C：

- A：actual accessor side-effect audit branch 可以封账。
- C：actual application singleton accessor call 继续 blocked；下一步只允许进入 actual-call preflight guard。

本轮不选择 actual application singleton accessor call first slice，也不选择继续新增同构 audit-ready / accessor-ready / application-ready wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`
- 上游 manifest：[actual accessor side-effect audit stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-stop-line-reconciliation-manifest.md)

## 分支确认

当前 actual accessor side-effect audit branch 已固定：

- actual accessor side-effect audit required。
- application singleton lifecycle side-effect risk classified。
- main-thread / headless / teardown / artifact diagnostics / rollback cleanup audit required。
- actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、actual AppKit event loop、bounded run-loop pump、actual teardown execution、artifact write、artifact publication、public diagnostics、native visible order、drawable、render、renderer state write、backend-ready truth、public API 与 public C ABI 均仍 blocked。
- no pointer / handle / `Class` / `id` return 保持不变。

这些 facts 足够封住当前 audit branch；继续包装同构 readiness 只会增加误读风险。

## 仍然缺失

当前缺口不是“再证明 audit required”，而是进入任何 future actual-call first slice 前必须先固定 preflight guard：

- first slice 必须 main-thread confined。
- first slice 必须 isolated / probe-first。
- first slice 不得 activation、不得 activation policy mutation。
- first slice 不得启动 AppKit event loop、不得 bounded pump。
- first slice 不得 visible order、drawable、render、artifact publication、public API、`runtime_state.cj` write 或 `cjpm.toml` change。
- preflight guard 不能把 audit facts 升级为 AppKit permission、backend-ready truth 或 public diagnostics publication。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard preflight decision`

该 opening 只允许判断是否新增 internal no-call preflight guard owner。它不是 actual application singleton accessor call implementation。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不调用 `makeKeyAndOrderFront` / `orderFront`；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 与拟新增 preflight guard endpoint 返回 target not found / UNKNOWN / 0 impacted。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与最终 `detect-changes` 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，actual accessor side-effect audit branch 从 stop-line reconciliation 转为 branch sealed。
- 本轮是否改变 canonical tail / endpoint：否，仍为 actual accessor side-effect audit readiness。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 branch closure 与 actual-call preflight guard 缺口结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 actual accessor call preflight guard preflight。
- 是否同步 topic manifest：是。
