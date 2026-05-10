# P1 内部渲染器 native bridge resource creation admission 清单稳定化复核

日期：2026-05-10

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_resource_creation_admission.cj`。
- 本轮路线是 value boundary，不是 native resource callable implementation。
- 本轮没有新增 production native resource C ABI。
- 本轮没有实现 token table。
- 本轮没有执行 destroy、retain 或 release。
- 本轮没有修改 production native `.h` / `.m`。
- 本轮没有修改 scripts。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有把 resource creation admission facts 暴露到 public API。

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

不得把 resource creation admission、main-thread gate prerequisite、token table prerequisite、teardown callable prerequisite、token-return-only future policy 或 smoke evidence 包装成 resource creation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native token table implementation preflight decision`

下一轮若进入该入口，必须先确认 token table 是否可以 implementation、是否允许 native / runtime mutability、如何保持 bridge-local ownership、generation / epoch invalidation、main-thread confinement、revoke-before-destroy ordering 和 no-public-surface；不得直接创建 AppKit / Metal object、native handle、raw pointer、resource callable、public API 或 backend-ready truth。

## 下游封账

下游 [native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-token-table-implementation-manifest-stabilization-closure-review.md) 已完成。

下游 endpoint 是 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`，只消费本 closure 所固定的 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`。

下游仍不实现 token table，不新增 native token C ABI，不修改 production native `.h` / `.m`，不创建 resource object table，不绑定 native object，不保存 raw pointer，不返回 native pointer，不新增 public API，不调用 resource callable，不创建 backend-ready truth。当前全局唯一后续入口已经转为：

`P1 internal Renderer native token table no-resource shell first implementation preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，resource creation admission value boundary 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_resource_creation_admission.cj`；truth 固定为 resource creation admission intent、main-thread gate prerequisite、token table prerequisite、teardown callable prerequisite、token-return-only future policy 与 no-native-resource-creation-admission readiness facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
