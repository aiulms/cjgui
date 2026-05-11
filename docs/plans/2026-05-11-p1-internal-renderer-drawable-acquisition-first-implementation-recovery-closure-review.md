# Drawable acquisition first implementation recovery 阶段复核

## 实际路线

本轮完成 A：recovery/preflight only。

新增 recovery owner 接受 `CjguiInternalRendererNoDrawableAvailabilityReadiness`，把 `nextDrawable` first implementation 的当前 blocker 脱水成 internal facts：缺少 display-backed layer 证据、缺少可见 window 证据、缺少 run loop non-blocking 证据，且 command queue / present 仍是明确 stop-line。

本轮没有进入 B/C：没有调用 `nextDrawable`，没有获取 drawable，没有创建 drawable token table，没有 present，没有 command queue / command buffer / encoder。

## 实际写集

- 新增 [runtime_renderer_drawable_acquisition_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_recovery.cj)。
- 新增 [verify_native_bridge_drawable_acquisition_recovery.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_recovery.sh)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure 文档。

本轮没有修改 production native `.h` / `.m`、`runtime/cjgui/cjpm.toml`、smoke native files 或 `runtime_state.cj`。

## 当前事实

- Canonical endpoint 固定为 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()`。
- Runtime input 是 `CjguiInternalRendererNoDrawableAvailabilityReadiness`。
- Recovery probe 在 token-backed `NSView` / `CAMetalLayer` / `MTLDevice` attach-bind-cleanup 路径上观察 drawable acquisition still blocked 与 command queue still blocked。
- Recovery probe 明确输出 `visible_window_evidence=false`、`display_backed_layer_evidence=false`、`next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。

## 验证摘要

- [verify_native_bridge_drawable_acquisition_recovery.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_recovery.sh) 已通过。
- 既有回归 probe 已通过：Metal device binding / create-destroy / availability，CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach，NSView runtime call / create-destroy / object table / feasibility / no-object creation，AppKit import / class / main-thread，teardown，token issue/revoke，no-resource call，isolated FFI，package link，cjpm package link，skeleton compile，symbol probe，cjpm boundary。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-acquisition-first-implementation-target --skip-script` 已在 `runtime/cjgui` 下通过；保留既有 unused 警告，不影响本阶段封账。
- macOS smoke auto-close 已通过。
- `git diff --check`、本阶段写集 whitespace、Markdown absolute link、reachability、中文标题正文抽查、public declaration scan、native forbidden scan、protected path scan 均已通过。
- 复核说明：一次 broad whitespace check 命中过往 `sources/` / 历史 docs 的既有空白问题，已按本阶段写集重跑通过；一次 `envsetup.sh` + `set -u` 与一次仓库根目录 `cjpm build` 属于 runner / workdir 问题，按正确环境重跑通过。

## 停止线复核

本轮没有调用 `nextDrawable`，没有 present，未创建 command queue / command buffer / encoder，未提交 GPU work，未执行 render，未写 renderer state，未触碰 `runtime_state.cj`，未返回 pointer / handle / `id` / `Class`，未新增 public API / diagnostics。

## 后续接续

本 closure 已由 [drawable environment / window visibility planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) downstream 接续。该接续只把 visible window、main-thread run loop、display backing 与 no-present acquisition cleanup 约束固定为 planning facts，不调用 `nextDrawable`，不创建 production `NSWindow`，不改变本 closure 的 recovery stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition first implementation 当前停在 recovery / blocker facts。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 recovery owner 与 recovery probe；truth 限环境 / visibility / non-blocking blocker facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
