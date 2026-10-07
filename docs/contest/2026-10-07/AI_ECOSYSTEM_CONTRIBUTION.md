# CJGUI 仓颉 AI 生态贡献说明

申请成果：CJGUI 通用共享操作工具与人机接续示例。类型：工具、工作流和示例。

## 解决的问题

Agent 操作桌面应用时，需要知道可操作的对象、参数和规则，并在修改后读回真实状态。CJGUI 的应用以仓颉声明资源、字段和动作，公开客户端动态读取这些能力，经应用签发的连接凭据调用业务操作。此工具可用于 Agent 工具适配，也可用于普通脚本、调试和集成测试。

本次贡献属于作品仓库内独立可复用模块，源码和文档入口为 runtime/cjgui/shared_operation_core/。我们未将普通 AI 辅助写代码计作生态加分，未声称实现通用 Agent 规划器或 MCP 服务端。

## 源码与复用入口

- 作品与贡献仓库：https://gitcode.com/aiulms/cjgui
- 仓颉契约、业务域、传输与测试：runtime/cjgui/shared_operation_core/src/
- 通用 Python 客户端：runtime/cjgui/shared_operation_core/client.py
- 客户端完整说明：runtime/cjgui/shared_operation_core/README.md
- 文档窗口：runtime/cjgui/examples/shared_document_window_app/
- 规则编辑器：runtime/cjgui/examples/rule_set_window_app/
- 其他普通消费者：shared_operation_second_consumer、backup_rule_config_consumer。

## 运行和调用

准备 macOS/Apple Silicon、仓颉 1.1.3、Xcode Command Line Tools 和 Python 3。按验证报告使用源码包或已公开的对应版本；设置 CANGJIE_HOME 并 source 其 envsetup.sh。

```sh
zsh runtime/cjgui/examples/shared_document_window_app/run.sh --with-connection
# 应用输出 DESCRIPTOR_PATH 后，使用这次实例签发的路径
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json describe
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json get
```

调用者从当前描述读取资源 ID、动作、参数、位置单位及文档版本，再按 client.py 的 invoke/read-range/replace-range 入口操作。不要猜测旧 socket 或复用已关闭实例的 descriptor。凭据保持在本机私有目录，不进入日志、视频和代码仓。

生成式消费者还提供 generated-capabilities、generated-fields、generated-structure、generated-submit 等入口。生成候选必须引用应用已声明字段、动作和受支持组件。接收候选不等于画面接受，需读取候选终态和当前结构版本。

## 可复用的处理流程

1. 发现当前实例允许的对象与操作。
2. 获取对应业务版本和位置单位。
3. 构造带预期版本的合法操作并调用。
4. 读回业务状态、候选终态和窗口进度。
5. 人继续在正常窗口中编辑；冲突由业务规则处理。

客户端可作为外部 Agent 的进程工具或 Python 适配层。资源和动作来自应用，客户端不写死某个业务消费者。模型调用需要应用或 Agent 另行接入；当前演示仅证明脚本调用公开工具和人机接续链路。

## 验证与限制

本次 Python 客户端六组测试合计 96 项通过；其中使用协议兼容对端的测试属于客户端契约验证，不能代替正常应用集成。正常窗口演示及仓颉测试的环境、版本、命令和结果见 VALIDATION.md。

所有 API 当前为 experimental。授权、失效、版本冲突和读回由协议处理；没有完成全平台无障碍、云端远程安全方案或大模型自主使用评估。加分是否成立及分数由赛事评审认定。
