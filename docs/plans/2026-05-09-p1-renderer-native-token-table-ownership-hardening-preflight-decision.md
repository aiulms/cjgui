# P1 内部渲染器 native token table ownership hardening 预检

日期：2026-05-09

状态：docs-only preflight / 选择 value boundary

## 目标

本轮评估 native token table 是否可以进入后续实现 runway。当前上游 [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md) 已固定 opaque token type、no-pointer token、token table mutability denial、issue / revoke deferred、revoke-without-destroy 与 main-thread gate preservation facts，但没有 token table、native token C ABI、native object 或 public API。

本预检不实现 token table，不修改 production native `.h` / `.m`，不修改 scripts，不修改 `runtime/cjgui/cjpm.toml`，不触碰 `runtime/cjgui/src/runtime_state.cj`。

## 证据判断

- token table 是后续 native resource bridge 的必需安全模型，但不是本轮实现对象；后续任何 native object / destroy / revoke 都需要 table ownership、generation / epoch 与 fail-closed 分类先固定。
- token table 若存在，应是 future production native bridge 私有 owner 的 bridge-local table，而不是 runtime renderer truth source，也不是 Objective-C truth source。
- token table 可以在未来被允许为受限可变状态，但必须 main-thread confined、bridge-private、带 generation / epoch，并由 runtime 只消费 dehydrated facts；本轮继续禁止实际 table、global mutable native table 和 module-level mutable runtime state。
- token 必须只表示 bridge-local opaque identifier，不得编码 native pointer，不得从 native pointer cast 得来，不得泄露到 public API。
- issue / revoke / destroy 必须分离。安全顺序应先 revoke token，再执行 future native destroy，再 invalidate table entry，最后 classify failure；当前只固定 ordering policy，不调用 destroy。
- double revoke、double destroy、dangling token、stale generation、wrong-thread token mutation 都必须 fail-closed，不得变成 recoverable public diagnostics。
- 当前证据足以进入 value boundary，但不足以实现 token table 或 native token callable。

## 候选结论

- A 采用：`P1 internal Renderer native token table ownership hardening value boundary bundle`。只新增 internal value owner，固定 token table ownership / mutability / generation / revoke ordering / failure classification，不实现 table。
- B 暂不采用：`P1 internal Renderer native token table implementation blocker follow-up`。table mutability 可被安全定义为 future bridge-private state，因此不需要先 blocker。
- C 暂缓：native token callable first implementation。没有 table ownership 前不应新增 issue / revoke callable。
- D 暂缓：teardown callable preflight。需要先把 revoke-before-destroy 与 dangling-token 分类固化。
- E 拒绝：actual token table / native object / pointer handle / public API / Metal / AppKit。

## 执行许可

本轮允许新增：

- `runtime/cjgui/src/runtime_renderer_native_token_table_ownership.cj`
- token table ownership hardening 的 closure、next-boundary、manifest 与 manifest closure。

本轮不允许：

- native token C ABI。
- token table implementation。
- production native `.h` / `.m` 修改。
- scripts 修改。
- `runtime/cjgui/cjpm.toml` 修改。
- public API / diagnostics。
- native object、native handle、raw pointer 或 native pointer return。
- retain / release / destroy。
- Metal / AppKit / Cocoa / QuartzCore。
- renderer state write 或 backend-ready truth。

## 同形边界刹车

不得把 token table ownership、token callable planning、main-thread query、token ownership manifest 或 smoke evidence 包装成 token table implementation permission、native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。Token table ownership hardening 只定义未来 token table 的安全边界，不证明 table exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，选择从 native token callable planning 进入 token table ownership hardening value boundary。
- 本轮是否改变 canonical tail / endpoint：预期改变，下一步将新增 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期改变，新增 owner 固定 table ownership policy、mutability confinement、generation / epoch invalidation、revoke-before-destroy 与 failure classification；stop-line 继续禁止 token table implementation、public API、native object、pointer handle、Metal / AppKit 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，先进入 `P1 internal Renderer native token table ownership hardening value boundary bundle`。
- 是否同步 topic manifest：是，后续 closure / manifest 同步。
- 已同步哪些 topic manifest：待 value boundary 与 manifest 完成后同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
