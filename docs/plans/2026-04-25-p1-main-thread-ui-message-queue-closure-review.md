# P1 Main-thread UI Message Queue Closure Review

日期：2026-04-25

性质：closure review / landed slice review
状态：完成
对应执行卡：[2026-04-25-p1-main-thread-ui-message-queue-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-execution-card.md)

## 1. Landed Code Reality

本轮已经落地：

- `labs/macos_bridge_smoke/native/cjgui_macos.m` 增加 bridge 内部单实例 lifecycle queue first slice。
- 当前只支持一种 lifecycle message：
  - `RequestClose`
- 自动关闭路径现在先输出：
  - `cjgui: post close request: auto-close`
  - `cjgui: main-thread drain`
  - `cjgui: close requested: auto-close`
- 人工关闭路径通过 `windowShouldClose` 先 post close request，并由主线程 drain 后再进入关闭路径。
- 关闭仍复用既有 `close requested -> window will close -> destroy complete -> event loop exited` 路径。
- `labs/macos_bridge_smoke/README.md` 已记录本 smoke 的 lifecycle queue 行为和日志断言命令。

本轮没有落地：

- 没有实现通用 UI update queue。
- 没有实现 target update message。
- 没有实现 handle table / generation table。
- 没有新增 public runtime API。
- 没有设计 Scene / Renderer / Widget / Layout / DSL。
- 没有做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。

## 2. Invariants Review

已守住：

- AppKit / Metal 原生对象仍只存在于 Objective-C bridge 内部。
- 仓颉侧仍只调用 `cjgui_app_run()`，没有新增 public runtime API。
- message payload 没有携带 `NSWindow*`、`NSView*`、`NSEvent*`、`CAMetalLayer*`、Metal 对象或 Objective-C `id`。
- drain 只在主线程执行。
- 自动关闭不再直接 close window，而是先 post `RequestClose`。
- 人工关闭不直接走另一条释放路径，而是通过 `windowShouldClose` post `RequestClose`。
- close / destroy 路径仍保持幂等。
- `last_error` 仍只是实验期观察口，没有扩展成并发错误系统。

## 3. Verification

### 3.1 Red Check

实现前执行：

```zsh
set -o pipefail
LOG=/tmp/cjgui-p1-message-queue-red.log
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh 2>&1 | tee "$LOG"
for needle in \
  'cjgui: post close request' \
  'cjgui: main-thread drain' \
  'cjgui: close requested' \
  'cjgui: destroy complete' \
  'cjgui: event loop exited' \
  'Cangjie: cjgui_app_run returned 0'; do
  grep -F "$needle" "$LOG" >/dev/null || { echo "missing expected log: $needle"; exit 1; }
done
```

结果：

```text
missing expected log: cjgui: post close request
```

这证明断言能捕捉本轮缺失的 queue / drain 行为。

### 3.2 Green Check

实现后执行：

```zsh
set -o pipefail
LOG=/tmp/cjgui-p1-message-queue.log
CJGUI_AUTOCLOSE_SECONDS=1 /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh 2>&1 | tee "$LOG"
for needle in \
  'cjgui: post close request' \
  'cjgui: main-thread drain' \
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
- 自动关闭触发。
- 输出 `cjgui: post close request: auto-close`。
- 输出 `cjgui: main-thread drain`。
- 输出 `cjgui: close requested: auto-close`。
- 输出 `cjgui: destroy complete`。
- 输出 `cjgui: event loop exited`。
- `cjgui_app_run()` 返回 `0`。
- 日志断言通过。

## 4. Stop-Line Review

本轮 stop-line 已守住：

- 不支持通用 UI update。
- 不支持 target update。
- 不实现 handle table / generation。
- 不新增 public runtime API。
- 不设计 Scene / Renderer。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不把 smoke demo 宣称为正式 runtime。

## 5. Residual Risk

仍未覆盖：

- 真实多线程压力。
- handle generation。
- 多窗口。
- target update message。
- 通用 UI update queue。
- 自动视觉验证 / pixel diff。
- Agent action 或 runtime async update。

当前结论：

- 本轮只证明单实例 `RequestClose` lifecycle message 可以经由主线程 post / drain 进入已有关闭路径。
- 不能把它升级解释为正式 async UI runtime。
- 如果后续要支持 target update message，必须另开或扩展 execution card，并同步实现最小 handle / generation validation。

## 6. Next Opening

当前不自动开启下一轮实现。

如果继续推进，应回到 docs-only gate 或创建新的受限 execution card。

候选 future opening：

- 平台事件模型冻结 preflight。
- 自动视觉验证 / pixel-diff preflight。
- 更完整的 handle table / generation preflight。

这些都不因本轮 closure 自动开启。
