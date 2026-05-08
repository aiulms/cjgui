# P1 渲染器 encoder implementation preflight 决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 encoder implementation runway，但下一步仍只能是 internal value boundary / implementation admission facts，不是真实 encoder implementation。

推荐唯一后续入口：

`P1 internal Renderer encoder implementation admission value boundary bundle implementation`

下一步若进入 runtime owner，默认候选 owner 只能是 `runtime/cjgui/src/runtime_renderer_encoder_admission.cj` 或等价 internal-only owner；本轮不新建该 owner，不修改任何 `.cj`。后续若新增 `.cj` owner file，必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

下一步 value boundary 的唯一 runtime input 建议只消费：

- `CjguiInternalRendererNoRenderPassImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`

下一步 output truth 只能限定为：

- encoder implementation intent value facts。
- encoder creation admission policy value facts。
- encoding scope admission guard value facts。
- end-encoding admission policy value facts。
- no-encoder-implementation readiness value facts。

本 preflight 不批准创建 encoder，不批准调用 `renderCommandEncoder` 或 `endEncoding`，不批准绑定 pipeline / buffer / texture / resource，不批准创建 render pass descriptor、attachment object、texture、drawable、pipeline state 或 command buffer，不批准调用 `commandBuffer`、`commit`、`present` 或 `nextDrawable`，不批准 native handle / raw pointer、C ABI、FFI declaration、bridge call、retain / release / destroy、Metal / AppKit / Objective-C / FFI、GPU submission、render / draw call、renderer state write 或 public API expansion。

## 证据读取

本轮读取并采用以下 evidence，但所有 reference evidence 都不能升格为 runtime truth：

- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)：固定 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`，只代表 render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts；不授予 encoder、`renderCommandEncoder`、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)：提供 encoder lifecycle intent、encoding scope policy、pipeline binding guard、end-encoding policy 与 no-encoder readiness vocabulary。该 manifest 不是 encoder implementation manifest，`CjguiInternalRendererNoEncoderReadiness` 也不是本轮 runtime input。
- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)：提供 no-real-command-buffer-implementation upstream evidence，继续拒绝 command buffer、`commandBuffer`、`commit`、render pass、encoder、GPU submission、render、renderer state write 或 public API permission。
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)：提供 no-real-drawable-implementation evidence，继续拒绝 drawable、`nextDrawable`、present、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)：提供 no-gpu-submission evidence，继续拒绝 `commit`、`present`、`nextDrawable`、command buffer、drawable、render pass、encoder、pipeline state、GPU submission、render、renderer state write 或 public API permission。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)：提供 Apple Metal command encoder / render pass / command buffer 关系依据，但只作为 docs evidence，不是 runtime input，不批准 Metal / AppKit / Objective-C / FFI implementation。
- [GUI 风险账本](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)：继续提醒 GPU 资源生命周期、FFI 所有权、主线程边界、错误处理、资源限制与视觉验证风险；本轮只登记 stop-line，不实现任何资源。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：要求新增 / 修改 Markdown 使用中文正文与中文章节标题，并要求后续新增 `.cj` owner file 保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

结论：evidence 足够打开 encoder implementation runway，但只够打开 admission value boundary，不足以进入真实 encoder creation。

理由：

- `CjguiInternalRendererNoRenderPassImplementationReadiness` 已经是新的 no-render-pass-implementation endpoint，可作为下一步 encoder admission 的唯一 runtime input candidate。
- encoder lifecycle manifest 已经提供 encoding scope、pipeline binding guard、end-encoding policy 与 no-encoder vocabulary，足以让下一步表达 encoder creation admission、encoding scope admission 与 end-encoding admission。
- backend / Metal reference pack 确认 encoder 通常与 command buffer、render pass descriptor、pipeline / resource binding 和 draw call 关系紧密，因此下一步必须停在 admission facts，不能创建真实 encoder。
- command submission manifest 和 real command buffer implementation admission manifest 继续证明当前没有 GPU submission、`commit`、command buffer creation 或 completion observation permission。
- 风险账本要求 GPU / FFI / platform resource lifecycle 在真实资源前先冻结 owner、teardown、failure 与 validation strategy；本轮只能把这些写入 stop-line。

不需要先选择更窄 B / C / D 的原因：

- encoder creation 与 render pass / command buffer 的关系已经由 render pass implementation admission manifest、real command buffer implementation admission manifest 和 reference pack 覆盖到足够 preflight 深度。
- `endEncoding` 与 post-encoding invalidation 已由 encoder lifecycle manifest 作为 vocabulary 固定，下一步可在 admission value boundary 中表达，不需要先单独拆 preflight。
- pipeline binding 关系仍然只能作为 admission guard / placeholder，不进入 pipeline implementation；若后续靠近 pipeline state，必须另开 docs-only preflight。

## 候选比较

### 候选 A：推荐 encoder implementation admission value boundary

选择：

`P1 internal Renderer encoder implementation admission value boundary bundle implementation`

该候选只允许表达 encoder implementation intent / encoder creation admission policy / encoding scope admission guard / end-encoding admission policy / no-encoder-implementation readiness facts。

它不创建 encoder，不调用 `renderCommandEncoder`，不调用 `endEncoding`，不绑定 pipeline / buffer / texture / resource，不新增 native handle、FFI declaration 或 C ABI。

### 候选 B：暂缓 encoder creation admission preflight

暂不选择。

当前 render pass / command buffer relation evidence 足够支撑 value boundary。只有未来发现 creation admission owner、runtime input 或 failure semantics 不足时，才回到更窄 preflight。

### 候选 C：暂缓 end-encoding admission preflight

暂不选择。

`EndEncodingPolicy` 已提供 end-encoding boundary 与 post-encoding invalidation vocabulary。下一步只表达 admission facts，不调用 `endEncoding`，因此不需要先单独拆分。

### 候选 D：暂缓 pipeline binding admission preflight

暂不选择。

Pipeline binding 仍应作为 encoder admission 的 guard / placeholder。真实 pipeline implementation 或 pipeline binding 必须晚于 encoder admission manifest，并另开 docs-only preflight。

### 候选 E 到 G：暂缓后续渲染切口

Pipeline implementation preflight、draw call implementation preflight 与 render pass admission hardening 均暂缓。它们都更靠近 pipeline state、resource binding、draw command、GPU submission 或 render execution。

### 候选 H 到 U：拒绝直接实现或发布

拒绝 direct encoder creation implementation、direct `renderCommandEncoder` call、direct `endEncoding` implementation、direct pipeline / buffer / texture / resource binding、direct command buffer / commit implementation、direct render pass / attachment / texture implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 V：仅限明确重复时 consolidation

当前没有 duplicate / self-wrapping evidence，不选择 consolidation。

## 同构边界刹车（Same-shape Boundary Brake）

不得把 `CjguiInternalRendererNoRenderPassImplementationReadiness`、`CjguiInternalRendererNoEncoderReadiness`、`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 或 reference evidence 包成：

- encoder implementation receipt / record / publication。
- encoder-ready permission wrapper。
- `renderCommandEncoder` permission wrapper。
- `endEncoding` permission wrapper。
- pipeline-binding permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一步进入 value boundary，必须证明新增的是 encoder creation admission、encoding scope admission、end-encoding admission 与 no-encoder-implementation readiness 语义，而不是把 no-render-pass-implementation endpoint 换名包装。

`CjguiInternalRendererNoEncoderReadiness` 只作为既有 encoder lifecycle vocabulary evidence，不能被升级为 encoder implementation permission，也不能成为本次 implementation admission owner 的 runtime input。

## 停止线

在后续 docs-only preflight 或 value boundary 明确批准前，继续禁止：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 `runtime_state.cj`。
- 不触碰 `runtime/cjgui/cjpm.toml`。
- 不触碰 smoke / harness / native bridge / entry。
- 不触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不创建 encoder。
- 不调用 `renderCommandEncoder`。
- 不调用 `endEncoding`。
- 不绑定 pipeline / buffer / texture / resource。
- 不创建 render pass descriptor。
- 不创建 attachment object。
- 不创建 texture。
- 不获取 drawable。
- 不创建 pipeline state。
- 不创建 command buffer。
- 不调用 `commandBuffer`。
- 不调用 `commit`。
- 不调用 `present`。
- 不调用 `nextDrawable`。
- 不创建 native handle。
- 不创建 raw pointer。
- 不新增 C ABI。
- 不新增 FFI declaration。
- 不调用 bridge。
- 不调用 retain / release / destroy。
- 不调用 Metal / AppKit / Objective-C / FFI。
- 不提交 GPU work。
- 不执行 render / draw call。
- 不写 renderer state。
- 不扩 public API。

## 公共 surface

Public declaration allowlist 仍保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 preflight 不批准新增 public declaration，不批准 public C ABI，不批准 diagnostics / event bus / observer / telemetry 或 public API。

## 验证记录

本轮已执行允许的 docs-only 验证：

- `git diff --check` 通过。
- 新 decision no-index whitespace check 通过。
- Markdown absolute link missing target check 通过，范围限定 project Markdown，已避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 通过，四个入口均可到达本 decision 与新的唯一后续入口。
- Markdown 中文标题与中文正文抽查通过：新增 diff 中未出现 `Decision` / `Boundary` / `Verification` / `Next Opening` 作为主标题，新增标题与正文均有中文承载。
- forbidden check 通过：无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan 通过，仍只看到 `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool {`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 已执行：`changed_count=33`、`changed_files=11`、`affected_count=0`、`risk_level=low`、`affected_processes=[]`。

本轮按约束没有运行 `cjpm build`，没有运行 smoke。

## 下游落地

下游 encoder implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj)

该 owner 只消费 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`。

当前 truth 仅限 encoder implementation intent / encoder creation admission policy / encoding scope admission guard / end-encoding admission policy / no-encoder-implementation readiness value facts。它仍不是 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline / buffer / texture / resource binding permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

后续新增 `.cj` owner 文件仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

下游 encoder implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 足够作为当前 no-encoder-implementation endpoint。下一步只能 docs-only 固定 owner / truth / canonical endpoint / stop-line，不批准继续包装成 receipt / record / publication 或 permission wrapper。

下游 encoder implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_encoder_admission.cj` owner / truth / canonical endpoint / default draft / stop-line。Canonical endpoint 是 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，下一步进入 docs-only pipeline state implementation preflight。

## 唯一后续入口

`P1 internal Renderer pipeline state implementation preflight decision`
