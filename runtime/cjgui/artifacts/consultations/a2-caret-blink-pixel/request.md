只读分析，不修改文件、不运行构建或桌面操作。

## 目标与不变量

A2 需要让普通 CJGUI 文本输入消费者得到聚焦时可见的插入光标相位，定时切换只改变 caret 装饰，不移除或重算 accepted caret 几何，不做正文 raster/upload；失焦后停止继续闪烁。当前代码已有原生 fake-clock 测试，但尚缺真实 Metal drawable 像素及普通消费者证据。

## 精确复现

仓库：`/Users/jiangxuanyang/Desktop/cangjie`
源码版本：`runtime/cjgui/native/cjgui_internal_renderer.m` SHA-256 `a7673be5e21173e574cc578b79f1b22fc9d831f917f169fdcb336427010fe145`。
复现探针：`runtime/cjgui/probe/text_caret_geometry_probe.cj` SHA-256 `e681fa978bc55d22f03ad118a600544f1b24d2967be6e3b6af2b372b03059f69`。探针创建普通 `cjguiComposableTextInput`，通过 `focusAcceptedSemanticNode("caret-blink-field")` 聚焦，使用已存在的 TESTING 原生时钟接口，并经真实 Metal drawable 像素读回 API 采样 accepted caret 矩形内一点。代码位置：blink controller/buildUi 大约 136–170，`captureBlinkPixel` 大约 343，`runCaretBlinkConsumerProbe` 大约 528 起。

日志：`/private/tmp/cjgui-caret-blink-consumer-build/run.log`。运行进程 PID 84201，实际二进制 `/private/tmp/cjgui-caret-blink-consumer-build/text_caret_geometry_probe`，该探针自行关闭三个窗口后退出 91，没有遗留进程。

同一进程的精简输出：
- normal input focus、accepted caret rect 成功：before `x=7,y=6,w=1.5,h=18`。
- `cjgui_internal_renderer_test_caret_blink_clock(action=3)` stop 返回 `visible=0, hasCaretRect=1`。
- 随后的 `action=0` reset 返回 status 0，但仍 `visible=0, hasCaretRect=1, deadline=5530000`，即预期显示的恢复态仍为隐藏。
- 隐藏前、预期可见、半周期隐藏、再度预期可见四次 Metal 像素采样均成功 readback、像素均为 `rgb=255,255,255,a=255`，相位间无变化。
- accepted geometry 在隐藏态仍相同。
- 全部 6 个正文工作计数始终相同：raster `1 / 122880 B / 346 us`，upload `1 / 122880 B / 14 us`。
- 同一程序既有 `runCaretReuseProbe` 对已声明普通 caret 的 drawable 像素预期也失败，样本全白；该 probe 的 raster/upload 计数反例有效（正文编辑时 raster/upload 各增加）。因此像素故障可能覆盖 blink 之前的普通 caret 装饰绘制链，不能直接归因为 blink-only 调度。

之前一次探针修正去掉了对每帧的 `window.refresh()`，并在 fake clock reset 前做 `stop`，确保可见/隐藏转换确实调度 present。修正后像素仍全白。不得继续盲目移动取样点或延长 pump 时间，需先定位故障边界。

## 相关源码

- `runtime/cjgui/native/cjgui_internal_renderer.m`：`caretBlinkTarget` 8653 起；`applyCaretBlinkPaintState` 8671；`stopCaretBlink` 8687；`resetCaretBlink` 8695；`advanceCaretBlinkAtMicros` 8741；Metal caret decoration append 约 7064；drawable readback 约 15812–15892 与 16230–16242；TESTING clock API 21311 起。
- `runtime/cjgui/native/tests/composable_caret_blink_clock_test.m`：当前纯 fake-clock/lifecycle 测试，使用 overridden target，不创建正常 drawable。
- `runtime/cjgui/native/scripts/verify_composable_caret_blink_clock.sh`：该 native harness 通过，exit 0。
- `runtime/cjgui/probe/text_caret_geometry_probe.cj`：普通正常窗口、真实 Metal readback、geometry/work计数。

## 已验证与尚未确认

`runtime/cjgui/shared_operation_core` 的 `cjpm build --skip-script` 成功；native renderer/bridge 编译成功；probe Cangjie source set 编译链接成功；`verify_composable_caret_blink_clock.sh` exit 0；`git diff --check` 通过。前述这些不构成 normal pixel acceptance。Probe 运行触达真实 drawable，但相位像素验收失败。没有编辑 renderer、text_session/window 源或 Pharos 产品。

## 希望你给出

1. 从源码和这份复现区分根因：TESTING clock API 观察到的隐藏状态问题、accepted node/view 副本/同步问题、Metal painter 漏绘，或采样/窗口坐标问题，各自有哪些直接证据？
2. 给出一到两个能区分以上假设的最小实验，包含应观察的变量/像素/节点身份。优先复用现有 TESTING 钩子和 normal consumer，不改 public API。
3. 推荐最小修复及实施边界；是否要分开修“phase 状态恢复”和更早的“已声明 caret 从未出现在 drawable”故障？
4. 明确失败/回退边界和能接受修复的反例；不要基于纯源码或 fake-clock 通过声称 Metal/consumer 验收通过。
