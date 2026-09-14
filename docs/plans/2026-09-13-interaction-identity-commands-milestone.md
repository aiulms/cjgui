# 大阶段：动态界面的交互身份、命令与无障碍接续

2026-09-13，原执行任务Terra/xhigh、原目录。指导下发完整实施，不按单个补丁停工。

## 方向、复用与取舍

渲染阶段接受确定性像素采样、按节点减少FFI写入、提交资源保留与重复窗口负载的已验范围；不把96.4% setter减少称为总延迟加速。native仍克隆整组节点，整体CPU/内存与实际呈现存在边界，后续按热点处理。

当前优先交付可复用的人侧交互：动态插删/重排、菜单层和焦点变化后，键盘、AX与外部业务动作仍正确对应同一对象；开发者可配置命令，无需native写应用分支。六主线中布局/渲染/资源已有基础，文字保留尾部成本，语义与包已有消费；交互完整性和可发现命令现在更影响普通应用可用性。下一候选为开发者组件组合体验，按本轮缺口决定。

复用composable_ui、窗口controller/FIFO、层宿主、当前AX bridge、真实owner命令和公开观察；旧Action Router摘要不复活。依据DESIGN_INTENT_INDEX及历史避坑的双真相、输入重入、AX与平台边界：命令执行走现有owner，不能让快捷键/菜单/AX另有业务副本；不创建Agent shell，不锁编码。

## 必要正确性与新能力

1. 先复核新增staging复用的scope身份：native克隆保留旧inputScope数字，仓颉当前scene按遍历重新编码；sameLayoutNode比较scope字符串，但不比较旧/新编码。提前建立新表不保证旧编号相同。构造节点本身/index不变、其他较早节点scope改变/插入/重排导致编号改变的反例，验证原生焦点/Tab/模态范围和AX操作，而非只比场景文本。若可复现，稳定映射或检测编码变化后刷新相关节点；不可把视觉范围错绑与外部业务授权混同。复用路径同时覆盖删除缩短、重排、部分setter失败/重试、present失败/恢复、关闭重开，旧输入不能串到新对象。这是指导静态发现的待验证风险，不先宣称已发生。
2. 建立小而通用的命令声明/解析机制：稳定命令身份、快捷键、可用状态、目标与当前焦点范围，统一菜单/键盘/AX入口进入真实controller动作。复用现有save/undo/redo和编辑键，支持应用只在仓颉声明自定义命令/快捷键，不在native添加业务分支。原生只翻译键/修饰符或系统文本命令。明确同键冲突、顶层模态/焦点范围优先级和文本输入/组合态优先权；无操作能力不伪报成功。公共API experimental、兼容旧消费者，不扩完整插件/命令面板产品。
3. 动态组件与层的焦点/无障碍接续：Tab/Shift-Tab、Enter/Space、Escape逐层退出、删除/禁用焦点项的合理恢复，重新绑定的旧AX对象拒绝写新对象。标签/角色/值/只读/禁用/选区正确投影，交互通知有变化才发；焦点变化不触发无关业务更新或全量布局。外部已授权操作不因视觉模态被重复要求授权。
4. 两个不同正常消费者用同一命令/焦点机制：至少一个文档编辑与一个结构化编辑；键盘保存/撤销、菜单选择、外部修改后本地接手和动态树变更形成完整场景。由独立Luna/Terra只按公开说明新增自定义命令并实际运行、触发、读回；明确工具输入与用户亲手输入不同。
5. 桌面可用时优先尝试真实系统中文输入法组合/候选/提交取消及VoiceOver接续；仅调用setMarkedText或AX树不计系统IME/VoiceOver通过。工具无法可靠完成则记具体阻塞及最小人工验收步骤，继续其余实现，不无限后置也不伪造结果。不改变系统安全/锁屏配置；必要临时辅助功能状态改动后恢复。

## 成本与收口

正常窗口重复焦点导航、开关层、动态插删、菜单/快捷键和外部接续，记录主线程端到端、实际build/layout/submit和AX通知/队列规模；无内容变化的导航不应按次数重建领域/全文测量，预热与样本数明确，CPU/RSS恢复独立记录。程序化生产事件和真实桌面路径分别标记，提交/GPU/overlay不冒充最终呈现。

相关controller/native/布局、core/client、runtime build --skip-script、公共声明与影响/差异扫描、两个最终bundle和独立消费一次收口。失败局部复测，生产最终变化后再重建相关产物，不每个实验全套重复。接受前阶段已验成果，不要求长文本尾部清零。遗留scope/恢复若影响新命令正确性则先解决依赖，其他独立能力继续。

按AGENTS两次实际修复失败后只读K3、两有效轮仍失败指导给方法，原环境无响应不盲目重试。无新worktree/切分支/stage/commit/push/安装发布；保持窄写集。只更新ACTIVE与本页，完整阶段或实质升级主动回报指导01a08f0f-e1ce-71c1-9a6e-4eee08308d61。

## 2026-09-13 实施与验收记录

### 交付内容

- `syncProjection` 现在把当前场景和上一已提交场景各自编码 input scope；即使布局节点本身及其索引未变、较早节点失去 scope 造成紧凑数字重排，也只在编码相同的时候复用 native staged node。`ScopeRemapController` 用真实 AppKit Tab 复现了该反例：修复前退出 `94`，修复后 Tab 从 `9406` 到 `9407`。删除缩短、部分测量 setter 失败后重试、presentation 失败恢复及关闭重开仍由同一 controller probe 覆盖。
- 新增实验性公开声明 `CjguiComposableUiShortcut`、`CjguiComposableUiCommand`、`declareCommand` 与 `invokeCommand`；旧 `bindCommand(save/undo/redo, ...)` 保持兼容。native 只把 Command 修饰键翻译成规范的 `shortcut:...` 字符串，文本系统的 Cmd-A/C/X/V 及 marked text 优先，不含任何消费者业务字符串。Cangjie 在当前 accepted scene 内检查目标可输入、命令重复、可用性、焦点 scope 与 native scene version；旧场景入队、刷新后再 pump 的快捷键曾退出 `111`，现被拒绝。
- 菜单 API、快捷键、普通 AX press 都落到同一个 `controller.applyUiEvent(eventKind: 27)`。窗口焦点保留稳定 identity；当前项禁用或删除时移至同 scope 的下一个可聚焦项，同 node id/resource/kind 被重新绑定时清空旧焦点而非猜测新业务目标。保留的旧 AX 对象要求完整 node identity 加 projection version，删除后复用 raw 字段不能作用新节点（修复前退出 `104`）。
- 正常消费者各自只在仓颉声明了一条自定义命令：文档窗口 `shared-document.open-menu`，规则编辑器 `rule-set.open-presentation-menu`，独立公开消费者 `adaptive-layout.toggle-resource`。后者没有使用内部 native 测试 ABI。

### 验证证据

| 范围 | 当前结果 | 边界 |
| --- | --- | --- |
| 动态身份、焦点、AX、命令 | `verify_composable_ui_window_controller.sh` 通过。该 probe 的先红后绿退出码为 scope `94`、禁用焦点 `97`、陈旧 AX `104`、自定义 Cmd-K `107`、陈旧快捷键 `111`。最后收紧内部类型可见性后，首次同脚本运行曾在既有逐层 Escape 收尾返回 `69`；未改代码的紧随两次重跑均为 `0`，该一次时序波动不被忽略，也尚未有根因。 | probe 使用真实 AppKit 控件/键盘和 test-only FIFO/AX seam；不等同人工辅助技术验收。 |
| 文本、场景、布局 | `verify_composable_ui_appkit_text.sh`、`verify_composable_scene_renderer.sh`、`verify_composable_ui_layout.sh` 通过。 | 文字 probe 证明 AppKit delegate/选择投影，不能代替物理中文候选窗。 |
| 构建与包 | `runtime/cjgui` 的 `cjpm build --skip-script` 通过；文档、规则、独立公开消费者三份最终 `.app` 均已在本轮源码后重新构建。 | 未安装、未公证、未发布；构建仍报告已有 `chmod`、`allowedFileTypes` deprecation 及部分未使用函数警告。 |
| 独立桌面消费者 | 从最终 `AdaptiveLayoutPublicConsumer.app` 启动，AX 树可见；自动化键盘的真实 AppKit ⌘M 使蓝色灯塔切换为珊瑚色，关闭窗口后测试进程以 0 退出。 | 自动化工具输入不等于人手键盘；没有宣称人工像素验收。 |

成本样本为预热启动后一次：controller probe 记录 idle wait `19ms`、已入队交互 turn `1ms`，两者 build/layout/submit delta 均为 `0`；菜单命令路径队列 high-water 为 `2`、pump 后 pending 为 `0`、AX 通知为 `2`。这不是 p50/p95 或长期 CPU/RSS 结论。独立消费者的短时 `ps` 读数约 `109648KiB/1.0% CPU`（9 秒）和 `111328KiB/0.9% CPU`（18 秒）；随后窗口关闭、进程退出。未做长时 RSS 收敛声明。

### 尚未以系统辅助功能通过的边界与人工步骤

此次环境可发送键盘事件并读取 AX 树，但不能可靠切换中文输入法、选择候选或读取 VoiceOver 语音；没有改动系统输入/辅助功能设置。因此“系统中文 IME”和“VoiceOver 接续”仍是未运行，而非通过或失败。

最小人工验收：启动最终文档窗口，聚焦编辑框后手动选择中文输入法；输入拼音，使用方向键切换候选，分别 Esc 取消与提交中文，确认 owner 文本/选区和撤销链路。随后由用户启用 VoiceOver，依次用 VO 导航菜单、打开层、禁用/删除当前控件、关闭层并触发命令，确认读出的标签/角色/禁用状态、焦点恢复和动作只落到当前 controller；结束后恢复原辅助功能状态。系统 IME 候选窗或 VoiceOver 语音本身不能由本轮 `setMarkedText`、AX tree 或截图替代。

### 指导复核结论

接受scope、命令、陈旧输入/AX的针对性成果；未接受无条件整阶段完成。退出69的Escape时序失败尚无根因，且重复交互成本/资源恢复未完成。两项在[组件实例与绑定生命周期阶段](2026-09-13-component-instance-binding-milestone.md)明确承接，保留原证据，不能因切换阶段视为解决。
