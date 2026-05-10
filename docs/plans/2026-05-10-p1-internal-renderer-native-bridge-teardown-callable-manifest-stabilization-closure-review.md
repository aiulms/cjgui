# P1 内部渲染器 native bridge teardown callable 清单稳定化复核

日期：2026-05-10

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_callable.cj`。
- 本轮路线是 planning value boundary，不是 native teardown callable implementation。
- 本轮没有新增 production native teardown C ABI。
- 本轮没有实现 token table。
- 本轮没有执行 destroy、retain 或 release。
- 本轮没有修改 production native `.h` / `.m`。
- 本轮没有修改 scripts。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有把 teardown callable facts 暴露到 public API。

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

不得把 teardown callable planning、no-destroy policy、revoke-before-destroy ordering、double-destroy / dangling-token classification、main-thread destroy gate、token table ownership 或 smoke evidence 包装成 destroy permission、native object permission、native handle permission、resource creation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge resource creation admission preflight decision`

下一轮若进入该入口，必须先确认 resource creation admission 是否仍能保持 no-native-object until explicitly approved、main-thread gate、token / teardown compatibility、no-public-surface 与 backend-ready denial；不得直接创建 AppKit / Metal object、native handle、raw pointer、public API 或 backend-ready truth。

下游 [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-resource-creation-admission-manifest-stabilization-closure-review.md) 已完成。全局唯一后续入口已经转为 `P1 internal Renderer native token table implementation preflight decision`；该入口仍不批准 native object、resource callable、public API、Metal / AppKit、renderer state write 或 backend-ready truth。

下游 [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-implementation-manifest-stabilization-closure-review.md) 也已完成。全局唯一后续入口已经转为 `P1 internal Renderer platform object AppKit import preflight decision`；该入口仍不批准 actual destroy、native object、resource callable、public API、renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge teardown callable planning value boundary 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_callable.cj`；truth 固定为 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy、main-thread destroy callable gate policy 与 no-native-bridge-teardown-callable readiness facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge resource creation admission preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
