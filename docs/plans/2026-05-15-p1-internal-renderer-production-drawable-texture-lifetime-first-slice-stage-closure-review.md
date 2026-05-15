# 生产 drawable texture lifetime 第一切片阶段封账

## 本轮结果

本轮完成 A 路线：first-slice preflight / blocker refresh。

没有进入 production drawable acquire / classify / release implementation。没有新增 C ABI、runtime owner、probe 或 package link route。生产桥仍不调用 `nextDrawable`，也不创建 visible `NSWindow` harness。

## 为什么停止在 A

no-submit branch milestone 的价值已经成立：pipeline descriptor、shader library / function、pipeline state、vertex buffer 与 draw input bundle 已经为未来 encoder / draw 提供 no-submit 输入合同。

但 display 链的最小缺口没有消失。production drawable lifetime 需要 display-backed `CAMetalLayer` 和可证明的 cleanup co-ownership。现有 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness` 只证明 isolated visible-window probe evidence；它不拥有 production runtime window semantics。

如果本轮强行实现 B/C，就会把 isolated window probe 的环境事实伪装成 production runtime truth。这正是本阶段需要避免的形状漂移。

## GitNexus impact 结果

对上游 endpoint / default draft 执行 impact：

```text
impact CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness --repo cangjie-live-codelattice
结果：UNKNOWN / target not found / impactedCount 0
```

```text
impact cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft --repo cangjie-live-codelattice
结果：UNKNOWN / target not found / impactedCount 0
```

该结果不当作安全证明。本轮按源码阅读、上游 manifest、native source stop-line 与 docs-only 扫描兜底。

## 本轮未修改范围

- 未修改 [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)。
- 未修改 [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)。
- 未新增 `runtime_renderer_drawable_texture_lifetime.cj`。
- 未新增 `runtime_renderer_drawable_texture_lifetime_runtime_call.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 `labs/macos_bridge_smoke` native files。

## 当前固定事实

- isolated visible-window / no-present drawable acquisition 是 probe evidence，不是 production runtime truth。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` facts 不能证明 layer display-backed。
- production drawable acquire / release 需要可见窗口 ownership、bounded run loop、drawable table、release cleanup 与 stale / double release classification。
- render pass descriptor color attachment 仍需等待 production drawable texture lifetime。
- no-submit branch 不再继续新增同构 wrappers；display 链回到 drawable lifetime recovery。

## 当时唯一后续入口

`P1 internal Renderer drawable texture lifetime implementation recovery decision`

## 下游已接续

已由 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer visible-window production harness preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。production drawable first slice 由尝试 implementation 转为 recovery / blocker refresh。
- 本轮是否改变 canonical tail / endpoint：否。无新增 runtime owner；旧 drawable lifetime planning endpoint 与 no-submit milestone endpoint 都保持。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加 first-slice blocked 结论；stop-line 明确 production `nextDrawable` 仍禁止。
- 本轮是否改变唯一 next opening：是，当时转为 drawable texture lifetime implementation recovery decision；后续已由 recovery decision 接续并转为 visible-window production harness preflight decision。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
