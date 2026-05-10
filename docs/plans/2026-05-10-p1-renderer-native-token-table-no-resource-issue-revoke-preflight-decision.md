# P1 内部渲染器 native token table no-resource issue/revoke 预检

日期：2026-05-10

状态：preflight / implementation runway opened

## 读取结论

已读取设计意图索引、三个 topic manifest、设计意图出口协议、native token table no-resource shell manifest / closure、native token table implementation manifest、native token table ownership hardening manifest、native resource creation admission manifest、`runtime_renderer_native_token_table_shell.cj`、`runtime_renderer_native_token_table_implementation.cj`、production native bridge `.h/.m` 与相关 probe scripts。

上游当前 tail 是 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。它已经证明 invalid token、zero capacity、table disabled 与 classification observed facts，但明确未实现 issue / revoke，也未创建 mutable token table。

## 判断

本轮可以打开 no-resource issue / revoke first implementation runway，前提是第一刀严格采用 fixed-capacity bridge-local table，并保持以下条件：

- issue 只分配 opaque token，不绑定 native resource。
- revoke 只撤销 token，不执行 native object release / lifecycle teardown。
- token encoding 只能包含 slot 与 generation / epoch，不包含 pointer bits。
- table entry 只能保存 active flag 与 generation facts，不保存 raw pointer、native handle 或 object identity。
- table 容量固定，capacity exhausted 必须返回 invalid token / fail-closed facts。
- issue / revoke 必须通过 main-thread gate；classify 可在 mutex 保护下读取 dehydrated token facts。
- double revoke、invalid token、stale generation 与 malformed slot 必须 fail-closed。
- runtime owner 只把 issue / classify / revoke sequence 脱水成 internal facts，不 public、不写 state。

## 候选选择

选择 A：`P1 internal Renderer native token table no-resource issue/revoke first implementation bundle`。

选择理由：

- 当前 shell 已固定 token invalid / capacity / classify C ABI。
- ownership hardening 已固定 bridge-local opaque table、generation / epoch、main-thread confinement、fail-closed failure classification。
- resource creation admission 已明确 future resource creation 仍需 token table 与 teardown 前置，但本轮不创建资源。
- fixed-capacity table 可以只保存 integer facts，避免 pointer / native object / renderer truth source。
- `pthread_mutex` 是实现 table mutation 的最小并发保护，不引入 AppKit / Metal / Foundation。

不选择 B：当前无需 blocker，因为 no-resource fixed-capacity shell 可以不绑定资源完成。

不选择 C：并发策略可先限制为 main-thread mutation + mutex read/write，不需要先开复杂 concurrency hardening。

不选择 D：本轮不进入 resource object table、pointer handle、public API、Metal / AppKit。

## 实现准入

本轮允许新增 / 修改：

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- token / no-resource native probe scripts
- `runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`
- docs / README / topic manifests

默认不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不修改 `runtime_state.cj`。

## 停止线

- no resource object table。
- no native object binding。
- no raw pointer storage。
- no native pointer / handle return。
- no token-as-pointer encoding。
- no retain / release / destroy。
- no public API / diagnostics。
- no renderer state write。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no backend-ready truth。

## GitNexus 记录

编辑 runtime symbol 前运行 impact：

- `CjguiInternalRendererNoNativeTokenTableShellReadiness`：`UNKNOWN / not found`，affected 0。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft`：`UNKNOWN / not found`，affected 0。

编辑 native symbol 前运行 impact：

- `cjgui_native_bridge_token_classify`：`UNKNOWN / not found`，affected 0。
- `cjgui_native_bridge_token_table_capacity`：`UNKNOWN / not found`，affected 0。
- `cjgui_native_bridge_token_table_enabled`：`UNKNOWN / not found`，affected 0。
- `cjgui_native_bridge_surface_capabilities`：`UNKNOWN / not found`，affected 0。

按近期新增 owner / native surface 未索引处理；继续用源码、build、probe 与 forbidden scan 兜底。未忽略 HIGH / CRITICAL 风险。

## 同形边界刹车

不得把 issue / revoke token、token table shell、capacity facts、token ownership hardening 或 smoke evidence 包装成 resource table permission、native handle permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。No-resource issue / revoke 只证明 bridge-local opaque token mechanics，不证明 resource exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，打开 no-resource issue / revoke first implementation runway。
- 本轮是否改变 canonical tail / endpoint：预检后将尝试新增 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，若实现成功将新增 issue / revoke owner；truth 仍限 no-resource token mechanics。
- 本轮是否改变唯一 next opening：预期转为 `P1 internal Renderer platform object native callable preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 后同步。
- 已同步哪些 topic manifest：待本轮完成后同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
