# P1 内部 Renderer 可见窗口 Visible Order Policy Value Boundary 阶段封账复核

## 完成内容

本阶段完成 visible-order policy value boundary implementation：

- 新增 [runtime_renderer_visible_window_visible_order_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_visible_order_policy.cj)。
- 新增 runtime probe [verify_renderer_visible_window_visible_order_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_visible_order_policy_owner.sh)，先红后绿验证 owner 存在、上游输入、policy facts 与停止线。
- 当前 canonical endpoint 推进到 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`。
- 该 owner 只消费 `CjguiInternalRendererVisibleWindowContentViewAttachmentReadiness`，固定 application ownership policy、application creation deferred、activation deferred、bounded run loop requirement、auto-close requirement、headless / CI-like fail-closed route、content-view cleanup co-ownership、no drawable permission 与 no backend-ready truth。

## 未越过的停止线

- 未修改 production native bridge。
- 未新增 native C ABI。
- 未做 native visible order implementation。
- 未创建 application side effect。
- 未获取 drawable，未创建 render encoder，未 draw。
- 未提交 GPU work，未执行 render。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public diagnostics。
- 未返回 pointer / handle / `id` / `Class`。

## 验证摘录

- `verify_renderer_visible_window_visible_order_policy_owner.sh`：implementation 前红测失败于 missing owner；implementation 后通过。
- `cjpm build --target-dir /tmp/cjgui-visible-order-policy-target --skip-script`：通过，保留既有 unused warnings。

## report-6 blocker 解除说明

report-6 中的 `verify_auto_close.sh` blocker 已由用户人工复核解除。用户在同一工作区、Metal-capable 本地 shell 中执行 `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 后运行 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，包含 `metal device ok`、`first frame rendered`、`metal readback: success=true degraded=none` 与 `auto-close log assertions passed`。因此本阶段不再把 report-6 作为阻塞条件；若自动化环境再次出现 `default Metal device is unavailable`，按 smoke environment unavailable 分类。

## 设计意图出口自检

- 新 owner 有中文维护注释，声明 owner / truth / stop-line / Same-shape Boundary Brake。
- canonical tail 从 content-view attachment endpoint 推进到 visible-order policy endpoint。
- stop-line 与用户硬约束一致。
- Same-shape Boundary Brake：没有把 policy facts 包装成 visible-ready、drawable-ready、render-ready、backend-ready、renderer state write 或 public API。
