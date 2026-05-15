# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Native Side-Effect Containment 预检决策

状态：docs-first preflight / no runtime truth

## 决策结论

本阶段选择 A 路线：允许下一刀进入 internal-only、no-call native side-effect containment implementation bundle；不允许 actual application singleton accessor call。

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness` 足够作为 side-effect containment 的上游。下一刀只能新增 deterministic native integer facts 与 runtime owner，把 future `sharedApplication` accessor-call discussion 继续隔离在 no-call containment 边界内。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()`
- [accessor call preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-preflight-manifest.md)

## 下一刀允许的实现面

- 可新增 production native bridge internal C ABI，命名保持 `cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_*`。
- 新增 native C ABI 只能返回 deterministic `int32_t` facts；不得调用 application singleton accessor，不得创建 `NSApplication`，不得产生 AppKit lifecycle side effect。
- 可新增 runtime internal owner，默认文件为 [runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj)。
- Runtime owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`。
- 可新增 native probe 与 owner probe，验证 containment facts、符号存在、上游 input 与停止线。
- 可更新 existing native bridge callable allowlist，使新增 no-call containment symbols 不被旧 probes 误报。

## containment facts

下一刀只能固定：

- accessor call still blocked。
- no singleton accessor call observed / executed。
- singleton creation still blocked。
- main-thread gate required。
- bounded run loop required。
- auto-close required。
- teardown before visible required。
- non-user-visible mode required。
- application side effect still blocked。
- activation policy mutation blocked。
- activation blocked。
- event loop blocked。
- native visible order blocked。
- production drawable blocked。
- render blocked。
- no pointer / handle / `Class` / `id` return。
- no renderer state write。
- no backend-ready truth。

## 严格禁止

下一刀不得调用 `sharedApplication`、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得修改 activation policy，不得运行 AppKit event loop，不得做 native visible order implementation，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，不得写 renderer state，不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`，不得把 containment facts 升级为 application-ready / visible-ready / drawable-ready / render-ready / backend-ready truth。

## GitNexus 结果

GitNexus 对 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`、`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()` 与既有 `cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked` 返回 target not found / UNKNOWN / impactedCount 0。该结果只说明近期新增 Renderer/native symbols 未被索引覆盖，不能作为安全证明；本阶段必须以源码读取、probe、build、smoke、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 下一边界

若 implementation、owner probe、native probe、build、smoke 与 scans 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment policy value boundary decision`

该 next opening 仍不是 application singleton accessor call、`NSApplication` creation / activation、visible order、drawable acquisition、GPU submission、render、renderer state write、backend-ready truth、public API 或 public C ABI permission。
