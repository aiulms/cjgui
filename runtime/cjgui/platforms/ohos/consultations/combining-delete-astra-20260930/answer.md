**“系统 ICU 窄服务＋真实删除意图”方向成立，但 GLM 的建议还缺少意图分类、同版本凭据和取消后的输入仲裁，不能直接据此宣布方案完整。** N1 可以复用；需要补的是它之前的删除事务，以及“同 owner 已接受、平台代理尚未安装”的衔接。

我核对了原始读回：两次都是 `VERSION 10 / RANGE 0 26`，正文为 `'# Pharos Mark\n\nH1R\n中文e'`；严格期望确实是去掉末尾 `e` 后的 25 B。[原证](runtime/cjgui/platforms/ohos/consultations/combining-delete-glm-20260930/combining-red.raw.json:19)

以下是只读源码裁决与建议接口，未修改、构建或执行设备验证。

1. **现有证据能确认框架缺口，尚不能把具体原因定为平台的“剥重音策略”。**

   当前链路是 `onChange → registry → native 全文差分 → kind51 → session.replaceRange16`。差分只保证标量边界及结果文本等价，没有表达 `DeleteBackward`。因此：

   | 同一次操作的直接证据 | 可以作出的判断 |
   |---|---|
   | 删除前代理为 `é`，平台回调后的实际值为 `e`，native 收到的也是 `e` | 问题发生在平台编辑结果形成之前或过程中；kind51 保留该结果并不错误 |
   | 平台实际值已经删除整个 `é`，native/owner 最后却留下 `e` | 查 registry、native 基线、差分或迟到恢复 |
   | `onWillDelete` 报完整 `é`，随后实际值仅少重音 | 不能仅依据回调范围归因；要核对取消、替换及恢复回声的顺序 |
   | UITest 删除没有进入 `onWillDelete` | 该回调不能覆盖这条验收路径，不能靠已知 DEL2055 推断意图 |

   旗帜、肤色、家庭组合成功，只证明这些样本的最终删除结果正确；它既不能证明平台完整采用 EGC，也不能排除代理差分问题。

   GLM 另有三处需要撤回：

   - `handlePlainIntent` **已有** `compositionActive` 总门禁，不能再以“缺门禁”为理由修改。[text_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/text_session.cj:818)
   - `onWillChange` 表达即将发生的值变更，不能单独替代字符删除意图。
   - “先接受平台删除，再补删一笔”会改变明确范围并产生第二笔编辑，不是本任务的合格退路。

2. **`DeleteValue` 三字段不够；必须与同一操作前的文本、选区和身份一起分类。**

   本机 SDK 确认 `onWillDelete` 可以取消、仅用于系统输入法、不用于 preview；只保证 `onWillChange` 位于 will 与 did 回调之间。`deleteOffset` 的说明仅是“被删除文本的位置”，没有充分定义方向坐标、选择删除时的定位方式，或它与 `onChange` 的顺序。当前官方文档同样没有补足这些细节。[SDK 声明](/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/component/text_area.d.ts:1148)；[官方 DeleteValue](https://github.com/openharmony/docs/blob/master/en/application-dev/reference/apis-arkui/arkui-ts/ts-text-common.md#deletevalue12)

   建议明确采用以下规则：

   | 操作前事实 | 裁决 |
   |---|---|
   | 非空明确选区，回调删除范围与选区、原文字节完全一致 | 保持该精确范围，绝不改成相邻簇删除 |
   | 已证明是 collapsed 的普通方向删除，平台拟删范围正好等于相邻完整簇 | 可以放行平台，后续仍由原 kind51 写一次 |
   | 同上，但平台拟删范围只是相邻簇的一部分 | 才允许取消平台操作，提交一个共同 `DeleteBackward/Forward` |
   | preview/composition 活跃或状态未知 | 不转成 plain intent；由现有组合路径处理 |
   | 选区版本不明、代理未完成恢复、绑定失效、删除跨多个簇或属于复合替换 | 不提升成“删一个簇”；具名拒绝或保留明确替换语义 |

   **范围包含关系只是校验，不是意图识别器。** 不能因为 `deleteValue` 恰好是重音，就认定它是一个字符退格。还须通过平台实验确认该回调没有混入自动替换、候选提交的删除部分或多字符删除请求。

   设已确认的操作前文本为 `T`、collapsed caret 为 `p`、删除内容长度为 `L`。平台实验确定 offset 约定之后，才能固定 backward/forward 的范围公式，并要求：

   - 回调范围合法，端点不切代理对；
   - `T[range] == deleteValue`；
   - 范围与 `p`、方向一致；
   - ICU 给出的相邻簇完整包含在可证明的正文上下文中。

   不得运行时尝试几种 offset 解释，挑一个“字符串碰巧相等”的结果。

   对非空选区还有一个必须明确的边界：当前 session 会精确删除非空选区，未检查簇端点。**建议本次用户删除契约采用：完整簇端点则精确删除，半簇选区则具名拒绝；不扩选、不扩删。** 明确的范围替换 API 仍保留其原有精确语义。Flutter 的删除 action 会扩张非空选区，因此只能借鉴意图与边界服务分离，不能照搬该行为。[Flutter 实现](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/widgets/editable_text.dart#L6240)

3. **接线应复用现有 FIFO，增加冻结的删除请求凭据；不建议从 NAPI 同步调用 core。**

   当前 ArkTS/NAPI 在 UI 线程，Cangjie 应用有独立 owner 线程。直接同步调用 `session.handlePlainIntent` 会新增跨线程访问、重入和锁顺序问题，现有代码没有提供这种保证。[owner 线程入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp:2352)

   最小请求需要区分这些身份，不能把它们合成一个 `version`：

   ```text
   ProxyKey:
     appInstance, sessionToken, contextId, editGeneration, mountGeneration

   NativeTarget:
     nodeId, resourceId, nodeKind, fieldId
     acceptedProjectionVersion, acceptedBindingEpoch
     textSessionBindingEpoch

   CoreBasis:
     原 session/owner 绑定凭据
     contextEpoch, mirrorRevision, ownerContentVersion, windowStartByte

   Observation:
     proxyTextRevision, selectionRevision, selectionStart16, selectionEnd16
     preview/composition 状态
     callbackSeq, direction, deleteOffset, deleteValue
   ```

   Native 同步预检须证明：挂载仍有效；代理、native 编辑缓冲与已发布基线文本一致；选区属于这份文本；没有未安装恢复或未结算的前序编辑。**Native 无法仅凭 `editingContextBaseVersion` 证明当前 owner 版本**——它保存的是场景版本。core 必须发布只读基线凭据，并在消费时再次通过真实 owner 版本守卫。

   同样，不能先调用会钳位的 `setSelection16`，再把钳位后的数字当作正确操作前选区。先核验原始范围及版本。

   建议接线位置如下；新名称仅表示接口形状：

   | 文件 | 最小职责 |
   |---|---|
   | [arkts/cjgui-text-proxy.ets](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/arkts/cjgui-text-proxy.ets:63) | 共同 `onWillDelete(m, value, observation)`；挂载注册/退役通知；捕获原始回调，不分簇 |
   | [cjgui_host_bridge.cpp](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp:3015) | NAPI 参数、整数及长度校验；转交 `reserveDelete`，返回明确裁决 |
   | [ohos_renderer.cpp](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:7934) | 冻结完整请求、ICU 查询、单次消费及取消；保持 `editorEnqueueTextCommit` 原语义 |
   | [snapshot/cjgui_internal_renderer.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/cjgui_internal_renderer.h:461)、[runtime_renderer_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/runtime_renderer_session.cj:1181) | 增加内部 typed 请求读取/结算 ABI；不向产品暴露原生对象 |
   | [composable_ui_window.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:2058) | 在既有 kind35 路由中消费删除凭据，核验后调用共同 plain handler |
   | [text_session.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/text_session.cj:953) | 沿唯一写入路径提交，并交出本次 edit receipt，供窗口正确结算 pending |

   可以让 kind35 保留 `deleteBackward/deleteForward` 名称，附带只能读取一次的本次 FIFO 请求记录。**只有名称、没有凭据的事件不能进入新删除通道。** 不复用 composition/gesture 字段偷运身份，也不把 JSON 编辑命令塞进 `formText` 形成另一套协议。

   GLM 的“同步查询，取消后再异步新建请求”存在空档。建议同步阶段原子保留请求和队位；回调返回 `false` 后再使请求可消费。owner 线程只能领取已经完成这一阶段的请求。领取与取消竞争同一状态，失败、超时、旧挂载均有唯一终态；不在 renderer 锁内调用 core。

   产品 `Index.ets` 只挂共同回调和提供真实组件观测。TextInput/TextArea 共用 registry/native，产品不计算簇。

4. **需要补新契约，但不重写 N1：同 owner 接受事实与代理安装事实必须分开。**

   这里有两个源码上的实际接缝：

   - `submitPlainDelete` 的结果没有交出内部 edit ticket，而 kind51 路由会显式 `acknowledge`。新路由必须结算本次 pending，不能只调用 handler 后计成功。
   - `syncEditingBufferAfterAcceptedSceneLocked` 看到新 accepted 值与 `editingText` 不同时，会进入外部换版、换 context。平台删除被取消而 core 成功删簇，恰好会产生这种差异。[native 同步分支](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:6691)

   因此需要一份 **同一删除请求的 owner 接受回执**：关联原绑定、版本前后值、本次请求号及接受后的文本/选区。只有下一次 accepted 场景与该回执准确匹配，才能按“本次同 owner 编辑尚待安装”保留 context，并进入 N1。不能按字符串相等猜同 owner，也不能提前把代理标成已安装。

   成功删除还须显式标记代理待同步。现有成功 `submitRange16` 会更新 session 选区，不能据此推定 ArkUI 已经更新。

   建议终态规则：

   | 交错位置 | owner 与恢复处理 |
   |---|---|
   | 领取前绑定/owner 基线失效 | 删除零写入，终结原请求，不在新版本重放 |
   | owner 事务拒绝 | 删除零写入；按当前同 owner 权威状态进入必要的 N1 校准 |
   | owner 已接受，安装尚未完成 | 保留“已提交、待安装”事实；只重试恢复，不再执行删除 |
   | owner 再换版 | 旧恢复票据终结；重新冻结当前 owner 投影，不给旧票据补新版本 |
   | A 挂载退役、B 已挂载 | A 的请求/回声/ACK 不改 B 的正文、选区、焦点或恢复账本 |
   | 安装失败或超时 | 沿 N1 有界失败路径，不能记恢复成功或无限重发 |

   继续复用现有 `recover_text_proxy_ticket → 实际文本观测 → 实际选区观测 → imeRestoreAck → kind55 → canAdoptNativeRestore/consume/confirm`。[N1 窗口入口](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/composable_ui_window.cj:5777)

   **输入交错仍是 GLM 未解决的部分。** 例如：

   ```text
   平台仍持有 é
   core 已把 owner 删成空串
   恢复尚未安装，平台又输入 x，报告 éx
   ```

   不能把 `éx` 当最新正文，也不能把恢复取消称为这次输入已经安全接纳。新请求存续期间必须按代理基线标识隔离后续事件；旧基线事件不得写新 owner。若要继续接纳，必须通过共同范围机制证明其坐标转换，不能盲放全文、重发按键或凭差分猜意图。

   最小安全实现可以具名拒绝并保留未接纳输入证据；**但如果验收要求快速“退格后续输”不丢任何操作，这种拒绝仍是 RED。** 当前资料不足以证明异步方案已经满足该要求。改成同步 owner 提交也不会自动消除平台代理安装前的空档。

   单次删除只允许一个 owner edit receipt；取消、恢复和 ACK 都不写历史。是否恰好形成一个撤销单元，仍须由实际 `HISTORY/UNDO/REDO` 验证，不能由“一次函数调用”推出。

5. **ICU 服务可以直接定窄 ABI，不需要引入 IME 或第三方框架运行时。**

   保留当前：

   ```c
   grapheme_cluster_range(
       const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
       uint64_t *outStartByte, uint64_t *outEndByte);
   ```

   其含义是返回**包含输入字节的簇**，不是“从该字节向前找一个簇”。兼容 mac 的要求是：

   - `offsetByte >= declaredLength`、空串查询：无包含簇，具名失败；不得夹到末尾。
   - 多字节标量内部的 byte offset 合法，映射到该标量所属簇。backspace 查询 `caretByte - 1` 正依赖这一点。
   - 严格 `u_strFromUTF8`；非法、截断、过长编码、孤立代理值均拒绝，不替换成 U+FFFD。
   - 保留现有 CString 的无内嵌 NUL 契约；按声明长度做有界检查，不以截断后的 C 串继续计算。
   - 长度进入 ICU `int32_t` 前检查上界及分配溢出；失败输出保持零。
   - 明确 `ubrk_open(UBRK_CHARACTER, "root", ...)`，不传 `nullptr` 使用默认 locale。

   计算方式可固定为：

   ```text
   完整严格解码，同时建立 UTF8 字节 ↔ UTF16 标量边界映射
   x = 包含 offsetByte 的标量起点对应的 UTF16 offset
   start16 = isBoundary(x) ? x : preceding(x)
   end16   = following(x)
   将两个边界映回原 UTF8 字节
   校验 startByte <= offsetByte < endByte <= declaredLength
   ```

   `preceding/following` 是严格前/后边界，不能直接用 `preceding(x)` 处理恰在簇起点的查询，否则会取到前一簇。[本机 ICU 声明](/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/native/sysroot/usr/include/unicode/ubrk.h:421)

   UTF16 缓冲必须保持不变，直到 iterator 关闭；每次查询独立 iterator，RAII 先关 iterator 再释放文本。动态库函数表的生命周期覆盖所有调用。缺库、缺符号、缺规则数据均具名不可用，不降级标量；公共接口只返回区间/失败。

   另有两个具体约束：

   - mac 已有 `GRAPHEME_BOUNDARY_INVALID = 24`，OHOS snapshot 头目前未声明它，应对齐现有值而非另造编号。[mac 定义](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_internal_renderer.h:93)
   - ICU 对输入片段给出的边界，不自动证明它是完整 owner 的边界。若有界 mirror 截在组合序列中，须先证明上下文完整；不能固定补几个码点就宣称足够。本反例的小文档可以使用已确认的完整文本。

   ICU 72.1 头文件和符号存在不等于目标 HAP 的服务可运行；也没有依据声称其结果是 mac CFString 的“严格超集”。保留当前共同 CRLF 规则，逐样本验证跨平台契约。

接下来的实验应只解决这些前提，再做同一最终包的验收：

| 实验 | 必须留下的可区分证据 |
|---|---|
| 回调与取消 | TextArea 的 `willDelete/willChange/didDelete/onChange/selection` 顺序、返回值、操作前实际选区和实际文本；取消成功以文本事实判定，不以“没有回调”判定 |
| 删除分类 | backward/forward、非空选区、多字符删除、自动替换、候选提交；确定 offset 单位与方向约定，验证是否能够识别纯方向删除 |
| ICU 实际运行 | 在目标运行环境验证重音、多重 combining、中文、ZWJ、肤色、旗帜、CRLF、内部 byte offset、非法 UTF8、服务不可用；CLI probe 与正常 HAP 分别记证据 |
| 事务交错 | 取消后立即换 owner/换挂载/开始组合/继续输入；提交前后分别插入交错；重复回调、迟到 ACK、安装失败不得二次删除或写新 field |
| 正常最终 HAP | 冻结一个新 final SHA/PID，单次重放原输入；第四次 DEL 后完整 owner 精确为 25 B，恢复选区实际确认；随后续输、一次 undo/redo、保存重开均核完整字节 |

保留原 `1a1ee8…` 的生产 RED。新最终包的输入、owner、画面和恢复证据必须属于同一身份，不能拼接 ICU probe 或早期包结果。正常系统输入可以自动驱动真实系统 IME，并不额外要求人工审批；但仅发送 UITest 键码不能自行证明组合、候选与取消路径已覆盖。

**当前明确未决的是平台删除意图粒度，以及取消后连续输入的保真路径。** 这两项实验未成立之前，可以认可 ICU 和上述接线契约，不能认可整条 normal TextArea 簇删除能力已经闭合。

