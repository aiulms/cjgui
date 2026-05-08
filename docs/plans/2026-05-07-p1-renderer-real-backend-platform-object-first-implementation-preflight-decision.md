# P1 渲染器真实后端 platform object 第一刀实现预检决策

日期：2026-05-07

状态：docs-only first implementation preflight / no implementation this round

## 文件定位

本文件承接 [real backend implementation planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-implementation-planning-reset-decision.md)，评估真实 backend platform object 第一刀是否可以打开，以及下一轮 implementation slice 的 write set、owner、teardown、failure、verification 和 stop-line 应该多窄。

本轮是 first implementation preflight，不是 implementation。本文件不修改 `.cj`，不新建 runtime owner，不创建 backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不调用 Metal / AppKit / Objective-C / FFI，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不扩 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real backend implementation planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-implementation-planning-reset-decision.md)

入口状态确认：当前 `CjguiInternalRendererNoBackendReadyImplementationReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft()` 仍只是 no-backend-ready implementation admission branch tail，不是 backend-ready permission，也不是 platform object creation permission。

## 预检结论

可以打开第一口真实 backend platform object implementation runway，但只能选择极窄 A：

`P1 internal Renderer real backend platform object first implementation slice bundle`

该 slice 只允许进入 `runtime/cjgui/src` 的 internal-only owner shell，评估最小 backend platform object lifecycle token / shell 的 owner-local create / release / teardown / failure facts。它不得修改 native bridge、Objective-C、Metal、AppKit、smoke、harness、entry 或 `runtime/cjgui/cjpm.toml`；不得新增 C ABI / FFI declaration；不得创建 native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state、draw call、GPU submission、renderer state write 或 public API。

若下一轮发现必须修改 native bridge、Objective-C、Metal、AppKit、C ABI 或 FFI 才能完成第一刀，则当前 A 自动失效，必须先回退到 `P1 internal Renderer native teardown contract hardening preflight decision`。

## 是否仍限于 labs

第一刀不应继续限于 `labs/macos_bridge_smoke`。原因是 `labs` 只能提供 feasibility / teardown / smoke evidence，不是 runtime truth；继续留在 `labs` 会延迟正式 owner / truth / stop-line 的建立，也容易把 smoke 成功误读成 runtime owner 已具备。

第一刀可以进入 `runtime/cjgui/src`，但只能进入 internal-only runtime owner shell。`labs/macos_bridge_smoke` 在下一轮只作为回归验证和 teardown evidence 来源，不作为 write set，不作为 runtime input，不作为 backend implementation truth。

## 第一刀 owner 候选

推荐 owner candidate：

- `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`

推荐该候选而不是扩展既有 admission owner，原因是：

- 既有 `runtime_renderer_platform_object_admission.cj` 已封账为 no-platform-object-implementation admission facts；继续往里写真实 owner shell 容易混淆 admission facts 与 implementation facts。
- 独立 owner 可以在文件头维护注释里明确 Owner / Truth / Stop-line / Same-shape Boundary Brake，并保持 no-ready truth 与 no-native-handle stop-line。
- 独立 owner 更容易被 stop-line scan、public declaration scan 与 future teardown review 单独定位。

备选 owner candidate：

- existing platform object owner 的极窄 extension 仅在后续 preflight 证明不会污染 no-* admission endpoint 时可考虑。
- native bridge wrapper 不在本轮推荐写集内；一旦需要 bridge wrapper，应先做 native teardown contract hardening preflight。

## 第一刀 write set

若下一轮选择 A，建议 write set 极窄限定为：

- 新增一个 internal-only runtime owner：`runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj`。
- 更新对应 docs closure / manifest / README / tracker / topic manifest。
- 可运行 `cjpm build --target-dir <tmp> --skip-script` 与 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 作为验证；但不得修改 smoke / harness。

下一轮 A 不应包含：

- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 native bridge、Objective-C、Metal、AppKit 或 entry。
- 不新增 C ABI / FFI declaration。
- 不新增 public API 或 public diagnostics。
- 不触碰 `runtime_state.cj`。
- 不新增 module-level `var`。
- 不创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass descriptor、encoder、pipeline state、shader、descriptor 或 draw call。

## native bridge 判断

本轮证据不足以授权 native bridge / Objective-C / Metal / AppKit 修改。虽然 native resource bridge manifest、platform object admission manifest、risk ledger 与 smoke README 已提供 handle confinement、teardown、main-thread、create / destroy 日志和 failure 风险证据，但这些仍不能直接授予 C ABI / FFI 或 bridge call permission。

因此下一轮 A 必须默认不进入 native bridge。如果第一刀确实需要真实 native handle、retain / release / destroy、Objective-C allocation 或 Metal / AppKit 对象，则必须先选择 B：

`P1 internal Renderer native teardown contract hardening preflight decision`

该 hardening 需要先固定 C ABI / FFI declaration 是否允许、owner 如何隔离 raw pointer、destroy 是否幂等、主线程 confinement 如何证明、失败路径如何结构化返回，以及 smoke / crash safety 如何覆盖。

## teardown 与 failure 证据

下一轮 A 的验证重点不是视觉输出，而是 owner-local lifecycle 和 fail-closed 证据：

- create：只能创建 Cangjie owner-local backend platform object shell / token，不创建 native handle 或 platform object。
- retain：不得调用真实 retain；只能记录 owner-local no-retain / no-native-retain facts。
- release：不得调用真实 release；只能证明 owner-local release path 不发布 backend-ready truth。
- destroy：不得调用真实 destroy；只能证明 owner-local teardown path 可重复、可 fail-closed、可保持 no dangling owner facts。
- failure：创建失败、重复 release、重复 teardown、blocked / inconsistent input 必须形成结构化 failure / no-ready facts。
- confinement：owner 不暴露 raw pointer，不跨线程写 UI resource，不发布 platform object。
- main-thread：下一轮若未接 native bridge，main-thread 只能作为 future requirement facts；不得伪称已验证 AppKit main-thread ownership。

`labs/macos_bridge_smoke` 可用于验证 auto-close、destroy complete、main-thread drain 和 event loop exited 这些实验日志仍可用，但它不证明新 runtime owner 的 native lifetime 已实现。

## 无 ready truth 证明

下一轮 A 必须用扫描和文档闭环证明：

- 没有 backend ready truth。
- 没有 backend-ready permission。
- 没有 platform object creation permission。
- 没有 native handle、raw pointer、C ABI 或 FFI declaration。
- 没有 bridge call、retain / release / destroy、Metal / AppKit / Objective-C call。
- 没有 renderer state write。
- 没有 `runtime_state.cj` modification。
- 没有 GPU submission、`commit`、`present`、`nextDrawable`、command buffer、encoder 或 draw call。
- 没有 public API / public C ABI expansion。

## 验证策略

下一轮 A 至少应验证：

- `cjpm build --target-dir /tmp/cjgui-renderer-backend-platform-object-real-target --skip-script`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`，只作为 regression / smoke evidence。
- `git diff --check`。
- 新 runtime owner no-index whitespace check。
- Markdown absolute link missing target check。
- README / tracker / docs/plans README / runtime README reachability。
- Markdown 中文标题与中文正文抽查。
- forbidden check：protected paths 无 diff/status，`runtime_state.cj` 行数仍为 `10065`。
- comment-aware public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- new owner header scan：Owner / Truth / Stop-line / Same-shape Boundary Brake 必须存在。
- new owner stop-line scan：不得出现 native handle、raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline、draw call、GPU submission、renderer state write、public API 或 module-level `var`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`。

manual visual confirmation 本轮不作为必须项，因为 A 不应创建可见资源、不 render、不提交 GPU work。若后续 slice 改为 smoke-only lab probe 或接入 native bridge，再要求 manual visual / screenshot / teardown logs。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer real backend platform object first implementation slice bundle`

谨慎推荐。条件是下一轮 write set 只新增 internal-only runtime owner shell，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle，不创建 backend-ready truth，不写 renderer state，不 render，不提交 GPU work，不扩 public API。

### 候选 B：备选

`P1 internal Renderer native teardown contract hardening preflight decision`

如果下一轮无法避免 native bridge、retain / release / destroy、C ABI / FFI 或 Objective-C / Metal / AppKit 修改，则必须选择 B，而不是 A。

### 候选 C：备选

`P1 internal Renderer real backend platform object owner implementation admission hardening`

暂不选择。当前 admission facts 足以支持一个 no-native-bridge 的 internal owner shell slice；若后续 review 发现 owner vocabulary、failure shape 或 teardown facts 仍不足，再回到 C。

### 候选 D：备选

`P1 internal Renderer real backend platform object smoke-only lab probe decision`

暂不选择。Smoke 已能作为 feasibility evidence；继续留在 `labs` 不利于建立 runtime owner truth。只有在用户明确要求先做实验验证，或 runtime write set 仍不清楚时，才选择 D。

### 候选 E 到 F：暂缓

real Metal device-layer implementation preflight 与 real command queue implementation preflight 暂缓。它们需要 platform object owner shell 和 native lifecycle contract 更清楚后再打开。

### 候选 G 到 N：拒绝

拒绝 direct backend ready implementation、direct `MTLDevice` / `CAMetalLayer` creation、direct command queue / drawable / command buffer、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、browser engine / foreign surface implementation、receipt / record / publication wrapper。

## 同形边界刹车

本轮不得把 platform object admission、native resource bridge、branch milestone 或 planning reset 包成新的 platform-ready、backend-ready 或 native-handle-ready wrapper。

下一轮若选择 A，也不得新增 `ready` / implementation-ready / resource-ready endpoint。它只能新增最小 runtime owner shell，用于表达 owner-local lifecycle / teardown / failure implementation facts，并继续保持 no-backend-ready truth、no-native-handle、no-GPU-submission、no-renderer-state-write posture。

## 停止线

后续 implementation slice 明确获准前，继续禁止：

- no backend ready truth。
- no backend-ready permission。
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
- no module-level `var`。
- no public diagnostics / API。
- no browser engine / foreign surface implementation。
- no native handle。
- no raw pointer。
- no C ABI。
- no FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no Metal / AppKit / Objective-C。

## 设计意图出口自检

- 本轮是否改变主题状态：是，Renderer implementation admission chain 与 backend readiness runway 从 planning reset decision completed 推进到 real backend platform object first implementation preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 admission branch tail 仍是 `CjguiInternalRendererNoBackendReadyImplementationReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessFinalizationDraft()`；它仍不是 backend-ready permission。
- 本轮是否改变 owner / truth / stop-line：是，导航层 stop-line 允许下一轮在极窄条件下新增 runtime owner shell，但仍禁止 native bridge、native handle、Metal / AppKit、GPU submission、renderer state write 与 public API；本轮 runtime owner / truth 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real backend platform object first implementation slice bundle`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real backend platform object first implementation slice bundle`

## 下游实现切片闭环

下游 `P1 internal Renderer real backend platform object first implementation slice bundle` 已完成：

- [real backend platform object first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-closure-review.md)
- [runtime_renderer_backend_platform_object_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj)

该 slice 新增 internal-only owner shell，唯一 runtime input 是 `CjguiInternalRendererNoPlatformObjectImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`。

下游 truth 仅限 real backend platform object intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts。该 slice 没有修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI，没有创建 native handle、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、GPU submission、renderer state write 或 public API。

新的下游后续入口：

`P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision`

## 下游切片后续边界决策

下游 `P1 internal Renderer real backend platform object first implementation slice closure / next real backend platform object decision` 已完成：

- [real backend platform object first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()` 足够作为当前 no-real-backend-platform-object shell endpoint。该 endpoint 仍只代表 shell intent / shell policy / teardown proof / failure policy / no-real-backend-platform-object readiness facts，不是 native platform object permission、native handle permission、backend ready permission、Metal device permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation`

## 下游切片 manifest 稳定化

下游 `P1 internal Renderer real backend platform object first implementation slice manifest stabilization bundle implementation` 已完成：

- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [real backend platform object first implementation slice manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-backend-platform-object-first-implementation-slice-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_backend_platform_object_real.cj` 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。它仍不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle、Metal resource、GPU submission、renderer state write 或 public API。

新的下游后续入口：

`P1 internal Renderer real backend platform object branch closure / next real platform object decision`
