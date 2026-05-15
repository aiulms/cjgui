# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 下一边界决策

## 决策结论

若 no-side-effect native guard implementation、runtime owner probe、native bridge probe、build 与 scans 全部通过，当前阶段可以封账，并把唯一 next opening 推进为：

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary decision`

## 下一边界含义

下一边界只能评估 shared-application native guard facts 是否足够形成 internal value-style guard policy owner。它不得把 native guard facts 升级为 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、AppKit event loop、native visible order implementation、production drawable、color attachment、encoder、draw、commit / present、GPU submission、render、renderer state write、backend-ready truth 或 public API。

## 必读上游

- [shared-application native guard preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-native-guard-preflight-decision.md)
- [shared-application feasibility value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-feasibility-value-boundary-manifest.md)
- [NSApplication creation / activation scope value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-creation-activation-scope-value-boundary-manifest.md)
- [NSApplication guard policy value boundary manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-guard-policy-value-boundary-manifest.md)

## 停止线

不新增 public API / public C ABI / diagnostics；不返回 pointer / handle / `Class` / `id`；不写 renderer state；不修改 `runtime_state.cj`；不修改 `runtime/cjgui/cjpm.toml`。
