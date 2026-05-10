# P1 内部渲染器 native bridge native token callable 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_bridge_token_callable.cj`。
- 本轮路线是 planning value boundary，不是 native callable implementation。
- 本轮没有新增 token C ABI symbol。
- 本轮没有创建 token table。
- 本轮没有修改 production native `.h` / `.m`。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有把 token 暴露到 public API。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未创建 token table。
- 未新增 module-level mutable `var`。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 AppKit / Metal。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 native token callable planning、opaque-token type policy、token table mutability denial、revoke-without-destroy policy、main-thread gate preservation 或 token ownership manifest 包装成 native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native token table ownership hardening preflight decision`

下一轮若进入该入口，必须先解决 token table 是否允许、状态是否可变、ownership domain、main-thread confinement、fail-closed validate / revoke、teardown compatibility 与 no-pointer guarantee；不得直接进入 native object、pointer handle、destroy callback、resource callable、Metal / AppKit 或 public API。

## 下游封账

该入口已由 [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-token-table-ownership-hardening-manifest-stabilization-closure-review.md) 接续。下游 endpoint 是 `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft()`，只固定 bridge-local opaque token table policy、table mutability confinement、generation / epoch invalidation、revoke-before-destroy ordering 与 double-revoke / dangling-token failure classification facts。

该 downstream 不是 token table implementation、native token C ABI、native object、pointer handle、destroy、Metal / AppKit、public API、renderer state write 或 backend-ready permission。当前全局唯一后续入口已经转为 `P1 internal Renderer native bridge teardown callable preflight decision`。

## 下游 teardown callable 接续

[native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 已继续接续该链。它通过 token table ownership endpoint 间接继承本 manifest 的 opaque token / no-pointer / revoke-without-destroy facts，但没有新增 native teardown C ABI、token table implementation、destroy、native object、Metal / AppKit、public API、renderer state write 或 backend-ready truth。当前全局唯一后续入口已经转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token callable planning value boundary 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_token_callable.cj`；truth 固定为 opaque token planning、token table mutability denial 与 revoke-without-destroy facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table ownership hardening preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
