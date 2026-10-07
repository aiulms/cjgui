# CJGUI 验证与复现报告

验证日期为 2026 年 10 月 7 日。本报告说明本次源码候选、实际通过项、演示来源和仍未完成的边界。仓颉框架 560/560、共享核心 100/100、Python 客户端 96/96 通过，正常 macOS 文档窗口已构建运行。不同平台与消费者的画面不拼成同一版本的全平台验收。

## 源码版本与公开状态

候选基线为 3b1ad6e57dff601627db0d28167d5a3c7ac8df10，补齐清单列出的 15 个原有生产源码文件。没有纳入并行开发的未提交生产改动和 11 个新增测试文件。清单 SHA256 为 12ff1f8582c14e6bb3c7c06178478d4fd610e314137026d117881387b9d9f3b9，共 4,828 个源码及文档文件。

整理开始时 GitCode 与 GitHub main 均为 33ee9e44ac5736bb845f9f3c2c99670905b3d659。该公开版本去掉缓存后编译失败，原因是缺少已引用的 internalRendererWindowLog 实现。候选包含补齐文件，本次材料不能宣称原公开提交已经通过干净克隆验证。最终同步状态以 SOURCE_STATUS.md 为准。

## 环境与结果

本次为 macOS 26.6 arm64、仓颉 1.1.3、Python 3.12.14、Xcode Command Line Tools。正常应用使用当前 macOS SDK；框架单元测试的 native sidecar 使用脚本默认 MacOSX15.4.sdk。所有构建在隔离目录运行，未占用并行开发的 cjpm target。

框架单元测试：TOTAL 560，PASSED 560，SKIPPED 0，ERROR 0，FAILED 0；测试体耗时 20.94 秒，不包括编译。共享核心：TOTAL 100，PASSED 100，SKIPPED 0，ERROR 0，FAILED 0；测试体耗时 2.66 秒。公开客户端六组 unittest：96 项，8.122 秒，OK。各套件独立计数，不将 25 项子集重复相加。

正常应用：使用框架 run_macos_application.sh 构建普通 bundle 并完成 ad hoc 签名；无 native 单元测试宏。文档窗口实际接收桌面输入，公开客户端追加两次后读回正文和版本；画面与公开状态分别保存。正常应用成功不等于全部文本输入边界已收口。

## 复现命令

准备仓颉 1.1.3、Command Line Tools 与 Python 3。设 CANGJIE_HOME 为实际工具链目录，再 source "$CANGJIE_HOME/envsetup.sh"。先解压本次源码包，在 SOURCE_ROOT 的不同副本中分别构建测试和普通应用，避免测试 sidecar 被普通应用复用。

仓颉框架单元测试：进入 runtime/cjgui，先运行 CJGUI_NATIVE_CLANG_FLAGS_APPEND='-DCJGUI_INTERNAL_TESTING -DCJGUI_INTERNAL_RENDERER_TESTING' zsh native/scripts/build_cjgui_internal_renderer_sidecar.sh，再运行 cjpm test --parallel 1 --no-progress。预期摘要为 TOTAL/PASSED 560、无 skip/error/failure。不同 SDK 需按脚本说明设置 CJ_GUI_SDKROOT。

共享核心：进入 runtime/cjgui/shared_operation_core，执行 cjpm test --parallel 1 --no-progress，预期 100/100。Python 客户端：在同一目录执行 python3 -m unittest discover -s . -p 'test*.py' -v，预期 96 项 OK。客户端测试含协议兼容对端，仅证明客户端契约。

正常窗口：从另一个没有测试宏的源码副本执行 zsh runtime/cjgui/examples/shared_document_window_app/run.sh --build-only；构建成功后执行同一入口 --with-connection。使用应用输出的私有 DESCRIPTOR_PATH，调用 python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json describe 与 get。根据实际发现的文档 resource、动作及 documentVersion 调用 REPLACE_RANGE；位置单位为声明的 UTF-8 字节，不写死跨实例句柄。

## 视频与正常消费者

编辑器首页滚动及排版采用独立启动的 Pharos Mark 集成预览；原有用户测试实例保持。精确二进制指纹与素材来源见视频清单。此段说明真实应用消费，自身版本与框架候选分开记录。

生成式任务面板采用本次候选框架构建的普通消费者，展示手写区、生成结构及字段绑定。接收候选必须检查终态；脚本客户端调用不称为真实大模型自主操作。

本次生成式普通窗口实录：公开结构已读回 STRUCTURE_VERSION=3、SCENE_STATE=scene_accepted；窗口中点击“提交当前任务”，owner v3→v4，生成与手写标题同步只读。公开 SET_NOTES 使 v4→v5，两个区域显示相同备注；在 v5 发起 SET_TITLE 被 title_frozen_after_submit 拒绝，APPLIED=false、VERSION_BEFORE/AFTER=5，后续读回版本及原标题保持。这条链包含真实窗口操作、公开调用、业务读回和画面反馈。此次直接粘贴标题的尝试未改变业务状态，未计作通过项。

鸿蒙采用已经归档的正常消费者画面：温控示例与 Pharos Mark 编辑器。画面来自模拟器；温控 r22 的 HAP 指纹为 0611289c1f68de1be43d01c00a85031fbfed39dbedda602b5a3c43c363ec0501。仍使用 XComponent 与 OH_Drawing，未宣称真机、发行审核或完整跨平台视觉编辑完成。

## 已知边界与未完成项

本次文档窗口链已读回人输入 v1、外部追加 v2/v3、随后窗口输入 v4。后续全选粘贴出现“节点已在事件处理前变更”的明确拒绝，不能把这个结果写成完整输入闭环。文本落点、普通键入和输入交接仍需继续验收；初赛主视频以成熟的首页、排版、生成绑定和平台样例说明能力。

当前 E 正常编辑与 16 ms owner 门、H 跨帧选择/来源交接、W 正常 Windows 消费仍有未完成项。系统输入、无障碍、真机、发布包和公共 API 稳定性不包含在本次通过项中。历史测试与截图按其原版本、负载和平台解释，不推导为当前全套成功。

## 证据入口

仓库材料目录 docs/contest/2026-10-07/ 提供项目提案、查重、生态贡献、源码状态和 evidence/。原始测试输出已去 ANSI 与机器私有目录；凭据、socket、用户数据和联系信息不进入公开材料。候选源码及结果清单与视频清单分别提供 SHA256，以便评审对应具体文件。

## 公共同步后的补充验证

本次固定源码与成片提交 `8f9091c2a03cded04ac1875dfaa293987208962f` 已同步 GitCode/GitHub。匿名 GitCode 克隆后，4,826 个基线文件与测试候选逐字节一致，另外两处为 README 与 .gitignore 的材料覆盖。普通 macOS 消费者构建和框架 `cjpm build --skip-script` 均成功；匿名下载成片 SHA256 与本地一致。具体命令、日志和固定版本见 [SOURCE_STATUS](SOURCE_STATUS.md)。公开测试日志副本仅去除 ANSI、机器私有目录和行尾空白，运行顺序与结果保留；私有原件另存。
