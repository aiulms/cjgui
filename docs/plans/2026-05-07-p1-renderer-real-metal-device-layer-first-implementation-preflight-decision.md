# 渲染器真实 Metal device-layer 第一刀实现预检决策

日期：2026-05-07
状态：docs-only preflight / no native implementation / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real Metal device-layer first implementation preflight decision`。本轮只评估是否允许打开真实 `MTLDevice` / `CAMetalLayer` 第一刀 runway，以及第一刀 write set、owner、teardown proof、smoke、rollback 与 stop-line 应该多窄。

本轮不是 implementation，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，也不扩 public API。

本文件不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不替代对应 owner manifest、admission manifest、native teardown manifest 或 smoke evidence。开后续 Renderer gate 前，仍应先从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 进入，再读取对应 topic manifest 和关键原文链。

## 读取证据

本轮读取并采用以下证据：

- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)

`labs/macos_bridge_smoke` 只作为 feasibility / teardown / smoke evidence：它证明实验路径曾经能完成 capability check、Metal setup、first-frame logs、readback summary 与 auto-close teardown logs；它不能升格为 runtime ownership truth、native bridge permission、`MTLDevice` / `CAMetalLayer` permission、GPU submission permission、renderer state write permission 或 public API permission。

## 预检判断

允许打开真实 Metal device-layer 第一刀 runway，但下一步只能是极窄 implementation slice，不是直接 native bridge / Objective-C / Metal / AppKit implementation。

第一刀仍应优先是 internal owner shell / dehydrated native result facts，而不是直接触碰 native bridge。推荐 owner candidate 是 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`。它应只承接 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 与 upstream docs evidence，表达 real Metal device-layer first-slice intent、device-layer shell policy、layer-host relation placeholder、scale-color-space placeholder、teardown proof placeholder、failure policy 与 no-real-metal-device-layer readiness facts。

本轮不选择 native bridge wrapper，也不选择 existing Metal device-layer owner 的极窄 extension。原因是 native bridge / Objective-C / Metal / AppKit write set 尚未冻结；直接扩展既有 owner 容易把 no-metal-device-layer admission facts 误读成 real `MTLDevice` / `CAMetalLayer` permission。

第一刀当前不需要新增或修改 native bridge 入口。若后续发现必须碰 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle 或 raw pointer，必须先转向 `P1 internal Renderer native bridge write-set preflight decision`，明确文件范围、C ABI 是否变化、teardown proof、failure mode、main-thread confinement 与 rollback stop-line；不得在 implementation slice 中顺手扩大 public API / C ABI。

`MTLDevice` creation、`CAMetalLayer` binding、scale / color space、main-thread confinement、teardown proof 与 failure mode 的验证策略应分层冻结：

- 第一层：runtime owner shell build 验证，确保没有 native handle、bridge call、C ABI / FFI、Metal / AppKit / Objective-C 符号和 module-level `var`。
- 第二层：auto-close smoke 仍只作为已有 feasibility evidence，不在本轮运行；若未来触碰 native bridge，必须要求 auto-close smoke、teardown logs、crash safety scan 与 resource lifecycle scan。
- 第三层：若未来创建真实 `MTLDevice` / `CAMetalLayer`，必须记录 create unavailable、no device、no layer、wrong thread、teardown failed、double-release risk、dangling pointer risk 与 bridge optimism 的 fail-closed 分类。
- 第四层：manual visual 只可作为补充 evidence，不能替代 teardown logs、crash safety 与 lifecycle scan。

当前 native teardown contract 足以支撑进入 internal owner shell 第一刀；它不足以直接授权 native bridge 修改、真实 native handle、real `MTLDevice` / `CAMetalLayer` creation 或 retain / release / destroy implementation。

## 候选比较

### 候选 A：谨慎推荐

`P1 internal Renderer real Metal device-layer first implementation slice bundle`

选择 A。下一步只允许极窄 implementation slice，默认 owner candidate 是 `runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`。该 slice 最多表达 device-layer shell / dehydrated native result facts，不得直接创建 `MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state、draw call 或 GPU work。

该 slice 也不得把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`、`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`、Metal device-layer admission、smoke evidence 或 reference pack 包成 Metal-ready / device-ready / layer-ready / backend-ready / resource-ready wrapper。

若下一刀 prompt 明确要求真实 `MTLDevice` / `CAMetalLayer` creation，则必须同时冻结 native bridge write set、C ABI policy、teardown proof、main-thread confinement、failure classification 与 no-command-queue / no-drawable / no-command-buffer / no-GPU-work stop-line；否则应回退到候选 B 或 C。

### 候选 B：备选

`P1 internal Renderer native bridge write-set preflight decision`

暂不选择。当前 A 可先落地 runtime-local owner shell，不需要修改 native bridge。若后续实际实现必须新增 bridge entry、Objective-C / Metal / AppKit code、C ABI / FFI declaration、retain / release / destroy 或 native handle token，则必须先选择 B。

### 候选 C：备选

`P1 internal Renderer real Metal device-layer smoke-only lab probe decision`

暂不选择。`labs/macos_bridge_smoke` 已有 capability check、Metal setup、auto-close 与 teardown logs，可作为 planning evidence。当前第一刀不需要先回到 `labs` 做 smoke-only probe；若后续要验证真实 device/layer teardown 而 runtime risk 过高，再选择 C。

### 候选 D：备选

`P1 internal Renderer Metal device-layer real implementation admission hardening`

暂不选择。Metal device-layer owner manifest、implementation admission manifest、platform object shell manifest 与 native teardown manifest 已足够支撑下一步极窄 shell slice。当前没有证据说明必须先新增同构 admission hardening。

### 候选 E 与 F：暂缓

real command queue first implementation preflight 与 real drawable acquisition implementation preflight 暂缓。它们必须晚于 real Metal device-layer 第一刀，并且不得借本轮 preflight 提前获得 command queue、drawable、command buffer 或 GPU submission permission。

### 候选 G 到 L：拒绝

拒绝 direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、browser engine / foreign surface implementation、receipt / record / publication wrapper。

## 同形边界刹车

本轮不得把 native teardown manifest、platform object shell、Metal device-layer admission、Metal device-layer owner、reference pack 或 smoke evidence 包成 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、GPU-submission、render-permission、renderer-state-write、public diagnostics、receipt / record / publication 或 public API wrapper。

下一步若选择 A，只能进入 first implementation slice。它必须证明新增的是 real Metal device-layer shell / dehydrated native result / teardown proof / failure policy / no-real-metal-device-layer readiness 语义，而不是 permission wrapper。

## 停止线

本轮继续禁止：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no `MTLDevice` creation。
- no `CAMetalLayer` creation。
- no `MTLCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no shader / descriptor creation。
- no draw call。
- no GPU submission。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no backend ready truth。
- no public diagnostics / API。
- no browser engine / foreign surface implementation。

若下一步选择 implementation slice，下一刀仍必须继续禁止 command queue、drawable、command buffer、render pass、encoder、pipeline state、draw call、GPU work、renderer state write、backend ready truth、public diagnostics / API、browser engine / foreign surface implementation，以及任何未经 write-set preflight 固定的 native bridge / C ABI / FFI 扩展。

## 下游同步

本决策同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native teardown contract hardening manifest stabilization completed 推进到 real Metal device-layer first implementation preflight decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime endpoint 仍是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`；native resource bridge tail 仍是 `CjguiInternalRendererNoNativeResourceBridgeReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，本轮 docs-only 固定下一刀 owner candidate、first-slice truth 约束与 stop-line；未修改 runtime owner，也未修改 `.cj`。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first implementation slice bundle`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation slice bundle`

## 下游真实 Metal device-layer 第一刀切片

下游 real Metal device-layer first implementation slice 已完成：

- [real Metal device-layer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-closure-review.md)
- [runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)

该 slice 消费本 decision 固定的 `CjguiInternalRendererNoNativeTeardownImplementationReadiness`，并输出 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。它不把本 preflight 升格为 `MTLDevice` / `CAMetalLayer` creation permission、native bridge permission、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`

## 下游切片后续边界决策

下游 real Metal device-layer first implementation slice next-boundary decision 已完成：

- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)

该 decision 确认 downstream slice 输出的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint，但上一轮 build verification 未完成，原因是当前 shell 与交互式 zsh 均找不到 `cjpm`。因此它优先选择 build verification follow-up，不把本 preflight 或 downstream slice 升格为 `MTLDevice` / `CAMetalLayer` creation permission、native bridge permission、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

## 下游 manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 manifest 只固定 downstream owner shell 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。它不把本 preflight、downstream shell、build recovery 或 smoke evidence 升格为真实 `MTLDevice` / `CAMetalLayer` creation permission、native bridge permission、device-ready wrapper、layer-ready wrapper、backend-ready wrapper、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`
