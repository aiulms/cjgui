只读咨询，聚焦新生产RED，不写、不构建、不操作设备。框架 /Users/jiangxuanyang/Desktop/cangjie；产品 /Users/jiangxuanyang/Desktop/Pharos Mark。请挑战归因并给最小机制与可区分反例，不全仓盘点。
设备normal r8 SHA e6ab68aa7587881014c734312bc1123fd382eb38d215d4047db2599e0ce8884d PID30467。此前先聚焦安装后长按word、两端拖、跨行拖均正常。新路径：SAVE失焦后直接长按alpha：15:14:19.187 nativeword5:10真实paint高亮，开始proxy mount，caret安装5:10 focused=false；19.197 onChange整值len60与原正文相同(不是人改文)，ime selection回声60:60 native_changed=0，随后nativecaret geometry60(第5行)。19.525 onFocus getter实际5:10，可native仍60；20.262长按END native通知caret60:60，最终平台/窗口塌缩到文尾。后续Agent追加新行恢复68:68（因此N1期望5:10失败是此前视觉selection先丢失，不是restore的identity匹配问题）。原日志在 artifacts/h-overnight-final-20260930/54-final-normal-rejection-restoration-r8/actual-install-and-adoption.hilog.txt；只查16:14:19–20范围，避免巨量历史。
归因假设：native editorCommitPlainChangeLocked 会先cancel restore/seteditingText/caret=全文尾/sel折叠，再editorEnqueueTextCommit(previous,next)，后者发现previous==next没有事件但前者早已移动caret；movingSelection只挡ime_set_selection，不挡same-text mount onChange。
拟最小修复：owned文本节点 plainChange入口若next==editingText且没有活动composition/preview，视为无变化回声，return true但不取消恢复、不动caret/sel/anchor/preview及owner、不出事件。真实不同值仍原入口。请查同值echo可能在composition settle/取消路径出现的边界，不能因guard吃掉真实提交；以及late selection60:60在END后才来是否仍可覆盖、该由native人类anchor还是ArkTS pending selection fence处理。
直接相关文件：
1 runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp editorEnqueueTextCommit约5494，editorCommitPlainChangeLocked约8877，ime_preview_text_ctx/ime_preview_range_ctx、ime_set_selection_ctx约9000，requestLongPressWordLocked/applySelectionHitLocked约4770–4840。
2 产品apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets onChange/selectionChange约520–595、armProxySelection/installProxySelection/onProxyCaret约1171–1265。
3 同产品CjguiTextProxyRegistry.ts onChange、observeSelection，及现有tests/脚本actualgetter、humanselectionanchor。
4 本地成熟Fluttereditable text input value/selection安装机制可按需只读参考，不引依赖。
回答：根因证据、不同序列的判别实验、最小修复写集、平台回声与真实导航/同值composition结算边界、确定性负控。保留同owner/协议/ArkTS薄壳。
