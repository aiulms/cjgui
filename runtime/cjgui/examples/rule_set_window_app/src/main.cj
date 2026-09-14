package cjgui_rule_set_window_app

import cjgui.*
import cjgui_rule_set_application.*
import cjgui_shared_operation_core.*
import std.collection.*
import std.convert.*
import std.env.*
import std.overflow.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

private class CjguiRuleSetStartupFiles {
    let openPath: String
    let saveAsPath: String
    let verifiesHostCloseDecisions: Bool
    /// A finite duration is only a measurement-run lifecycle bound. It does
    /// not alter domain truth or the normal event scheduler.
    let measurementDurationMs: Int64
    /// The same ordinary scheduler pumps during this explicit pre-measurement
    /// interval; it keeps startup outside the steady-state sample window.
    let measurementWarmupMs: Int64
    init(openPath: String, saveAsPath: String, verifiesHostCloseDecisions: Bool, measurementDurationMs: Int64,
        measurementWarmupMs: Int64) {
        this.openPath = openPath
        this.saveAsPath = saveAsPath
        this.verifiesHostCloseDecisions = verifiesHostCloseDecisions
        this.measurementDurationMs = measurementDurationMs
        this.measurementWarmupMs = measurementWarmupMs
    }
}

/// Rule-set presentation adapter for the variable-height range source. It
/// asks the domain for one item only when the composable list materializes
/// that row; it does not copy `collectionSnapshot().allItems()` into a
/// component tree. A row revision is the record's own draft revision, never
/// the collection-wide version, so one changed draft invalidates one cache
/// entry without moving the viewport or selection.
class CjguiRuleSetVirtualListSource <: CjguiComposableUiVariableHeightListSource {
    private let domain: CjguiRuleSetEditingDomain
    private let theme: CjguiComposableUiTheme
    private let bodyStyle: CjguiComposableUiStyle

    init(domain: CjguiRuleSetEditingDomain, theme: CjguiComposableUiTheme, bodyStyle: CjguiComposableUiStyle) {
        this.domain = domain
        this.theme = theme
        this.bodyStyle = bodyStyle
    }
    public func itemCount(): Int64 {
        return domain.collectionRangeSnapshot().totalCount
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let item = domain.collectionItemAt(index)
        if (item.resourceId < 0) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        let draftRevision = domain.draftVersionForCollectionItem(item.resourceId)
        let revision = if (draftRevision >= 0) {
            draftRevision.saturatingMul(2).saturatingAdd(if (domain.selectedRecordId() == item.resourceId) {
                1
            } else {
                0
            })
        } else {
            0
        }
        return CjguiComposableUiVariableHeightListItem("rule_${item.resourceId}", item.resourceId, item.title, revision,
            estimatedHeight: 76)
    }
    public func indexForKey(key: String): Int64 {
        // The range domain already owns a direct resource-id index. Parsing
        // this framework-owned key avoids a hidden full collection scan for
        // every sparse-height correction or keyboard navigation request.
        let parts = key.split("_")
        if (parts.size == 2 && parts[0] == "rule") {
            if (let Some(resourceId) <- Int64.tryParse(parts[1])) {
                return domain.collectionIndexForResourceId(resourceId)
            }
        }
        return -1
    }
    public func measurementGeneration(): Int64 {
        // Selection changes are local row projections, not a shared text
        // measurement dependency.  The selected bit is folded into each
        // item's layoutRevision above, so A/B are lazily refreshed while all
        // unrelated measured rows remain warm.
        return if (bodyStyle.fontFamily == "monospaced") {
            1
        } else {
            0
        }
    }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        let rowTextColor = if (isSelected || isFocused) {
            theme.primaryAction.textColor
        } else {
            bodyStyle.textColor
        }
        let rowBackground = if (isSelected || isFocused) {
            theme.primaryAction.background
        } else {
            theme.card.background
        }
        let row = cjguiComposableVertical(10000000 + item.resourceId, "rule-row-${item.resourceId}",
            CjguiComposableUiStyle(minHeight: 76, padding: 6, gap: 3, background: rowBackground,
                border: theme.card.border, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily))
        row.add(
            cjguiComposableText(11000000 + item.resourceId, "rule-title-${item.resourceId}", item.title,
                CjguiComposableUiStyle(textColor: rowTextColor, fontFamily: bodyStyle.fontFamily, fontWeight: 0),
                resourceId: item.resourceId, displayValueRole: "applied"))
        let revision = domain.draftVersionForCollectionItem(item.resourceId)
        // The range projection intentionally exposes only applied labels. For
        // the selected record, the existing form snapshot is the domain's
        // authoritative draft projection, so external/human draft text can
        // change this off-screen row's ordinary wrapped subtree without
        // creating a second record or draft store. Other rows retain a small
        // status summary and their own revision.
        let summary = if (revision < 0) {
            "规则草稿不可用"
        } else if (domain.selectedRecordId() == item.resourceId) {
            let form = domain.formSnapshot()
            let draftLabel = form.fieldForResourceId(CjguiRuleSetEditingDomain.formLabelResourceId).draftText
            "草稿：${draftLabel} · 版本 ${revision}"
        } else {
            "草稿版本 ${revision} · 可继续编辑此规则"
        }
        row.add(
            cjguiComposableText(12000000 + item.resourceId, "rule-summary-${item.resourceId}", summary,
                CjguiComposableUiStyle(fontSize: 11.0, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily,
                    maxWidth: 300), resourceId: item.resourceId, displayValueRole: "draft"))
        // Keep the existing externally discoverable SELECT_RECORD descriptor
        // and action routing while making title/summary ordinary wrapping
        // text children whose height is solved by the regular layout path.
        row.add(
            cjguiComposableButton(100000 + item.resourceId, "rule-select-${item.resourceId}", "选择", "SELECT_RECORD",
                item.resourceId,
                CjguiComposableUiStyle(fixedHeight: 26, textColor: rowTextColor, fontFamily: bodyStyle.fontFamily),
                operationActionName: "SELECT_RECORD", operationResourceId: item.resourceId))
        return row
    }
}

/// A normal consumer of the experimental composable window. The component
/// tree deliberately lives here, beside the rule-set choices and actions;
/// native code receives no rule field names or fixed form layout.
private class CjguiRuleSetComposableController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant & CjguiComposableUiPointerCaptureVersionProvider {
    private let domain: CjguiRuleSetEditingDomain
    private let listState: CjguiComposableUiVirtualListState
    private let componentRegistry: CjguiComposableUiComponentRegistry
    private var filePath: String
    private var localRevision: Int64
    private var renderedSelectedId: Int64
    private var inputNotice: String
    private var usesDarkAppearance: Bool
    private var usesCoralBeacon: Bool
    private var usesMonospacedText: Bool
    private var layerMode: String

    init(domain: CjguiRuleSetEditingDomain) {
        this.domain = domain
        this.listState = CjguiComposableUiVirtualListState()
        this.componentRegistry = CjguiComposableUiComponentRegistry()
        this.filePath = ""
        this.localRevision = 1
        this.renderedSelectedId = -1
        this.inputNotice = ""
        this.usesDarkAppearance = false
        this.usesCoralBeacon = false
        this.usesMonospacedText = false
        this.layerMode = ""
    }

    public func uiSceneVersion(): Int64 {
        // Aggregate owner state still rebuilds the whole declaration. Pointer
        // capture below uses its narrower split owner revision instead.
        return domain.snapshot().version.saturatingAdd(localRevision)
    }

    public func pointerCaptureVersion(node: CjguiComposableUiLayoutNode): Int64 {
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && node.resourceId == CjguiRuleSetEditingDomain
            .ruleSetResourceId) {
            return domain.splitFirstSizeVersion()
        }
        return uiSceneVersion()
    }

    public func buildUi(): CjguiComposableUiNode {
        let collection = domain.collectionRangeSnapshot();
        let form = domain.formSnapshot();
        let binding = domain.formBinding()
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        let headingStyle = presentationTextStyle(theme.heading)
        let bodyStyle = presentationTextStyle(theme.body)
        let inputStyle = presentationTextStyle(theme.input)
        let validationStyle = CjguiComposableUiStyle(fixedHeight: 20,
            textColor: CjguiComposableUiColor(0.75, 0.12, 0.14, 1.0), fontFamily: bodyStyle.fontFamily)
        let beaconPath = if (usesCoralBeacon) {
            "composable-beacon-coral.png"
        } else {
            "composable-beacon.png"
        }
        let beaconVersion = if (usesCoralBeacon) {
            2
        } else {
            1
        }
        renderedSelectedId = collection.selectedResourceId
        listState.setSelectedKey(if (renderedSelectedId >= 0) {
            "rule_${renderedSelectedId}"
        } else {
            ""
        })
        let host = cjguiComposableLayerHost(1, "rule-set-layer-host", theme.page)
        let root = cjguiComposableVertical(2, "rule-set-root", theme.page)
        // The title owns a full row. Keeping it beside eight fixed actions
        // leaves too little width in a narrow normal window and clips the
        // text; the action row itself still has stable node identities.
        // This region has no range materialization or field draft subtree.
        // Its explicit key therefore covers every value/style dependency
        // below it while allowing the changing list/detail region to remain
        // on the canonical solver path.
        let header = cjguiComposableVertical(5, "rule-set-header", CjguiComposableUiStyle(fixedHeight: 70, gap: 4),
            layoutReuseKey: "rule-header|applied=${form.appliedConfigVersion}|draft=${form.draftVersion}|dark=${usesDarkAppearance}|mono=${usesMonospacedText}")
        header.add(
            cjguiComposableText(3, "rule-set-title",
                "规则集编辑 · 已应用 v${form.appliedConfigVersion} · 草稿 v${form.draftVersion}", headingStyle,
                resourceId: CjguiRuleSetEditingDomain.ruleSetResourceId, fieldId: "ruleSet", displayValueRole: "applied"))
        let commands = cjguiComposableHorizontal(4, "rule-set-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 7))
        commands.add(command(10, "create", "新增", "CREATE_RECORD"))
        commands.add(command(11, "copy", "复制", "COPY_RECORD"))
        commands.add(command(12, "delete", "删除", "DELETE_RECORD"))
        commands.add(command(13, "undo", "撤销", "UNDO"))
        commands.add(command(14, "redo", "重做", "REDO"))
        commands.add(command(15, "save", "保存", "SAVE"))
        commands.add(command(16, "new", "新建", "NEW"))
        commands.add(command(17, "discard", "放弃", "DISCARD"))
        commands.add(localPresentationButton(18, "open-rule-set-menu", "菜单", "OPEN_PRESENTATION_MENU", 64))
        commands.add(localPresentationButton(19, "toggle-rule-set-beacon", "图标", "TOGGLE_BEACON", 64))
        commands.add(localPresentationButton(29, "open-rule-set-editor", "编辑草稿", "OPEN_EDIT_DIALOG", 84))
        header.add(commands);
        root.add(header)

        let listPane = if (collection.totalCount == 0) {
            cjguiComposableText(
                23,
                "empty-list",
                "尚无规则；可用新增创建",
                CjguiComposableUiStyle(
                    minWidth: 160,
                    idealWidth: 260,
                    maxWidth: 340,
                    growX: 1,
                    fixedHeight: 30,
                    textColor: bodyStyle.textColor,
                    fontFamily: bodyStyle.fontFamily
                )
            )
        } else {
            cjguiComposableVariableHeightList(21, "rule-list-scroll", 22,
                CjguiRuleSetVirtualListSource(domain, theme, bodyStyle), listState, 76, 5, 3,
                CjguiComposableUiStyle(minWidth: 160, idealWidth: 260, maxWidth: 340, growX: 1,
                    alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH, background: theme.card.background,
                    border: theme.card.border))
        }

        let detail = cjguiComposableVertical(
            30,
            "rule-detail",
            CjguiComposableUiStyle(
                minWidth: 260,
                idealWidth: 520,
                growX: 2,
                gap: 8
            )
        )
        detail.add(cjguiComposableText(31, "detail-title", if (renderedSelectedId >= 0) {
            "当前规则草稿"
        } else {
            "请选择或新增一条规则"
        }, headingStyle))
        detail.add(
            cjguiComposableImage(32, "rule-set-beacon", beaconPath,
                CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 64, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END),
                imageResourceId: "rule-set-beacon", imageResourceVersion: beaconVersion))
        if (renderedSelectedId >= 0 && layerMode != "edit" && layerMode != "edit-menu") {
            var fieldIndex: Int64 = 0
            while (fieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(fieldIndex);
                let field = form.fieldForResourceId(descriptor.resourceId)
                detail.add(
                    cjguiComposableBoundFormField(detailFieldGroupNodeId(renderedSelectedId, fieldIndex),
                        "field-group-${descriptor.fieldId}", detailFieldNodeId(renderedSelectedId, fieldIndex),
                        detailValidationNodeId(renderedSelectedId, fieldIndex), descriptor, field, renderedSelectedId,
                        inputStyle, validationStyle, editorSemanticId: "field-${descriptor.fieldId}",
                        validationSemanticId: "error-${descriptor.fieldId}", textOperationActionName: "EDIT_DRAFT_TEXT",
                        booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
                fieldIndex += 1
            }
            let applyRow = cjguiComposableHorizontal(41, "draft-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            applyRow.add(command(detailActionNodeId(renderedSelectedId, 0), "apply", "应用草稿", "APPLY"));
            applyRow.add(command(detailActionNodeId(renderedSelectedId, 1), "cancel", "取消草稿", "CANCEL"));
            detail.add(applyRow)
        }
        if (renderedSelectedId >= 0 && (layerMode == "edit" || layerMode == "edit-menu")) {
            detail.add(
                cjguiComposableText(34, "detail-layer-editor-notice",
                    "草稿正在通用对话框中编辑；应用/取消仍直接进入规则集领域。", bodyStyle))
        }
        detail.add(
            cjguiComposableTextInput(390, "file-path", "文件路径", filePath, -1, inputStyle, displayValueRole: "draft"))
        let fileActions = cjguiComposableHorizontal(40, "file-actions", CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
        fileActions.add(command(403, "save-as", "另存为", "SAVE_AS"));
        fileActions.add(command(404, "open", "打开", "OPEN"));
        fileActions.add(command(405, "close", "关闭", "CLOSE"));
        detail.add(fileActions)
        detail.add(cjguiComposableText(50, "status", if (inputNotice.size > 0) {
            inputNotice
        } else {
            collection.statusMessage
        }, fixedTextStyle(bodyStyle, 30)))
        // A distinct normal application also composes the reusable local-key
        // API: neither group reserves a global numeric range or leaks a
        // native menu/product type. Their actions stay on this controller's
        // established owner path.
        let appearance = componentRegistry.use("rule-set-appearance")
        if (appearance.isLive()) {
            let group = cjguiComposableVertical(appearance.nodeId("root"), appearance.semanticId("root"),
                CjguiComposableUiStyle(padding: 4, gap: 2), inputScopeId: appearance.focusScopeId())
            group.add(
                cjguiComposableButton(appearance.nodeId("toggle"), appearance.semanticId("toggle"), "组件：外观/字体",
                    "TOGGLE_PRESENTATION", -1, presentationButtonStyle(150)))
            detail.add(group)
        }
        let resource = componentRegistry.use("rule-set-resource")
        if (resource.isLive()) {
            let group = cjguiComposableVertical(resource.nodeId("root"), resource.semanticId("root"),
                CjguiComposableUiStyle(padding: 4, gap: 2), inputScopeId: resource.focusScopeId())
            group.add(
                cjguiComposableButton(resource.nodeId("toggle"), resource.semanticId("toggle"), "组件：切换图标",
                    "TOGGLE_BEACON", -1, presentationButtonStyle(150)))
            detail.add(group)
        }
        let splitScope = CjguiComposableUiIdentityScope("rule-set-content")
        let split = cjguiComposableScopedSplitView(splitScope, "rule-set-content", listPane, detail,
            CjguiComposableUiSplitAxis.HORIZONTAL, domain.splitFirstSize(), 160, 260,
            CjguiComposableUiStyle(growX: 1, growY: 1), operationActionName: "SET_SPLIT_SIZE",
            operationResourceId: CjguiRuleSetEditingDomain.ruleSetResourceId)
        root.add(split)
        host.add(root)
        if (layerMode == "menu") {
            let menu = cjguiComposableAnchoredLayer(500, "rule-set-menu", "rule-set-menu", "menu", "open-rule-set-menu",
                18,
                CjguiComposableUiStyle(fixedWidth: 156, fixedHeight: 96, background: theme.card.background,
                    border: theme.card.border, padding: 6, gap: 4))
            menu.add(localPresentationButton(501, "menu-toggle-presentation", "外观/字体", "TOGGLE_PRESENTATION", 140))
            menu.add(localPresentationButton(502, "menu-toggle-beacon", "切换图标", "TOGGLE_BEACON", 140))
            menu.add(localPresentationButton(503, "menu-close", "关闭菜单", "CLOSE_LAYER", 140))
            host.add(menu)
        }
        if ((layerMode == "edit" || layerMode == "edit-menu") && renderedSelectedId >= 0) {
            let dialog = cjguiComposableDialogLayer(510, "rule-set-edit-dialog", "rule-set-edit-dialog", "rule-detail",
                30,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 360, background: theme.card.background,
                    border: theme.card.border, padding: 14, gap: 8),
                initialFocusNodeId: dialogFieldNodeId(renderedSelectedId, 0))
            dialog.add(
                cjguiComposableText(511, "rule-dialog-title", "编辑规则草稿", headingStyle,
                    resourceId: CjguiRuleSetEditingDomain.ruleSetResourceId, fieldId: "ruleSet",
                    displayValueRole: "draft"))
            var dialogFieldIndex: Int64 = 0
            while (dialogFieldIndex < binding.fieldCount()) {
                let descriptor = binding.fieldAtControlIndex(dialogFieldIndex);
                let field = form.fieldForResourceId(descriptor.resourceId)
                dialog.add(
                    cjguiComposableBoundFormField(dialogFieldGroupNodeId(renderedSelectedId, dialogFieldIndex),
                        "dialog-field-group-${descriptor.fieldId}",
                        dialogFieldNodeId(renderedSelectedId, dialogFieldIndex),
                        dialogValidationNodeId(renderedSelectedId, dialogFieldIndex), descriptor, field,
                        renderedSelectedId, inputStyle, validationStyle,
                        editorSemanticId: "dialog-field-${descriptor.fieldId}",
                        validationSemanticId: "dialog-error-${descriptor.fieldId}",
                        // The rule editor chooses contextual human wording for
                        // this dialog. Its shared projection still exposes the
                        // stable `retention_count_required` machine reason to
                        // external consumers.
                        validationDisplayMessage: if (descriptor.fieldId == "retentionCount" &&
                            field.validationError.size > 0) {
                            "请先填写保留天数，再应用规则"
                        } else {
                            ""
                        }, textOperationActionName: "EDIT_DRAFT_TEXT", booleanOperationActionName: "EDIT_DRAFT_BOOLEAN"))
                dialogFieldIndex += 1
            }
            let dialogActions = cjguiComposableHorizontal(512, "rule-dialog-actions",
                CjguiComposableUiStyle(fixedHeight: 34, gap: 8))
            dialogActions.add(localPresentationButton(513, "dialog-more", "更多", "OPEN_DIALOG_MENU", 64))
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 0), "dialog-apply", "应用草稿", "APPLY"))
            dialogActions.add(command(dialogActionNodeId(renderedSelectedId, 1), "dialog-cancel", "取消草稿", "CANCEL"))
            dialog.add(dialogActions);
            host.add(dialog)
            if (layerMode == "edit-menu") {
                let submenu = cjguiComposableAnchoredLayer(520, "rule-dialog-menu", "rule-dialog-menu", "menu",
                    "rule-set-edit-dialog", 513,
                    CjguiComposableUiStyle(fixedWidth: 150, fixedHeight: 64, background: theme.card.background,
                        border: theme.card.border, padding: 6, gap: 4))
                submenu.add(
                    localPresentationButton(521, "dialog-menu-presentation", "外观/字体", "TOGGLE_PRESENTATION", 134))
                submenu.add(localPresentationButton(522, "dialog-menu-close", "关闭菜单", "CLOSE_LAYER", 134))
                host.add(submenu)
            }
        }
        return host
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let node = event.node
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && event.eventKind == 35) {
            let direction = if (event.text == "left" || event.text == "up") {
                -1
            } else if (event.text == "right" || event.text == "down") {
                1
            } else {
                0
            }
            if (direction != 0) {
                // The editing domain owns the public 160..720 boundary. A
                // keyboard nudge remains an ordinary local owner action;
                // it never writes a framework-local pane size.
                let next = if (direction < 0) {
                    max(160, domain.splitFirstSize().saturatingSub(8))
                } else {
                    min(720, domain.splitFirstSize().saturatingAdd(8))
                }
                let result = domain.setSplitFirstSizeFromHuman(next)
                if (result.applied) {
                    localRevision += 1
                }
                return CjguiComposableUiDispatchResult(result.applied)
            }
            return CjguiComposableUiDispatchResult(false)
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && (event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_BEGIN || event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_UPDATE ||
            event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_POINTER_END)) {
            let trackOrigin = node.bounds.x - node.pointerControlFirstSize
            let splitFirstSize = CjguiComposableUiSplitGeometry.firstSizeForPointer(event.pointerX, trackOrigin, 720,
                node.pointerControlHandleThickness, 160, 260)
            let result = domain.setSplitFirstSizeFromHuman(splitFirstSize)
            if (result.applied) {
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (node.nodeKind == CJGUI_COMPOSABLE_UI_SPLIT_HANDLE && event.eventKind ==
            CJGUI_COMPOSABLE_UI_EVENT_POINTER_CANCEL) {
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if ((event.eventKind == 36 && layerMode.size > 0) || (event.eventKind == 27 && node.actionName == "LAYER_OUTSIDE")) {
            layerMode = if (event.eventKind == 36 && layerMode == "edit-menu") {
                "edit"
            } else {
                ""
            };
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 30 && node.nodeId == 21) {
            listState.scrollByViewport(event.text)
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 31 && node.actionName == "SELECT_RECORD") {
            listState.setFocusedKey("rule_${node.resourceId}")
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (event.eventKind == 35 && node.nodeId == 21) {
            let target = listState.moveFocus(currentListSource(), event.text)
            if (target.resourceId < 0) {
                return CjguiComposableUiDispatchResult(false)
            }
            let selected = domain.selectCollectionItemFromHuman(target.resourceId)
            if (selected.applied) {
                listState.setSelectedKey(target.key);
                listState.setFocusedKey(target.key);
                localRevision += 1
            }
            return CjguiComposableUiDispatchResult(selected.applied)
        }
        if (event.eventKind == 28 && node.nodeId == 390) {
            filePath = event.text
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let detailTargetRecordId = detailRecordId(node.nodeId)
        let targetRecordId = if (detailTargetRecordId >= 0) {
            detailTargetRecordId
        } else {
            dialogRecordId(node.nodeId)
        }
        if (event.eventKind == 28 && targetRecordId >= 0) {
            let result = domain.editTextForCollectionItemFromHuman(targetRecordId, node.resourceId, event.text,
                event.selectionStart, event.selectionEnd)
            if (result.applied) {
                localRevision += 1
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind == 29 && targetRecordId >= 0) {
            let result = domain.editBooleanForCollectionItemFromHuman(targetRecordId, node.resourceId,
                event.text == "true")
            if (result.applied) {
                localRevision += 1
            };
            return CjguiComposableUiDispatchResult(result.applied)
        }
        if (event.eventKind != 27) {
            return CjguiComposableUiDispatchResult(false)
        }
        if (node.actionName == "OPEN_PRESENTATION_MENU") {
            layerMode = "menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "OPEN_EDIT_DIALOG") {
            if (renderedSelectedId < 0) {
                inputNotice = "请先选择一条规则"
            } else {
                layerMode = "edit"
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(renderedSelectedId >= 0)
        }
        if (node.actionName == "OPEN_DIALOG_MENU" && layerMode == "edit") {
            layerMode = "edit-menu"
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "CLOSE_LAYER") {
            layerMode = if (node.semanticId == "dialog-menu-close") {
                "edit"
            } else {
                ""
            }
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_PRESENTATION") {
            usesDarkAppearance = !usesDarkAppearance
            usesMonospacedText = !usesMonospacedText
            inputNotice = if (usesDarkAppearance) {
                "已切换到深色与等宽文字"
            } else {
                "已切换到浅色与系统文字"
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        if (node.actionName == "TOGGLE_BEACON") {
            usesCoralBeacon = !usesCoralBeacon
            inputNotice = if (usesCoralBeacon) {
                "已替换为珊瑚灯塔资源"
            } else {
                "已恢复蓝色灯塔资源"
            }
            layerMode = ""
            localRevision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        let result = if (node.actionName == "SELECT_RECORD") {
            domain.selectCollectionItemFromHuman(node.resourceId)
        } else if (node.actionName == "CREATE_RECORD") {
            domain.createCollectionItemFromHuman()
        } else if (node.actionName == "COPY_RECORD") {
            domain.copySelectedCollectionItemFromHuman()
        } else if (node.actionName == "DELETE_RECORD") {
            domain.deleteSelectedCollectionItemFromHuman()
        } else if (node.actionName == "UNDO") {
            domain.undoFromHuman()
        } else if (node.actionName == "REDO") {
            domain.redoFromHuman()
        } else if (node.actionName == "SAVE") {
            domain.saveFromHuman()
        } else if (node.actionName == "NEW") {
            domain.newUntitledFromHuman()
        } else if (node.actionName == "DISCARD") {
            domain.discardUnsavedContentFromHuman()
        } else if (node.actionName == "SAVE_AS") {
            domain.saveAsFromHuman(filePath)
        } else if (node.actionName == "OPEN") {
            domain.openFromHuman(filePath)
        } else if (node.actionName == "APPLY" && actionRecordId(node.nodeId) >= 0) {
            let itemId = actionRecordId(node.nodeId)
            domain.applyDraftForCollectionItemFromHuman(itemId, domain.draftVersionForCollectionItem(itemId),
                domain.baseAppliedVersionForCollectionItem(itemId))
        } else if (node.actionName == "CANCEL" && actionRecordId(node.nodeId) >= 0) {
            let itemId = actionRecordId(node.nodeId)
            domain.cancelDraftForCollectionItemFromHuman(itemId, domain.draftVersionForCollectionItem(itemId),
                domain.baseAppliedVersionForCollectionItem(itemId))
        } else if (node.actionName == "CLOSE") {
            domain.requestCloseFromHuman()
        } else {
            CjguiSharedOperationActionResult(false, false, 0, 0, "unknown_ui_action")
        }
        if (result.applied && node.actionName == "SELECT_RECORD") {
            listState.setSelectedKey("rule_${node.resourceId}");
            listState.setFocusedKey("rule_${node.resourceId}")
        }
        if (result.applied && (node.actionName == "APPLY" || node.actionName == "CANCEL")) {
            layerMode = ""
        }
        if (result.applied) {
            localRevision += 1
        }
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: node.actionName == "CLOSE" && result.applied)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        let result = domain.requestCloseFromHuman();
        if (result.applied) {
            localRevision += 1
        }
        return CjguiComposableUiDispatchResult(result.applied, shouldClose: result.applied)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        inputNotice = if (eventKind == 11) {
            "输入队列已满：本次输入未应用，请重试"
        } else {
            "输入未应用：事件 ${eventKind} 的原控件已刷新或移除（节点 ${nodeId}）"
        }
        localRevision += 1
        return CjguiComposableUiDispatchResult(true)
    }
    public func beginSceneRefresh(): Bool {
        return componentRegistry.beginTransaction()
    }
    public func prepareSceneRefresh(): Bool {
        return componentRegistry.prepareTransaction()
    }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>(
            [CjguiComposableUiCommand("rule-set.open-presentation-menu", 18, CjguiComposableUiShortcut("m"))])
    }
    public func commitSceneRefresh(): Unit {
        componentRegistry.commitTransaction()
    }
    public func rollbackSceneRefresh(): Unit {
        componentRegistry.rollbackTransaction()
    }

    private func command(nodeId: Int64, semanticId: String, label: String, actionName: String): CjguiComposableUiNode {
        return cjguiComposableButton(nodeId, semanticId, label, actionName, CjguiRuleSetEditingDomain.ruleSetResourceId,
            presentationButtonStyle(64), operationActionName: operationActionName(actionName))
    }
    private func localPresentationButton(nodeId: Int64, semanticId: String, label: String, actionName: String,
        width: Int64): CjguiComposableUiNode {
        return cjguiComposableButton(nodeId, semanticId, label, actionName, -1, presentationButtonStyle(width))
    }
    private func presentationButtonStyle(width: Int64): CjguiComposableUiStyle {
        let base = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark().card
        } else {
            CjguiComposableUiTheme.paperLight().card
        }
        return CjguiComposableUiStyle(minWidth: if (width > 48) {
            48
        } else {
            width
        }, idealWidth: width, fixedHeight: 30, background: base.background, border: base.border,
            textColor: if (usesDarkAppearance) {
                CjguiComposableUiColor(0.92, 0.95, 1.0, 1.0)
            } else {
                CjguiComposableUiColor(0.12, 0.16, 0.23, 1.0)
            }, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            })
    }
    private func presentationTextStyle(base: CjguiComposableUiStyle): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(background: base.background, border: base.border, textColor: base.textColor,
            padding: base.padding, gap: base.gap, fixedWidth: base.fixedWidth, fixedHeight: base.fixedHeight,
            growX: base.growX, growY: base.growY, borderWidth: base.borderWidth, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: if (usesMonospacedText) {
                "monospaced"
            } else {
                "system"
            }, minWidth: base.minWidth, maxWidth: base.maxWidth, idealWidth: base.idealWidth, minHeight: base.minHeight,
            maxHeight: base.maxHeight, idealHeight: base.idealHeight, alignX: base.alignX, alignY: base.alignY)
    }
    private func fixedTextStyle(base: CjguiComposableUiStyle, height: Int64): CjguiComposableUiStyle {
        return CjguiComposableUiStyle(fixedHeight: height, textColor: base.textColor, fontSize: base.fontSize,
            fontWeight: base.fontWeight, fontFamily: base.fontFamily)
    }
    private func operationActionName(controllerAction: String): String {
        if (controllerAction == "CREATE_RECORD" || controllerAction == "COPY_RECORD" || controllerAction ==
            "DELETE_RECORD" || controllerAction == "UNDO" || controllerAction == "REDO") {
            return controllerAction
        }
        if (controllerAction == "SAVE") {
            return "SAVE_RULE_SET"
        }
        if (controllerAction == "APPLY") {
            return "APPLY_DRAFT"
        }
        if (controllerAction == "CANCEL") {
            return "CANCEL_DRAFT"
        }
        return ""
    }
    private func currentListSource(): CjguiRuleSetVirtualListSource {
        let theme = if (usesDarkAppearance) {
            CjguiComposableUiTheme.beaconDark()
        } else {
            CjguiComposableUiTheme.paperLight()
        }
        return CjguiRuleSetVirtualListSource(domain, theme, presentationTextStyle(theme.body))
    }
    private func detailFieldNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 200000000 + recordId * 16 + fieldIndex
    }
    private func detailFieldGroupNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 600000000 + recordId * 16 + fieldIndex
    }
    private func detailValidationNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 700000000 + recordId * 16 + fieldIndex
    }
    private func detailActionNodeId(recordId: Int64, actionIndex: Int64): Int64 {
        return 300000000 + recordId * 4 + actionIndex
    }
    private func dialogFieldNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 400000000 + recordId * 16 + fieldIndex
    }
    private func dialogFieldGroupNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 800000000 + recordId * 16 + fieldIndex
    }
    private func dialogValidationNodeId(recordId: Int64, fieldIndex: Int64): Int64 {
        return 900000000 + recordId * 16 + fieldIndex
    }
    private func dialogActionNodeId(recordId: Int64, actionIndex: Int64): Int64 {
        return 500000000 + recordId * 4 + actionIndex
    }
    private func detailRecordId(nodeId: Int64): Int64 {
        if (nodeId < 200000000 || nodeId >= 300000000) {
            return -1
        }
        return (nodeId - 200000000) / 16
    }
    private func detailActionRecordId(nodeId: Int64): Int64 {
        if (nodeId < 300000000) {
            return -1
        }
        return (nodeId - 300000000) / 4
    }
    private func dialogRecordId(nodeId: Int64): Int64 {
        if (nodeId < 400000000 || nodeId >= 500000000) {
            return -1
        }
        return (nodeId - 400000000) / 16
    }
    private func actionRecordId(nodeId: Int64): Int64 {
        let detail = detailActionRecordId(nodeId)
        if (detail >= 0 && nodeId < 400000000) {
            return detail
        }
        if (nodeId < 500000000) {
            return -1
        }
        return (nodeId - 500000000) / 4
    }
}

private func parseStartupFiles(args: Array<String>): ?CjguiRuleSetStartupFiles {
    var openPath = "";
    var saveAsPath = "";
    var verifiesHostCloseDecisions = false;
    var measurementDurationMs: Int64 = 0
    var measurementWarmupMs: Int64 = 0;
    var hasMeasurementWarmup = false;
    var index: Int64 = 0
    while (index < args.size) {
        if ((args[index] == "--open" || args[index] == "--save-as") && index + 1 < args.size) {
            if (args[index] == "--open" && openPath.size == 0) {
                openPath = args[index + 1]
            } else if (args[index] == "--save-as" && saveAsPath.size == 0) {
                saveAsPath = args[index + 1]
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--verify-host-close-decisions" && !verifiesHostCloseDecisions && openPath.size == 0 &&
            saveAsPath.size == 0) {
            verifiesHostCloseDecisions = true
            index += 1
        } else if (args[index] == "--measurement-duration-ms" && index + 1 < args.size && measurementDurationMs == 0) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value > 0 && value <= 900000) {
                    measurementDurationMs = value
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 2
        } else if (args[index] == "--measurement-warmup-ms" && index + 1 < args.size && !hasMeasurementWarmup) {
            if (let Some(value) <- Int64.tryParse(args[index + 1])) {
                if (value >= 0 && value <= 60000) {
                    measurementWarmupMs = value
                    hasMeasurementWarmup = true
                } else {
                    return None
                }
            } else {
                return None
            }
            index += 2
        } else {
            return None
        }
    }
    return Some(
        CjguiRuleSetStartupFiles(openPath, saveAsPath, verifiesHostCloseDecisions, measurementDurationMs,
            measurementWarmupMs))
}

private func authorization(): CjguiSharedOperationExternalAuthorization {
    let all = ArrayList<Int64>()
    return CjguiSharedOperationExternalAuthorization(
        "规则集本地 Agent",
        "cjgui-rule-set-agent-20260912",
        ArrayList<CjguiSharedOperationExternalActionScope>(
            [
                CjguiSharedOperationExternalActionScope("GET_CONTEXT", all, true),
                CjguiSharedOperationExternalActionScope("GET_CHANGES", all, true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_PROGRESS", all, true),
                CjguiSharedOperationExternalActionScope("GET_WINDOW_INTERACTION", all, true),
                CjguiSharedOperationExternalActionScope("CREATE_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("COPY_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("RENAME_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("DELETE_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("SELECT_RECORD", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_TEXT", all, true),
                CjguiSharedOperationExternalActionScope("EDIT_DRAFT_BOOLEAN", all, true),
                CjguiSharedOperationExternalActionScope("APPLY_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("CANCEL_DRAFT", all, true),
                CjguiSharedOperationExternalActionScope("BATCH_SET_ENABLED", all, true),
                CjguiSharedOperationExternalActionScope("UNDO", all, true),
                CjguiSharedOperationExternalActionScope("REDO", all, true),
                CjguiSharedOperationExternalActionScope("SAVE_RULE_SET", all, true),
                CjguiSharedOperationExternalActionScope("SET_SPLIT_SIZE", all, true)
            ]
        )
    )
}

private func assertRuleSetProjectionIdentity(projection: CjguiSharedOperationWindowProjection): Unit {
    var listContentNodeId: Int64 = -1
    var splitHandleNodeId: Int64 = -1
    for (node in projection.nodes) {
        if (node.semanticId == "rule-list-scroll_materialized") {
            listContentNodeId = node.nodeId
        }
        if (node.semanticId == "rule-set-content-handle") {
            splitHandleNodeId = node.nodeId
        }
    }
    @Assert(listContentNodeId, 22)
    @Assert(splitHandleNodeId > 0, true)
    @Assert(splitHandleNodeId != listContentNodeId, true)
}

// Regression boundary for the first real collection mutation. The native UI
// event path has already resolved the visible `create` button to this exact
// controller action; this test keeps the owner/controller -> rebuilt
// variable-height-list projection in the normal window transaction. It must
// not strand a successfully-created record behind the former empty-list scene.
@Test
func firstCreateProjectsRuleListThroughNormalWindowTransaction(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let before = window.windowProjection()
    let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(), CjguiComposableUiRect(0, 0, 980, 620),
        1)
    let create = initialScene.nodeForId(10)
    @Assert(create.nodeId, 10)
    let dispatched = controller.applyUiEvent(CjguiComposableUiEvent(create, 27, "", 0, 0, initialScene.version))
    @Assert(dispatched.didApply, true)
    @Assert(domain.collectionRangeSnapshot().totalCount, 1)
    @Assert(window.refresh(), true)
    assertRuleSetProjectionIdentity(window.windowProjection())
    let after = window.windowProjection()
    @Assert(after.acceptedSceneVersion > before.acceptedSceneVersion, true)
    @Assert(after.pendingRefreshReason, "none")
    window.close()
}

// The public shared-operation route may add a run of records while the
// window remains open. Each accepted owner version must reach the same list
// projection as a local action; a stale scene is not an acceptable fallback.
@Test
func externalRuleFixtureProjectsEveryVisibleListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    var index: Int64 = 1
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "外部滚动验证规则 ${index}", true, 7,
                "cache", "external-scroll-${index}"))
        @Assert(created.applied, true)
        @Assert(window.refresh(), true)
        let progress = window.windowProjection()
        @Assert(progress.pendingRefreshReason, "none")
        @Assert(progress.lastNativeFailure, "none")
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    assertRuleSetProjectionIdentity(window.windowProjection())
    window.close()
}

// The normal host drains multiple already-accepted external actions in one
// turn, then requests one projection refresh. Keep that coalesced path
// distinct from the per-action case above: virtual-list materialization must
// converge from one visible row to a populated viewport in a single commit.
@Test
func batchedExternalRuleFixtureProjectsCoalescedListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    var index: Int64 = 1
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "批量滚动验证规则 ${index}", true, 7,
                "cache", "batched-scroll-${index}"))
        @Assert(created.applied, true)
        if (index == 1) {
            @Assert(window.refresh(), true)
        }
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    @Assert(window.refresh(), true)
    let progress = window.windowProjection()
    @Assert(progress.pendingRefreshReason, "none")
    @Assert(progress.lastNativeFailure, "none")
    assertRuleSetProjectionIdentity(progress)
    window.close()
}

// A local first create leaves controller-local presentation revision state;
// subsequent externally authored records are still coalesced by the normal
// host. This is the exact mixed-owner sequence exercised by a real button
// followed by a public fixture load.
@Test
func localFirstCreateThenBatchedExternalFixtureProjectsListRefresh(): Unit {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    let controller = CjguiRuleSetComposableController(domain)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let initialScene = CjguiComposableUiLayoutEngine.layout(controller.buildUi(), CjguiComposableUiRect(0, 0, 980, 620),
        1)
    let localCreated = controller.applyUiEvent(
        CjguiComposableUiEvent(initialScene.nodeForId(10), 27, "", 0, 0, initialScene.version))
    @Assert(localCreated.didApply, true)
    @Assert(window.refresh(), true)
    var index: Int64 = 2
    while (index <= 16) {
        let created = domain.executeFromExternal(
            CjguiRuleSetInvocationFactory.create(domain.snapshot().version, "混合滚动验证规则 ${index}", true, 7,
                "cache", "mixed-scroll-${index}"))
        @Assert(created.applied, true)
        index += 1
    }
    @Assert(domain.collectionRangeSnapshot().totalCount, 16)
    @Assert(window.refresh(), true)
    let progress = window.windowProjection()
    @Assert(progress.pendingRefreshReason, "none")
    @Assert(progress.lastNativeFailure, "none")
    assertRuleSetProjectionIdentity(progress)
    window.close()
}

private func runRuleSetApp(startup: CjguiRuleSetStartupFiles): Int32 {
    let domain = CjguiRuleSetEditingDomain.newUntitled()
    if (startup.openPath.size > 0 && !domain.openFromHuman(startup.openPath).applied) {
        getStdErr().writeln("rule set: cannot open requested file");
        CjguiMacosApplicationHost.stopApplicationLoop();
        return 2
    }
    if (startup.saveAsPath.size > 0 && !domain.saveAsFromHuman(startup.saveAsPath).applied) {
        getStdErr().writeln("rule set: cannot save requested file");
        CjguiMacosApplicationHost.stopApplicationLoop();
        return 2
    }
    let controller = CjguiRuleSetComposableController(domain)
    let host = CjguiMacosApplicationHost(
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 规则集编辑器", 980u32, 620u32)
    )
    let window = host.window()
    let connection = CjguiSharedOperationExternalConnection(domain, authorization(), domain, window)
    if (!connection.enableTargetedContextReads(domain) || !connection.enableWindowProgressReads(window) ||
        !host.attachExternalConnection(connection) || !host.start()) {
        host.close();
        return 1
    }
    if (startup.verifiesHostCloseDecisions) {
        if (!domain.createCollectionItemFromHuman().applied) {
            host.close();
            return 1
        }
        window.requestRefresh()
        // The real controller/domain rejects the first close while data is unsaved.
        if (host.requestClose() || !host.isOpen()) {
            host.close();
            return 1
        }
        if (!domain.discardUnsavedContentFromHuman().applied) {
            host.close();
            return 1
        }
        window.requestRefresh()
        // It then accepts the same Host close decision and cleans its endpoint.
        if (!host.requestClose() || host.isOpen()) {
            host.close();
            return 1
        }
        if (let Some(_) <- connection.connectionInfo()) {
            host.close();
            return 1
        }
        host.close()
        getStdOut().writeln("CJGUI_RULE_SET_HOST_PROBE rejected_then_accepted_close_cleaned")
        return 0
    }
    if (let Some(info) <- connection.connectionInfo()) {
        let output = getStdOut()
        output.writeln("CJGUI_RULE_SET_READY DESCRIPTOR_PATH ${info.descriptorPath}")
        output.writeln("CJGUI_RULE_SET_READY PROTOCOL ${info.protocol}")
        let projection = window.windowProjection()
        if (!projection.isActive || projection.sessionIdentity.size == 0 || projection.submittedFrameIndex <= 0) {
            output.flush();
            host.close();
            return 1
        }
        output.writeln(
            "CJGUI_RULE_SET_READY WINDOW_READY ${projection.sessionIdentity} ${projection.submittedFrameIndex}")
        output.flush()
    }
    let warmupStarted = MonoTime.now()
    while (host.isOpen() && (MonoTime.now() - warmupStarted).toMilliseconds() < startup.measurementWarmupMs) {
        let _ = host.pumpOneTurn()
    }
    if (host.isOpen()) {
        let output = getStdOut();
        let projection = window.windowProjection()
        output.writeln("CJGUI_RULE_SET_READY MEASUREMENT_START ${projection.sessionIdentity}");
        output.flush()
    }
    let measurementStarted = MonoTime.now()
    while (host.isOpen() && (startup.measurementDurationMs <= 0 ||
            (MonoTime.now() - measurementStarted).toMilliseconds() < startup.measurementDurationMs)) {
        let _ = host.pumpOneTurn()
    }
    host.close();
    return 0
}

main(args: Array<String>): Int64 {
    if (let Some(startup) <- parseStartupFiles(args)) {
        return Int64(runRuleSetApp(startup))
    }
    getStdErr().writeln(
        "usage: CJGUIRuleSet [--open PATH] [--save-as PATH] [--verify-host-close-decisions] [--measurement-warmup-ms 0..60000] [--measurement-duration-ms 1..900000]")
    CjguiMacosApplicationHost.stopApplicationLoop()
    return 2
}
