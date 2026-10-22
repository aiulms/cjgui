# 创建、运行和接入混合表单

可选字体资源模式：`./run.sh --fonts`（包含公共组合入口）。手写 Georgia、生成 Lilex 与同 owner 的多行只读字段
共享原文字链；点击“字体换版／缺失回退”后，`client.py DESCRIPTOR font-switch --font-resource preview-mono`
提交引用目录当前版本的结构。`font-switch --font-resource preview-serif` 可选择已公开的系统字体；`reorder` 保留同 key。
字体改变和生成结构调整不写业务草稿。`--check-font-resources` 是同二进制资源/声明检查，不能代替正常 GUI 验收。
字体和 OFL.txt 由原 runner 相对打包；应用窗口正常关闭后，原 finally 关闭资源 registry。
完整公共契约见框架 `FONT_RESOURCES.md`，实际支持仍为 experimental macOS；不承诺旁白或其他平台。


Experimental，当前交付 macOS / Cangjie 1.1.3。此模板是内存中的打印预设示例；退出后重新初始化，不是生产数据库。独立客户端是真实公共调用，没有使用模型服务。

可选公共组合模式：`./run.sh --commands`。这仍默认离线；原手写字段可直接编辑。
工具栏、⌘P 操作面板、操作按钮的右键菜单与原生菜单投影同一组命令，Apply／Reset 的标签、
可用状态与禁用原因来自原表单 owner。⌘S 应用，⌘R 恢复已应用值，⌘T 切外观，⌘K 查看说明。
主题 checked 状态只属于呈现，业务动作仍经过原 writer。菜单和面板取消／返回复用框架恢复，不复制输入状态机。

此模式同时展示同一份数声明的整数步进和滑块、原布尔字段、公共错误汇总与字段帮助、
完整语义文本的最多两行省略、共同字距／行高，以及 catalog 声明的 PNG。
点击“开启本地协作”后，`client.py generate` 再按实际目录创建同字段的生成编辑器、滑块及图片；
`client.py reorder` 保留 key 调整真实结构。手写／生成区都不存第二份业务草稿。
`--commands --collaboration` 可以显式组合启动；两个选项均非默认。

`python3 client.py DESCRIPTOR check-refusal` 用错误 capability 做一次真实拒绝读取，
typed client 必须具名报错，并核对原 owner 未变化；不打印连接凭据。
生成图片 key／版本与字段／动作均由目录发现；资源路径只在应用声明和 bundle 配置中。
常态不启用 Inspector、录像或成本采集；`--check-composition` 只检查同二进制的命令可用状态／原 owner 保持规则，不等于 GUI 验收。

普通构建需要 Apple Command Line Tools/macOS SDK 及 Python 3.11+。`run.sh` 自行固定本应用的 native 归档，使用标准 cjpm 构建，不要求私有重链脚本；构建配置、只读仓颉输入快照与实际链接身份保存在 `.cjgui/macos-build`，原源码仍从 `src` 与框架目录修改。同一应用/target 的构建与测试须串行。

从框架根目录创建（父目录须存在，目的目录须不存在）：

```sh
zsh scripts/create_macos_application.sh mixed-form "/你的目录/My Print Tool"
cd "/你的目录/My Print Tool"
export CANGJIE_HOME="/你的 Cangjie 1.1.3 目录"
./run.sh
# 只构建：./run.sh --build-only
```

`ui-only` 与 `collaboration` 原入口继续可用。`run.sh` 通过 `cjpm.toml` 声明的框架及 `shared_operation_core` 源构建，原生编译和 App 打包由既有 macOS runner 完成。可执行 App 在 `target/release/CJGUIMixedFormStarter.app`，也可直接打开；构建中间产物不是源码依赖。

默认直接编辑左侧手写区域，无需任何服务。点击“开启本地协作”才启动现有本地连接；终端 `DESCRIPTOR_PATH` 是当前进程的私有连接文件，关闭后失效。也可用 `./run.sh --collaboration` 明确开启。示例授权只允许已声明的本领域操作，请勿发布连接凭据。

把 `DESCRIPTOR` 换为日志中的实际路径，在另一终端运行：

```sh
python3 client.py DESCRIPTOR inspect
python3 client.py DESCRIPTOR generate
python3 client.py DESCRIPTOR set --field duplex --value false
python3 client.py DESCRIPTOR reorder
python3 client.py DESCRIPTOR read
python3 client.py DESCRIPTOR cancel
python3 client.py DESCRIPTOR apply
```

`generate` 先发现公开字段/动作再提交实际节点；`reorder` 移动已经接受的树，保留 key/binding。聚焦生成输入后重排，直接续写仍进入同一草稿。`set` 和 `apply` 使用同一公开业务操作；错误由原 owner 返回，不用客户端猜业务范围。命令支持 `--output result.json` 留存完整结果。连接由现有 Application 接管关闭并在同一业务线程有界泵送；主窗关闭后统一关闭可选 Inspector 和连接，不另起业务线程。

接入自己的业务只改三处：

- `src/domain.cj`：字段及约束只在 `formBinding()` 的声明中出现一次；校验读取这份声明。实现既有 `CjguiSharedEditableFormDomain`，保留一个真实草稿/已应用 owner，按自己的业务决定 Apply、版本和持久化。
- `src/main.cj`：用 `cjguiComposableBoundFormField` 画手写字段、公共 `CjguiNumericStepper` 画整数编辑与步进，均消费相同声明和 owner；调整容器/样式即可换布局。`CjguiGeneratedUiFormBinding` 读写原领域；其 `capabilityCatalog()` 提供可选标准表单词汇。若需要其他组件，用已有 catalog 注册接口，自行选择允许的范围。
- 动态区继续用 `CjguiGeneratedUiWindowRegion`；将 scene refresh 和事件委派给 region，再将手写事件交给 form binding。TEXT 绑定范围会话，宿主须启用模板已有的 `rangeTextEditDeltaDelivery: true`，避免将整值预览误作另一笔写入。窗口焦点/选择、输入队列、候选接受和完成协议都由已有框架负责。业务变化不需要修改 native。

字段 TEXT / INTEGER / BOOLEAN、标签、必填、长度、数字范围和动作签名供手写、生成和外部发现共同消费。只读文本可用 `textMaxLines` / `textOverflow`，完整业务值不截断。此模板不承诺其他平台宿主、任意并行业务数据库、真实模型生成或完整 IME 验收。

同字段多视图连续编辑也使用上述入口：保持当前 TEXT 聚焦时运行
`client.py DESCRIPTOR set --field jobName --value Package`，正常刷新会把同一 owner
的值投影到两区和原生输入代理，下一笔系统输入直接以该值为基线。无需换焦点、
轮询字段或写同值 setter。控制器须把全部字段的 FOCUS 事件（包括手写区）交给
同一个 region，再调用 `form.handleFormEvent`；现有范围会话绑定和完成路径处理输入。

`draftFieldVersion` 表示该字段的输入基线，不是整份表单事务版本。模板中的
`fieldVersions` 只随相应字段的写入/实际还原推进；修改 copies、duplex 或 Apply
不会使 jobName 的既有选区过期。`draftVersion` / `contextVersion` 仍按原事务推进，
外部操作继续执行 CAS。全值写入后的选区沿已有 source/窗口政策；本适配器不推测旧选区
在新文本中的位置，不提供跨版本 rebase。

非法中间值（例如 copies=0）保留在草稿并显示校验，Apply 明确拒绝且不改变已应用值；
修正后才可提交。过期请求可用 `--expected-draft-version N` / `--expected-version N`
显式指定，结果在 JSON 的 `action` 中；命令能返回 JSON 不代表业务已接受。

校验与动作反馈也共用 owner：一次 `form.formFeedback()` 保留原
`CjguiSharedFormSnapshot`，手写字段和 `region.buildNode(feedback: Some(feedback))`
消费这一份快照。生成字段复用同一个 `cjguiComposableBoundFormField`，错误文字、
错误样式及 Apply 的可用条件与手写区一致；非法草稿仍可编辑，Cancel 恢复原已应用值。
无需在应用或生成描述里再写一遍校验规则。

公开 Python `GeneratedUiSession.form_state()` 使用原 `GET_GENERATED_UI_FIELDS`
一次读取，返回 `known`、`consistent`、owner/草稿/已应用版本、`can_apply`、
`message`、`fields` 和 `actions`。`client.py read` 的 JSON 直接包含 `form_state`
及同次读取的 `fields` / `actions`；动作带 `available`、`blocked_reason` 和判断版本。
每个字段的 `validation_state` 为 `valid` / `invalid` / `unknown`，
`validation_error` 为 owner 原文，`validation_version` 为判断时的 owner 版本，
`field_version` 为该字段输入基线；可编辑性 `available` 与校验结果独立。

## 可读的普通组合组件（两张活预设卡）

`client.py generate` 在 `presetCard` 声明下提交两张卡，每张卡声明**五个 child**（顺序是应用契约）：
标题、说明和三个字段标签。它们是框架分配的普通只读文本节点，样式引用应用登记的命名样式
`preset-card-title` / `preset-card-note` / `preset-card-field-label`——这些定义由当前主题在每个 build
重新发布，所以切换外观（⌘T 或工具条按钮）会重绘已接受的卡，不需要重投结构。

字段、错误、锁定原因和“草稿与已应用值一致”的状态来自框架的只读 `projection` 元素：
`field_error`（逐字段校验）、`field_reason`（owner 拒绝编辑的原因，例如卡片锁定）、
`action_reason`（动作被拒原因，例如无未应用修改）和 `owner_status`。它们都从该实例**同一份**
冻结 owner 快照解析，值/错误/锁定更新只刷新投影，不重提结构；owner 没有文本时工厂可以不挂该节点。

可编辑性只有一个答案：当 owner 报告字段不可用时，文本、整数、布尔三种编辑器的场景状态和
AX 状态都为不可编辑，工厂若把被 block 的字段仍挂成可编辑控件，扩展会以
`composite_element_availability_mismatch` 拒绝；只读副本（普通文本）不受影响。
每张卡的业务 owner（6301/6302，换绑后 6303）与手写区共用同一字段/动作声明和同一 owner 事实。

此接口及字段均为 experimental；旧 binding 默认 `formFeedback() = None`，旧协议
即使含 `ERROR none` 也只得到 `validation_state=unknown`，不能推断校验通过。
原 `fields()` 及 FIELD 前缀/既有 token 保留，新 token 为增量扩展；未接入原子表单快照的
provider 若在读值期间改版，本次返回 `consistent=false` 且不发布拼接字段，不重试或等待。
共同协议/投影可供其他平台接入，本簇只验 macOS 自绘宿主和上述正常消费者。


本版模板的 Wrap 工具栏／操作栏、公共状态消息和可选 Inspector 只接既有组件。
步进读字段声明的 minimum/maximum，调用公共 resolve 后进入原 owner writer；拒绝保留原值。
⌘K 打开普通说明弹层，Esc／“返回编辑”由框架恢复原字段和选区；⌘S 应用内存草稿。
Inspector 默认关闭，开发按钮显式打开；普通运行无需该副窗，也不启成本采集。
生命周期由同一个 `CjguiMacosApplication` 负责，主窗关闭后 finally 关闭副窗和连接。
这些是应用声明和普通操作接线，没有额外编辑／焦点／候选状态机。

## 公共多样式文本

`./run.sh --styled-text` 启动自动高度的多字体/字号说明；`client.py DESCRIPTOR styled-generate` 读取同一 `assets/styled-description.tsv`。`styled-color` / `styled-size` / `styled-font-current` 修改原声明并保留完整正文和 owner。窄窗生成操作按钮按列排列。双窗口与结束核对入口见 [STYLED_TEXT.md](../../../STYLED_TEXT.md)。
