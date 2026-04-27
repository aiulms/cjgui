# P1 App Lifecycle State Shape Execution Card

日期：2026-04-27

性质：docs-only execution card / short authorization card / no runtime code

状态：完成；创建本卡不等于实现

## 0. Authority

唯一 authority：

- [2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-27-p1-first-internal-app-lifecycle-state-closure-review.md)

## 1. Future First Slice

未来 first slice 只允许修改：

- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中的 `CjguiInternalAppLifecycleState`

未来最多只能新增一个不可变 `Bool` 字段，语义等价于：

```text
stateMachineActive: Bool = false
```

该字段只能表达最小脱水 state shape；不代表 state machine 已定义，也不代表 `run` / `shutdown` / `request quit` / queue / drain 已实现。

## 2. Future Stop-line

未来 first slice 必须继续禁止：

- 不允许新增其他字段。
- 不允许 `public`。
- 不允许 import。
- 不允许函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不允许 public runtime API。
- 不允许 public C ABI。
- 不允许 AppKit / Metal / Objective-C 引用。
- 不允许修改 `cjpm.toml`。
- 不允许新增 `src/main.cj` 或 `package_anchor.cj`。
- 不允许修改 smoke / harness / native bridge / 仓颉入口。

## 3. Future Verification

未来 first slice 修改前必须查证：

- CangjieSkills / 本地官方文档中的 struct field 规则。
- package / visibility / default internal 规则。
- build 规则。

未来 first slice 必须运行：

- `cjpm build`，使用临时 target dir。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

## 4. This Card Stop-line

本轮只创建本卡，不修改：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- harness
- native bridge
- 仓颉入口
- `cjpm.toml`

## 5. Next Opening

当前 next opening：

> `P1 app lifecycle state shape first slice`

它不自动开启实现；如果用户明确执行，必须按本卡保持单字段、脱水、无行为的极窄切片。
