# P1 Renderer 真实 drawable implementation admission manifest

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_real_drawable_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj) 的 owner、truth、canonical endpoint、default draft、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本 manifest 不批准获取 drawable，不批准调用 `nextDrawable` 或 `present`，不批准创建 command buffer，不批准调用 `commit`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render execution、renderer state write 或 public API expansion。

后续若新增任何 `.cj` owner file，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 固定 owner

Owner file：

- [runtime_renderer_real_drawable_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj)

唯一 runtime input：

- `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()`

Canonical endpoint：

- `CjguiInternalRendererNoRealDrawableImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`

Default draft：

- `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 先从 `cjguiInternalExecuteDefaultRendererRealCommandQueueAdmissionDraft()` 获取 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`。
- 它只构造 real drawable implementation intent、drawable acquisition admission policy、drawable availability admission guard、drawable presentation admission policy 与 no-real-drawable-implementation readiness value facts。
- 它不获取 drawable，不调用 `nextDrawable`，不调用 `present`，不创建 command buffer，不调用 `commit`，不创建 native handle / raw pointer，不新增 C ABI / FFI declaration，不调用 bridge / retain / release / destroy / Metal / AppKit / Objective-C / FFI。
- 它不提交 GPU work，不执行 render，不写 renderer state，不修改 bridge / smoke / harness / native entry，不扩 public API。

## 当前 truth

Current truth 仅限：

- real drawable implementation intent value facts。
- drawable acquisition admission policy value facts。
- drawable availability admission guard value facts。
- drawable presentation admission policy value facts。
- no-real-drawable-implementation readiness value facts。

Canonical value chain 是：

1. `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`
2. `CjguiInternalRendererRealDrawableImplementationIntent`
3. `CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy`
4. `CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard`
5. `CjguiInternalRendererRealDrawablePresentationAdmissionPolicy`
6. `CjguiInternalRendererNoRealDrawableImplementationReadiness`

## value 语义

`CjguiInternalRendererRealDrawableImplementationIntent` 只记录未来 real drawable implementation intent facts。它不是 drawable permission、backend implementation permission、GPU submission permission、render permission 或 public API permission。

`CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy` 只记录 drawable acquisition admission facts。它不获取 drawable，不调用 `nextDrawable`，不执行 lookup call，不借用或保存真实 drawable。

`CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard` 只记录 drawable availability admission facts。它不查询真实 drawable pool，不持有 drawable token，不创建 resource token，也不暴露 pointer-like resource。

`CjguiInternalRendererRealDrawablePresentationAdmissionPolicy` 只记录 drawable presentation admission facts。它不调用 `present`，不创建 command buffer，不提交 command buffer，不提交 GPU work。

`CjguiInternalRendererNoRealDrawableImplementationReadiness` 封住当前 no-real-drawable-implementation readiness facts。它不是 drawable permission、`nextDrawable` permission、present permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 关系事实

Real drawable implementation admission facts 只把上游 no-real-command-queue-implementation endpoint 作为 runtime input：

- `CjguiInternalRendererNoRealCommandQueueImplementationReadiness` 是唯一 runtime input。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 只提供 no-real-command-queue-implementation endpoint，不授予 drawable、command buffer、GPU submission、render 或 public API permission。
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 只作为 drawable lifecycle vocabulary evidence；`CjguiInternalRendererNoRealDrawableReadiness` 不是本 owner 的 runtime input。
- [real drawable implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md) 已把下一刀限定为 value-only implementation admission facts，不是真实 drawable acquisition。
- [real drawable implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md) 已确认当前 endpoint 足够，不需要继续包装 tail wrapper。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续约束后续 Markdown 中文写作和 `.cj` owner 文件头维护注释。

## 明确的非 truth

`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不是：

- drawable permission。
- drawable-ready permission。
- drawable acquisition permission。
- `nextDrawable` permission。
- present permission。
- command buffer permission。
- command buffer creation permission。
- command buffer commit permission。
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

当前 truth 没有真实 drawable、没有 drawable texture、没有 command buffer、没有 native handle、没有 raw pointer、没有 C ABI、没有 FFI declaration、没有 bridge call、没有 GPU work、没有 render work、没有 renderer state mutation，也没有外部 API surface。

## 同构边界刹车（Same-shape Boundary Brake）

本轮是 manifest 封账，明确拒绝：

- drawable-ready permission wrapper。
- `nextDrawable` permission wrapper。
- present permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- backend implementation wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不得继续包装成新的 tail wrapper，除非未来 docs-only preflight 证明存在新的 owner / lifecycle / teardown / failure / verification 语义，并且这些语义没有被本 manifest 捕获。

未来靠近 real command buffer implementation、drawable acquisition hardening、drawable presentation hardening、drawable starvation / failure policy、render completion / frame completion tracking、真实 `nextDrawable` / `present` / GPU submission 或 renderer state write，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不获取 drawable。
- 不调用 `nextDrawable`。
- 不调用 `present`。
- 不创建 command buffer。
- 不调用 `commit`。
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

### 候选 A：推荐 real command buffer preflight

推荐下一步：

`P1 internal Renderer real command buffer implementation preflight decision`

理由：real drawable implementation admission 已经封账为 no-real-drawable-implementation endpoint。下一步可以 docs-only 评估 command buffer creation / commit admission、drawable relation、no-submit stop-line 与 failure strategy，但仍不得创建 command buffer、不得 `commit`、不得 GPU submission。

### 候选 B：暂缓 acquisition hardening

`RealDrawableAcquisitionAdmissionPolicy` 已表达 no drawable、no `nextDrawable` 与 no lookup call facts；只有未来 review 发现 acquisition admission 表达不足时才选择 hardening。

### 候选 C：暂缓 presentation hardening

`RealDrawablePresentationAdmissionPolicy` 已表达 no `present`、no command work 与 no command buffer facts；只有未来 review 发现 presentation admission 表达不足时才选择 hardening。

### 候选 D：暂缓 starvation / failure policy preflight

Drawable unavailable、timeout、starvation 与 fail-closed policy 如果未来靠近 callback、state visibility 或 runtime waiting behavior，必须另开 docs-only preflight。

### 候选 E：暂缓 completion tracking preflight

Render completion / frame completion tracking 靠近 callback、telemetry、observer、frame state 与 renderer state visibility，当前过早。

### 候选 F 到 P：拒绝直接实现或发布

拒绝 direct drawable acquisition implementation、direct `nextDrawable` call、direct drawable present implementation、direct command buffer creation / commit implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 Q：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 downstream real command buffer implementation preflight，而不是删除或合并。

## 封账决定

`runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj` 是当前 no-real-drawable-implementation endpoint 的固定 owner。

`CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 是 real drawable implementation admission value facts 的 canonical tail。它不授予 drawable、`nextDrawable`、present、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

唯一 next opening：

`P1 internal Renderer real command buffer implementation preflight decision`

## 下游 command buffer implementation preflight

下游 real command buffer implementation preflight 已记录在：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-preflight-decision.md)

该 preflight 只把本 manifest 的 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 作为唯一 runtime input candidate，并选择下一步 value-only real command buffer implementation admission boundary。它不批准 command buffer creation、`commandBuffer`、`commit`、render pass / encoder / pipeline state、drawable acquisition、`nextDrawable`、`present`、native handle、C ABI、FFI declaration、bridge call、GPU submission、render execution、renderer state write 或 public API。

该 preflight 当时的 downstream next opening：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 value boundary 落地

下游 real command buffer implementation admission value boundary 已落地：

- [2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_real_command_buffer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj)

该下游只把本 manifest 固定的 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 作为唯一 runtime input，canonical endpoint 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`。

下游 truth 仅限 real command buffer implementation intent / command buffer creation admission policy / single-use admission guard / command buffer failure policy / no-real-command-buffer-implementation readiness value facts；仍不批准 command buffer creation、`commandBuffer`、`commit`、render pass / encoder / pipeline state、drawable acquisition、`nextDrawable`、`present`、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

value boundary 后的唯一 opening：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 next-boundary 决策

下游 real command buffer implementation admission next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 已足够作为当前 no-real-command-buffer-implementation endpoint，并选择 docs-only manifest stabilization。它不把本 manifest 的 `CjguiInternalRendererNoRealDrawableImplementationReadiness` 包成 command-buffer-ready permission wrapper，也不批准 `commandBuffer`、`commit`、render pass / encoder、GPU submission、render、renderer state write 或 public API。

next-boundary decision 当时的唯一 opening：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 command buffer implementation admission manifest

下游 real command buffer implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md)

该下游固定 `runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`。它只把本 manifest 的 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 作为 runtime input。

下游 current truth 仅限 real command buffer implementation intent / command buffer creation admission policy / single-use admission guard / command buffer failure policy / no-real-command-buffer-implementation readiness value facts；仍不批准 command buffer creation、`commandBuffer`、`commit`、render pass、encoder、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

新的唯一 opening：

`P1 internal Renderer render pass implementation preflight decision`

## 下游 render pass implementation preflight

下游 render pass implementation preflight 已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md)

该 preflight 不把本 manifest 的 `CjguiInternalRendererNoRealDrawableImplementationReadiness` 作为 runtime input；它只作为 drawable relation docs evidence。唯一 runtime input candidate 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`。

下游 output truth 仅限 render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts；仍不批准 render pass descriptor、attachment object、texture、encoder、`renderCommandEncoder`、command buffer、`commit`、drawable acquisition、GPU submission、render execution、renderer state write 或 public API permission。

新的唯一 opening：

`P1 internal Renderer render pass implementation admission value boundary bundle implementation`

## 下游真实 drawable 第一刀 shell

新的 real drawable first implementation runway 已从 real command queue first-slice shell 重新评估，并完成 docs-only preflight 与 runtime-local shell：

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-next-boundary-decision.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)
- [real drawable first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-manifest-stabilization-closure-review.md)

该 downstream shell 只把本 manifest 作为 real drawable implementation admission vocabulary evidence。`CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 仍不是 downstream runtime input，不是 drawable acquisition、`nextDrawable`、present、command buffer、native handle、C ABI / FFI、GPU submission、render、renderer state write 或 public API permission。

新的 downstream endpoint 是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。它只消费 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`
