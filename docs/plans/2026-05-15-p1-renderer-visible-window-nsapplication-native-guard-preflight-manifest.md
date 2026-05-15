# P1 Renderer 可见窗口 NSApplication Native Guard 预检 Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication native guard preflight decision`。阶段完成后，Renderer 主线允许进入 no-side-effect native guard implementation，但仍没有打开 `NSApplication` creation、activation、event loop 或 native visible order implementation。

## 当前 canonical endpoint

- Upstream：`CjguiInternalRendererVisibleWindowApplicationActivationPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowApplicationActivationPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness`

## 预检结论

允许下一刀新增 internal runtime owner、internal native C ABI guard callables、native probe 与 runtime owner probe。所有新增 callable 只能返回 deterministic integer facts，并且必须保持 no-side-effect。

## 停止线

不调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution；不创建 `NSApplication`；不 activation；不运行 AppKit event loop；不返回 pointer / handle / `id` / `Class`；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下游

Downstream next opening：

`P1 internal Renderer visible-window production harness NSApplication native guard no-side-effect implementation`

## GitNexus 结果

GitNexus 对近期新增 endpoint、default draft 与 visible-order native guard callables 返回 not found / UNKNOWN；该结果不作为安全证明。implementation 必须用源码读取、build、probe、forbidden scan、protected path scan、public declaration scan 与 manifest reachability 兜底。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical endpoint 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
