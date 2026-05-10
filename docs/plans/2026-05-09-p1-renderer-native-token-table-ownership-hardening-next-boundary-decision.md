# P1 内部渲染器 native token table ownership hardening 后续边界选择

日期：2026-05-09

状态：docs-only next-boundary / 选择 manifest stabilization

## 当前判断

`CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()` 足够作为当前 no-native-token-table-ownership endpoint。

它补齐了 native token callable planning 后缺失的 table ownership 安全边界：

- table 若未来存在，只能是 bridge-local / bridge-private。
- token 不得编码 native pointer。
- table mutability 不得成为 renderer truth source。
- generation / epoch 与 invalidation 必须先于 token 复用。
- revoke / destroy 必须分离，并保持 revoke-before-destroy。
- double-revoke、double-destroy、dangling-token、wrong-thread mutation 必须 fail-closed。

当前仍没有 actual token table、native token C ABI、native object、native handle、raw pointer、public API、resource callable、Metal / AppKit 或 backend-ready truth。

## 候选结论

- A 采用：`P1 internal Renderer native token table ownership hardening manifest stabilization bundle`。当前 owner / endpoint / stop-line 足以封账，应先固定 manifest。
- B 暂缓：`P1 internal Renderer native bridge teardown callable preflight decision`。该入口应在 manifest 封账后作为唯一后续入口。
- C 暂缓：`P1 internal Renderer native token callable first implementation preflight decision`。没有 actual table 实现前不新增 issue / revoke callable。
- D 拒绝：actual token table / public API / native object / Metal / AppKit。

## 后续入口

下一步先进入：

`P1 internal Renderer native token table ownership hardening manifest stabilization bundle`

Manifest 封账后唯一后续入口建议为：

`P1 internal Renderer native bridge teardown callable preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，token table ownership hardening value boundary 已可进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，继续使用 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，owner / truth / stop-line 与 value boundary closure 一致。
- 本轮是否改变唯一 next opening：是，转入 `P1 internal Renderer native token table ownership hardening manifest stabilization bundle`。
- 是否同步 topic manifest：是，manifest 阶段统一同步。
- 已同步哪些 topic manifest：待 manifest stabilization 同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
