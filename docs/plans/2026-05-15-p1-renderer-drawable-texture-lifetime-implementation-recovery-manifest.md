# 可绘制纹理生命周期实现恢复清单

## 清单状态

状态：docs-only / recovery decision / visible-window harness split

本清单固定 production drawable texture lifetime first slice 再次停止后的恢复结论：不继续硬推 drawable acquire / classify / release，而是把 visible-window production harness 拆为独立后续分支。

2026-06-21 复核补记：本轮重新核对 first-slice manifest / closure / next-boundary、visible-window probe、drawable no-present acquisition、no-submit branch milestone、color attachment recovery、Metal device binding 与 `CAMetalLayer` runtime attachment manifests 后，清单状态不变。当前仍不新增 runtime owner、production native C ABI、probe 或 package route；唯一后续入口继续固定为 `P1 internal Renderer visible-window production harness preflight decision`。

## 路线选择

选择 A：

`recovery decision only：确认 production drawable lifetime 暂停，开 visible-window production harness 分支。`

拒绝 B：主线不停止等待用户方向，因为证据已经足够说明下一块最小缺口是 visible-window harness。

拒绝 C：现有证据仍不足以直接打开 visible-window production harness implementation preflight；必须先做 harness preflight。

拒绝 D：证据没有冲突。isolated probe、no-submit milestone 与 color attachment recovery 的角色一致。

## 当前 canonical tail

本轮未新增 endpoint。

当前可引用 tail：

- Drawable lifetime planning tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- No-submit milestone tail：`CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`

上一轮建议的 `CjguiInternalRendererNoDrawableTextureLifetimeFirstSlicePlanningReadiness` 未创建，因此不是 canonical tail。

## 上游证据

- [production drawable texture lifetime first slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)
- [drawable visible-window probe manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [drawable no-present acquisition manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- [no-submit render pipeline branch milestone manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- [render pass descriptor color attachment recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)

## 固定 blocker

Production drawable texture lifetime 仍缺：

- production visible `NSWindow` ownership。
- bounded production run loop。
- display-backed layer ownership。
- production cleanup order。
- drawable token table。
- acquire / classify / release lifecycle。
- released / stale / double release fail-closed classification。
- descriptor / drawable / layer / device / view cleanup co-ownership。

## visible-window harness 分支职责

下一分支必须只回答 harness 是否可以进入 production runtime：

- 是否允许 production runtime 拥有 visible-window harness。
- 是否必须创建 `NSWindow`，以及是否保持 internal-only。
- bounded run loop 如何定义。
- display-backed `CAMetalLayer` 如何与 token-backed `NSView` / `CAMetalLayer` / `MTLDevice` 对齐。
- cleanup 如何证明窗口、view、layer、device、drawable 相关状态归零。
- headless / CI-like shell 中如何 fail-closed。
- 是否仍不写 renderer state、不扩 public API、不 present、不 commit、不 render。

## 本轮未打开事项

本清单不是 runtime truth，也不授予 production drawable acquisition、color attachment、encoder、present、render、GPU submission、renderer state write、backend-ready truth 或 public API 权限。Isolated visible-window probe 只保留为 feasibility evidence，不得被解释为 production runtime ownership。

CodeLattice 本轮可调用但仅给出 static-only / low-confidence 项目级证据；`runtime/cjgui` compact explore 未执行 runtime、build 或 probe，也未形成可替代 source reading 的 symbol proof。后续若进入 visible-window production harness，应继续用 source reading、focused probes、bounded cleanup evidence、protected path scan 与 GitNexus detect-changes 兜底。

- 未打开 production drawable acquire / classify / release。
- 未打开 render pass descriptor color attachment。
- 未打开 render command encoder creation。
- 未打开 command buffer / encoder / draw。
- 未打开 `commit` / `present`。
- 未打开 GPU submission。
- 未打开 renderer state write。
- 未打开 public API / diagnostics。

## 唯一后续入口

`P1 internal Renderer visible-window production harness preflight decision`

## 封账复核

- [Drawable texture lifetime 实现恢复封账复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-drawable-texture-lifetime-implementation-recovery-closure-review.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是。drawable lifetime recovery 明确拆出 visible-window production harness 分支。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 固定 isolated probe 仅为 feasibility evidence；stop-line 继续禁止 production `nextDrawable` 与 color attachment。
- 本轮是否改变唯一 next opening：是。唯一后续入口转为 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。
