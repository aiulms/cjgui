# 渲染器后端 readiness 与真实后端 runway

状态：docs-only / topic manifest / no runtime truth

## 主题定位

本主题记录 Renderer 从 no-render backend readiness 走向真实 backend resource runway 的长链。它回答“哪些后端资源 owner、lifecycle、bridge 和 submission 前置事实已经被表达”，不回答“现在能否创建真实 Metal / AppKit 资源”。

## 当前状态

当前已经形成 backend readiness、platform object owner、Metal device-layer owner、no-draw backend shell、real command queue lifecycle、real drawable lifecycle、command submission、backend shell skeleton、native resource bridge 与 backend readiness implementation finalization admission 等 value facts / admission facts。

当前真实资源桥接前的后端 runway tail 是 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`。

当前最新 real first-slice shell endpoint 是 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`。

implementation admission 链已从 platform object implementation 推进到 real backend implementation planning reset decision。该 decision 确认 no-native-resource-bridge 到 no-backend-ready-implementation 的 value / admission facts 足以进入真实 backend implementation planning，但仍不批准直接 implementation；第一口真实资源选择 platform object / native resource creation owner 的 docs-only preflight。

real backend platform object first implementation preflight decision 已完成，确认下一步可以进入极窄 internal runtime owner shell slice。该 slice 不应继续限于 `labs/macos_bridge_smoke`，但 `labs` 仍只能作为 feasibility / teardown / smoke evidence；下一步默认不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle 或 Metal resource。

real backend platform object first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`。该 owner shell 只消费 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 platform object、native handle、Metal / AppKit resource、GPU submission、renderer state write 或 public API。

real backend platform object first implementation slice next-boundary decision 已完成，确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 shell endpoint。下一步只能 manifest stabilization，不得转向 native bridge、native handle、Metal / AppKit 或 backend-ready truth。

real backend platform object first implementation slice manifest stabilization 已完成，固定 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj` 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。该 manifest 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 platform object、native handle、Metal / AppKit resource、GPU submission、renderer state write 或 public API。

real backend platform object branch next-boundary decision 已完成，确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 shell endpoint。下一步选择 native teardown contract hardening preflight，在接近 native bridge、retain / release / destroy、native handle、Objective-C、Metal 或 AppKit 前先硬化生命周期和失败路径，不直接打开 Metal resource work。

native teardown contract hardening preflight decision 已完成，判定当前 teardown contract 还不足以直接进入 native bridge / Objective-C / Metal / AppKit 或 real Metal device-layer first implementation preflight。下一步选择 internal-only value boundary，先固定 ownership release、teardown failure classification、main-thread confinement 与 no-native-teardown-implementation facts。

native teardown contract hardening value boundary 已完成，新增 `runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj`。该 owner 只消费 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`，canonical endpoint 是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不调用 retain / release / destroy，不创建 native handle、Metal resource、GPU submission、renderer state write 或 public API。

native teardown contract hardening closure / next decision 已完成，确认 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 足够作为当前 no-native-teardown-implementation endpoint。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不授予 native bridge、retain / release / destroy、native handle、Metal / AppKit、backend-ready、renderer state write 或 public API permission；唯一 next opening 转为 manifest stabilization。

native teardown contract hardening manifest stabilization 已完成，固定 `runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj` 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不新增 runtime owner，不修改 `.cj`，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不调用 retain / release / destroy，不创建 native handle、Metal resource、GPU submission、renderer state write 或 public API。

real Metal device-layer first implementation preflight decision 已完成，确认可以打开 real Metal device-layer 第一刀 runway，但下一步只能是极窄 implementation slice。推荐 owner candidate 是 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`；下一刀默认只表达 owner shell / dehydrated native result facts，不直接修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不调用 retain / release / destroy，不创建 command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API。

real Metal device-layer first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`。该 owner 只消费 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API。

real Metal device-layer first implementation slice next-boundary decision 已完成，确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint。但上一轮 `cjpm build` 未完成，原因是当前 shell 与交互式 zsh 均找不到 `cjpm`；因此当前不进入 manifest stabilization，唯一 next opening 转为 build verification follow-up。

real Metal device-layer first slice build recovery and stabilization 已完成。本轮只在 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj` 内修复构造参数一致性，`CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)`、`CjguiInternalRendererRealMetalDeviceLayerIntent(...)` 与 `CjguiInternalRendererRealMetalDeviceShellPolicy(...)` 构造点已对齐类型定义；native resource bridge tail、canonical endpoint、runtime input、truth 与 stop-line 不变。`cjpm build` 与 auto-close smoke 均通过。

real Metal device-layer first implementation slice manifest stabilization 已完成，固定 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj` 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。该 manifest 不改变 native resource bridge tail，不创建真实 `MTLDevice` / `CAMetalLayer`，也不创建 backend-ready truth；唯一 next opening 转为 branch closure / next decision。

real Metal device-layer branch next-boundary decision 已完成，确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint，first slice manifest 足够作为本分支阶段封账。该 decision 不改变 native resource bridge tail，不创建真实 `MTLDevice` / `CAMetalLayer`、`MTLCommandQueue`、drawable、GPU submission、renderer state write、backend ready truth 或 public API；唯一 next opening 转为 real command queue first implementation preflight decision。

real command queue first implementation preflight decision 已完成，确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为进入 real command queue planning 的上游 endpoint。该 decision 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API；唯一 next opening 转为 real command queue first implementation slice bundle。

real command queue first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_command_queue_real.cj`。该 owner 只消费 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。旧 lifecycle endpoint `CjguiInternalRendererNoRealCommandQueueReadiness` 仍归 `runtime_renderer_real_command_queue.cj`，不作为本 slice endpoint。该 slice 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API；唯一 next opening 转为 real command queue first implementation slice closure / next real command queue decision。

real command queue first slice 后续边界、manifest stabilization 与 branch closure / next decision 已完成。`CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()` 足够作为 no-real-command-queue shell endpoint，但不是旧 lifecycle truth、`MTLCommandQueue`、`newCommandQueue`、drawable、command buffer、GPU、render、state write 或 public API permission；branch decision 选择 real drawable first implementation preflight。

real drawable first implementation preflight 已完成，确认 `CjguiInternalRendererNoRealCommandQueueShellReadiness` 足够作为 real drawable planning 的上游 endpoint。下一刀只允许 internal owner shell / dehydrated drawable result facts；默认 owner candidate 是 `runtime/cjgui/src/runtime_renderer_drawable_real.cj`，runtime input candidate 只消费 `CjguiInternalRendererNoRealCommandQueueShellReadiness`。该 preflight 不批准 drawable acquisition、`nextDrawable`、`present`、command buffer、GPU submission、renderer state write、native bridge / Objective-C / Metal / AppKit / FFI、C ABI、native handle、raw pointer 或 public API。

real drawable first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_drawable_real.cj`。该 owner 只消费 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。当前 truth 仅限 drawable shell intent / drawable availability admission shell / drawable acquisition denial proof / presentation denial proof / drawable teardown / failure classification / no-real-drawable-shell readiness facts；`cjpm build` 已通过。该 owner 不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API，不创建 native handle / raw pointer。

real drawable first slice 已完成 next-boundary 与 manifest stabilization。该 manifest 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不把 `CjguiInternalRendererNoRealDrawableShellReadiness` 升格为 drawable-ready、backend-ready、resource-ready、GPU-submission、render-permission、receipt / record / publication。

real drawable branch next-boundary decision 已完成，确认 no-real-drawable-shell 分支可收口，并选择 real command buffer first implementation preflight。该 decision 不授权 drawable acquisition、`nextDrawable`、present、command buffer、GPU submission、render、renderer state write 或 public API。

real command buffer first implementation preflight 已完成，确认 `CjguiInternalRendererNoRealDrawableShellReadiness` 足够作为 real command buffer planning 的上游 endpoint。下一刀只允许 internal owner shell / dehydrated command buffer result facts；默认 owner candidate 是 `runtime/cjgui/src/runtime_renderer_command_buffer_real.cj`，runtime input candidate 只消费 `CjguiInternalRendererNoRealDrawableShellReadiness`。该 preflight 不批准真实 command buffer creation、`commandBuffer`、`commit`、render pass、encoder、pipeline、draw call、GPU submission、renderer state write、native bridge / Objective-C / Metal / AppKit / FFI、C ABI、native handle、raw pointer 或 public API。

real command buffer first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_command_buffer_real.cj`。该 owner 只消费 `CjguiInternalRendererNoRealDrawableShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()`。该 slice 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 command buffer，不调用 `commandBuffer` / `commit`，不调用 `present` / `nextDrawable`，不创建 render pass / encoder / pipeline / draw call，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API；`cjpm build` 与 auto-close smoke 均通过。

real command buffer first slice 已完成 next-boundary 与 manifest stabilization。该 manifest 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不把 `CjguiInternalRendererNoRealCommandBufferShellReadiness` 升格为 command-buffer-ready、backend-ready、resource-ready、GPU-submission、render-permission、receipt / record / publication；唯一 next opening 转为 real command buffer branch closure / next real command buffer decision。

real command buffer branch next-boundary decision 已完成，确认 no-real-command-buffer-shell 分支可收口，并选择 real render pass first implementation preflight。该 decision 不改变 native resource bridge tail，不授权真实 command buffer、`commandBuffer`、`commit`、render pass descriptor、encoder、GPU submission、render、renderer state write 或 public API。

real render pass first implementation preflight 已完成，确认 `CjguiInternalRendererNoRealCommandBufferShellReadiness` 足够作为 real render pass planning 的上游 endpoint。下一刀只允许 internal owner shell / dehydrated render pass result facts；默认 owner candidate 是 `runtime/cjgui/src/runtime_renderer_render_pass_real.cj`，runtime input candidate 只消费 `CjguiInternalRendererNoRealCommandBufferShellReadiness`。该 preflight 不批准真实 render pass descriptor creation、attachment / texture view creation、`renderCommandEncoder`、`endEncoding`、encoder、pipeline、draw call、GPU submission、renderer state write、native bridge / Objective-C / Metal / AppKit / FFI、C ABI、native handle、raw pointer 或 public API。

real render pass first implementation slice 已完成，新增 `runtime/cjgui/src/runtime_renderer_render_pass_real.cj`。该 owner 只消费 `CjguiInternalRendererNoRealCommandBufferShellReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`。该 slice 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不创建真实 render pass descriptor，不创建 attachment / texture view，不调用 `renderCommandEncoder` / `endEncoding`，不创建 encoder / pipeline / draw call，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API；`cjpm build` 与 auto-close smoke 均通过。

real render pass first slice 已完成 next-boundary 与 manifest stabilization。该 manifest 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不把 `CjguiInternalRendererNoRealRenderPassShellReadiness` 升格为 render-pass-ready、encoder-ready、backend-ready、resource-ready、GPU-submission、render-permission、receipt / record / publication；唯一 next opening 转为 real render pass branch closure / next real render pass decision。

## 已落地现实

- backend readiness tail 已固定 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`。
- platform object owner tail 已固定 `CjguiInternalRendererNoPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererBackendPlatformObjectOwnerDraft()`。
- Metal device-layer owner tail 已固定 `CjguiInternalRendererNoMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerOwnerDraft()`。
- no-draw backend shell tail 已固定 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`。
- real command queue lifecycle tail 已固定 `CjguiInternalRendererNoRealCommandQueueReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueLifecycleDraft()`。
- real drawable lifecycle tail 已固定 `CjguiInternalRendererNoRealDrawableReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableLifecycleDraft()`。
- real command queue first-slice shell endpoint 已固定 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。
- real drawable first-slice shell endpoint 已固定 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。
- real command buffer first-slice shell endpoint 已固定 `CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()`。
- real render pass first-slice shell endpoint 已固定 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`。
- command submission tail 已固定 `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`。
- backend shell skeleton tail 已固定 `CjguiInternalRendererNoResourceBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererBackendShellSkeletonDraft()`。
- native resource bridge tail 已固定 `CjguiInternalRendererNoNativeResourceBridgeReadiness` / `cjguiInternalExecuteDefaultRendererNativeResourceBridgeDraft()`。
- backend readiness implementation finalization preflight 已允许打开 value-only runway。
- backend readiness implementation finalization admission owner 已固定 `CjguiInternalRendererNoBackendReadyImplementationReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft()`；该 endpoint 不是 backend ready truth，不得把 backend 标记为 ready，不得创建 backend object、platform object、native handle 或 renderer state write。
- backend readiness implementation admission closure / next decision 已确认该 endpoint 足够作为当前 no-backend-ready-implementation endpoint；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 manifest stabilization。
- backend readiness implementation admission manifest stabilization 已固定 `runtime/cjgui/src/runtime_renderer_backend_readiness_admission.cj` 的 owner file、runtime input、canonical endpoint、default draft、current truth 与 stop-line；唯一 next opening 转为 backend readiness branch implementation milestone stabilization。
- backend readiness implementation branch milestone stabilization 已固定 implementation admission branch 起点 `CjguiInternalRendererNoNativeResourceBridgeReadiness`、当前尾点 `CjguiInternalRendererNoBackendReadyImplementationReadiness`、完整 evidence chain 与 fail-closed / no-permission posture；唯一 next opening 转为 branch milestone closure / next renderer branch decision。
- backend readiness implementation branch next-boundary decision 已确认 current branch tail 与 branch milestone 足够封账，选择 stop here / reconciliation；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 implementation admission branch reconciliation scan。
- implementation admission branch reconciliation scan 已确认当前 tail、topic manifest、README、tracker、runtime README 与 branch 原文一致；无 backend-ready permission 误写、无明显 chain 缺口、无旧新 milestone 术语冲突；唯一 next opening 转为 `STOP / wait for user direction on real backend implementation planning reset`。
- real backend implementation planning reset decision 已选择 platform object / native resource creation owner 作为第一口真实资源的 docs-only preflight；smoke 与 reference pack 只作为 feasibility / teardown / planning evidence，不是 runtime truth。
- real backend platform object first implementation preflight decision 已选择 `P1 internal Renderer real backend platform object first implementation slice bundle`；下一步只允许极窄 internal runtime owner shell，不批准 native bridge、native handle、Metal / AppKit、GPU submission、renderer state write 或 public API。
- real backend platform object first implementation slice 已新增 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`，固定 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`，current truth 仅限 shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts；下一步转 closure / next decision。
- real backend platform object first implementation slice next-boundary decision 已确认该 shell endpoint 足够作为当前 no-real-backend-platform-object endpoint；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 manifest stabilization。
- real backend platform object first implementation slice manifest stabilization 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 branch closure / next real platform object decision。
- real backend platform object branch next-boundary decision 已确认 shell endpoint 与 manifest 足够封账；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 native teardown contract hardening preflight decision。
- native teardown contract hardening preflight decision 已确认 teardown 合约仍需 value boundary 硬化；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 native teardown contract hardening value boundary bundle implementation。
- native teardown contract hardening value boundary 已固定 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`；current truth 仅限 native teardown contract intent / ownership release policy / teardown failure classification / main-thread confinement guard / no-native-teardown-implementation readiness facts，唯一 next opening 转为 closure / next native teardown decision。
- native teardown contract hardening closure / next decision 已确认该 endpoint 足够封账；canonical endpoint、owner / truth / stop-line 不变，唯一 next opening 转为 native teardown contract hardening manifest stabilization bundle implementation。
- native teardown contract hardening manifest stabilization 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line；canonical endpoint 不变，唯一 next opening 转为 real Metal device-layer first implementation preflight decision。
- real Metal device-layer first implementation preflight decision 已选择下一步进入 real Metal device-layer first implementation slice bundle；native resource bridge tail 与 native teardown endpoint 均不变，下一刀仍禁止 command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth、public API 与未经 write-set preflight 的 native bridge / C ABI / FFI 扩展。
- real Metal device-layer first implementation slice 已新增 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`，固定 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`；native resource bridge tail 不变，current truth 仅限 real Metal device-layer shell facts，唯一 next opening 转为 slice closure / next real Metal device-layer decision。
- real Metal device-layer first implementation slice next-boundary decision 已确认该 shell endpoint 足够；native resource bridge tail、owner / truth / stop-line 不变，但 build verification gap 未关闭，唯一 next opening 转为 build verification follow-up。
- real Metal device-layer first slice build recovery 已修复该 owner 的构造参数一致性并恢复 build；native resource bridge tail、canonical endpoint、owner / truth / stop-line 不变。
- real Metal device-layer first implementation slice manifest stabilization 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line；native resource bridge tail 不变，后续 branch next-boundary decision 已完成。
- real Metal device-layer branch next-boundary decision 已确认 shell endpoint 与 first slice manifest 足够封账；native resource bridge tail、owner / truth / stop-line 不变，唯一 next opening 转为 real command queue first implementation preflight decision。
- real command queue first implementation preflight decision 已确认下一步可以进入 real command queue first implementation slice bundle；其后 first slice 已新增 `runtime/cjgui/src/runtime_renderer_command_queue_real.cj`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`，native resource bridge tail 与旧 lifecycle endpoint `CjguiInternalRendererNoRealCommandQueueReadiness` 不变。

## 未落地与明确禁止

- 尚未创建真实 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer。
- 尚未创建 backend shell object、backend object、platform object、native handle 或 raw pointer。
- 尚未新增 C ABI、FFI declaration 或 bridge call。
- 尚未调用 retain / release / destroy、`commit`、`present`、`nextDrawable` 或 Metal / AppKit / Objective-C / FFI。
- 尚未提交 GPU work、执行 render、写 renderer state 或扩 public API。
- 尚未创建 backend ready truth，尚未发布 public diagnostics / readiness read surface。

## 当前 owner 链摘要

这条链的意图是逐步证明真实后端 resource runway 的 owner vocabulary 和 stop-line，而不是把 no-* readiness 包成 permission wrapper。当前 owner 链从 backend readiness 出发，经过 platform object owner、Metal device-layer owner、no-draw backend shell、real queue / drawable lifecycle、command submission、backend shell skeleton，最终到 native resource bridge readiness。

backend readiness implementation finalization admission owner 是 implementation admission chain 回看 backend readiness runway 的 value-only 桥接点。它把 `CjguiInternalRendererNoStateWriteImplementationReadiness` 作为唯一 runtime input，把旧 `CjguiInternalRendererNoBackendReadyReadiness` 与本主题证据链作为 docs evidence；它不改变 native resource bridge tail，也不批准 backend ready truth。

branch milestone stabilization 只确认并固定 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 到 `CjguiInternalRendererNoBackendReadyImplementationReadiness` 的 admission facts 串联，不改变本主题的真实资源桥接 tail，也不创建 backend-ready permission。

branch next-boundary decision 进一步确认该 milestone 已足够作为当前分支阶段封账。后续 reconciliation scan 已检查导航与阶段一致性，并选择 stop here / wait for user direction；planning reset decision 则选择下一步进入 platform object first preflight。它们都不创建 backend ready truth，不改变真实资源桥接 tail，也不新增 backend-ready wrapper。

platform object first implementation preflight decision 进一步确认下一步不再停留在 `labs`，但只能新增 runtime internal owner shell；它不改变 native resource bridge tail，不创建 native handle，不开放 C ABI / FFI，不调用 bridge / retain / release / destroy。

platform object first implementation slice 已落地为 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`。它只在 runtime 内表达 shell facts，并没有推进 native bridge tail，也没有创建真实平台资源或后端就绪 truth。

platform object first implementation slice manifest stabilization 已完成封账。它只固定 shell facts 的当前语义，不把该 shell endpoint 升格为 native resource bridge tail、backend-ready truth 或 runtime resource permission。

platform object branch next-boundary decision 进一步确认该 shell 分支不应继续新增同构 wrapper。下一步回到 native teardown contract hardening preflight，先复查 future native bridge / C ABI / FFI / retain / release / destroy / main-thread / failure 关系。

native teardown contract hardening preflight decision 进一步确认 bridge / C ABI / FFI / retain / release / destroy / native handle / Metal resource 之前还缺少 runtime-local hardening value boundary。该 preflight 不改变 native resource bridge tail，也不把 smoke evidence 升格为 runtime truth。

native teardown contract hardening value boundary 新增 runtime-local hardening owner。它把 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 作为唯一 runtime input，并输出 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`；该 endpoint 只用于后续 closure / manifest 判断，不是 native resource bridge tail、native handle permission、Metal resource permission 或 backend-ready truth。

native teardown contract hardening closure / next decision 进一步确认该 endpoint 足够作为当前 no-native-teardown-implementation endpoint。下一步只允许 manifest stabilization，固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line；不得把该 endpoint 包成 native-teardown-ready、bridge-ready、native-handle-ready、Metal-ready、backend-ready、resource-ready 或 public API wrapper。

native teardown contract hardening manifest stabilization 已完成封账。它只固定 native teardown contract hardening facts 的当前语义，不把该 endpoint 升格为 native resource bridge tail、native bridge permission、native handle permission、Metal resource permission、backend-ready truth 或 public API permission。

real Metal device-layer first implementation preflight decision 只把本主题的 runway 推进到下一刀 implementation slice 评估。它不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，不把 native teardown endpoint 或 smoke evidence 升格为 `MTLDevice` / `CAMetalLayer` permission，也不允许跳到 command queue、drawable、command buffer、GPU submission 或 renderer state write。

real Metal device-layer first implementation slice 已新增 runtime-local shell owner。它把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 作为唯一 runtime input，并输出 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`；该 endpoint 只用于后续 closure / manifest 判断，不是 native resource bridge tail、真实 Metal resource permission、backend-ready truth 或 public API permission。

real Metal device-layer first implementation slice next-boundary decision 进一步确认该 endpoint 足够作为当前 no-real-metal-device-layer shell endpoint，但上一轮 build verification 未完成。后续 build recovery 已修复构造参数一致性并验证通过。

real Metal device-layer first implementation slice manifest stabilization 已完成封账。该 manifest 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不把 shell endpoint 升格为 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready 或 public API permission；下一步只能做 branch closure / next decision。

real Metal device-layer branch next-boundary decision 已完成封账。该 decision 不改变 `CjguiInternalRendererNoNativeResourceBridgeReadiness` tail，也不把 shell endpoint、manifest 或 build recovery 升格为 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、command-queue-ready 或 public API permission；下一步只能做 real command queue first implementation preflight decision。

## 关键文档链

- [backend readiness branch milestone](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [backend readiness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [no-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [backend shell skeleton manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-skeleton-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend readiness implementation finalization preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-backend-readiness-implementation-finalization-preflight-decision.md)
- [backend readiness implementation finalization admission closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-backend-readiness-implementation-finalization-admission-value-boundary-closure-review.md)
- [backend readiness implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-backend-readiness-implementation-admission-next-boundary-decision.md)
- [backend readiness implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-backend-readiness-implementation-admission-manifest.md)
- [backend readiness implementation admission manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-backend-readiness-implementation-admission-manifest-stabilization-closure-review.md)
- [backend readiness implementation branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-backend-readiness-implementation-branch-milestone-manifest.md)
- [backend readiness implementation branch milestone closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-backend-readiness-implementation-branch-milestone-stabilization-closure-review.md)
- [backend readiness implementation branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-backend-readiness-implementation-branch-next-boundary-decision.md)
- [implementation admission branch reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-implementation-admission-branch-reconciliation-scan.md)
- [real backend implementation planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-implementation-planning-reset-decision.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [real backend platform object first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend platform object first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real backend platform object branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native teardown contract hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)
- [real Metal device-layer first implementation slice build verification follow-up](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-build-verification-follow-up.md)
- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)
- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)
- [real command queue first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-closure-review.md)
- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real command queue first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real command queue branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-branch-next-boundary-decision.md)
- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-next-boundary-decision.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)
- [real drawable first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-manifest-stabilization-closure-review.md)

## 下次开 gate 前必须读取

开任何 native bridge、platform object、Metal device、command queue、drawable、command buffer、render pass、GPU submission、backend readiness finalization 或 backend implementation gate 前，至少读取 real render pass first implementation slice manifest closure、real render pass first implementation slice manifest、real render pass first implementation slice next-boundary decision、real render pass first implementation slice closure、real render pass first implementation preflight decision、real command buffer branch next-boundary decision、real command buffer first implementation slice manifest closure、real command buffer first implementation slice manifest、real command buffer first implementation slice next-boundary decision、real command buffer first implementation slice closure、real command buffer first implementation preflight decision、real drawable branch next-boundary decision、real drawable first implementation slice manifest closure、real drawable first implementation slice manifest、real drawable first implementation slice next-boundary decision、real drawable first implementation slice closure、real drawable first implementation preflight decision、real command queue branch next-boundary decision、real command queue first implementation slice manifest closure、real command queue first implementation slice manifest、real command queue first implementation slice next-boundary decision、real command queue first implementation slice closure、real command queue first implementation preflight decision、real Metal device-layer branch next-boundary decision、first slice manifest、manifest stabilization closure、build recovery closure、build verification follow-up、slice next-boundary decision、slice closure、first implementation preflight decision、native teardown contract hardening manifest、manifest closure、native teardown contract hardening next-boundary decision、native teardown contract hardening value boundary closure、real backend platform object branch next-boundary decision、real backend platform object first implementation slice manifest、manifest stabilization closure、slice next-boundary decision、real backend platform object first implementation slice closure、real backend platform object first implementation preflight decision、real backend implementation planning reset decision、implementation admission branch reconciliation scan、backend readiness implementation branch next-boundary decision、branch milestone、backend readiness implementation admission manifest、backend readiness implementation finalization admission closure、backend readiness manifest、backend readiness branch milestone、native resource bridge manifest、platform object implementation admission manifest、backend platform object owner manifest、Metal device-layer owner manifest、Metal device-layer implementation admission manifest、real command queue lifecycle manifest、real command queue implementation admission manifest、real drawable lifecycle manifest、real drawable implementation admission manifest、real command buffer lifecycle manifest、real command buffer implementation admission manifest、render pass lifecycle manifest、render pass implementation admission manifest、backend shell skeleton manifest、command submission manifest、Metal reference pack、smoke README、implementation admission topic manifest 和当前 tracker 的 Renderer 段落。

## 推荐下一步

当前推荐下一步与 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md) 保持一致：

`P1 internal Renderer real render pass branch closure / next real render pass decision`

这表示下一轮应只做 real render pass branch closure / next real render pass decision，确认 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()` 与 first slice manifest 是否足够作为当前 no-real-render-pass-shell branch 封账，并选择 stop、encoder first implementation preflight、render pass shell hardening 或 native bridge render pass write-set preflight。不得借这些证据靠近 native bridge、真实 render pass descriptor、attachment / texture view、`renderCommandEncoder`、`endEncoding`、encoder、pipeline、draw call、GPU submission、renderer state write、backend ready truth 或 public API。

## 禁止误读点

- no-* readiness / admission facts 不是 permission wrapper。
- native resource bridge readiness 不是 native handle permission、C ABI permission、FFI permission、platform object permission、Metal permission、GPU submission permission 或 render permission。
- `CjguiInternalRendererNoBackendReadyImplementationReadiness` 不是 backend-ready permission、resource-ready wrapper、state-visible wrapper、renderer-state-write wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper 或 receipt / record / publication。
- implementation admission branch stop here / wait 不是 backend-ready permission，也不是 real backend implementation planning reset 已获批准。
- `STOP / wait for user direction on real backend implementation planning reset` 不是 backend implementation permission。
- real backend implementation planning reset decision 不是 direct implementation permission；platform object first preflight 仍不得创建 platform object、native handle、raw pointer、C ABI、FFI、Metal / AppKit object、command queue、drawable、command buffer、GPU submission、renderer state write 或 public API。
- real backend platform object first implementation preflight 不授权 native bridge / Objective-C / Metal / AppKit；如果下一刀必须触碰 bridge、retain / release / destroy、C ABI / FFI 或 native handle，必须先回退到 native teardown contract hardening preflight。
- real backend platform object first implementation slice 不是 platform object permission、native handle permission、backend-ready permission、resource-ready permission、Metal / AppKit permission、GPU submission permission、renderer state write permission 或 public API permission。
- real backend platform object branch next-boundary decision 不是 native bridge permission、native handle permission、Metal device permission、resource-ready permission 或 backend-ready permission。
- native teardown contract hardening preflight 只能先做 docs-only risk hardening，仍不是 retain / release / destroy、C ABI / FFI、Objective-C、Metal、AppKit 或 native handle implementation permission。
- native teardown contract hardening value boundary 也不能成为 native-handle-ready、bridge-ready、Metal-ready、resource-ready 或 backend-ready wrapper。
- native teardown contract hardening closure / next decision 只是确认 endpoint 足够进入 manifest stabilization，不是 native bridge、retain / release / destroy、native handle、Metal / AppKit、backend-ready、renderer state write 或 public API permission。
- native teardown contract hardening manifest stabilization 只固定 owner / truth / stop-line；它不是 real Metal device-layer implementation permission，也不是 `MTLDevice` / `CAMetalLayer` creation permission。
- real Metal device-layer first implementation preflight 不是 command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth、public API 或 browser engine / foreign surface permission；它也不是未经 write-set preflight 的 native bridge / C ABI / FFI expansion permission。
- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 不是 `MTLDevice` / `CAMetalLayer` creation permission、device-ready permission、layer-ready permission、backend-ready permission、GPU submission permission、renderer state write permission、native bridge permission 或 public API permission。
- real Metal device-layer first implementation slice build recovery 只恢复构造一致性与 build 通过，不得误读成 backend-ready、Metal-ready、device-ready、layer-ready 或 resource-ready evidence。
- real Metal device-layer first implementation slice manifest stabilization 只固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line；它不是 branch-ready、Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、native-handle-ready、GPU-submission、render-permission、public diagnostics、receipt / record / publication 或 public API wrapper。
- real Metal device-layer branch next-boundary decision 只选择下一步 docs-only command queue preflight；它不是 `MTLCommandQueue` permission、queue-ready wrapper、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。
- real command queue first implementation preflight 只选择下一步极窄 command queue owner shell；它不是 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、queue-ready wrapper、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。
- `CjguiInternalRendererNoRealCommandQueueShellReadiness` 不是 drawable permission、`nextDrawable` permission、present permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。
- `CjguiInternalRendererNoRealDrawableShellReadiness` 不是 drawable acquisition permission、`nextDrawable` permission、present permission、command buffer permission、native handle permission、C ABI / FFI permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics 或 public API permission。
- `CjguiInternalRendererNoRealCommandBufferShellReadiness` 不是 command buffer creation permission、`commandBuffer` permission、`commit` permission、render pass permission、encoder permission、pipeline permission、draw call permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics 或 public API permission。
- `CjguiInternalRendererNoRealRenderPassShellReadiness` 不是 render pass descriptor creation permission、attachment / texture view permission、encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、command buffer permission、`commandBuffer` permission、`commit` permission、`present` permission、`nextDrawable` permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics 或 public API permission。
- `labs/macos_bridge_smoke` 的 evidence 只能辅助 feasibility / teardown / smoke 判断，不能升格 runtime truth。

## 维护备注

本 manifest 已按设计意图出口协议同步 real command buffer 到 real render pass first-slice macro。当前唯一 next opening 是 `P1 internal Renderer real render pass branch closure / next real render pass decision`。若未来真正靠近 native handle token、C ABI、FFI、真实 platform object、真实 Metal resource、真实 `MTLCommandQueue`、drawable acquisition、`nextDrawable`、`present`、command buffer creation、`commandBuffer`、`commit`、render pass descriptor、attachment、texture view、encoder、backend-ready truth、public diagnostics 或 readiness read surface，必须先补对应 docs-only preflight，并在本 manifest 中更新当前 tail、推荐下一步与禁止误读点。
