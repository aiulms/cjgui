# 渲染器 native teardown contract 硬化后续边界决策

日期：2026-05-07
状态：docs-only next-boundary decision / no native implementation / no runtime truth

## 文件定位

本文件承接 `P1 internal Renderer native teardown contract hardening value boundary bundle implementation`，用于确认当前 no-native-teardown-implementation endpoint 是否足够封账，并判断下一步是否进入 manifest stabilization。

本轮是 docs-only decision，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit 代码，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle / raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，不扩 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

入口状态确认：当前最新 runtime endpoint 是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`，唯一 runtime input 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`。当前唯一后续入口是本 closure / next decision。

## 读取证据链

本轮读取并用于判断的关键原文包括：

- [runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)
- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)

这些证据共同说明：当前 endpoint 已把 native teardown contract intent、ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation readiness facts 收束为 internal value facts；同时它没有进入 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle、GPU submission、renderer state write 或 public API。

## endpoint 足够性

`CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 足够作为当前 no-native-teardown-implementation endpoint。

理由：

- 它只消费 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`，没有引入 native bridge、native resource bridge tail、smoke evidence 或 reference evidence 作为 runtime input。
- 它显式保持 native teardown contract hardening intent 为 value-only facts，不创建 native handle，不调用 bridge，也不执行真实 teardown。
- 它把 ownership release policy、double-release risk、dangling resource risk、bridge optimism、wrong-thread risk 和 stale resource risk 都收束为 fail-closed classification。
- 它保留 main-thread confinement guard，但不进入主线程调度、不调用 platform API、不写 renderer state。
- 它没有新增 public surface，也没有把 failure fact 发布成 diagnostics、event、receipt、record 或 publication。

因此下一步不需要再新增同构 wrapper。下一步应只做 manifest stabilization，固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line。

## 当前 endpoint 非许可说明

当前 endpoint 只代表：

- native teardown contract intent facts。
- ownership release policy facts。
- teardown failure classification facts。
- main-thread confinement guard facts。
- no-native-teardown-implementation readiness facts。

它不是：

- native bridge permission。
- retain / release / destroy permission。
- native handle permission。
- raw pointer permission。
- C ABI / FFI permission。
- Objective-C / Metal / AppKit permission。
- `MTLDevice` / `CAMetalLayer` permission。
- backend-ready permission。
- resource-ready permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- public diagnostics permission。
- public API permission。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`

推荐。该路线只固定 owner、truth、canonical endpoint、default draft、runtime input 与 stop-line；不修改 `.cj`，不新增 runtime owner，不进入 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不调用 retain / release / destroy，不创建 native handle 或 Metal resource。

### 候选 B：暂缓

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

暂缓。当前必须先封账 teardown contract hardening manifest，避免把 no-native-teardown-implementation endpoint 误读成进入 `MTLDevice` / `CAMetalLayer` 的许可。

### 候选 C：暂缓

`P1 internal Renderer native bridge write-set preflight decision`

暂缓。write set 评估必须在 manifest 固定 owner / truth / stop-line 后再决定，且仍不得默认批准 native bridge 修改。

### 候选 D：暂缓

`P1 internal Renderer native resource token preflight decision`

暂缓。native resource token / handle identity 仍需后续更窄 docs-only preflight，不应由当前 endpoint 同构包装出来。

### 候选 E 到 M：拒绝

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct retain / release / destroy implementation、direct native handle / raw pointer creation、direct `MTLDevice` / `CAMetalLayer` creation、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

### 候选 N：仅在证据出现时选择

consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择。本轮没有发现需要合并或删除历史文档的证据。

## 同形边界刹车

`CjguiInternalRendererNoNativeTeardownImplementationReadiness` 不得继续包装成 native-teardown-ready wrapper、native-handle-ready wrapper、bridge-ready wrapper、Metal-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

下一步若选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line；不得新增 tail wrapper，不得把当前 endpoint 升格为 native bridge、retain / release / destroy、native handle、Metal / AppKit、backend-ready、renderer state write 或 public API permission。

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
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native teardown contract hardening value boundary completed 推进到 native teardown contract hardening closure / next decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 endpoint 仍是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，本轮 docs-only 不新增 owner，不修改 `.cj`，不改变 runtime truth；只确认 stop-line 继续禁止 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`

## 下游 manifest 稳定化

下游 native teardown contract hardening manifest stabilization 已完成：

- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native teardown contract hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)

该 manifest 确认 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 仍只是 no-native-teardown-implementation readiness facts。它不新增 tail wrapper，不批准 native bridge、retain / release / destroy、native handle、Objective-C、Metal、AppKit、backend-ready、renderer state write、public diagnostics 或 public API。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation preflight decision`
