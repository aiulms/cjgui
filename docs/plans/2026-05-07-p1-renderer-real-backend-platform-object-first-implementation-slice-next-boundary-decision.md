# 渲染器真实后端 platform object 第一刀实现切片后续边界决策

日期：2026-05-07

状态：docs-only closure decision / no native platform object permission

## 文件定位

本文件承接 [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)，确认当前 shell endpoint 是否足够封账，并选择后续是否进入 manifest stabilization。

本轮是 docs-only，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge、Objective-C、Metal 或 AppKit 代码，不新增 C ABI / FFI declaration，不创建 native handle、raw pointer、Metal resource、GPU submission、renderer state write、public diagnostics 或 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)

入口状态确认：设计意图地图已将主题推进到 first implementation slice completed，当前唯一后续入口是本 closure / next decision。本轮若改变 next opening，必须同步两个 Renderer topic manifest。

## 当前端点复查

当前 owner file：

- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

当前 canonical endpoint：

- `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

本轮确认：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。它已经覆盖 real backend platform object intent、shell policy、teardown proof、failure policy 与 no-real-backend-platform-object readiness facts，并保持 open path dehydrated、defer-only 保持 defer、blocked / inconsistent fail-closed 的姿态。

当前 endpoint 只代表：

- real backend platform object intent facts。
- shell policy facts。
- teardown proof facts。
- failure policy facts。
- no-real-backend-platform-object readiness facts。

当前 endpoint 明确不是：

- native platform object permission。
- native handle permission。
- backend ready permission。
- Metal device permission。
- resource-ready permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- public API permission。

## 决策结论

选择候选 A：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游切片 manifest 稳定化

下游 manifest stabilization 已完成：

- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend platform object first implementation slice manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream 仅固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line。`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 仍不是 platform object permission、native handle permission、backend-ready permission、resource-ready permission、Metal-device permission、GPU-submission permission、render-permission wrapper、public diagnostics wrapper 或 receipt / record / publication。

新的下游后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`

理由：当前 shell endpoint 已足够作为 no-real-backend-platform-object shell endpoint。下一步应只做 manifest stabilization，固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line，并继续声明该 shell 不是 native platform object permission、native handle permission、backend-ready permission、Metal device permission、GPU submission permission、renderer state write permission 或 public API permission。

本轮不选择 native teardown contract hardening、real Metal device-layer first implementation preflight 或 shell hardening，因为当前证据没有显示 teardown、failure shape 或 shell vocabulary 缺口。继续靠近 native bridge / Metal 会越过当前 stop-line。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

推荐。只固定 owner、truth、canonical endpoint、default draft、runtime input 与 stop-line，不新增 tail wrapper，不修改 native bridge，不创建 native handle 或 Metal resource。

### 候选 B：暂缓

`P1 internal Renderer native teardown contract hardening preflight`

暂缓。只有当后续必须触碰 bridge、retain / release / destroy、C ABI / FFI、Objective-C、Metal 或 AppKit 时，才先回退到该 preflight。

### 候选 C：暂缓

`P1 internal Renderer real Metal device-layer first implementation preflight`

暂缓。Metal device-layer 仍依赖 platform object shell manifest 封账，不应在 shell endpoint 未 manifest-stabilized 前打开。

### 候选 D：暂缓

`P1 internal Renderer real backend platform object shell hardening`

暂缓。当前 closure 没有发现 shell facts、teardown proof 或 failure policy 的明确缺口。

### 候选 E 到 L：拒绝

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct native handle / raw pointer creation、direct `MTLDevice` / `CAMetalLayer` creation、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

### 候选 M：仅在证据出现时合并

Consolidation 只在明确 duplicate / self-wrapping evidence 出现时选择；本轮没有发现该证据。

## 同形边界刹车

`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 不得继续包装成 platform-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

下一步若选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / stop-line，并继续证明该 endpoint 是 shell facts，不是 permission wrapper。

## 停止线

继续禁止：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no `MTLDevice`。
- no `CAMetalLayer`。
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

本决策需要同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 first implementation slice completed 推进到 first implementation slice next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 shell endpoint 仍是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`；backend readiness implementation branch tail 仍是 `CjguiInternalRendererNoBackendReadyImplementationReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，owner 仍是 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`，truth 仍限于 shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts，stop-line 仍禁止 native bridge、native handle、Metal / AppKit、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`
