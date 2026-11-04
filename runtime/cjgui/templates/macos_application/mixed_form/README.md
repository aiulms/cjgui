# 创建、运行和接入混合表单

### macOS 测试依赖闭包

`input_route_test.cj` 与 `primary_route_regression_test.cj` 使用框架的
`macos_owner_fixture_test.cj`，由 AppKit owner loop 托管真实 controller/window fixture。
开发树中的 `native/scripts/verify_cjpm_mac_testing_link.py --consumer` 会把框架源改写为
消费者包名并注入隔离测试包；导出的 SDK 则在本模板 `src/` 中携带同一 helper 的包名改写副本，
因此从 SDK 创建的应用仍能直接解析这些模板测试。helper 是仅供测试的输入，不属于生产源码集合；
native-backed 测试须链接 testing archive，正常 archive 与标准 Cangjie test runner 的职责不变。

SDK 自带消费者测试入口及其依赖（`macos_build_config.py`、sidecar builder、source-set
helper）。从解压后的 SDK 根直接运行包内 driver；`--consumer` 指向用该 SDK 创建的应用。
应用构建/测试仍要求本机 Cangjie 1.1.3 和 macOS SDK 环境。三个 filter 分进程运行：

```sh
python3 framework/cjgui/native/scripts/verify_cjpm_mac_testing_link.py \
  --runtime framework/cjgui --consumer "/你的目录/My Print Tool" \
  --filter '*mixedRouteOwnedWhole*'
python3 framework/cjgui/native/scripts/verify_cjpm_mac_testing_link.py \
  --runtime framework/cjgui --consumer "/你的目录/My Print Tool" \
  --filter '*mixedRouteWholeValue*'
python3 framework/cjgui/native/scripts/verify_cjpm_mac_testing_link.py \
  --runtime framework/cjgui --consumer "/你的目录/My Print Tool" \
  --filter '*mixedRoutePrimaryWhole*'
```

可选字体资源模式：`./run.sh --fonts`（包含公共组合入口）。手写 Georgia、生成 Lilex 与同 owner 的多行只读字段
共享原文字链；点击“字体换版／缺失回退”后，`client.py DESCRIPTOR font-switch --font-resource preview-mono`
提交引用目录当前版本的结构。`font-switch --font-resource preview-serif` 可选择已公开的系统字体；`reorder` 保留同 key。
字体改变和生成结构调整不写业务草稿。`--check-font-resources` 是同二进制资源/声明检查，不能代替正常 GUI 验收。
字体和 OFL.txt 由原 runner 相对打包；应用窗口正常关闭后，原 finally 关闭资源 registry。
完整公共契约见框架 `FONT_RESOURCES.md`，实际支持仍为 experimental macOS；不承诺旁白或其他平台。


Experimental，当前交付 macOS / Cangjie 1.1.3。不带 `--work-session` 时，打印预设示例只保存在内存中并在退出后重新初始化；显式启用业务工作会话时，仅卡片A/B的草稿与已应用值可保存。此功能不是生产数据库。独立客户端是真实公共调用，没有使用模型服务。

可选公共组合模式：`./run.sh --commands`。这仍默认离线；原手写字段可直接编辑。
工具栏、⌘P 操作面板、操作按钮的右键菜单与原生菜单投影同一组命令，Apply／Reset 的标签、
可用状态与禁用原因来自原表单 owner。⌘S 应用，⌘R 恢复已应用值，⌘T 切外观，⌘K 查看说明。
主题 checked 状态只属于呈现，业务动作仍经过原 writer。菜单和面板取消／返回复用框架恢复，不复制输入状态机。

此模式同时展示同一份数声明的整数步进和滑块、原布尔字段、公共错误汇总与字段帮助、
完整语义文本的最多两行省略、共同字距／行高，以及 catalog 声明的 PNG。
窗口内还挂载“主详情布局”和“辅助摘要布局”两个独立文档工作区：各自有真实 Surface、
session 和界面文件，关闭前由同一保护检查全部工作区的未保存界面/在途票据，再进入业务
关闭策略；保存界面不会应用业务草稿。路径输入、打开和另存始终可用，空路径保存具名拒绝，
已有其他目标不覆盖。
点击“开启本地协作”后，`client.py generate` 再按实际目录创建同字段的生成编辑器、滑块及图片；
`client.py reorder` 保留 key 调整真实结构。手写／生成区都不存第二份业务草稿。
`--commands --collaboration` 可以显式组合启动；两个选项均非默认。

协作连接启用时，应用显式授权只读 `GET_WINDOW_TARGETS`、`GET_WINDOW_PROGRESS` 和
`GET_WINDOW_INTERACTION`，并把当前 `CjguiMacosApplication` 注册为窗口目标目录与定向进度提供者。
这不是框架默认权限，也不授予 `GET_WINDOW_CONTEXT`。先用 `window-targets` 读取本连接当前的
opaque 窗口标识，再把该值显式传给进度或交互读取；已关闭、过期或不属于此连接的 target
由应用以 `unknown_window_target` 拒绝，格式错误的 target 由客户端在发送前拒绝；两者都不回退
到其他仍打开的窗口：

```sh
python3 client.py "$DESCRIPTOR" window-targets
python3 client.py "$DESCRIPTOR" window-progress --window-target "$WINDOW_TARGET"
python3 client.py "$DESCRIPTOR" window-interaction --window-target "$WINDOW_TARGET"
```

每个结果保留原始响应和 typed entries；窗口进度至多含四条视口摘要，交互读取只投影焦点、
选择与活动层。它们是同一 target 的只读状态，既不选择业务卡片，也不执行 Apply。
权限未授予时返回 `unauthorized_action`，target 不再存活时返回 `unknown_window_target`。

可选业务工作会话：`./run.sh --work-session "/你的目录/print-presets.session"`。该选项在
新进程创建 endpoint 前读取并校验应用 schema，再恢复 cardA/cardB 两个稳定 owner 的 draft、applied
基线、字段/业务版本和 A/B 选择；不会 Apply 草稿，也不会恢复旧窗口、endpoint 或 ticket。当前界面显示五张卡，
但业务会话只保存卡片A/B，其他卡片不纳入保存并在新进程中重新初始化。工作区按钮和 File 菜单的
“保存卡片A/B工作会话”都会显式保存。关闭时若卡片A/B业务会话有未保存改动，会显示保存卡片A/B并继续关闭、
放弃卡片A/B未保存会话并关闭、取消关闭三项；关闭说明和状态也标明保存范围。保存失败会留在窗口并保留原文件。
路径不存在时按新会话启动，不显示 `file_read_failed`；路径已存在但读取或校验失败时明确显示未载入且不采用文件内容，
旧文件保持不变。无参数时此功能完全关闭，原有关闭流程不变。会话文件最大 32 MiB，并与主/摘要界面文档分别保存。

启用后可从另一终端用 `python3 client.py DESCRIPTOR work-session-readback` 一次命令逐 owner 读取两个 owner 的
applied/draft、dirty、版本、Apply/Cancel 可用性及当前新 endpoint identity。继续操作仍走公共 owner：
`card-set --instance cardA|cardB --field jobName --value "新草稿"`、`card-apply --instance cardA`
或 `card-cancel --instance cardA`。截断/长度不匹配、无效 UTF-8、错 schema、业务 owner/schema
不匹配及尺寸超限都会拒绝载入且不部分改写已有内存状态；载入后若文件被外部改写，保存会拒绝覆盖。
envelope 提供版本、长度和严格应用校验，没有 checksum 或 tamper-authentication 保证。

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

read --instance KEY 或 read --owner ID 把选择交给同一 typed 请求；输出完整的
form_state、逐字段 owner_resource_id/draft/applied/draft_version/state_version/field_version，
以及已有的可用性、blocked/validation 原因。相同字段名属于不同 owner 时分别保留；
缺失正文/版本输出 null，旧投影未发布的 owner 仍为 -1，不据此推断真实 owner 或版本。
读取不会执行编辑。公开示例也按完整 typed 字段读取，不把字段名当成跨 owner 唯一键。
有效请求被端点拒绝时，--output 仍保存已取得的submit/terminal及错误code/版本/target，未取得的form_state/fields/actions为null，退出码1；不会换成默认owner的成功值。card操作也透传显式expected版本，用于真实的过期请求拒绝。

文档启动只调用 documentWorkspace.beginStartup(path)；普通 turn 对两个 workspace
调用 finish()，关闭使用原 close guard。准确票据、实际文件观察和终态留在同一个
session；应用无需复制启动观察者。同步启动预算结束后仍由普通 turn 完成原操作，
不会重投或用默认生成候选抢占。业务类继续负责草稿/已应用值和持久化；此内存模板
保存的是界面定义，不是打印预设数据库，重开进程会建立新的默认业务 owner。

接入自己的业务只改三处：

- `src/domain.cj`：字段及约束只在 `formBinding()` 的声明中出现一次；校验读取这份声明。实现既有 `CjguiSharedEditableFormDomain`，保留一个真实草稿/已应用 owner，按自己的业务决定 Apply、版本和持久化。
- `src/main.cj`：用 `cjguiComposableBoundFormField` 画手写字段、公共 `CjguiNumericStepper` 画整数编辑与步进，均消费相同声明和 owner；调整容器/样式即可换布局。`CjguiGeneratedUiFormBinding` 读写原领域；其 `capabilityCatalog()` 提供可选标准表单词汇。若需要其他组件，用已有 catalog 注册接口，自行选择允许的范围。
- 动态区继续用 `CjguiGeneratedUiWindowRegion`；将 scene refresh 和事件委派给 region，再将手写事件交给 form binding。TEXT 绑定范围会话，宿主须启用模板已有的 `rangeTextEditDeltaDelivery: true`，避免将整值预览误作另一笔写入。窗口焦点/选择、输入队列、候选接受和完成协议都由已有框架负责。业务变化不需要修改 native。

选中对象的手写字段在 `buildSelectedDetail` 清理、重声明 instance alias；这些声明随原 scene 一起准备、接受或回滚，准备时不会使旧 accepted TEXT 源失效。接受换属或移除时，region 复用窗口的输入结算和解绑协议，并退休旧范围适配器；未完成输入仍由原会话保留，不重放到新 owner。窗口若保留旧输入载体，region 不把新绑定写成已安装；实际新聚焦仍须通过完整节点、owner 和版本检查。相同 node id 的其他 region 会话也不归本 region 释放。

字段 TEXT / INTEGER / BOOLEAN、标签、必填、长度、数字范围和动作签名供手写、生成和外部发现共同消费。只读文本可用 `textMaxLines` / `textOverflow`，完整业务值不截断。此模板不承诺其他平台宿主、任意并行业务数据库、真实模型生成或完整 IME 验收。

单行 TEXT/INTEGER 字段的 Return 由框架系统输入代理消费，不写入换行，也不结束编辑；需要换行的正文用
`cjguiComposableMultilineTextInput`，它的 Return 仍由 TextKit 插入换行。系统组字进行中的
Enter/Esc 继续归文本服务，不当作普通单行回车。业务草稿/已应用值和版本归应用 domain；焦点、
UTF-16 选区、候选与组合态归窗口和系统输入代理；外部 `set`/`apply` 走同一个 owner。旧 draft、
旧绑定或旧选择请求按具名拒绝返回，不改正文也不污染另一个 owner。

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

### 虚拟集合的共享视口与稳定 key

本模板的 `presetCards` 集合仍由一份业务集合、过滤器和选择对象提供数据。已接受的
`CjguiGeneratedCollectionView` mount 持有同一 `CjguiComposableUiScrollViewport`；列表行、
滚动区和定向显露不能各自维护偏移。框架的 fixed/variable list viewport overload 与
定向 reveal 是 experimental，完整签名和进度边界见
[`LAYOUT_PRIMITIVES.md`](../../../LAYOUT_PRIMITIVES.md)。

外部客户端可在当前 domain version 上请求显露稳定 key `card30`：

```sh
python3 framework/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json invoke "$DOMAIN_VERSION" REVEAL_CARD_KEY \
  --target 6200 --arg cardKey=card30
```

本应用先在当前活动集合中解析 key，再将请求交给已接受的
`preset-business-collection` mount。回执中的 `reveal_requested_card30_view_data_card30_viewport_preset-business-collection`
只证明显露请求获接受；它不选择 `card30`，不 Apply、不改草稿/已应用值，也不推进
owner/domain 业务版本。客户端要先用上面的 `window-progress` 等待同一窗口的 accepted scene，再读取最多四条
`WINDOW_VIEWPORT` 的 requested/accepted/pending 摘要；这份摘要不带目标 key。随后仍须从
同次已接受树/可见 AX 行身份和有效几何确认 `data:card30` 已可见，最后才由人选择。
仅有 `APPLIED=true`、请求 offset 或 viewport accepted offset 都不能替代该行可见证明。

普通键盘导航从列表的已接受 scroll-area 事件进入。应用先按事件携带的 viewport 与当前
accepted mount 取对应 `CjguiGeneratedCollectionView`，再调用框架的 accepted-view 重载；它按
当前排序/筛选后的稳定 key 导航并请求该 mount 显露。仅当事件被该视图接收且选择键语义需要
业务选中时，应用才走现有 `SELECT_CARD` owner 动作。旧 mount、别的 viewport 或退役目标不
改变业务选择；字段内键盘输入仍沿原字段/range 路由，不会被集合导航分支消费。键盘焦点/显露
请求被接受也不等于目标已显示，仍要独立读取 accepted scene 和目标行的真实几何。

若目标 key 不在当前过滤/排序后的集合中，或 mount/viewport 身份不匹配、已退役，动作应
返回明确拒绝并保留业务选择和 owner。过滤到 `30` 后再清空是一次真实 source 更新；每次
显露都重新读取 domain version 和当前活动顺序。客户端不得用旧版本重试，也不得把 AX
可见性当成业务选择授权。该短链的正常应用验证仍单独记录，不由此文档宣称已通过。

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

`./run.sh --styled-text` 启动自动高度的多字体/字号说明；`client.py DESCRIPTOR styled-generate` 读取同一 `assets/styled-description.tsv`。`styled-color` / `styled-size` / `styled-font-current` 修改原声明并保留完整正文和 owner。窄窗生成操作按钮按列排列。双窗口与结束核对入口见 [STYLED_TEXT.md](<../../../STYLED_TEXT.md>)。

## 会话内界面撤销与重做（experimental）

主界面文档 session 默认示范可选 UI history：32 个完整接受点（含当前锚点）、序列化总量 2 MiB；摘要 surface 未开启。已有应用不传 `historyPolicy` 时保持关闭。工具栏“撤销界面 / 重做界面”与公开客户端同用 workspace、当前 CAS/digest 和准确票据；这是界面声明的历史，不回滚业务草稿、已应用预设、选择或授权，也不占用正文 Cmd-Z。

```sh
python3 client.py DESCRIPTOR ui-history > observed.json
python3 client.py DESCRIPTOR ui-undo --history-baseline observed.json
# 返回 candidate_pending / 退出9时尚未完成；用同一endpoint的现有票据接口观察。
# 接受后重新读取一次 ui-history，再把新观察交给 ui-redo。
```

客户端只把这三项转交公共 `cjgui_generated_edit`，不暗中刷新旧观察或重投。撤销后有新接受修改会裁掉 redo；错过外部版本、条目超限和文件/会话切换有明确边界。保存不持久化历史；正常关闭会断开旧 workspace，重新打开从新会话开始。完整能力事实、拒绝、限制与公共 Python 用法见框架 `shared_operation_core/GENERATED_EDITING.md` 的 Optional UI-document undo/redo。

### 同时有业务与界面未保存时

关闭先检查可选 A/B 工作会话，再检查界面文档。逐步放弃只适用于本次关闭及当时的内容；取消、相关内容/版本变化或保存失败会撤销旧决定，下一次关闭重新检查。放弃不写文件、不 Apply；保存业务不等于保存界面。⌘Q 的参与窗口在全部检查通过前保留各自决定，任一窗口取消或保存失败会撤销这次退出的决定。各文件沿已有独立保护保存，不提供跨业务/多界面文件的原子事务；前面已成功保存的文件不会因后面失败而隐式回滚。

## 有界资源消费检查

`./run.sh --resource-cycles` 在正常应用中执行固定十轮自有窗口、生成区、图片／文字／效果替换与滚动，然后正常关闭。它显式开启资源诊断，不代表默认 OFF 的性能样本，也不模拟键盘或真实模型调用。

每轮检查实际接受的生成节点、已提交效果 pass、完成帧、图片缓存及引用；关闭后的排空同时检查全应用的已观测效果在途目标，不能用主窗的零值替代已关副窗。全应用效果数字只覆盖启用观测后的提交；缓存允许按声明预算驻留。原始报告含 initial、十组 active/drained 和 final，任何中途失败保留已采样本并输出失败终态。

可将完整输出交给 `python3 scripts/verify_resource_cycle_report.py LOG` 独立检查。必须同时核对报告终态与进程状态；单独的退出码、RSS、GPU 完成或这些资源数字均不证明 drawable 已实际呈现，也不证明无限期运行无泄漏。

标准 Cangjie 测试执行目录没有 `.app` 的资源目录。通过 `verify_cjpm_mac_testing_link.py` 运行这两个资源测试时，使用三次 `--test-resource` 显式提供框架 `resources` 下的 `preview-swatch.png`、`preview-swatch.jpg` 和 `preview-swatch-v2.jpg`；驱动记录原件哈希并放入其自有测试目录，拒绝覆盖不同内容的执行产物。普通 App 继续由原 `CJGUI_MACOS_APP_RESOURCES` 声明装入相同资产。
