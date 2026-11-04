# Mac 集合视口接入与连续导航整包

2026-11-01正式接续。沿用户“指导自行复核、安排完整阶段，持续实际修复并集中报告”的授权，由现有主执行 `01a18297-1b22-7f63-ad2d-e49f066db253` 连续完成，直接回指导 `01a17207-04bc-76a2-90c3-99c8c5060423`。实际复用 `gpt-6.1-terra` 与 `gpt-6-luna`，档位按难度；不开新线程/监控、不恢复旧Sol/DS、不等W/H。

## 为什么接这一包

按[设计导航](DESIGN_INTENT_INDEX.md#shared-code-entrypoints)、[首版范围](2026-09-26-framework-capability-roadmap.md#first-mature-version)和[完整性视角](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#规划大阶段时的完整性视角)，本包推进普通应用中人和外部系统对同一集合的定位、滚动、选择及继续编辑。组件和滚动算法已有实现；要交付便于应用直接接入、能在真实混合界面连续使用的公共能力。

[上一包的性能调查](2026-10-31-macos-responsiveness-accessibility-package.md#guidance-performance-route-boundary-20261031)停止该采集路线，保留性能优化未得、四类各20及16/32ms未达、VO系统通道未验。B/C/D只增加了有限证据，不能冒充性能交付；不继续profile/新trace/调缓存或GPU参数，也不把这些门作为本包开工条件。新增真实卡顿、丢输入或资源增长仍按实际缺陷处理。

基底为共同根当前32e/锁c6a9的精确消费输入：相对冻结SDK741e含已接受Rules字段选择投影及默认OFF的原有writer观察接线，保留其3个production输入和1个测试差分。Native aca8、Window82a、text_session c605、Core50c、renderer_session fe19未做性能改动；SDK741e不原位改。已核字段源/TDD及正常三笔/保存关闭按范围复用，不重开Source/Visual/外写/历史矩阵。

## 已有入口与本次实际缺口

- `runtime/cjgui/src/composable_ui.cj` 已有共享 `CjguiComposableUiScrollViewport`、虚拟列表状态/稀疏高度索引、`revealKey`、候选/accepted分离和嵌套 `CjguiComposableUiRevealPlanner`。`adoptSharedViewportRequest` 已把集合请求接到共享viewport。
- 当前公共固定/变高列表工厂只接source/state，未传 `scrollViewport`；普通ScrollArea已有绑定viewport的公共重载。Rules正用未绑定的变高工厂，故其列表没有该显式共享绑定。这是可复用接入的具体缺口，不等于已证明滚轮实现错误。
- `composable_ui_window.cj::revealVirtualListItem` 已按accepted目标、语义ID、同一viewport引用及stable key处理显露请求，并已有嵌套裁剪规划。**复用它，不新建reveal状态机或另一套坐标/滚动权威。** 公共交互读回只列显式绑定viewport，且现有摘要上限4，不能通过无界扩大输出来补观察。
- `shared_operation_core/client.py::get_window_targets` 枚举的是获授的**窗口**目标，非窗口内节点或列表行。该请求在Rules被拒绝是现有授权事实；不能为查看嵌套列表扩大该权限，也不能以此推断列表功能缺失。
- 原 `rules-list-viewport-normal` 的page:-1虽然工具返回ok，但没到达record2；保“目标未达”，不算生产RED或成功。先核实际源顺序/筛选、稳定key与可见范围，不能把“第二个可见行”等同于resource2，也不能混用截图像素与窗口点。

## 连续完成的工作

1. **补齐公共列表的共享视口接入。** 复用上述状态、布局和候选提交，在公共固定/变高列表工厂提供兼容的显式viewport接入；旧签名/原未绑定用法保持可消费，不让应用手写底层Node来接普通列表。请求偏移、候选范围和accepted范围仍各按既有责任；一份viewport绑定到错误集合或已退役实例时按既有身份拒绝。不要复制全部列表算法或引入native句柄。
2. **让滚轮、键盘与稳定key显露走同一状态。** Rules接公共入口并清除确有重复的应用侧滚动处理；确保一次原始动作不会被窗口和应用各消费一次。先用该现场区分工具投递、实际命中/裁剪、应用接线和共同缺陷；有生产反例才修对应层。嵌套滚动按既有轴/边界规则，键盘导航按source顺序，显露按stable key；不靠猜坐标、连续补滚或私有方法救绿。
3. **接入已有公共操作与有界读回。** 复用现有集合适配、窗口/交互投影、客户端及授权范围，使正常应用和外部调用能请求显示指定集合项，并读回相应viewport的请求/accepted偏移、目标身份及候选状态。能由已有公开路径完成就接通，不强造协议；必要的小公共扩展留experimental、兼容旧调用，并接共同目录/错误说明。显示请求接受不能冒充已经呈现；显示本身不偷偷选择/Apply/改业务版本。可见性不充当数据权限，原已授权的屏外业务操作仍可用。摘要超过上限须如实给范围/截断或既有有界定向查询，不物化1000行来凑完整输出。
4. **把动态更新与脏会话纳入同一能力。** 按现有sort/filter/source revision、变高测量和stable-key锚处理显露后的重新排序、改变行高、目标暂时被过滤或移除；目标未找到、错误viewport、旧scene/代次和拒绝候选均不能跳到兄弟集合或污染旧accepted界面/草稿。焦点及文本首键沿已接受的普通输入路径，不另开输入交接状态机。
5. **实际跨消费者复用并交付。** Rules作为1000条主消费；再用已有mixed/generated集合接同一个公共入口，换一组业务key与布局，证明应用不复制滚动/输入机制。只补本能力短链，不复制大应用或历史矩阵。最终一次导出唯一开发候选，更新公共接入示例/声明/来源与失败语义；包外消费仅检查本次公共入口和对应短链，不重验所有SDK能力。

## 验收与分工

Terra领公共viewport/列表/显露接入及必要共同修复完整块；Luna领Rules/mixed接线、公共客户端正常消费及精确交付块。主执行先分清文件，重叠源码、native、共享target与前台统一集成/串行，子代理只回主执行，不逐函数派工。

先留能区分的源级反例，重点是公共工厂的绑定、一次滚动的单一消费、同几何兄弟viewport身份、stable key重排/过滤及拒绝保旧；适用旧测试复用。只有改native/FFI才补对应边界，不为每个Cj接线重做跨线程全矩阵。通用机制不明确时局部参考GPUI/Slint等既有入口，仅借鉴，不引依赖。

汇合后以默认OFF完成一条预先写好目标与预期的正常会话：

- 同1000条、两个有不同正文/草稿的owner；在实际可见的内列表投递一次滚动，核该viewport的真实变化、实际可见行/accepted几何与正确owner。工具ok或仅外层变化不能顶替内层结果。
- 通过已有公开入口按稳定key显示一个已声明的屏外项，等待实际accepted后人点击/键盘选择并编辑；公开读回完整owner正文/版本。目标选择来自本轮source顺序，不预设resource2必在一页内。
- 保另一个owner草稿，做一次有意义的sort/filter或行高更新后继续导航和编辑，Apply/Cancel及焦点首键只补受影响部分；完整保存、正常关闭、端点释放。
- mixed/generated只补对应公共入口、不同key和一次运行中变化的短链。拒绝反例在源级/直接接缝证明充分的，不全部重复到GUI。

输入每次只发一次，不用延时、重投、补点或AX写刷绿。合法的等待accepted状态不是重复动作；若方法/坐标前提错误，先修方法并保原件，不将原失败删除。连续两次同工具失败先离线收束，不启动第四个同义实例。采集准备放启动前，长分析放退出后。旧性能A/B/C/D、三笔ON和VO失败不在本包重跑；新的实际性能退化/资源增长只按影响验证，虚拟化不得变成构建全1000行，读回不得触发刷新。

本包完成须交付可复用公共接入、真实修复或接通收益、两消费者按范围的实际消费与唯一候选；不以测试数量/日志代替收益。普通接线、编译及已明根因修复持续执行，只有真实架构/重大正确性/资源冲突或低收益重复才集中升级。直接向指导集中报告，不逐小步停工。

## 容量与收尾

沿[AGENTS容量规则](../../AGENTS.md#artifact-space-budget)，原累计不清零、不另加10GiB。五部临时≤3GiB，E最终≤15.25GiB/峰≤16.5GiB，DS子范围仍计入E、最终≤2.75GiB/峰≤3.25GiB；写盘前重新核实际余量，宿主峰后≥20GiB。上一例E距最终上限仅约44MiB，这不是新构建额度。

唯一约260MB图直接复用，不为阶段切换先删后造；受影响mixed编译复用已有目录，串行并计入同一总峰。最终新App/SDK/必要RED-GREEN保全后回收本线可再生图和中间产物，使最终留存回到原cap；旧32e必要原件/精确档案及SDK741e仍保护，不猜删他方。若产物预计超出最严边界，先在本任务说明可回收物、峰与回收点再处理，不静默扩容。默认仅当前及最近可用交付，日志64MiB单文件/512MiB当轮并服从更小余量；runner成功/失败/取消finally都收尾。

报告给实际新增/保留/释放、宿主可用空间、仍在用目录及理由。无Git写/顾问/新监控，不改W/H/Linux冻结源或包，不关他方/用户实例；不要求用户再次让出已授权桌面。原性能/VO未完成状态保留，新包直接推进。

<a id="guidance-review-20261101"></a>
## 指导复核与下一包（2026-11-01）

按本包实际受验范围接受：[集中原件](../../runtime/cjgui/artifacts/ds51-normal-workspace-delivery-20261024/section-18-20261028/combined-20261028/mature-package-20261029/input-exit-performance/performance/collection-viewport-navigation/RESULT.md)。指导已读共同四文件相对保存基底的完整差分、Rules接入差分及关键断言；未发现需要回退的生产问题。晚测量RED与最终同图六项原日志支持其边界，早八项仍按各自源身份复用，不升级为最终图全量通过。

实际SDK630项SHA/长度全相符，锁e30f/content6a65；Core c895、Window804b、generated511b、prepared cef3在共同根、SDK、Rules641锁和最终测试锁对应，Mixed实际2780ad provenance也取同四源。Rules35/Mixed69成员归档逐项复核路径、类型、mode、size/SHA，签后EXE979e/bcae匹配；没有重建、重启应用或重跑测试。

Rules原文件/保存文件1000×5字段独立复算：仅owner1000.label增加V，头部和其余字段不变。九组原始完整草稿/应用正文与版本、selected-context围栏通过；两张同轮JPEG复核显示目标选择按钮确在内层、Apply正文反馈对应。原始日志SHA与normal0/端点[]相符，Rules有close_permitted/destroy，Mixed有destroy和明确守卫关闭原件，不补称其日志也含close_permitted。Mixed公开typed-card三字段及Apply/Cancel、过滤返回和cardA草稿/字段版本保持相符；全局state_version正常推进，不冒称所有版本不变。

边界保持：Mixed编辑是公开业务action，不是原生键盘；WINDOW_PROGRESS/INTERACTION未获授权，不能以root6200 accepted context替代完整viewport查询，也不能把owner-ID当opaque window target。缺独立Mixed截图/GPU-presented与filter-clear单独shell退出标记仍保留；本轮无需因此重投动作。旧元数据纠正仅修身份引用，不改不可变原件。16/32ms、四类20、VoiceOver仍未完成。

两图target/.cjgui确已不存在，原E/DS公式核对相符，当前宿主约181.63GiB。630项之外另有两份SDK客户端运行产生的`__pycache__/*.pyc`，不是新的源载荷；下一包开工核归属后清理并约束客户端不向冻结SDK写缓存，不重导本SDK、也不为此单独回一轮确认。直接进入[普通应用键盘与公开交互接入整包](2026-11-01-macos-keyboard-public-interaction-package.md)。
