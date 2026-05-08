# P1 渲染器 native bridge C ABI surface contract 预检决策

日期：2026-05-09

状态：完成 / docs-only preflight / no C ABI implementation

## 文件定位

本文件收束 `P1 internal Renderer native bridge C ABI surface contract preflight decision`。本轮从 native bridge write-set planning reset 进入，只评估正式 native bridge C ABI surface contract runway 是否可以打开。

本 preflight 不修改 `.cj`，不新增 native `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不创建 backend ready truth，不创建 backend object，不创建真实 Metal / AppKit resource，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## 输入证据

本轮先读取 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)、[renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)、[renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)、[macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md) 与 [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)。

本轮同时读取 [native bridge write-set planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-native-bridge-write-set-planning-reset-decision.md)、[real backend readiness shell branch reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-shell-branch-reconciliation-scan.md)、[real backend readiness final shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-backend-readiness-final-shell-manifest.md)、[native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)、[native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)、[Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)、[labs smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)、[cjgui_macos.h](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h) 与 [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)。

## 预检结论

生产 native bridge C ABI surface contract runway 可以打开，但第一切片必须仍是 internal value boundary，而不是 C ABI implementation。

上游 `CjguiInternalRendererNoRealBackendReadyShellReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendReadinessShellDraft()` 只能作为 planning evidence。它证明 real shell branch 已经把 resource chain denial、execution visibility denial、backend-ready truth denial 与 failure classification 串联完成；它不授予 native bridge、C ABI、Metal、backend-ready、GPU submission、render、state write 或 public API permission。

future allowed write set candidate 必须独立于 `labs/macos_bridge_smoke/native/*`。smoke native 文件只能提供主线程、C ABI 形状、错误分类、ownership / invalidate / destroy 与验证 harness 证据，不能被原样升级为 production bridge。

最小 surface category candidate 仅限：

- bridge init / destroy admission。
- main-thread guard。
- platform object create admission。
- Metal device-layer create admission。
- command queue create admission。
- error code / category / message dehydration。
- no backend-ready truth。

本阶段明确排除：

- drawable acquisition。
- command buffer creation。
- render pass / encoder / pipeline / draw call。
- `commit` / `present` / GPU submission。
- renderer state write。
- public diagnostics / public API。

未来 C ABI surface 即使进入 implementation，也只能返回 dehydrated status / token facts，不能把 raw native pointer、Objective-C object、Metal object 或 backend-ready truth 泄露进仓颉核心。

handle / token ownership、destroy contract、double-release denial、dangling pointer denial 与 main-thread confinement 仍需后续更窄 preflight 固定；本轮只先固定 surface contract value boundary。

## 候选比较

候选 A 胜出：`P1 internal Renderer native bridge C ABI surface contract value boundary bundle implementation`。

选择 A 的原因是当前首要缺口是正式 surface contract 的 owner、write-set policy、category admission 与 status dehydration vocabulary，而不是直接 C ABI / FFI implementation。A 允许新增一个 Cangjie internal owner，用 value facts 冻结 contract 语义，同时保持 no native implementation stop-line。

候选 B 暂缓：smoke-to-runtime extraction 仍有价值，但本轮已从 smoke 中抽出可借鉴和不可搬运条目，下一步更需要 owner 化 surface contract。

候选 C 暂缓：native handle token ownership 依赖 surface contract 先定名，下一轮再进入。

候选 D 暂缓：native teardown implementation 仍太靠近 retain / release / destroy，需要 surface contract 与 token ownership 先固定。

候选 E、F、G、H、I、J 拒绝：不直接进入 real Metal write-set，不修改 smoke native 文件并当作 runtime bridge，不新增 runtime native bridge / C ABI / FFI implementation，不创建 Metal resource / drawable / command buffer，不进入 GPU submission / render / state write / public API，也不继续新增 no-real-* wrapper。

## 同形边界刹车

不得把 real shell branch、smoke lab、Metal reference pack、native resource bridge manifest 或本 preflight evidence 包装成 native bridge implementation permission、C ABI implementation permission、native-handle permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

下一步若选择 A，必须新增 surface contract / write-set policy / category admission / status dehydration 语义，而不是 thin wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no backend ready truth。
- no backend object。
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

## GitNexus 记录

本轮在编辑 runtime owner 前运行 upstream impact：

- `CjguiInternalRendererNoRealBackendReadyShellReadiness`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererRealBackendReadinessShellDraft`：GitNexus 返回 `UNKNOWN / not found`，`impactedCount=0`。

该结果按近期新增 owner 尚未索引记录；本轮继续使用源码读取、`cjpm build`、smoke 与扫描兜底。未出现 HIGH / CRITICAL 风险。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 planning reset 推进到 C ABI surface contract preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，本 preflight 不新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：是，固定下一刀 owner candidate、truth vocabulary 与 no-C-ABI-implementation stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge C ABI surface contract value boundary bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge C ABI surface contract value boundary bundle implementation`

## 下游 native handle token ownership 封账

下游 native handle token ownership macro 已完成：[native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md)。该 downstream 不把本 preflight 选择的 C ABI surface contract runway 升格为 C ABI implementation、FFI、native bridge implementation、native handle、Metal / AppKit、backend-ready、GPU submission、render、renderer state write、public diagnostics 或 public API permission。
