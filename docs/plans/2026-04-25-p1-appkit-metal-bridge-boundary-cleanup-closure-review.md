# P1 AppKit / Metal Bridge Boundary Cleanup Closure Review

日期：2026-04-25

性质：closure review / landed slice review  
状态：完成  
对应执行卡：[2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-execution-card.md)

## 1. Landed Code Reality

本轮已经落地：

- `labs/macos_bridge_smoke/native/cjgui_macos.m` 从单段 smoke 逻辑整理为内部 bridge context 和 Metal view。
- bridge 内部现在显式持有并清理 `NSWindow`、`CJGuiMetalView`、`CAMetalLayer`、`MTLDevice`、`MTLCommandQueue`。
- 新增最小 Metal capability 检查：
  - 默认 `MTLDevice`
  - command queue
  - `CAMetalLayer`
  - 首帧 drawable / command buffer / encoder
- 新增实验期 last-error C ABI：
  - `cjgui_last_error_code()`
  - `cjgui_last_error_category()`
  - `cjgui_last_error_message()`
- 自动关闭和人工关闭入口现在都会经过 `close requested` 语义。
- `destroyIfNeeded()` 提供单次销毁防线，避免重复销毁。
- `build_and_run.sh` 会打印当前使用的 `SDKROOT`，方便确认仍在使用 `MacOSX15.4.sdk`。
- `labs/macos_bridge_smoke/README.md` 已记录本 smoke 的关键日志和边界。

本轮没有落地：

- 没有创建正式 GUI runtime。
- 没有创建公共 Widget / DSL / Scene / Renderer API。
- 没有实现 handle table / generation table。
- 没有实现主线程消息队列。
- 没有实现文本、输入法、无障碍、AI semantic tree。

## 2. Invariants Review

已守住：

- AppKit / Metal 原生对象仍只存在于 Objective-C bridge 内部。
- 仓颉侧仍只调用 `cjgui_app_run()`，没有持有平台指针。
- `cjgui_app_run()` 仍要求在主线程调用。
- 构建链仍显式使用 `/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。
- recoverable / degraded 错误会写入 last-error 并输出错误日志。
- 自动关闭路径会输出 `close requested`、`destroy complete`、`event loop exited`。
- 本轮新增 C ABI 只作为实验期错误观察口，不是长期公共契约。

仍未覆盖：

- 没有跨线程 UI 更新入口，因此主线程消息队列仍是 future opening。
- 没有自动截图、离屏渲染或像素级 diff。
- 没有多窗口生命周期模型。

## 3. Verification

### 3.1 Red Check

实现前执行了日志断言验证，旧代码能够返回 `0`，但缺少 P1 要求的关键日志。

失败点：

```text
missing expected log: cjgui: capability check: metal device ok
```

这确认本轮验证确实能捕捉到待实现行为。

### 3.2 Green Check

实现后执行：

```zsh
set -o pipefail
LOG=/tmp/cjgui-p1-green.log
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh 2>&1 | tee "$LOG"
for needle in \
  'cjgui: using SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk' \
  'cjgui: bridge init' \
  'cjgui: capability check: metal device ok' \
  'cjgui: window created' \
  'cjgui: metal setup complete' \
  'cjgui: first frame rendered' \
  'cjgui: close requested' \
  'cjgui: destroy complete' \
  'cjgui: event loop exited' \
  'Cangjie: cjgui_app_run returned 0'; do
  grep -F "$needle" "$LOG" >/dev/null || { echo "missing expected log: $needle"; exit 1; }
done
```

结果：

- 编译成功。
- 链接成功。
- 自动关闭成功。
- `cjgui_app_run()` 返回 `0`。
- 所有关键日志断言通过。

### 3.3 Visual Check

自动关闭验证会真实创建 macOS 窗口并完成首帧绘制。

未完成：

- 本轮未解决自动截图失败问题。
- 本轮未单独执行无限等待的人工关闭命令，避免阻塞执行线程。

## 4. Stop-Line Review

本轮 stop-line 已守住：

- 不进入正式 runtime。
- 不设计对外 GUI API。
- 不新增跨平台抽象。
- 不实现消息队列。
- 不实现 Scene / Renderer。
- 不实现 Element / Widget / Layout。
- 不实现文本、输入法、无障碍。
- 不实现 AI-native semantic tree。
- 不把 smoke demo 宣传成可用 GUI 框架。

## 5. Residual Risk

残留风险：

- `last_error` 仍是实验期全局状态，只适合当前单主线程 smoke，不适合作为长期 ABI。
- `CJGuiBridgeContext` 仍是单窗口、单实例模型。
- 没有 handle table，因此不能支撑未来多窗口或异步 action。
- 没有 message queue，因此未来后台任务仍不能直接进入 UI。
- 自动视觉验证仍不完整。

这些风险均已留在后续边界，不阻塞本轮 closure。

## 6. Next Opening

当前不自动开启下一轮实现。

推荐下一条 docs-only opening：

- `P1 main-thread UI message queue preflight`

目的：

- 在任何后台任务、Agent action、异步 runtime 更新 UI 之前，先冻结 enqueue / drain / stale handle / destroyed window 的规则。

在它完成前，不实现跨线程 UI 更新能力。
