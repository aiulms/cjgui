# 业务 owner、字段、草稿和保存

先选覆盖需求的最小同版模板：

- 纯本地手写字段、列表、计数/合计、保存：用 `ui-only`。controller 可以承载该应用的业务 owner；
  持久化可按 `ui_only/WORK_SESSION.md` 接 `CjguiComposableUiWorkSession`。
  有字段或保存需求本身不要求 mixed-form。
- 需要同一组字段的手写/生成投影及相关绑定：读 `mixed_form/README.md`、模板 `src/domain.cj`。
  公开命令或 Inspector 单独需求可先看 `command-surface`，不默认启用整个 mixed 模板。

模板路径相对 `FRAMEWORK/templates/macos_application`；字段契约按需查 `FIELD_CONTROLS.md`。
共享文档使用同版 `shared_operation_core/DOCUMENT_CLIENT.md`；正常消费者在导出包
`SDK/consumers/shared_document_window_app`，checkout 则在 `FRAMEWORK/examples/shared_document_window_app`。

- 业务值、草稿、版本、校验和动作归应用领域 owner；手写/生成/外部入口读取同一声明和 writer。
  修改字段时改 owner 声明与真实业务操作，不在视图、日志或 Python 客户端另存一份草稿。
- 复用 bound form/region 的事件路径，按本版模板委派焦点与字段事件，避免同一输入由范围增量和整值预览写两遍。
  字段输入版本、表单事务版本、文档版本与原生焦点不是同一个数；不互相替代。
- 复合字段工厂要传播公开的 owner 可用性；不能显示成可编辑却所有写入被 owner 拒绝。
  暂时非法草稿按同版字段契约保留并反馈，提交时走现有校验，不把每个按键当 Apply。
- 重排/生成界面保留稳定 owner、字段、实例 key；拒绝候选时继续使用 accepted 界面与草稿。
  应用业务不能依赖节点位置或一份易变的窗口快照来确定 owner。
- 保存前明确“保存业务数据”“Apply 内存草稿”“保存 UI 定义”分别是谁的动作。
  mixed-form 默认内存预设不会因 ⌘S 自动成为磁盘文件；工作会话、UI 文档和业务正文各按同版说明接入。
  保存成功需要真实目标与读回；验证失败/取消时原数据和可继续编辑状态。
- 系统 marked text、选区/焦点归窗口与系统文本服务；不复制输入法或输入状态机。
  公共文档字节范围与窗口 UTF-16 范围按各自契约转换，不能拿聚合版本充正文版本。

已有公开连接时，先用随包 client 发现本应用动作/资源及授权，再执行任务需要的真实业务操作。
generated UI 编辑与保存计划使用 `shared_operation_core/GENERATED_EDITING.md` 中的客户端，
不另写协议、权限或票据状态机。纯本地应用可一直保持无连接。

验证选择一次正常短链：输入草稿 → 校验/反馈 → Apply 或保存 → owner/文件读回 → 必要的继续输入/关闭。
若任务涉及手写和生成两种投影，再核它们读写同一 owner。SDK 编译通过不表示实际状态已写入。

## 工作会话路径与已观察障碍

工作会话另看同版 `ui_only/WORK_SESSION.md` 和 `MACOS_APPLICATION_HOST.md` 的可选业务工作会话段。
本次 2026-11-07 试用的公开示例使用绝对路径；相对文件名曾返回 `file_write_failed`，
原因尚未隔离，不能写成所有版本的“不支持相对路径”。遇到同类失败时保留实际 SDK/构建、cwd、
传入路径、父目录存在/可写条件和原始结果，再尝试明确的绝对路径以继续应用任务。
若成功，记录这是该条件下的恢复方式；只有对应版本验证后才能撤掉 workaround。
失败时保留 owner/旧文件和 dirty guard，不通过伪报保存成功或强制关闭掩盖问题。
