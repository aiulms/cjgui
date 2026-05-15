# P1 内部 Renderer 可见窗口 Visible Order Native Implementation Preflight Manifest 稳定化封账复核

## 完成内容

本阶段将 visible-order native implementation preflight 稳定为 docs-only manifest：

- 维持 current endpoint 为 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`。
- 明确 direct native visible order implementation 仍 blocked。
- 将唯一 next opening 收束为 no-side-effect native guard implementation。

## 未越过的停止线

未新增 runtime owner、native C ABI、probe、build config 或 public API。未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、真实 visible order、drawable、encoder、draw、GPU submission、render 或 renderer state write。

## 下一 opening

`P1 internal Renderer visible-window production harness visible-order native guard no-side-effect implementation`

## 设计意图出口自检

- 本 manifest 是 preflight 稳定化文档，不是 runtime truth。
- 下一段仍必须先通过 no-side-effect guard probe，再考虑任何 application creation / activation scope unlock。
