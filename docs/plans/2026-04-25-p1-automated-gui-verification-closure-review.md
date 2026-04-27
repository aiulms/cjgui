# P1 Automated GUI Verification Closure Review

日期：2026-04-25

性质：closure review / landed slice review
状态：完成
对应执行卡：[2026-04-25-p1-automated-gui-verification-execution-card.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-execution-card.md)

## 1. Landed Code Reality

本轮已经落地：

- 新增 `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`。
- harness 默认调用：
  - `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/build_and_run.sh`
- harness 默认设置：
  - `CJGUI_AUTOCLOSE_SECONDS=1`
- harness 默认捕获日志到：
  - `/tmp/cjgui-p1-auto-close-verify.log`
- harness 只检查现有日志 needle。
- `labs/macos_bridge_smoke/README.md` 已记录 smoke 验证命令、日志语义和非像素级验证边界。

本轮没有落地：

- 没有修改 Objective-C bridge。
- 没有修改仓颉入口。
- 没有修改 `build_and_run.sh`。
- 没有实现自动截图、window screenshot、pixel diff、Metal readback、frame hash 或 offscreen renderer。
- 没有新增 frame metadata / render stats 代码。
- 没有引入重型 GUI 测试框架。
- 没有设计 Renderer / Scene / Widget / Layout / DSL。
- 没有把 harness 宣称为正式 GUI runtime 测试框架。

## 2. Harness Contract

harness 检查的日志 needle：

- `cjgui: using SDKROOT=`
- `cjgui: bridge init`
- `cjgui: capability check: metal device ok`
- `cjgui: capability check: command queue ok`
- `cjgui: window created`
- `cjgui: metal setup complete`
- `cjgui: first frame rendered`
- `cjgui: post close request`
- `cjgui: main-thread drain`
- `cjgui: close requested`
- `cjgui: destroy complete`
- `cjgui: event loop exited`
- `Cangjie: cjgui_app_run returned 0`

如果任一日志缺失，harness 输出：

```text
missing expected log: <needle>
```

并返回非 0。

成功时 harness 输出简短摘要，并明确：

```text
cjgui verify: this is not pixel-level verification
```

## 3. Verification

### 3.1 Red Check

实现前执行：

```bash
bash /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

结果：

```text
bash: /Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh: No such file or directory
```

退出码：

```text
127
```

这证明本轮开始前没有可复用 verification harness。

### 3.2 Green Check

实现后执行：

```bash
/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/scripts/verify_auto_close.sh
```

日志路径：

```text
/tmp/cjgui-p1-auto-close-verify.log
```

结果：

- harness 退出码为 `0`。
- `cjgui: using SDKROOT=` 可见。
- `cjgui: bridge init` 可见。
- `cjgui: capability check: metal device ok` 可见。
- `cjgui: capability check: command queue ok` 可见。
- `cjgui: window created` 可见。
- `cjgui: metal setup complete` 可见。
- `cjgui: first frame rendered` 可见。
- `cjgui: post close request` 可见。
- `cjgui: main-thread drain` 可见。
- `cjgui: close requested` 可见。
- `cjgui: destroy complete` 可见。
- `cjgui: event loop exited` 可见。
- `Cangjie: cjgui_app_run returned 0` 可见。
- harness 输出 `cjgui verify: auto-close log assertions passed`。
- harness 输出 `cjgui verify: this is not pixel-level verification`。

## 4. Evidence Boundary

本验证证明：

- build script 可以运行。
- macOS SDK 路径通过日志可见。
- bridge init 进入。
- Metal capability check 至少完成 device 和 command queue 检查。
- 单窗口创建路径进入。
- Metal setup complete 日志出现。
- first frame submitted / rendered 日志出现。
- 自动关闭通过 `post close request` 进入 lifecycle queue。
- close request 由主线程 drain。
- close / destroy / event loop exit 路径完成。
- 仓颉侧观察到 `cjgui_app_run()` 返回 `0`。

本验证不证明：

- 屏幕像素正确。
- 窗口实际可见或未被遮挡。
- Metal drawable 最终像素非空。
- screenshot / window screenshot 可用。
- Metal readback 可用。
- frame hash 或 pixel diff 通过。
- offscreen renderer 可用。
- headless GUI verification 可用。

## 5. Stop-Line Review

本轮 stop-line 已守住：

- 未修改 `labs/macos_bridge_smoke/native/cjgui_macos.m`。
- 未修改 `labs/macos_bridge_smoke/native/cjgui_macos.h`。
- 未修改 `labs/macos_bridge_smoke/src/main.cj`。
- 未修改 `labs/macos_bridge_smoke/scripts/build_and_run.sh`。
- 未实现自动截图、window screenshot、pixel diff、Metal readback、frame hash 或 offscreen renderer。
- 未新增 frame metadata / render stats 代码。
- 未引入重型 GUI 测试框架。
- 未设计 Renderer / Scene / Widget / Layout / DSL。
- 未做跨平台抽象、文本、输入法、无障碍、AI semantic tree / Action Router。
- 未把 harness 宣称为正式 GUI runtime 测试框架。

## 6. Residual Risk

仍未覆盖：

- 真实多线程压力。
- handle generation。
- 多窗口。
- target update。
- 通用 UI update queue。
- 自动截图。
- window screenshot。
- Metal readback。
- frame hash。
- pixel diff。
- offscreen renderer。
- 自动视觉验证。
- 真实 CI / headless 环境稳定性。

当前结论：

- 本轮只把已有自动关闭日志断言封装成可复用 harness。
- 本轮让 closure review 可以复核 machine-readable 日志证据。
- 本轮不能升级解释为像素级验证、视觉回归测试或正式 GUI runtime 测试框架。

## 7. Next Opening

当前不自动开启下一轮实现。

如果继续推进 automated GUI verification，应先回到 docs-only gate，选择一个单独 bounded opening，例如：

- 最小 screenshot attempt exploratory execution card。
- Metal drawable readback exploratory execution card。
- frame metadata / render stats execution card。

这些都不能从本轮 closure 自动获得实现授权。
