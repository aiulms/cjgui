# P1 内部渲染器 native token table no-resource issue/revoke 首切复核

## 本轮结论

本轮按 preflight 选择 A，完成 no-resource issue/revoke 首切。production native bridge 只新增 bridge-local opaque token 的 issue / revoke callable，不绑定任何 native object，不保存 raw pointer，不返回 native pointer，也不执行 destroy / retain / release。

新增 runtime owner 为 `runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`。该 owner 只消费 `CjguiInternalRendererNoNativeTokenTableShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。

## 实际写集

- 修改 `runtime/cjgui/native/cjgui_native_bridge.h`：新增 fixed-capacity token table constants、issue/revoke capability bit、issue/revoke declarations 与 fail-closed classification constants。
- 修改 `runtime/cjgui/native/cjgui_native_bridge.m`：新增 fixed-capacity no-resource token table shell、slot + generation token encoding、main-thread issue/revoke guard、issue / classify / revoke / double revoke fail-closed behavior。
- 修改 native probe scripts：更新 no-resource callable allowlist，并让 package-adjacent / temporary `cjpm` probes 观察 issue -> classify valid -> revoke -> classify stale -> double revoke stale sequence。
- 新增 `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`：专门验证 issue/revoke sequence，不修改 source 或 build config。
- 新增 `runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`：把 issue/revoke/classify 返回值脱水为 internal facts。

## 固定语义

- token 是 `uint64_t` opaque token，编码仅包含 slot + generation，不包含 pointer bits。
- table 是 fixed capacity，当前 capacity 为 `8`。
- issue 只分配 token，不绑定 resource。
- revoke 只撤销 token，不执行 destroy。
- stale / invalid / double revoke 都 fail-closed。
- runtime owner 只产出 internal dehydrated facts，不发布 public API，不写 renderer state。

## 保持边界

本轮没有修改 `runtime/cjgui/cjpm.toml`，没有修改 smoke native files，没有新增 public API / diagnostics，没有创建 resource object table，没有绑定 native object，没有保存 raw pointer，没有返回 native pointer / handle，没有导入 Cocoa / Metal / QuartzCore，没有触碰 `runtime_state.cj`。

Same-shape Boundary Brake：no-resource issue/revoke 只证明 bridge-local opaque token mechanics，不证明 resource exists、native handle permission、native object permission、Metal/AppKit permission、backend-ready truth、public API permission、receipt / record / publication。

## 验证记录

- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh` 已观察 capacity / table enabled / invalid token / issue / revoke / double revoke。
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh` 已观察 token shell owner 与 issue/revoke owner source，并通过 temporary `cjpm` package 观察 issue/revoke sequence。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-token-table-issue-revoke-target --skip-script` 已通过，现存 warnings 为历史 unused warnings。

完整最终验证仍以本轮统一汇总为准。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table no-resource issue/revoke 从 preflight 推进到首切实现。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 issue/revoke owner，truth 扩展到 fixed-capacity opaque token issue/revoke facts；stop-line 仍禁止 resource binding、native object、pointer、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：将转为 manifest stabilization 后的 `P1 internal Renderer platform object native callable preflight decision`。
- 是否同步 topic manifest：是，本轮需同步 renderer implementation admission chain、backend readiness runway 与 macOS bridge smoke topic manifest。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
