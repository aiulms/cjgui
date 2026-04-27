# P1 Automated GUI Verification Preflight

日期：2026-04-25

性质：docs-only / verification strategy preflight / P1 runtime foundation
状态：完成；不批准直接实现
范围：冻结未来 GUI 自动化验证路线，不实现截图、pixel diff、offscreen renderer 或正式测试框架。

## 1. 背景

当前已经完成：

- [P0 macOS bridge smoke](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)。
- [P1 AppKit / Metal bridge boundary cleanup](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)。
- [P1 main-thread UI message queue first slice](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)。

这些工作证明了：

- 仓颉可以通过 C ABI 进入 Objective-C / AppKit / Metal。
- smoke 可以创建 macOS 单窗口。
- Metal 可以完成首帧清屏。
- 自动关闭路径可以通过日志断言验证。
- `RequestClose` lifecycle message 可以经由主线程 post / drain 进入关闭路径。

但 GUI 结果本身仍没有自动化视觉证据。

当前仍依赖：

- 生命周期日志。
- 退出码。
- 人工视觉确认。

本 preflight 的目标是冻结下一步验证策略，让项目逐步从“日志 + 人工看见窗口”走向 AI 可以稳定复核的截图、像素、frame hash、render stats 或离屏验证。

## 2. Authority

本轮 authority：

- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI_RISK_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_DEVELOPMENT_CONSTITUTION.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)
- [2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-appkit-metal-bridge-boundary-cleanup-closure-review.md)
- [2026-04-25-p1-main-thread-ui-message-queue-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-main-thread-ui-message-queue-closure-review.md)

本 preflight 只冻结验证策略。

它不是：

- execution card
- implementation authorization
- 自动截图实现批准
- pixel diff 实现批准
- Renderer / Scene 设计批准

## 3. 当前 GUI 验证现实

当前 GUI 验证现实是：

- 自动验证主要靠日志断言和进程退出码。
- 人工视觉检查曾确认窗口可见且呈青色 / 深青色 Metal 清屏。
- 自动截图曾失败，错误为：

```text
could not create image from display
```

当前最可靠的自动证据是：

- 构建脚本能运行。
- 使用的 `SDKROOT` 可见。
- AppKit / Metal 初始化日志可见。
- Metal capability check 日志可见。
- 首帧渲染路径日志可见。
- 自动关闭能触发。
- 主线程 lifecycle queue 能 post / drain close request。
- `destroy complete` 和 `event loop exited` 可见。
- 仓颉侧 `cjgui_app_run()` 返回 `0`。

当前最不可靠的证据是：

- 屏幕上到底有没有正确颜色。
- 窗口是否被遮挡。
- 截图是否捕捉到目标窗口。
- 渲染是否在像素层面符合预期。

## 4. 目前已经能自动验证什么

目前已经能自动验证：

1. 构建链是否能完成。
   - `clang` 编译 Objective-C bridge。
   - `ar` 生成静态库。
   - `cjc` 链接仓颉入口。

2. macOS SDK 是否被显式使用。
   - 当前脚本会输出 `cjgui: using SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。

3. bridge 生命周期是否进入关键阶段。
   - `bridge init`
   - `window created`
   - `metal setup complete`
   - `first frame rendered`

4. Metal 最小 capability 是否存在。
   - default device。
   - command queue。
   - layer / drawable / command buffer / encoder。

5. 自动关闭和 event loop 退出。
   - `post close request`
   - `main-thread drain`
   - `close requested`
   - `destroy complete`
   - `event loop exited`

6. 仓颉侧是否看到返回值。
   - `Cangjie: cjgui_app_run returned 0`

这些证据可以证明“执行路径”存在。

它们不能证明“像素结果”正确。

## 5. 目前仍不能自动验证什么

当前不能自动验证：

- 窗口实际内容是否为预期颜色。
- Metal drawable 最终像素是否非空。
- 清屏颜色是否正确。
- 窗口是否被遮挡、最小化或落在不可见桌面空间。
- Retina scale / drawable size 是否与预期像素尺寸完全一致。
- resize 后像素是否正确。
- GPU command 是否真的产生了可读结果，而不仅是提交成功。
- 多帧稳定性。
- headless / CI 环境下的可重复视觉结果。
- 多窗口、遮挡、焦点、窗口管理器边缘行为。

这些限制意味着：

> 当前 closure review 可以接受日志和人工视觉证据，但不能把它们解释为完整 GUI 自动化验证。

## 6. 自动截图失败的风险

之前自动截图失败：

```text
could not create image from display
```

风险包括：

- macOS 屏幕录制权限可能未授予当前进程。
- 运行环境可能没有可截图的显示会话。
- 截图工具可能无法捕捉目标 display。
- 即使截图成功，也可能截到错误桌面、错误窗口、遮挡窗口或空白区域。
- 全屏空间、Mission Control、显示器休眠、窗口焦点都可能影响截图。
- 截图证据可能变成 flaky false negative。
- 为了让截图稳定，可能诱导我们过早改动窗口管理、定位、置顶、等待策略或 runtime 生命周期。

结论：

> macOS 屏幕截图不能直接作为第一阶段唯一自动视觉验证路线。

它可以作为 future exploratory slice，但必须有单独 execution card，并且失败时应记录为 degraded，而不是把 GUI 本身判定为失败。

## 7. 验证 owner

未来验证 owner 应拆分，而不是塞给单一模块。

### 7.1 bridge owner

bridge owner 负责：

- 暴露窄的日志和 diagnostics。
- 报告 capability。
- 报告 lifecycle。
- 在未来提供最小 frame metadata / render stats。
- 保持平台对象不泄露。

bridge 不应该负责：

- 存 baseline image。
- 做完整 pixel diff 策略。
- 设计 Renderer / Scene。
- 成为跨平台 verification abstraction。

### 7.2 test harness owner

test harness 负责：

- 启动 smoke。
- 设置环境变量。
- 收集日志。
- 判断 expected log。
- 未来收集截图 / hash / stats。
- 输出 machine-readable verification result。

近期最合适的 owner 是：

> 独立 verification harness。

它可以先是脚本或小工具，但必须独立于正式 runtime API。

### 7.3 render layer owner

未来 Renderer / Scene 出现后，render layer 才能负责：

- deterministic render input。
- frame hash。
- offscreen texture render。
- pixel baseline。
- render command replay。

在 Renderer / Scene 之前，不应让 smoke demo 反向发明正式渲染验证 API。

## 8. 第一阶段路线选择

候选路线评估如下。

### 8.1 render stats / lifecycle logs

优先级：最高。

适合作为近期第一刀。

可验证：

- 构建链。
- 生命周期。
- Metal capability。
- 首帧提交。
- drawable size / scale factor。
- frame count。
- clear color metadata。
- close / destroy / event loop exit。

优点：

- 当前已有基础。
- 不需要屏幕录制权限。
- 不需要读取 GPU texture。
- 不需要正式 Renderer / Scene。
- 不容易把验证扩成 runtime。

限制：

- 不能证明最终像素正确。
- 只能证明渲染路径和元数据。

建议：

- 近期如果要实现第一刀 verification harness，应优先做日志断言 + 可选 frame metadata / render stats。

### 8.2 macOS 屏幕截图

优先级：低到中。

优点：

- 能验证用户视角看到的东西。
- 与真实窗口路径一致。

风险：

- 依赖屏幕录制权限。
- 易受遮挡、焦点、桌面空间、显示器状态影响。
- 失败不一定代表渲染失败。
- 不适合作为无头 CI 第一证据。

建议：

- 只能作为 exploratory slice。
- 失败归类为 degraded。
- 不作为第一阶段主线。

### 8.3 window screenshot

优先级：中。

优点：

- 比全屏截图更靠近目标窗口。
- 可能减少遮挡和裁剪问题。

风险：

- 仍依赖 macOS API、权限和窗口会话。
- 需要稳定定位目标 window。
- 可能诱导过早设计 window handle 或 query API。

建议：

- 等最小 handle / window diagnostics 更清楚后再开。
- 不在本轮承诺。

### 8.4 Metal drawable readback

优先级：中。

优点：

- 直接靠近 GPU 渲染结果。
- 不依赖屏幕录制权限。
- 可以产生 frame hash 或像素摘要。

风险：

- 当前 `CAMetalLayer` 路径未为 readback 设计。
- `framebufferOnly`、storage mode、synchronization 等细节会影响可读性。
- readback 可能改变渲染管线和性能假设。
- 容易把 smoke 代码扩成半个 renderer。

建议：

- 可以作为未来单独 execution card 探索。
- write set 必须极窄。
- 不应与 Renderer / Scene 设计绑定。

### 8.5 offscreen texture render

优先级：中到高，但必须延后。

优点：

- 最适合可重复、无窗口、无显示器的验证。
- 可直接做 hash / pixel diff。

风险：

- 需要渲染输入与窗口系统解耦。
- 很容易提前设计 Renderer / Scene。
- 当前 smoke 还没有 render command 或 Scene 输入。

建议：

- 必须等 Renderer / Scene 或最小 render command 设计之后。
- 不在当前 P1 直接开启。

### 8.6 frame hash

优先级：中。

优点：

- 比完整 pixel diff 更轻。
- 适合快速确认 frame 是否稳定、非空、颜色是否大致一致。

前提：

- 必须有稳定像素来源。
- 来源可以是 Metal readback 或 offscreen texture。

建议：

- 先规划，不实现。
- 可作为 Metal readback / offscreen 的后续产物。

### 8.7 pixel diff

优先级：后置。

优点：

- 最接近自动视觉回归测试。

风险：

- 需要 baseline 管理。
- 需要 tolerance。
- 需要处理颜色空间、scale、平台差异、抗锯齿、GPU 差异。
- 很容易引入重型测试框架或跨平台抽象。

建议：

- 不能作为当前第一刀。
- 等像素来源稳定后再单独 preflight。

## 9. 当前推荐路线

推荐路线：

```text
阶段 A：日志断言 + frame metadata / render stats
-> 阶段 B：最小截图或 Metal readback exploratory slice
-> 阶段 C：frame hash
-> 阶段 D：pixel diff
-> 阶段 E：offscreen / headless render verification
```

当前最稳的近期方向是：

> 先做日志断言 + 可选 frame metadata / render stats；再单独开 execution card 探索最小截图或 Metal readback。

不建议现在承诺：

- 完整 headless GUI 测试。
- 完整 pixel diff。
- 正式 offscreen renderer。
- 跨平台 verification abstraction。

## 10. 哪些现在可以规划

现在可以规划：

- 统一日志断言格式。
- smoke verification script 的输入输出形状。
- `render stats` 可能包含哪些字段。
- `frame metadata` 的最小字段：
  - frame index
  - drawable width / height
  - scale factor
  - pixel format
  - clear color metadata
  - first frame submitted
- closure review 可接受的证据分级。
- 截图失败时如何记录 degraded。
- 验证 harness 与 runtime 的边界。

现在不能实现：

- 自动截图。
- pixel diff。
- Metal readback。
- offscreen renderer。
- frame hash。

## 11. 哪些必须等 Renderer / Scene 之后

必须等 Renderer / Scene 或至少最小 render command 之后：

- render command replay。
- offscreen texture render。
- framework-level frame hash。
- widget-level pixel diff。
- layout visual regression。
- scene-level golden image。
- cross-platform visual baseline。

原因：

- 当前 smoke 没有状态树。
- 当前 smoke 没有 Scene。
- 当前 smoke 没有 Renderer 输入。
- 当前 smoke 只有平台桥接层和 Metal 清屏。

不能为了验证提前发明这些层。

## 12. closure review 可接受的验证证据

closure review 可以接受分级证据。

### 12.1 当前可接受

当前可接受：

- 构建命令。
- 退出码。
- 日志断言。
- capability check。
- lifecycle logs。
- `cjgui_app_run()` 返回值。
- 人工视觉确认。

前提：

- 明确写出“这不是像素级验证”。
- 明确记录未覆盖风险。

### 12.2 近期可接受

近期可接受：

- render stats。
- frame metadata。
- first-frame counter。
- drawable size / scale factor。
- clear color metadata。
- screenshot attempt result。
- degraded reason。

### 12.3 未来可接受

未来可接受：

- window screenshot artifact。
- Metal readback bytes / hash。
- offscreen texture hash。
- pixel diff result。
- baseline comparison report。
- frame hash history。

## 13. 避免人工视觉成为永久唯一证据

规则：

- 每个 closure review 必须标注视觉证据类型。
- 人工视觉可以作为补充证据，但不能永远是唯一证据。
- 每次 GUI slice 都应优先留下至少一种机器可复核证据。
- 如果只有人工视觉，必须写明阻塞原因和下一步验证 opening。
- 自动截图失败不能被遗忘，必须保留在 residual risk 中，直到有替代路线。

近期最低要求：

> 任何 GUI implementation closure 至少要有日志断言；涉及视觉结果时，应说明是否有人工视觉、截图、metadata、hash 或 pixel 证据。

## 14. 避免为了验证扩写正式 runtime

验证 harness 不能反向定义 runtime。

禁止：

- 为了截图引入正式 `WindowHandle` API。
- 为了 pixel diff 提前设计 Renderer / Scene。
- 为了 offscreen 测试创造公共 render abstraction。
- 为了 CI 引入跨平台 backend。
- 为了方便测试暴露 `NSWindow*`、`CAMetalLayer*` 或 Metal 对象。
- 为了基线管理引入重型 GUI 测试框架。

允许：

- 在实验区做极窄脚本或 harness。
- bridge 暴露脱水 metadata。
- 记录 degraded reason。
- 用 execution card 限定 write set。

## 15. 是否允许修改 labs/macos_bridge_smoke

本轮答案：

> 不允许。

本轮只做 docs-only preflight。

不修改：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`
- `labs/macos_bridge_smoke/native/cjgui_macos.h`
- `labs/macos_bridge_smoke/src/main.cj`
- `labs/macos_bridge_smoke/scripts/*`
- `labs/macos_bridge_smoke/README.md`

如果未来要实现第一刀 verification harness，必须先创建 execution card。

## 16. 未来第一刀 write set 建议

如果未来实现第一刀 verification harness，建议 write set 极窄。

优先允许：

- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 或等价脚本。
- `labs/macos_bridge_smoke/README.md`，仅记录验证命令和结果。
- `docs/plans/*execution-card.md`
- `docs/plans/*closure-review.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`

谨慎允许：

- `labs/macos_bridge_smoke/native/cjgui_macos.m`，仅当需要输出 frame metadata / render stats。

禁止：

- 新建正式 runtime 目录。
- 修改 public GUI API。
- 新增 Renderer / Scene。
- 新增 Widget / Layout / DSL。
- 新增跨平台 verification abstraction。
- 引入重型 GUI 测试框架。

未来第一刀目标建议：

- 只封装现有日志断言为可复用 harness。
- 可选增加脱水 frame metadata / render stats。
- 不做截图。
- 不做 pixel diff。
- 不做 offscreen render。

## 17. 当前 stop-line

本轮强制 stop-line：

- 不实现自动截图。
- 不实现 pixel diff。
- 不实现 offscreen renderer。
- 不修改 `labs/macos_bridge_smoke` 代码。
- 不设计正式 Renderer / Scene。
- 不设计 Widget / Layout / DSL。
- 不做跨平台抽象。
- 不做文本、输入法、无障碍。
- 不做 AI semantic tree / Action Router。
- 不引入重型 GUI 测试框架。
- 不把当前 smoke demo 宣称为正式 runtime。

额外保持：

- 不把人工视觉检查写成长期唯一方案。
- 不把日志断言写成像素验证。
- 不把截图失败解释成渲染失败。
- 不把 verification harness 变成 runtime owner。

## 18. 结论

本轮结论：

- 当前 GUI 自动验证已经能覆盖构建、日志、lifecycle、Metal capability、first frame submitted 和退出码。
- 当前仍不能自动验证真实像素、窗口截图、frame hash 或 pixel diff。
- 之前 `could not create image from display` 说明 macOS 截图路径存在权限和环境不确定性，不能作为第一阶段唯一证据。
- 近期 owner 应是独立 verification harness，bridge 只提供窄 metadata / stats，Renderer / Scene 相关验证必须等对应层出现。
- 第一阶段优先路线是日志断言 + 可选 frame metadata / render stats。
- 截图、Metal readback、frame hash、pixel diff、offscreen render 都必须另开 execution card。
- 本轮不允许修改 `labs/macos_bridge_smoke`。
- 本轮不实现任何自动视觉验证。

下一步不自动进入实现。

如果继续推进，推荐下一条 docs-only opening：

- `P1 automated GUI verification execution card`

它应只授权一个极窄 first slice：

- 封装现有日志断言为 verification harness。
- 可选增加 frame metadata / render stats。
- 不做截图。
- 不做 pixel diff。
- 不做 offscreen renderer。
