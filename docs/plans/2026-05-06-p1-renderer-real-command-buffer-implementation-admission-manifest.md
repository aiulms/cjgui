# P1 Renderer 真实 command buffer implementation admission manifest

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_real_command_buffer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj) 的 owner、truth、canonical endpoint、default draft、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准创建 command buffer，不批准调用 `commandBuffer` 或 `commit`，不批准创建 render pass / encoder / pipeline state，不批准获取 drawable、调用 `nextDrawable` 或 `present`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render execution、renderer state write 或 public API expansion。

后续若新增任何 `.cj` owner file，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 固定 owner

Owner file：

- [runtime_renderer_real_command_buffer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj)

唯一 runtime input：

- `CjguiInternalRendererNoRealDrawableImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 先从 `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 获取 `CjguiInternalRendererNoRealDrawableImplementationReadiness`。
- 它只构造 real command buffer implementation intent、command buffer creation admission policy、single-use admission guard、command buffer failure policy 与 no-real-command-buffer-implementation readiness value facts。
- 它不创建 command buffer，不调用 command queue factory，不调用 `commandBuffer`，不调用 `commit`，不创建 render pass / encoder / pipeline state。
- 它不获取 drawable，不调用 `nextDrawable` 或 `present`，不创建 native handle / raw pointer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy / Metal / AppKit / Objective-C / FFI。
- 它不提交 GPU work，不执行 render，不写 renderer state，不修改 bridge / smoke / harness / native entry，不扩 public API。

## 当前 truth

Current truth 仅限：

- real command buffer implementation intent value facts。
- command buffer creation admission policy value facts。
- single-use admission guard value facts。
- command buffer failure policy value facts。
- no-real-command-buffer-implementation readiness value facts。

Canonical value chain 是：

1. `CjguiInternalRendererNoRealDrawableImplementationReadiness`
2. `CjguiInternalRendererRealCommandBufferImplementationIntent`
3. `CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy`
4. `CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard`
5. `CjguiInternalRendererRealCommandBufferFailurePolicy`
6. `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`

## value 语义

`CjguiInternalRendererRealCommandBufferImplementationIntent` 只记录未来 real command buffer implementation intent facts。它不是 command-buffer-ready permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy` 只记录 command buffer creation admission facts。它不创建 command buffer，不调用 command queue factory，不调用 `commandBuffer`，也不保存任何 buffer object。

`CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard` 只记录 single-use admission facts。它不保存 command buffer token，不表达 post-commit usable permission，不表达 post-submit reusable permission。

`CjguiInternalRendererRealCommandBufferFailurePolicy` 只记录 command buffer failure policy facts。它不注册 completion callback，不观察真实 GPU completion，不写 renderer state，不发布 completion / failure event。

`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 封住当前 no-real-command-buffer-implementation readiness facts。它不是 command buffer permission、`commandBuffer` permission、`commit` permission、render pass permission、encoder permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 后续真实第一刀接入

后续 real command buffer first-slice macro 已接入，但没有改变本 implementation admission manifest 的 endpoint 或 truth：

- [real command buffer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-preflight-decision.md)
- [real command buffer first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-buffer-first-implementation-slice-closure-review.md)
- [real command buffer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-buffer-first-implementation-slice-manifest.md)

新 shell endpoint `CjguiInternalRendererNoRealCommandBufferShellReadiness` 只表达 command buffer shell intent、creation admission shell、commit denial proof、completion denial proof 与 teardown / failure classification facts。它不是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 的薄包装，也不授予真实 command buffer creation、`commandBuffer`、`commit`、render pass、encoder、GPU submission、renderer state write 或 public API permission。

## 关系事实

Real command buffer implementation admission facts 只把上游 no-real-drawable-implementation endpoint 作为 runtime input：

- `CjguiInternalRendererNoRealDrawableImplementationReadiness` 是唯一 runtime input。
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md) 只提供 no-real-drawable-implementation endpoint，不授予 command buffer、`commandBuffer`、`commit`、render pass、encoder、GPU submission、render 或 public API permission。
- [command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 只作为 command buffer lifecycle vocabulary evidence；`CjguiInternalRendererNoCommandBufferReadiness` 不是本 owner 的 runtime input。
- [real command buffer implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-preflight-decision.md) 已把下一刀限定为 value-only implementation admission facts，不是真实 command buffer implementation。
- [real command buffer implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-next-boundary-decision.md) 已确认当前 endpoint 足够，不需要继续包装 tail wrapper。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续约束后续 Markdown 中文写作和 `.cj` owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 不是：

- command buffer permission。
- command-buffer-ready permission。
- command buffer creation permission。
- `commandBuffer` permission。
- `commit` permission。
- render pass permission。
- encoder permission。
- pipeline state permission。
- drawable acquisition permission。
- `nextDrawable` permission。
- present permission。
- native handle permission。
- raw pointer permission。
- C ABI permission。
- FFI permission。
- bridge call permission。
- retain / release / destroy permission。
- Metal / AppKit / Objective-C permission。
- GPU submission permission。
- render execution permission。
- backend implementation permission。
- renderer state write permission。
- diagnostics / event bus / observer / telemetry permission。
- public API / public C ABI permission。

当前 truth 没有 command buffer object、没有 command buffer token、没有 render pass descriptor、没有 encoder、没有 pipeline state、没有 drawable、没有 native handle、没有 raw pointer、没有 C ABI、没有 FFI declaration、没有 bridge call、没有 GPU work、没有 render work、没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车（Same-shape Boundary Brake）

本轮是 manifest 封账，明确拒绝：

- command-buffer-ready permission wrapper。
- `commandBuffer` permission wrapper。
- `commit` permission wrapper。
- render-pass permission wrapper。
- encoder permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 不得继续包装成新的 tail wrapper，除非未来 docs-only preflight 证明存在新的 owner / lifecycle / teardown / failure / verification 语义，并且这些语义没有被本 manifest 捕获。

未来靠近 render pass implementation、encoder implementation、command buffer creation hardening、command buffer single-use token、completion / failure policy、真实 `commandBuffer` / `commit`、GPU submission 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建 command buffer。
- 不调用 command queue factory。
- 不调用 `commandBuffer`。
- 不调用 `commit`。
- 不创建 render pass。
- 不创建 encoder。
- 不创建 pipeline state。
- 不获取 drawable。
- 不调用 `nextDrawable`。
- 不调用 `present`。
- 不创建 native handle。
- 不创建 raw pointer。
- 不新增 C ABI。
- 不新增 FFI declaration。
- 不调用 bridge。
- 不调用 retain / release / destroy。
- 不调用 Metal / AppKit / Objective-C / FFI。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不扩 public API。
- 不新增 module-level `var`。

## 公共 surface

Public declaration allowlist 仍保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

## 下一阶段候选

### 候选 A：推荐 render pass implementation preflight

推荐下一步：

`P1 internal Renderer render pass implementation preflight decision`

理由：real command buffer implementation admission 已经封账为 no-real-command-buffer-implementation endpoint。下一步可以 docs-only 评估 render pass implementation admission runway、attachment relation、encoder stop-line 与 no-render-pass-implementation facts，但仍不得创建 render pass、不得创建 encoder、不得创建 pipeline state、不得提交 GPU work。

### 候选 B：暂缓 encoder implementation preflight

Encoder implementation 更靠近 command encoding、pipeline binding、draw command 与 render execution，应晚于 render pass implementation preflight。

### 候选 C：暂缓 command buffer creation admission hardening

`RealCommandBufferCreationAdmissionPolicy` 已表达 no command buffer object、no command queue factory call 与 no `commandBuffer` facts。只有未来 review 发现 creation admission 表达不足时才选择 hardening。

### 候选 D：暂缓 command buffer single-use token preflight

`RealCommandBufferSingleUseAdmissionGuard` 已表达 no command buffer token 与 no post-commit usable permission facts。当前不需要引入 token owner。

### 候选 E：暂缓 command buffer completion / failure policy preflight

`RealCommandBufferFailurePolicy` 已表达 no completion callback 与 no real GPU completion observation facts。只有未来靠近 callback、state visibility、telemetry 或 failure rollback 时才需要更窄 preflight。

### 候选 F：暂缓 command submission / GPU submission hardening

Command submission / GPU submission hardening 应晚于 render pass / encoder / command buffer implementation admission 进一步收束，并且不得把 no-real-command-buffer endpoint 当成 submit permission。

### 候选 G 到 R：拒绝直接实现或发布

拒绝 direct command buffer creation implementation、direct `commandBuffer` call、direct `commit` implementation、direct render pass / encoder / pipeline implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 S：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream render pass implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj` 是当前 no-real-command-buffer-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 是 real command buffer implementation admission value facts 的 canonical tail。它不授予 command buffer、`commandBuffer`、`commit`、render pass、encoder、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

唯一后续入口：

`P1 internal Renderer render pass implementation preflight decision`

## 下游 render pass implementation preflight

下游 render pass implementation preflight 已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md)

该 preflight 只把本 manifest 固定的 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 作为唯一 runtime input candidate。`CjguiInternalRendererNoRenderPassReadiness`、`CjguiInternalRendererNoRealDrawableImplementationReadiness`、reference pack 与 risk ledger 只能作为 docs evidence。

该 preflight 选择下一步进入 value-only render pass implementation admission boundary。Output truth 仅限 render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts；仍不批准 render pass descriptor、attachment object、texture、encoder、`renderCommandEncoder`、command buffer、`commit`、drawable acquisition、GPU submission、render execution、renderer state write 或 public API permission。

下游 value boundary closure 已记录在：

- [2026-05-06-p1-internal-renderer-render-pass-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 [runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj)，canonical endpoint 是 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`；仍不授予 render pass、attachment、texture、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

新的唯一 opening：

`P1 internal Renderer encoder implementation preflight decision`

下游下一边界决策已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 足够作为当前 no-render-pass-implementation endpoint，并选择下一步 docs-only `P1 internal Renderer render pass implementation admission manifest stabilization bundle implementation`。它不把本 manifest 的 no-real-command-buffer endpoint、旧 `CjguiInternalRendererNoRenderPassReadiness` 或 reference evidence 升格成 render pass descriptor、attachment、texture、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

下游 manifest 封账已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`，并选择下一步 docs-only `P1 internal Renderer encoder implementation preflight decision`。它仍不授予 encoder、`renderCommandEncoder`、pipeline state、command buffer、GPU submission、render、renderer state write 或 public API permission。

下游 encoder implementation preflight 已记录在：

- [2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md)

该 preflight 继续把本 manifest 固定的 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 作为上游 evidence，而不是 command buffer、`commandBuffer`、`commit`、encoder、GPU submission、render、renderer state write 或 public API permission。新的 downstream opening 是 `P1 internal Renderer encoder implementation admission value boundary bundle implementation`。
