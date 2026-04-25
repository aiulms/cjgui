# P1 AppKit / Metal Bridge Boundary Cleanup Execution Card

日期：2026-04-25

性质：execution card / bounded implementation authorization  
状态：已创建，允许进入下一轮受限实现  
范围：只清理 `labs/macos_bridge_smoke` 的 macOS bridge 边界，不创建正式 GUI runtime。

## 0. Architect Sign-off

架构管理师确认：

- 状态：已确认
- 确认者：Codex
- 确认依据：
  - [2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-preflight.md)
  - [GUI_PROJECT_DIRECTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
  - [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
  - [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
  - [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

本轮符合项目初心：

- 不依赖重型外部 GUI 框架：是。本轮只使用 macOS 系统 AppKit / Metal 能力。
- 上层尽量仓颉原生：是。仓颉侧仍只通过 C ABI 调用桥接入口。
- 底层只保留必要平台桥接：是。允许桥接层内部变厚，但向上接口必须保持窄。
- 没有过早抽象跨平台：是。本轮只处理 macOS 单平台 smoke。

## 1. Authority

本轮唯一 authority / owner 判断：

- 执行 owner：`labs/macos_bridge_smoke/native/` 中的 macOS bridge。
- 入口 owner：`labs/macos_bridge_smoke/src/main.cj` 和 `scripts/build_and_run.sh`。
- 真相 owner：bridge 内部生命周期、Metal capability、事件循环退出状态和错误状态。
- 文档 owner：本 execution card、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`。

仓颉侧只能消费 bridge 暴露的受控 C ABI 结果，不能持有或解释 AppKit / Metal 原生对象。

## 2. Goal

本轮唯一目标：

- 把 P0 macOS bridge smoke 从“能跑”收紧到“可控”：生命周期更清楚、错误更可见、Metal capability 更明确、退出路径更可靠。

成功标准：

- 自动关闭 smoke 仍能编译、运行、进入事件循环、绘制首帧、关闭窗口并返回 `0`。
- bridge 日志能说明关键生命周期阶段，而不是只给出模糊成功。
- 平台对象仍不泄露到仓颉公共层。

## 3. Scope

本轮只做：

- 在 smoke bridge 内部整理 AppKit / Metal 对象持有关系。
- 固定 `create -> run -> close -> destroy -> event loop exit` 的最小顺序。
- 增加最小 capability 检查：
  - `MTLCreateSystemDefaultDevice()` 是否成功。
  - command queue 是否能创建。
  - `CAMetalLayer` 是否能创建和挂载。
  - 首帧 drawable / command buffer / present 是否成功走完。
- 增加生命周期日志：
  - bridge init
  - capability check
  - window create
  - metal setup
  - first frame rendered
  - close requested
  - destroy complete
  - event loop exited
- 继续保留 `CJGUI_AUTOCLOSE_SECONDS` 自动关闭验证路径。
- 如果结构体返回对仓颉 FFI 不顺手，可以先采用 `int32` 返回值加 `last_error` 辅助函数，但不得把它定义为长期公共契约。

本轮明确不做：

- 不创建正式 `src/` GUI runtime。
- 不引入正式 `CjguiHandle` 公共 API。
- 不实现 handle table / generation table，除非只作为 bridge 内部单实例保护。
- 不做多窗口。
- 不做主线程消息队列实现。
- 不做 Scene / Renderer / Element tree / Widget / Layout。
- 不做 Text / Input / IME / Accessibility。
- 不做 AI semantic tree / Action Router / IPC。
- 不做跨平台抽象。

## 4. Write Set

本轮允许修改的文件 / 模块：

- [cjgui_macos.h](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.h)
- [cjgui_macos.m](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/native/cjgui_macos.m)
- [main.cj](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/src/main.cj)
- [env.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/env.sh)
- [build_and_run.sh](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh)
- [macos_bridge_smoke README](/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/README.md)
- [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)，仅当构建命令、路径或脚本参数变化时
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- 本 execution card

本轮禁止触碰的文件 / 模块：

- `/Users/jiangxuanyang/cangjie-toolchains/cangjie`
- 系统 SDK symlink，例如 `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`
- `reference_repos/`
- `sources/`
- 未来正式框架核心目录，例如 `src/gui`、`src/runtime`、`src/widgets`
- 任何公共 Widget / DSL / cross-platform backend 设计文件

## 5. Truth / Projection

本轮真相层：

- bridge 当前生命周期阶段。
- Metal 最小能力是否存在。
- 首帧是否完成提交。
- 自动关闭或人工关闭是否走到同一类退出路径。
- 最后一次 bridge 错误的 code / category / message。

本轮只是投影 / read surface 的部分：

- 终端日志。
- 仓颉 `main.cj` 打印结果。
- smoke README 中的运行说明。
- closure review 中的验证记录。

投影不得反向发明真相。例如 README 不能宣称“已具备正式 runtime”，除非代码和执行卡都支持。

## 6. Invariants

本轮必须守住的 invariant：

- AppKit / Metal 原生对象不能以裸指针语义泄露给仓颉公共层。
- GUI 资源创建、修改、销毁默认由 macOS 主线程 owner 处理。
- 后台线程 / 仓颉协程不得直接写 GUI 资源。
- 不修改系统 SDK symlink，只通过 `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk` 绕过当前仓颉链接问题。
- recoverable 失败必须返回失败状态或错误信息，不能静默伪装为成功。
- 自动关闭路径和人工关闭路径不能出现二次释放。
- 窗口关闭后不能继续提交 redraw callback。
- 本轮所有新增 C ABI 都必须是实验性质，不得被文档升级为长期公共 API。

## 7. Fallout Scan Targets

本轮完成前必须检查的尾部影响：

- 公共 API：确认没有新增正式公共 Widget / Runtime API。
- 事件流：确认自动关闭和人工关闭都能退出 event loop。
- 状态流：确认没有引入第二套 UI 状态真相。
- 渲染流：确认 Metal clear / first frame 路径仍然有效。
- 平台桥接：确认 AppKit / Metal 对象只停留在 bridge 内部。
- 视觉 / 交互：确认人工模式仍能显示青色 / 深青色窗口。
- 文档 / 示例：确认 smoke README、tracker、closure review 与实际命令一致。
- 测试：确认自动关闭 smoke 可稳定返回。

## 8. Verification

本轮计划执行的验证：

```zsh
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

期望结果：

- 编译成功。
- 链接成功。
- 日志显示使用 `MacOSX15.4.sdk`。
- 日志显示 Metal capability check 通过。
- 日志显示窗口创建成功。
- 日志显示首帧完成。
- 日志显示自动关闭触发。
- 日志显示 destroy 完成。
- 日志显示 event loop 退出。
- 仓颉侧看到 bridge 返回 `0`。

人工视觉验证：

```zsh
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh
```

期望结果：

- 出现青色 / 深青色 Metal 清屏窗口。
- 用户手动关闭窗口后进程退出。

本轮如果无法完成的验证：

- 自动截图 / 像素级对比仍可能受 macOS 屏幕录制权限或当前截图工具限制。

对应残留风险：

- P1 仍不能完全替代人工视觉检查。
- 后续需要单独开口建设 headless rendering、frame hash 或可控截图验证。

## 9. Stop-Line

本轮 stop-line：

- 只清理 `labs/macos_bridge_smoke` 的平台桥接边界。
- 不进入正式 runtime。
- 不设计对外 GUI API。
- 不新增跨平台抽象。
- 不实现消息队列。
- 不实现 Scene / Renderer。
- 不实现 Element / Widget / Layout。
- 不实现文本、输入法、无障碍。
- 不实现 AI-native semantic tree。
- 不把 smoke demo 宣传成可用 GUI 框架。

## 10. Closure

完成后需要同步的文档或账本：

- 创建 `2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md`。
- 更新 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，只做轻量补账。
- 更新 [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)。
- 如果构建命令或环境变量变更，更新 [BUILD_FROM_ZERO.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/BUILD_FROM_ZERO.md)。
- 如果发现新的仓颉工具链问题，更新 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)。
