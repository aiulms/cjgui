# P1 内部渲染器 native bridge teardown callable implementation 后续边界

日期：2026-05-10

状态：next-boundary / docs-only

## 当前结论

no-resource teardown admission callable 与 internal owner 已实现并通过阶段 probe / build。当前应选择：

`P1 internal Renderer native bridge teardown callable implementation manifest stabilization bundle`

manifest stabilization 完成后，唯一后续入口建议转为：

`P1 internal Renderer platform object AppKit import preflight decision`

## 选择理由

- 已有 teardown admission callable list 足够表达 destroy path 的 fail-closed classification。
- Runtime owner 已能在 internal-only 范围调用 teardown admission / not-supported / revoke-before-destroy-required / double-destroy classification C ABI。
- 该实现没有 actual destroy、retain / release、native object binding、pointer / handle return、public API、renderer state write 或 AppKit / Metal resource。
- 下一步若靠近 platform object creation，必须先单独评估 AppKit import、main-thread gate、token issue/revoke、teardown admission 与 resource creation stop-line，不能由本轮直接越线。

## 暂缓与拒绝

- 暂缓：`P1 internal Renderer platform object AppKit import preflight decision`，必须在 manifest 封账后单独开。
- 暂缓：`P1 internal Renderer platform object no-object admission callable first implementation preflight decision`，因为本轮目标已经完成 teardown admission，不继续扩 write set。
- 拒绝：actual destroy / retain / release。
- 拒绝：native object / pointer handle。
- 拒绝：public API / public diagnostics。
- 拒绝：Metal / AppKit object creation。
- 拒绝：backend-ready truth / renderer state write。

## 同形边界刹车

本轮不得把 teardown admission callable、token issue/revoke、platform object native callable admission 或 smoke evidence 包装成 actual destroy permission、native object permission、resource creation permission、native handle permission、AppKit / Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。No-resource teardown callable 只证明 destroy path 的 fail-closed classification，不证明 resource destroyed。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable implementation 已进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 是 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_native_bridge_teardown_admission_call.cj`；truth 为 no-resource teardown admission classification facts；stop-line 禁止 actual destroy / native object / public API。
- 本轮是否改变唯一 next opening：是，短线进入 manifest stabilization，manifest 后转为 `P1 internal Renderer platform object AppKit import preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
