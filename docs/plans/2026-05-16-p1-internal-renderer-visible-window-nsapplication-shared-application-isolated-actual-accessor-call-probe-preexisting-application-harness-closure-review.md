# P1 Renderer 可见窗口 NSApplication Shared-Application Preexisting Harness Closure Review

状态：closure review / docs-only / blocker confirmed

## Closure 结论

Preexisting-application harness decision 可以封账。当前 workspace 没有符合 stop-line
的同进程 preexisting `NSApplication` singleton harness；继续观察 non-null accessor
result 需要人工提供外部 harness 或明确批准 throwaway isolated creation probe。

## 本轮完成

- 完成 preexisting-application harness decision：
  [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-isolated-actual-accessor-call-probe-preexisting-application-harness-decision.md)。
- 保持 current canonical endpoint / default draft / runtime input 不变。
- 确认 `labs/macos_bridge_smoke` 不是可直接复用的 no-create preexisting singleton
  harness，因为它包含 `sharedApplication`、activation policy mutation、activation、
  visible order 与 AppKit run loop 行为。
- 确认 production runtime / native bridge 未新增 `sharedApplication` call site、
  `NSApplication` creation、activation、event loop、visible order、drawable、render、
  public C ABI 或 renderer state write。

## 未新增内容

本 closure 未新增 runtime owner、native probe、production C ABI、public API、
runtime state write 或 `cjpm.toml` change。原因是本阶段的真实结论是 harness
缺口，不是 implementable production slice。

## Stop-line

Stop-line 保持：

- actual accessor call site 仍只存在于 isolated native probe。
- probe 只有在 preexisting `NSApplication` singleton 已存在时才允许调用 accessor。
- 当前 automation 环境没有 preexisting singleton。
- 不创建 `NSApplication`。
- 不 activation。
- 不修改 activation policy。
- 不运行 AppKit event loop / bounded pump。
- 不 visible order、drawable 或 render。
- 不写 artifact / diagnostics publication。
- 不扩 public API 或 production public C ABI。
- 不写 `runtime_state.cj`。
- 不修改 `cjpm.toml`。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe external preexisting singleton harness or throwaway creation approval decision`

## Closure 风险

当前阻塞是 intentional stop-line blocker。若没有外部 preexisting singleton harness 或
人工批准 throwaway creation probe，自动化不能继续推进到 accessor non-null observation。
