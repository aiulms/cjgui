# P1 渲染器状态写入实现预检决策

日期：2026-05-06

状态：docs-only preflight decision

## 入口依据

本轮先读取设计意图导航入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

本决策只用于判断 renderer state write implementation runway 是否可以打开。它不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，不批准真实 renderer state write、`runtime_state.cj` 修改、module-level `var`、frame completion publication、public diagnostics、render execution、GPU submission、Metal / AppKit / Objective-C / FFI 或 public API expansion。

## 决策结论

本轮允许打开 renderer state write implementation runway，但下一步仍只能是 internal value boundary / implementation admission facts，不是真实 renderer state write。

谨慎选择：

`P1 internal Renderer renderer state write implementation admission value boundary bundle implementation`

下一步若实施，仍必须只表达 renderer state write implementation intent / state mutation admission policy / visibility commit admission guard / rollback state admission policy / no-renderer-state-write-implementation readiness facts。它不写 renderer state，不触碰 `runtime_state.cj`，不新增 module-level `var`，不发布 public diagnostics / API，不记录真实 frame completion，不注册 callback，不执行 render，不提交 GPU work，也不把 render execution admission endpoint 解释成 state mutation permission。

后续若新增 runtime owner，owner 文件必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。注释只能解释维护边界，不能把 admission facts 写成真实 implementation permission。

## 证据读取

- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`。该 endpoint 只代表 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness value facts，不批准 render、GPU submission、command submission、presentation、completion callback、renderer state write 或 public API permission。
- [state write no-write manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md) 已固定 `CjguiInternalRendererNoStateWriteReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteNoWriteDraft()`。该旧 no-write endpoint 只记录 state write intent、state mutation policy、commit visibility guard、rollback state policy 与 no-state-write readiness value facts，不批准 renderer state mutation、`runtime_state.cj` 写入、module-level mutable state、frame completion record、diagnostics publication、public API 或 public C ABI。
- [frame pacing owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-manifest.md) 已固定 `CjguiInternalRendererNoFrameSchedulerReadiness` / `cjguiInternalExecuteDefaultRendererFramePacingOwnerDraft()`，并明确 frame pacing facts 不是 renderer-state-write readiness、render loop permission、callback permission、command buffer commit permission 或 GPU submission permission。
- [backend readiness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md) 已固定 `CjguiInternalRendererNoBackendReadyReadiness` / `cjguiInternalExecuteDefaultRendererBackendReadinessDraft()`。它把 state visibility gate 限定为 value facts，不批准 renderer state write、frame completion record、diagnostics / event bus / observer / telemetry、backend implementation 或 public API expansion。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 evidence。它说明 completion status、presentation、command buffer lifecycle、drawable 和 frame pacing 的真实 backend 关系，但不能升格为 runtime truth、completion callback permission、GPU submission permission、renderer state write permission 或 backend implementation permission。
- [GUI 风险账本](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 继续要求渲染结果不能自持 UI truth，后台或平台回调不得直接写 GUI 资源，GPU / FFI / 平台资源生命周期必须提前定义 owner。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

允许打开 renderer state write implementation runway 的理由是：render execution implementation admission 已封账为 no-render-execution-implementation endpoint，且 state write no-write、frame pacing、backend readiness、command submission 与 backend reference evidence 已经把 state mutation、visibility commit、completion observation、rollback、diagnostics / publication、frame completion 与 backend readiness 关系限定为 value facts 或 reference evidence。

下一步仍不能直接写 renderer state。它也不能把 `CjguiInternalRendererNoRenderExecutionImplementationReadiness`、旧 `CjguiInternalRendererNoStateWriteReadiness`、backend readiness endpoint 或 reference evidence 包成 state-ready permission、frame-completion wrapper、visibility-commit wrapper、backend-ready wrapper、GPU-submission wrapper、render-permission wrapper 或 public API wrapper。

本轮没有发现必须先拆成 B / C / D 的证据缺口。State owner / mutation vocabulary 在 state write no-write manifest 中已有 no-mutation policy evidence；commit visibility / read surface 在 backend readiness state visibility gate 和 render execution rollback facts 中已有 no-publication evidence；rollback / failure state 在 state write no-write、render execution admission 与 risk ledger 中已有 fail-closed evidence。这些 evidence 足够支撑下一步 value boundary，但仍不足以批准真实 state mutation、frame completion visibility、callback、diagnostics publication 或 public API。

## 建议的下一步形状

若执行下一步，建议 runtime input candidate 只能是：

- `CjguiInternalRendererNoRenderExecutionImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`

建议 canonical endpoint 只能表达：

- renderer state write implementation intent
- state mutation admission policy
- visibility commit admission guard
- rollback state admission policy
- no-renderer-state-write-implementation readiness facts

Open path 只能形成 dehydrated admission facts；defer-only 保持 defer；blocked / inconsistent path 必须 fail-closed，并保留 no state write、no `runtime_state.cj` touch、no module-level `var`、no public diagnostics / API、no frame completion publication、no render execution、no GPU submission 与 no backend implementation facts。

## 候选比较

### 候选 A：谨慎推荐并选择

`P1 internal Renderer renderer state write implementation admission value boundary bundle implementation`

选择 A。它只允许表达 renderer state write implementation intent / state mutation admission policy / visibility commit admission guard / rollback state admission policy / no-renderer-state-write-implementation readiness facts；不写 renderer state，不触碰 `runtime_state.cj`，不新增 module-level `var`，不发布 public diagnostics / API，不执行 render，不提交 GPU work。

### 候选 B：暂不选择 state mutation admission preflight

暂不选择。State owner / mutation vocabulary evidence 在 state write no-write manifest 已有 state mutation policy 与 no-mutation stop-line，足以支撑下一步 value boundary。若未来发现 mutation vocabulary 不足，再单独 hardening。

### 候选 C：暂不选择 visibility commit admission preflight

暂不选择。Commit visibility / read surface evidence 在 backend readiness state visibility gate、render execution rollback policy 与 no-publication stop-line 中已有覆盖。真实 visibility commit、frame completion visibility 或 external read surface 仍必须另开 docs-only preflight。

### 候选 D：暂不选择 rollback state admission preflight

暂不选择。Rollback / failure state evidence 在 state write no-write、render execution admission 与 risk ledger 中已有 no-draw / no-write / fail-closed 约束。真实 rollback state mutation、callback 或 publication 仍被拒绝。

### 候选 E 到 G：暂缓

Backend readiness implementation finalization preflight、frame completion visibility preflight 与 render execution admission hardening 均暂缓。当前 runway 只收束 no-renderer-state-write-implementation admission facts，不靠近 backend finalization、completion publication、callback 或 render execution hardening。

### 候选 H 到 P：拒绝

拒绝 direct renderer state write implementation、direct mutation of `runtime_state.cj`、module-level mutable state、direct render completion publication、direct command submission / GPU submission、direct render execution、direct Metal / AppKit / Objective-C / FFI implementation、public API / C ABI expansion、receipt / record / publication。

### 候选 Q：仅限明确重复时 consolidation

仅在出现明确 duplicate / self-wrapping evidence 时选择 consolidation。当前 evidence 指向新增 state mutation admission / visibility commit admission / rollback state admission / no-renderer-state-write-implementation 语义，而不是删除、合并或把既有 endpoint 改名包装。

## 同构边界刹车

本轮不得把 `CjguiInternalRendererNoRenderExecutionImplementationReadiness`、`CjguiInternalRendererNoStateWriteReadiness`、backend readiness endpoint 或 reference evidence 包成：

- renderer-state-write implementation receipt / record / publication
- state-ready permission wrapper
- frame-completion wrapper
- visibility-commit wrapper
- backend-ready wrapper
- GPU-submission wrapper
- render-permission wrapper
- native-handle permission wrapper
- C-ABI / FFI permission wrapper
- public API wrapper

若下一步执行 A，新增语义必须明确是 state mutation admission / visibility commit admission / rollback state admission / no-renderer-state-write-implementation readiness facts。它不能表达 renderer state 可写、`runtime_state.cj` 可改、frame completion 可发布、diagnostics 可公开、render 可执行、GPU work 可提交或 public API 可扩展。

## 停止线

下一步继续保持以下 stop-line：

- no renderer state write
- no `runtime_state.cj` modification
- no module-level `var`
- no public diagnostics / API
- no render execution
- no GPU submission
- no `commit`
- no `present`
- no `nextDrawable`
- no command buffer creation / submission
- no encoder creation
- no `renderCommandEncoder`
- no `endEncoding`
- no draw call
- no pipeline / buffer / texture / sampler / resource binding
- no native handle
- no raw pointer
- no C ABI
- no FFI declaration
- no bridge call
- no retain / release / destroy
- no Metal / AppKit / Objective-C

## 文档同步

本决策作为以下文档的 downstream：

- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [state write no-write manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-state-write-no-write-manifest.md)
- [backend readiness manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，Renderer implementation admission chain 从 render execution manifest 已封账推进到 renderer state write implementation preflight 已完成。
- 本轮是否改变 canonical tail / endpoint：否，当前仍以 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 作为最新已落地 endpoint；下一步才允许建立 no-renderer-state-write-implementation admission endpoint。
- 本轮是否改变 owner / truth / stop-line：是，本轮新增下一步 state write implementation admission value boundary 的 truth candidate 与 stop-line，但未修改 runtime owner。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer renderer state write implementation admission value boundary bundle implementation`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`。
- 若未同步，理由：不适用。

## 验证清单

本轮必须验证：

- `git diff --check`
- 新 decision no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- comment-aware public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

本轮 docs-only，不运行 `cjpm build` / smoke，不修改 `.cj`。

## 唯一后续入口

`P1 internal Renderer renderer state write implementation admission value boundary bundle implementation`

## 下游取值边界封账

Renderer state write implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-state-write-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-state-write-implementation-admission-value-boundary-closure-review.md)

该 downstream 新增 [runtime_renderer_state_write_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_state_write_admission.cj)，只消费本决策指定的 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`。它把 endpoint 固定为 `CjguiInternalRendererNoStateWriteImplementationReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteAdmissionDraft()`，仍不批准 renderer state write、`runtime_state.cj` mutation、module-level `var`、public diagnostics / API、render execution、GPU submission 或 public API。

## 下游后续边界决策

Renderer state write implementation admission closure / next decision 已完成：

- [2026-05-06-p1-renderer-state-write-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-next-boundary-decision.md)

该 downstream 确认 `CjguiInternalRendererNoStateWriteImplementationReadiness` / `cjguiInternalExecuteDefaultRendererStateWriteAdmissionDraft()` 足够作为当前 no-renderer-state-write-implementation endpoint，并选择 manifest stabilization。它不改变本 preflight 的 stop-line，不批准 renderer state write、`runtime_state.cj` mutation、module-level `var`、public diagnostics / API、render execution、GPU submission 或 public API。

## 下游 manifest 封账

Renderer state write implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-state-write-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-state-write-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream 固定 `runtime_renderer_state_write_admission.cj` 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line，并把下一步指向 backend readiness implementation finalization preflight。它不改变本 preflight 的 stop-line，不批准 renderer state write、`runtime_state.cj` mutation、module-level `var`、public diagnostics / API、render execution、GPU submission 或 public API。
