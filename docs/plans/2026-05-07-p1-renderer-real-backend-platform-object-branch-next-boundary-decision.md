# 渲染器真实后端 platform object 分支后续边界决策

日期：2026-05-07
状态：docs-only branch closure decision / no native permission / no backend ready truth

## 文件定位

本文件承接 real backend platform object first implementation slice manifest stabilization，确认当前 no-real-backend-platform-object shell endpoint 是否足够作为本分支阶段封账，并选择后续是否进入 native teardown contract hardening、real Metal device-layer first implementation preflight、stop here 或 shell hardening。

本轮 docs-only，不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，不扩 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

入口状态确认：设计意图地图已将主题推进到 first implementation slice manifest stabilization completed。当前唯一后续入口是本 branch closure / next decision；本轮若改变 next opening，必须同步两个 Renderer topic manifest。

## 读取证据链

本轮读取并用于决策的关键原文包括：

- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend platform object first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real backend platform object first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)
- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [real backend platform object first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

这些文档共同说明：当前 shell endpoint 已经足够封账，但真实 native handle、bridge call、retain / release / destroy、Objective-C / Metal / AppKit resource lifecycle 和 crash safety 仍未被授权实现。

## 当前端点复查

当前 owner file：

- `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`

当前 canonical endpoint：

- `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`
- `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoPlatformObjectImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPlatformObjectAdmissionDraft()`

本轮确认：`CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。它已经覆盖 real backend platform object intent、shell policy、teardown proof、failure policy 与 no-real-backend-platform-object readiness facts；manifest 已固定 owner file、default draft、runtime input、current truth 与 stop-line。

当前 endpoint 明确不是：

- native object permission。
- native handle permission。
- backend-ready permission。
- Metal device permission。
- resource-ready permission。
- GPU submission permission。
- render permission。
- renderer state write permission。
- public API permission。

## 决策结论

选择候选 A：

`P1 internal Renderer native teardown contract hardening preflight decision`

理由：当前 shell 分支可以 stop here，不需要继续新增同构 platform-ready 或 backend-ready wrapper。但下一步若要靠近 native bridge、retain / release / destroy、raw pointer、native handle、Objective-C、Metal 或 AppKit，必须先把 teardown contract 的 owner、C ABI / FFI 允许范围、destroy 幂等性、main-thread confinement、failure mode、crash safety 和 smoke strategy 重新硬化为 docs-only preflight。直接进入 real Metal device-layer first implementation preflight 会过早接近 `MTLDevice` / `CAMetalLayer` 资源，而 native lifetime 合约仍没有获得实现前的窄口复查。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer native teardown contract hardening preflight decision`

推荐。它只做 docs-only preflight，先硬化 create / retain / release / destroy / failure / dangling pointer / main-thread / smoke strategy 关系，不修改 native bridge，不新增 C ABI / FFI，不创建 native handle，也不创建 Metal resource。

### 候选 B：备选

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

暂不选择。只有当 native teardown contract 已足够清晰、且不需要先复查 bridge / retain / release / destroy / native handle 风险时，才适合打开。当前证据仍提示 FFI 生命周期、主线程和资源销毁是进入真实资源前的优先风险。

### 候选 C：备选

`STOP / wait for user direction before native bridge or Metal resource work`

暂不选择。用户已明确要求本轮判断下一阶段；当前最安全的下一步不是停等，而是把进入 native / Metal 风险区前的 teardown contract 作为 docs-only hardening preflight。

### 候选 D 到 E：暂缓

real backend platform object shell hardening 与 real command queue first implementation preflight 暂缓。当前 shell facts 已由 manifest 封账，没有发现需要继续 shell hardening 的缺口；command queue 仍晚于 native lifecycle 与 Metal device-layer 风险。

### 候选 F 到 M：拒绝

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct native handle / raw pointer creation、direct `MTLDevice` / `CAMetalLayer` creation、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

### 候选 N：仅在证据出现时合并

Consolidation 只在明确 duplicate / self-wrapping evidence 出现时选择；本轮没有发现该证据。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`、slice manifest、backend platform object owner evidence、native resource bridge evidence 或 topic manifest summary 继续包装成 platform-ready wrapper、native-handle-ready wrapper、backend-ready wrapper、resource-ready wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、public diagnostics wrapper、receipt / record / publication。

本轮选择 native teardown contract hardening preflight，正是为了停止继续堆同构 endpoint，并在靠近 native bridge / retain / release / destroy / native handle / Metal resource 前先硬化真实生命周期风险。

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
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)

## 下游 native teardown 预检

下游 native teardown contract hardening preflight decision 已完成：

- [native teardown contract hardening preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-preflight-decision.md)

该 decision 判定当前 teardown contract 还不足以直接进入 native bridge / Objective-C / Metal / AppKit 或 real Metal device-layer first implementation preflight。它不把本文件、slice manifest、smoke evidence 或 topic manifest 升格为 native-handle-ready、bridge-ready、Metal-ready、backend-ready、resource-ready、GPU-submission、render-permission、public diagnostics 或 receipt / record / publication wrapper。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 first implementation slice manifest stabilization completed 推进到 real backend platform object branch next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 shell endpoint 仍是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`；backend readiness implementation branch tail 仍是 `CjguiInternalRendererNoBackendReadyImplementationReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，owner 仍是 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`，truth 仍限于 shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts，stop-line 仍禁止 native bridge、native handle、Metal / AppKit、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native teardown contract hardening preflight decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer native teardown contract hardening preflight decision`
