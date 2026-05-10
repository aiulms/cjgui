# P1 内部渲染器 native token table no-resource shell 后续边界选择

日期：2026-05-10

状态：next-boundary / choose manifest stabilization

## 当前判断

`CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()` 足够作为当前 no-resource token table shell endpoint。

当前 endpoint 只代表 invalid token constant、disabled capacity、disabled table flag 与 token classification facts。它不是 issue / revoke permission，不是 mutable token table permission，不是 resource object table permission，不是 native object permission，也不是 public API 或 backend-ready truth。

## 候选结论

- A：`P1 internal Renderer native token table no-resource shell manifest stabilization bundle`
- B：`P1 internal Renderer native token table no-resource issue/revoke preflight decision`
- C：`P1 internal Renderer platform object native callable preflight decision`
- D：`P1 internal Renderer native bridge teardown callable implementation preflight decision`
- E 拒绝：resource object table / public API / Metal / AppKit

## 选择

选择 A。

理由：

- 本轮已经新增 production native callable、probe allowlist 与 runtime owner，需要先把 callable list、runtime endpoint、mutation stop-line 与 evidence chain 固定。
- issue / revoke 会引入 mutable token table、generation / epoch update、capacity allocation 与 stale token handling，必须在 manifest 封账后单独 preflight。
- platform object native callable 与 teardown callable implementation 都依赖 token issue / revoke 与 destroy ordering 进一步硬化，不能跳过当前 manifest。

## 后续入口

manifest stabilization 完成后，唯一后续入口建议为：

`P1 internal Renderer native token table no-resource issue/revoke preflight decision`

该入口只能评估 no-resource issue / revoke shell 是否可在 fixed capacity、generation / epoch、fail-closed、main-thread confinement 与 no resource binding 下实现；不得直接进入 resource object table、native object、pointer handle、public API、Metal / AppKit 或 backend-ready truth。

## 同形边界刹车

不得把 token table shell、token classification、capacity facts、token ownership hardening 或 smoke evidence 包装成 resource table permission、native handle permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，选择进入 token table shell manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，确认 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 token shell classification facts；stop-line 继续禁止 issue / revoke、resource table、native object、pointer、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，manifest 后建议转为 `P1 internal Renderer native token table no-resource issue/revoke preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
