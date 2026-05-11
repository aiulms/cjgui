# P1 内部渲染器 CAMetalLayer runtime attachment FFI call owner 阶段封账

日期：2026-05-11

状态：stage closure / runtime owner 完成

## 封账结论

本轮新增 `CAMetalLayer` runtime attachment FFI call owner。Owner 消费 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`，复用同 package 已验证的 `foreign func` declaration，局部执行 create `NSView` token、create `CAMetalLayer` token、attach、classify attached、detach、double detach classify 与 cleanup destroy，并只生成 internal dehydrated facts。

该结果不新增 production native C ABI，不修改 `runtime/cjgui/cjpm.toml`，不新增 public API，不写 renderer state，不返回 token / pointer / handle / `id` / `Class` 到 public surface，也不证明 backend ready、render ready、Metal device binding 或 drawable acquisition。

## 实际写集

- Runtime owner：`runtime/cjgui/src/runtime_renderer_cametallayer_attachment_runtime_call.cj`
- Runtime-adjacent probe：`runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_attachment_runtime_call.sh`
- 文档：本轮 preflight、closure、next-boundary、manifest 与 manifest closure。
- 索引同步：README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。

## Runtime owner

- Endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness`

Owner 固定 facts：

- Runtime internal attach / classify / detach call 已执行。
- Token 只在函数局部存在，不持久化。
- Attach 后 classify 为 attached。
- Detach 后 classify 为 detached。
- Double detach fail-closed。
- Cleanup 后 `NSView` / `CAMetalLayer` occupied count 回到 `0`。
- Device binding after attach 仍 blocked。
- No Metal / device / drawable / render / GPU submission / state write。

## 验证摘要

- 新 runtime attachment call probe 通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-cametallayer-attachment-runtime-call-target --skip-script` 通过，仅保留既有 unused warnings。
- GitNexus impact 对上游 endpoint / default draft、新 endpoint 与 native attach symbol 均为近期新增符号未索引 / UNKNOWN，`impactedCount=0`，无 HIGH / CRITICAL；已用源码、build、probe 与 scan 兜底。

## Stop-line

- 不 import Metal。
- 不创建 `MTLDevice` / command queue / drawable / command buffer。
- 不设置 `CAMetalLayer.device`。
- 不调用 `nextDrawable`。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不返回 pointer / handle / `id` / `Class`。

## 下游已接续

后续 [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md) 已完成，接续本 closure 固定的 `CAMetalLayer` attachment runtime facts。该下游只允许 `Metal` import、default `MTLDevice` availability、token-backed `MTLDevice` create / destroy 与 `CAMetalLayer.device` bind / unbind first slice；仍禁止 drawable acquisition、`nextDrawable`、command queue、command buffer、GPU submission、render、renderer state write、public API 与 pointer / handle return。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 token-backed attachment first slice 推进到 runtime internal FFI call owner。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 runtime attachment call owner；truth 限于 internal dehydrated call facts；stop-line 继续禁止 Metal、device、drawable、public、state write 与 backend-ready。
- 本轮是否改变唯一 next opening：是，若 manifest stabilization 成功则转为 `P1 internal Renderer Metal device binding planning preflight decision`。
- 是否同步 topic manifest：将在 manifest stabilization 同步。
- 已同步哪些 topic manifest：阶段 closure 记录为待同步。
