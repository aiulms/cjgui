# Drawable 环境与窗口可见性清单稳定化复核

## 封账结果

[Drawable 环境与窗口可见性清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 已固定本轮 actual route 为 A：environment / window visibility planning value boundary。

当前 canonical endpoint 为 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`。本轮没有新增 production native C ABI，没有创建 `NSWindow`，没有调用 `nextDrawable`，没有修改 `runtime/cjgui/cjpm.toml`。

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

上游 drawable recovery、drawable availability、Metal device binding、CAMetalLayer attachment 与 real drawable admission 相关 manifest 已补 downstream 指向本阶段。

## 风险记录

GitNexus 对上游 symbols 返回近期新增 symbol 未索引 / not found，risk 记录为 UNKNOWN，affected count 为 0。本轮以源码读取、`cjpm build`、probe 与 forbidden scan 兜底。

## 验证记录

- 新增 drawable visible-window environment planning probe 已通过，并观察 `drawable_environment_visibility_probe=passed`、`isolated_visible_window_probe_executed=false`、`production_window_created=false`、`next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。
- 全量回归 probe 已通过：drawable recovery / planning、Metal device binding、CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach、NSView runtime call / create-destroy / object table / feasibility / no-object creation、AppKit import / class / main-thread、teardown、token issue/revoke、no-resource call、isolated FFI、package link、cjpm package link、skeleton compile、symbol probe、cjpm boundary。
- `verify_native_bridge_cjpm_integration_boundary.sh` 在 source `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 后通过；未 source 时的 `cjpm not found` 提示记录为 runner 环境缺省，不是本阶段 blocker。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-environment-window-visibility-target --skip-script` 已在 `runtime/cjgui` 下通过；保留既有 unused warnings，不影响本阶段封账。
- macOS smoke auto-close 已通过。
- `git diff --check`、本阶段写集 whitespace、Markdown absolute link、reachability、中文标题正文抽查、public declaration scan、native forbidden scan、protected path scan 与 owner / script header stop-line scan 均已通过。
- Broad docs whitespace check 命中过往 2026-04 历史 docs 既有 trailing whitespace；按本阶段变更写集复查通过，未扩大写集修历史无关空白。
- GitNexus `detect_changes(scope=unstaged)` 返回 `risk=low`、`affected_processes=0`，当前未暂存工作树检测到 35 个文件 / 21 个 symbols；上游 impact 对近期新增 owner 仍为 UNKNOWN / not found，已用源码、build、probe 与 scan 兜底。

## 保留风险

`nextDrawable` 仍未执行。后续要进入 visible-window acquisition probe，必须先证明 isolated `NSWindow` 创建、display-backed `CAMetalLayer`、bounded run loop 与 no-present cleanup 稳定；如果这些证据仍不足，应继续停在 recovery。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable environment / window visibility planning 已封账。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner 与 planning consistency probe；truth 限 environment / visibility requirement facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
