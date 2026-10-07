# CJGUI 验证与复现报告

验证日期：2026 年 10 月 7 日。本报告供评审核对协作演示，并从公开源码重现构建与测试。固定源码提交为 8f9091c2a03cded04ac1875dfaa293987208962f。

## 构建与测试结果

环境为 macOS 26.6 arm64、仓颉 1.1.3、Python 3.12.14 与 Xcode Command Line Tools。普通应用使用当前 macOS SDK；框架测试的 native sidecar 使用脚本默认 MacOSX15.4.sdk。构建在独立目录进行。

| 验证项 | 结果 | 说明 |
| --- | --- | --- |
| 仓颉框架测试 | 560/560 | skip/error/failure 均为 0；测试体 20.94 秒 |
| 仓颉共享核心测试 | 100/100 | skip/error/failure 均为 0；测试体 2.66 秒 |
| Python 客户端六组测试 | 96/96 | unittest 返回 OK；耗时 8.122 秒 |
| 公开源码的普通应用构建 | 退出码 0 | native 编译、仓颉构建、bundle 创建及 ad hoc 签名成功 |
| 公开源码的框架构建 | 退出码 0 | cjpm build --skip-script 成功 |
| 公开成片下载 | HTTP 200 | 下载文件 SHA256 与本地成片相同 |

测试计数按套件分别列出；25 项子集未重复计入客户端总数。客户端测试包含协议兼容对端，正常应用集成由窗口实录和业务读回单独验证。测试耗时不包括编译，也不作为帧率指标。

## 协作演示验证了什么

生成式任务面板同时显示手写区和生成区。人点击“提交当前任务”，两个区域的标题一起变为只读；公开客户端追加备注，两个区域显示同一份新内容；再次尝试修改标题被拒绝，原标题保留。这个过程验证了人的窗口操作与外部工具调用进入同一套应用数据和规则。

对应读回：生成结构版本 3，终态 scene_accepted；窗口提交使业务版本 v3→v4；SET_NOTES 使 v4→v5；SET_TITLE 返回 title_frozen_after_submit、APPLIED=false，操作前后版本均为 5。请求结果和最终状态保存在 evidence/，可与视频 00:41 起的窗口画面对照。

本次调用者为公开脚本客户端，验证的是 AI 可接入的工具入口。模型经工具适配接入后的自主操作效果另行评测。

## 获取对应源码

```sh
git clone https://gitcode.com/aiulms/cjgui.git
cd cjgui
git checkout 8f9091c2a03cded04ac1875dfaa293987208962f
export CANGJIE_HOME=/absolute/path/to/cangjie-1.1.3
source "$CANGJIE_HOME/envsetup.sh"
```

也可使用随附候选源码包。测试与普通应用请使用不同源码副本，以免普通应用复用带测试宏的 native sidecar。

## 复现普通窗口

在没有测试宏的副本中运行：

```sh
unset CJGUI_NATIVE_CLANG_FLAGS_APPEND CJGUI_INTERNAL_TESTING CJGUI_INTERNAL_RENDERER_TESTING
zsh runtime/cjgui/examples/shared_document_window_app/run.sh --build-only
zsh runtime/cjgui/examples/shared_document_window_app/run.sh --with-connection
```

应用输出私有 DESCRIPTOR_PATH。把该路径设为 DESCRIPTOR，调用公开客户端：

```sh
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json describe
python3 runtime/cjgui/shared_operation_core/client.py "$DESCRIPTOR" --json get
```

根据返回的文档资源、动作及 documentVersion 调用 REPLACE_RANGE。位置单位为声明的 UTF-8 字节，资源与连接凭据使用当前实例提供的值。框架构建可在 runtime/cjgui 中执行 cjpm build --skip-script。

## 复现单元测试

框架测试先构建测试 sidecar，再执行仓颉测试：

```sh
cd runtime/cjgui
CJGUI_NATIVE_CLANG_FLAGS_APPEND='-DCJGUI_INTERNAL_TESTING -DCJGUI_INTERNAL_RENDERER_TESTING' zsh native/scripts/build_cjgui_internal_renderer_sidecar.sh
cjpm test --parallel 1 --no-progress
```

预期 TOTAL/PASSED 为 560，skip/error/failure 均为 0。使用不同 SDK 时，按脚本说明设置 CJ_GUI_SDKROOT。

在另一个源码副本的仓库根目录执行共享核心与公开客户端测试：

```sh
cd runtime/cjgui/shared_operation_core
cjpm test --parallel 1 --no-progress
python3 -m unittest discover -s . -p 'test*.py' -v
```

预期仓颉 100/100，Python 96 项 OK。

## 源码与演示如何对应

固定源码已同步 GitCode 和 GitHub。它基于 3b1ad6e57dff601627db0d28167d5a3c7ac8df10，补齐 15 个已被引用的原有源码文件；并行开发的未提交实现和 11 个新增测试未纳入。source-manifest.json 包含 4,828 个代码及既有文档基线文件，SHA256 为 12ff1f8582c14e6bb3c7c06178478d4fd610e314137026d117881387b9d9f3b9。

匿名克隆后，4,826 个基线文件与测试候选逐字节一致；另外两处是 README 和 .gitignore 的材料覆盖。新目录完成了普通应用与框架构建。随后材料修订只调整文字，生产源码和成片保持原指纹。详细记录见 [SOURCE_STATUS](SOURCE_STATUS.md)。

生成式任务面板由本次候选构建，采用普通应用入口，无 native 单元测试宏。Pharos Mark 首页段使用单独记录二进制指纹的集成预览，展示真实滚动和 Markdown 排版。

鸿蒙段采用已归档的温控与编辑器模拟器画面。温控 r22 HAP SHA256 为 0611289c1f68de1be43d01c00a85031fbfed39dbedda602b5a3c43c363ec0501；平台使用 XComponent 与 OH_Drawing。各段素材和指纹见 demo/video-provenance.json。

## 仍需完善的部分

文档窗口已读回人输入 v1、外部追加 v2/v3、随后窗口输入 v4。后续全选粘贴出现“节点已在事件处理前变更”的拒绝；生成面板的直接粘贴标题尝试也未改变业务状态。这两次尝试均未计作通过。正常键入、文本落点、输入交接和跨帧选择仍需继续完善。

普通编辑的 16 ms 性能目标尚未全部达成，GPU 回调也不能代表物理呈现时间。完整无障碍、鸿蒙真机、Windows 正常消费者、发行交付与公共 API 稳定性仍待验证。当前鸿蒙结论限于模拟器，视频中的不同消费者按各自版本解释。

## 原始记录

evidence/ 包含测试输出、公开下载构建日志、结构接受、窗口提交、备注写入、标题拒绝及最终业务读回。公开日志去除了 ANSI、机器私有目录和行尾空白，运行顺序与结果保留。私有原件另存；连接凭据与联系人不进入公开材料。
