# P1 渲染器 encoder implementation admission next-boundary 决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 决策结论

`CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()` 已足够作为当前 no-encoder-implementation endpoint。

当前 endpoint 只代表 encoder implementation intent / encoder creation admission policy / encoding scope admission guard / end-encoding admission policy / no-encoder-implementation readiness value facts。

它不是 encoder permission、`renderCommandEncoder` permission、`endEncoding` permission、pipeline / buffer / texture / resource binding permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下一步选择：

`P1 internal Renderer encoder implementation admission manifest stabilization bundle implementation`

下一步仍必须 docs-only，只能固定 owner / truth / canonical endpoint / stop-line / Same-shape Boundary Brake；不得继续把当前 endpoint 包成 tail wrapper。后续若新增 runtime owner，文件头维护注释仍必须覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake，且不能把 admission facts 写成真实 implementation permission。

## 读取依据

本轮读取并确认：

- [runtime_renderer_encoder_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_encoder_admission.cj)：固定 internal-only owner、唯一 runtime input、canonical endpoint、value facts 与 stop-line。
- [encoder implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-value-boundary-closure-review.md)：记录 GitNexus impact、build、smoke、stop-line scan、public declaration scan 与 closure 结论。
- [encoder implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md)：确认 runway 只允许 admission value boundary，不允许真实 encoder implementation。
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)：固定 `CjguiInternalRendererNoRenderPassImplementationReadiness` 作为上游 evidence，不授予 encoder 或 command buffer 权限。
- [encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)：提供 encoder lifecycle vocabulary，但 `CjguiInternalRendererNoEncoderReadiness` 不是 implementation admission runtime input。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：要求 Markdown 中文正文 / 中文标题，并要求后续新增 `.cj` owner 文件保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## endpoint 足够性

当前 endpoint 已覆盖本阶段需要封账的事实：

- encoder implementation intent 已表达未来 implementation admission 的意图，但没有 implementation permission。
- encoder creation admission policy 已表达 creation admission 事实，但不创建 encoder，不调用外部编码 API，不保存 encoder token。
- encoding scope admission guard 已表达 scope admission 与 no command encoding 事实，但不绑定 pipeline / buffer / texture / resource，不发 draw call。
- end-encoding admission policy 已表达 end-encoding admission 与 post-encoding invalidation 事实，但不调用 `endEncoding`，不注册 completion callback，不观察真实 GPU completion。
- no-encoder-implementation readiness 已 sealed 为 value-only endpoint，保留 no resource / no GPU / no render / no state write / no public API stop-line。

因此不需要继续新增 receipt / record / publication，也不需要再包一层 encoder-ready permission wrapper。下一步应固定 manifest，而不是继续扩展 runtime owner 链。

## 候选比较

### 候选 A：推荐 manifest stabilization

选择：

`P1 internal Renderer encoder implementation admission manifest stabilization bundle implementation`

理由：当前 owner、runtime input、canonical endpoint、default draft、truth 和 stop-line 已由 value boundary closure 验证通过；下一步只需要 docs-only 固定 manifest，避免 endpoint 被继续 thin-wrapper 化。

### 候选 B：暂缓 pipeline state implementation preflight

暂缓。Pipeline state 更靠近 pipeline descriptor、shader function、pipeline object 与 encoder binding，应晚于 encoder admission manifest stabilization。

### 候选 C：暂缓 draw call implementation preflight

暂缓。Draw call 更靠近 render execution、resource binding 和 command encoding，应晚于 encoder admission manifest stabilization。

### 候选 D：暂缓 encoder admission hardening

暂缓。只有发现 encoder creation admission / encoding scope admission 表达不足时才选择。当前 closure 没有暴露这类缺口。

### 候选 E：暂缓 end-encoding admission hardening

暂缓。`CjguiInternalRendererEndEncodingAdmissionPolicy` 已表达 end-encoding admission、post-encoding invalidation 与 no completion observation facts；当前不需要进一步硬化。

### 候选 F 到 R：拒绝 wrapper、直接实现和发布

拒绝 encoder receipt / record / publication、encoder-ready permission wrapper、`renderCommandEncoder` permission wrapper、`endEncoding` permission wrapper、pipeline / buffer / texture / resource binding wrapper、command-buffer-ready wrapper、GPU-submission wrapper、render-permission wrapper、direct encoder creation implementation、direct Metal / AppKit / Objective-C / FFI implementation、renderer state write、public API / C ABI expansion。

Consolidation 仅在明确 duplicate / self-wrapping evidence 出现时选择；当前 evidence 指向 manifest stabilization，不指向删除或合并。

## 同构边界刹车（Same-shape Boundary Brake）

`CjguiInternalRendererNoEncoderImplementationReadiness` 不得继续包装成：

- 不包装成 receipt / record / publication。
- 不包装成 encoder-ready permission wrapper。
- 不包装成 `renderCommandEncoder` permission wrapper。
- 不包装成 `endEncoding` permission wrapper。
- 不包装成 pipeline-binding permission wrapper。
- 不包装成 command-buffer permission wrapper。
- 不包装成 native-handle permission wrapper。
- 不包装成 C-ABI / FFI permission wrapper。
- 不包装成 GPU-submission wrapper。
- 不包装成 render-permission wrapper。
- 不包装成 renderer-state-write wrapper。

若下一步选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / stop-line，不能新增 runtime owner，不能新增 value-tail wrapper，不能扩大 public surface。

## 停止线

本轮和下一轮 manifest stabilization 前继续禁止：

- 不创建 encoder。
- 不调用 `renderCommandEncoder`。
- 不调用 `endEncoding`。
- 不绑定 pipeline / buffer / texture / resource。
- 不创建 command buffer。
- 不调用 `commandBuffer`。
- 不调用 `commit`。
- 不获取 drawable。
- 不调用 `nextDrawable`。
- 不调用 `present`。
- 不创建 native handle。
- 不创建 raw pointer。
- 不新增 C ABI。
- 不新增 FFI declaration。
- 不调用 bridge。
- 不调用 retain / release / destroy。
- 不调用 Metal / AppKit / Objective-C。
- 不提交 GPU submission。
- 不执行 render / draw call。
- 不写 renderer state。
- 不扩 public API。

同时不得触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## 文档同步

本 decision 成为以下文档的 downstream 指向：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [encoder implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-preflight-decision.md)
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)
- [encoder lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-manifest.md)

下游 encoder implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-encoder-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime_renderer_encoder_admission.cj` owner / truth / canonical endpoint / default draft / stop-line。`CjguiInternalRendererNoEncoderImplementationReadiness` 仍不是 encoder、`renderCommandEncoder`、`endEncoding`、pipeline / buffer / texture / resource binding、command buffer、GPU submission、render、renderer state write 或 public API permission。

## 验证记录

本轮 docs-only 验证结果：

- `git diff --check` 通过。
- 新 decision no-index whitespace check 通过。
- Markdown absolute link missing target check 通过；检查范围限定 project docs scope，并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 检查通过。
- Markdown 中文标题与中文正文抽查通过。
- forbidden check 通过：无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan 通过：仍只能看到 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 完成：`changed_count=33`、`affected_count=0`、`changed_files=11`、`risk_level=low`，没有 affected processes。

本轮按约束不运行 `cjpm build`，不运行 smoke，也没有触碰 `.cj` runtime owner。

## 唯一后续入口

`P1 internal Renderer pipeline state implementation preflight decision`
