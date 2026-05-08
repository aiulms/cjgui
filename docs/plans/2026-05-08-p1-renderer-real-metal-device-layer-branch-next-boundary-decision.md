# 渲染器真实 Metal device-layer 分支后续边界决策

日期：2026-05-08

状态：docs-only decision / no native implementation / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`。本轮只确认当前 real Metal device-layer shell endpoint 与 first slice manifest 是否足够作为本分支阶段封账，并选择下一步 docs-only 入口。

本轮 docs-only，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit 代码，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer，不创建真实 `MTLDevice`、真实 `CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state 或 draw call，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把 first slice manifest、build recovery closure 或 topic manifest summary 升格为真实 Metal resource permission。

## 入口复核

本轮先读取设计意图入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

随后读取并采用以下阶段原文：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)
- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 当前端点判断

确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint。

确认 [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md) 足够作为本分支阶段封账。该 manifest 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line；[build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md) 只证明 owner shell 可编译，不证明真实 Metal resource 可用。

当前 endpoint 只代表 real Metal device-layer shell / dehydrated native result facts，也就是 real Metal device-layer intent、device shell policy、layer binding shell policy、teardown proof 与 no-real-metal-device-layer readiness facts。

它不是：

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

## 下一阶段判断

选择 A：`P1 internal Renderer real command queue first implementation preflight decision`。

理由：

- 当前 device-layer shell endpoint 与 manifest 已足够作为 planning evidence。
- 下一步仍是 docs-only preflight，不允许直接创建 `MTLCommandQueue`。
- 当前下一步并不需要直接修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy 或 native handle，因此不必先选择 native bridge write-set preflight。
- 如果后续 command queue preflight 发现真实 queue 第一刀必须触碰 native bridge 或 C ABI / FFI，必须在该轮 fail-closed 并转向 native bridge write-set preflight。

## 候选比较

A 推荐：`P1 internal Renderer real command queue first implementation preflight decision`

选择。下一轮只能做 docs-only preflight，评估 command queue 第一刀的 owner、write set、teardown proof、failure mode 与 no-command-queue / no-GPU stop-line，不能直接创建 `MTLCommandQueue`。

B 备选：`P1 internal Renderer native bridge write-set preflight decision`

暂不选择。当前分支 closure 不需要直接靠近真实 `MTLDevice` / `CAMetalLayer` 或 native bridge 修改；若下一轮 command queue preflight 证明 write set 不清楚，再回退到 B。

C 备选：`STOP / wait for user direction before command queue or native bridge work`

暂不选择。用户已明确要求本轮判断下一阶段，且现有 shell / manifest 可支撑进入 docs-only command queue preflight。

D 暂缓：real Metal device-layer shell hardening。

E 暂缓：real drawable acquisition implementation preflight。

F 拒绝：direct native bridge / Objective-C / Metal / AppKit modification。

G 拒绝：direct native handle / raw pointer creation。

H 拒绝：direct real `MTLDevice` / `CAMetalLayer` creation。

I 拒绝：direct command queue / drawable / command buffer。

J 拒绝：direct render / GPU submission。

K 拒绝：direct renderer state write。

L 拒绝：public API / C ABI expansion。

M 拒绝：receipt / record / publication wrapper。

N 拒绝：继续新增 Metal-ready / device-ready thin wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`、slice manifest、build recovery closure 或 topic manifest 包成 Metal-ready wrapper、device-ready wrapper、layer-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

下一阶段只能是 command queue first implementation preflight 或 native bridge write-set preflight。不得继续新增同构 wrapper，也不得把本 decision 解释成 branch-ready、Metal-ready、device-ready、layer-ready 或 backend-ready endpoint。

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
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real Metal device-layer first slice manifest stabilization completed 推进到 real Metal device-layer branch next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 shell endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`；native resource bridge tail 仍未改变。
- 本轮是否改变 owner / truth / stop-line：否，本轮 docs-only 复核并重申 stop-line；owner file、current truth 与 runtime stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command queue first implementation preflight decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real command queue first implementation preflight decision`

## 下游真实 command queue 第一刀预检

下游 real command queue first implementation preflight decision 已完成：

- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)

该 downstream decision 继续只把本文件确认的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 作为 planning evidence，不把 real Metal device-layer shell endpoint、first slice manifest、build recovery closure 或 topic manifest 升格为 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、queue-ready permission、drawable permission、command buffer permission、GPU submission permission、renderer state write permission、backend ready truth 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice bundle`
