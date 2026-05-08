# 渲染器真实 Metal device-layer 第一刀切片 manifest 稳定化闭环复核

日期：2026-05-07

本轮性质：docs-only manifest stabilization closure / no runtime truth。

## 文件定位

本文件复核 `P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation` 的封账结果。本轮不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer、真实 `MTLDevice`、真实 `CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，也不扩 public API。

本 closure 不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)。它只确认 manifest 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line，并记录下一步 branch closure / next decision。

## 封账结论

已新增 [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)。

manifest 固定：

- owner file：`runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`
- canonical endpoint：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`
- runtime input：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- current truth：real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts

本轮没有改变 endpoint、default draft、runtime input、owner truth 或 stop-line。上一轮 build recovery 只作为 owner shell 可编译证据；它不证明真实 `MTLDevice`、真实 `CAMetalLayer`、native bridge、Objective-C / Metal / AppKit、command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API 可用。

## 候选结论

选择 A：`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`。

理由：real Metal device-layer first implementation slice 已完成 slice、next-boundary decision、build verification follow-up、build recovery 与 manifest stabilization。下一步应做 branch closure / next decision，判断是否 stop here、进入 native bridge write-set preflight、进入 real command queue first implementation preflight，或继续 shell hardening；不得跳过 branch closure 直接进入 command queue、drawable、GPU work、renderer state write、backend ready truth 或 public API。

B `native bridge write-set preflight decision` 暂缓；C `real command queue first implementation preflight` 暂缓；D `real Metal device-layer shell hardening` 暂缓。

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct native handle / raw pointer creation、direct real `MTLDevice` / `CAMetalLayer` creation without preflight、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

## 边界保持

本轮仍保持 no-real-Metal / no-native / no-GPU / no-state / no-public 边界：

- 不修改 native bridge / Objective-C / Metal / AppKit。
- 不新增 C ABI / FFI declaration。
- 不调用 bridge / retain / release / destroy。
- 不创建 native handle / raw pointer。
- 不创建真实 `MTLDevice`。
- 不创建真实 `CAMetalLayer`。
- 不创建 `MTLCommandQueue`。
- 不获取 drawable。
- 不创建 command buffer、render pass、encoder、pipeline state、shader、descriptor 或 draw call。
- 不提交 GPU work，不执行 render。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不新增 module-level `var`。
- 不发布 public diagnostics / API，不扩 public API。
- 不创建 backend ready truth。

## 同形边界刹车

本轮只做 manifest 封账，不新增 tail wrapper。`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 不得包装成 Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication 或 public API wrapper。

下一步 branch closure / next decision 只能判断是否 stop、hardening 或 preflight；不得把 manifest、closure、build recovery 或 topic manifest summary 当成真实 Metal resource permission。

## 下游同步

本闭环同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 验证记录

按本轮 docs-only 要求，未运行 `cjpm build`，未运行 smoke。上一轮 build recovery 已记录 `cjpm build` 与 auto-close smoke 均通过；本轮仅复核文档与边界同步。

本轮计划并执行的验证包括：

- `git diff --check`
- 新 manifest / closure no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- comment-aware public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real Metal device-layer first slice build recovery completed / build passed 推进到 first implementation slice manifest stabilization completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`；native resource bridge tail 仍未改变。
- 本轮是否改变 owner / truth / stop-line：否，本轮只固定 manifest；owner file、current truth 与 stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`
