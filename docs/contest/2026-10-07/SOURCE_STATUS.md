# CJGUI 初赛源码状态

## 已公开的参赛源码与成片

固定源码提交：`8f9091c2a03cded04ac1875dfaa293987208962f`。GitCode 与 GitHub 已同步，匿名 GitCode 克隆的 HEAD 与该提交一致。后续文档补记不改变这份源码；初版源码与材料归档标签为 `cjgui-contest-20261007`；随后文字修订见 main，固定源码与视频保持原指纹。

- [GitCode 固定源码](https://gitcode.com/aiulms/cjgui/tree/8f9091c2a03cded04ac1875dfaa293987208962f)
- [GitHub 固定源码](https://github.com/aiulms/cjgui/tree/8f9091c2a03cded04ac1875dfaa293987208962f)
- [参赛成片直接下载，无需登录](https://raw.githubusercontent.com/aiulms/cjgui/8f9091c2a03cded04ac1875dfaa293987208962f/docs/contest/2026-10-07/demo/CJGUI%20%E5%88%9D%E8%B5%9B%E5%8F%82%E8%B5%9B%E6%BC%94%E7%A4%BA.mp4)
- [演示章节与素材范围](demo/README.md)

匿名下载返回 HTTP 200，成片大小 4,419,309 字节，SHA256 为 `f3673b4a48aefb43195caf6299155aac584cd06e4c999ffb2a17e36c59109bec`，与本地成片完全一致。服务器以 application/octet-stream 返回文件，可下载后观看。

## 复现来源与指纹

本次源码基于 `3b1ad6e57dff601627db0d28167d5a3c7ac8df10`，补齐 [source-candidate.json](source-candidate.json) 中的 15 个原有源码文件，并移除两份被误纳入 Git 的编译缓存。没有纳入 E/H/W 并行开发的未提交生产差异和 11 个新增测试文件。

[source-manifest.json](source-manifest.json) 描述 4,828 个代码及既有文档基线文件，清单 SHA256 为 `12ff1f8582c14e6bb3c7c06178478d4fd610e314137026d117881387b9d9f3b9`。匿名克隆逐一核对其中 4,826 个文件，全部与测试候选一致；两处覆盖是根 README 的参赛导航与 .gitignore 的缓存忽略规则。随后新增的参赛文档、验证记录和视频独立记载；生产源码内容保持该测试指纹。

## 公开下载后的干净构建

在新目录匿名克隆 GitCode main，确认 HEAD 为上述固定源码提交、没有旧 target/.cache/native/lib 后，执行普通消费者构建和框架构建：

```bash
git clone https://gitcode.com/aiulms/cjgui.git
cd cjgui
git checkout 8f9091c2a03cded04ac1875dfaa293987208962f
# 设置 CANGJIE_HOME 为仓颉 1.1.3 工具链目录
source "$CANGJIE_HOME/envsetup.sh"
unset CJGUI_NATIVE_CLANG_FLAGS_APPEND CJGUI_INTERNAL_TESTING CJGUI_INTERNAL_RENDERER_TESTING
zsh runtime/cjgui/examples/shared_document_window_app/run.sh --build-only
cd runtime/cjgui
cjpm build --skip-script
```

两项退出码均为 0，普通应用完成 native 编译、仓颉构建、bundle 创建及 ad hoc 签名；框架 `cjpm build --skip-script` 成功。记录见 [普通应用构建](evidence/public-clean-clone-build.log)、[框架构建](evidence/public-clean-framework-build.log)和[下载与指纹核对](evidence/publication-verification.json)。以上给出固定提交的复现命令；匿名构建记录在公开提交 8f9091c2 时完成。归档标签指向 64815411，仅补充材料记录，生产源码相同。

## 历史差异与完成范围

材料整理开始时，两端 main 为 `33ee9e44ac5736bb845f9f3c2c99670905b3d659`，该旧提交去掉缓存后因缺少已引用实现而构建失败。本次补齐并公开的提交已经通过上述独立下载构建；旧反例与新结果分别记录。

框架 560/560、共享核心 100/100、公开客户端 96/96 来自相同生产源码指纹的隔离候选。公共同步没有重复改变生产实现，故沿用这些单元结果，并新增公开下载构建证据。系统输入、跨帧选择、真机、Windows 正常消费者及发行交付的完成边界仍见 [VALIDATION](VALIDATION.md)；编辑器、生成面板与鸿蒙截图的版本分别见视频说明。

签字后的官方模板与联系人属于团队私有邮件材料，不进入公开仓库。赛事网站最终确认和正式邮件由参赛者本人完成。
