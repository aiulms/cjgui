# 大阶段：可复用控件与人机共同编辑交付

2026-09-13。原执行任务 Terra/xhigh、原目录持续实施；指导负责审阅和取舍。当前组件刷新及工具链升级的报告已收到，指导抽查了事务提交/拒绝路径和 runner；本轮没有代执行运行测试。

## 目标与主线取舍

让应用开发者通过仓颉公开 API 组合可正常使用的表单、选择列表和编辑区域，人用键盘/鼠标/输入法编辑，外部系统通过真实业务动作接续。完整交付通用控件、两种应用消费、独立接入与交互成本，不能只改示例外观或逐个按钮停工。

复用[设计导航](DESIGN_INTENT_INDEX.md)中的 composable 节点/主题/布局、组件身份和刷新 participant、TextKit 输入代理、焦点/命令、AX、共享文档/表单 owner 与公开客户端。复用[输入阶段](2026-09-13-text-composition-accessibility-milestone.md)已有程序化组合/Unicode/AX回归；未验的物理输入不重复包装成新实现。[避坑原文](../research/gui-framework-pitfalls-intelligence.md)有关文字不等于绘字、事件重入、状态归属与无变化不重绘继续约束本轮。

六主线中，组件身份、布局、自绘/资源/调度已有基础与有界成本证据；当前优先降低开发者重复接入代码，并证明人侧真实交互与外部接续。保留仓颉核心、GPU自绘与窄平台服务，不改成原生控件套壳或 Agent 产品。新编码、完整富文本、多平台、动画系统不属于本阶段；长文本尾部和 presentation 未证实边界继续保留。

## 必要收尾与实现

1. **配套升级收尾先接通。** 当前技能目录仍递归发现 `cangjie-legacy-1.1.0-backup-20260913T120000` 内六份旧技能：把已核实的备份可恢复地移到所有活动 skills 根目录之外，记录实际回退位置，不删除未知文件。确认新 `cangjie-coding` 检索正常；当前会话已加载内容不能宣称瞬间卸载。normal runner 仍消费 PATH/CANGJIE_HOME，文档不能把 manifests 等同自动选择编译器：核实正常入口，使用项目局部的明确环境入口或清晰版本诊断，保留显式覆盖和旧全局环境。修正 ACTIVE 中仍称 probe 待收口的过时行。旧 no-resource guard 按真实桥接边界改为有效检查或明确退役并指向替代，不为了绿灯恢复旧禁令。
2. **完成刷新公开消费边界。** 上轮缺少新 participant 的独立消费记录，本轮安排独立 Luna/Terra 只按公开文档消费新流程，跑更新、可恢复失败、重试、命令和 owner 读回。源码中 buildUi/participant 调用没有明显异常清理保护；核实可恢复异常契约，用真实抛出验证能否留下未结束 candidate。若会污染后续刷新，在框架层修正清理或明确错误传播，不捕获致命内存错误伪造恢复。链接缺符号只说明 seam 未实现，不能作为旧行为失败证据；补相应状态断言/反向验证即可，不重跑所有历史红测。
3. **把常用控件做成可复用框架能力。** 先用两个已有消费者找出重复构造/事件/标签绑定，补或提炼通用按钮、文本/数值编辑字段、开关、选择列表的组合与绑定入口；已有能力足够则迁移复用，不平行造同义 API。支持标签、提示/校验错误、禁用/只读、焦点与选中状态；使用主题/测量布局，不硬编码示例字段或固定像素补丁。字段值/规则仍属应用 owner，组件保留必要交互状态。普通用户可读文案不能显示 false、内部错误码或用省略号掩盖布局问题。公共 API 仍标实验等级，窄 native 不暴露对象句柄。
4. **一次声明接通人侧和外部侧。** 同一控件的业务字段/动作、可访问标签、外部语义关系应有明确复用关系，减少应用重复维护映射。人改后外部读到草稿/选择；外部已授权修改后人能继续编辑；旧版本冲突、禁用/只读和真实业务约束仍准确。允许屏外授权批量，不以界面确认外观增加授权。复用已有传输与 owner，不绑定模型或引入聊天框。
5. **完成普通桌面操作。** 两种布局/业务的正常宿主消费，至少包含列表重排/删除、字段校验、编辑与撤销、弹层或菜单。键盘 Tab/Shift-Tab、Space/Enter、方向键、Escape、编辑快捷键及焦点样式符合对应角色，旧对象移除后不串输入。文字复用既有输入法/TextKit路径，修复实际发现的问题；系统中文候选、提交/取消及 VoiceOver 有条件时实际操作一次并记录。锁屏或工具不能驱动系统输入时记具体阻塞，继续控件、语义、独立消费和成本工作，不循环等待，不以粘贴/AX替代系统验收。

## 验收与成本

独立执行者与主执行写集分离，同目录不创建 worktree；用户 RuleSet 同 ID 实例保留，使用隔离 bundle ID 和临时数据。独立消费必须实际通过公开新 API，无需改框架 native；同时指出剩余应用协调代码。完整场景依次验证人侧输入、真实 owner 状态、外部读取/改写、人继续编辑、过期拒绝、刷新失败后重试、关闭清理。

相关源码/公共 API/native/脚本按 AGENTS 做有针对性的回归、1.1.3 build --skip-script、声明与 diff 检查；CodeLattice 当前 live root 返回 path_denied，使用允许的已知索引路径或源码补证，不绕过工具限制，也不把缺图当阻塞。性能以两个实际消费者的交互测量为准，观察输入/刷新次数、提交、队列、30轮交错负载及空闲恢复；已有结果可复用，变动相关项才复跑，不为表格补数字。独立真实模型调用与硬编码脚本分开标记；没有模型路径不伪称通过。

最终报告框架新增/复用能力、应用减少了什么重复接入、实际消费者及原始证据位置、物理IME/AX/VoiceOver/模型调用各自状态和成本限制。文档只维护当前 ACTIVE 与本阶段交付，避免新治理台账。完成即向指导任务报告，下一候选根据主要热点选择局部渲染提交/文字成本或更广应用消费，而非继续循环修同一个样例。

同场景两次实际修复仍失败按 AGENTS 调用 Kimi Code CLI 的 kimi-code/k3 只读讨论；两轮有效讨论及验证仍失败立即升级指导给方法，同时推进独立工作。无效环境调用不反复重试。不 stage/commit/push/发布、不改系统安全设置、不关闭用户应用。

## 执行交付（2026-09-13）

- 配套收尾：旧六个 1.1.0 skills 已可恢复地移出活动 roots；normal runner 明确选择项目 1.1.3、保留 `CJGUI_CANGJIE_HOME` 与 `CJ_GUI_SDKROOT` 覆盖并打印实际版本；no-resource guard 改为生产 bridge 的正向 ABI/调用检查。
- 刷新与公开消费：`syncProjection` 对 `Exception` 执行 participant rollback；probe 用真实 `IllegalArgumentException` 覆盖 build/prepare 失败、重试与 live instance 保留。独立 public consumer 仅通过公开 participant/host 接口完成候选重试、命令、socket owner 读回、旧版本 `version_conflict`（客户端 exit 4）和 close 清理。
- 复用 API：新增 experimental `cjguiComposableBoundFormField`、`cjguiComposableSelectableListRow`。Rule Set 迁移字段/列表绑定，Shared Document 迁移 candidate command participant；字段值、校验、选择和版本仍在应用 owner，public projection 复用同一 field/action relation。
- 人侧实测：隔离 Rule Set bundle 验证连续 `abc`、Tab/Space 开关、`请填写保留天数` 校验文案和 Escape 菜单；Shared Document bundle 验证 participant 命令菜单与 Escape。发现并修复“replacement projection 构造期间抵达的续写”竞态；回归同时断言文本外部删除仍拒绝。测试窗口使用临时数据关闭，用户同 ID Rule Set 进程未操作。
- 验证：`verify_composable_ui_window_controller.sh`、`cjpm build --skip-script`、两个 normal bundle build/codesign 均通过；bridge probe、独立 consumer socket 读回及 30 轮交错/idle 成本沿用本阶段当前原始样本。未验证物理中文 IME 候选/提交/取消、VoiceOver、人工像素、安装/发布或真实模型调用；AX/自动化输入和公开 socket 证据不替代这些边界。
