# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Call Preflight Guard 分支收束与下一隔离探针决策

状态：branch closure decision / docs-only / no actual accessor call

## 本轮裁定

本轮选择 A + B：

- A：actual accessor call preflight guard branch 可以封账。
- B：后续只允许打开 isolated actual accessor call probe preflight discussion。

本轮不选择 actual application singleton accessor call implementation，也不继续新增同构 no-call guard wrapper。

## 当前上游

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- 上游 manifest：[actual accessor call preflight guard stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-call-preflight-guard-stop-line-reconciliation-manifest.md)

## 分支确认

当前 preflight guard branch 已经固定：

- actual accessor side-effect audit readiness preserved。
- actual-call first slice explicit approval missing。
- main-thread confined preflight required。
- isolated / probe-first route required。
- no activation policy mutation。
- no application activation。
- no AppKit event loop。
- no bounded run-loop pump。
- no visible order。
- no drawable。
- no render。
- no artifact publication。
- no public API。
- no `runtime_state.cj` write。
- no `cjpm.toml` change。
- actual application singleton accessor call still blocked。
- no pointer / handle / `Class` / `id` return。
- no public C ABI、no renderer state write、no backend-ready truth。

这些 facts 足够封住当前 no-call preflight guard branch；继续包装同构 no-call readiness 不会解除 actual accessor call 的真实 blocker。

## 下一缺口

当前缺口不是“再证明 actual accessor call 被阻塞”，而是未来如果讨论 isolated actual accessor call probe，必须先独立预检：

- main-thread confinement 是否可被局部化证明。
- probe 是否能保持 isolated / probe-first。
- 是否严格禁止 activation、activation policy mutation、AppKit event loop、bounded pump、visible order、drawable、render 与 artifact publication。
- 是否保持 no public API、no public C ABI、no `runtime_state.cj` write 与 no `cjpm.toml` change。
- 是否能在失败时 fail closed，不产生 runtime truth、backend-ready truth 或 public diagnostics。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preflight decision`

该 opening 只能判断是否允许一个极窄 isolated probe preflight；它仍不是 actual accessor call implementation。

## 停止线

不调用 application singleton accessor；不创建 `NSApplication`；不 activation；不修改 activation policy；不运行 AppKit event loop；不实现 bounded pump；不执行 actual teardown；不写 artifact；不发布 diagnostics；不做 native visible order implementation；不获取 drawable；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API / public C ABI；不新增 public diagnostics；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，actual accessor call preflight guard branch 从 stop-line reconciliation 转为 branch sealed。
- 本轮是否改变 canonical endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是，truth 新增 branch closure 与 isolated probe preflight gap 结论；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，转为 isolated actual accessor call probe preflight decision。
- 是否同步 topic manifest：是。
