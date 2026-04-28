# P1 First Internal App Lifecycle State 执行卡

日期: 2026-04-27

性质: docs-only execution card / short authorization card / no runtime code

状态: 完成; 创建本卡不等于实现

## 0. 授权依据

唯一 authority:

- [2026-04-26-p1-app-lifecycle-surface-boundary_preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-boundary-preflight.md)

## 1. 未来 first slice

未来 first slice 只允许做一件事:

> 在 [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj) 中新增一个默认 internal 的 app lifecycle state marker / placeholder type。

推荐语义类似:

```text
CjguiInternalAppLifecycleState
```

最终名称必须符合仓颉命名规范。该 marker 只能表达:

```text
app lifecycle state boundary exists
lifecycle state machine is not yet defined
```

## 2. 未来允许修改范围

未来 first slice 最大允许写入:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`, 只允许补充 app lifecycle state marker 说明
- future closure review
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`

## 3. 未来 Stop-line

未来 first slice 必须继续禁止:

- 不允许字段。
- 不允许 `public`。
- 不允许 import。
- 不允许函数、方法、显式 init、构造逻辑或 runtime behavior。
- 不允许 `run` / `shutdown` / `request quit` / queue / drain。
- 不允许 platform adapter callback binding。
- 不允许 window lifecycle behavior。
- 不允许 error strategy behavior。
- 不允许 public runtime API。
- 不允许 public C ABI。
- 不允许 AppKit / Metal / Objective-C 引用。
- 不允许修改 `cjpm.toml`。
- 不允许新增 `src/main.cj` 或 `package_anchor.cj`。
- 不允许修改 smoke / harness / native bridge / 仓颉入口。
- 不允许 Renderer / Scene / Widget / Layout / DSL。
- 不允许 Dirty Rect / global tick / frame scheduler。
- 不允许 Text / Input / IME / Accessibility。
- 不允许 semantic tree / Action Router。
- 不允许 command-list hash / pixel diff / baseline / offscreen renderer。
- 不允许创建 `CJGUI_TRUTH_MANIFEST.md`。

## 4. 未来验证

未来 first slice 修改前必须查证:

- CangjieSkills / 本地官方文档中的 struct 规则。
- package / visibility / default internal 规则。
- build 规则。

未来 first slice 必须运行:

- `cjpm build`, 使用临时 target dir。
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh`
- `git diff --check`

closure review 必须记录 marker 名称、default internal、无字段、无 public、无 import、无函数 / 方法 / 显式 init、无 runtime behavior、build 结果、smoke guard 结果和 stop-line。

## 5. 本卡 Stop-line

本轮只创建本卡，不修改:

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/`
- `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`
- harness
- native bridge
- 仓颉入口
- `cjpm.toml`

## 6. 下一步 opening

当前 next opening:

> `P1 first internal app lifecycle state first slice`

它不自动开启实现; 如果用户明确执行，必须按本卡保持最小 internal marker 切片。
