# P1 Renderer 可见窗口 Visible Order Policy Value Boundary Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness visible-order policy value boundary bundle implementation`。阶段完成后，runtime 内部新增 visible-order policy readiness，但没有打开 native visible order implementation。

## 新增或更新的 owner

- Runtime owner：`CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- Probe：`verify_renderer_visible_window_visible_order_policy_owner.sh`

## 事实边界

只承认 application ownership still policy-only、application creation deferred、activation deferred、bounded run loop required、auto-close required、headless / CI-like fail-closed route retained、content-view cleanup co-ownership retained、native visible order implementation absent、production drawable permission absent 与 backend-ready truth absent。

## 停止线

不修改 native bridge；不新增 C ABI；不做 native visible order implementation；不创建 application side effect；不获取 drawable；不创建 command buffer / encoder；不 draw；不提交 GPU work；不执行 render；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`
- Current：`CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness visible-order native implementation preflight decision`

## report-6 blocker 状态

report-6 blocker 已由用户人工复核解除：Metal-capable local shell 中 `verify_auto_close.sh` 通过。后续自动化环境若单独出现 `default Metal device is unavailable`，应记录为 smoke environment unavailable，而不是代码回归。

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
