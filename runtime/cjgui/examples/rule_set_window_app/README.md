# CJGUI 规则集编辑器

这是可用预览的正常 macOS 应用：左侧分页显示任意数量的规则，右侧编辑当前规则的草稿。新增、删除、撤销、重做、保存和应用草稿都经由同一份 `CjguiRuleSetEditingDomain`；窗口行号只是视口位置，不是记录 ID。它使用框架拥有的 [macOS 应用宿主](../../MACOS_APPLICATION_HOST.md)，不再编译 sample launcher 或声明 finish FFI。

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/rule_set_window_app
zsh run.sh --save-as /tmp/rules.cjgui-rules
```

用 `--open PATH` 重新打开已有文件。`PATH` 可以是当前目录相对名；打开/保存会把它固定为同一文件的绝对目标，后续原子的临时写入、租约和冲突复查都使用该目标。启动时会打印一次私有 descriptor 路径；获授权的外部客户端必须先发现 descriptor，再读上下文、读取变化或调用声明的动作。桌面锁屏时不把脚本写文件当成 GUI 验收。

集合视图预设（列表/表格/卡片模式、筛选、排序、列宽/显隐/顺序）使用单独偏好文件，默认是 `--open PATH` 的 `PATH.cjgui-views`，也可用 `--view-preferences PATH` 指定。工具栏“视图预设”保存/切换/恢复默认视图；只有“保存偏好”显式写盘。重开恢复已保存视图，不恢复未提交草稿。接口、格式和边界见 [COLLECTION_VIEWS.md](COLLECTION_VIEWS.md)；公共虚拟卡片网格的用法见 [CARD_GRID.md](../../CARD_GRID.md)。

仅验证普通 bundle 构建与签名而不启动窗口：`zsh run.sh --build-only`。保存写入已应用的规则集；草稿要先“应用草稿”，或使用“取消并重载”明确放弃。关闭未保存窗口会丢弃内存内容，启动参数不会覆盖已经存在的另存为目标。重启后的重复请求保证不延续，调用方应通过 `GET_CONTEXT`/`GET_CHANGES` 读回确认结果。

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
