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
- [混合表单](framework/cjgui/templates/macos_application/mixed_form/README.md)：同一 owner 的声明字段、公共整数步进、Wrap 布局、状态反馈、说明弹层及可选 Inspector；更改字段、范围、动作和布局只改应用源码。示例为内存数据，Apply 不等于持久保存。
- [布局](framework/cjgui/LAYOUT_PRIMITIVES.md)、[字段与反馈](framework/cjgui/FIELD_CONTROLS.md)、[卡片](framework/cjgui/CARD_GRID.md)：公共实现与限制，沿用同一仓颉布局和渲染链。
- [集合与键盘／Inspector](consumers/generated_collection/README.md)：已有薄消费者包含列表／表格、同 key 生成重排、公共键盘接线与默认关闭的 Inspector。其演示客户端使用应用发出的本地 descriptor，没有模型服务。
- [规则集消费者](consumers/rule_set_window_app/README.md)：字段、状态及集合组件的较完整既有消费；源码随包，不要求把其整份程序复制成新应用。

所有新增接口均为 experimental，按当前声明消费，不承诺跨版本源码或二进制兼容。手写／生成界面共用字段、动作与 owner；公开描述只能引用应用登记的组件，不能提交源码、native 指针或另起一份业务状态。

## 消费证据与保留边界

`source-manifest.json` 给出这一包的精确内容身份；包外普通组合应用的构建来源、可启动候选和连续链原件与交付一同保留。
此前规则窗口、Inspector、键盘、图片、AX和成本证据只按各自版本复用，不当成本次包外消费通过。
声明构建的局部收益不外推总体时延或RSS，本包未重跑旧性能矩阵。

实际 VoiceOver 导航／朗读／激活仍未验证：工具路径 not_verified，远程用户真人检查 not_run。AX 查询及服务能启动都不构成通过。其他平台宿主、全 IME、GiB、严格性能和物理呈现延迟未纳入本包；既有 native 窗口 harness 的失败也没有因整合而改绿。不宣称框架全部成熟或全面性能达标。

`source-manifest.json` 是一份扁平的实际导出清单，列源／导出哈希和文件大小；构建后的 `.cjgui/macos-build/build-provenance.json` 标明真实编译输入与链接成员。普通 runner 从本包源码构建，无作者临时目录、验证宏、私有重链或预置缓存依赖。完成的 App 携带必要运行库，可在本机启动；仅 ad-hoc 签名，未公证、未远端发布。
