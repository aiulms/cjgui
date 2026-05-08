# 渲染器 native teardown contract 硬化预检决策

日期：2026-05-07
状态：docs-only preflight decision / no native implementation / no runtime truth

## 文件定位

本文件承接 real backend platform object branch next-boundary decision，用来判断在靠近 native bridge、Objective-C、Metal、AppKit、retain / release / destroy 或 native handle 前，是否已经具备足够的 teardown contract 证据。

本轮是 docs-only preflight，不是 implementation。不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy，不创建 native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable 或 command buffer，不提交 GPU work，不写 renderer state，不触碰 `runtime_state.cj`，不发布 public diagnostics / API，不扩 public API。

## 设计意图入口

本轮先读取并对齐：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [real backend platform object branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)

入口状态确认：当前最新 runtime shell endpoint 仍是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`，它不是 native platform object permission、native handle permission、backend-ready permission、Metal device permission、resource-ready permission、GPU submission permission、renderer state write permission 或 public API permission。当前唯一后续入口是本 native teardown contract hardening preflight。

## 读取证据链

本轮读取并用于判断的关键原文包括：

- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [platform object implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-platform-object-implementation-admission-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [real backend implementation planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-implementation-planning-reset-decision.md)
- [Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [macOS bridge smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)

这些证据共同说明：已有 owner / admission / shell facts 能表达 native resource bridge intent、handle confinement、bridge call admission、teardown policy、platform object lifecycle admission、teardown failure policy 和 shell teardown proof，但它们仍都是 dehydrated facts，不是 native bridge、native handle、retain / release / destroy、Objective-C、Metal 或 AppKit implementation permission。

## teardown 证据判断

进入 native bridge / Objective-C / Metal / AppKit 前，当前 teardown contract 还不足以直接实现。

已具备的证据：

- native resource bridge manifest 已固定 handle confinement、bridge call admission 和 native teardown contract policy 的 value facts。
- platform object implementation admission manifest 已固定 native handle admission、platform object lifecycle admission guard 与 teardown failure policy。
- backend platform object owner manifest 已记录 native resource ownership、lifecycle teardown ordering、failure rollback 与 confinement vocabulary。
- real backend platform object shell 已提供 owner-local shell policy、teardown proof 占位和 failure policy facts。
- `labs/macos_bridge_smoke` 已提供 auto-close、main-thread drain、destroy complete、event loop exited 等 feasibility / teardown / smoke evidence。
- `GUI_RISK_LEDGER.md` 明确 FFI handle owner、retain / release、destroy 顺序、悬垂指针、二次释放与主线程边界是进入 native object 前必须防守的风险。

仍不足的证据：

- 没有冻结 future native resource token / handle identity 的最小词汇。
- 没有冻结 create / retain / release / destroy 的 owner-local ordering、幂等 destroy、double-release denial 与 dangling pointer denial。
- 没有冻结 failure classification：create failure、retain failure、destroy failure、thread violation、null handle、stale handle、already destroyed、bridge unavailable。
- 没有冻结 main-thread confinement：哪些 native lifecycle step 必须在主线程，哪些只能以脱水事实回传。
- 没有冻结 rollback stop-line：native create 失败、destroy 失败、teardown 中断时不得写 renderer state、不得发布 backend-ready truth、不得生成 public diagnostics。
- 没有冻结 future native bridge implementation 的最小 write set 与验证策略。

因此，不能直接进入 real Metal device-layer first implementation preflight。下一步必须先新增 internal-only teardown contract hardening value boundary，用 value facts 固定 ownership release policy、failure classification、handle confinement 与 no-native-teardown-implementation readiness。

## 最小词汇冻结

后续 value boundary 应只表达以下语义：

- native teardown contract hardening intent。
- native ownership release policy。
- native teardown failure classification。
- native main-thread confinement guard。
- no-native-teardown-implementation readiness。

这些词汇只能证明“进入真实 native 前还需要的合约被收束”，不能证明 native bridge 已可修改，也不能证明 native handle、C ABI / FFI、retain / release / destroy、Objective-C、Metal 或 AppKit 已可实现。

## smoke 证据边界

`labs/macos_bridge_smoke` 可以支持：

- 仓颉到 C ABI、C ABI 到 Objective-C、AppKit 单窗口和 Metal clear 的 feasibility evidence。
- auto-close、main-thread drain、destroy complete、event loop exited 的 teardown / smoke evidence。
- future verification strategy 中的 auto-close、teardown log、crash safety、manual visual 辅助判断。

`labs/macos_bridge_smoke` 不能支持：

- runtime owner truth。
- native bridge implementation permission。
- native handle permission。
- retain / release / destroy permission。
- `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue` creation permission。
- GPU submission、render execution、renderer state write 或 public API permission。

Smoke evidence 只能作为 feasibility / teardown / verification evidence，不能替代 future runtime owner 的文件头 truth、stop-line、failure mode、teardown proof 或 main-thread confinement。

## future write set 限制

如果未来真的进入 native bridge implementation preflight，第一刀 write set 必须先在 docs 中逐项冻结：

- 是否允许新增或修改 native bridge 文件；若允许，必须列出具体文件与具体函数。
- 是否允许新增 C ABI / FFI declaration；若允许，必须列出函数名、参数、返回形状与 failure classification。
- 是否允许 create / retain / release / destroy；若允许，必须说明 owner、调用顺序、幂等性、double-release 防护、null / stale handle 处理和 teardown log。
- 是否允许 Objective-C / Metal / AppKit；若允许，必须说明主线程 confinement 与失败回收。
- 不得顺手创建 `MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer 或 GPU submission。
- 不得写 renderer state，不得触碰 `runtime_state.cj`，不得发布 public diagnostics / API。

本轮不批准任何 write set，只记录 future preflight 必须回答的问题。

## 决策结论

选择候选 A：

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

理由：teardown 语义仍有关键缺口，尤其是 handle confinement、ownership release、failure classification、main-thread confinement、rollback stop-line、future bridge write set 与 smoke verification strategy。直接进入 real Metal device-layer first implementation preflight 会过早接近 `MTLDevice` / `CAMetalLayer`，而 native lifecycle contract 尚未作为 runtime-local value boundary 固定。

## 候选比较

### 候选 A：推荐

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

推荐。下一步新增 internal-only owner facts，只表达 teardown contract / ownership release policy / failure classification / no-native-teardown-implementation readiness，不修改 native bridge / Objective-C / Metal / AppKit，不新增 C ABI / FFI，不创建 native handle。

### 候选 B：备选

`P1 internal Renderer real Metal device-layer first implementation preflight decision`

暂不选择。当前 teardown contract 还没有冻结到足以接近 `MTLDevice` / `CAMetalLayer` 的程度。

### 候选 C：备选

`P1 internal Renderer native resource token preflight decision`

暂不选择为独立路线。handle token / ownership identity 的问题应并入下一步 teardown hardening value boundary 的最小词汇，除非后续发现 token shape 需要单独拆分。

### 候选 D：备选

`P1 internal Renderer native bridge write-set preflight decision`

暂不选择。当前还未到修改 bridge 的 write set 评估，必须先用 value boundary 固定 teardown contract hardening semantics。

### 候选 E 到 F：暂缓

real backend platform object bridge implementation preflight 与 real command queue first implementation preflight 暂缓。它们更靠近 native bridge、Metal resource、command queue 或 GPU submission。

### 候选 G 到 N：拒绝

拒绝 direct native bridge / Objective-C / Metal / AppKit modification、direct retain / release / destroy implementation、direct native handle / raw pointer creation、direct `MTLDevice` / `CAMetalLayer` creation、direct render / GPU submission、direct renderer state write、public API / C ABI expansion、receipt / record / publication wrapper。

## 同形边界刹车

本轮不得把 native resource bridge manifest、platform object shell、smoke evidence、branch decision 或 topic manifest 包成 native-handle-ready、bridge-ready、Metal-ready、backend-ready、resource-ready、GPU-submission、render-permission、public diagnostics、receipt / record / publication wrapper。

若下一步选择 A，新增内容必须是 teardown contract hardening 语义：native ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation readiness；不得是 ready wrapper 或 permission wrapper。

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
- [real backend platform object branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-branch-next-boundary-decision.md)
- [native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real backend platform object branch next-boundary decision completed 推进到 native teardown contract hardening preflight decision completed。
- 本轮是否改变 canonical tail / endpoint：否，当前 shell endpoint 仍是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness` / `cjguiInternalExecuteDefaultRendererRealBackendPlatformObjectShellDraft()`；native resource bridge tail 仍是 `CjguiInternalRendererNoNativeResourceBridgeReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，本轮 docs-only 不新增 owner，不改变既有 runtime truth；stop-line 继续禁止 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、retain / release / destroy、native handle、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native teardown contract hardening value boundary bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer native teardown contract hardening value boundary bundle implementation`

## 下游 value boundary 封账

下游 native teardown contract hardening value boundary 已完成：

- [native teardown contract hardening value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-value-boundary-closure-review.md)
- [runtime_renderer_native_teardown_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj)

该 boundary 新增 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()`，唯一 runtime input 是 `CjguiInternalRendererNoRealBackendPlatformObjectReadiness`。它只表达 native teardown contract intent、ownership release policy、teardown failure classification、main-thread confinement guard 与 no-native-teardown-implementation readiness facts，不把本 preflight 升格为 native bridge permission、C ABI / FFI permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening closure / next native teardown decision`

## 下游后续边界决策

下游 native teardown contract hardening closure / next decision 已完成：

- [native teardown contract hardening next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft()` 足够作为当前 no-native-teardown-implementation endpoint。它不把本 preflight、value boundary 或 smoke evidence 升格为 native bridge permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native teardown contract hardening manifest stabilization bundle implementation`

## 下游 manifest 稳定化

下游 native teardown contract hardening manifest stabilization 已完成：

- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [native teardown contract hardening manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-native-teardown-contract-hardening-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_native_teardown_contract.cj` 的 owner file、canonical endpoint、default draft、runtime input、current truth 与 stop-line。它不把本 preflight、value boundary 或 smoke evidence 升格为 native bridge permission、retain / release / destroy permission、native handle permission、Objective-C / Metal / AppKit permission、backend-ready permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation preflight decision`
