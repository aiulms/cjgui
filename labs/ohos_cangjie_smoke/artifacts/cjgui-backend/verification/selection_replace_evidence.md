# C/第六次复核第 3 项：系统选区→替换/删除 精确读回（历史 FAIL 补足）

日期：2026-09-26。探针：`verify_selection_replace_probe.py` → **PASS（failures=0）**。
断言明细：`selection_replace_evidence.json`；主应用 verify-transport+test-gates 变体。

## 历史 FAIL 的补足方式
selection_probe 的「非空选区」「替换后 owner 值」两 FAIL 源于 uitest 拖拽/双击
在 0.01 透明代理上不产生系统选区。新链路改走**真实系统选择菜单**：
长按字段 → 系统菜单（uitest 树内可见）→ 点「全选」→ 系统全选事件
`ime select [0,11) rc=0`（真实非空系统选区，逐码元数与字段文本一致）。

## 结果
| 断言 | 结果 |
| --- | --- |
| S1 基线提交精确（全选→DEL→粘贴→回车） | OK `选区基线甲乙丙` v=1 |
| S2a 系统全选产生非空选区事件（历史 FAIL#1） | OK `[0,11)` |
| S2b 选区替换后 owner 读回精确（历史 FAIL#2） | OK `替换后文本` |
| S3a 第二次系统全选非空 | OK |
| S3b 全删后提交空名 → 域规则拒绝、owner 保持原值 | OK（撤回的草稿不写入 owner） |

## 提交/取消语义与 marked 范围的平台边界（如实记录）
1. **组合（marked）范围**：本机 SDK（DevEco arkui 组件声明）不向应用层暴露
   TextInput 的组合范围事件；可观察面为 onChange（含组合文本的全量镜像）、
   onTextSelectionChange、onSubmit、onBlur。渲染器预览路径按**全跨度镜像**
   组合文本（ohos_renderer_ime_preview_text_ctx：previewStart=0 /
   previewEnd=editingText.size）。取消安全性由全量镜像设计保证：组合取消时
   onChange 回退 → draft 回退，未提交组合文字不可能进入 owner（提交只走
   onSubmit/onBlur 的显式 m.draft 全量）。探针 S3b 从域规则侧验证了
   「提交被拒 → owner 保持原值」。
2. **空白失焦的本地延续语义（本轮实测记录，交指导裁定）**：点非交互空白时
   渲染器就地折入草稿（`ime blur settle settled=1`）但 owner 不被写入
   （accepted 投影仍显示 owner 旧值）；晚到的 ArkTS blur 被身份校验正确拒绝
   （`blur verdict=stale`，项 3a 身份捕获生效实证）。草稿保留在本地延续窗口，
   后续显式提交才落 owner。探针因此全部采用回车显式提交做确定性 owner 写入。
3. **冷首焦粘贴丢失**：冷启动首次聚焦后的 uitest inputText 稳定丢失
   （4/4），菜单交互唤醒会话后恢复；探针以重试 + 热路径规避。
