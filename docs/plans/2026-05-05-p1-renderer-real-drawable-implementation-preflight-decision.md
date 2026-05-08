# P1 Renderer 真实 drawable implementation preflight 决策

日期：2026-05-05

状态：docs-only preflight 已完成

## 决策结论

本轮允许打开真实 drawable implementation runway，但不批准真实 drawable 获取、`nextDrawable`、drawable 展示、native handle、bridge call、command buffer creation、GPU submission 或 render implementation。

下一步选择：

`P1 internal Renderer real drawable implementation admission value boundary bundle implementation`

该下一步仍必须是 internal value boundary，只能表达真实 drawable implementation admission value facts，不能获取真实 drawable。

## 证据读取

- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()`，作为 no-real-command-queue-implementation endpoint。
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 已提供 drawable availability、acquisition guard、presentation ownership 与 no-real-drawable 词汇，但不获取 drawable，也不调用 `nextDrawable`。
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md) 已冻结 device / layer implementation admission facts，不创建 `MTLDevice`、`CAMetalLayer`、command queue、drawable 或 command buffer。
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) 继续把 native handle、C ABI、FFI declaration、bridge call、retain / release / destroy 与 platform object 行为排除在 runtime truth 之外。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) 已记录 no-gpu-submission facts，并拒绝 command buffer creation、`commit`、`present`、`nextDrawable`、GPU submission、render execution 与 renderer state write permission。
- [backend Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只能作为 evidence：`CAMetalLayer.nextDrawable()` 是 late-bound，可能等待或失败，drawable 属于 layer，drawable texture exposure 必须保持 backend-local。
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 要求在引入任何手动管理的 GPU / native object 前，先明确 resource ownership、teardown、unavailable / failure 与 FFI 边界。
- [macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/) 只保留 feasibility、teardown 与 smoke evidence；它的 Metal clear path、drawable metadata、screenshot summary 与 auto-close path 都不是 runtime truth。

## 预检回答

证据足以打开真实 drawable implementation runway，但只能以 value-only implementation admission boundary 进入。

本轮不需要先拆成更窄的 drawable acquisition admission、drawable presentation admission、drawable starvation / failure policy 或 layer availability hardening，因为现有 evidence 已经冻结足够词汇：

- real command queue implementation admission 已提供上游 no-real-command-queue-implementation endpoint。
- real drawable lifecycle manifest 已以 dehydrated value facts 记录 drawable availability、acquisition guard、presentation ownership 与 no-real-drawable 语义。
- Metal device-layer implementation admission 继续保持 device / layer facts value-only，并拒绝真实 `CAMetalLayer` / drawable permission。
- native resource bridge manifest 继续把 native handle、bridge、FFI 行为排除在 runtime truth 之外。
- command submission manifest 已记录 presentation / commit / no-submit 词汇，并明确拒绝 `present`、`commit`、`nextDrawable` 与 GPU submission。
- risk ledger 说明 unavailable drawable、ownership、teardown 与 fail-closed admission facts 是获取任何真实 drawable object 前的硬前置。

下一步 value boundary 的唯一 runtime input candidate 是：

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness`

`CjguiInternalRendererNoRealDrawableReadiness`、`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`、command submission facts、reference pack evidence 与 smoke evidence 只能作为 docs evidence，不能成为额外 runtime input。

下一步 value boundary 的 output truth 必须限于：

- real drawable implementation intent。
- drawable acquisition admission policy。
- drawable availability admission guard。
- drawable presentation admission policy。
- no-real-drawable-implementation readiness value facts。

推荐 owner candidate：

`runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj`

## 候选比较

### A. `P1 internal Renderer real drawable implementation admission value boundary bundle implementation`

推荐。

理由：这是下一刀最窄且有用的切口。它新增 drawable acquisition admission、availability admission、presentation admission 与 no-real-drawable-implementation 语义，但不调用 `nextDrawable`，不获取 drawable，不展示 drawable，不新增 native handle、FFI / C ABI，不创建 command buffer，也不靠近 GPU submission。

### B. `P1 internal Renderer real drawable acquisition admission preflight decision`

暂不选择。

理由：acquisition timing 与 layer availability evidence 已足以支撑 value-only admission boundary。real drawable lifecycle manifest 已记录 late-bound acquisition guard、unavailable fallback 与 no borrowed resource facts，Metal device-layer implementation admission 也拒绝真实 layer / drawable permission。

### C. `P1 internal Renderer drawable presentation admission preflight decision`

暂不选择。

理由：presentation ownership / command submission relation evidence 已足以形成 admission facts。real drawable lifecycle manifest 记录 presentation ownership facts，command submission manifest 记录 no-present / no-commit / no-submit gates，但不授予 present permission。

### D. `P1 internal Renderer drawable starvation / failure policy preflight decision`

暂不选择。

理由：unavailable drawable、timeout 与 fail-closed concerns 确实存在，但下一步 value boundary 已可表达 drawable availability admission guard 与 no-real-drawable-implementation readiness，不需要实现 blocking behavior、timeout handling 或 callback。

### E. real command buffer implementation preflight

暂缓。command buffer creation 必须晚于 drawable implementation admission manifest stabilization。

### F. render completion / frame completion tracking preflight

暂缓。completion tracking 靠近 callback、diagnostics、telemetry 与 renderer state visibility。

### G. real backend shell implementation preflight

暂缓。backend shell implementation 与 drawable implementation admission 分属不同风险，不应过宽地暗示 resource ownership。

### H 到 R

以下方向拒绝或不选择：direct drawable acquisition implementation、direct `nextDrawable` call、direct drawable present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication、consolidation。

consolidation 只有在明确 duplicate / low-value / self-wrapping evidence 出现时才选择；当前没有这类证据。

## 同构边界刹车（Same-shape Boundary Brake）

下一步不得把 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`、`CjguiInternalRendererNoRealDrawableReadiness`、`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 或 smoke evidence 包成以下形态：

- real drawable implementation receipt / record / publication。
- drawable-ready permission wrapper。
- `nextDrawable` permission wrapper。
- present permission wrapper。
- native-handle permission wrapper。
- C ABI / FFI permission wrapper。
- backend implementation wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一步推进 value boundary，必须新增的是：

- drawable acquisition admission。
- drawable availability admission。
- drawable presentation admission。
- no-real-drawable-implementation readiness。

## 停止线

本决策不批准：

- drawable acquisition。
- `nextDrawable`。
- drawable present。
- command buffer creation。
- native handle。
- raw pointer。
- C ABI。
- FFI declaration。
- bridge call。
- retain / release / destroy。
- Metal / AppKit / Objective-C call。
- GPU submission。
- render execution。
- renderer state write。
- public API。

本决策也不批准 backend shell object、backend object、platform object、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable object、command buffer、render pass、encoder、pipeline state、`commit`、`present`、diagnostics output、event bus、observer、telemetry 或 public C ABI。

## smoke 证据边界

`labs/macos_bridge_smoke` 只能作为 feasibility / teardown / smoke evidence。它的 Metal setup、drawable frame metadata、readback logs、screenshot summary 与 auto-close path 都不会成为 runtime truth，不定义 runtime drawable owner，不授权 `nextDrawable`，不授权 drawable acquisition / present，也不授权 native handle、C ABI / FFI、GPU submission、render correctness 或 renderer state write。

## 下游指向

本 preflight 的下游已进入 value boundary implementation，并由以下 closure 收束：

- [2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md)

后续 next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 已足够作为当前 no-real-drawable-implementation endpoint，并选择下一步 docs-only manifest stabilization。

后续 manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj` owner / truth / canonical endpoint / default draft / stop-line / Same-shape Boundary Brake，并把下游 opening 收敛到 docs-only real command buffer implementation preflight。

当前 downstream next opening：

`P1 internal Renderer real command buffer implementation preflight decision`
