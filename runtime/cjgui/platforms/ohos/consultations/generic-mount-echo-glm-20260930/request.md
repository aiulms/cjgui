# 独立只读咨询：普通 TextInput 相同正文挂载回声阻止长按选择

仅读下列相关函数及证据，不扫描整个仓库，不修改、不构建、不操作设备。质疑归因，区分已证事实与推断，给最小机制修复、可区分反例与边界。

框架根 /Users/jiangxuanyang/Desktop/cangjie。
真实最终 normal thermo HAP 74ebc7c8b5c7bfb5653df7977c8f5dd77097f8c2463f8642617dde9ceb0e8f2a，PID8329，平台指纹15bc261b893d4ddd0a3eca961630b4728b01bf238ba26edd371f35d371ef28c8。同指纹Pharos受管正文长按、双端拖柄、完整接续已通过。普通 thermo note 属于现有显式 submit owner 规则，不能改成逐键提交或另造 owner。

真实正常手写视口 offscreen reveal→focus→长按，owner提前通过公开SET_NOTE(text=warm)准备为warm4UTF16，且无其他owner写入。正确新accepted几何和平台聚焦已通过；长按落在实际字形，BEGIN17:55:32.269，END17:55:33.774，1.505s，caret命中0，期间完全没有word hit/long-press selection。装载时17:55:26.654 onChange len4 verdictok；其后caret/setSelection getter观察0:0真实一致。没有替换输入被发出。当前严格探针停止而非放宽全选条件。

生产路径：ohos_renderer_ime_preview_text_ctx调用editorCommitPlainChangeLocked；后者首句!editorOwnsTextSession返回false（generic），其后未preview/marked的same-text noop guard只对owned成立。外层false后将相同warm置previewActive=true。requestLongPressWordLocked明确拒绝previewActive。这是当前假设，需检查其他撤销/生命周期可能性。现有test_plain_mount_echo_native.py甚至断言generic相同正文必须returnfalse，导致未涵盖此正常消费缺口。

拟议：将未preview/marked的next==editingText no-op guard放在ownership判断前，保留整值差异和已有真实marked/preview路径。generic same-value挂载回声不产生预览、提交、caret折叠，也不取消恢复；generic实际变文仍保持draft直到submit。不得依靠清preview后强制选择、绕过组合门或改ArkTS产品规则。

必要文件：
- runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp：requestLongPressWordLocked(~4775)，editorCommitPlainChangeLocked(~8900)，ohos_renderer_ime_preview_text_ctx/range_ctx(~8930)，editorOwnsTextSession，beginEditingOnNodeLocked。
- runtime/cjgui/platforms/ohos/scripts/test_plain_mount_echo_native.py（actual函数摘取）；test_selection_handles_native.py（actual长按函数）；test_ime_range_delta_native.py（stub/harness）。
- runtime/cjgui/platforms/ohos/arkts/cjgui-text-proxy.ets onChange（平台previewText是否为marked之唯一入口）。
- artifacts/h-overnight-final-20260930/84-final-second-consumer-hand-input-r12/probe/hilog_after_long_click.txt（按上述时间局部读取，勿输出全文），failure.json、field_point.json。

回答：1是否应在ownership之前消除same-text非composition回声；2普通draft与真实组合同值是否仍保留；3需要哪些生产摘录反例/负控；4若本归因不成立，给区分检查。咨询不当运行证据。不要要求从头重验已绿积分数学。
