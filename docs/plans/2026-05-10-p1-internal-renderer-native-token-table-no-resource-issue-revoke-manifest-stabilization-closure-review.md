# P1 内部渲染器 native token table no-resource issue/revoke 清单稳定化复核

## 封账结果

[native token table no-resource issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md) 已封账。

当前 fixed point：

- Owner：`runtime/cjgui/src/runtime_renderer_native_token_table_issue_revoke.cj`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableShellReadiness`
- Endpoint：`CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`
- Native callable：`cjgui_native_bridge_token_issue` / `cjgui_native_bridge_token_revoke` 与既有 token shell classification callable。
- Truth：fixed-capacity opaque token issue/revoke/classify observed facts、generation invalidation、double revoke fail-closed、no resource binding、no pointer、no public surface。

## 稳定化边界

本清单不改变 `runtime/cjgui/cjpm.toml`，不接入 production native object 到主包 config，不新增 public API，不创建 native object，不保存或返回 native pointer，不绑定 token 到 AppKit / Metal resource，不执行 destroy / retain / release，不写 renderer state，不触碰 `runtime_state.cj`。

Same-shape Boundary Brake：issue/revoke token mechanics 不得被包装成 resource table permission、native handle permission、native object permission、Metal/AppKit permission、backend-ready permission、public API permission、receipt / record / publication。

## 后续入口

当时唯一后续入口为 platform object native callable preflight。该入口已经完成并由下游 manifest 封账。

该入口必须重新做 preflight，且只能在 token table issue/revoke、teardown callable planning、main-thread query 与 resource creation admission stop-line 都被读取后判断是否进入 platform object callable runway。

当前下游接续状态：该入口已由 [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md) 接续并封账。最新唯一后续入口转为 `P1 internal Renderer native bridge teardown callable implementation preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table no-resource issue/revoke stage 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 固定为 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_issue_revoke.cj`；truth 固定为 no-resource issue/revoke dehydrated facts；stop-line 固定为 no resource binding / no pointer / no public / no renderer state write。
- 本轮是否改变唯一 next opening：是，当时转为 platform object native callable preflight；当前已由下游 platform object native callable manifest 接续。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
