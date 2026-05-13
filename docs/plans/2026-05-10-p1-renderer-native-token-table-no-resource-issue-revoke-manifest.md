# P1 内部渲染器 native token table no-resource issue/revoke 清单

## 清单结论

native token table no-resource issue/revoke stage 已封账。当前实现只建立 bridge-local opaque token mechanics，不创建 resource object table，不绑定 native object，不保存 raw pointer，不返回 native pointer / handle，不新增 public API，不写 renderer state。

## Native callable list

- `cjgui_native_bridge_token_invalid(void)` -> `uint64_t`
- `cjgui_native_bridge_token_table_capacity(void)` -> `uint32_t`
- `cjgui_native_bridge_token_table_enabled(void)` -> `uint32_t`
- `cjgui_native_bridge_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_token_issue(void)` -> `uint64_t`
- `cjgui_native_bridge_token_revoke(uint64_t token)` -> `int32_t`

## Token encoding policy

- token type 是 `uint64_t`。
- token 编码只包含 slot + generation。
- token 不包含 native pointer bits。
- invalid token 固定为 `0`。
- fixed capacity 当前为 `8`。
- generation 用于 revoke 后失效旧 token，避免 dangling token 被重新解释为 valid。

## Issue / revoke / classify 语义

- issue：只分配 opaque token，不绑定 resource，不创建 native object。
- classify：只读取 token table shell state，返回 valid / invalid / stale / fail-closed classification。
- revoke：只撤销 token table entry，不执行 destroy，不调用 retain / release。
- double revoke：返回 stale classification。
- invalid token：返回 invalid classification。
- capacity exhausted：fail-closed 返回 invalid token 或对应 failure classification。

## Runtime owner

- Owner file：`runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableShellReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`
- Truth：fixed-capacity issue/revoke/classify observed facts、generation invalidation facts、double revoke fail-closed facts、no-resource-binding facts 与 no-public-surface facts。

## Probe scripts

- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

## 禁止清单

- 不创建 resource object table。
- 不绑定 token 到 native object。
- 不保存 raw pointer。
- 不返回 native pointer / handle。
- 不调用 retain / release / destroy。
- 不创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不获取 drawable，不创建 command buffer，不调用 `commit` / `present`。
- 不提交 GPU work，不执行 render。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-preflight-decision.md)
- [implementation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-token-table-no-resource-issue-revoke-first-implementation-closure-review.md)
- [next boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-next-boundary-decision.md)
- [native token table shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-manifest.md)
- [native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md)

## 后续入口

当时唯一后续入口建议为 platform object native callable preflight。该入口已经完成并由下游 manifest 封账。

该入口只能做 preflight；不得直接创建 platform object、native object、native handle、raw pointer、Metal/AppKit resource、public API、renderer state write 或 backend-ready truth。

当前下游接续状态：该入口已由 [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md)、[teardown admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)、AppKit import / class availability / main-thread admission、[token-backed creation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-creation-planning-manifest.md)、[no-object creation callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-no-object-creation-callable-manifest.md)、[real NSView allocation feasibility manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-real-nsview-allocation-manifest.md)、[token-backed NSView object table manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-object-table-manifest.md)、[token-backed NSView create/destroy first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-token-backed-nsview-create-destroy-first-slice-manifest.md)、[NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md)、[NSView backend shell integration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-manifest.md)、[CAMetalLayer attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md) 与 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 接续并封账。最新唯一后续入口转为 `P1 internal Renderer Metal device binding planning preflight decision`。该下游不改变本 token issue / revoke 边界：token 仍不得编码 pointer，不得公开，不得绕过 generation / fail-closed classification，也不得授权 public API、renderer state write、Metal device、drawable、GPU submission 或 backend-ready truth。

后续 Renderer 路线已继续接到 [production drawable texture lifetime 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)，当前唯一入口转为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`。该下游仍不改变本 token issue / revoke 边界，也不授权 production drawable acquire / release、descriptor attachment、encoder、draw、commit、present、GPU submission、render 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table no-resource issue/revoke 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_issue_revoke.cj`；truth 固定为 bridge-local opaque token issue/revoke facts；stop-line 继续禁止 resource table、native object、pointer、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，当时转为 platform object native callable preflight；当前已由下游 platform object native callable manifest 接续。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
