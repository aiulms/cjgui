# CJGUI 仓颉 AI 生态贡献说明

申请成果：CJGUI 通用共享操作工具与人机接续示例。类型：工具、工作流、示例。

## 把 AI 工具接进正在使用的应用

人在窗口里选中一条记录，希望 AI 帮忙整理内容。工具需要知道当前是什么对象、允许改哪些字段、能执行哪些动作，还需要把结果交回用户正在看的界面。CJGUI 为仓颉应用提供这样的入口。

应用声明资源、字段、动作和规则，公开客户端发现这些能力，经授权调用真实业务操作，再读取结果。手写界面和生成界面共用这些数据。开发者可以把客户端接到自己的 Agent 工具中，让模型参与当前任务，用户继续在窗口里检查和操作。

本次成果包括仓颉服务端契约、通用 Python 客户端、多个应用示例和测试，位于同一开源仓库内，可按模块复用。生态贡献申请对应这套工具和接入方法。

## 从哪里开始

| 内容 | 仓库路径 |
| --- | --- |
| 仓颉契约、业务操作、传输与测试 | runtime/cjgui/shared_operation_core/src/ |
| 通用 Python 客户端 | runtime/cjgui/shared_operation_core/client.py |
| 客户端说明 | runtime/cjgui/shared_operation_core/README.md |
| 文档窗口示例 | runtime/cjgui/examples/shared_document_window_app/ |
| 规则编辑器示例 | runtime/cjgui/examples/rule_set_window_app/ |
| 生成式任务面板 | runtime/cjgui/examples/generated_panel_consumer/ |

成果仓库：[CJGUI](https://gitcode.com/aiulms/cjgui)。更多消费者包括 shared_operation_second_consumer 和 backup_rule_config_consumer，可用于理解同一客户端怎样服务不同业务。

## 运行一个可以共同操作的窗口

准备 macOS/Apple Silicon、仓颉 1.1.3、Xcode Command Line Tools 和 Python 3。按[源码版本说明](SOURCE_STATUS.md)取得本次源码，设置 CANGJIE_HOME 并载入工具链环境。

```sh
source "$CANGJIE_HOME/envsetup.sh"
zsh runtime/cjgui/examples/shared_document_window_app/run.sh --with-connection
```

应用输出本次实例的 DESCRIPTOR_PATH。把该路径设为 DESCRIPTOR，然后查看它提供的能力与当前内容：

```sh
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json describe
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json get
```

根据返回的资源 ID、动作、参数和文档版本调用 invoke、read-range 或 replace-range。文本位置使用应用声明的单位。连接凭据仅供当前实例使用，保留在本机私有目录。

## Agent 可以怎样使用

一次操作先发现应用能力，读取当前内容与版本，再提交合法请求，最后读回结果。遇到版本冲突时，重新读取当前内容后决定下一步；人仍可在正常窗口中继续工作。

客户端可用作 Agent 的进程工具或 Python 适配层。模型和任务规划由应用开发者接入，资源与动作由应用声明。生成式消费者还提供 generated-capabilities、generated-fields、generated-structure 和 generated-submit，可供工具发现可用组件和字段、提交面板结构并查询终态。

同一字段的类型、校验与写入动作同时服务手写控件、生成控件和工具调用。开发者可以据此把“在窗口中操作”和“让 AI 帮忙操作”接进一个应用。

## 已提供的验证

正常任务面板实录展示了人提交任务、外部工具追加备注，以及应用拒绝修改已冻结标题的过程。结果直接显示在手写区和生成区，详见[演示说明](demo/README.md)。

共享核心 100/100、公开 Python 客户端六组 96/96 测试通过；协议契约测试与正常应用记录见[验证报告](VALIDATION.md)。框架、客户端和示例采用 Apache License 2.0。

当前接口为 experimental，演示调用者为脚本客户端；真实模型接入后的协作效果仍需评测。项目提供应用工具入口，Agent 规划和 MCP 适配可由上层接入。
