# P1 内部渲染器 native token table no-resource issue/revoke 后续边界选择

## 当前证据

no-resource issue/revoke 首切已经完成。证据链包括 fixed-capacity native token table shell、slot + generation token encoding、issue -> classify valid -> revoke -> classify stale -> double revoke stale sequence、runtime owner dehydrated facts、package-adjacent probe、temporary `cjpm` package probe 与主包 `cjpm build --skip-script`。

当前 owner 是 `runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`，canonical endpoint 是 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。

## 候选判断

选择 A：`P1 internal Renderer native token table no-resource issue/revoke manifest stabilization bundle`。

理由：

- issue/revoke 已经满足 no-resource、no-pointer、fixed-capacity、generation invalidation、double revoke fail-closed 与 no public API 边界。
- 当前证据足够封账，但仍不授权 platform object 或 resource object creation。
- 进入 platform object native callable 前，应先以 manifest 固定 callable list、token encoding、failure classification 与 stop-line。

暂缓 B：`P1 internal Renderer platform object native callable preflight decision`。

该入口只能在 manifest stabilization 后打开，并且仍必须先做 preflight。

暂缓 C：`P1 internal Renderer native bridge teardown callable implementation preflight decision`。

当前 revoke 不是 destroy，不执行 retain / release / destroy。真实 teardown callable 仍需独立 preflight。

暂缓 D：`P1 internal Renderer native token table concurrency hardening preflight decision`。

当前首切使用 main-thread guard + fixed-capacity mutex-protected table；复杂并发 hardening 不是本轮目标。

拒绝 E：resource object table / public API / Metal/AppKit。

本轮 issue/revoke 不得被解释为 resource object table、native object、native handle、raw pointer、public API、Metal/AppKit 或 backend-ready truth permission。

## 后续入口

当前选择 manifest stabilization。完成 manifest 后，唯一后续入口建议为：

`P1 internal Renderer platform object native callable preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，issue/revoke 首切进入后续边界选择。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 确认为 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_native_token_table_issue_revoke.cj`，truth 为 no-resource issue/revoke dehydrated facts；stop-line 保持 no resource binding / no pointer / no public / no renderer state write。
- 本轮是否改变唯一 next opening：是，先进入 manifest stabilization，manifest 后建议 `P1 internal Renderer platform object native callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
