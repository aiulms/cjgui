# Drawable 环境与窗口可见性规划复核

## 实际路线

本轮完成 A：environment / window visibility planning value boundary。

新增 owner 接受 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`，把 `nextDrawable` 前置环境脱水成 internal facts：需要可见 window、main-thread bounded run loop、display-backed `CAMetalLayer`、token-backed layer/device 绑定、no-present acquisition cleanup 与后续 isolated probe 证据。

本轮没有进入 B/C：没有创建 isolated `NSWindow`，没有调用 `nextDrawable`，没有获取 drawable，没有 present，没有 command queue / command buffer / encoder。

## 实际写集

- 新增 [runtime_renderer_drawable_environment_visibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_environment_visibility.cj)。
- 新增 [verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure 文档。

本轮没有修改 production native `.h` / `.m`、`runtime/cjgui/cjpm.toml`、smoke native files 或 `runtime_state.cj`。

## 当前事实

- Canonical endpoint 固定为 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`。
- Runtime input 是 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`。
- Planning probe 明确输出 `isolated_visible_window_probe_executed=false`、`production_window_created=false`、`next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。
- 本阶段只说明后续必须先证明可见窗口、display-backed layer、bounded run loop 与 no-present cleanup；不是 production runtime truth。

## 验证摘要

- [verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh) 已通过，并观察 `drawable_environment_visibility_probe=passed`、`isolated_visible_window_probe_executed=false`、`production_window_created=false`、`next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。
- 全量回归 probe 已通过：drawable recovery / planning、Metal device binding、CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach、NSView runtime call / create-destroy / object table / feasibility / no-object creation、AppKit import / class / main-thread、teardown、token issue/revoke、no-resource call、isolated FFI、package link、cjpm package link、skeleton compile、symbol probe、cjpm boundary。
- `verify_native_bridge_cjpm_integration_boundary.sh` 在未 source 工具链的 shell 中先提示 `cjpm not found`；按任务要求 source `/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 后重跑通过。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-environment-window-visibility-target --skip-script` 已在 `runtime/cjgui` 下通过；保留既有 unused warnings，不影响本阶段封账。
- macOS smoke auto-close 已通过。
- `git diff --check`、本阶段写集 whitespace、Markdown absolute link、reachability、中文标题正文抽查、public declaration scan、native forbidden scan、protected path scan 与 owner / script header stop-line scan 均已通过。
- 复核说明：一次 broad docs whitespace check 命中过往 2026-04 历史 docs 的既有 trailing whitespace，已按本阶段变更写集重跑通过，未修改历史无关文档。

## 停止线复核

本轮没有调用 `nextDrawable`，没有 present，未创建 command queue / command buffer / encoder，未提交 GPU work，未执行 render，未写 renderer state，未触碰 `runtime_state.cj`，未返回 pointer / handle / `id` / `Class`，未新增 public API / diagnostics。

## 风险记录

GitNexus impact 对上游 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness` 与 `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft` 返回近期新增 symbol 未索引 / not found，risk 记录为 UNKNOWN，affected count 为 0。本轮以源码读取、`cjpm build`、probe 与 forbidden scan 兜底。GitNexus `detect_changes(scope=unstaged)` 返回 `risk=low`、`affected_processes=0`，覆盖当前未暂存工作树的 35 个文件 / 21 个 symbols。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition first implementation 从 recovery 进入 environment / window visibility planning。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner 与 planning consistency probe；truth 限环境前置需求 facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
