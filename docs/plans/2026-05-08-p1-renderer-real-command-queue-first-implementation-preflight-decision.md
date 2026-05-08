# 渲染器真实 command queue 第一刀实现预检决策

日期：2026-05-08

状态：docs-only preflight / no command queue implementation / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real command queue first implementation preflight decision`。本轮只判断 real Metal device-layer first slice 封账后，是否可以打开 real command queue 第一实现切片 runway。

本轮 docs-only，不修改 `.cj`，不新增 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 `runtime/cjgui/src/runtime_state.cj`，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer，不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不获取 drawable，不创建 command buffer，不调用 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不把 Metal device-layer shell、command queue lifecycle manifest、command queue implementation admission manifest、smoke evidence 或 topic manifest summary 升格为 queue-ready permission。

后续若新增 `.cj` owner 文件，必须保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake；注释只解释维护边界，不得把 shell facts、teardown facts 或 admission facts 解释成真实 resource permission。

## 入口复核

本轮先读取设计意图入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

随后读取并采用以下阶段原文：

- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [Renderer backend Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

reference pack 只作为 backend / Metal lifecycle、resource lifetime、command queue / command buffer relation、failure rollback 与 no-draw path evidence；risk ledger 只作为 native handle、retain / release / destroy、main-thread confinement 与 bridge optimism 的风险 evidence。二者均不是 runtime truth。

## 上游端点判断

确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为进入 real command queue planning 的上游 endpoint。

理由：

- real Metal device-layer first slice manifest 已固定 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。
- 该 endpoint 只代表 real Metal device-layer shell / dehydrated native result facts，不创建真实 `MTLDevice` / `CAMetalLayer`。
- native teardown contract hardening manifest 已固定 ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation facts，可作为后续 queue shell 的 teardown / failure vocabulary evidence。
- real command queue lifecycle manifest 与 real command queue implementation admission manifest 已证明 queue creation policy、ownership guard、teardown policy、creation admission、ownership admission 与 teardown failure vocabulary 已存在；这些仍是 docs evidence，不是 runtime input。

该上游 endpoint 不是：

- 真实 `MTLDevice` permission。
- 真实 `CAMetalLayer` permission。
- `MTLCommandQueue` permission。
- `newCommandQueue` permission。
- native handle permission。
- command buffer permission。
- drawable permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- backend ready truth。
- public diagnostics / API permission。

## 第一切片判断

选择打开 real command queue 第一实现切片 runway，但下一轮只能是极窄 internal owner shell / dehydrated native result facts。

默认 owner candidate：

- `runtime/cjgui/src/runtime_renderer_command_queue_real.cj`

runtime input candidate：

- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`

第一切片允许表达的 facts 只限：

- command queue shell intent。
- queue creation admission shell。
- queue ownership proof。
- queue teardown proof。
- queue failure classification。
- no-real-command-queue readiness facts。

这些 facts 只能形成 no-real-command-queue shell endpoint。它们不得创建真实 `MTLCommandQueue`，不得调用 `newCommandQueue`，不得保存 native handle / raw pointer，不得新增 C ABI / FFI，不得调用 bridge / retain / release / destroy，也不得进入 drawable、command buffer、GPU submission、render、renderer state write、backend ready truth 或 public API。

当前不需要先选择 native bridge command queue write-set preflight。原因是下一轮若按 A 执行，仍可完全停留在 runtime internal owner shell 与 dehydrated facts，不需要修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI 或真实 native resource。如果下一轮实现发现必须触碰这些写集，必须立即 fail-closed，并改走 native bridge command queue write-set preflight。

当前也不需要先选择 smoke-only lab probe。`labs` evidence 能证明 feasibility / teardown / smoke 路径曾经可观察，但不足以自动成为 runtime truth；本轮选择的下一刀并不创建真实 queue，因此不需要用 lab probe 先行。

## 候选比较

A 推荐：`P1 internal Renderer real command queue first implementation slice bundle`

选择。下一轮只允许新增极窄 internal owner shell / dehydrated native result facts，不直接创建 `MTLCommandQueue`，不调用 `newCommandQueue`，不修改 native bridge / Objective-C / Metal / AppKit / C ABI / FFI。

B fallback：`P1 internal Renderer native bridge command queue write-set preflight decision`

暂不选择。仅当下一轮发现 command queue shell 无法避开 native bridge、C ABI / FFI、retain / release / destroy、native handle 或真实 queue 写集时，才应回退到 B。

C fallback：`P1 internal Renderer real command queue smoke-only lab probe preflight decision`

暂不选择。仅当 runtime shell evidence 不足，而需要先补 lab feasibility / teardown / smoke evidence 时才选择 C。

D 暂缓：command queue implementation admission hardening。

E 暂缓：real drawable first implementation preflight。

F 拒绝：直接 `MTLCommandQueue` / `newCommandQueue`。

G 拒绝：direct drawable、command buffer、`commit` / `present`、GPU submission、render、renderer state write。

H 拒绝：public API / C ABI expansion。

I 拒绝：receipt / record / publication。

J 拒绝：queue-ready、backend-ready、native-handle、GPU-submission、render 或 renderer-state-write permission wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`、real command queue lifecycle manifest、real command queue implementation admission manifest、command submission manifest、smoke evidence、reference pack 或 branch milestone 包装成 queue-ready permission、backend-ready permission、native-handle permission、GPU-submission permission、render permission、renderer-state-write permission、receipt / record / publication。

若下一轮选择 A，必须新增 command queue shell / queue creation admission shell / ownership proof / teardown proof / failure classification / no-real-command-queue readiness 语义，而不是把已有 no-real-metal endpoint、旧 command queue lifecycle endpoint 或 admission endpoint再包成薄 wrapper。

## 停止线

本轮和下一轮 opening 继续禁止：

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
- no `newCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no draw call。
- no `commit`。
- no `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
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
- [real Metal device-layer branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-metal-device-layer-branch-next-boundary-decision.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real Metal device-layer branch next-boundary decision completed 推进到 real command queue first implementation preflight decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前已落地 runtime endpoint 仍是 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`；本轮只固定下一刀 command queue shell 的候选 endpoint 方向，尚未新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：是，本轮 docs-only 固定下一刀 owner candidate、runtime input candidate、允许表达的 future truth vocabulary 与 stop-line；未修改任何 runtime owner 或 `.cj`。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command queue first implementation slice bundle`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real command queue first implementation slice bundle`

## 下游真实 command queue 第一刀切片

下游 real command queue first implementation slice 已完成：

- [real command queue first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-closure-review.md)
- [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj)

该 downstream slice 只把本决策确认的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 作为 runtime input，并输出 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。旧 `CjguiInternalRendererNoRealCommandQueueReadiness` 仍归 lifecycle owner，不被本 slice 复用。

该 slice 不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不保存 native handle / raw pointer，不获取 drawable，不创建 command buffer，不提交 GPU work，不写 renderer state，不发布 backend ready truth 或 public API。

新的下游后续入口：

`P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`

## 下游真实 command queue 封账与 drawable 第一刀

下游 real command queue first slice 已继续完成后续边界、manifest stabilization 与 branch closure：

- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real command queue first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real command queue branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-branch-next-boundary-decision.md)

该 branch decision 选择下游 real drawable first implementation preflight。后续 real drawable first slice 已新增 `runtime/cjgui/src/runtime_renderer_drawable_real.cj`，endpoint 是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。

下游 drawable shell 只消费本链路输出的 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，仍不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`
