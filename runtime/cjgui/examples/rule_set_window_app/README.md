# CJGUI 规则集编辑器

这是可用预览的正常 macOS 应用：左侧分页显示任意数量的规则，右侧编辑当前规则的草稿。新增、删除、撤销、重做、保存和应用草稿都经由同一份 `CjguiRuleSetEditingDomain`；窗口行号只是视口位置，不是记录 ID。它使用框架拥有的 [macOS 应用宿主](../../MACOS_APPLICATION_HOST.md)，不再编译 sample launcher 或声明 finish FFI。

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/rule_set_window_app
zsh run.sh --save-as /tmp/rules.cjgui-rules
```

用 `--open PATH` 重新打开已有文件。`PATH` 可以是当前目录相对名；打开/保存会把它固定为同一文件的绝对目标，后续原子的临时写入、租约和冲突复查都使用该目标。启动时会打印一次私有 descriptor 路径；获授权的外部客户端必须先发现 descriptor，再读上下文、读取变化或调用声明的动作。桌面锁屏时不把脚本写文件当成 GUI 验收。

集合视图预设（列表/表格/卡片模式、筛选、排序、列宽/显隐/顺序）使用单独偏好文件，默认是 `--open PATH` 的 `PATH.cjgui-views`，也可用 `--view-preferences PATH` 指定。工具栏“视图预设”保存/切换/恢复默认视图；只有“保存偏好”显式写盘。重开恢复已保存视图，不恢复未提交草稿。接口、格式和边界见 [COLLECTION_VIEWS.md](COLLECTION_VIEWS.md)；公共虚拟卡片网格的用法见 [CARD_GRID.md](../../CARD_GRID.md)。

仅验证普通 bundle 构建与签名而不启动窗口：`zsh run.sh --build-only`。保存写入已应用的规则集；草稿要先“应用草稿”，或使用“取消并重载”明确放弃。业务关闭仍遵循原领域策略；界面文档先单独结算：未保存界面时系统关闭/⌘W/⌘Q 显示“保存界面 / 放弃本次界面改动 / 取消关闭”，保存界面只写 `cjgui.ui-document`，不应用或保存业务草稿；空路径需先另存。取消后可继续编辑，保存后重开以文件结构摘要为准。启动参数不会覆盖已经存在的另存为目标。重启后的重复请求保证不延续，调用方应通过 `GET_CONTEXT`/`GET_CHANGES` 读回确认结果。

## 普通窗口成本与复用

正常启动仍为空列表，诊断默认关闭。`zsh run.sh --seed-table-rows 2000 --retention-range 1 365 --performance-scene`
经原 owner 创建真实记录，使用现有虚拟列表、手写与生成字段，并让两个图片实例引用同一已注册 beacon；不引入另一份业务数据。
`--observe-costs` 仅为有界归因：Host 启动后启用既有 `setWorkloadDiagnostics`／`setTimingDiagnostics`，
从 `diagnosticSnapshot(maximumNodes: 1)` 稀疏读取标量，最多 96 笔；结束恢复采集设置。
首次 build/layout 发生于启用计时前，其耗时未知，不能把累计值零解释成零成本。

公开消费者可复用 `../../examples/window_perf_baseline.py` 的普通应用进程采样、
`--interactive-executable` 与 `--generated-structure`（经公共 client 提交同一声明）；
stdin JSON `{"phase":"name"}` 只读一次紧凑进度。宿主没有持久 stdin 时，用
`--mark-descriptor PATH --phase name --output phases.jsonl`。输入和操作仍走正常窗口或公开 owner 入口。
保留每笔样本；CPU/RSS 来自实际应用 PID。`WINDOW_WORKLOAD_*` 为现有进度事实，未知时间不补数。
声明构建、布局、原生准备／提交、GPU 完成分别解释；任何一项都不代表实际屏幕呈现延迟。
常态使用可不启动采样器；Inspector 按需读取同一个诊断快照。

静态文字的字形纹理在本地 tile、正文、布局、字体／排版、颜色和资源身份均相同时，可跨 shader 裁剪变化复用；
完整来源身份仍随当前几何更新。完全裁剪后的释放、24 MiB 文字资源准入及 GPU 完成退休规则沿用原实现，
不新增无界缓存。生成图片继续使用共同叶样式，字距／行高与 fontSize 一样经共同样式解码；
`textOverflow` 仍限只读文字／动作组件。此轮原生复用和窗口消费验于 macOS；其他后端未验。

该正常应用的 descriptor 明确授予 `GET_WINDOW_PROGRESS` 与
`GET_WINDOW_INTERACTION` 两个不同动作，均为 `ALL` scope。前者仅含会话、场景、
提交和帧进度，适用于 `wait-window`；后者才含焦点、可选 UTF-16 选区和顶层 layer。
先通过 `python3 ../../shared_operation_core/client.py "$DESCRIPTOR" get` 动态读取
`ACTION`/`AUTH_SCOPE`，再按需运行 `window-interaction`；不要把旧的进度读取授权当作
交互信息授权。规则集快照同时携带由同一 owner 读取边界产生的 `STREAM_ID`，可作为
`observe` 的初始 cursor 身份。

## 正常 VoiceOver 使用（macOS，2026-11-02）

本消费者提供 VoiceOver 操作入口。以下用法结合不同版本与实例的验收记录，不代表最终 SDK
在一次运行中完成了全程无辅助聚焦的 VO 操作链。文字、布尔、应用/取消沿用 renderer
`19c06921`、PID 34864 的记录，其中包含普通 Tab/Space、剪贴板及输入源/前台修正；
该链业务保存由公开 `SAVE_RULE_SET` 客户端触发。

最终 renderer `eda3a550`、应用 `c888abe5` 的 PID 88443 记录了 VO-I 选取“保存”、
VO-Right 落焦、VO-Space 保存：149 B 文件重写同字节，mtime 更新。最终退出守卫先经
AX 设置焦点，再由 VO-Space 激活关闭；独立包装实例 PID 90050 记录 exit 0。
运行来自 `41472b6b`，交付 `eb58ceb9` 是相同编译源的 README 重导出。

- **定位目标。** 用 `VO-I` 打开项目选取器，方向键移动、Return 选中、`VO-Space` 激活。
  项目选取器是分层列表：先选容器，再进入其子项；行内的“选择”“启用”“应用”等按钮在行子树中。
  选取器的筛选框可键入 ASCII；一次本工具尝试中 `⌘V` 未粘贴剪贴板而输入了字母 `v`，
  只记该次工具现象，不概括为 VO 或系统不支持粘贴。
- **虚拟列表。** 列表按可见/聚焦行物化，未聚焦的远端行不必全部常驻，也不保证都出现在项目选取器里。
  用 Tab/Shift-Tab 或行内普通方向键把焦点移入某行后，该行会进入 AX 并可被 VO 读出；
  这是正常的虚拟化交互，不是投影遗漏。普通 Down 只移动到下一个可聚焦位置，不能单独作为
  “列表导航失败”的证据。
- **编辑弹层。** 在行内激活“编辑”后，弹层会读出当前 owner 的名称与值。名称文本框和“启用”控件
  只修改该 owner；`应用` 提交草稿，`取消` 丢弃草稿并保留已应用值。关闭弹层后 VO 回到触发行的
  正确目标。编辑期间可用公开客户端 `generated-fields --owner N` 读回
  `DRAFT_HEX` / `APPLIED_HEX` / `VERSION`，同时核对两个 owner 没有被串写。
- **退出守卫。** 有未保存界面文档时，`⌘W` / `⌘Q` 打开可访问保护条，读出标题、原因和
  `保存界面并关闭` / `放弃界面变更并关闭` / `取消关闭`。VO-Space 激活“放弃界面变更并关闭”后
  日志出现 `RULE_SET_UI_CLOSE ... close_permitted` 与窗口销毁；取消关闭只收起守卫，
  不出现 `destroy complete`，应用继续可编辑。
- **读出可靠性。** VO 字幕面板显示实际朗读文本，但截图可能滞后；定位用项目选取器/AX，
  业务状态以 shared-operation 快照和文件字节为准。字幕面板按需要开启；验收改动后恢复既有设置。
- 已验范围按上述版本与实例区分；本包未验证其他平台和其他输入法组合。
