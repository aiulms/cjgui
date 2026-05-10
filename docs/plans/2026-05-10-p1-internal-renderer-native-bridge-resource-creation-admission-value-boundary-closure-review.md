# P1 内部渲染器 native bridge resource creation admission value boundary 复核

日期：2026-05-10

状态：value boundary closure / no native implementation

## 本轮结论

本轮新增 internal-only owner：

`runtime/cjgui/src/runtime_renderer_native_resource_creation_admission.cj`

该 owner 只消费：

`CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`

并固定新的 endpoint：

`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`

default draft：

`cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`

## 写集说明

本轮只新增 value owner 与文档。没有修改 production native `.h/.m`、probe scripts、`runtime/cjgui/cjpm.toml`、smoke native files 或 `runtime_state.cj`。

## 固定事实

owner 只表达：

- native resource creation admission intent。
- main-thread gate prerequisite policy。
- token table prerequisite policy。
- teardown callable prerequisite policy。
- token-return-only future policy。
- no-native-resource-creation-admission readiness facts。

这些 facts 不是 native resource creation permission。

## 停止线复核

- 未新增 native resource C ABI。
- 未新增 native resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未实现 token table。
- 未调用 retain / release / destroy。
- 未导入 Cocoa / Metal / QuartzCore。
- 未创建 AppKit / Metal object。
- 未写 renderer state。
- 未新增 public API / diagnostics。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 resource creation admission、main-thread gate、token table prerequisite、teardown callable prerequisite 或 token-return-only policy 包装成 native object permission、resource creation permission、native handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，resource creation admission value boundary 已完成。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_resource_creation_admission.cj`；truth 固定为 resource creation admission prerequisite facts；stop-line 继续禁止 actual resource creation、native object、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，下一步转为 manifest stabilization，再封账到 `P1 internal Renderer native token table implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
