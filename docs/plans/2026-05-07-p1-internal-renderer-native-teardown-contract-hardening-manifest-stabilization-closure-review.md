# 渲染器 native teardown contract 硬化 manifest 稳定化封账复核

日期：2026-05-07
状态：docs-only closure review / manifest stabilization completed / no native implementation

## 文件定位

本文件封账 `P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`。本轮只新增 manifest 与 closure review，并同步设计意图导航、topic manifest 和下游指向。

本轮没有修改任何 `.cj`，没有新建 runtime owner，没有运行 `cjpm build` / smoke，没有触碰 protected paths，没有修改 native bridge / Objective-C / Metal / AppKit 代码，没有新增 C ABI / FFI declaration，没有调用 bridge / retain / release / destroy，没有创建 native handle / raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，没有提交 GPU work，没有写 renderer state，没有触碰 `runtime_state.cj`，没有发布 public diagnostics / API，也没有扩 public API。

## 本轮落地

- 新增 manifest：[native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- 新增 closure review：[native teardown contract hardening manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)
- 固定 owner file：`runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj`
- 固定 canonical endpoint：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- 固定 default draft：`cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`
- 固定 runtime input：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- 固定 current truth：native teardown contract intent / ownership release policy / teardown failure classification / main-thread confinement guard / no-native-teardown-implementation readiness facts

本轮不新增 `.cj` owner 文件，因此不修改 runtime owner 注释。后续若新增 runtime owner 文件，仍必须保留文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。

## 语义边界复核

`NativeOwnershipReleasePolicy` 不调用 retain / release / destroy，不释放真实 native resource，不创建或保存 native handle，不执行真实 teardown。

`NativeTeardownFailureClassification` 只表达 double-release、dangling pointer、wrong-thread、bridge optimism、stale resource、already closed 与 create unavailable 等 fail-closed 分类；它不发布 failure event，不生成 public diagnostics。

`NativeMainThreadConfinementGuard` 不调用 AppKit / Metal / Objective-C，不调度 main-thread work，不调用 platform API，不写 renderer state。

`NoNativeTeardownImplementationReadiness` 不是 native bridge permission、retain / release / destroy permission、native handle permission、C ABI / FFI permission、Metal / AppKit permission、backend-ready permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 同形边界刹车

本轮只做 manifest 封账，不新增 tail wrapper。不得把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 包成 native-teardown-ready wrapper、native-handle-ready wrapper、bridge-ready wrapper、Metal-ready wrapper、backend-ready wrapper、resource-ready wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

下一步若进入 real Metal device-layer first implementation preflight，也仍然是 docs-only preflight，不得直接创建 `MTLDevice` / `CAMetalLayer`，不得修改 native bridge / Objective-C / Metal / AppKit，必须先冻结第一刀 write set、teardown proof、failure mode、main-thread confinement 与验证策略。

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

本轮同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)
- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)

## 验证记录

本轮验证在最终阶段执行，以最终总结为准。按照本轮约束，不运行 `cjpm build` / smoke。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native teardown contract hardening closure / next decision completed 推进到 native teardown contract hardening manifest stabilization completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 endpoint 仍是 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，docs-only manifest 固定 owner file、runtime input、current truth 与 stop-line；未修改 runtime owner，也未修改 `.cj`。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first implementation preflight decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation preflight decision`
