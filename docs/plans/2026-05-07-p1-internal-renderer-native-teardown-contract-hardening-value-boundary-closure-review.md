# 渲染器 native teardown contract 硬化 value boundary 封账复核

日期：2026-05-07
状态：runtime owner value boundary 已落地 / no native implementation / no runtime truth

## 文件定位

本文件封账 `P1 internal Renderer native teardown contract hardening value boundary bundle implementation`。本轮新增一个 internal-only owner，用 value facts 固定 native teardown contract hardening intent、ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation readiness。

本轮没有修改 native bridge / Objective-C / Metal / AppKit 代码，没有新增 C ABI / FFI declaration，没有调用 bridge / retain / release / destroy，没有创建 native handle / raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state、shader、descriptor 或 draw call，没有提交 GPU work，没有执行 render，没有写 renderer state，没有触碰 `runtime_state.cj`，没有发布 public diagnostics / API，也没有扩 public API。

## 本轮落地

- 新增 owner file：[runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)
- 新增 canonical endpoint：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- 新增 default draft：`cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`
- 唯一 runtime input：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- 当前 truth：native teardown contract intent / ownership release policy / teardown failure classification / main-thread confinement guard / no-native-teardown-implementation readiness facts

新增 `.cj` owner 文件已保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。注释只解释维护边界，不把 teardown facts 解释成 native bridge、native handle、Metal resource 或 backend-ready permission。

## 新增符号

- `CjguiInternalRendererNativeTeardownContractIntent`
- `CjguiInternalRendererNativeOwnershipReleasePolicy`
- `CjguiInternalRendererNativeTeardownFailureClassification`
- `CjguiInternalRendererNativeMainThreadConfinementGuard`
- `CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- `cjguiInternalBuildRendererNativeTeardownContractIntent()`
- `cjguiInternalBuildRendererNativeOwnershipReleasePolicy()`
- `cjguiInternalBuildRendererNativeTeardownFailureClassification()`
- `cjguiInternalBuildRendererNativeMainThreadConfinementGuard()`
- `cjguiInternalBuildRendererNoNativeTeardownImplementationReadiness()`
- `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`

## 语义边界

`CjguiInternalRendererNativeTeardownContractIntent` 只表达进入 future native lifecycle 前仍需硬化 teardown contract 的意图事实。它不是 native bridge permission、native handle permission、backend-ready permission 或 Metal resource permission。

`CjguiInternalRendererNativeOwnershipReleasePolicy` 只表达 owner-local release ordering、idempotent teardown expectation、double-release risk fail-closed 与 dangling resource risk fail-closed。它不调用 retain / release / destroy，不创建或保存 native handle，不执行真实 teardown。

`CjguiInternalRendererNativeTeardownFailureClassification` 只表达 create unavailable、release failure、already closed、stale resource 与 bridge optimism 的 fail-closed classification。它不发布 failure event，不生成 public diagnostics，不把 failure fact 升格为 runtime truth。

`CjguiInternalRendererNativeMainThreadConfinementGuard` 只表达 wrong-thread fail-closed、dehydrated lifecycle facts 与 no state mutation / no public surface facts。它不进入主线程调度，不调用 platform API，不写 renderer state。

`CjguiInternalRendererNoNativeTeardownImplementationReadiness` 只收束 no-native-teardown-implementation readiness facts。它不是 native bridge permission、C ABI / FFI permission、native handle permission、retain / release / destroy permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 同形边界刹车

本轮新增的是 teardown hardening 语义，不是 ready wrapper。不得把 `CjguiInternalRendererNoNativeResourceBridgeReadiness`、`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`、smoke evidence 或 topic manifest 包成 native-handle-ready、bridge-ready、Metal-ready、backend-ready、resource-ready、GPU-submission、render-permission、public diagnostics、receipt / record / publication wrapper。

下一步只能先做 `P1 internal Renderer native teardown contract hardening closure / next native teardown decision`，确认当前 endpoint 是否足够封账；不得直接进入 native bridge / Objective-C / Metal / AppKit 修改、C ABI / FFI declaration、retain / release / destroy、native handle、Metal resource、GPU submission、renderer state write 或 public API。

## 停止线

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
- no pipeline state / shader / descriptor。
- no draw call。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。
- no backend ready truth。

## 验证记录

- `GitNexus impact` 已先跑；四个近期符号在当前索引中返回 `UNKNOWN / Target not found`，因此本轮用源码阅读、`cjpm build`、smoke、diff scan 与 GitNexus `detect_changes` 作为补充安全网。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-teardown-contract-value-boundary-target --skip-script` 已通过；输出包含既有 unused warnings。
- 其余验证项在本轮最终验证阶段统一执行并以最终总结为准。

## 下游同步

本轮同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native teardown contract hardening preflight decision completed 推进到 native teardown contract hardening value boundary completed。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 作为当前 no-native-teardown-implementation endpoint；上游 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` 不变。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner `runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj`，truth 仅限 native teardown contract hardening value facts，stop-line 继续禁止 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native teardown contract hardening closure / next native teardown decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer native teardown contract hardening closure / next native teardown decision`

## 下游后续边界决策

下游 native teardown contract hardening closure / next decision 已完成：

- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 足够作为当前 no-native-teardown-implementation endpoint，并选择 manifest stabilization。它不把本 closure 或 runtime owner facts 升格为 native bridge、retain / release / destroy、native handle、Objective-C / Metal / AppKit、backend-ready、renderer state write、public diagnostics 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`
