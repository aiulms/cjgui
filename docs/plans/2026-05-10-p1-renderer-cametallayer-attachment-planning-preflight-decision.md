# P1 渲染器 CAMetalLayer attachment planning 预检结论

日期：2026-05-10

状态：preflight / 选择 no-attach value boundary

## 预检结论

本轮选择 A：`P1 internal Renderer CAMetalLayer attachment planning value boundary bundle`。

当前 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` 已经封账，足够进入 `CAMetalLayer` attachment planning 的 no-attach value boundary；但不足以创建 `CAMetalLayer`、导入 QuartzCore、绑定 `NSView.layer`、设置 `wantsLayer`、创建 `MTLDevice` 或进入 render / GPU submission。

本轮不新增 production native C ABI，不修改 `runtime/cjgui/native/cjgui_native_bridge.h` / `.m`，不新增 no-attach probe，不修改 `runtime/cjgui/cjpm.toml`。`CAMetalLayer` class availability 可作为后续入口，但必须单独 preflight 后才允许 import QuartzCore 或新增 no-attach class lookup callable。

## 判断记录

- 是否允许 import QuartzCore：本轮不允许；只记录后续 import admission policy。
- 是否只允许 class availability / no-attach facts：是，本轮只做 value facts，class lookup callable 暂缓。
- 是否允许创建 `CAMetalLayer`：不允许。
- 是否允许 attach 到 `NSView.layer`：不允许。
- 是否需要 `wantsLayer`：如果需要，必须停止；本轮明确不设置。
- 是否需要 `MTLDevice`：如果需要，必须停止；本轮明确不创建或查询。
- main-thread gate 是否足够：足够作为 planning guard，不足以授权 attachment。
- teardown / detach / token invalidation 是否足够：足够表达 detach-before-destroy dependency，不足以执行 attach / detach。

## GitNexus 影响记录

- `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness`：impact 返回 not found / `UNKNOWN` / impacted count `0`。
- `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft`：impact 返回 not found / `UNKNOWN` / impacted count `0`。

该结果按近期新增 owner 尚未索引处理。本轮采用源码阅读、`cjpm build`、probe 矩阵、public declaration scan、native forbidden scan、protected path scan 与 GitNexus detect changes 兜底。

## 批准写集

- 新增 `runtime/cjgui/src/runtime_renderer_cametallayer_attachment_planning.cj`。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。
- 给上游 `NSView` backend shell integration、real Metal device-layer shell、native teardown 与 token issue/revoke 相关文档补 downstream 指向。

不批准：

- production native bridge 修改。
- `runtime/cjgui/cjpm.toml` 修改。
- smoke native files 修改。
- `runtime_state.cj` 修改。
- public API / diagnostics。

## 设计意图出口自检

- 本轮是否改变主题状态：是，打开 `CAMetalLayer` attachment planning no-attach value boundary。
- 本轮是否改变 canonical tail / endpoint：预检批准新增 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，预检批准新增 planning owner；truth 仅限 no-attach planning facts；stop-line 禁止 QuartzCore import、layer creation、attachment、Metal device、drawable、state write、public API。
- 本轮是否改变唯一 next opening：预检阶段选择完成后应转入阶段实现与封账。
- 是否同步 topic manifest：将在 closure / manifest 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

