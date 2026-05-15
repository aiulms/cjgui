# Renderer visible-window production harness 预检清单

## 清单状态

状态：docs-only / preflight / value boundary approved

本清单固定 visible-window production harness 预检结论：可以打开 harness 分支，但下一步只能先做 internal value-style policy boundary，不得直接进入 production native visible-window harness implementation。

## 路线选择

选择 A：

`visible-window production harness policy value boundary bundle implementation`

该路线允许下一轮新增 internal owner，默认候选为 `runtime/cjgui/src/runtime_renderer_visible_window_production_harness.cj`。该 owner 只表达 policy / prerequisite / cleanup / fail-closed value facts，不创建 native object、不调用 native bridge、不新增 C ABI。

拒绝直接 native implementation，拒绝直接 production drawable acquire / release，拒绝继续堆叠 no-submit wrapper。

## 当前 canonical tail

本轮未新增 endpoint。

当前可引用 tail：

- Drawable lifetime planning tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- No-submit milestone tail：`CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`

## 上游证据

- [Drawable texture lifetime 实现恢复清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md)
- [生产 drawable texture lifetime 第一切片清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)
- [No-submit 渲染管线分支里程碑清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- [Drawable 可见窗口 probe 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [渲染通道描述符颜色附件恢复清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)

## 下一阶段职责

下一阶段必须只回答：

- production visible `NSWindow` ownership policy。
- bounded run loop policy。
- display-backed `CAMetalLayer` prerequisite。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy。
- cleanup co-ownership policy。
- headless / CI-like shell fail-closed policy。
- no-drawable-acquire readiness。

## 当前未打开事项

- 未打开 production `NSWindow` creation。
- 未打开 production `nextDrawable`。
- 未打开 production drawable acquire / classify / release。
- 未打开 color attachment。
- 未打开 render command encoder creation。
- 未打开 pipeline / vertex buffer binding。
- 未打开 draw / `commit` / `present`。
- 未打开 GPU submission / render / renderer state write。
- 未打开 public API / public diagnostics。

## 唯一后续入口

`P1 internal Renderer visible-window production harness policy value boundary bundle implementation`

## 设计意图出口自检

- 本轮是否改变主题状态：是。visible-window production harness 已从 recovery 后续入口转为预检通过的 policy value boundary。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 固定下一阶段职责；stop-line 继续禁止 production `nextDrawable` 与 render chain。
- 本轮是否改变唯一 next opening：是。唯一后续入口转为 `P1 internal Renderer visible-window production harness policy value boundary bundle implementation`。
- 是否同步 topic manifest：需要同步。
