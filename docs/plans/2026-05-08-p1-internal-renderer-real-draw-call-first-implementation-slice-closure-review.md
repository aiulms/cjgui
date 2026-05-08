# P1 内部渲染器真实 draw call 第一实现切片封账复核

状态：完成 / runtime owner shell 已新增 / no-real-draw-call

## 实施范围

本轮新增 internal-only owner：

`runtime/cjgui/src/runtime_renderer_draw_call_real.cj`

新增 runtime symbols：

- `CjguiInternalRendererRealDrawCallShellIntent`
- `CjguiInternalRendererRealDrawPrimitiveCommandDenialProof`
- `CjguiInternalRendererRealDrawGeometryBindingDenialProof`
- `CjguiInternalRendererRealDrawOrderingAdmissionShell`
- `CjguiInternalRendererRealDrawExecutionDenialProof`
- `CjguiInternalRendererNoRealDrawCallShellReadiness`
- 对应 builders
- `cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()`

## 当前 truth

唯一 runtime input 是 `CjguiInternalRendererNoRealPipelineStateShellReadiness`。

Canonical endpoint 是 `CjguiInternalRendererNoRealDrawCallShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()`。

当前 truth 只限：

- real draw call shell intent
- primitive command denial proof
- geometry binding denial proof
- draw ordering admission shell
- draw execution denial proof
- no-real-draw-call-shell readiness facts

该 owner 是 internal-only shell / dehydrated facts，不是真实 draw command、primitive API、pipeline / buffer / texture / resource binding、GPU work、native bridge、native handle、C ABI / FFI、renderer state write 或 public API permission。

## GitNexus 影响记录

编辑前已对上游入口运行 GitNexus impact：

- `CjguiInternalRendererNoRealPipelineStateShellReadiness`：GitNexus 返回 not found / `UNKNOWN`，affected_count 为 `0`。
- `cjguiInternalExecuteDefaultRendererRealPipelineStateShellDraft`：GitNexus 返回 not found / `UNKNOWN`，affected_count 为 `0`。

归类：近期新增 owner 尚未被索引覆盖。本轮按源码读取、`cjpm build`、smoke 与 stop-line scan 兜底；未出现 HIGH / CRITICAL 风险信号。

## 构建修复记录

首次构建暴露新增 owner 内部字段引用不一致：draw call owner 使用了 pipeline state shell 不存在的 `didConfirmRendererNoRealPipelineStateShellReadiness` 与 `didPrepareRendererNoRealPipelineStateShellReadiness` 字段。

修复范围只限 `runtime_renderer_draw_call_real.cj`：按 `CjguiInternalRendererNoRealPipelineStateShellReadiness` 类型定义，将上游 ready / sealed 判断对齐到 `isRendererNoRealPipelineStateShellReady` 与 `didSealRendererNoRealPipelineStateShellReadiness`。

修复未改变 endpoint、default draft、runtime input、truth 或 stop-line。

## 停止线确认

- 未发出真实 draw call。
- 未调用 `drawPrimitives` 或 `drawIndexedPrimitives`。
- 未绑定 pipeline / buffer / texture / resource。
- 未创建真实 pipeline state、shader function、pipeline descriptor、encoder、command buffer、drawable 或 render pass。
- 未调用 `renderCommandEncoder`、`endEncoding`、`commandBuffer`、`commit`、`present` 或 `nextDrawable`。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime_state.cj`。
- 未新增 public API / C ABI。
- 未修改 native bridge / Objective-C / Metal / AppKit / FFI。
- 未创建 native handle / raw pointer。
- 未调用 retain / release / destroy。
- 未新增 module-level mutable `var`。

## 验证记录

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-real-draw-call-first-slice-macro-target --skip-script`：通过；仅见既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- 新 runtime / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：无 tracked `.cj` diff；protected paths clean；`runtime_state.cj` 行数仍为 `10065`。
- comment-aware public declaration scan：仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- new owner header / stop-line scan：通过。
- GitNexus detect_changes：risk_level 为 `low`，affected_count 为 `0`。

## 同构边界刹车

本轮没有把 `CjguiInternalRendererNoRealPipelineStateShellReadiness`、draw call lifecycle / admission manifest 或 smoke evidence 薄包装成 draw-ready permission、binding-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt / record / publication。

新增 owner 的价值是 draw call shell / primitive command denial / geometry binding denial / ordering admission / execution denial 语义。

## 设计意图出口自检

- 本轮改变主题状态：是，real draw call first slice owner shell 已新增。
- 本轮改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoRealDrawCallShellReadiness`。
- 本轮改变 owner / truth / stop-line：是，新增 `runtime_renderer_draw_call_real.cj`；truth 与 stop-line 如本文所列。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real draw call first implementation slice closure / next real draw call decision`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real draw call first implementation slice closure / next real draw call decision`
