# P1 渲染器 native bridge C ABI surface contract manifest

日期：2026-05-09

状态：docs-only manifest stabilization / no C ABI implementation

## 文件定位

本 manifest 固定 [runtime_renderer_native_bridge_c_abi_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj) 的 owner、runtime input、canonical endpoint、default draft、current truth 与 stop-line。

本 manifest 不新增 runtime owner，不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不创建 Metal resource，不创建 backend ready truth，不写 renderer state，不发布 public diagnostics 或 public API。

## 固定项

- owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj`
- runtime input：`CjguiInternalRendererNoRealBackendReadyShellReadiness`
- canonical endpoint：`CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()`
- current truth：native bridge C ABI surface intent / production bridge write-set policy / C ABI category admission policy / native status dehydration policy / no-native-bridge-C-ABI-surface readiness facts

## 当前事实

`NativeBridgeCAbiSurfaceIntent` 只表达未来正式 native bridge C ABI surface contract 的 planning intent，不实现 C ABI，不声明 FFI，不调用 native bridge。

`ProductionBridgeWriteSetPolicy` 固定 smoke native files remain lab-only、no production native file creation、no native bridge modification 与 no protected path modification。它不创建 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`。

`CAbiCategoryAdmissionPolicy` 只记录 future bridge init / destroy admission、main-thread guard、platform object create admission、Metal device-layer create admission、command queue create admission 与 error status dehydration 的类别规划；它排除 drawable、command buffer、render pass、encoder、pipeline、draw call、GPU work、renderer state write 与 public API。

`NativeStatusDehydrationPolicy` 只允许 dehydrated status / token facts，不暴露 raw pointer，不暴露 native handle，不让 Objective-C 成为 runtime truth source。

`NoNativeBridgeCAbiSurfaceReadiness` 不是 native bridge implementation permission、C ABI implementation permission、FFI permission、native handle permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

本轮 build 只证明 Cangjie internal value owner 可编译，不证明 production C ABI、native bridge、Metal resource、backend ready truth、GPU submission、render、renderer state write 或 public diagnostics 可用。

## 同形边界刹车

本 manifest 只做封账，不新增 tail wrapper，不新增 receipt、record、publication、permission 字段或 public API。

不得把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 包成 native bridge ready、C ABI ready、native-handle ready、Metal ready、backend-ready、GPU-submission ready、render permission、state-write permission、public diagnostics、receipt、record 或 publication wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no render pass / encoder / pipeline / draw call。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no retain / release / destroy。
- no module-level mutable `var`。

## 证据链

- [native bridge write-set planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-native-bridge-write-set-planning-reset-decision.md)
- [native bridge C ABI surface contract preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-preflight-decision.md)
- [native bridge C ABI surface contract value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-value-boundary-closure-review.md)
- [native bridge C ABI surface contract next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-next-boundary-decision.md)
- [real backend readiness final shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-final-shell-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [macOS bridge verification smoke topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 唯一后续入口

`P1 internal Renderer native handle token ownership planning preflight decision`

## 下游 native handle token ownership 封账

下游 native handle token ownership macro 已完成：

- [native handle token ownership preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-planning-preflight-decision.md)
- [native handle token ownership value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-value-boundary-closure-review.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native handle token ownership manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-manifest-stabilization-closure-review.md)

该 downstream 只把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoNativeHandleTokenReadiness` / `cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()`。它不把本 manifest 的 C ABI surface facts 升格为 native bridge implementation permission、C ABI implementation permission、FFI permission、native handle permission、raw pointer permission、Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native bridge teardown implementation planning preflight decision`

## 下游 native bridge teardown implementation planning 封账

下游 [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-teardown-implementation-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 通过 native handle token ownership 链路继续使用本 manifest 的 surface intent、production write-set policy、category admission 与 native status dehydration facts 作为 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 升格为 native bridge implementation permission、C ABI implementation permission、FFI permission、destroy permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge first production write-set preflight decision`

## 下游生产写集预检封账

下游 [native bridge first production write-set preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-first-production-write-set-preflight-decision.md) 已完成。该 downstream 继续使用本 manifest 的 surface intent、production bridge write-set policy、C ABI category admission 与 native status dehydration facts 作为 planning evidence。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 升格为 native bridge implementation permission、callable C ABI permission、FFI permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer production native bridge skeleton write-set contract bundle`

## 下游 skeleton 写集封账

下游 [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-manifest-stabilization-closure-review.md) 已完成。该 downstream 使用本 manifest 的 surface intent、production bridge write-set policy、C ABI category admission 与 native status dehydration facts 作为 planning evidence，只新增 production skeleton `.h` / `.m` 写集落点。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 升格为 native bridge implementation permission、callable C ABI permission、FFI permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics、public API 或 build config modification permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge build system integration preflight decision`

## 下游 callable C ABI planning 封账

下游 [native bridge callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 surface intent、production bridge write-set policy、C ABI category admission 与 native status dehydration facts 作为 planning evidence，但只新增 runtime-local callable planning owner。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 升格为 callable C ABI implementation permission、FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`

## 下游 callable C ABI 第一实现封账

下游 [native bridge callable C ABI first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-first-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-first-implementation-manifest-stabilization-closure-review.md) 已完成。该 downstream 继续使用本 manifest 的 surface intent、production bridge write-set policy、C ABI category admission 与 native status dehydration facts，但只新增 no-resource callable `C ABI` surface。

该 downstream 不把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`、callable surface 或 skeleton compile 升格为 runtime FFI permission、runtime `.cj` FFI declaration permission、native bridge implementation permission、native handle permission、raw pointer permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission、render、renderer state write、public diagnostics 或 public API permission。

当前 downstream 后续入口：

`P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`
