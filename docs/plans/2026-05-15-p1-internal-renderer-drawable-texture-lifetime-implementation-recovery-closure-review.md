# Drawable texture lifetime 实现恢复封账

## 本轮结果

本轮完成 docs-only recovery decision，选择 A：production drawable lifetime 暂停，visible-window production harness 拆为独立后续分支。

没有新增 runtime owner，没有新增 native C ABI，没有新增 probe，没有修改 `.cj`、native source、native scripts、`runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`。

## 封账理由

上一轮 production drawable texture lifetime first slice 再次停在 A 路线，说明 blocker 不在 drawable acquire / release 这一层本身，而在更上游的 display environment ownership：

- production visible-window ownership 尚未定义。
- bounded production run loop 尚未定义。
- display-backed layer 与 token-backed `CAMetalLayer` / `NSView` / `MTLDevice` 的共同所有权尚未定义。
- cleanup order 与 headless / CI-like fallback 尚未定义。

在这些前置 owner 未定义前，新增 production drawable token table 会把环境问题伪装成 resource lifecycle 问题。

## 当前保留证据

保留以下事实作为后续 preflight 输入：

- isolated visible-window probe 可以构造临时可见窗口环境。
- isolated no-present probe 可以观察 no-present `nextDrawable`。
- no-submit milestone 已证明 pipeline descriptor、shader library / function、pipeline state、vertex buffer 与 draw input bundle facts。
- render pass descriptor color attachment 仍等待 production drawable texture lifetime。
- render command encoder 仍等待合法 color attachment descriptor。

这些证据都不是 production runtime truth。

## 本轮同步

本轮需要把新的唯一 next opening 同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

并补齐 first slice、visible-window probe、no-submit milestone 与 color attachment recovery 的 downstream 指向。

## 停止线复核

本轮继续禁止：

- production `nextDrawable`
- production drawable acquire / classify / release
- render pass descriptor color attachment
- command buffer / render command encoder creation
- `commit` / `present`
- GPU submission
- render execution
- renderer state write
- public API / diagnostics
- pointer / handle / `id` / `Class` return

## 设计意图出口自检

- 本轮是否改变主题状态：是。drawable lifetime recovery 进入 visible-window production harness 分支准备状态。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 runtime owner 或 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 明确 isolated evidence 不可升格；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是。唯一后续入口是 `P1 internal Renderer visible-window production harness preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：计划同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md` 与 `macos-bridge-verification-smoke.md`。
