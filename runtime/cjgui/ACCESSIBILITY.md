# 公共表单的可访问事实与操作

本页的 `semanticHelp` 和表单帮助接口为 **experimental**。字段名称、值、范围、可用性和错误仍由原字段声明及业务 owner 提供；辅助呈现不保存另一份草稿，也不判断业务合法性。

`cjguiComposableBoundFormField` 同时构造编辑器和可见校验说明，并把同一字段投影的说明写到编辑器的 `semanticHelp`。生成表单也调用该函数。`cjguiComposableFormFieldHelp(descriptor, projection, ...)` 供多行编辑器等其他字段呈现复用；可补 `helpText`、`readOnly`、`enabled` 和 `unavailableReason`。错误代码保留在公共字段投影中，帮助文字同时保留其具名原因。完整字段值不受影响。

普通节点可声明 `node.semanticHelp = "辅助说明"`，默认空。该事实随窗口候选冻结、比较、发布和退役；说明归空会清除旧说明，拒绝候选保留原已接受场景且不泄露新说明，退役包装不再保留说明。macOS 桥接受最多 8192 UTF-8 字节，超限拒绝候选并沿用已接受场景。

macOS 把说明映射为 `AXHelp`。单行／多行编辑器、复选框、滑块及按钮的写操作进入原有 owner 通道。滑块只提供原有步长的增减动作，范围和值从已接受声明读取。只读字段仍可读取、聚焦和选择，其值不可通过 AX 修改；禁用及当前模态作用域之外的控件不可接受写操作。退役包装不会因数字 ID 重用而重新指向新节点。AppKit 的动作和可写属性通过 `isAccessibilitySelectorAllowed:` 按当前节点收窄。

普通整值窗口和显式范围增量窗口沿用各自现有入口。生成表单只有在窗口已启用范围增量运输时才自动建立范围会话；关闭运输时仍执行原来的整值字段 writer。

共同 Python 客户端的 typed 读取会检查响应种类和 `ERROR` 包。合法空投影仍为空；`unauthorized_action` 等拒绝原因抛出 `GeneratedUiError`，端点替换和本地超时沿用已有专用异常。失败的能力刷新不会留下旧缓存供下次读取冒充成功。不自动放宽授权或重发请求。

正常消费者位于 [generated_collection/src/accessibility.cj](examples/generated_collection/src/accessibility.cj)，以 `--accessibility` 启动。它复用规则 owner、FormFeedback 和原有公开客户端，包含手写／生成字段、多行呈现、只读／禁用镜像及滚动。

其他平台保留共同帮助事实和 typed 客户端修复；本轮未接通其他平台的原生辅助服务，也未做平台验收。实际 VoiceOver 朗读与 AX API 检查分开报告；AX 查询成功本身不能证明旁白体验已通过。
