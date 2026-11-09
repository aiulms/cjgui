# macOS 首版候选公共子集

本页限定本包可供普通应用消费的公共面，配合 [开发入口](MACOS_DEVELOPER_QUICKSTART.md)、
[宿主](../MACOS_APPLICATION_HOST.md)、[字段控件](../FIELD_CONTROLS.md)、
[布局](../LAYOUT_PRIMITIVES.md) 和 [公开编辑客户端](../shared_operation_core/GENERATED_EDITING.md) 使用。
这是本地 SDK 候选的范围说明；导出、编译、窗口运行、连续消费、真实 VoiceOver 和性能分别取证，
本页不把待验项写成通过，也不替代包内 `source-manifest.json`、`source-lock.json` 与运行实例身份。

## 平台、来源与稳定性

- 当前参考消费平台是 macOS，工具链为 Cangjie 1.1.3、Apple Command Line Tools/macOS SDK；
  创建器和 Python 客户端要求 Python 3.11+。CPU 架构、系统版本和实际编译配置以该候选构建来源记录为准。
  Windows/OHOS/Linux 的既有交付不由本包推定同版或通过。
- 仓颉接口、生成能力和文档工作区保持 **experimental**。当前公开生成 surface 为 `version=1.0`、
  `compatibility=additive_only`，subset 为 `host,layout,fields,commands,identity,generated,read_write`。
  这是实际发布的发现事实，不承诺 stable 源 API、二进制 ABI 或任意跨版本混用。
- 本包客户端接受 surface major 1、公开运输协议 `2`；结构语法支持 format 1 和
  `GENERATED_UI_STRUCTURE 2`，界面文件是 `cjgui.ui-document` v1，CHOICE 是 v1。
  缺失 surface 的旧生产者仍可读取；显式不兼容 major/protocol/compatibility 会具名拒绝。
  客户端支持语法不表示当前应用已登记相应能力，须读取实际 catalog 的 SURFACE/SUPPORT/EVIDENCE。
- SDK 的 format-2 source lock 固定共同源、native 输入、脚本、模板、资产，以及
  `GENERATED_EDITING.md`、`DOCUMENT_CLIENT.md` 和 skill 全文；普通公共文档不在该锁的覆盖范围，
  其实际内容由 source manifest 的逐文件哈希核对。应用的 `.cjgui/macos-build/build-provenance.json`
  另记实际准备输入、native 归档、链接与可执行文件。包名、日期或 Git HEAD 不能替代这些身份。
  实验性 v6 `cjgui-app-dev` 随包携带，是否被某宿主发现/加载仍须分别核实。

## 包内公共面

| 范围 | 普通消费入口与边界 |
| --- | --- |
| 宿主/窗口 | `CjguiMacosApplication` / `CjguiMacosApplicationHost`、公开 controller、普通事件/场景刷新与关闭决策；AppKit 访问遵守主线程。运行器处理本应用 native、bundle、资源、rpath 与签名。 |
| 布局/主题 | Vertical/Horizontal、Wrap、Stack/LayerHost、ScrollArea、Split、Tabs 和已登记 Image；约束、grow、对齐、平移、裁剪与主题角色按同版布局/样式文档。应用显式登记允许的生成词汇，不隐式开放任意组件。 |
| 字段/命令 | TEXT/INTEGER/BOOLEAN、公共 bound form helper、数值步进与已登记选择控件；动作、参数类型、范围、可用性和原因来自领域 owner/共同声明，菜单、工具栏与按钮可投影同一命令。 |
| 身份/业务 | 稳定 field/resource/node/instance key 与 owner target/incarnation；业务值、草稿、校验、版本、Apply/Cancel 和持久化归应用。位置或可见性不是 owner 身份或授权。 |
| 手写/生成/混合 | `CjguiGeneratedUiFormBinding` 与 `CjguiGeneratedUiWindowRegion`；多对象用 `CjguiGeneratedUiMultiObjectBinding` 和应用对象适配，事件与范围会话复用既有 accepted 绑定，不另造草稿或输入状态机。 |
| 受限集合/组合 | 应用登记的集合、稳定 key、accepted mount/viewport、定向 reveal；受预算约束的组合定义、嵌套引用和单次候选原子发布。预算读取实际 `BOUNDS`/`COMPOSITION_BUDGET`，不可写死为所有应用能力。 |
| 界面文档 | `CjguiGeneratedUiDocumentSession` / `CjguiUiDocumentWorkspace`、预览/确认/取消、保存/打开/另存及可选会话内 undo/redo；文档保存已接受 UI 定义，与业务 Apply/保存分开。 |
| 公开客户端 | 随包 `cjgui_generated_client.py`、`cjgui_generated_edit.py` 与共享操作客户端；发现、原子快照、计划/票据、精确读回、字段写入、动作及历史均走既有端点。默认不开连接，应用只授权必要操作。 |

布局、主题或界面文件的变化不自行 Apply 业务草稿。重排保留稳定 field/instance/owner 身份时，
可继续消费同一草稿；跨 owner、旧节点、旧 accepted 绑定和过期计划按实际身份检查拒绝。
文档历史只撤销已接受 UI 定义，不回滚业务值、焦点、授权或文件外部改动，也不占用正文 Cmd-Z。
历史默认关闭；启用时按应用选择的有界 policy 保存，会话结束不持久化历史。

## 一份字段声明与只读兼容

字段声明签名保留原参数并增量提供 `readOnly`：

```cangjie
CjguiSharedFormFieldDescriptor(resourceId: Int64, fieldId: String,
    label: String, editorKind: String, required!: Bool = false,
    minimum!: Int64 = 0, maximum!: Int64 = 0,
    maximumLength!: Int64 = 0, readOnly!: Bool = false)
```

`readOnly=false` 保持既有构造的默认可写行为。`readOnly=true` 是字段声明事实，
与临时 owner 不可用、组件禁用及校验错误不同；只读字段仍可显示、读取和选择文本。
手写 bound helper 和生成输入从同一声明继承它；整数步进输入与 ± 同时遵守它。
应用的真实 writer 仍须保留 `field_read_only` 拒绝，不能仅靠灰色外观保护数据。
生成候选不能把只读声明降为可写，公开字段读回的 `READONLY`/typed `read_only`
与 available/reason 必须描述同一事实。当前 producer 显式输出 `READONLY 0|1`；
旧 producer 未给此 token 时 typed `read_only` 为 `None`，非法 token 具名拒绝，
不能把缺失信息推断成已验证可写或只读。

字段 ID、标签、required、TEXT 的 Unicode scalar 长度及 INTEGER 的 minimum/maximum
只定义一次，校验、手写构建、生成 catalog 与 owner writer 消费这一来源。
业务规则在建项/编译时更改不代表支持运行时 schema 迁移。

## 参数、拒绝与完成

- 字段写入使用公开动作的类型和 `expectedDraftVersion`，Apply/Cancel 使用同一 owner 和事务基线；
  TEXT 输入版本、表单草稿版本、应用上下文版本、UI accepted 版本及原生焦点身份不可互换。
- 未登记 kind/property/action、未知/退休 instance/owner、错误参数、越界、超预算、循环组合、
  stale version/endpoint/plan/digest、readonly 或 unavailable 均按端点实际原因拒绝。
  拒绝保留旧 accepted 界面与已存在业务值/草稿；不通过客户端重试、换 owner 或改版本刷成成功。
- 校验非法的中间草稿可以保留、显示错误并继续修正；Apply 拒绝不能改已应用值。
  只读/禁用、可编辑/校验合法、运输成功/业务接受是不同事实。
- 提交回执或 `candidate_pending` 不是完成。沿同一票据观察终态，再读 owner、accepted 结构和窗口反馈。
  部分客户端会在业务 `APPLIED false` 时正常 exit0；须核 typed applied/reason，不能只看退出码。
- 文档保存空路径拒绝 `ui_document_path_empty`，另存到已存在的其他目标拒绝
  `ui_document_save_as_target_exists`，外改冲突拒绝 `ui_document_save_conflict` 并保留外部字节。
  关闭沿公共 guard 结算在途票据与保存/放弃/取消，失败后可继续编辑。

## 当前证据边界

本页描述候选的公共契约，不对本轮尚未完成的 SDK、独立消费者、VoiceOver 或固定普通负载测量给结论。
AX 查询、AXPress、普通键盘、实际 VO 读出和模型公开调用各标明来源；它们不能互相代证。
accepted/submitted、GPU completed、实际 present 和人已看见也分别记录。
旧版本已验子集继续按原件使用，旧失败与未知项保留，未验证平台/完整 IME/严格性能不因导出成功而通过。
运行时规则修改、删字段与迁移引擎、递归通用脚本/完整源码热重载、出版排版及 GiB 编辑不在本子集。

导出包根 `README.md`、候选说明和 manifest 记录实际包身份与最短启动方法。
独立应用需从该包公开创建器建项，两个 path 依赖和运行器只指向该 SDK；
不得从作者 checkout 补取 native、客户端或私有宿主类。
