# 大阶段：正常窗口显示、输入与缩放一致性

2026-09-13；指导下发，原目录 Terra/xhigh 负责，直接复用 Luna/high。此阶段包含上一阶段未闭合的真实窗口与最终产物验收，不能以新阶段名称把欠项标为完成。

## 目标与取舍

使用公开组件与正常 macOS Host 的开发者，能够得到文字方向正确、可读、命中与选区对应，并能在调整窗口或显示缩放后继续人机共同编辑的应用。实现和修复落在框架通用显示、输入与失效路径，样例仅作为消费者；不新增业务工具，不改仓颉、自绘/GPU、窄桥接或模型无关方向，不安装或覆盖用户应用。

六主线判断：组件/布局及语义动作已有实际接通，资源/调度和有序GPU合成已有受控证据；文字重复准备和临时模式切换已得到根因修复。当前短板是这些能力在正常窗口、坐标/像素比例变化和真实输入路径下是否一致。本阶段优先打通显示、输入、布局和资源失效，最终绑定普通包消费；超长单段首/中约171–179ms仍为明确限制，不在本阶段无限扩TextKit架构。物理IME、VoiceOver和实际显示器呈现与程序化/截图证据分别标记。

## 复用与承接

- 复用 `composable_ui.cj` 的单一布局、稳定身份和resolved clip，以及 `composable_ui_window.cj` 的事件/owner确认事务；不另造正文、布局或调度真相。
- 复用 `cjgui_internal_renderer.m` 的有序形状/图片/文字纹理、唯一活动TextKit、失败保留与有界重试。旧经验见[设计导航](DESIGN_INTENT_INDEX.md)和[避坑研究](../research/gui-framework-pitfalls-intelligence.md)：重点处理坐标转换、显示比例失效、焦点/关闭重入，无变化不重绘，避免平台对象进入公共API。
- 复用正常Host、文档/规则集消费者与公开client/导出脚本；旧文档中的禁止实施语句不恢复。[连续编辑阶段](2026-09-13-continuous-editing-local-update-milestone.md)的重复准备和临时mode toggle修复按受控源码证据接受，但最终修改后的导出及窗口证据未闭合，本阶段直接完成。
- 文档Host旧报告有中文工具输入丢失/拒绝、文字反向观感；保存了正文读回但没有对应截图/事件。不视为已排除问题，也不能先认定renderer错误。之前Host验收早于最后生产输入修复，不能冒称覆盖最终产物。

## 完整实施范围

1. **正常窗口显示正确性与修复。** 用隔离正常Host先保存可复查窗口截图、源码/产物身份和同次公开正文。使用少量能辨别上下左右的内容（多行不同开头、中文/英文/emoji、静态/活动文字和图片方向），查清反向观感来自文字bitmap→纹理UV/裁剪、叠层/截图还是其他原因。若发现框架缺陷，先用生产绘制路径的针对性像素/几何证据复现再修；不能只靠AX正确、几个纯色像素或截图后处理证明字形方向正确。正常截图只读检查即可，不要求逐像素跨系统字体完全一致。保存必要截图给指导复核，不把生产常驻截图/全文日志作为产品功能。
2. **尺寸与backing scale变化的完整更新路径。** 当前源码可见Metal view在setFrameSize和viewDidMoveToWindow更新drawableSize，需核实同point尺寸仅backing比例变化的通知与资源失效是否接通。补齐实际缺口，让drawable、文字/图片派生资源、裁剪、命中、选区与系统候选定位在同一布局/比例下收敛；无变化不重建。resize和滚动时保住对象身份与正文，失败后保留旧有效资源并有界恢复。沿用8MiB/文字资源、24MiB/已接受scene及现有生命周期，不放大常数掩盖问题。没有第二显示器可用时，用真实更新入口的受控比例变化验证并标记物理多屏未验，不能改用户显示设置或宣称跨屏实测。
3. **正常Unicode输入与外部接续。** 文档多行和另一现有单行Host中核对GUI工具输入、系统粘贴/组合适配、选择替换/删除/undo与外部同对象修改；先区分工具输入不支持、事件身份过期、实际框架丢输入。公开正文、UTF-8范围、可见选择必须对应，不放宽权限/CAS或吞真实冲突。不把ASCII成功当中文通过，不把粘贴/程序化marked text当真实系统IME。系统IME若环境允许仅做一条系统组合提交/取消/候选定位接续；无物理输入证据明确未验，不因此停止其余实施，也不自行研发输入法引擎。
4. **正常负载和观测可靠性。** 延续普通窗口与256混合场景、现有100KB多段热点即可，不增加庞大矩阵。仅对受影响路径做针对性回归，确认新增显示/scale失效不恢复重复raster/upload、idle不无谓提交、关闭后资源收敛。现有test-only glyph诊断会大量输出并破坏日志行，诊断应显式按需开启；性能默认使用有界标量并分离stderr，不拿丢行数据补齐样本或虚构p95。已有完整样本仍保留，不为了重建旧基线反复跑历史矩阵。GPU完成、截图可见、实际presented事件和物理显示延迟分别表述，工具不可测就不推定。
5. **最终源码和迁移消费闭环。** 最后生产改动后统一构建相关正常Host及导出preview，核对源码payload与导出payload、实际链接/资源来源和bundle身份。两消费者在最终产物上完成适用的输入→公开读取/授权修改→GUI继续操作与正常关闭；复用已有未受影响部分证据，只补受影响路径。当前旧preview指纹不能继承新的renderer修复。可移除作者目录依赖的临时消费仍在既有授权内；不安装、公证、签发发布或接触用户已有实例。完成必要公开文档及唯一ACTIVE状态更新。

## 分工、验收和停止条件

Terra主导坐标/比例、事务、TextKit/GPU生命周期根因和跨层设计；Luna承接明确完整包，例如隔离正常消费者与截图/正文证据、确定方案后的局部实现和针对性验证。写集隔离，默认一个并复用，子代理向Terra报告；指导只接整阶段或重大升级，不重复跑实现/测试。无独立有价值工作就等待通知，不轮询刷消息。合理消耗可以接受。

阶段交付必须给出：已实现/原有即正确的显示与scale链路、已报告视觉/输入疑点的可复查结论、两正常消费者最终产物的具体正文与截图、相关针对性测试/build/差异检查、最终源码/导出/bundle绑定，以及未验限制。不能靠缺少旧截图宣告异常消失；若当前正常窗口确实无法复现，可记录复现条件和当前证据，保留旧报告的不确定性，不无限追丢失的历史物料。

先完成实际链路与必要修复，不每修一个点停工；同一场景失败按AGENTS累计升级/K3规则，已有K3环境无响应不算有效建议。需要第二排版图、改变正文所有权/公共范围契约或大改渲染路线时带证据升级指导。锁屏跳过GUI，继续比例事件/资源失效和确定实现，保留桌面欠项。原目录，不切分支、不stage/commit/push、不改系统锁屏/显示设置；使用隔离bundle与临时数据，关闭后不要用会自动重启应用的CUA查询冒充清理检查。完成或实质阻塞立即报告指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。

## 2026-09-13 执行交付记录

### 已实现

- `CJGuiInternalMetalView` 统一处理 resize 与 backing-properties 变化；scale-only 变化会使 geometry revision 进入真实的 prepare/submit 路径，而无变化场景仍保留快路径。受控 `2x -> 1x` 验证得到 drawable `1960x1240 -> 980x620`、revision `2`、build/layout/submit `1`、raster/upload `2`。
- 生产文字纹理由 AppKit `CGBitmapContext` 行序上传 Metal 时，文本专用地翻转 V 坐标；图片资源继续使用其既有坐标。方向判别 GPU 像素断言由修复前 `upper=36,20,10,255 / lower=255,0,255,255` 变为 `upper=255,0,255,255 / lower=36,20,10,255`。
- 正式 preview exporter 现在包含三个文档 core 源文件。正式消费脚本从导出的 preview 重建既有 UI、协作与文档消费者，移动到含空格路径后仍验证来源、依赖、资源、公开空标题、过期拒绝及正常关闭。

### 最终隔离 Host 证据

- 没有启动、安装、覆盖或查询用户截图中的 `CJGUISharedOperation`。唯一窗口是临时 bundle `org.cangjie.cjgui.direction-fix-host-20260913`，从临时 preview 构建；构建日志将 runtime、native、依赖全部指向该 preview。当前 renderer 源文件 SHA-256 为 `20f1a1512d58be233aaa737f925e4f316be3e060cb0aed80d6c6f7a0b1cb9e44`，Host 可执行文件 SHA-256 为 `f7e181e0e5358b68863008a0ff089f15bab0d18a3e99036b033a293c3041547b`。
- 原始 macOS 窗口在调整大小前后均显示正常方向的 `TOP/LEFT/RIGHT/BOTTOM`、中文、箭头与 emoji。真实坐标放置光标后，同一 `documentVersion=0` 内容给出 owner 的 UTF-8 byte `219..219`，同时窗口交互投影给出 native UTF-16 code unit `101..101`；该对应关系来自同一版本、同一正文，而非将两种单位混为一谈。
- 外部受权 `REPLACE_RANGE` 以目标 `documentVersion=0` 追加 `\\n外部中文🙂`：RESULT 为 `APPLIED=true`、`CONFLICT=false`、`0 -> 1`。公开 `READ_RANGE 7101 258 275 1` 读回 17-byte UTF-8 文本；窗口 AX 与截图同时显示新增内容，window frame 4 已 accepted/submitted/completed，pending/native failure 均为 `none`。

- 隔离 Host 已经原生窗口关闭路径退出；日志依次记录 `post close request`、`window will close`、`destroy complete` 与运行时 shutdown。其私有 descriptor 已清理且进程列表无残留；关闭后没有再查询该 bundle，避免自动重启误作清理证据。

### 本轮验证与边界

- Cangjie 1.1.3 下 `cjpm build --skip-script`、场景渲染、AppKit 文本、窗口 controller 和正式 preview 消费校验均通过；`git diff --check` 与两份脚本语法检查通过。构建仍报告既有 deprecated/unused warning，未将 warning 伪称为零。
- CUA `typeText` 的 Unicode 丢失与 paste 超时仍为工具输入路径异常，现有证据不足以完全区分工具未发送和原生拒绝，未作为框架输入失败或成功证据；本轮外部 Unicode 写/读回为真实受权协议路径。物理键盘/系统 IME、VoiceOver、真实多显示器、实际 presented 事件、安装/公证/发布仍未验。


### 指导验收与接续

指导只读核对文字专用V翻转与图片路径分离、backing通知/真实prepare提交、正式导出闭包，并直接查看执行任务原始截图（工具调用call_ZkgKKKAHl0no24oMuGLaS2Xb，原图解码副本`/private/tmp/cjgui-guide-direction-review.png`）：多行中英文、箭头、emoji和外部追加内容正向。当前renderer hash与执行报告一致。实际完成的导出原始输出为`/private/tmp/cjgui-preview-document-closure-green-2.stdout`，source/preview payload均`f0266b8d824b8d3c1baa6161a42c65c499f3c6bc1701bafb0003d89c63d5ff6f`，指导对当前源码只读重算相同；exporter hash为`b781d466e41a978fd5cf028db6fcecc017851b498edd7a71a4acd96de23cfab5`。该次UI/协作/文档消费build、迁移来源与协作公开接续/关闭有各自证据；不能把名字带final却无成功尾行的日志当通过。指导未重跑开发测试、构建或操作窗口。

以上修复与受控/正常窗口范围接受，前阶段最终源码导出欠项已闭合。物理IME/VoiceOver、多屏/呈现事件及工具Unicode原始事件归因仍按上文保留，不把这些标为通过。截图中部分控件label/value重复是非阻塞可见问题，随相关工作处理，不扩大为样例美化阶段。后续进入[低延迟编辑与文字资源增量复用](2026-09-13-low-latency-text-resource-milestone.md)，不继续重复本阶段整套验收。
