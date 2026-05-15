# P1 内部 Renderer 可见窗口 Visible Order Native Guard 阶段封账复核

## 完成内容

本阶段完成 `P1 internal Renderer visible-window production harness visible-order native guard no-side-effect implementation`：

- 新增 runtime owner [runtime_renderer_visible_window_visible_order_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_visible_order_native_guard.cj)。
- 新增 production native bridge visible-order guard callable，只返回 deterministic integer facts。
- 新增 native guard probe [verify_native_bridge_nswindow_visible_order_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nswindow_visible_order_guard.sh)。
- 新增 runtime owner probe [verify_renderer_visible_window_visible_order_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_visible_order_native_guard_owner.sh)。
- 更新 native bridge compile / symbol / package-adjacent allowlist，使新增 callable 保持 no-side-effect surface。

当前 canonical endpoint 推进到 `CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()`，runtime input 是 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`。

## 新增事实

本阶段只固定 native guard facts：

- application ownership required
- application creation deferred
- activation deferred
- bounded run loop required
- auto-close required
- headless / CI-like fail-closed
- content-view prerequisite required
- native visible order still blocked
- production drawable still blocked
- render still blocked

## 未越过的停止线

- 未调用 `makeKeyAndOrderFront` / `orderFront` / `activateIgnoringOtherApps`。
- 未创建 `NSApplication`，未 activation，未运行 AppKit event loop。
- 未调用 production `nextDrawable`，未配置 color attachment，未创建 encoder，未 draw。
- 未 `commit` / `present`，未提交 GPU work，未执行 render。
- 未返回 pointer / handle / `id` / `Class`。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public diagnostics。

## 验证摘录

- `verify_renderer_visible_window_visible_order_native_guard_owner.sh`：通过。
- `verify_native_bridge_nswindow_visible_order_guard.sh`：通过，所有 guard facts value match，且 application / activation / order front / drawable / encoder / commit / present / pointer 均为 false。
- `CLANG_MODULE_CACHE_PATH=/tmp/cjgui-clang-module-cache verify_native_bridge_skeleton_compile.sh`：通过。未设置 writable module cache 的第一次运行失败于 sandbox 无法写 `~/.cache/clang/ModuleCache`，已按环境缓存路径问题复跑。
- `cjpm build --target-dir /tmp/cjgui-visible-order-native-guard-target --skip-script`：通过，保留既有 unused warnings。

## GitNexus 结果

GitNexus 对本阶段 planned endpoint / draft / nearby native callable 返回 not found / UNKNOWN。该结果只说明近期新增符号未索引，不作为安全证明；本阶段已用 source reading、owner probe、native probe、build 与 forbidden scan 兜底。

## 设计意图出口自检

- 新 owner 有中文维护注释，声明 owner / truth / stop-line / Same-shape Boundary Brake。
- canonical tail 从 visible-order policy endpoint 推进到 visible-order native guard endpoint。
- Same-shape Boundary Brake：没有把 native guard facts 包装成 visible-ready、drawable-ready、render-ready、backend-ready、renderer state write 或 public API。
