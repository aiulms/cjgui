# Production drawable texture lifetime 预检结论

日期：2026-05-11

## 读取范围

- 上游 recovery owner：[runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_descriptor_color_attachment_recovery.cj)
- 上游 recovery manifest：[渲染通道描述符颜色附件恢复清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)
- Drawable no-present acquisition manifest：[Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- Drawable visible-window manifest：[Drawable visible-window acquisition probe 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- Drawable environment manifest：[Drawable environment / window visibility 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md)
- Metal device binding manifest：[Metal device binding runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- CAMetalLayer runtime attachment manifest：[CAMetalLayer runtime attachment FFI call owner 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)
- Command buffer runtime manifest：[Command buffer creation runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-buffer-creation-runway-manifest.md)
- Native bridge：[cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h) 与 [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

## 路线选择

本阶段选择 A：production drawable texture lifetime planning / ownership facts。

不进入 B / C：

- 不新增 production drawable acquire / classify / release C ABI。
- 不在 production bridge 调用 `nextDrawable`。
- 不新增 drawable token table。
- 不新增 runtime FFI call owner。
- 不配置 render pass descriptor color attachment。

## 关键判断

- 当前 `nextDrawable` 证据来自 isolated visible-window probe，不能作为 production runtime truth。
- Production runtime 尚无 window visibility / run loop / display backing 语义。
- Production runtime 尚无 drawable token-local acquire / classify / release 生命周期。
- Production runtime 尚无 drawable / layer / device / descriptor cleanup 共同所有权。
- 因此 color attachment first slice 仍需要 production drawable texture lifetime implementation recovery。

## GitNexus 记录

- `CjguiInternalRendererNoRenderPassDescriptorColorAttachmentRecoveryReadiness` impact：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererRenderPassDescriptorColorAttachmentRecoveryDraft` impact：当前索引返回 `UNKNOWN` / not found / impactedCount `0`。
- 未出现 HIGH / CRITICAL 风险输出。
- 本轮以源码阅读、`cjpm build`、planning probe、native forbidden scan 与 GitNexus detect 兜底。

## 停止线

不 present，不调用 `presentDrawable` / `present`，不创建 command buffer / encoder，不调用 `commit`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 drawable texture lifetime planning facts 解释成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 color attachment recovery blocker 进入 production drawable texture lifetime planning facts。
- 本轮是否改变 canonical tail / endpoint：是，预检选择新增 planning endpoint `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner；truth 只说明 production drawable texture lifetime 尚缺，不说明 drawable 可稳定获取。
- 本轮是否改变唯一 next opening：是，若路线 A 完成，唯一 next opening 固定为 `P1 internal Renderer drawable texture lifetime implementation recovery decision`。
- 是否同步 topic manifest：待本阶段封账同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

