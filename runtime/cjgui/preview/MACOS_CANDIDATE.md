# CJGUI macOS 统一开发候选

本批是 experimental 源码开发候选，不是 1.0、stable SDK 或稳定 ABI，包版本号未改变。面向 Apple Silicon macOS；构建需要 Cangjie 1.1.3 cjnative、Xcode Command Line Tools／有效 macOS SDK、Python 3.11+ 和 zsh。SDK 不随包提供。runner 的最低部署目标为 macOS 12，实际消费只验证当前宿主，不代表全部旧系统可用。

本批将已交付的公共布局、字段／反馈、集合表格／卡片、窄窗滚动、模态选区返回、只读文本溢出和 native 静态文字资源复用纳入同一源码闭包。手写与生成投影继续共用现有 catalog、绑定和 owner；不要求开发者拼接历史阶段差量。`source-lock.json`（format 2）冻结的是**交付闭包**——共同源、native `.m/.h`、`build.cj`、脚本、配置、模板与资产逐项原始哈希；新并行叶子模块或先行漂移的 native/脚本不自动进入该候选，并会在导出时具名拒绝。

本批同时交付**普通可读的组合组件**：同一 `presetCard` 组合通过既有 `children`（受框架分配身份的只读文本和命名主题样式）显示标题、说明与逐字段标签，通过框架新增的只读 `projection` 元素显示 owner 自己的逐字段错误、锁定原因与业务状态；两者都从该实例同一份冻结 owner 快照解析，值/错误/锁定更新不重投结构。owner 禁止编辑时，三种编辑器（文本、整数、布尔）在场景状态与 AX 上同时为不可编辑；工厂若把被 block 的字段仍挂成可编辑控件，扩展会以 `composite_element_availability_mismatch` 拒绝。主题切换（⌘T/按钮）在已接受场景上重绘卡片，不需要重投结构。

升级已有应用只替换 SDK 依赖；若应用自带复合工厂，需把 `ownerAvailable` 传给可编辑控件的 `enabled`（见快速开始“升级已有应用”）。

当前普通组合入口是 `mixed-form` 创建后运行 `--commands`：同 owner 的工具栏、面板、操作按钮上下文菜单、主题、
错误/禁用反馈、semanticHelp、滑块/布尔、公共图片与排版均在同一应用中消费。协作仍由显式入口开启；
typed client 的生成、结构调整、外部写和拒绝检查不使用模型服务。`ui-only` 和独立 `command-surface` 保留。

## 可以直接采用的入口

- [快速开始](README.md)：公开创建、普通构建、启动、显式开启协作及客户端读回。
- [混合表单](framework/cjgui/templates/macos_application/mixed_form/README.md)：同一 owner 的声明字段、公共整数步进、Wrap 布局、状态反馈、说明弹层及可选 Inspector；更改字段、范围、动作和布局只改应用源码。默认使用内存数据；可选工作会话显式保存卡片 A/B 的草稿与已应用值，Apply 不等于写文件。
- [业务工作会话](framework/cjgui/MACOS_APPLICATION_HOST.md#business-work-sessions)：Experimental 的有界保存/载入与可信文件基线；应用定义 schema 和恢复规则。mixed-form 与 UI-only 使用同一接口，新进程创建新窗口和端点，布局文档分别保存。
- [布局](framework/cjgui/LAYOUT_PRIMITIVES.md)、[字段与反馈](framework/cjgui/FIELD_CONTROLS.md)、[卡片](framework/cjgui/CARD_GRID.md)：公共实现与限制，沿用同一仓颉布局和渲染链。
- [集合与键盘／Inspector](consumers/generated_collection/README.md)：已有薄消费者包含列表／表格、同 key 生成重排、公共键盘接线与默认关闭的 Inspector。其演示客户端使用应用发出的本地 descriptor，没有模型服务。
- [规则集消费者](consumers/rule_set_window_app/README.md)：字段、状态及集合组件的较完整既有消费；源码随包，不要求把其整份程序复制成新应用。

所有新增接口均为 experimental，按当前声明消费，不承诺跨版本源码或二进制兼容。手写／生成界面共用字段、动作与 owner；公开描述只能引用应用登记的组件，不能提交源码、native 指针或另起一份业务状态。

## 消费证据与保留边界

`source-manifest.json` 给出这一包的精确内容身份；包外普通组合应用的构建来源、可启动候选和连续链原件与交付一同保留。
此前规则窗口、Inspector、键盘、图片、AX和成本证据只按各自版本复用，不当成本次包外消费通过。
规则集版本读取复用同锁的版本接口，去掉无谓的全量复制/序列化；局部查询收益不外推总体输入时延或 RSS，普通负载与资源结论以对应身份的原件为准，不重跑无关旧矩阵。

当前源增加了最终退出的纯预检与批量提交、当前 owner 的命令可用性核对、独立卡片的单调场景版本，以及应用轮次外直接刷新的预算边界修复。正常 mixed 消费已覆盖末键紧接 Apply/Cancel、系统组合输入提交、最小化副窗参与退出、取消后续写和分别保存业务／界面文件。固定十轮资源消费保留相同窗口、生成结构、图片／文字／效果替换及滚动，使用真实完成帧和资源引用检查排空；缓存驻留与在途引用分别报告，不以 RSS 或进程退出替代资源证据。

输入关联与效果资源观测是有界、显式开启的诊断；默认关闭。Rules 的真实 writer 返回已通过同一事件、执行线程与 dispatch cookie 直接关联到原始接收和分派；owned token 为零不影响这条独立关联。旧 O0 两组各 5 笔与 `fc3f3390`／`7f54a715` 同一编译闭包的 O2 名称输入 20 笔分别有原件，不能将它们混成一次验收。筛选、选择和滚动按各自的真实状态与交互完成点判断，不虚构文本 writer。

上述 O2 基线 App `7d03ad97` 的同会话四类各 20 次诊断，保留全部投递、一次未投递的目标 guard 和合批。筛选与名称各 20 笔取得同一 drawable 的非零原始 presentedTime，接收至呈现 p95 分别为 65.521／66.340ms，均未达到 32ms；该会话同时开启 phase 诊断，不代表默认关闭诊断时的性能或优化收益。滚动仅 1 笔取得非零呈现，其余 19 笔及选择 20 笔原值为零，仍为 unknown。选择中的 7 个双成员批次各来自同一原输入的 focus 与 activate；共同的 batch 场景不等于两个独立业务选择完成。旧样本未逐笔读取 collection 选择权威，不能补写各笔选择版本。接受场景、回调到达、GPU 完成或下一帧不能替代原始呈现值。

优化闭包 `8769ddf8`／App `f81aa540` 的另一轻量 ON 会话，仅开启现有输入关联、writer 与 cadence 三门，筛选／名称各 20 个原语义动作均只投一次。固定驱动的名义命令发起间隔为 100ms，实际子进程耗时 106–307ms 及全部迟延保留；计时段不夹模型、截图、AX 树或外部状态查询。这与上述逐工具停顿的重型 ON 会话属于不同条件，不能相减为源码收益。40 笔均闭合同 drawable 的非零实际呈现：筛选／名称接收至呈现 p95 为 77.445／61.184ms，共 37/40 超过 32ms。筛选处理返回界与名称 writer 向下量化观测点的 p95 分别为 4.044／9.317ms；名称实际采样时刻在观测点至其后 1µs 的半开区间，严格保守端点应取后者，不能把向下量化值称为 ns 上界。相邻分段共用该边界与量化不确定度，不能分别加 1µs 后仍声称精确加和。首个筛选 25.539ms 慢样本保留。提交至呈现是 36/40 样本中的最大分段，drawable 获取中位约 24µs、GPU 执行中位约 1.6–1.7ms；GPU 结束至呈现的间隔仍未归因，不称必要 GPU 等待或精确系统根因。本段 p50 使用 nearest-rank（20 笔中的第 10 项），并非两个中间值的均值；各分段 p95 不相加，也不外推默认 OFF。

滚动请求与实际接受必须核同一 viewport 和代次。现有 `GET_WINDOW_INTERACTION` 是读取时的偏移／pending 快照，不携带请求代次；`GET_TREE_SELECTION` 需区分 tree 与 collection scope，版本变化也不单独证明选择对象改变。源码在既有默认关闭的 `CJGUI_FOCUS_SCROLL_TRACE` 门内提供目标 viewport 身份、请求／接受代次、scene、单调时钟及 requested／accepted／pending，沿用 128 行上限。只有同窗口、原 raw／ordinal、同目标和真实提交阶段闭合时，才能据此判断接受、后续请求或 no-change；被新 raw 打断、缺行或上限截断仍为 unknown。该诊断不增加公共完成协议，不改变滚动、选择或调度状态。

正常 Rules 已取得真实 VoiceOver 导航、读出和激活证据，使用方法见[消费者说明](consumers/rule_set_window_app/README.md#正常-voiceover-使用macos2026-11-02)。证据按版本和实例区分：文字／布尔编辑与 Apply/Cancel 归 renderer `19c06921`／PID 34864，其中包含普通键盘和辅助聚焦；最终 `eda3a550`／App `c888abe5`／PID 88443 经 VO-I 选取保存、VO-Right、VO-Space 重写同字节的 149 B 文件。该实例的退出守卫先经 AX 聚焦再由 VO-Space 激活，独立 PID 90050 记录 exit0。运行来自 `41472b6b`，`eb58ceb9` 是相同编译源的说明重导出；不称最终 SDK 一次完成全程无辅助聚焦的 VO 编辑链，也不把 AX 查询或服务启动当作旁白通过。

本次系统输入短链复用 `fc3f3390` 编译闭包，正常 mixed App `dea711f8`／PID 96799、三包实际 O2、默认成本诊断关闭。在当前微信拼音中，一次原生 n 产生真实 marked 预编辑；一次 Escape 取消后，完整双 owner 正文／版本及 UTF-16 6..8 选区不变。说明层返回后首个 9 无补焦地替换所选 emoji；外部旧 draft CAS 被拒且两 owner 不变，B 完成 Apply／临时编辑／Cancel，A 保留未应用草稿。一次保存的 738 B 业务会话独立解码一致，随后正常 Quit／明确放弃界面变更，自然 exit0、端点清理。此增量限单行 TEXT 的 owned 范围入口与当前宿主／输入源；多行、整值和旧系统提交证据仍按原版本复用，不外推全部输入法、提交／取消组合或迟到交错。

无系统组字时，输入代理消费单行 TEXT/INTEGER 的 Return，多行换行和组字交由系统文本服务处理。`composable_focused_input_skip_test` 覆盖这三种分派。正常 mixed-form 窗口中，整数框 `copies` 已输入 `42`，随即连续按 Return 和 `3`，两键之间没有补焦或等待读回。结果为 `423`，AX 焦点仍在原整数框，插入点为 3。该次输入证据来自 EXE `dc6e23fc…`，进程由 300 秒超时回收。普通文本框 `jobName` 已有真实字符输入记录，其 Return 后继续键入的路径仍待独立实测。

系统 IME 只按已验通道陈述，完整覆盖及严格默认 OFF 的 16/32ms 门仍未完成；其他平台宿主和 GiB 不由本 Mac 包推进。既有 native 窗口 harness 的失败没有因整合而改绿。不宣称框架全部成熟或全面性能达标。

`source-manifest.json` 是一份扁平的实际导出清单，列源／导出哈希和文件大小；构建后的 `.cjgui/macos-build/build-provenance.json` 标明真实编译输入与链接成员。普通 runner 从本包源码构建，无作者临时目录、验证宏、私有重链或预置缓存依赖。完成的 App 携带必要运行库，可在本机启动；仅 ad-hoc 签名，未公证、未远端发布。
