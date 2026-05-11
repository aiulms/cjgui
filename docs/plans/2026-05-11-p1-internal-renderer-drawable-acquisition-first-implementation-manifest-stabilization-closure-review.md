# Drawable acquisition first implementation 清单稳定化复核

## 封账结果

[Drawable acquisition first implementation recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md) 已固定本轮 actual route 为 A：recovery/preflight only。

当前 canonical endpoint 为 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()`。本轮没有新增 production native C ABI，没有调用 `nextDrawable`，没有修改 `runtime/cjgui/cjpm.toml`。

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

上游 drawable availability、Metal device binding、CAMetalLayer attachment、token / teardown 相关 manifest 已补 downstream 指向本阶段。

本阶段 downstream 已由 [drawable environment / window visibility planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续，当前下游 endpoint 是 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`；该下游仍未调用 `nextDrawable`，未 present，未创建 command queue / command buffer / encoder，未提交 GPU work 或 render。

## 风险记录

GitNexus 对上游与新 owner symbols 均返回近期新增 symbol 未索引 / not found，risk 记录为 UNKNOWN，affected count 为 0。本轮以源码读取、`cjpm build`、probe 与 forbidden scan 兜底。

## 验证记录

- 新增 drawable acquisition recovery probe 已通过，并观察 `next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。
- 全量回归 probe 已通过：Metal device binding / create-destroy / availability，CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach，NSView runtime call / create-destroy / object table / feasibility / no-object creation，AppKit import / class / main-thread，teardown，token issue/revoke，no-resource call，isolated FFI，package link，cjpm package link，skeleton compile，symbol probe，cjpm boundary。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-acquisition-first-implementation-target --skip-script` 已在 `runtime/cjgui` 下通过；保留既有 unused 警告，不影响本阶段封账。
- macOS smoke auto-close 已通过。
- `git diff --check`、本阶段写集 whitespace、Markdown absolute link、reachability、中文标题正文抽查、public declaration scan、native forbidden scan、protected path scan 与 owner / script header stop-line scan 均已通过。
- GitNexus `detect_changes(scope=unstaged)` 返回 `risk=low`、`affected_processes=0`，本轮未引入执行流影响；变更检测覆盖当前未暂存工作树的 35 个文件 / 21 个文档或 owner symbols。

## 保留风险

`nextDrawable` 仍未执行。后续要进入 B/C，必须先证明 visible window / display-backed layer / run loop non-blocking / no-present acquisition cleanup；如果这些证据仍不足，应继续停在 recovery。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition first implementation 已封账为 recovery。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 recovery owner 与 recovery probe；truth 限 blocker facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
