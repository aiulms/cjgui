# 大阶段：统一应用接入与本地框架预览交付

2026-09-13，原执行任务 Terra/xhigh、原目录。指导读取资源实现和原始日志，接受12小图/6大图缓存收敛、24图busy公平排空及所列加载中输入/公开owner证据；没有代执行运行测试。本轮从资源优化转向开发者可消费的框架交付，不继续无界扩展资源压力案例。

## 目标与依据

让一个未了解仓库内部的开发者，使用仓颉公开接口创建自己的桌面应用，选择是否启用外部共同操作，正常构建/启动/编辑/资源更新/关闭。交付统一宿主入口、可迁移依赖与资源配置、最小创建流程和本地框架预览消费证据。应用类型由开发者决定，不把规则编辑器做成最终产品，也不引入强制聊天或Agent。

复用[设计导航](DESIGN_INTENT_INDEX.md)的正常包消费、开发者自由组合、外部可选接口及平台泄漏教训，复用[通用Host](../../runtime/cjgui/MACOS_APPLICATION_HOST.md)、现有runner/内容指纹/原子bundle、仓颉controller/组件/事务、异步资源和shared-operation core。旧launcher和硬编码样例应迁移或明确标历史，不再作为主线默认教学入口。保留实验API等级、macOS首个平台、窄native、自绘/Metal与系统TextKit服务；本轮不宣布稳定ABI、正式发布或多平台。

六主线取舍：组件/布局、输入、语义与资源已有真实路径；现在优先验证它们能否被独立应用复用，减少应用手写循环和native打包。性能继续保留真实成本与idle回归，长文本尾部/重排热点和系统输入集成未验承接，下一候选再按消费中主要缺口决定。

## 先校正现有证据，随后完成整个交付

1. 资源报告称Notification为normal Host，但 `examples/notification_threshold_window_app/src/main.cj` 仍直接window/connection.pump+sleep并调用foreign finish，`run.sh`仍source旧1.1.0、固定15.4并手写native打包。补上上轮实际隔离源码/config/产物路径；若临时入口另有新Host则核对并接回正式可复现入口，不能凭一次临时构建声称已迁移。更正资源阶段原证据标签，不删除真实窗口行为。将Notification与至少一个不同布局/业务消费者统一到CjguiMacosApplicationHost+TurnScheduler和中央runner，去掉应用自有FFI/launcher/双pump和固定sleep；保留领域语义，别另造Host。
2. 普通开发者入口不依赖作者本机目录。项目工具链支持显式路径和准确版本诊断，仓库本机便利配置不外泄为分发契约；保留1.1.3默认选择意图，不覆写用户全局shell。资源从应用配置/bundle解析，换cwd和包含空格的新路径也能启动，错误资源/错误工具链能说明原因。保护旧产物，构建失败不破坏上一份可运行bundle。
3. 提供可复用的最小创建流程：使用cjpm规范骨架，加必要公开依赖/应用配置/仓颉入口。可以是小生成命令或模板，按实际重复成本选；生成应用不得复制renderer源码、私有测试入口或大量示例业务。应用开发者只关注controller/组件/领域动作和可选connection；生成器不能变成第二包管理器。
4. 打通可迁移的本地框架消费：一个只含公开源/必要native资源与构建入口的本地预览目录或归档，由清晰清单导出，不复制整个仓库和历史probe；在独立临时应用目录以path依赖消费，不能偷偷链接原workspace缓存/绝对目录。保留来源/许可证和实验版本说明，无远程发布/安装。已有导出能力先复用。区分源码预览与预编译稳定SDK，不承诺ABI兼容。
5. 两类独立消费：A只使用UI，无外部descriptor/socket、无Agent依赖；B自有业务模型与布局、资源、动态组件/校验，并选择性接入外部授权动作。独立Luna/Terra只按公開文档创建/构建/使用B，不复制现有example实现；外部Agent通过发现对象/动作/参数后完成真实任务并读回（可由独立模型任务使用公开client），不能仅执行预写固定请求脚本就称真实模型接入。用户数据不作为测试负载；任务若环境无模型调用则分开保留未验，不造成功。
6. 用普通应用入口跑人编辑→外部读→授权修改→人继续编辑、旧版本拒绝、资源busy/ready、退出取消或正常退出与endpoint清理。UI-only有真实窗口输入，B有完整共同操作和资源接续。框架通用问题在framework修复，应用只消费。保持系统输入法仅做集成，不自研/穷举；锁屏跳过桌面依赖继续构建/公开消费工作。

## 验收、范围与完成报告

代码、生成流程、本地预览和两类实际应用一起交付，不能写完教程或迁移一个run.sh就停工。按AGENTS检查公共签名/依赖边界/native与Host影响，1.1.3相关构建和针对性回归、diff/本地文档链接。Normal bundle资源、外部endpoint权限与关闭失败边界、无外部模式明确验证。保留代表性交互/资源负载和idle成本；只对改动相关路径复跑，不重复全套规模测试。8项/32MiB是可复用cache预算，不等于总GPU/活动纹理硬上限，文档应说清。

前阶段冷/热13/8ms与输入p95 10ms（最大80ms）为具体采样，不称普遍性能保证；无旧同步同条件对照，不声称加速倍数。原始证据按实际入口和产物身份可追溯；编译成功、GUI、独立应用、模型调用和发布分别标记。

更新ACTIVE保持唯一当前阶段，过时过程指令移入阶段历史；旧no-FFI guard若仍被新入口调用则改为有效边界检查/明确退役，不恢复旧禁令。发现仓颉上游问题先最小复现并查旧账本，向指导报告反馈材料。两次实际失败按K3规则，环境不可用不循环。

Terra/xhigh原目录，可独立Luna/Terra做消费任务且写集隔离；临时消费目录不属于仓库worktree或完整复制，禁止切分支/stage/commit/push/远程发布。保留用户正在使用的RuleSet实例，使用隔离bundle ID和临时数据。完成或实质阻塞主动回报指导。

## 实施结果（2026-09-13）

- Notification Threshold 已迁到 `CjguiMacosApplicationHost`：正式 `main.cj` 不再声明 `foreign finish`、直接 `connection/window.pump` 或固定 sleep；`run.sh` 只调用 central runner，`cjpm.toml` 只引用 runner 生成的 `.cjgui/native/lib` 两个 archive，资源/bundle 身份在 `cjgui_macos_app.sh` 声明。1.1.3 build 和隔离真实窗口均通过；窗口的 checkbox→“应用配置”最终读回“已启用”。资源阶段报告中该旧入口的 normal Host 标签已撤回，旧窗口行为仍作为历史事实保留。
- runner 不再内嵌作者的工具链绝对路径。它默认校验调用者 `CANGJIE_HOME` 为 1.1.3，或记录 `CJGUI_CANGJIE_HOME` override 和实际版本；未选择时明确失败。framework 的 CFFI renderer archive 是在首次 application build 时从 framework 的 native source 生成的本地 cache，预览导出不携带预编译库；应用 bundle 仍使用原子 staging，失败不替换上一份 bundle。
- 新增 `create_macos_application.sh` 的 `ui-only`/`collaboration` 两种规范骨架。前者没有 descriptor/socket/Agent 依赖；后者独立拥有任务草稿校验、动态 component registry、布局和 bundled image，并选择性接入授权的 `SET_MARKED` connection。模板不复制 renderer、launcher、private probe 或现有 example 业务。
- `export_framework_preview.sh` 导出清单化的最小源码预览：5 个 composable Host 实现文件、4 个 core 文件、必要 native source/资源、runner、模板及可选公开 Python client；没有 examples、probes、tests、target、workspace cache 或用户数据。`preview-manifest.md` 明确来源、许可证边界、实验性/非 ABI 承诺。自动检查从含空格临时路径生成两个应用，以相对 path dependency 构建；初始预览没有 renderer archive，首建后才有本地 cache。
- 真实 GUI 验收分开记录：UI-only 窗口的原生键盘输入最终在 AX 中读回 `preview`，计数变为 1；协作窗口的人侧输入后显示“本地任务已添加 #1”。独立公开 client 先从 descriptor/snapshot 发现 3 个 actions 和 `target=8101`，再完成授权 `SET_MARKED`、旧 version 的 `version_conflict`、target readback 和 active window projection；窗口 AX 显示共享领域版本 1。预览中的 collaboration normal-close probe 同时记录 bundle resource `started→ready`，随后通过 `host.requestClose()` 清除 descriptor/endpoint。
- 已通过：`verify_framework_consumption_entrypoints.sh`、`verify_framework_consumer_scaffolding.sh`、`verify_framework_preview_consumption.sh`、`verify_macos_application_host_runner.sh`、Notification normal bundle build、以及 `cjpm build --skip-script`。前阶段资源/文本的既有退役或未运行边界不因本轮改变。没有配置并实际调用独立模型/Agent；固定或通用公开 client 的通过不表示模型接入，保留为未验。未 stage、commit、push、安装或发布，也未操作用户 Rule Set。

## 指导复核与本阶段接续（2026-09-13）

上述是执行报告中的初次交付事实，不代表全部阶段目标通过。指导只读审阅源码及报告，没有重跑构建或 GUI。统一入口和预览构建继续接受其已证明范围；以下工作承接原阶段目标，不另开补丁阶段。

1. 协作模板尚未共同操作同一内容：`collaboration/src/main.cj` 的 `HUMAN_ADD` 只增加 `humanTaskCount` 并清空本地 draft（70–80 行），外部 `SET_MARKED` 写的是启动时固定记录 8101（106–122 行），界面只回显共享版本（48–50 行）。将人侧和外部接到同一真实任务/字段及受控动作，显示实际内容和修改结果；复用既有 core、绑定组件和 Host，不新造同步业务库。输入框声明的 `EDIT_DRAFT` 也须与真实动作/上下文一致。草稿可暂时为空，提交时校验，不应拒绝用户删除最后一个字符。具体应用保持小而可用，不扩张成任务管理产品。
2. 当前预览 checker 仅扫描静态路径并构建，runner 仍接收继承的 `CJGUI_NATIVE_SOURCE_DIR`；故环境覆盖可使“relative_path_only”标签超出证据。在消费验证中隔离影响来源的覆盖配置、记录并断言实际 native/依赖/资源来源属于导出预览；将预览与应用整体移到另一个含空格目录、清理本次生成缓存后正常重建/启动，保留实际路径与产物证据。不要删除原仓库缓存或禁止开发者有意使用正常 override。
3. 从导出的公开文档与接口完成独立消费者接入：另一个 Luna/Terra 消费任务自行发现对象/动作/参数，使用公开 client 完成人改后读取、授权改同一字段/对象、人继续操作，验证实际值、旧版本拒绝与资源/关闭接续。不给它预写固定请求冒充自主发现。现有子任务能力可用，应先实际安排；真实环境受限则写明尝试与阻塞，脚本、独立模型和 GUI 分开标记。完成后统一收口生成器、导出清单、教程、针对性回归及 ACTIVE，主动报告指导。

许可边界仍限本地实验预览，不自行选择开源许可或宣称可对外发布；不把未来发布材料变成当前核心实现的无限前置条件。当前缺口是共享操作接通及消费证据，不继续扩大资源压力或重开输入法范围。模型、目录、失败升级和用户实例保护沿用本阶段原授权。

## 本阶段收口（2026-09-13）

- 协作模板已移除 controller-local `draft`、`humanTaskCount` 与 `EDIT_DRAFT`：输入节点直接投影同一共享记录的 `title`，人侧输入走 `SET_TITLE`，提交仅在空标题时拒绝，并以 `SET_MARKED` 写同一记录。公开 action descriptor 新增 `SET_TITLE(title: STRING)`；人和外部都经同一 domain handler，外部保持 expected-version CAS。空标题是合法编辑中值，资源 transport 名称回退为“记录 <id>”，不把 field 值伪造成非空。
- core 针对性回归覆盖人清空、公共 snapshot 的空 field、错误 typed 参数拒绝、外部改写、过期写 `version_conflict` 以及人继续编辑。导出的 preview verifier 从空缓存构建后，把预览与两种应用整体移动到另一处含空格路径；该命令清空继承的 `CJGUI_NATIVE_SOURCE_DIR`，并断言 runner 的 runtime/native/core/resource 来源全为导出 preview。正常关闭通过 `host.requestClose()` 证实 descriptor/endpoint 已清理；强制终止不冒充正常关闭。
- 独立 Luna 消费者在 `/private/tmp` 的全新、未改业务值 preview 中，只使用公开模板/文档和 client 动态发现 resource、`SET_TITLE` 及 `title STRING` 参数。它确认初始空 title snapshot、外部非空和空值写回、stale `SET_TITLE` 拒绝；AX 可用时还实际完成 `human-first-final → external-after-human-final → human-after-external-final` 并由窗口和 client 读回同一标题。其产物不进入工作区。该结果是独立 Agent 的本地协议消费，不把 generic client 或此任务称作第三方 model/provider SDK 集成。
- 本轮通过 `shared_operation_core/cjpm test`（43/43）、`cjpm build --skip-script`、Notification normal bundle build、`verify_framework_consumption_entrypoints.sh`、`verify_framework_consumer_scaffolding.sh`、`verify_framework_preview_consumption.sh`、`verify_macos_application_host_runner.sh`、第二消费者验收及 `git diff --check`。未 stage、commit、push、安装、发布或操作用户 Rule Set；稳定 ABI、跨平台、物理 IME/VoiceOver、人工像素和第三方 provider 集成仍不在此证据范围内。
