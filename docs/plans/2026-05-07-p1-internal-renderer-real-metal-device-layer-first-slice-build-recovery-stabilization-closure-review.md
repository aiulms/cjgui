# 渲染器真实 Metal device-layer 第一刀切片 build 恢复闭环复核

日期：2026-05-07

本轮性质：build recovery / stabilization / internal-only owner consistency fix。

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer first slice build recovery and stabilization bundle`。目标是恢复 [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj) 的构建可用性，并把 real Metal device-layer first implementation slice 推回可封账状态。

本轮只修改既有 owner 文件，不新增 runtime owner，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer，不创建真实 `MTLDevice`、真实 `CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state、shader、descriptor 或 draw call，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不新增 module-level `var`，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把 build recovery 解释成 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、GPU-submission、render-permission、receipt、record 或 publication。

## GitNexus 影响记录

本轮按要求先跑 GitNexus impact：

- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft`

GitNexus 当前索引未命中这两个近期新增 internal shell 符号，返回 risk `UNKNOWN` 与 impacted count `0`。本轮据此没有把未知风险当作安全许可，而是把 write set 限定在 [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj) 内，并用本地构造点审计确认所有修复只影响该 owner 的 value construction consistency。

## 失败根因

上一轮 build verification follow-up 已确认 toolchain env 不是根因：通过 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 后，`cjpm` 与 `cjc` 均可用，build 已进入 `cjgui` package 编译阶段。

实际根因是 owner 内构造调用与类型定义字段数量不一致：

- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 的类型定义是 `teardownProof` 加 29 个 `Bool`。
- 4 个 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 构造点传入了 `teardownProof` 加 30 个 `Bool`。
- build recovery 过程中进一步发现先前泛化补丁曾影响同 owner 内更早的构造块，导致 `CjguiInternalRendererRealMetalDeviceLayerIntent(...)` 与 `CjguiInternalRendererRealMetalDeviceShellPolicy(...)` 的部分构造点少传参数。

这些错误均属于同一 owner 内的字段数量 / 顺序一致性问题，不涉及 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、真实 native resource、GPU submission、renderer state write 或 public API。

## 修复范围

修复范围仅限：

- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

修复内容：

- 以类型定义作为 source of truth，对齐 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 的 4 个构造点，使其全部为 `teardownProof` 加 29 个 `Bool`。
- 复核并恢复同 owner 内 `CjguiInternalRendererRealMetalDeviceLayerIntent(...)` 的 4 个构造点，使其全部为 input 加 13 个 `Bool`。
- 复核并恢复 `CjguiInternalRendererRealMetalDeviceShellPolicy(...)` 的 4 个构造点，使其全部为 input 加 12 个 `Bool`。
- 确认 `CjguiInternalRendererRealMetalLayerBindingShellPolicy(...)`、`CjguiInternalRendererRealMetalDeviceLayerTeardownProof(...)`、default draft 与 builder 链保持一致。

未改变：

- canonical endpoint：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`
- runtime input：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- current truth：real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts
- stop-line 与 Same-shape Boundary Brake

## 边界保持

本轮仍保持 no-real-Metal / no-native / no-GPU 边界：

- 不创建真实 `MTLDevice`。
- 不创建真实 `CAMetalLayer`。
- 不创建 `MTLCommandQueue`。
- 不获取 drawable。
- 不创建 command buffer、render pass、encoder、pipeline state、shader、descriptor 或 draw call。
- 不提交 GPU work，不执行 render。
- 不修改 native bridge / Objective-C / Metal / AppKit。
- 不新增 C ABI / FFI declaration。
- 不调用 bridge / retain / release / destroy。
- 不创建 native handle / raw pointer。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不新增 module-level `var`。
- 不发布 public diagnostics / API，不扩 public API。

## 验证记录

使用 toolchain env：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
```

在 [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui) 下执行：

```bash
cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script
```

结果：通过。

build 输出仍包含既有 `unused` warnings；本轮不新增 compile error，未观察到与 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write 或 public API 相关的新 warning / error。

smoke：

```bash
labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：通过，`auto-close log assertions passed`。该 smoke 仍只作为 labs feasibility / teardown evidence，不是 runtime truth。

## 同形边界刹车

本轮是 build recovery，不新增 wrapper、receipt、record、publication、permission 字段或新的 endpoint。不得把本轮 build 通过解释成真实 `MTLDevice` / `CAMetalLayer` permission、native bridge permission、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

## 下游同步

本闭环同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation slice build verification follow-up](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-build-verification-follow-up.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 build verification follow-up completed / build failed 推进到 build recovery and stabilization completed / build passed。
- 本轮是否改变 canonical tail / endpoint：否，当前 endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，本轮只修复 owner 内构造一致性；owner file、current truth 与 stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`

## 下游 manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 manifest 只把本闭环恢复出的可编译 owner shell 固定为 docs evidence；build recovery 仍只证明构造一致性与 build 通过，不证明真实 Metal resource、native bridge、Objective-C / Metal / AppKit、command queue、drawable、GPU submission、renderer state write、backend ready truth 或 public API 可用。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`
