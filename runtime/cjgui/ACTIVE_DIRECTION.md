# CJGUI 当前方向与实施状态

更新：2026-09-20，本工作包（必要返工 + 公共组合组件扩展 + 两个领域消费 + 性能验证 + 最终导出）已由执行 AI 完成并自验。**A/B/C/D 四项全部闭合**：树契约与规范 key、共同定义退出分类、导出一致性与预登记回收、公共组合组件注册/构建接缝、规则窗口与任务消费者两处真实消费、性能四场景与同变更实现对照、双窗排队时延、含新组合组件的导出汇合链与最终统一导出。测试：cjgui 61/61、generated_panel_consumer 16/16、rule_set_window_app 28/28、tree_outline_consumer 3/3、shared_operation_core 52/52、rule_set_application 20/20；共同定义验收与导出链均 PASSED。指导可据此复核；下一阶段方向由指导/用户下发。

## 唯一当前工作包

**必要返工与应用自定义组合组件的公共生成扩展。** 保留既有成果，新增“开发者写一次组合组件，手写与运行时生成共同使用”的框架接缝；不靠七种内置控件的别名冒充可扩展性。

- [完整任务与可转交提示词](../../docs/plans/2026-09-19-external-executor-handoff-prompt.md)。用户转交后由当前外部执行AI连续实施；指导只做规划/审阅，没有启动开发。
- 原Codex执行任务及30分钟自动化仍暂停，鸿蒙仍暂停。本页不恢复它们。
- 外部执行者主写入；复杂根因/公共契约按AGENTS用Terra CLI/xhigh聚焦只读咨询。可按需将完整桌面包交CLI Luna/high，确定性脚本够用无需为了分工强行调用。

## 已接受范围

- 第二消费者字段声明、owner事务规则和writer/argument派发统一，title标量长度/required/业务冻结测试及notes新增字段已落地；规则窗口真实CGEvent数字输入、共同拒绝与恢复，以及1..365/1..730两启动配置有原始证据。
- 树changed-key更新、规则真实owner接线、公共树消费、全树groupKeys修复成立；单可见对象index_calls=0是有效工作量证据。原有结构回退、折叠选择保持继续复用。
- 本轮含空格导出四实例来源及两生成消费者控件编辑、S2续写、非法候选后继续编辑接受。日志在 `/private/tmp/cjgui-preview-chains/cjgui preview 20260920101219-40829/`；共同定义日志在 `/private/tmp/cjgui-common-definition/20260920100951-38546/`。
- 两窗正常循环有界进展与一活一闲独立性接受；50/2/52/20/24/11包测试沿用执行报告。A3、剪贴板、既有键鼠、100条批量接续与候选事务不无故重验。

## 必要旧项与新增能力

**执行进度（2026-09-20 第三轮，证据见[阶段页本轮记录](../../docs/plans/2026-09-19-runtime-generated-ui-milestone.md#执行记录2026-09-20-第三轮a-四项返工闭合公共组合组件接缝阶段页留档)）**

- 旧项 1、3、4 已闭合：树内容补丁只改显示内容且声明不一致整批拒绝（新增 `pruneSelectionToSelectable`）、
  Catalog 规范 key 精确核对（畸形 key 不改内容/版本/通知）、source 未武装/版本倒退不走快路径、可见单行变更当步从
  **已接受场景**读到新文字并有真实提交（新 API `acceptedNodeText`）；共同定义验收脚本按
  FAIL(1)/BLOCKED(3) 如实传播并有三条有界负对照；导出一份 56 文件清单同驱 cmp/逐文件 hash/汇总指纹，
  manifest 同步，启动前登记身份 + 未握手候选精确回收（对照实例不受影响）。
- 旧项 5 的**框架接缝**已完成并通过 cjgui 59/59：`registerComposite`（拒绝内置覆写/重复/未知 field、action/未声明 preset/
  超预算/重复元素 key）、holder 用框架分配的实例+元素身份与解析后的 owner 绑定调用应用工厂，并对**真实展开子树**
  审计预算与身份（重复/外部/漏元素都拒绝且保留旧场景），公共 `resolveIntent` 把 field/preset/action 控件事件解析为
  字段编辑或动作（preset 不再因字段是 INTEGER 被吞掉）。
- 旧项 5 的**规则窗口消费已完成**：新增 `retention_integer_edit.cj`，预设值由字段自身声明边界派生、一份
  `buildEditor` 同时供手写对话框与生成区域；生成消费者改用公共 `resolveIntent` 适配器（INTEGER 字段上的预设按钮
  不再被吞）。规则窗口 28/28；共同定义脚本新增 step9e/9f 用**真实点击**驱动两个区域的预设按钮
  （`label='设为 90'` / `'生成预设90'`，`input=real_desktop_control driver=ax`），整脚本 PASSED exit 0。
- 旧项 5 的**任务消费者消费已完成**：新增 `task_edit_card.cj`（title+notes 编辑卡，只改应用注册与组件文件，
  框架 kind 分派未动），消费者派发改用公共 `resolveIntent`；新增 `installIntoEveryRecord` 为每个暴露 target 安装
  权威规则（用例钉住“未接线的 target 不会被 owner 拒绝”，故接线是应用责任），第二条记录的越界/冻结拒绝、重排身份
  保持、非法候选后旧卡可写均有用例；generated_panel_consumer 16/16。
- 旧项 2 的**四场景重写已完成并验证**：cold 用新 holder 的首次提交、hot 每轮改真实声明布局属性（并核实已接受面板
  带该值，同时说明子节点 rect 相对父级、不用几何相等当证据）、field 每轮换值且不重提结构、idle 不 bump 不提交并
  断言零 build/提交与场景不变；强制同内容刷新单独命名（如实记录：重建但不产生新场景/不重复 native 提交）。
  新增只读 `acceptedSceneDump/acceptedNodeValue/acceptedNodeBounds/acceptedNodeCount`，等价性落在被测实例上
  （fields=30 → declared/accepted 均 61）。cjgui 59/59。
- 旧项 2 **已全部完成**：新增同变更 patch/rebuild 对照（同进程同起点，patch `index_calls=0`/3157µs vs
  rebuild `index_calls=10001`/11326µs，两者已接受文字相同、物化均 12 行），以及两窗过同一正常循环的排队时延
  （A 持续滚动、B 经既有入口排队，20/20 个样本都在**下一轮**内被 owner 应用并场景接受，p50 入队→接受 17.4ms、
  p95 33.7ms，停止后 10 轮零重建零提交）。诊断中澄清并记录：屏外行的 content-only 补丁不产生新已接受场景是既有
  契约，不是调度饿死。cjgui 61/61。
- D **已完成**：两个消费消费者在导出实例上跑完"公开能力查询→结构创建→真实控件编辑（键入+预设点击）→外部精确读回
  →同 key 重排续写→非法候选后旧界面仍可操作"，`PASSED exported consumer chains`；最终统一导出
  `files=59 sha256=ecb8d3c8…`，快速校验 59 文件与 59 条逐文件 hash 一一对应，四进程 `origin_ok`，manifest 已同步。
  期间修掉第二消费者真实缺陷：`fieldsPayload`/`draftText` 曾对每个非布尔字段都返回 title 的值，导致 `FIELD notes`
  的外部读回是标题；改为每字段读自己的值，并补齐 `SET_NOTES` 的外部授权。
- **本工作包 A/B/C/D 全部完成**：最终测试 cjgui 61/61、generated_panel_consumer 16/16、rule_set_window_app 28/28、
  tree_outline_consumer 3/3、shared_operation_core 52/52、rule_set_application 20/20；证据见阶段页第四至第八轮。

1. **树契约修复**：内容补丁默认selectable=true会改变不可选分组；限定为显示内容或在属性不同前拒绝快路径。修Catalog畸形key被接受、source版本未武装/倒退边界。可见单行更新当步核对实际场景文本与native提交，不能只验controller缓存及后续全量更新。
2. **性能实测修正**：cold/hot目前同一路径，field五样本仅首次改变值，no_change生成侧为空树而手写为完整面板。撤回四场景比较结论；以实际被测实例等价、每轮真实变化、完整idle基线重做。单对象patch与同一单对象rebuild对照；双活动窗口补B请求排队/owner应用/接受时延，现有两turn进展不是该证据。
3. **共同定义剩余验收**：两个数字输入仍不是两种不同交互。用数字输入与预设按钮组合补齐，并进入同一owner规则。共同定义脚本在工具输入失败后invoke兜底仍exit0，须如实传播FAIL/BLOCKED；本轮成功日志不因此作废。
4. **导出收尾**：cmp19文件与hash10文件的清单不一致，manifest过期；修启动成功但register_round前失败的精确清理。最终生产变更汇合后一次导出，复用已验证控件驱动。
5. **新增公共组件扩展**：应用预注册仓颉组合实现、属性和字段/动作引用；外部可查询并运行期组装，手写复用同一实现。复用catalog/validator/holder/身份事务/普通组件，不复制解释器；展开后也检查预算/绑定。规则预设编辑组合和第二领域组件证明可复用，同kind多实例、重排、换绑、删除与候选失败正确。

## 边界与下一候选

本包重点是通用扩展、实际显示与可信成本，六条主线取舍见阶段页。下一候选为真实模型仅凭公开能力生成/操作，以及依据测量选择的自绘/资源热点；不固化编码，不扩全控件库、Agent运行时或平台后端。

CGEvent/AX工具输入与人工物理输入分开。真实模型、物理输入、系统IME/VoiceOver、GPU实际呈现、实测内存峰值、外部TextEdit源实拖、真机、安装/公证/发布仍未验；跨窗drop旧间歇失败根因未定，有新复现再查。锁屏仅阻塞依赖桌面段，独立工作继续。

原目录，不建worktree/切分支，不stage/commit/push，保留并行修改；自有实例整轮后按身份清理，用户实例不动。约20GB历史临时目录与引用证据本包不清理。

## 历史与资产

- [最新阶段页及历史执行记录](../../docs/plans/2026-09-19-runtime-generated-ui-milestone.md)、[树阶段历史](../../docs/plans/2026-09-19-macos-tree-selection-milestone.md)、[旧状态归档](../../docs/archive/2026-09-19-active-direction-before-consolidation.md)。
- [设计意图与反馈导航](../../docs/plans/DESIGN_INTENT_INDEX.md)：复用状态归属、事件生命周期、局部更新和生成式设计，保留上下游反馈；不恢复旧Bool审计链。
