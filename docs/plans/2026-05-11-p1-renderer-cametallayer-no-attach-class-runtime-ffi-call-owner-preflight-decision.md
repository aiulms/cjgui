# P1 渲染器 CAMetalLayer no-attach 类可见性与 runtime 调用预检

日期：2026-05-11

状态：preflight / 选择 no-attach class/runtime FFI call owner

## 预检结论

本轮选择 A：

`P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner`

选择理由：

- 上游 `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness` 已封账，明确下一步只能评估 QuartzCore import、`CAMetalLayer` class availability 与 no-attach runtime internal facts。
- 生产 bridge 已具备 AppKit no-object、`NSView` token-backed lifecycle、teardown admission 与 main-thread gate evidence，足够进入 no-attach class lookup。
- 本阶段允许 `#import <QuartzCore/QuartzCore.h>`，但只允许 static availability / class lookup facts，不允许创建 `CAMetalLayer` / `CALayer`。
- package link 与 runtime internal FFI call 路线已有 `NSView` runtime call owner 证据，可支撑只返回 `Int32` 的 no-attach callable。

## 允许写集

- 修改 `runtime/cjgui/native/cjgui_native_bridge.h` 与 `runtime/cjgui/native/cjgui_native_bridge.m`，仅新增 QuartzCore import boundary 与 no-attach `CAMetalLayer` class availability / blocked facts。
- 新增 `runtime/cjgui/src/runtime_renderer_cametallayer_no_attach_call.cj`。
- 新增 `runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_no_attach.sh`。
- 更新已有 native probe allowlist / link flags，使 QuartzCore class lookup 可验证，同时继续禁止 Metal、layer allocation 与 attachment。
- 新增本阶段文档、closure、manifest 与索引同步。

## 拒绝路线

- 不进入 B：不做 `CAMetalLayer` allocation without attachment。
- 不进入 C：不做 token-backed `CAMetalLayer` table。
- 不进入 D：不把 `CAMetalLayer` attach 到 token-backed `NSView`。
- 不 import Metal，不创建 `MTLDevice`、command queue、drawable 或 command buffer。
- 不设置 `NSView.layer`，不设置 `wantsLayer`。
- 不返回 pointer / handle / `id` / `Class`。
- 不新增 public API / diagnostics。
- 不写 renderer state，不触碰 `runtime_state.cj`。

## GitNexus 预检

已对上游 endpoint 与 default draft 执行 impact：

- `CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`
- `cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentDraft`

两者在当前 GitNexus index 中均为 not found / UNKNOWN，`impactedCount=0`。按近期新增 owner 未索引处理，本轮用源码读取、`cjpm build`、native probe、public scan、forbidden scan 与 `detect_changes` 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，允许从 no-attach planning 进入 QuartzCore import / `CAMetalLayer` class lookup / runtime internal FFI call owner。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_cametallayer_no_attach_call.cj`；truth 仅限 no-attach observed facts；stop-line 继续禁止 layer allocation / attachment、Metal、drawable、GPU submission、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：若 A 成功，转为 `P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：待 manifest stabilization 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
