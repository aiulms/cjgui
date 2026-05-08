# 渲染器真实 Metal device-layer 第一刀切片 build 验证跟进

日期：2026-05-07

状态：build verification follow-up / no code change / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`。目标是补齐 [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md) 记录的 build verification gap。

本轮不修改 `.cj`，不新建 runtime owner，不推进功能，不做 manifest stabilization，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer，不创建真实 `MTLDevice`、真实 `CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把 build failure 包装成 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、receipt、record 或 publication。

## 上轮缺口

上一轮 [slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md) 已记录：bare `cjpm` 与交互式 zsh 均找不到 `cjpm`，因此 `cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script` 未完成。

本轮先确认 bare `cjpm` 仍不在当前 shell 与交互式 zsh 的 PATH 中，然后定位到本机可用工具链：

- `envsetup`：`/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`
- `CANGJIE_HOME`：`/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- `cjpm`：`/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin/cjpm`
- `cjc`：`/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin/cjc`

直接运行 `/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin/cjpm --version` 在未 source `envsetup.sh` 时仍失败，原因是 `cjpm` 需要通过 envsetup 配置 `cjc`、`CANGJIE_HOME` 与 `DYLD_LIBRARY_PATH`。

## 本轮工具链方式

本轮使用以下方式进入工具链环境：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
```

source 后确认：

- `cjpm=/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/bin/cjpm`
- `cjc=/Users/jiangxuanyang/cangjie-toolchains/cangjie/bin/cjc`
- `CANGJIE_HOME=/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- `DYLD_LIBRARY_PATH` 包含 `/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative` 与 `/Users/jiangxuanyang/cangjie-toolchains/cangjie/tools/lib`

本轮 build 在包目录 [runtime/cjgui](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui) 下执行，符合 follow-up 要求。

## 实际 build 命令

实际命令：

```bash
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script
```

执行目录：

```text
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui
```

## build 结果

build 未通过。

失败归类：代码问题。

理由：工具链环境已经恢复，`cjpm` 与 `cjc` 均可通过 envsetup 找到，build 进入 `cjgui` package 编译阶段后失败。错误来自 [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)，不是 `cjpm`、`cjc` 或 PATH 缺失。

编译器报错摘要：

- `runtime_renderer_metal_device_layer_real.cj:913:68`：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` expected 30 arguments, found 31。
- `runtime_renderer_metal_device_layer_real.cj:949:68`：同类参数数量错误。
- `runtime_renderer_metal_device_layer_real.cj:985:68`：同类参数数量错误。
- `runtime_renderer_metal_device_layer_real.cj:1020:64`：同类参数数量错误。

候选 constructor 位于 `runtime_renderer_metal_device_layer_real.cj:282`，参数列表为 `teardownProof` 加 29 个 `Bool`，总计 30 个参数；上述 4 个返回分支均传入 31 个参数。

## warning 与 error 记录

本轮 build 没有进入“通过但带 warning”的状态。

本轮实际出现的是 4 个 compile error。它们都集中在同一个 owner shell 的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 构造调用参数数量不匹配；未观察到与 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write 或 public API 相关的新 warning / error。

## smoke 结果

`labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，输出 `auto-close log assertions passed`。

该 smoke 仍只作为 labs feasibility / teardown evidence，不是 runtime truth，不授权 native bridge、Metal / AppKit、GPU submission、renderer state write、backend-ready truth 或 public API。

## 候选结论

### 候选 A：build 成功后 manifest stabilization

不选择。build 未通过，因此不能进入 `P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`。

### 候选 B：环境恢复决策

不选择。环境缺口已被定位并恢复到可执行 build 的程度：通过 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 能找到 `cjpm` 与 `cjc`，build failure 已进入代码编译阶段。

### 候选 C：推荐

`P1 internal Renderer real Metal device-layer first slice build fix bundle`

选择 C。下一步应只修复 `runtime_renderer_metal_device_layer_real.cj` 中 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 的构造参数数量不匹配，并重新运行同一 build 与 smoke 验证。

### 候选 D 到 F：拒绝

拒绝跳过 build gap 直接 manifest stabilization。拒绝继续进入 command queue、drawable 或 GPU work。拒绝修改 native bridge、Metal 或 AppKit 以绕过验证。

## 同形边界刹车

本轮 build failure 不得被包装成 Metal-ready、device-ready、layer-ready、native-handle-ready、backend-ready、resource-ready、GPU-submission、render-permission、public diagnostics、receipt / record / publication。

下一步 build fix 只能处理构造参数数量不匹配，不得顺手引入 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、native handle、真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API。

## 停止线

本轮继续禁止：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no real `MTLDevice`。
- no real `CAMetalLayer`。
- no `MTLCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no draw call。
- no GPU submission。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。
- no backend ready truth。

## 下游同步

本 follow-up 同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 slice next-boundary decision completed 推进到 build verification follow-up completed，但 build 未通过。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime shell endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，本轮未修改 `.cj`，未新增 owner，未改变 current truth 或 stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first slice build fix bundle`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first slice build fix bundle`

## 下游 build 恢复闭环

下游 real Metal device-layer first slice build recovery and stabilization 已完成：

- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)

该闭环只在 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj` 内修复构造参数一致性，`CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)`、`CjguiInternalRendererRealMetalDeviceLayerIntent(...)` 与 `CjguiInternalRendererRealMetalDeviceShellPolicy(...)` 构造点已对齐类型定义。`cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script` 通过，auto-close smoke 通过；canonical endpoint、default draft、runtime input、truth 与 stop-line 不变。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`
