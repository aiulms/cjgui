# P1 Internal Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe Approval Reconciliation Manifest Stabilization Closure Review

状态：manifest stabilization closure / docs-only / no runtime truth expansion

## 封账结论

Approval reconciliation manifest 已稳定：

- manifest 链接到 decision、closure、next-boundary 与上游 isolated probe preflight manifest。
- 当前 canonical endpoint、default draft 与 runtime input 保持不变。
- stop-line 未放宽。
- 当前唯一 next opening 仍是 explicit human approval decision。
- automation blocker 仍为 true，因为 actual-call first slice 未获人工明确批准。

## 本轮未改变的内容

- 未新增 runtime owner。
- 未新增 native C ABI。
- 未新增 probe 或 package route。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API。
- 未执行 actual application singleton accessor call。

## 出口自检

- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifests 应指向 [approval reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-approval-reconciliation-manifest.md)。
- `runtime/cjgui/src/runtime_state.cj` 行数必须保持 10065。
- Public declaration scan 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Protected path scan 必须确认 `runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 无 diff。

## 下一边界

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe explicit human approval decision`

该 next opening 需要人工明确批准或拒绝 actual-call first slice；自动化仍不得把“继续”或 docs-only reconciliation 解释为 actual-call approval。
