# P1 渲染器 native bridge C ABI surface contract value boundary closure

日期：2026-05-09

状态：完成 / internal value boundary closure / no C ABI implementation

## 文件定位

本 closure 收束 `P1 internal Renderer native bridge C ABI surface contract value boundary bundle implementation`。本轮新增唯一 runtime owner [runtime_renderer_native_bridge_c_abi_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj)，用于表达生产 native bridge C ABI surface contract 的 internal-only value facts。

本轮没有新增 production `.h` / `.m`，没有修改 `labs/macos_bridge_smoke/native/*`，没有实现 C ABI / FFI，没有修改 native bridge、Objective-C、Metal、AppKit 或 protected paths。

## 落地内容

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj`

新增 runtime symbols：

- `CjguiInternalRendererNativeBridgeCAbiSurfaceIntent`
- `CjguiInternalRendererProductionBridgeWriteSetPolicy`
- `CjguiInternalRendererCAbiCategoryAdmissionPolicy`
- `CjguiInternalRendererNativeStatusDehydrationPolicy`
- `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`
- `cjguiInternalBuildRendererNativeBridgeCAbiSurfaceIntent`
- `cjguiInternalBuildRendererProductionBridgeWriteSetPolicy`
- `cjguiInternalBuildRendererCAbiCategoryAdmissionPolicy`
- `cjguiInternalBuildRendererNativeStatusDehydrationPolicy`
- `cjguiInternalBuildRendererNoNativeBridgeCAbiSurfaceReadiness`
- `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoRealBackendReadyShellReadiness`

Canonical endpoint：

- `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`

Default draft：

- `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()`

## 当前 truth

当前 truth 仅限：

- native bridge C ABI surface intent。
- production bridge write-set policy。
- C ABI category admission policy。
- native status dehydration policy。
- no-native-bridge-C-ABI-surface readiness facts。

`NativeBridgeCAbiSurfaceIntent` 只表达未来正式 bridge surface contract 的命名与规划需要。

`ProductionBridgeWriteSetPolicy` 明确 smoke native files 仍是 lab-only evidence，不创建 production native file，不修改 native bridge，不触碰 protected paths。

`CAbiCategoryAdmissionPolicy` 只允许 bridge init / destroy、main-thread guard、platform object create、Metal device-layer create、command queue create、error status dehydration 等 category 的规划 admission；它排除 drawable、command buffer、render pass、encoder、pipeline、draw call、GPU work 与 public API。

`NativeStatusDehydrationPolicy` 只允许 status / token facts，不暴露 raw pointer，不暴露 native handle，不让 Objective-C 成为 runtime truth source。

`NoNativeBridgeCAbiSurfaceReadiness` 不是真实 C ABI implementation permission、native bridge implementation permission、native handle permission、Metal resource permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 构建与 smoke

构建命令：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-c-abi-surface-contract-macro-target --skip-script
```

结果：通过。输出仅包含仓库既有 unused warnings，未出现本 owner 的构造参数、字段名、导入、命名冲突或语法错误。

smoke 命令：

```bash
labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：通过。auto-close log assertions passed。该 smoke 仍只作为 lab feasibility / teardown / verification evidence，不是 runtime truth。

## 同形边界刹车

本轮没有把 `CjguiInternalRendererNoRealBackendReadyShellReadiness`、real shell branch、smoke lab、Metal reference pack 或 native resource bridge manifest 包成 native bridge permission、C ABI permission、native-handle permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

新增 owner 提供的是 surface contract / write-set policy / category admission / status dehydration 语义，不是 thin wrapper。

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

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 C ABI surface preflight 推进到 internal value boundary landed。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj` 并固定 surface contract / write-set policy / category admission / status dehydration truth 与 no-implementation stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge C ABI surface contract manifest stabilization bundle implementation` 前的 next-boundary decision。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge C ABI surface contract next-boundary decision`

## 下游 native handle token ownership 封账

下游 native handle token ownership macro 已完成，新增 [runtime_renderer_native_handle_token.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_handle_token.cj)，并输出 `CjguiInternalRendererNoNativeHandleTokenReadiness` / `cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()`。该 downstream 只使用本 value boundary 的 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 作为 input，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer。
