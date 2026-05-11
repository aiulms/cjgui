# P1 内部渲染器 CAMetalLayer NSView attachment 清单稳定化封账

日期：2026-05-11

状态：manifest stabilization closure / completed through C route

## 稳定化结论

本轮完成 token-backed `CAMetalLayer` attach/detach first slice 并封账。Production native bridge 当前允许在 main thread 内设置 `NSView.wantsLayer` / `NSView.layer`，但仅限 attachment C ABI 内部；detach 会清理 attachment relation，destroy 前仍要求 detach。该能力不包含 Metal device、drawable、render、GPU submission、public API、renderer state write 或 backend-ready truth。

## 验证摘要

新增 probe 已通过：

- `verify_native_bridge_cametallayer_nsview_attachment.sh`

核心观测：

- `NSView` token 与 `CAMetalLayer` token create observed。
- Background attach / detach denied observed。
- Attach observed，attachment classify attached observed。
- Double attach fail-closed observed。
- Detach observed，attachment classify detached observed。
- Double detach fail-closed observed。
- Invalid / stale token fail-closed observed。
- Cleanup 后 occupied count 归零 observed。
- Device binding still blocked observed。
- Metal import / device / drawable / pointer return / public API 均未出现。

完整回归已通过：

- CAMetalLayer no-attach / allocation / object table / create-destroy probes 通过。
- NSView runtime-call / create-destroy / object table / feasibility / no-object creation probes 通过。
- AppKit import / class availability / main-thread admission probes 通过。
- Teardown admission、token issue/revoke、no-resource call、isolated FFI、package link、cjpm package link、skeleton compile、symbol probe 与 cjpm boundary 均通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-cametallayer-nsview-attachment-target --skip-script` 通过，仅保留既有 unused warnings。

## 唯一后续入口

`P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`

后续 [CAMetalLayer runtime attachment FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md) 已完成。该下游只把本阶段 attachment C ABI 接入 runtime internal FFI call owner，并保持 no Metal、no device、no drawable、no public、no renderer state write stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，主线从 `CAMetalLayer` create/destroy first slice 推进到 token-backed `NSView` attachment first slice。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoCAMetalLayerNSViewAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNSViewAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 attachment owner 与 native callable；truth 限于 main-thread token-backed attach/detach lifecycle；stop-line 继续禁止 Metal、drawable、public、state write。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer runtime attachment FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
