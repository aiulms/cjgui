# P1 渲染器 native bridge 写集规划重置决策

日期：2026-05-08

状态：完成 / docs-only planning reset / no native bridge implementation

## 文件定位

本文件收束 `P1 internal Renderer native bridge write-set planning reset decision`。本轮只做 docs-only planning reset，不修改 `.cj`，不新增 runtime owner，不运行 `cjpm build` 或 smoke，不触碰 protected paths，不修改 `runtime/cjgui/src/runtime_state.cj`。

本轮目标是在 real backend readiness shell branch 已完整对账后，重新规划进入 native bridge / Objective-C / Metal / AppKit 写集前的第一刀。它不批准直接修改 native bridge，不批准新增 C ABI / FFI，不批准真实 `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue` / drawable / command buffer / render pass / encoder / pipeline / draw call / GPU submission / renderer state write / public API。

## 输入证据

本轮先从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)、[renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)、[renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)、[macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md) 与 [design intent navigation exit protocol](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md) 进入。

本轮读取并对照 [real backend readiness shell branch reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-shell-branch-reconciliation-scan.md)、[real backend readiness final shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-final-shell-manifest.md)、[native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)、[native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)、[Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)、[labs smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)、[cjgui_macos.h](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h) 与 [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)。

## shell 分支证据定位

real shell branch 只能作为 native bridge planning evidence，不能作为 implementation permission。`CjguiInternalRendererNoRealBackendReadyShellReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendReadinessShellDraft()` 已经证明上游 shell 链条完整，但它只表达 backend readiness final shell intent、resource chain denial proof、execution visibility denial proof、backend-ready truth denial proof、failure classification 与 no-real-backend-ready-shell facts。

该 endpoint 不是真实 backend ready truth，不是 backend object、native handle、Metal resource、GPU submission、render execution、renderer state write、public diagnostics 或 public API permission。旧 implementation admission branch、real shell branch、smoke lab evidence 与 Metal reference pack 都不得混成一个 backend-ready truth。

因此，下一阶段如果要靠近正式 native bridge，必须先固定 write-set contract、C ABI surface、错误分类、主线程 guard、handle confinement、destroy contract 和验证策略；不能从 shell branch 直接跳到 Objective-C / Metal / AppKit implementation。

## smoke 可借鉴证据

- `labs/macos_bridge_smoke` 证明 AppKit 入口必须主线程运行；`cjgui_app_run` 在非主线程时 fail-closed，并把错误归为 fatal。
- `cjgui_macos.h` 展示了窄 C ABI 入口、状态码、错误类别与错误消息查询的实验形状，可作为正式 bridge surface contract 的输入证据。
- `CJGuiBridgeContext` 与 `CJGuiMetalView` 展示了 Objective-C bridge ownership、window delegate 关联、close request、invalidate、destroy ordering 与 `destroyIfNeeded` 的方向。
- smoke 中的创建顺序可作为规划证据：AppKit app / window 建立后，实验层创建 `MTLDevice`、`MTLCommandQueue`，再建立 `CJGuiMetalView` / `CAMetalLayer` 并触发首帧。
- failure code / category taxonomy 可借鉴为正式 error taxonomy 的草案输入，但不能直接成为 runtime truth。
- auto-close、lifecycle logs、readback probe 与 screenshot harness 可作为未来验证模板：它们适合证明 teardown、主线程 drain、窗口关闭和 smoke-only 可观测性，而不是证明正式 renderer ready。

## smoke 不可搬运内容

- 不得把 `gLastErrorCode`、`gLastErrorCategory`、`gLastErrorMessage` 这种 global mutable last error 直接搬入正式 runtime。
- 不得把真实 render 写入 `NSView render` 作为 runtime 主路径；该路径在 smoke 中直接创建 drawable、command buffer、render pass、encoder，并调用 `presentDrawable` / `commit`。
- 不得直接搬入 `nextDrawable`、`commit`、`waitUntilCompleted`、readback buffer / blit / `framebufferOnly = NO` 等 smoke-only 逻辑。
- 不得让 Objective-C 层成为 backend ready truth、renderer state truth 或 runtime owner truth source。
- 不得让 native pointer / handle 泄露进仓颉核心，也不得把 C ABI last error 查询误读为 public diagnostics surface。
- 不得把 readback-only defaults、screenshot harness 或 auto-close harness 当成正式 renderer contract。

## 正式写集规划原则

下一刀必须先固定正式 native bridge write-set，而不是直接实现。需要明确：

- 允许文件：下一轮 preflight 只能先枚举候选正式 bridge header / source / internal Cangjie FFI wrapper 位置；本轮不默认复用 `labs/macos_bridge_smoke/native/*`。
- 禁止文件：不得修改 `runtime/cjgui/src/runtime_state.cj`、public API、existing runtime owner、smoke harness、`runtime/cjgui/cjpm.toml`、protected paths 或 AGENTS / CLAUDE / CANGJIE issue ledger。
- 函数命名：下一轮必须冻结 internal 正式 bridge 前缀，避免直接复用 `cjgui_app_run` 这类 smoke app-level 入口。
- 错误分类：必须先定义 fail-closed taxonomy，覆盖 not-main-thread、app / window / device / layer / queue unavailable、invalid handle、double destroy、dangling token、bridge optimism、GPU request denial。
- 主线程 guard：必须在 contract 层说明哪些入口要求 main-thread、哪些入口只能 schedule / deny，且错误路径不能写 renderer state。
- handle confinement：native pointer 只能停留在 native bridge owning layer；仓颉核心最多接收 opaque token / dehydrated facts，不持有 raw pointer。
- destroy contract：必须先定义 idempotent destroy、wrong-thread destroy、double-release、dangling pointer 和 partial-init rollback 的行为。
- 验证策略：未来 implementation 需要 build、auto-close smoke template、teardown logs、crash safety、resource lifecycle scan、public declaration scan 与 protected path scan；仍不得用 GPU submission、render 或 renderer state write 作为第一刀验收。

## 候选比较

候选 A 胜出：`P1 internal Renderer native bridge C ABI surface contract preflight decision`。

选择 A 的原因是当前最大风险不是 shell chain 是否完整，而是正式 bridge surface 还没有被冻结。进入 native handle token、teardown implementation 或 real Metal write-set 前，必须先明确最小 C ABI surface、allowed write set、error taxonomy、main-thread guard、handle confinement、destroy contract 与 test strategy。A 仍是 docs-only，不实现 C ABI，也不触碰 native bridge。

候选 B 不选择：smoke-to-runtime extraction 的可复用 / 不可复用条目已可在本 planning reset 中先完成初筛；下一轮更需要把这些证据压成正式 C ABI contract。

候选 C 不选择：handle token ownership 重要，但它依赖 bridge surface 和 C ABI ownership boundary 先定名。

候选 D 不选择：native teardown implementation 仍太靠近 retain / release / destroy；必须先有 C ABI surface 与 destroy contract preflight。

候选 E 暂缓：real Metal device-layer implementation write-set 必须等正式 native bridge surface、handle confinement 与 teardown contract 更清楚后再开。

候选 F、G、H、I、J 拒绝：不直接修改 `labs/macos_bridge_smoke/native/*` 并当作 runtime bridge，不直接新增 runtime native bridge / C ABI / FFI implementation，不直接创建 Metal resource、drawable、command buffer，不进入 GPU submission / render / renderer state write / public API，也不继续新增 no-real-* wrapper。

## 同形边界刹车

本轮不得也没有把 `CjguiInternalRendererNoRealBackendReadyShellReadiness`、real shell branch reconciliation、smoke lab evidence 或 reference pack 包装成 native bridge permission、C ABI permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

本轮只产生 planning reset decision。下一轮若选择 A，只能定义 surface contract preflight，不得实现 bridge，不得创建 native handle，不得引入 C ABI / FFI declaration，不得把 shell facts 或 smoke evidence 升格为 runtime truth。

## 停止线

- no backend ready truth。
- no backend-ready permission。
- no backend object creation。
- no platform object / native handle / raw pointer。
- no C ABI / FFI declaration。
- no native bridge implementation。
- no Objective-C / Metal / AppKit modification。
- no bridge call。
- no retain / release / destroy。
- no real `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no render pass / encoder / pipeline / draw call。
- no `commit` / `present` / `waitUntilCompleted`。
- no GPU submission。
- no direct render。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no module-level mutable `var`。
- no receipt / record / publication wrapper。

## 同步记录

本轮同步 README、GUI_TASK_TRACKER、docs/plans README、runtime README、DESIGN_INTENT_INDEX、Renderer implementation admission chain topic manifest、Renderer backend readiness real backend runway topic manifest 与 macOS bridge verification smoke topic manifest。

本轮同时给 real backend readiness shell branch reconciliation scan、real backend readiness final shell manifest、native teardown contract hardening manifest、native resource bridge manifest 与 Metal reference pack 补 downstream 指向。

## 验证记录

本轮按 docs-only planning reset 约束执行，未运行 `cjpm build` / smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定项目 docs / README 范围并避开 `reference_repos/`，检查 `765` 个 Markdown 文件，missing 为 `0`。
- README / tracker / plans README / runtime README reachability：通过，四个入口均可到达本 decision 与 `P1 internal Renderer native bridge C ABI surface contract preflight decision`。
- 中文标题与中文正文抽查：通过；新增 decision 与触碰的入口 / topic manifest 均未使用 `Decision` / `Boundary` / `Verification` / `Next Opening` 作为主标题。
- forbidden check：通过；无 tracked `.cj` diff，protected paths clean，`runtime_state.cj` 行数仍为 `10065`。
- comment-aware public declaration scan：通过；仍只有 `runtime/cjgui/src/runtime_queue_public_submit.cj:cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus detect_changes：通过；`risk_level=low`，`changed_count=27`，`changed_files=24`，`affected_count=0`，affected processes 为空。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real backend readiness shell branch reconciliation completed 推进到 native bridge write-set planning reset completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 canonical endpoint 仍是 `CjguiInternalRendererNoRealBackendReadyShellReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendReadinessShellDraft()`；旧 native resource bridge tail `CjguiInternalRendererNoNativeResourceBridgeReadiness` 也未被改写。
- 本轮是否改变 owner / truth / stop-line：是，未改变 runtime owner 或 runtime truth，但为下一阶段固定 planning stop-line：real shell branch 与 smoke 只能作为 planning evidence，不是 native bridge / C ABI / Metal / backend-ready permission。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge C ABI surface contract preflight decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge C ABI surface contract preflight decision`

## 下游 C ABI surface contract 封账

下游 [native bridge C ABI surface contract preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-preflight-decision.md)、[value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-value-boundary-closure-review.md)、[next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-next-boundary-decision.md)、[manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-manifest-stabilization-closure-review.md) 已完成。

下游新增 `runtime/cjgui/src/runtime_renderer_native_bridge_c_abi_surface.cj`，endpoint 为 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()`。该 endpoint 只把本 planning reset 的 write-set、surface、错误分类、main-thread guard、handle confinement 与 destroy contract 证据收束为 internal value facts；不实现 C ABI / FFI，不新增 production `.h` / `.m`，不修改 smoke native 文件，不创建 native handle / raw pointer，不创建 backend ready truth，不提交 GPU work，不写 renderer state，不扩 public API。

新的下游唯一入口：

`P1 internal Renderer native handle token ownership planning preflight decision`
