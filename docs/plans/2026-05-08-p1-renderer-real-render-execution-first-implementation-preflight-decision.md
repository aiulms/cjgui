# P1 渲染器真实 render execution 第一实现预检决策

状态：完成 / docs-only / 不新增 runtime owner

## 读取入口

本轮已读取 real draw call branch closure、draw call owner、pipeline state owner、render execution no-op / implementation admission manifest、command submission manifest、renderer state write implementation admission manifest 与 backend readiness 相关 stop-line 证据，并从设计意图入口确认当前 Renderer runway。

## 预检判断

`CjguiInternalRendererNoRealDrawCallShellReadiness` 足够作为进入 real render execution planning 的上游 endpoint。它只能作为 planning evidence，不能升格为真实 draw call、resource binding、GPU submission 或 render permission。

real render execution 第一实现切片可以打开，但第一刀必须是极窄 internal owner shell / dehydrated execution result facts。默认 owner candidate 是：

`runtime/cjgui/src/runtime_renderer_render_execution_real.cj`

runtime input candidate 只能消费：

`CjguiInternalRendererNoRealDrawCallShellReadiness`

第一切片只允许表达：

- real render execution shell intent
- execution admission shell
- completion observation denial proof
- rollback execution denial proof
- render execution failure classification
- no-real-render-execution-shell readiness facts

## 禁止事项

本 preflight 不批准真实 render execution，不批准 GPU submission，不批准 `commit` / `present`，不批准 `drawPrimitives` / `drawIndexedPrimitives`，不批准 pipeline / buffer / texture / resource binding，不批准真实 encoder / render pass / command buffer，不批准 `renderCommandEncoder`、`endEncoding`、`commandBuffer` 或 `nextDrawable`，不批准 renderer state write、native bridge / Objective-C / Metal / AppKit / FFI、C ABI、native handle、raw pointer 或 public API。

## 候选取舍

- A 胜出：进入 `P1 internal Renderer real render execution first implementation slice bundle`。理由是可以用 owner shell 表达 execution admission、completion denial、rollback denial 与 failure classification，不需要触碰 native bridge 或真实 Metal API。
- B 暂缓：draw call shell hardening。当前上游 endpoint 已完成 manifest 封账。
- C 暂缓：native bridge draw execution write-set preflight。当前第一刀不需要 native bridge 写集。
- D 拒绝：直接 render / GPU submission / commit / state write / public API。

## 同构边界刹车

不得把 draw call shell endpoint、render execution no-op / implementation admission manifest、command submission manifest、smoke evidence 或 branch milestone 包装成 render-ready permission、GPU-submission permission、completion-ready permission、renderer-state-write permission、receipt / record / publication。

下一刀若实施，必须新增 render execution shell / completion denial / rollback denial / failure classification 语义，而不是 thin wrapper。

## 停止线

- no real render execution
- no GPU submission
- no `commit`
- no `present`
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / resource binding
- no real encoder
- no real render pass
- no real command buffer
- no `renderCommandEncoder`
- no `endEncoding`
- no `commandBuffer`
- no `nextDrawable`
- no renderer state write
- no `runtime_state.cj` modification
- no public API / C ABI
- no native bridge / Objective-C / Metal / AppKit / FFI
- no native handle / raw pointer
- no retain / release / destroy
- no module-level mutable `var`

## 设计意图出口自检

- 本轮改变主题状态：是，从 render execution preflight 前置状态推进到允许极窄 first slice。
- 本轮改变 canonical tail / endpoint：否，preflight 只确认候选，不创建 endpoint。
- 本轮改变 owner / truth / stop-line：否，候选 owner 仍待下一步实现。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real render execution first implementation slice bundle`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real render execution first implementation slice bundle`
