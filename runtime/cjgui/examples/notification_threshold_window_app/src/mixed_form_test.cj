package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_shared_operation_core.*
import cjgui_notification_threshold_application.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func mixedFormNotificationExposesTheExistingEditableFormContract(): Unit {
    let owner: CjguiSharedOperationDomain = CjguiNotificationThresholdDomain()
    @Assert(owner is CjguiSharedEditableFormDomain, true)
}

private func mixedFormEdit(binding: CjguiGeneratedUiFormBinding, fieldId: String,
    value: CjguiSharedOperationValue): Bool {
    let field = binding.fieldSpec(fieldId).getOrThrow()
    return binding.applyFieldIntent(CjguiGeneratedUiIntent(CJGUI_GENERATED_INTENT_FIELD_EDIT, "test", "",
        fieldId: fieldId, writerOperation: field.writeActionName,
        ownerTargetResourceId: CjguiNotificationThresholdDomain.resourceId,
        argumentName: field.argumentName, value: value)).didApply
}

@Test
func mixedFormSharedDefinitionsWriteAllEditorsAndApplyTheOriginalDomain(): Unit {
    let domain = CjguiNotificationThresholdDomain()
    let binding = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
    let catalog = notificationGeneratedCatalog(domain, binding)
    @Assert(catalog.fieldIds().size, 3)
    let threshold = catalog.fieldFor("triggerThreshold").getOrThrow()
    @Assert(threshold.minimum, domain.formBinding().fieldAtControlIndex(1).minimum)
    @Assert(threshold.maximum, domain.formBinding().fieldAtControlIndex(1).maximum)
    @Assert(mixedFormEdit(binding, "deliveryChannel", CjguiSharedOperationValue.string("企业微信")), true)
    @Assert(mixedFormEdit(binding, "triggerThreshold", CjguiSharedOperationValue.string("83")), true)
    @Assert(mixedFormEdit(binding, "isEnabled", CjguiSharedOperationValue.boolean(true)), true)
    @Assert(domain.notificationSnapshot().channel, "邮件")
    @Assert(binding.draftText("deliveryChannel"), "企业微信")
    @Assert(binding.executeAction("APPLY_DRAFT", "apply").applied, true)
    @Assert(domain.notificationSnapshot().channel, "企业微信")
    @Assert(domain.notificationSnapshot().threshold, 83)
    @Assert(domain.notificationSnapshot().enabled, true)
    @Assert(binding.appliedBoolean("isEnabled").getOrThrow(), true)
    @Assert(mixedFormEdit(binding, "deliveryChannel", CjguiSharedOperationValue.string("")), true)
    @Assert(binding.actionAvailable("APPLY_DRAFT"), false)
    @Assert(binding.actionAvailable("CANCEL_DRAFT"), true)
    @Assert(binding.executeAction("CANCEL_DRAFT", "cancel").applied, true)
    @Assert(binding.draftText("deliveryChannel"), "企业微信")
}

@Test
func mixedFormRangeBridgeUsesTheSameOwnerAndRejectsAnOldFieldVersion(): Unit {
    let domain = CjguiNotificationThresholdDomain()
    let binding = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
    let source = CjguiGeneratedFieldRangeSession(binding, "deliveryChannel")
    let before = source.rangeTextVersion()
    @Assert(source.applyRangeTextEdit(before, 0, source.rangeTextByteLength(), "通道A").applied, true)
    @Assert(domain.draftSnapshot().fieldForResourceId(9101).draftText, "通道A")
    let now = source.rangeTextVersion()
    @Assert(now > before, true)
    @Assert(source.applyRangeTextEdit(before, 0, 0, "BAD").isVersionConflict, true)
    @Assert(binding.draftText("deliveryChannel"), "通道A")
    @Assert(binding.rebaseFieldTextSelection("deliveryChannel", now, 0, 3).isSome(), true)
    // The form provider observed the old body through the bridge write and
    // names the whole-value replacement at the new end.
    let replaced = binding.rebaseFieldTextSelection("deliveryChannel", before, 0, 0)
    @Assert(replaced.isSome(), true)
    if (let Some(range) <- replaced) {
        @Assert(range[0], now)
        @Assert(range[1], cjguiUtf8Length("通道A"))
        @Assert(range[2], cjguiUtf8Length("通道A"))
    }
    // A version the provider never observed remains a refusal.
    @Assert(binding.rebaseFieldTextSelection("deliveryChannel", before - 1, 0, 0).isNone(), true)
}

@Test
func mixedFormRangeBridgeMapsAnExternalWholeValueToTheEndAfterANewerPeek(): Unit {
    let domain = CjguiNotificationThresholdDomain()
    let binding = CjguiGeneratedUiFormBinding(domain, CjguiNotificationThresholdDomain.resourceId)
    let source = CjguiGeneratedFieldRangeSession(binding, "deliveryChannel")
    let initial = source.readRangeText(0, 65536)
    @Assert(initial.content, "邮件")
    @Assert(initial.contentVersion, source.rangeTextVersion())
    let initialVersion = initial.contentVersion
    @Assert(source.rebaseRangeTextSelection(initialVersion, 0, 3).isSome(), true)
    // A version this provider never observed has no body to compare; it must
    // stay a refusal instead of being replaced by a generic caret policy.
    @Assert(source.rebaseRangeTextSelection(initialVersion - 1, 0, 0).isNone(), true)
    // Whole-value field write: the adapter names the new end.
    @Assert(mixedFormEdit(binding, "deliveryChannel", CjguiSharedOperationValue.string("企业微信")), true)
    let replacedVersion = source.rangeTextVersion()
    @Assert(replacedVersion > initialVersion, true)
    // The window peeks the NEW body before rebasing the OLD selection. The
    // single latest-read slot would have lost the mapping here.
    let peeked = source.readRangeText(0, 65536)
    @Assert(peeked.content, "企业微信")
    @Assert(peeked.contentVersion, replacedVersion)
    let mapped = source.rebaseRangeTextSelection(initialVersion, 0, 3)
    @Assert(mapped.isSome(), true)
    if (let Some(range) <- mapped) {
        @Assert(range[0], replacedVersion)
        @Assert(range[1], 12)
        @Assert(range[2], 12)
    }
    // Another draft field moves the shared version but leaves this body alone:
    // the old byte range is preserved instead of jumping to the end.
    @Assert(mixedFormEdit(binding, "triggerThreshold", CjguiSharedOperationValue.string("83")), true)
    let laterVersion = source.rangeTextVersion()
    @Assert(laterVersion > replacedVersion, true)
    let laterPeek = source.readRangeText(0, 65536)
    @Assert(laterPeek.content, "企业微信")
    let preserved = source.rebaseRangeTextSelection(replacedVersion, 3, 6)
    @Assert(preserved.isSome(), true)
    if (let Some(range) <- preserved) {
        @Assert(range[0], laterVersion)
        @Assert(range[1], 3)
        @Assert(range[2], 6)
    }
    // The older body is still named while the bounded history holds it.
    let oldMapped = source.rebaseRangeTextSelection(initialVersion, 0, 0)
    @Assert(oldMapped.isSome(), true)
    if (let Some(range) <- oldMapped) {
        @Assert(range[0], laterVersion)
        @Assert(range[1], 12)
        @Assert(range[2], 12)
    }
}

private class MixedFormModalController <: CjguiComposableUiController {
    let panel = CjguiSearchableSelectionPanel("owned-form-return-test")
    public func uiSceneVersion(): Int64 { return panel.revision() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "owned-form-base", CjguiComposableUiStyle())
        root.add(cjguiComposableTextInput(13, "owned-form-field", "通道", "邮件", 9101,
            CjguiComposableUiStyle(fixedHeight: 38)))
        return panel.attachTo(root, CjguiComposableUiTheme.paperLight())
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func rejectUiEvent(kind: Int64, node: Int64): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(false) }
    public func requestWindowClose(): CjguiComposableUiDispatchResult { return CjguiComposableUiDispatchResult(true, shouldClose: true) }
}

@Test
func mixedFormOwnedSingleLineModalReturnUsesTheBoundSelection(): Unit {
    let owner = CjguiNotificationThresholdDomain()
    let binding = CjguiGeneratedUiFormBinding(owner, CjguiNotificationThresholdDomain.resourceId)
    let source = CjguiGeneratedFieldRangeSession(binding, "deliveryChannel")
    let controller = MixedFormModalController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("Owned Form Return Check", 640u32, 520u32))
    let window = host.window()
    @Assert(host.start(), true)
    try {
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        let session = window.bindRangeTextSession(13, "owned-form-field", source, source, 9101,
            CJGUI_COMPOSABLE_UI_TEXT_INPUT)
        @Assert(window.focusAcceptedNodeById(13), true)
        session.setSelection16(0, 2)
        @Assert(window.requestOwnedSelectionRestore(), true)
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        controller.panel.open("通道", ArrayList<CjguiSearchableSelectionItem>([
            CjguiSearchableSelectionItem("mail", "邮件")]), CjguiComposableUiNodeReference.manual(13))
        let _ = window.refresh()
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        // The bound session remains authoritative while the query owns focus.
        // A plain native bookmark still holds 0..2 and cannot restore this 1..2.
        session.setSelection16(1, 2)
        controller.panel.cancel()
        let _ = window.refresh()
        // Wait for the closing scene's actual acceptance, as in the existing
        // modal fixture. refresh may return while its Metal frame is pending.
        // The original-key/native ordering is checked by the normal short chain.
        for (_ in 0..32) { let _ = host.pumpOneTurn() }
        @Assert(window.modalReturnPositionState(CjguiComposableUiNodeReference.manual(13)), "installed")
        @Assert(window.windowProgress().selectionStart, 1)
        @Assert(window.windowProgress().selectionEnd, 2)
        @Assert(session.needsNativeSelectionRestore(), false)
        @Assert(binding.draftText("deliveryChannel"), "邮件")
        let edit = session.replaceRange16(1, 2, "Z")
        @Assert(edit.accepted, true)
        @Assert(session.acknowledge(edit.ticket, edit.contextEpoch), true)
        @Assert(binding.draftText("deliveryChannel"), "邮Z")
        @Assert(binding.appliedText("deliveryChannel"), "邮件")
    } finally { host.close() }
}
