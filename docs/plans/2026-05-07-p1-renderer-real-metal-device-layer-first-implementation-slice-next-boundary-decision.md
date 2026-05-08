# 渲染器真实 Metal device-layer 第一刀切片后续边界决策

日期：2026-05-07

状态：docs-only decision / no native implementation / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`。本轮只确认当前 real Metal device-layer owner shell 是否足够作为 no-real-metal-device-layer shell endpoint，并判断下一步应先补 build verification gap，还是可以进入 manifest stabilization。

本轮 docs-only，不修改 `.cj`，不新建 runtime owner，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer，不创建真实 `MTLDevice`、真实 `CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把上一轮 shell facts 升格为真实 Metal resource permission。开后续 Renderer gate 前，仍应先从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 进入，再读取对应 topic manifest 和关键原文链。

## 入口复核

本轮读取并采用以下证据：

- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

设计意图入口、两个 Renderer topic manifest 与上一轮 closure 当前一致：最新 runtime shell endpoint 是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`，唯一 runtime input 是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`。

## 当前 endpoint 判断

`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint。

当前 owner shell 只代表 real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts。它可以作为后续 manifest stabilization 的待封账对象，但在 build verification gap 关闭前，不应直接进入 manifest stabilization。

该 endpoint 不是：

- 真实 `MTLDevice` permission。
- 真实 `CAMetalLayer` permission。
- native handle permission。
- command queue permission。
- drawable permission。
- command buffer permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- backend ready truth。
- public diagnostics / API permission。

## build 缺口判断

上一轮 slice closure 已记录：`cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script` 曾尝试执行，但当前 shell 与交互式 zsh 均未找到 `cjpm`，因此 build 未完成。

该缺口不是 runtime truth failure，也不证明 shell endpoint 语义错误；但它是新增 `.cj` owner shell 的验证缺口。由于 manifest stabilization 的职责是固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line，若在 build gap 未补齐前直接封账，后续执行者容易把未完成验证误读成已完成验证。

因此本轮选择先补 build verification follow-up。manifest stabilization 暂缓，直到后续明确以下任一事实：

- 找到可用 `cjpm` 并完成指定 build。
- 通过项目认可的等价工具链路径完成 build。
- 明确记录为什么 build gap 可作为 residual 进入 manifest，并由后续 closure 承担风险说明。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

选择 A。理由是当前 endpoint 语义足够，但新增 `.cj` owner shell 的 build verification 未完成；下一步应优先补齐工具链路径或构建证据，再决定是否进入 manifest stabilization。

该 follow-up 仍不得把 build gap 处理扩大为 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write 或 public API work。

### 候选 B：备选

`P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`

暂不选择。源码结构、stop-line scan、smoke evidence 与 GitNexus detect_changes 低风险记录支持当前 shell endpoint 语义，但 build 未完成仍是 closure residual。为避免未验证 owner 被过早 manifest 封账，本轮不进入 B。

### 候选 C 到 E：暂缓

native bridge write-set preflight、real command queue first implementation preflight 与 real Metal device-layer shell hardening 暂缓。它们都晚于当前 build verification gap，不能绕过新增 shell owner 的构建确认。

### 候选 F 到 M：拒绝

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct native handle / raw pointer creation、direct real `MTLDevice` / `CAMetalLayer` creation、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

### 候选 N：合并条件

consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择。本轮没有 duplicate 或 self-wrapping evidence。

## 同形边界刹车

`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 不得继续包装成 Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

下一步必须优先处理 build verification gap 或在后续明确选择 manifest stabilization；不得跳到 command queue、drawable、command buffer、GPU work、renderer state write、backend ready truth 或 public API。

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
- no public diagnostics / API。
- no backend ready truth。

## 下游同步

本决策同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real Metal device-layer first implementation slice completed 推进到 slice next-boundary decision completed，并把 build gap 标记为下一步优先处理事项。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime shell endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`；native resource bridge tail 仍未改变。
- 本轮是否改变 owner / truth / stop-line：否，owner file、current truth 与 stop-line 由上一轮 slice closure 固定；本轮只做 docs-only 决策并重申 stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

## 下游 build 验证跟进

下游 real Metal device-layer first implementation slice build verification follow-up 已完成：

- [real Metal device-layer first implementation slice build verification follow-up](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-build-verification-follow-up.md)

该 follow-up 通过 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 恢复 `cjpm` / `cjc` toolchain env，并在 `runtime/cjgui` 下执行 `cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script`。build 进入编译阶段但未通过，失败归类为代码问题：`runtime_renderer_metal_device_layer_real.cj` 中 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 4 个构造分支 expected 30 arguments, found 31。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first slice build fix bundle`

## 下游 manifest 封账

下游 real Metal device-layer first implementation slice build recovery 已完成后，manifest stabilization 也已完成：

- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream manifest 只固定 owner shell 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line。它不把本 decision、build recovery 或 shell endpoint 升格为真实 `MTLDevice` / `CAMetalLayer` permission、native bridge permission、Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`
