# 生产 drawable texture lifetime 第一切片预检裁定

## 本轮裁定

本轮选择 A：`production drawable lifetime first-slice preflight / blocker refresh`。

不进入 B/C。本轮不新增 production drawable acquire / classify / release C ABI，不新增 drawable token table，不新增 runtime internal FFI call owner，也不调用 production `nextDrawable`。

原因很窄：上一段 no-submit milestone 已经证明 pipeline descriptor、shader library / function、pipeline state、vertex buffer 与 draw input bundle facts 足够，但它们只覆盖 no-submit 输入合同；它们不能替代 display-backed layer、visible `NSWindow` ownership、bounded production run loop、drawable release / stale / double-release classification，或 descriptor / drawable / layer / device cleanup 共同所有权。

## 证据读取

本轮读取并对齐了以下上游证据：

- [no-submit render pipeline branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- [no-submit render pipeline branch reconciliation closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-no-submit-render-pipeline-branch-reconciliation-closure-review.md)
- [production drawable texture lifetime manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)
- [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [drawable visible-window acquisition probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [Metal device binding runway manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- [production native bridge header](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [production native bridge source](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## runtime input 取舍

本轮不新增 owner，因此不选择新的 runtime input。

旧 planning tail 仍是 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`，用于表达 production drawable lifetime 前置缺口。

`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness` 与 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness` 只能作为 isolated evidence：它们证明隔离 probe 可以创建可见窗口环境，并可在 bounded path 下做 no-present `nextDrawable` acquisition；它们不证明 production runtime 已拥有 visible-window harness、display backing、run loop ownership 或 drawable cleanup co-ownership。因此本轮不能把它们作为 production first-slice owner 的直接 input。

## blocker 刷新

production drawable texture lifetime 第一切片仍缺以下证据：

- production visible `NSWindow` ownership 或等价 harness 尚未建立。
- production bounded run loop / display-backing 语义尚未建立。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` 已存在，但 production path 不能证明 layer 已 display-backed。
- drawable token table 尚未建立。
- acquire / classify / release / stale / double release fail-closed 语义尚未证明。
- `nextDrawable` cleanup 后 drawable / layer / device / view 状态归零的 production co-ownership 尚未证明。
- render pass descriptor color attachment 仍没有 production drawable texture lifetime 作为输入。

## 被拒绝的路线

B 路线被拒绝：当前若在 production bridge 内新增 drawable acquire / release callable，要么直接在非 display-backed layer 上调用 `nextDrawable`，要么引入 production visible window semantics。前者不稳定，后者是单独 harness 设计问题，不能混入 drawable lifetime first slice。

C 路线被拒绝：runtime internal FFI call owner 必须消费稳定 production C ABI。当前没有 production drawable token table，也没有 release / stale / double release 语义，因此不能新增 runtime owner。

## 本轮 stop-line

- 不新增 production drawable C ABI。
- 不新增 runtime owner。
- 不调用 production `nextDrawable`。
- 不 present。
- 不创建 command buffer / encoder。
- 不调用 `commit`。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不返回 pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是。production drawable texture lifetime first slice 由 no-submit milestone 后的 next opening 转为 blocker refresh / recovery。
- 本轮是否改变 canonical tail / endpoint：否。未新增 owner，`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` 仍是 drawable lifetime planning tail；no-submit milestone tail 仍是 `CjguiInternalRendererNoDrawInputBundleReadiness`。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加“first slice 仍 blocked，isolated no-present evidence 不能升格 production lifetime”的文档事实；stop-line 继续禁止 production `nextDrawable`。
- 本轮是否改变唯一 next opening：是。下一步转为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：计划同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。

