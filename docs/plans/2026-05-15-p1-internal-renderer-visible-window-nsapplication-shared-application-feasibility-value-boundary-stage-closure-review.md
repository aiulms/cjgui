# P1 Renderer 可见窗口 NSApplication Shared-Application Feasibility Value Boundary 阶段封账

## 阶段结果

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation` 已完成。

新增 internal runtime owner：

- [runtime_renderer_visible_window_nsapplication_shared_application_feasibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_feasibility.cj)
- [verify_renderer_visible_window_nsapplication_shared_application_feasibility_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_feasibility_owner.sh)

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`

## 新增 truth

本阶段只固定 shared application singleton access still blocked、application singleton creation still blocked、main-thread affinity required、headless / CI-like fail-closed route、bounded run loop prerequisite required、auto-close prerequisite required、teardown before visible mode required、non-user-visible mode required、activation policy mutation still blocked、application activation still blocked、event loop still blocked、native visible order still blocked、production drawable still blocked、render still blocked、no public surface、no renderer state write 与 no backend-ready truth facts。

## 未打开的能力

未调用 application singleton accessor，未创建 `NSApplication`，未 activation，未修改 activation policy，未运行 AppKit event loop，未调用 `makeKeyAndOrderFront` / `orderFront`，未调用 production `nextDrawable`，未配置 color attachment，未创建 command buffer / encoder，未 draw，未 `commit` / `present`，未提交 GPU work，未执行 render，未写 renderer state，未新增 public API / public C ABI，未修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 验证摘要

- Owner probe 先红灯：缺少 owner 时返回 exit 3。
- 新增 owner 后 owner probe 通过，确认 singleton accessor call、application creation、activation policy mutation、activation、event loop、native visible order、public API、renderer state write、backend-ready truth 均为 false。
- `cjpm build --target-dir /tmp/cjgui-shared-application-feasibility-build --skip-script` 通过；仅有既有 unused warnings。

## 下一入口

`P1 internal Renderer visible-window production harness NSApplication shared-application native guard preflight decision`

该入口仍是 preflight，不是 singleton accessor implementation。
