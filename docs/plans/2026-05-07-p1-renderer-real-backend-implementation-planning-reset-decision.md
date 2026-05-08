# P1 渲染器真实后端实现规划重置决策

日期：2026-05-07

状态：docs-only planning reset decision / no implementation permission

## 文件定位

本文件是在 Renderer implementation admission branch 已封账并完成 reconciliation scan 后，重新评估“第一口真实资源”应从哪里切入。

本轮是 planning reset decision，不是 implementation preflight，不批准直接写真实 backend code，不批准新 runtime owner，不创建 backend ready truth，不创建 backend object、platform object、native handle、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass descriptor、encoder、pipeline state、shader、descriptor 或 draw call。

本文件不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、[DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)、topic manifest、admission manifest 或 smoke README。Admission facts 和 smoke evidence 只能作为 planning evidence，不能自动升格为 runtime truth。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [implementation admission branch reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-implementation-admission-branch-reconciliation-scan.md)

入口状态确认：当前 branch 已 stop here，`CjguiInternalRendererNoBackendReadyImplementationReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft()` 仍只是 no-backend-ready implementation admission branch tail，不是 backend-ready permission。

## 规划结论

当前可以从已封账的 admission branch 进入真实 backend implementation planning，但仍不能直接 implementation。下一步必须先开更窄 docs-only preflight，重新确认 owner、write set、teardown proof、failure mode、main-thread confinement、smoke / manual visual 策略与 no-ready truth stop-line。

选择候选 A：

`P1 internal Renderer real backend platform object first implementation preflight decision`

原因是第一刀应选择“最小真实资源 + 最强 teardown 证据 + 最低 renderer blast radius”。Platform object / native resource creation owner 是真实后端链路里最早接触 native ownership、handle confinement、create / retain / release / destroy、main-thread 与 failure rollback 的切面；它仍早于 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline、draw call、render execution 与 renderer state write，因此最适合作为第一口真实资源的 docs-only preflight。

## 当前能否进入真实后端规划

可以进入真实 backend implementation planning reset，理由是：

- Implementation admission chain 已从 `CjguiInternalRendererNoNativeResourceBridgeReadiness` 串联到 `CjguiInternalRendererNoBackendReadyImplementationReadiness`。
- Reconciliation scan 已确认主入口、topic manifest、README、tracker、runtime README 与 branch 原文对当前 tail 一致。
- 未发现 `CjguiInternalRendererNoBackendReadyImplementationReadiness` 被误写成 backend-ready permission。
- Platform object、Metal device-layer、command queue、drawable、command buffer、render pass、encoder、pipeline state、draw call、render execution、state write 与 backend readiness finalization 的 admission facts 已完整封账。

但这些只足以开启 planning reset，不足以直接 implementation。真实资源一旦出现，就会进入 native ownership、FFI / bridge、AppKit / Metal、main-thread、teardown、crash safety 与 verification 风险；必须先开更窄 docs-only preflight。

## 第一口真实资源

第一口真实资源应围绕 real backend platform object / native resource creation owner，而不是 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer 或 render execution。

选择 platform object first 的理由：

- 它直接承接 [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md) 与 [platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md) 的 handle confinement、lifecycle admission 和 teardown failure evidence。
- 它是后续 `MTLDevice` / `CAMetalLayer` / command queue 的 ownership 容器前置，不应跳过。
- 它可以先验证 create / retain / release / destroy / failure / confinement / main-thread / no-ready truth，而不接近 GPU submission、draw call 或 renderer state write。
- 它能把 “native object 是否可被 CJGUI owner 安全包住” 与 “Metal resource 是否可创建” 分开，降低 blast radius。

不优先选择 Metal device-layer、command queue、drawable、command buffer、render pass、encoder、pipeline、draw call 或 render execution，是因为这些方向更快靠近 GPU submission、present、draw command、resource binding 或 renderer state write，风险面更大。

## 证据使用方式

可作为 planning evidence 的内容：

- Native resource bridge facts：handle confinement、bridge call admission、native teardown contract、no-native-resource-bridge readiness。
- Platform object admission facts：future platform object implementation intent、native handle admission、lifecycle admission guard、teardown failure policy、no-platform-object-implementation readiness。
- Metal device-layer admission facts：device / layer vocabulary、scale / color-space admission、no-device / no-layer posture。
- Command queue、drawable、command buffer、render pass、encoder、pipeline、draw call、render execution、state write 与 backend readiness finalization admission facts：用于证明 downstream stop-line 和风险顺序，不用于批准第一刀跨过去。
- Backend / Metal reference pack：用于说明 Apple 资源顺序、late drawable、command buffer single-use、completion / retention、AppKit backing scale 和 frame pacing ownership。
- GUI risk ledger：用于提醒 FFI ownership、main-thread UI resource、platform lifecycle 和 crash safety。
- `labs/macos_bridge_smoke`：用于 feasibility / teardown / smoke evidence。

仍不能升格为 runtime truth 的内容：

- `CjguiInternalRendererNoBackendReadyImplementationReadiness` 不能升格为 backend-ready permission。
- `CjguiInternalRendererNoPlatformObjectImplementationReadiness` 不能升格为 platform object creation permission。
- `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 不能升格为 `MTLDevice` / `CAMetalLayer` permission。
- `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` 不能升格为 `MTLCommandQueue` / `newCommandQueue` permission。
- `labs/macos_bridge_smoke` 不能升格为 runtime backend implementation truth。
- Reference pack 不能升格为 implementation plan 或 runtime input。

## smoke 证据的角色

`labs/macos_bridge_smoke` 已证明：

- 仓颉可以通过 C ABI 调用 Objective-C macOS bridge。
- AppKit 单窗口、Metal capability check、最小 Metal 清屏、auto-close、main-thread drain、destroy complete 与 event loop exited 日志存在。
- smoke 具备 auto-close 验证、readback feasibility、screenshot feasibility / first-slice、frame hash feasibility 与 artifact cleanup diagnostics。

这些可以作为第一刀 preflight 的 feasibility / teardown / smoke strategy evidence，尤其用于要求 create / destroy 日志、crash safety、manual visual 与 auto-close fallback。

但 smoke 不能直接升格为 runtime truth，原因是：

- 它位于 `labs/`，不是 `runtime/cjgui` owner。
- 它是 smoke-only / harness evidence，不是 public API contract。
- 它已有 Metal clear / command queue / frame logs，但这些属于实验链路，不代表 runtime owner 已具备 resource lifecycle contract。
- 它不能替代 future owner 的 file-level truth、stop-line、failure mode、teardown proof 或 main-thread confinement。

## 第一刀 write set 约束

如果后续 preflight 批准 implementation，第一刀 write set 必须极窄，并在 preflight 中逐项列出。当前 planning reset 只允许提出约束，不批准写入。

建议后续 preflight 评估的最小 write set 原则：

- 最多新增一个 internal-only runtime owner，专门承载 real backend platform object first implementation 的 owner / truth / stop-line。
- 若必须改 native bridge / Objective-C / Metal / AppKit，必须在 preflight 中明确具体文件、具体函数、create / retain / release / destroy 顺序、failure return shape 与 teardown proof。
- 不修改 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`，除非后续 preflight 证明 build linkage 必不可少并单独列风险。
- 不修改 smoke、harness、native bridge、entry，除非后续 preflight 明确把它们列为验证或桥接最小必要写集。
- 不新增 public API / C ABI expansion。
- 不创建 command queue、drawable、command buffer、render pass、encoder、pipeline state、draw call、render execution 或 renderer state write。

## 第一刀验证策略

后续真正 implementation preflight 应要求第一刀验证策略至少覆盖：

- `cjpm build --target-dir <tmp> --skip-script`。
- auto-close smoke，用于证明进程可退出、teardown log 完整、不会挂住主线程。
- manual visual 仅作为辅助，不作为唯一验收。
- teardown logs：必须观察 create / destroy / failure cleanup / no dangling owner。
- crash safety：空指针、创建失败、重复 destroy、异常 teardown 路径必须 fail-closed 或结构化返回。
- resource lifecycle scan：确认没有 backend-ready truth、没有 GPU submission、没有 draw call、没有 renderer state write、没有 public API。
- stop-line scan：确认未出现 `commit`、`present`、`nextDrawable`、`renderCommandEncoder`、`endEncoding`、draw call、resource binding 或 public expansion。

本轮不运行 build / smoke，因为本轮是 docs-only planning reset decision。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer real backend platform object first implementation preflight decision`

推荐 A。它先评估最窄真实 platform object / native resource creation owner，重点放在 create / retain / release / teardown / failure / confinement / main-thread / no-ready truth，仍是 docs-only。

### 候选 B：备选

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

暂不选择。`MTLDevice` / `CAMetalLayer` 更靠近真实 Metal / AppKit resource，需要先证明 platform object owner 和 native lifecycle 容器足够安全。

### 候选 C：备选

`P1 internal Renderer real backend shell smoke-only implementation preflight decision`

暂不选择。Smoke-only shell 可以验证 lifecycle，但容易把 smoke evidence 误读成 runtime truth。若后续用户更想先做 shell 验证，可单独开 preflight。

### 候选 D：备选

`P1 internal Renderer real command queue first implementation preflight decision`

暂不选择。Command queue 需要真实 `MTLDevice` 与 queue factory relation，且更靠近 command buffer / GPU submission；不适合作为第一口真实资源。

### 候选 E：备选

`P1 internal Renderer native bridge teardown contract hardening preflight decision`

暂不选择。当前 native resource bridge 与 platform object admission evidence 足够支持 platform object first preflight；若后续 preflight 发现 FFI / retain / release / destroy 证据不足，再回落到 E。

### 候选 F 到 I：暂缓

real drawable acquisition implementation preflight、command buffer / render pass / encoder implementation preflight、pipeline / draw call implementation preflight、public diagnostics / readiness read surface preflight 均暂缓。这些方向更靠近 GPU submission、present、draw command、renderer state write 或 public API。

### 候选 J 到 Q：拒绝

拒绝 direct backend ready implementation、direct GPU submission / command buffer commit、direct drawable present / render execution、direct draw call / resource binding、direct renderer state write、public API / C ABI expansion、browser engine / foreign surface implementation、receipt / record / publication wrapper。

## 同形边界刹车

本轮不得把 reconciliation scan、branch milestone、topic manifest 或 admission facts 包成新的 backend-ready wrapper。不得新增 `ready`、implementation-ready 或 resource-ready endpoint。

本轮只做 planning reset 和下一步 docs-only preflight 选择，不新增 runtime truth，不新增 owner，不新增 readiness wrapper，不创建 receipt / record / publication。

## 停止线

后续 docs-only preflight 明确改变前，继续禁止：

- no backend ready truth。
- no backend-ready permission。
- no backend object creation。
- no platform object creation。
- no native handle。
- no raw pointer。
- no C ABI。
- no FFI declaration。
- no bridge call。
- no Metal / AppKit / Objective-C。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。
- no render execution。
- no GPU submission。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no command buffer creation / submission。
- no encoder creation。
- no pipeline state / shader / descriptor creation。
- no draw call。
- no pipeline / buffer / texture / sampler / resource binding。
- no browser engine / foreign surface implementation。

## 下游 platform object 第一刀预检

Renderer real backend platform object first implementation preflight decision 已完成：

- [2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-preflight-decision.md)

该 downstream 使用本 planning reset 的第一口真实资源判断作为 evidence，并进一步确认下一步可进入极窄 internal runtime owner shell slice。它不改变本文件的 no backend ready truth 结论，不创建 backend object、真实 platform object、native handle、raw pointer、C ABI、FFI declaration、bridge call、Metal / AppKit object、GPU submission、renderer state write 或 public API。

新的 downstream 后续入口：

`P1 internal Renderer real backend platform object first implementation slice bundle`

## 设计意图出口自检

- 本轮是否改变主题状态：是，Renderer implementation admission chain 与 backend readiness runway 从 branch stop here / wait 推进到 real backend implementation planning reset decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 admission branch tail 仍是 `CjguiInternalRendererNoBackendReadyImplementationReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft()`；它仍不是 backend-ready permission。
- 本轮是否改变 owner / truth / stop-line：是，导航层 stop-line 增补 planning reset 阶段的 no direct implementation / no first resource creation 约束；runtime owner / truth 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real backend platform object first implementation preflight decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real backend platform object first implementation preflight decision`
