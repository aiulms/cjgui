# P1 Renderer 可见窗口 Visible Order Native Implementation Preflight Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness visible-order native implementation preflight decision`。阶段结论是 direct native visible order implementation 仍 blocked；下一步只允许 no-side-effect native guard first slice。

## 当前 canonical endpoint

- Runtime endpoint：`CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`

## 事实边界

只承认 visible-order policy endpoint 已足够作为 native guard preflight 的上游；不承认 native visible order、application creation、activation、production drawable、color attachment、encoder、draw、GPU submission、render、renderer state write、backend-ready truth 或 public API permission。

## 停止线

不调用 `makeKeyAndOrderFront` / `orderFront` / `activateIgnoringOtherApps`；不创建 `NSApplication`；不运行 AppKit event loop；不调用 production `nextDrawable`；不创建 command buffer / encoder；不 draw；不 `commit` / `present`；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：visible-order policy value boundary manifest。
- Current：visible-order native implementation preflight manifest。
- Downstream next opening：`P1 internal Renderer visible-window production harness visible-order native guard no-side-effect implementation`

## GitNexus 结果

GitNexus impact / context 对本阶段近期与 planned symbols 返回 not found / UNKNOWN。该结果不作为安全证明，后续 implementation 必须以源码读取、build、probe、forbidden scan 与 manifest check 兜底。

## 设计意图出口自检

- manifest 已固定 direct visible order blocked 与 no-side-effect native guard next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
