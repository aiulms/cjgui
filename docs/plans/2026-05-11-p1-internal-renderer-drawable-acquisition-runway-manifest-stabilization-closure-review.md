# Drawable acquisition 清单稳定化复核

## 封账结果

[Drawable acquisition 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md) 已固定本轮 actual route 为 A/B：planning / no-acquire facts 加 availability / still-blocked facts。

当前 canonical endpoint 为 `CjguiInternalRendererNoDrawableAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft()`。本轮没有新增 production native C ABI，没有进入 `nextDrawable` feasibility，也没有修改 `runtime/cjgui/cjpm.toml`。

## 导航同步

已同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

上游 Metal device binding runway manifest / closure / next-boundary 已补 downstream 指向本阶段。

## 风险记录

GitNexus 对上游与新 owner symbols 均返回近期新增 symbol 未索引 / not found，risk 记录为 UNKNOWN，affected count 为 0。本轮以源码读取、`cjpm build`、probe 与 forbidden scan 兜底。

GitNexus `detect_changes(scope=unstaged)` 返回 low，affected processes 为 0；输出覆盖当前工作树已有多阶段改动，本阶段按源码/build/probe/scan 对 drawable acquisition 写集单独兜底。

## 验证记录

- 新增 drawable acquisition planning probe 已通过，并观察 `next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。
- 既有 native / runtime-adjacent 回归探针已通过：Metal device binding / create-destroy / availability，CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach，NSView runtime call / create-destroy / object table / feasibility / no-object creation，AppKit import / class / main-thread，teardown，token issue-revoke，no-resource call，isolated FFI，package link，cjpm package link，skeleton compile，symbol probe，cjpm boundary。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-acquisition-runway-target --skip-script` 已通过，只有既有 unused warning。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`、`git diff --check`、runtime/native/script/docs whitespace check、Markdown absolute link check、reachability check、中文标题正文抽查均已通过。
- Protected path scan 确认 `runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行；public declaration scan 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native forbidden scan 确认没有 drawable present、command queue / buffer / encoder、GPU submission、render、pointer return 或 public API。

## 保留风险

`nextDrawable` 仍未执行。后续如要进入 C，必须先证明 headless / CI-like shell 稳定性、drawable lifecycle cleanup、no-present path、command queue / command buffer absence 与 no renderer state write。否则应继续停在 blocked callable / recovery。

## 下游接续

本 manifest 的唯一后续入口已由 [Drawable acquisition first implementation 清单稳定化复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-drawable-acquisition-first-implementation-manifest-stabilization-closure-review.md) 接续。下游当前 tail 是 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`，并把后续入口改为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition A/B 已完成 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableAvailabilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning / availability owner 与 planning probe；truth 限 no-acquire / still-blocked facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
