# P1 内部渲染器 native token table ownership hardening 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_token_table_ownership.cj`。
- 本轮路线是 value boundary，不是 token table implementation。
- 本轮没有新增 native token C ABI。
- 本轮没有创建 token table。
- 本轮没有修改 production native `.h` / `.m`。
- 本轮没有修改 scripts。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有把 token 或 table 暴露到 public API。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未创建 token table。
- 未新增 global mutable native table。
- 未新增 module-level mutable runtime state。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 AppKit / Metal。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 token table ownership hardening、bridge-local opaque token table policy、generation / epoch invalidation、revoke-before-destroy ordering、double-revoke / dangling-token failure classification 或 token callable planning 包装成 token table implementation permission、native token C ABI permission、native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge teardown callable preflight decision`

下一轮若进入该入口，必须先确认 teardown callable 是否仍能保持 no-resource / guarded admission、revoke-before-destroy ordering、double-destroy / dangling-token fail-closed、main-thread confinement 与 no-public-surface；不得直接进入 native object、pointer handle、resource callable、Metal / AppKit 或 public API。

## 下游接续

该入口已由 [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-manifest-stabilization-closure-review.md) 接续。下游 endpoint 是 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`，只固定 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy 与 main-thread destroy callable gate facts。

该 downstream 不是 native teardown C ABI、token table implementation、destroy permission、native object、pointer handle、Metal / AppKit、public API、renderer state write 或 backend-ready permission。当前全局唯一后续入口已经转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table ownership hardening value boundary 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_ownership.cj`；truth 固定为 token table ownership / mutability confinement / generation invalidation / revoke ordering / failure classification facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge teardown callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
