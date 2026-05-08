# P1 渲染器真实 draw call 第一切片后续边界决策

状态：完成 / docs-only / 不新增 runtime owner

## 当前确认

`CjguiInternalRendererNoRealDrawCallShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawCallShellDraft()` 足够作为当前 no-real-draw-call-shell endpoint。

该 endpoint 只代表 draw call shell intent、primitive command denial proof、geometry binding denial proof、draw ordering admission shell、draw execution denial proof 与 no-real-draw-call-shell readiness facts。

它不是真实 draw call、`drawPrimitives`、`drawIndexedPrimitives`、pipeline / buffer / texture / resource binding、GPU submission、render、renderer state write、backend ready truth 或 public API permission。

## 候选取舍

- A 胜出：进入 `P1 internal Renderer real draw call first implementation slice manifest stabilization bundle implementation`。理由是 owner shell 已构建通过，下一步应固定 owner / truth / endpoint / stop-line。
- B 暂缓：draw call shell hardening。当前没有发现必须追加的 shell facts 缺口。
- C 暂缓：native bridge draw call write-set preflight。当前不需要触碰 native bridge 或 Metal / AppKit 写集。
- D 拒绝：直接 resource binding / GPU / render / state write / public API。

## 同构边界刹车

`CjguiInternalRendererNoRealDrawCallShellReadiness` 不得继续包装成 draw-ready wrapper、binding-ready wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、public diagnostics wrapper 或 receipt / record / publication。

下一步只允许 manifest stabilization；不得跳到 render execution、GPU submission、renderer state write 或 public API。

## 停止线

- no real draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / resource binding
- no real pipeline state
- no shader function load / compile
- no pipeline descriptor creation
- no real encoder
- no `renderCommandEncoder`
- no `endEncoding`
- no command buffer
- no `commandBuffer`
- no `commit`
- no `present`
- no `nextDrawable`
- no GPU submission
- no render execution
- no renderer state write
- no `runtime_state.cj` modification
- no public API / C ABI
- no native bridge / Objective-C / Metal / AppKit / FFI
- no native handle / raw pointer
- no retain / release / destroy
- no module-level mutable `var`

## 设计意图出口自检

- 本轮改变主题状态：是，从 slice closure 推进到 manifest stabilization。
- 本轮改变 canonical tail / endpoint：否，仍是 `CjguiInternalRendererNoRealDrawCallShellReadiness`。
- 本轮改变 owner / truth / stop-line：否，只确认现有 owner 与 stop-line。
- 本轮改变唯一 next opening：是，转为 `P1 internal Renderer real draw call first implementation slice manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real draw call first implementation slice manifest stabilization bundle implementation`
