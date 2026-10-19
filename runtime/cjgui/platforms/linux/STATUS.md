# Linux 第一阶段：实施状态（2026-10-18）

范围：X11 + Vulkan 的第一条真实连续链。本页只记当前可用能力、证据入口与剩余门，
逐笔过程留在各模块的汇报与 `/tmp` 证据目录里，不在这里堆历史。

## 1. 当前真实可用能力（有证据）

| 能力 | 状态 | 证据 |
| --- | --- | --- |
| 整链链接 | **通过**：`cjpm build` 在来宾上 `success`，产出 18,469,560 B 的 `main` | 来宾 `~/cjgui-linux/runtime/cjgui/examples/range_text_window_app/target/release/bin/main` |
| 建窗 | **通过**：900×620 窗口 `CJGUI Range Text Consumer`，`map_state=IsViewable` | `platforms/linux/tests/desktop_input_driver.c find` |
| Vulkan 出图 | **通过**：llvmpipe + `VK_KHR_xcb_surface`，MAILBOX，4 图像 / 在途 2 | 运行日志首行 |
| 自绘场景 | **通过**：7 节点、1974 顶点/帧，`promote` 708 次、`present` 持续 | `CJGUI_LINUX_PRESENT frame=… nodes=7 vertices=1974` |
| **中文显示** | **通过**：窗口内正确显示「这个窗口只用导出的 CJGUI 公共包：自己的 source/sink 覆盖一个普通字节数组。」「中文、emoji 与 ASCII 混排：😀 世界 hello」 | `artifacts/20261018-first-frame-chinese.png` |
| 字体回退 | 通过（native 单模块级）：强制 `DejaVu Sans` → 实际选中 `Noto Sans CJK SC`，渲染逐字节相同 | linux-text 汇报 §4 |
| 指针命中路由 | **通过**：点 (300,175) 正确解析到 node=4 / kind=10 / `binding=true` | `CJGUI_LINUX_ABI hit … node=4 kind=10` |
| 键盘事件到达 | **通过**：按键带正确 UTF-8 文本（`sym=0x68 utf8=1` …） | `CJGUI_LINUX_ABI key_down …` |

## 2. 本轮定位并修掉的两个真实集成缺陷

1. **run 声明必须先于节点入库**：共同层在 `configure` 之后、节点入库之前安装文字
   run 声明（`composable_ui_window.cj:10678` 的 S1 顺序）。按"先查已入库节点"实现会
   在第一次安装就返回 `NODE_NOT_FOUND` → 候选被拒 → 窗口永远不出第一帧。
   修法：run 声明按 nodeId 独立保存，在该节点入库时挂上。
2. **`configure` 不能清掉进行中的私有准备**：共同层顺序是
   `begin → prepare×N → advance → configure → promote`，提交阶段会再发一次同代
   `configure`。原来的实现顺手重置了准备句柄，于是 `promote` 被判 `SCENE_STALE`
   （实测 `promote_enter prep=2 active=0`），候选每轮被 cancel + discard。
   修法：准备进行中且节点数相同时，`configure` 只更新投影版本。

## 3. 输入链定位（2026-10-18 第二轮，已到最后一环）

第二轮把"点不动、打不进"拆成了三个独立原因，逐个定位并修掉前两个：

1. **正文节点没有声明指针交付**（已修）：框架的 `isPointerCapturable` 对 TEXT 系节点
   只看 `style.pointerInteractive`，示例的正文（node 4，多行文本输入）没声明它，
   于是每次点击都被共同层以 `CJGUI_POINTER_BEGIN_REJECT … pointer_interactive=false`
   拒掉。已在消费方给正文样式加 `pointerInteractive: true`——可编辑正文本来就该收
   指针事件，这不是 Linux 特例。修后 `POINTER_BEGIN_REJECT` 归零。
2. **没有初始焦点意图**（已修）：`rangeTextInitialFocus` 在 Linux 原本是空实现，
   窗口文本会话永远拿不到焦点。已按 macOS 同款改为
   `window.requestInitialOwnedTextFocusRestore()`。修后 `restore_composable_selection`
   被调用、代理激活（`key_down … proxy=1`），按键真正落到正文上。
3. **范围意图的承载（最后一环，进行中）**：事件身份已经对了
   （`CJGUI_LINUX_RETURN kind=51 node=4 epoch=1 proj=694`，`bindingEpoch` 与当前投影
   版本都正确），但控制器 `edits=0`。根因是**来源范围（installed-range）链**：
   `runtime_renderer_session.cj` 的 `internalRendererSourceRangeSupported()` 在
   macOS/Windows 都是 true、Linux 显式 false，于是 `focusNativeStatus` 走普通 focus
   路径，正文编辑意图落到控制器被当泄漏。接通需要 native 实现生产者侧
   （arm / receipt / activate / cancel / claim / copy / ack / release），
   已在 `cjgui_linux_installed_range.{h,c}` 立项，会话层已把三段正文
   （编辑前 / 替换串 / 编辑后）与一次性序列暴露给该模块。

顺带修掉的一个真实身份缺陷：文本编辑事件原本带的是**声明时刻**的投影版本，
共同层按它做节点解析会判 stale；已改为携带当前已接受场景版本。

## 3bis. 连续链已通（2026-10-18 第三轮）

来源范围生产者侧（`cjgui_linux_installed_range.c`，511 行）落地，并把 Cangjie 侧收尾：
9 个 installed-range `foreign` 声明放开到 Linux、删掉 8 个 Linux 桩（改用真实包装）、
`internalRendererSourceRangeSupported()` 的 Linux 支改为 true。

**端到端实测（来宾 `DISPLAY=:99`，无锁屏干扰）**：

| 环节 | 证据 |
| --- | --- |
| 点击正文 | `POINTER_BEGIN_REJECT` = 0（修前每次点击都被拒） |
| 键入 "ab" | `key_down … proxy=1` → `RANGE_TEXT_WORKLOAD_STEP` ×2 → `edits=1` → `edits=2` |
| owner 接受 | `RANGE_TEXT_OWNER_EDIT_RECEIPT` ×2、`RANGE_TEXT_OWNER_AFTER_WRITE` ×2 |
| 重新投影上屏 | 截图里正文出现 `ab# Pharos Mark range text consumer`，预览同步为 `ab# Pharos Mark range te`，状态行 `edits=2 rejected=0 seq=2 mirror=3 decisions=2` |
| 缩放 | `XResizeWindow 700×500` → `resized to 700x500`，继续出帧 |
| 关闭 | `WM_DELETE_WINDOW` → 进程退出、**`app_exit_code=0`** |
| 无泄漏 | `RANGE_TEXT_SUMMARY … full_text_events=0 leaked_range_events=0 session_accepted=2 session_refused=0 restored=0 restore_failures=0 pending=0 owner_bytes=190` |

证据图：`artifacts/20261018-edited-body-after-typing.png`。

## 3ter. 选择与替换已通 + 一个真实测量缺陷（2026-10-18 第四轮）

**修掉一个真缺陷：`lineHeight` 语义。** 共同层把 `lineHeight == 0` 也判为测量失败
（`runtime_renderer_session.cj:4234`），而且那个状态**是粘性的**：一次空文本标签的
测量就会毒化整轮布局，表现为 `CJGUI_STATIC_LAYOUT_REFUSED
reason=layout_native_measurement_failed`。原来把 `lineHeight` 设成文本块高度，空文本
时正好是 0。已改为取真实行高（`cjgui_linux_text_line_height`，并有 fontSize×1.2 与
最小 1 的兜底），多行自然高度同样保证非零。修后两窗夹具的
`LAYOUT_REFUSED` 归零、测量返回真实值（`bytes=18 w=116.3 h=24.0 lh=24.0`）。

**新增选择键**（会话层，走同一条代理路径，不另造状态机）：Shift+Left/Right/Home/End
扩展选区（锚点留在原处）、Ctrl+A 全选并上报 SELECTION_CHANGED；选中后打字即替换。
驱动侧加了 `keymod <keysym> <modifiers>` 以便投递带修饰位的按键。

**端到端实测（默认消费者，`DISPLAY=:99`）**：

| 操作 | 证据 |
| --- | --- |
| 键入 "abcd" | `edits=4`，`RANGE_TEXT_WORKLOAD_STEP`×4 |
| Shift+Left ×2 → 键入 Z | `edits=5`（**一次替换**，不是两次插入） |
| owner 最终正文 | `RANGE_TEXT_OWNER_HEX bytes=191`，解码为 **`abz# Pharos Mark range text consumer…`**（190→191 字节：插入 4 字、再把 2 字换成 1 字） |
| 无泄漏 | `range_decisions=5 full_text_events=0 leaked_range_events=0 session_refused=0` |

## 3quater. 撤销与滚动已通（2026-10-18 第五轮）

**上一轮"两窗夹具不出帧"的结论作废**：那是 `lineHeight` 缺陷的后果，修掉后两窗布局
自行出图（`PRESENT_ENTER` 591 次、14 节点），四个按钮（撤销并恢复选区 / 重做 /
交换片段 / 移动源范围）都在。上一轮看到的"present=0"是**我自己的探针条件太窄**
（`frameIndex % 60` 且只画在成功路径上），不是实现缺陷——已把入口探针改为无条件。

**撤销实测**：键入 "xy" → `edits=2`；点「撤销并恢复选区」按钮 → `edits=3`，
owner 正文 42 字节（41+1，最后一个插入被回滚）。撤销是 owner 的另一次写入，
不是范围意图，所以 `range_decisions` 不增加——两者口径不同，如实记录。

**滚动实测**：修了两处才通——
1. 滚轮增量必须走 `form_event_text` 的可解析载体
   `cjgui-wheel-v1|<x>|<y>|<precise>|<phase>|<momentum>`（共同层用
   `cjguiParseWheelDelta` 解析，见 `composable_ui_wheel.cj:82`）。放在 `pointerX/Y`
   里不会被解析。
2. 滚轮必须投给**包含该点的 SCROLL_AREA 或 wheelScrollable 节点**，不是叶子
   （与 Windows `cjgui_windows_renderer.c:3097-3099` 同判据）。
   修后 `accepted_offset` 随滚轮从 40 → 0，内容随之上移（见
   `artifacts/20261018-scrolled-origin-demo.png`）。
   驱动侧同时修了滚轮落点硬编码在 (10,10) 的问题，现在可指定坐标。

**最终组合链（一次运行内）**：键入 abc → Shift+Left → 键入 Q（替换）→ 滚轮 →
点按钮 → 缩放 → 关闭，**`exit=0`**，
`range_decisions=4 full_text_events=0 leaked_range_events=0 session_refused=0`。

## 3quinquies. 外部操作路径与回滚（2026-10-18 第六轮）

**修掉一个会让回滚静默失效的真缺陷**：`install_owned_source_selection` 没有 nodeKind
形参，我硬编码传 0，把 `set_composable_owned_text_session` 已声明的 kind=10 覆盖成 0。
后果是 `recover_active_text_proxy` 的身份判据永远不匹配（实测
`CJGUI_LINUX_RECOVER want node=4 res=102 kind=10 | have active=1 node=4 res=102 kind=0`），
**owner 拒绝后的回滚完全不执行**——代理停在被拒的本地值上，之后每一笔都在发散的
文本上工作。已改为"nodeKind == 0 表示调用方没有这个形参，沿用已声明的种类"。

**拒绝 → 回滚 → 继续（`RANGE_TEXT_REFUSE_FIRST=1`）实测**：
`range_decisions=4 session_accepted=0 session_refused=4 restored=4 restore_failures=0`，
owner 正文 **188 字节（= 原文，未被污染）**。四笔拒绝全部回滚成功，
`CJGUI_VISUAL_RECOVERY … recover_status=0`。

**owner 侧操作后人工继续输入（两窗布局）**：键入 "ab" → `edits=2`；点
「移动源范围」按钮（owner 侧操作，不写正文）→ `edits=2`；继续键入 "cd" →
**`edits=4`**（4 笔 `RANGE_TEXT_OWNER_EDIT_RECEIPT` / `RANGE_TEXT_WORKLOAD_STEP`）。

**文件后端被外部进程改动后继续输入**：`RANGE_TEXT_FILE=/tmp/rt.txt` 启动、键入 "ab"
（`edits=2`、`backing_reads=6`），在**进程外**追加内容，再键入 "cd" → **`edits=4`**。
**但要说清楚**：追加后 `backing_reads` 仍是 6，即该 owner 在打开时绑定版本、
**不观察外部追加**，所以这条只证明"外部改动不打断人工续写"，**不证明**一条会改变
共享状态的外部协作链。

**最终组合链（一次运行内）**：键入 abc → Shift+Left → 键入 Q（替换）→ 滚轮 →
点按钮 → 缩放 → 关闭，**`exit=0`**，
`range_decisions=4 session_accepted=4 session_refused=0 leaked_range_events=0`。
一处观察：`RANGE_TEXT_ORIGIN_DEMO=1` 时 `full_text_events=4`（默认模式为 0），
即该模式下整值事件也会到达控制器（消费者只计数不消费）。已记录，未深究。

## 3sexies. 外部协作通道在 Linux 上的边界（2026-10-18 第七轮）

**结论：`range_text_window_app` 无法承载"真·外部客户端协作链"**，原因是结构性的而不是
平台缺陷：它的 owner 是示例自己的 `PlainRangeTextStore`，**没有实现
`CjguiSharedOperationDomain`**，因此挂不上 `CjguiSharedOperationExternalConnection`
（该连接的构造要求 domain + authorization）。要在本消费者上真验，必须给它实现共享
操作域——那会改变这个消费者的性质，不属于本阶段范围。

**已在 Linux 上验到的边界**：
- 纯核心的外部协作消费者 `examples/shared_operation_second_consumer` 在来宾上
  `cjpm build --skip-script` → **`cjpm build success`**（它只依赖纯仓颉的
  `shared_operation_core`，不含 native ABI）。即**外部协作通道在 Linux 上可构建**。
- 它自带的验收驱动 `test_shared_operation_second_consumer.py` 是 **macOS 专用**
  （硬编码 `DYLD_LIBRARY_PATH` 与 `darwin_aarch64_cjnative` 运行时路径），
  且依赖 1761 行的 `shared_operation_core/client.py` 协议客户端。
  **本轮没有把它适配到 Linux 并真正驱动**，所以"外部进程改共享状态 → 人工续写"
  仍然没有真实外部客户端证据。
- 宿主侧 `CjguiLinuxApplicationHost.attachExternalConnection` /
  `pumpOneTurn → pumpWithExternal` 已按 Windows 同形状实现；第八轮起已有通知窗口
  宿主的真实运行证据（见下），不再是仅编译/链接。

**2026-10-18 第七轮补充：这一项已在 Linux 上跑通（框架级）。** 把
`test_shared_operation_second_consumer.py` 的三处 macOS 专用改掉
（`CANGJIE_HOME` 默认值、`darwin_aarch64_cjnative` → `linux_aarch64_cjnative`、
`DYLD_LIBRARY_PATH` → `LD_LIBRARY_PATH`；`client.py` 本身无平台引用），在来宾上运行：

```
$ python3 test_shared_operation_second_consumer.py
rc=0
shared_operation_second_consumer acceptance passed
```

该验收内含 **21 条 require 断言**，覆盖：描述符握手（0600 权限与长度）、发现通用列表
动作、**未授权动作不得从发现泄漏**、**两个独立进程共享一个端点**、第二个进程暴露
自己的列表、分片 GET_CONTEXT、**外部通用列表动作真的生效并被读回**、写范围不被绕过、
能力门不被绕过、**陈旧调用 fail-closed**、**被拒绝的调用不改变列表真值**、描述符清理。

即：**"外部进程经框架的共享操作通道写入共享状态并被读回"在 Linux 上成立**。
**2026-10-18 第八轮：外部协作通道"经过窗口宿主"已在 Linux 上验通。**
`examples/notification_threshold_window_app`（窗口消费者 + 领域 + 外部连接，用的是
无 `@When` 守卫的 `CjguiMacosApplicationHost`）在来宾上 `cjpm build` success 并运行：
840×520 Vulkan/xcb 窗口 + `DESCRIPTOR_PATH /tmp/tmpDir0rg8my/connection.cjgui` +
`PROTOCOL CJGUI_SHARED_OPERATION/2`。用真实外部进程（`shared_operation_core/client.py`）
驱动：

```
$ python3 client.py <descriptor> describe
PROTOCOL CJGUI_SHARED_OPERATION/2 ; CAPABILITY ... ; CALLER 通知阈值本地 Agent
ENDPOINT_EPOCH 1 ; ENDPOINT_INSTANCE c103c523a569df23... ; ACTIONS 7（动作名中文）
$ python3 client.py <descriptor> get --json
KIND SNAPSHOT ; VERSION 0 ; RESOURCE 9100 异常提醒
FIELD 9100 deliveryChannel/triggerThreshold/isEnabled/draftChannel/draftThreshold/draftEnabled/draftVersion
WINDOW_FIELD_VALUE ...（窗口字段投影已发布）
WINDOW_SCENE_VERSION / WINDOW_ACCEPTED_SCENE_VERSION / WINDOW_NATIVE_SUBMISSION_VERSION 持续推进
$ python3 client.py <descriptor> invoke 0 EDIT_DRAFT_TEXT --target 9100       --arg fieldId=STRING:deliveryChannel --arg text=STRING:AGENT-外部写入 --arg expectedDraftVersion=INTEGER:0
APPLIED true ; CONFLICT false ; VERSION_BEFORE 1 ; VERSION_AFTER 1 ; REASON draft_updated
读回：draftChannel = 4147454E542DE5A496E983A8E58699E585A5（"AGENT-外部写入"），draftVersion 0 → 1
```

即**外部进程写入了运行中窗口消费者的共享状态并被读回**，窗口投影同时发布给外部客户端。
中间还验到一次正确拒绝：`expectedDraftVersion=1` 时回 `APPLIED false / CONFLICT true /
REASON draft_version_conflict`，且真值未被改动。

**2026-10-18 第九轮补充**：上一段说的"只画出背景"已修（见 §3septies），窗口现在完整
渲染。第九轮末点击文本字段时曾出现可见横幅"输入未应用：事件 39 的原控件已刷新或移除
（节点 13）"；该问题已在第十轮定位并修复，不是消费者缺声明，详见 §3octies。

## 3septies. 修掉一个影响所有"直接路径"消费者的渲染缺陷（2026-10-18 第九轮）

上一轮留下的"通知阈值窗口只画背景"是**真缺陷，而且影响面很大**：共同层有两条场景路径，
我只把其中一条接通了。

| 路径 | 顺序 | 提交点 |
| --- | --- | --- |
| 私有准备（range_text 走这条） | begin → prepare×N → advance → configure → **promote** | `promote` |
| **直接路径**（通知阈值等走这条） | **configure → set_node×N → present** | **`present`** |

**缺陷一：直接路径从不提交。** 我的 `present_composable_scene` 只画 `accepted`、从不提交
候选，于是任何不走私有准备的消费者在 Linux 上**永远画不出内容**。实测：
`CJGUI_LINUX_PRESENT frame=0 nodes=0 vertices=6 accepted=0 candidate=1`——只有 6 个顶点
（窗口背景）。修法：`present` 入口处，若候选有效且没有进行中的准备，就提交候选
（promote 路径提交后候选已被移走、invalid，不会重复提交）。

**缺陷二：直接路径的 COW 克隆语义。** 共同层只为**变化过的**节点发 `set_node`
（`canReuseStagedNativeNode` 会跳过未变节点，注释明说"native then clones only that
staged index"）。我的 `configure` 却把候选槽位**全部清空**，被跳过的索引就成了空节点。
修法：`configure` 建立新事务时**从已接受场景整槽深拷贝**（新增 `cjgui_linux_slot_copy`），
只在索引超出上一代时才清空。

修后实测（通知阈值窗口）：`frame=0 nodes=24 vertices=1050 accepted=1 candidate=0`，
**600 帧后仍是 24 节点/1050 顶点**；画面完整渲染中文表单
（见 `artifacts/20261018-notification-window-rendered.png`）。

**外部写入已同步到画面**：外部进程写入 `deliveryChannel=AGENT-外部写入` 后，
窗口「投递通道」字段显示 `AGENT-外部写入`
（见 `artifacts/20261018-external-write-visible.png`）。

**回归（目标消费者，改动后重跑）**：键入 abc → Shift+Left → Q（替换）→ 滚轮 →
点撤销按钮（`edits=2 → 3`，owner 42 字节）→ 缩放 → 关闭 **`exit=0`**，
`range_decisions=4 session_accepted=4 leaked_range_events=0`。

## 3octies. 输入承载收口与"人→外部→人"连续链（2026-10-18 第十轮）

### 3octies.1 native 输入承载簇

| 位置 | 原问题 | 现行为 |
| --- | --- | --- |
| `native/cjgui_linux_session.c` `pending_push` | 队列满时清 `pendingCount/pendingHead`，已收起事件被丢 | 满时只累加 `pendingOverflowCount` 并拒绝**新**输入；已排队事件保留 |
| `pending_push_geometry` / 泵出队 | 事件捕获版本与几何来源不同，消费时重盖当前版本 | 每事件随载荷保存命中几何，出队按该事件自己的几何返回 |
| `cjgui_linux_proxy_insert`（:1731） | 扫描全局第一个 active session | 接收产生这笔输入的 `CjguiLinuxSession *`，不跨窗口 |
| `cjgui_linux_emit_text_edit`（:1766） | 容量不足时可能先改代理；rangeIntent/前像后像单槽 | 队列容量先于代理修改处理；整值+增量事件、前像/后像与替换串均按笔携带 |

同一构建的跟踪证据（`/tmp/notif_run6`，`CJGUI_LINUX_PUMP_TRACE=1`）：
`QUEUE_GEOM=5`、`PUMP_GEOM=5`，逐笔配对 `MISMATCH=0`；全部
`CJGUI_LINUX_INPUT_SESSION session=0xaaaae0a65f10` 指向同一会话；
`RANGE_DECISION=13` 全部 `accepted=true`。

### 3octies.2 共同层修复

1. **legacy range 拒绝未调度回滚**（`src/composable_ui_window.cj:18018`）：`replaceRange16`
   拒绝时只有 claimed 路径调度 `refusedRangeTextPending`；通知消费者走 legacy 路径，
   拒绝后会话永久 `recalibration_required`。现在 legacy 拒绝同样进入有界回滚。
2. **外部变更后选区失效**（`src/text_session.cj:627`）：`refreshMirror` 遇到外部写入、
   且 source 无 owner/无 rebase 时，把 caret 夹进新镜像并要求 native 恢复，会话不再
   永久不可编辑。
3. **accepted scene 未刷新 owned 镜像**（`src/composable_ui_window.cj:22739`）：外部写入
   后第一笔按键曾以 `stale_base` 被拒并丢失；现在在 accepted scene 发现节点值与镜像
   不同即刷新镜像，再由 `restoreOwnedTextSelectionAfterAcceptedScene` 签署/安装选区。
4. **无捕获 POINTER_END 误报**（`src/composable_ui_window.cj:16874`）：普通点击的 BEGIN
   未被控制器认领时，END 仍被交给 `rejectUiEvent(39)`，消费者显示"输入未应用：事件 39
   的原控件已刷新或移除"。现在无活动捕获的终止相位按无动作处理。

这 4 处由上述 Linux 链直接消费。macOS 单测本轮未重跑：`cjpm test --skip-script`
因 native test 符号缺失在链接期失败，未为此重编 macOS sidecar（属其他平台整包，
本轮范围外）。

### 3octies.3 通知消费者完整链（同一窗口、同一 draft 字段）

来宾 Xvfb `:99`，`OUT=/tmp/notif_run6`，一次运行、无补点击/无重投：

```
READ1 邮件human v5
invoke APPLIED true VERSION_BEFORE 6 VERSION_AFTER 6
READ2 EXT-改写 v6
续输（直接 End + CONTINUE）→ READ3 EXT-改写continue v14
CHAIN_EXIT=0 OVERFLOW=0 REJECTS=0 CHAIN_RESULT=PASS
```

画面：外部改写后显示 `EXT-改写`，续输后显示 `EXT-改写continue`，
**无"输入未应用"横幅**（`artifacts/notif_20261018_after_human3.png`）。

### 3octies.4 range 消费者正常连续链

一次运行：点入正文 → 连续键入 `abcd` → Shift+Left×2 → 替换 `Z` → 截图 → 关闭。

```
RANGE_TEXT_SUMMARY range_decisions=5 full_text_events=5 leaked_range_events=0
session_accepted=5 session_refused=0 pending=0 owner_bytes=191 version=6
owner_hex 61627a232050686172...（"abz# Pharos Mark range text consumer..."）
RANGE_EXIT=0
```

`full_text_events` 是到达 owner 的整值事件计数（该消费者按设计只计数、不消费），
不是泄漏；范围泄漏判据 `leaked_range_events=0`。

### 3octies.5 双窗口不串写与普通桌面

- **双窗口**：同时运行两个通知消费者进程，命令只命中其一；运行后
  `DRAFT_A=[邮件onlyb] DRAFT_B=[邮件]`，`TWO_RESULT=PASS`。边界：这是两个进程各一
  会话；同进程双会话工作负载未建，隔离依据是 `proxy_insert(session)` 使用产生输入的
  会话。
- **普通桌面**：来宾 `DISPLAY=:0`（UKUI/X11，真实窗口 root=(24,182)），点字段 + End +
  键入 `DESK` → `draftChannel=邮件desk v4`、`DESK_EXIT=0`，画面核对通过
  （`artifacts/notif_20261018_desktop0.png`）。
- Xvfb/XSendEvent 证据仍有效，但不等同物理键鼠；Vulkan 仍为 llvmpipe，未测硬件性能。

### 3octies.6 启动方式（来宾，普通桌面 `:0`）

```bash
source ~/cangjie-dl/cangjie/envsetup.sh
# 通知消费者（承担外部协作链；启动后日志打印 DESCRIPTOR_PATH）
cd ~/cjgui-linux/runtime/cjgui/examples/notification_threshold_window_app
DISPLAY=:0 XMODIFIERS=@im=ibus target/release/bin/main
# 外部读/写（同一 descriptor）：先 get 读当前 VERSION 与 draftVersion，
# invoke 的上下文版本取 VERSION，expectedDraftVersion 取 draftVersion，不能写死 0。
python3 ../../shared_operation_core/client.py --json <descriptor> get
python3 ../../shared_operation_core/client.py <descriptor> invoke <context-version> \
  EDIT_DRAFT_TEXT --target 9100 --arg fieldId=STRING:deliveryChannel \
  --arg text=STRING:... --arg expectedDraftVersion=INTEGER:<draftVersion>
# range 消费者（文字、选择、滚动、Undo、owner 拒绝恢复；ASCII 回归可不挂 IME）
cd ~/cjgui-linux/runtime/cjgui/examples/range_text_window_app
DISPLAY=:0 XMODIFIERS=@im=none target/release/bin/main
```

## 3nonies. 系统中文输入、完整剪贴板与共同层收窄（2026-10-18 第八轮）

本节是本版结果；§3octies 的 Xvfb/ASCII 记录保留为旧证据，不代表本版输入方式。

### 3nonies.1 共同层最小收窄（不改平台契约）

1. `src/text_session.cj` 的 `refreshMirror` 撤销上一轮“无 owner/rebase 就把旧 caret
   夹进新镜像”的通用兜底：现在按原契约返回具名 `selection_rebase_unavailable`，
   新选择由 owner/source 政策决定。
2. 新增 `refreshMirrorForAcceptedScene(acceptedText)`：只有窗口源切片从当前
   `windowStartByte` 读出的正文与 accepted 正文相同、且该切片的 `contentVersion`
   等于当前 `sourceVersion` 时才刷新。accepted 帧比来源旧时不采纳，等发布该字节的
   新场景；同字节但版本推进仍会刷新基座。
3. 整值字段“旧版本 → 新值末尾”的策略放在通知消费者的
   `CjguiNotificationDraftTextBridge.rebaseRangeTextSelection`（同版本沿用坐标；
   旧版本折叠到新值末尾；其余返回 None），不再由所有文本源共享一个 clamp。
4. legacy range 拒绝回滚与无捕获 POINTER_END 沿用上一轮共同路径：前者调度有界回滚，
   后者按指针协议无动作；未吞真实拒绝。

### 3nonies.2 系统中文输入（XIM/XIC + ibus-libpinyin）

- 实际输入方式：来宾 `:0` 普通桌面，XTest 投递真实键序，XIM `@im=ibus` 下由
  ibus-libpinyin 实际组字；不是把 Unicode 字符串直接写入。
- 预编辑（phase=1）只更新场景内 preedit 投影，不写 owner；空格/候选提交（phase=2）
  作为一笔 owner 编辑；Escape/失焦（phase=3）取消且正文不动。输入法消费的字母不再
  作为普通字符提交。
- 多字符提交直接借用事件自身的 65536 B `utf8` 载荷，不再经过 `typed[8]` 单字符缓冲。
- 候选位置：Linux 会话在组合态绘制时算出 preedit 末尾的 caret 几何，并用同一份几何
  写 `XNSpotLocation`；实测 `CJGUI_IME_SPOT x=92.0 y=196.5 h=19.0 focused=1`
  （`evidence/clipboard-ime-20261018/ime_spot.log`）。消费者不需要先调用
  `declareInputCaretBar`。
- 组合中失焦：清 preedit 并 flush cancel，正文不变、无 commit；组合中关窗：
  `exit 0`、descriptor 删除、无 commit（同目录 `ime_spot.log` 记录了这两条检查）。

### 3nonies.3 剪贴板（异步 CLIPBOARD，UTF-8 完整文本）

- 事件泵内异步 `XConvertSelection`；`take` 只认结果状态，请求在途为 PENDING，
  不把 IDLE 当成“已完成但没有数据”。
- 上限 `CJGUI_LINUX_CLIPBOARD_CAPACITY = 65536` B；超限或未支持类型在修改
  代理/owner 前具名拒绝（`clipboard_too_large` / `clipboard_unsupported`），旧正文保持。
- 粘贴是一笔范围编辑，不拆成模拟键入；自身复制与外部 owner 复制走同一 CLIPBOARD 服务。
- 实测：外部 587 B 中英多行文本一次粘贴为 605 B（原 18 B + 587 B），诊断长度一致；
  Ctrl+A/C 后外部读取 605 B；70013 B → `too_large` 保旧；PNG → `unsupported` 保旧；
  Ctrl+X 删除且外部读回 605 B，再粘贴恢复。

### 3nonies.4 一条组合链（来宾普通桌面 `:0`）

完整文本与逐项断言见 `evidence/clipboard-ime-20261018/chain.log`：

```
READ 邮件
IME: zhongwen+space → 中文；nihao+2 → 你好吗；Escape → 不变
IME: Shift+Left×2 + xuan+space → 邮件中文你选（commit 选）
外部 CLIPBOARD 587 B + Ctrl+V → 605 B
Ctrl+A/C → 外部读取 605 B；Ctrl+V 自粘贴保持
70013 B → too_large 保旧；PNG → unsupported 保旧
Ctrl+A/X → 空且外部读回 605 B；Ctrl+V 恢复
外部写 EXT-改写-20261018 → 直接 IME jixu+space → …继续（无补点/End）
同字节外部写（版本推进）→ 直接 IME bang+space → …邦
FINAL_TEXT len_bytes=28 repr='EXT-改写-20261018继续邦'
FINAL_HEX 4558542de694b9e586992d3230323631303138e7bba7e7bbade982a6
exit 0；descriptor 删除；QUEUE_OVERFLOW=0
```

外部写入示例读取当前 `VERSION` 作为 invoke 上下文（本链为 7/9），
`expectedDraftVersion` 取 `draftVersion`，没有写死 0。

### 3nonies.5 native 容量用例与 range 短回归

- 同进程双会话 + 16 槽饱和：`native_session_harness.log`，`HARNESS RESULT PASS failures=0`；
  覆盖满队拒绝、旧代理值保持、队列计数不变、overflow 计数、另一会话不受影响、
  腾出 1 槽仍拒 / 2 槽接受。正常样本 `OVERFLOW=0` 不作为容量分支证据。
- range 短回归（本版新构建）：启动 → 键入 `abcd` → Shift+Left×2 → `Z` → 关闭；
  owner 191 B、前缀 `abZ# Pharos Mark range text consumer`，
  `range_decisions=5 session_accepted=5 session_refused=0 leaked_range_events=0`，
  `exit 0`（`range_short_app.log` / `range_short_result.txt`）。
  滚动、字体、Vulkan 与 macOS 旧结论按原范围复用，未因本簇重跑。
- **构建身份**：组合链与 native 用例在 17:59 侧车/消费者上完成；之后仅把候选定位接入
  同一份 caret 几何，18:32 重建两个消费者，并用 `ime_spot.log`（组合中失焦/关窗与
  spot 数值）在最终二进制上复验预编辑路径；剪贴板路径未受该增量影响，未重跑。
  最终二进制 sha256：通知 `4f9283fc…`、range `08bebe3a…`、侧车 `2cc670f2…`
  （完整值见同目录 `SHA256SUMS`）。

## 4. 剩余门（下轮从这里接）

1. **命令菜单的 commit 路径未接通**：两窗布局每轮 `configure(4)` + `set_item`×4，
   但 `commit_composable_command_menu` 从未被调用；`replaceNativeCommandMenu` 才是
   唯一调用点，而该布局走的是直接 `stageNativeCommandMenu`。这不影响当前已验链
   （按钮激活走 PRESS/ACTIVATE），但菜单声明目前只到 staging。
2. **系统中文输入已接通 XIM/XIC**：ibus-libpinyin 的预编辑、候选、提交、取消、失焦/关窗
   取消与候选定位均有本版证据。未做其他 Linux 输入协议（Wayland text-input 等）；
   候选窗像素位置只按 `XNSpotLocation` 数值核对，未做窗口截图比对。
3. **emoji 彩色字形**：`😀` 在窗口里仍是缺字块；Noto Color Emoji 走 CBDT 位图字形，
   本阶段只做灰度光栅。
4. **Wayland 与硬件性能**：本阶段仅 X11/XCB；Vulkan 为 llvmpipe，未测硬件 GPU 性能，
   不设 p95 门。`full_text_events`/`leaked_range_events` 只说明对应事件未泄出，不能
   写成“无内存泄漏”。
5. **剪贴板边界**：只支持 UTF-8 文本（`UTF8_STRING`/`TEXT`/`STRING`），上限 65536 B；
   图像/HTML 等返回 `unsupported`，超限返回 `too_large`，均保留旧正文。legacy
   `get_clipboard` 超限同样拒绝，不再截断后返回成功。
6. **range 消费者仍无 `CjguiSharedOperationDomain`**：外部客户端协作链只在通知消费者；
   同进程双会话与队列容量已由 native 用例覆盖，不冒充产品双窗口测试。

## 5. 构建与环境（来宾 openEuler 26.09 aarch64，UKUI/X11）

- 消费者编译闭包 = `native/scripts/lib_cjgui_source_set.sh` 的命名集合，本轮补齐
  8 个滞后文件（缺一即编译报 undeclared type）；`platforms/linux/scripts/resolve_source_closure.py`
  可迭代重算。
- `build.cj` 已按平台分派：Linux 走 `platforms/linux/scripts/build_sidecar.sh`，
  macOS 走原 Objective-C/Metal sidecar，产物都落在 `native/lib/libcjgui_internal_renderer.a`。
- 来宾环境两处必要修补（都记在这里，避免下次重踩）：
  1. `/usr/lib64/libgcc.a` 软链到 `/usr/lib/gcc/aarch64-openEuler-linux/12/libgcc.a`
     （`cjpm` 的构建脚本链接用裸 `-lgcc`，不走包 link-option）；
  2. Cangjie SDK 自带的 `libpcre2-8.so.0`（0.14.0，无版本节点）会遮蔽系统的
     0.16.0，导致 `libglib-2.0.so.0` 的版本化 pcre2 引用在链接期全部报缺。已把
     SDK 的两个文件移到 `runtime/lib/linux_aarch64_cjnative/.pcre2-sdk-backup/`。
- 无 Xvfb 时锁屏会话里 `XGetImage` 取不到窗口内容（被全屏锁屏遮挡且无 backing
  store）。本轮在来宾装了 `xorg-x11-server-Xvfb`，用 `:99` 做渲染核验，
  **不碰用户会话与锁屏设置**。

## 6. 空间账

- 仓库新增：`platforms/linux/**`（含 1 张 23 KB 证据图）+ `src/linux_application_host.cj`
  + `build.cj`/`lib_cjgui_source_set.sh` 的最小改动；无构建产物入库。
- 来宾：`~/cjgui-linux` 138 MB（唯一可复用工作目录；含两消费者 `target/release`
  各约 45 MB，本轮重新构建）；`/tmp/drv` 8.1 MB、`/tmp/lg` 34 MB（Vulkan 自测与
  验证层）；本轮证据目录 `/tmp/notif_run5|6`、`/tmp/range_run`、`/tmp/two_window_run`、
  `/tmp/desktop_run` 合计约 8.3 MB。来宾 `/` 剩 46 GB，`/tmp` tmpfs 剩 7.4 GB。
- 宿主：`platforms/linux` 合计 3.6 MB（其中 `artifacts/` 2.8 MB，本轮新增
  `notif_20261018_after_human3.{ppm,png}` 与 `notif_20261018_desktop0.{ppm,png}`）；
  宿主可用 301 GB，高于 20 GiB 余量线。每线新增远低于 10 GiB 留存预算。
- 本轮结束已停止来宾上的两个 `main` 与 `Xvfb :99`；`:0` 上的核对窗口已正常关闭。

- **2026-10-18 第八轮**：仓库新增 `platforms/linux/tests/linux_session_harness_test.c` 与
  `platforms/linux/evidence/clipboard-ime-20261018/`（7 个文件，约 24 KB）；native 侧改
  `cjgui_linux_session.c`/`cjgui_linux_window.c`，共同层只收窄 `text_session.cj` 的
  accepted 镜像刷新与 caret 路径。来宾唯一工作目录 `~/cjgui-linux` 139 MB（两消费者
  `target` 各 45 MB，侧车 `libcjgui_internal_renderer.a` 1.5 MB）；本轮临时运行目录
  `/tmp/clip_final|focus_run|spot_run|range_short|clip_test` 合计约 3.5 MB，已按准确身份
  回收；`/tmp/drv` 54 MB 与 `/tmp/clip_fixtures` 84 KB 是前轮可复用驱动/夹具，未动。
  来宾 `/` 剩 46 GB、`/tmp` 剩 5.6 GB；宿主可用 295 GiB，均高于 20 GiB 余量线；
  无构建产物入库，无 Git 写。

- **2026-10-19 视觉能力核对轮**：用 `range_text_window_app` 探针在来宾 Xvfb `:99`
  像素验证矩形 clip 链（200 px 窗内子文本截断到 x=216）、rotateDegrees（标题可见倾斜，
  下缘回归斜率 0.118）、zIndex（先加的红 z=3 盖住后加的蓝 z=1）、
  translate/scale（状态行 +60 px；缩放字宽 73→51 px = 0.699）。
  证据：`platforms/ohos/evidence/visual-capabilities-20261018/`（3.0 MB，32 项 SHA256）。
  `linux_guest.sh sync` 增加排除 `build-script-cache/`：此前会把宿主 Mach-O
  `build-script` 同步到来宾，cjpm 复用时报“无法执行二进制文件”；来宾旧缓存已删。
  tint / effectGroup / backdrop 仍受单管线（直绘 swapchain + 字形图集）限制，登记未做。
  探针已还原（`main.cj` = `2b5d5065…`）并重建干净基线；Xvfb 与探针进程已停止；
  `~/cjgui-linux` 140 MB，来宾 `/` 剩 46 GB，宿主 `/` 剩 296 GiB。
