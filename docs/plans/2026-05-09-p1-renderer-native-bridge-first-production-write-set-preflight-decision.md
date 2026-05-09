# P1 渲染器 production native bridge 首个写集预检

日期：2026-05-09

状态：docs-only preflight / no native bridge implementation

## 文件定位

本 decision 在 `C ABI` surface、native handle token ownership 与 native bridge teardown planning 均已封账后，判断是否可以打开第一个 production native bridge 写集 runway。

本轮只定义允许写集、禁止写集、第一实现切口与验证策略；不新增 `.cj` owner，不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不调用 Objective-C / Metal / AppKit，不新增 public API。

## 证据入口

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Renderer backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [smoke C ABI header](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h)
- [smoke Objective-C bridge](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)

## 当前结论

可以打开 production native bridge write-set runway，但第一刀只能选择 `P1 internal Renderer production native bridge skeleton write-set contract bundle`。

该第一刀只允许定义 production bridge skeleton、header comments、status taxonomy docs / stubs 与写集 contract。它不实现 callable C ABI，不接 FFI，不创建 native object，不返回 raw pointer，不创建 token table runtime，不做 build system integration，不修改 runtime `.cj` FFI declaration，也不把 smoke lab 原样搬入 production bridge。

当前 runtime canonical tail / endpoint 不变：最新 runtime owner 仍是 `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj`，endpoint 仍是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。本 decision 只推进 planning status 与下一步 write-set contract，不改变 runtime truth。

## 第一实现切口

首个 production native bridge 切口应是 skeleton / status taxonomy，而不是 bridge behavior。

允许的下一刀语义：

- production bridge directory / file layout skeleton。
- production bridge header comments，说明 surface category、status shape、main-thread guard、token confinement 与 destroy contract 的未来落点。
- C ABI status taxonomy docs / enum stubs，但不得提供 callable behavior。
- no backend-ready truth、no raw pointer return、no native object creation 的编译前合同。

暂缓的切口：

- C ABI callable implementation。
- runtime `.cj` FFI declaration。
- native bridge token table skeleton。
- teardown-only production bridge behavior。
- build system integration。
- smoke-to-production 代码搬运。

## 允许写集候选

下一刀若执行 skeleton contract bundle，允许写集仅限：

- 新建 `runtime/cjgui/native/`。
- 新建 `runtime/cjgui/native/cjgui_native_bridge.h`。
- 新建 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 更新对应 docs / tracker / manifest / README。

`runtime/cjgui/native/cjgui_native_bridge.h` 与 `runtime/cjgui/native/cjgui_native_bridge.m` 在下一刀只能作为 production skeleton / taxonomy carrier，不得包含可从 Cangjie 调用的 runtime FFI 接线，不得创建 `NSWindow`、`NSView`、`CAMetalLayer`、`MTLDevice`、`MTLCommandQueue`、drawable、command buffer 或任何 native handle。

## 禁止写集

下一刀继续禁止：

- 修改 `labs/macos_bridge_smoke/native/*`。
- 修改 `runtime/cjgui/src/runtime_state.cj`。
- 修改 public API files。
- 修改 unrelated renderer owners。
- 修改 `runtime/cjgui/cjpm.toml` 或 package / build config。
- 新增 runtime `.cj` FFI declaration。
- 新增 production C ABI callable implementation。
- 新增 native resources beyond skeleton。

若后续需要让 production `.m` 进入 `cjpm` build，必须先进入 `P1 internal Renderer native bridge build system integration preflight decision`，不能在 skeleton bundle 中顺手修改 package config。

## 实验室证据取舍

可借鉴项：

- AppKit main-thread guard 与错误分类方向。
- `cjgui_app_run()` 这种极窄 C ABI 入口形状。
- Objective-C ownership / invalidate / destroy 的顺序概念。
- `NSView`、`CAMetalLayer`、`MTLDevice`、`MTLCommandQueue` 的创建顺序作为 future order evidence。
- failure code / category / message dehydration 的分类方式。
- auto-close、readback、screenshot harness 作为后续验证模板。

不得搬运项：

- global mutable last error 作为 production runtime truth。
- 直接把 render 写进 `NSView render`。
- 直接调用 `nextDrawable`、`commandBuffer`、`commit`、`present` 或 `waitUntilCompleted`。
- readback-only defaults。
- Objective-C 层成为 runtime truth source。
- native pointer / handle 泄露进 Cangjie core。

## 构建系统判断

生产 `.m` 是否纳入 `cjpm` 构建仍需单独 preflight。当前可以先做 skeleton contract，因为 skeleton 不应修改 `runtime/cjgui/cjpm.toml`，也不应要求 `cjpm` 编译 production Objective-C。

因此本轮不选择 build system integration preflight 作为唯一 next opening；但若 skeleton bundle 发现必须修改 build config，必须立刻停止并改走 `P1 internal Renderer native bridge build system integration preflight decision`。

## 候选比较

A 推荐：`P1 internal Renderer production native bridge skeleton write-set contract bundle`。

选择原因：C ABI surface、token ownership 与 teardown planning 已足以支撑一个只写 skeleton / status taxonomy / comments 的 production write-set contract。该路径可以先冻结 production native bridge 文件边界，同时仍不创建 native object、不实现 callable C ABI、不接 FFI、不修改 build config。

B 推荐备选：`P1 internal Renderer smoke-to-production extraction manifest stabilization bundle`。

暂缓原因：当前 smoke 可借鉴 / 不可搬运项已在 planning reset、C ABI surface、token ownership、teardown planning 与本 decision 中固定，足够支撑 skeleton contract。若后续需要复制具体 smoke 逻辑，必须先回到 extraction manifest。

C 备选：`P1 internal Renderer native bridge build system integration preflight decision`。

暂缓原因：production `.m` 是否进入 `cjpm` 仍不清楚，但 skeleton bundle 可以先保持 build-config-free。只有当下一刀需要 package config 才转入该 preflight。

D 备选：`P1 internal Renderer native bridge C ABI callable implementation preflight decision`。

暂不建议：write-set、build integration、token runtime 与 destroy behavior 还没有 production skeleton 落点，不应跳到 callable implementation。

E 拒绝：直接实现 C ABI / FFI。

F 拒绝：直接创建 AppKit / Metal object。

G 拒绝：直接修改 smoke lab 当 production bridge。

H 拒绝：直接写 `runtime_state.cj` / public API。

I 拒绝：继续新增同构 value wrapper。

## 同形边界刹车

不得把 C ABI surface、native handle token、teardown planning、smoke lab 或 Metal reference pack 包装成 native bridge implementation permission、C ABI implementation permission、native-handle permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

本轮只产生 first production write-set preflight decision。若下一轮选择 A，也只能新增 production skeleton / status taxonomy / write-set contract，不得新增 C ABI callable implementation、FFI declaration、native object、native handle、backend ready truth、GPU work、renderer state write 或 public API。

## 停止线

- no `.cj` modification。
- no runtime owner。
- no production `.h` / `.m` in this round。
- no `labs/macos_bridge_smoke/native/*` modification。
- no C ABI callable implementation。
- no FFI declaration。
- no native object creation。
- no native handle / raw pointer。
- no raw pointer return。
- no backend ready truth。
- no backend object。
- no `NSWindow` / `NSView` creation。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no render pass / encoder / pipeline / draw call。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no retain / release / destroy。
- no module-level mutable `var`。

## 下游同步

本 decision 是以下文档的 downstream：

- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)
- [native bridge teardown implementation planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-teardown-implementation-planning-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [Renderer backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)

本 decision 已要求同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证记录

本轮按 docs-only preflight 执行，不运行 `cjpm build`，不运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过，无尾随空白输出。
- Markdown absolute link missing target check：通过，限定 project docs / README scope，避开 `reference_repos/`。
- README / tracker / plans README / runtime README reachability：通过，四个入口均可检索到本 decision 与唯一后续入口。
- 中文标题与中文正文抽查：通过，新 decision 标题与章节标题含中文，正文以中文为主。
- forbidden check：通过，无 tracked `.cj` diff，`runtime_state.cj` 行数仍为 `10065`，protected path status clean。
- comment-aware public declaration scan：通过，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native file forbidden scan：通过，`labs/macos_bridge_smoke/native/*` 无 status；未新增 `runtime/cjgui/native/` 或 production `.h` / `.m`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：`risk_level=low`，`changed_count=17`，`affected_count=0`，`affected_processes=[]`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。主题从 native bridge teardown implementation planning manifest stabilization 后的待 preflight 状态，推进为 first production write-set preflight completed。
- 本轮是否改变 canonical tail / endpoint：否。runtime canonical endpoint 仍是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：不改变 runtime owner / truth；改变 planning stop-line，明确下一刀只允许 production skeleton / status taxonomy / write-set contract，不允许 callable C ABI / FFI / native object / build config / public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer production native bridge skeleton write-set contract bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer production native bridge skeleton write-set contract bundle`

## 下游 skeleton 写集封账

下游 [production native bridge skeleton write-set closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-contract-closure-review.md)、[next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-next-boundary-decision.md)、[manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-manifest-stabilization-closure-review.md) 已完成。

该 downstream 只新增 `runtime/cjgui/native/cjgui_native_bridge.h` 与 `runtime/cjgui/native/cjgui_native_bridge.m` 作为 production skeleton / status taxonomy / write-set contract；不接入 build / `cjpm` / FFI，不修改 build config，不新增 runtime `.cj` FFI declaration，不修改 `labs/macos_bridge_smoke/native/*`，不实现 callable C ABI，不创建 native object、native handle、raw pointer、backend ready truth、renderer state write、GPU submission、public diagnostics 或 public API。

新的 downstream 后续入口：

`P1 internal Renderer native bridge build system integration preflight decision`
