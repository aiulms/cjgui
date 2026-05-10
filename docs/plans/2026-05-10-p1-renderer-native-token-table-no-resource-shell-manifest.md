# P1 内部渲染器 native token table no-resource shell 清单

日期：2026-05-10

状态：manifest stabilization / classification shell

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`
- Endpoint：`CjguiInternalRendererNoNativeTokenTableShellReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`
- Actual route：classification shell
- Native token table：无 mutable table
- Native resource binding：无

## native callable list

本轮固定四个 no-resource token shell callable：

- `cjgui_native_bridge_token_invalid(void)`
- `cjgui_native_bridge_token_table_capacity(void)`
- `cjgui_native_bridge_token_table_enabled(void)`
- `cjgui_native_bridge_token_classify(uint64_t token)`

这些 callable 只返回 deterministic integer facts，不返回 pointer，不返回 native handle，不创建 object，不 mutate table。

## table capacity policy

first slice capacity 固定为 `0`。这表示当前只是 disabled classification shell，没有 slot allocation、没有 table entry、没有 issue / revoke，也没有 resource binding。

capacity exhausted / disabled table 后续必须 fail-closed；本轮不暴露 public diagnostics。

## token invalid policy

invalid token constant 固定为 `0`。它不是 native pointer，不编码 raw pointer，不编码 native object identity，也不代表 public token surface。

`cjgui_native_bridge_token_classify(0)` 返回 invalid classification。nonzero token 在当前 disabled shell 中返回 disabled / unsupported classification。

## classification policy

classification facts 只用于 internal verification：

- invalid token observed。
- zero capacity observed。
- table disabled observed。
- invalid classification observed。
- nonzero token disabled classification observed。

这些 facts 不说明 token exists，不说明 table exists，不说明 resource exists。

## mutation policy

本轮明确没有：

- issue callable。
- revoke callable。
- mutable native token table。
- generation / epoch mutation。
- slot allocation。
- token reuse。
- resource object table。
- native object binding。

后续 issue / revoke 必须先进入独立 preflight。

## probe scripts

已同步的 probes：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh`

probe 只验证 symbol / compile / temporary link / observed facts，不修改 `runtime/cjgui/cjpm.toml`，不接入 production `.m` 到主包，不创建 resource。

isolated FFI probe 的本轮变更只同步 token shell callable allowlist，并继续禁止 issue / revoke、resource callable、native object 与 pointer 行为。

## runtime facts

Default draft 产出：

- `didConfirmInvalidTokenObserved`
- `didConfirmTableCapacityObserved`
- `didConfirmTableDisabledObserved`
- `didConfirmTokenClassificationObserved`
- `didConfirmNoIssueRevokeCallable`
- `didConfirmNoMutableTokenTable`
- `didConfirmNoResourceBinding`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoNativeObjectHandleOrPointer`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 no-resource token table shell classification 已可内部验证。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- Production native `.h/.m` 只新增 no-resource token shell callable。
- Smoke native files 未修改。
- Production `.m` 仍未正式接入 `runtime/cjgui` 主包 package config。
- Temporary package probes 仍是 script-managed verification route。

## 停止线

- no issue / revoke。
- no mutable native token table。
- no global mutable native table。
- no resource object table。
- no native object binding。
- no raw pointer storage。
- no native pointer return。
- no native handle return。
- no token-as-pointer。
- no public API / diagnostics。
- no resource callable。
- no smoke native edits。
- no `runtime/cjgui/cjpm.toml` mutation。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 证据链

- [native token table no-resource shell preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-first-implementation-preflight-decision.md)
- [native token table no-resource shell closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-token-table-no-resource-shell-first-implementation-closure-review.md)
- [native token table no-resource shell next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-first-implementation-next-boundary-decision.md)
- [native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md)
- [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md)
- [native token table no-resource issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md)
- [native bridge main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md)

## 后续入口

唯一后续入口：

已由 `P1 internal Renderer native token table no-resource issue/revoke preflight decision` 接续；当前全局后续入口转为 `P1 internal Renderer platform object native callable preflight decision`。

该入口只能评估 no-resource issue / revoke shell 是否可在 fixed capacity、generation / epoch、fail-closed、main-thread confinement 与 no resource binding 下实现；不得直接进入 resource object table、native object、pointer handle、public API、Metal / AppKit 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table no-resource shell 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_shell.cj`；truth 固定为 invalid / capacity / enabled / classification observed facts；stop-line 继续禁止 issue / revoke、mutable table、resource table、native object、pointer、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource issue/revoke preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
