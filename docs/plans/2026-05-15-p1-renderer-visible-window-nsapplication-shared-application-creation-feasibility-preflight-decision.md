# P1 Renderer 可见窗口 NSApplication Shared-Application Creation Feasibility 预检决策

## 预检入口

当前入口来自 `NSApplication` creation / activation scope value boundary：

- 上游 endpoint：`CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`
- 上游 default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationCreationActivationScopeDraft()`
- 当前 opening：`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility preflight decision`

本预检只判断是否可以从 scope facts 靠近 `NSApplication.sharedApplication` creation feasibility；它不是 implementation approval。

## 决策

选择 A：不直接调用 `sharedApplication`，先落一个 internal value-style shared-application creation feasibility owner。

理由：

- `NSApplication.sharedApplication` 在 AppKit 语义上可能创建或返回 process singleton，不能被当成 no-side-effect probe。
- 当前只具备 creation / activation scope value facts，尚未固定 shared application singleton access policy、main-thread affinity、headless / CI-like fail-closed、bounded run loop、auto-close prerequisite、teardown / non-user-visible mode 与 no-activation proof。
- 任何真实 `sharedApplication` call 都可能被误读为 `NSApplication` creation permission、activation permission、event loop permission 或 visible-order permission。
- report-6 的 Metal-capable smoke 人工复核只解除自动化环境误判，不授权 production runtime 调用 AppKit singleton。

## 本阶段允许

- 新增 internal runtime owner，默认文件名为 `runtime_renderer_visible_window_nsapplication_shared_application_feasibility.cj`。
- 该 owner 只消费 `CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`。
- 该 owner 只能固定 shared application singleton access still blocked、`sharedApplication` call still blocked、main-thread affinity required、headless / CI-like fail-closed、bounded run loop prerequisite required、auto-close prerequisite required、teardown / non-user-visible mode prerequisite required、activation / activation policy / event loop still blocked、native visible order / drawable / render still blocked 等 value facts。
- 可新增 owner probe，验证 owner symbols、上游输入、stop-line 和 no public surface。

## 本阶段禁止

- 不调用 `NSApplication.sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation。
- 不修改 activation policy。
- 不运行 AppKit event loop。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不配置 color attachment。
- 不创建 render encoder。
- 不 draw。
- 不 `commit` / `present`。
- 不提交 GPU work。
- 不写 renderer state。
- 不新增 public API / public C ABI / diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml` 或 `runtime/cjgui/src/runtime_state.cj`。

## 下一段边界

本预检之后允许进入：

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation`

该下一段仍不是 `sharedApplication` implementation。Same-shape Boundary Brake：不得把 feasibility owner 包成 application-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。
