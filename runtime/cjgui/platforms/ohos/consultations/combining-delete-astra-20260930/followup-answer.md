**可以把同步 `onWillDelete → controller.deleteText → 真实 onChange → 原 kind51` 作为本阶段优先候选，不必坚持新增异步 owner 删除事务。** 它有实际平台证据，并能复用原有“平台先改、owner 仲裁、拒绝后 N1 恢复”的链路。

但目前只能裁决为**可实施候选**。两个条件仍不成立：选区变化不能证明正文修改完成；现有 guard 不能排除具有相同删除前缀的 compound replace。

1. **新证据改变了哪些判断**

   `callbacks-02` 确实给出了可用顺序：

   ```text
   willDelete：旧文 é，selection 2:2
     controller.deleteText：
       嵌套 willChange：旧文 é → 空串
     controller 返回：selection 0:0，但记录的 text 仍是 é
   onChange：空串
   selection：0:0
   后续输入 X：空串 → X
   ```

   原始 UI 结果也读到 `probeText = X`，不只是汇总脚本的布尔值。[成功日志](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/platform-delete-probe/callbacks-02/correct.hilog.txt:847)

   因而可以取消上一方案新增的“owner 已删、平台尚未安装”分叉。不过，**平台操作到 `onChange` 的交付仍有间隔**，不能称整个过程完全同步。

   `callbacks-03` 更提供了关键反例：`getSelection()` 已返回 `0:0`，正文却最终保留旧值。故“确认 selection 后即判纠偏成功”必须删除。[失败日志](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/platform-delete-probe/callbacks-03/result.hilog.txt:622)

   Will 的 offset=2、Did 的 offset=1 也必须分账。当前证据只支持这次 backward 的操作前公式，不支持把 Did offset 当作原删除坐标，更不支持直接推广到 forward。

2. **最小公共 contract：修正平台代理操作，唯一写入仍来自真实 onChange**

   共同 registry 的接口可以保持三态：

   ```text
   PassExact
   CorrectPlatformRange(start16, end16, expectedText, frozenBasis)
   Refuse(reason)
   ```

   `CorrectPlatformRange` 至少要求：

   - 捕获的 mount 仍是当前、存活、未 finishing；controller 仍属于该 mount。
   - `draft` 来自最近一次真实文本观测；没有未观测完的改文、恢复、重挂或纠偏。
   - 实际 `getSelection()` 与这份文本同代，且 collapsed。
   - preview/composition 明确不活跃，不能以字段缺失或旧缓存推断。
   - native 的 context、目标、绑定代次、编辑缓冲与冻结基线一致。
   - ICU 查询使用冻结文本；查询前后身份和文本修订未变化。
   - caret 位于簇边界，文本上下文足以证明该簇完整。

   对目前已经观察到的 backward，设操作前 caret 为 `p`：

   ```text
   d = will.deleteOffset
   L = will.deleteValue 的 UTF16 长度
   R = [d-L, d)

   要求 d == p，T[R] == deleteValue，R 两端标量安全
   相邻完整簇 C 的末端必须 == p

   R == C：原样放行
   R 是 C 的严格尾部：才成为纠偏候选
   其他情况：不提升为整簇删除
   ```

   Forward 必须有自己的实际证据和公式，不能借此对称推定。

   非空明确选区和多簇范围保持精确，不能扩删。沿上一轮严格门槛，用户删除若明确切入半簇，应拒绝而非扩大范围；preview 继续由组合路径处理。

   Native 的查询只能证明其持有的基线，**不能把查询成功包装成 owner 当前版本已锁定**。之后仍由原 kind51 的 owner 守卫裁决。

3. **需要一个 mount 内的短暂操作记录，但不需要第二套 owner 事务**

   建议仅保留：

   ```text
   mount 身份、operationSeq、原 proxyRevision
   原文本/选区、计划区间、expectedText
   Applying / AwaitingEcho / Observed / Failed
   ```

   具体纪律如下：

   - **先登记，再调用 controller。** `deleteText` 已实证会重入 `onWillChange`，不能调用完才设置防重入标记。
   - `Applying` 内只允许本次 controller 操作预期的回调通过；不得再次运行簇算法。若实际出现嵌套 `onWillDelete`，只能按本次调用身份和精确区间处理，不能用全局 `correcting=true` 无条件放行。
   - `onWillChange` 可以核对本次程序修改的 `oldContent/content/range`，**不能在那里再次执行删除**。这不复活已失败的 WillChange 纠偏方案。
   - **一旦尝试过 controller 修改，外层一律取消原删除。** 即使抛错、选区异常或观测失败，也不能返回 `true` 再让原删除执行一遍。
   - 不提前赋值 `m.draft = expectedText`，不手工调用一次 `registry.onChange(expectedText)`，不再发 plain intent。
   - 真实 `onChange(expectedText)` 才走原 registry/native/kind51 一次。它是用户操作产生的实际改文，**不能被当成 N1 程序恢复回声吞掉**。
   - `getSelection()` 的立即结果属于 controller 修改阶段；只有关联到实际文本回声，才成为新文本的选区证据。
   - 不等待 DidDelete：这次成功样本没有它。正常消费不能以它作为完成条件。

   纠偏观测状态也不能在 controller 返回时立即清掉。若下一次输入先到，而预期文本回声尚未出现，不能拿旧 draft 再纠偏。若平台把删除与后续输入合并成一个 `onChange`，不得补造缺失的空串回调；记录真实变化和未独立观测的纠偏结果，是否满足“一笔删除一个撤销单元”由生产验收判定。

   缺回声、异常或观测不符时，按捕获的 mount 请求既有 N1 校准；**恢复目标来自当前 owner，不来自冻结旧文本**。超时只用于终结等待，不能用来猜操作是否属于 compound。

4. **compound replace 是仍然不能用严格形状 guard 消除的风险**

   以下两个操作可以具有完全相同的首个可见回调：

   ```text
   A：退格，删除 U+0301
   B：替换重音，先删除 U+0301，随后插入另一重音
   ```

   当 `onWillDelete` 被调用时，`draft / collapsed selection / direction / offset / deleteValue` 都可能相同。此时整簇纠偏会让 B 多删基字母。

   **这是信息不足，不是再加一个 substring 判断就能解决。** 当前证据证明了独立 backward 样本，没有证明上述回调只能来源于独立字符删除。

   最小契约应明确：只有平台来源能够证明为独立方向删除时，才允许提升为簇操作；已知替换、组合及程序化范围操作不提升。接下来必须用真实系统候选替换、自动修正等对照判断：

   - 若平台给出可在删除前识别的不同状态，可以加入共同 guard。
   - 若产生不可区分的同形前缀，就不能对该来源普遍启用纠偏。不能用时间窗口、下一次插入或“没有 preview”补猜。
   - 原异步 request/receipt 方案也不能解决这项意图缺失，因此它不是必选退路。

   程序化 `deleteText` 不触发 `onWillDelete` 本身没有问题：簇策略作用于真实删除入口，程序范围操作保持精确。不能为了覆盖程序修改，在所有 `onChange` 上反推键盘删除。

5. **服务不可用、换版和恢复中的处理**

   | 情况 | 最小处理 |
   |---|---|
   | ICU 不可用或无法证明边界 | 对需要簇保证的 collapsed 删除取消并具名拒绝；不降级为标量或原部分删除 |
   | 查询后、controller 调用前 mount/文本修订改变 | 计划作废，不调用旧 controller |
   | 平台已改文，owner 外部换版 | 原 kind51 拒绝后复用 N1；不重算新版本删除、不重放用户操作 |
   | 恢复进行中 | 不进入纠偏；恢复回声与真人输入继续按 N1 原有分类和仲裁处理 |
   | 旧 mount 的迟到 change/selection | 不修改新 mount，不借新 context 发送 |
   | controller 异常，修改是否发生不明 | 不放行原删除、不自行回写旧文；保留实际观测并进入既有校准 |

   因此，“没有新增异步恢复间隙”成立；“不会再遇到异步 owner 拒绝或恢复”不成立。后者仍是原输入链路需要承担的边界。

   新 ICU 片段的严格解码、内部 byte offset 映射、root iterator、边界校验及释放顺序符合上一轮 ABI 方向；未见需要退回 stub 的机制理由。[生产片段](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp:5435)

   普通 HAP 的 root 边界原数也成立，包括 CRLF 的 UTF16 边界 `0,1,3,4`。[ICU 原证](/Users/jiangxuanyang/Desktop/cangjie/artifacts/h-overnight-final-20260930/platform-delete-probe/initial.hilog.txt:393) 但它证明的是该 HAP 中的 ICU oracle；生产 ABI 的 UTF8 字节映射、加载方式和失败出口仍待目标 HAP 验证。不要为了 shell CLI 缺 rules data，先去改变已经能工作的应用运行环境。

最小验收应保留以下几组，均不得靠重试或人为等待放宽判据：

| 验收 | 有判别力的结果 |
|---|---|
| 生产 ABI 冷启动 | 不先运行 `icuProbe` 预热；通过生产入口核对完整簇、内部 byte offset、非法 UTF8及不可用状态 |
| 原生产 RED | 同一新 final HAP 原序列一次输入；第四次删除后完整 owner 精确 25 B；一笔删除、一笔历史、undo/redo 精确往返 |
| 连续输入与重入 | 紧接 X、连续退格、重复回调；记录 controller 调用次数、真实 onChange、kind51 和 owner receipt；159 ms 样本不能代替这组 |
| 明确范围与 compound | 非空选区、多簇、候选替换、自动修正；不得多删基字母，不以 guard 形状相同宣称独立删除 |
| 失败及 N1 | 换 owner、换 mount、恢复中输入、controller 抛错、缺回声；零重复删除、旧回执不写新 field、失败不记成功 |

**本轮裁决是采用同步路径继续验证，撤销“必须新增异步 owner 删除事务”的要求；保留 compound 来源可区分性和生产链路验收为未决。** 当前 WillChange 实验版只作为失败反例，不作为候选实现。此次仅查了指定材料，没有修改、构建或操作设备。

