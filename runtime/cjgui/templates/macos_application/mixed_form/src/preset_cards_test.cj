// Consumer-side tests for the reactive preset cards: the SAME field
// declarations as the handwritten preset, one owner per card, per-card draft
// CAS, and an explicit rebind that refuses the retired owner.
package cjgui_mixed_form_starter

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*
import std.env.*
import cjgui.*
import cjgui_shared_operation_core.*

private func cardCall(domain: PrintPresetDomain, action: String, owner: Int64,
    arguments: ArrayList<CjguiSharedOperationActionArgument>): CjguiSharedOperationActionInvocation {
    // The protocol CAS is the owner context version, read from the same domain
    // the test is operating on (not a guessed 0).
    return CjguiSharedOperationActionInvocation(action, domain.formSnapshot().contextVersion,
        ArrayList<Int64>([owner]), arguments)
}

private func cardTextAction(domain: PrintPresetDomain, action: String, fieldId: String, text: String,
    owner: Int64, expectedDraft: Int64): CjguiSharedOperationActionResult {
    return domain.executeFromHuman(cardCall(domain, action, owner,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("fieldId", CjguiSharedOperationValue.string(fieldId)),
            CjguiSharedOperationActionArgument("text", CjguiSharedOperationValue.string(text)),
            CjguiSharedOperationActionArgument("expectedDraftVersion", CjguiSharedOperationValue.integer(expectedDraft))
        ])))
}

@Test
func presetCardUsesTheSharedDeclarationsWithItsOwnOwner(): Unit {
    let domain = PrintPresetDomain()
    let cardA = domain.cards.card("cardA").getOrThrow()
    let cardB = domain.cards.card("cardB").getOrThrow()
    // Same declared field ids and resource ids, different business objects.
    @Assert(cardA.ownerId, 6301)
    @Assert(cardB.ownerId, 6302)
    @Assert(cardA.binding().fieldCount(), domain.formBinding().fieldCount())
    for (index in 0..cardA.binding().fieldCount()) {
        @Assert(cardA.binding().fieldAtControlIndex(index).fieldId,
            domain.formBinding().fieldAtControlIndex(index).fieldId)
        @Assert(cardA.binding().fieldAtControlIndex(index).resourceId,
            domain.formBinding().fieldAtControlIndex(index).resourceId)
    }
}

@Test
func presetCardDraftCasIsPerCard(): Unit {
    let domain = PrintPresetDomain()
    // Card B's draft version is its own input basis: writing B does not make
    // A's accepted CAS stale.
    let writeB = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "改 B", 6302, 0)
    @Assert(writeB.applied, true)
    @Assert(domain.cards.card("cardB").getOrThrow().draftText("jobName"), "改 B")
    @Assert(domain.cards.card("cardA").getOrThrow().draftText("jobName"), "资料 A")
    let staleB = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "再改 B", 6302, 0)
    @Assert(staleB.applied, false)
    @Assert(staleB.reason, "stale_draft")
    let freshB = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "再改 B", 6302, 1)
    @Assert(freshB.applied, true)
}

@Test
func presetCardApplyRefusesInvalidDraftAndCancelRestores(): Unit {
    let domain = PrintPresetDomain()
    let invalid = cardTextAction(domain, "EDIT_DRAFT_TEXT", "copies", "99", 6301, 0)
    @Assert(invalid.applied, true)
    let applyInvalid = domain.executeFromHuman(cardCall(domain, "APPLY_DRAFT", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion", CjguiSharedOperationValue.integer(1))
        ])))
    @Assert(applyInvalid.applied, false)
    @Assert(applyInvalid.reason, "份数需在 1–24 之间")
    // The card's own snapshot reports the same reason on its Apply action.
    let availability = domain.cards.card("cardA").getOrThrow().actionAvailability("APPLY_DRAFT")
    @Assert(availability.known, true)
    @Assert(availability.isAvailable, false)
    @Assert(availability.reason, "份数需在 1–24 之间")
    // Cancel restores the applied value of THIS card.
    let cancel = domain.executeFromHuman(cardCall(domain, "CANCEL_DRAFT", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("expectedDraftVersion", CjguiSharedOperationValue.integer(1))
        ])))
    @Assert(cancel.applied, true)
    @Assert(domain.cards.card("cardA").getOrThrow().draftText("copies"), "4")
    // The sibling never saw any of it.
    @Assert(domain.cards.card("cardB").getOrThrow().draftText("copies"), "2")
}

@Test
func presetCardApplyAndCancelLeaveTheSelectedCardClean(): Unit {
    let domain = PrintPresetDomain()
    let card = domain.cards.card("cardB").getOrThrow()
    @Assert(card.setText("jobName", "只改 B"), true)
    let beforeApply = card.snapshot(domain.formSnapshot().contextVersion)
    @Assert(beforeApply.draftVersion != beforeApply.appliedConfigVersion, true)
    let applied = card.apply()
    @Assert(applied[0], true)
    let afterApply = card.snapshot(domain.formSnapshot().contextVersion)
    @Assert(afterApply.draftVersion, afterApply.appliedConfigVersion)
    @Assert(afterApply.fieldForResourceId(6201).appliedValue.displayText(), "只改 B")
    // Edit AGAIN after Apply, then Cancel: the draft returns to the values the
    // Apply just accepted, the card is clean (not merely restored-but-dirty),
    // and a request carrying the pre-Cancel draft basis is refused as stale.
    @Assert(card.setText("jobName", "又改 B"), true)
    @Assert(card.setText("copies", "12"), true)
    let beforeCancel = card.snapshot(domain.formSnapshot().contextVersion)
    @Assert(beforeCancel.draftVersion != beforeCancel.appliedConfigVersion, true)
    let draftVersionBeforeCancel = beforeCancel.draftVersion
    let cancelled = card.cancel()
    @Assert(cancelled[0], true)
    let afterCancel = card.snapshot(domain.formSnapshot().contextVersion)
    @Assert(afterCancel.fieldForResourceId(6201).draftText, "只改 B")
    @Assert(afterCancel.fieldForResourceId(6202).draftText, "2")
    @Assert(afterCancel.draftVersion, afterCancel.appliedConfigVersion)
    // The pre-Cancel draft basis is no longer an accepted input: a write
    // stamped with it must be rejected instead of silently rebasing.
    let staleAfterCancel = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "过期写", 6302,
        draftVersionBeforeCancel)
    @Assert(staleAfterCancel.applied, false)
    @Assert(staleAfterCancel.reason, "stale_draft")
    // Sibling card is untouched and still clean.
    let sibling = domain.cards.card("cardA").getOrThrow().snapshot(domain.formSnapshot().contextVersion)
    @Assert(sibling.draftVersion, sibling.appliedConfigVersion)
    @Assert(domain.cards.card("cardA").getOrThrow().draftText("jobName"), "资料 A")
}

@Test
func presetCardRebindRetiresTheOldOwner(): Unit {
    let domain = PrintPresetDomain()
    let rebind = domain.executeFromHuman(cardCall(domain, "REBIND_CARD", 6302,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("cardKey", CjguiSharedOperationValue.string("cardB")),
            CjguiSharedOperationActionArgument("newOwner", CjguiSharedOperationValue.integer(6303))
        ])))
    @Assert(rebind.applied, true)
    @Assert(domain.cards.ownerFor("cardB"), 6303)
    // A write addressed to the RETIRED owner is refused, not re-routed to the
    // new object the key maps to now.
    let stale = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "旧对象", 6302, 0)
    @Assert(stale.applied, false)
    @Assert(stale.reason, "unknown_target")
    @Assert(domain.cards.card("cardB").getOrThrow().draftText("jobName"), "新对象")
}

@Test
func presetCardChangeAdvancesTheOwnerContextVersion(): Unit {
    let domain = PrintPresetDomain()
    let before = domain.formSnapshot().contextVersion
    let write = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "触发版本", 6301, 0)
    @Assert(write.applied, true)
    // The window's scene version is derived from this owner version, so a card
    // change must move it without any structure submission.
    @Assert(domain.formSnapshot().contextVersion > before, true)
}

@Test
func presetCardLockBlocksWritesAndProjection(): Unit {
    let domain = PrintPresetDomain()
    // Lock through the SAME declared action, targeted at this card's owner.
    let lock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(true))
        ])))
    @Assert(lock.applied, true)
    let card = domain.cards.card("cardA").getOrThrow()
    // The projection and the write path publish/refuse with the SAME reason.
    let availability = card.fieldAvailability("jobName")
    @Assert(availability.known, true)
    @Assert(availability.isAvailable, false)
    @Assert(availability.reason, "卡片已锁定，暂不可编辑")
    @Assert(card.actionAvailability("APPLY_DRAFT").isAvailable, false)
    let refused = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "锁定写入", 6301, 0)
    @Assert(refused.applied, false)
    @Assert(refused.reason, "卡片已锁定，暂不可编辑")
    @Assert(card.draftText("jobName"), "资料 A")
    // Unlock restores both the projection and the write path.
    let unlock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(false))
        ])))
    @Assert(unlock.applied, true)
    @Assert(card.fieldAvailability("jobName").isAvailable, true)
    let accepted = cardTextAction(domain, "EDIT_DRAFT_TEXT", "jobName", "解锁写入", 6301,
        card.draftVersionValue())
    @Assert(accepted.applied, true)
    @Assert(accepted.reason, "none")
    @Assert(card.draftText("jobName"), "解锁写入")
}

@Test
func handwrittenPresetLockBlocksWrites(): Unit {
    let domain = PrintPresetDomain()
    let lock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", PrintPresetDomain.ownerId,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(true))
        ])))
    @Assert(lock.applied, true)
    @Assert(domain.lockReason(), "预设已锁定，暂不可编辑")
    let refused = domain.editTextFromHuman(6201, "锁定写入", 0, 0)
    @Assert(refused.applied, false)
    @Assert(refused.reason, "预设已锁定，暂不可编辑")
    let unlock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", PrintPresetDomain.ownerId,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(false))
        ])))
    @Assert(unlock.applied, true)
    let accepted = domain.editTextFromHuman(6201, "解锁写入", 0, 0)
    @Assert(accepted.applied, true)
}

// ---------------------------------------------------------------------------
// Readable card + honest editability
//
// The card is an ORDINARY generated scene: its title/note/labels are declared
// children (framework identities with a named style), and its errors, lock
// reason and business state are projection elements of the ONE frozen card
// snapshot. These tests pin the two review findings: the owner's blocking answer
// must reach the actual TEXT control (not only the integer/boolean ones), and a
// theme change must repaint the already accepted card without a resubmit.
// ---------------------------------------------------------------------------

private func cardTestCommit(holder: CjguiGeneratedUiStructureHolder,
    provider: CjguiGeneratedUiBindingProvider): Bool {
    if (!holder.beginCandidateRefresh()) { return false }
    let _ = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        holder.rollbackCandidateRefresh()
        return false
    }
    return holder.commitCandidateRefresh()
}

private func cardTestTextProperties(text: String, style: String): HashMap<String, String> {
    let properties = HashMap<String, String>()
    properties.add("text", text)
    properties.add("style", style)
    properties.add("growX", "1")
    properties.add("textMaxLines", "2")
    properties.add("textOverflow", "ellipsis")
    return properties
}

private func cardTestStructure(): CjguiGeneratedUiNodeSpec {
    let cards = ArrayList<CjguiGeneratedUiNodeSpec>()
    for (key in ["cardA", "cardB"]) {
        let title = if (key == "cardA") { "卡片 A" } else { "卡片 B" }
        let properties = HashMap<String, String>()
        properties.add("title", title)
        let children = ArrayList<CjguiGeneratedUiNodeSpec>()
        children.add(CjguiGeneratedUiNodeSpec("${key}-title", "label",
            properties: cardTestTextProperties(title, "preset-card-title")))
        children.add(CjguiGeneratedUiNodeSpec("${key}-note", "label",
            properties: cardTestTextProperties("编辑后点击应用；锁定/错误由业务对象决定", "preset-card-note")))
        for (field in ["jobName", "copies", "duplex"]) {
            children.add(CjguiGeneratedUiNodeSpec("${key}-${field}-label", "label",
                properties: cardTestTextProperties(field, "preset-card-field-label")))
        }
        cards.add(CjguiGeneratedUiNodeSpec(key, "presetCard", properties: properties, children: children))
    }
    return CjguiGeneratedUiNodeSpec("preset-layout", "vertical", children: cards)
}

private func cardTestFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) { return Some(node) }
    for (child in node.children()) {
        if (let Some(hit) <- cardTestFind(child, nodeId)) { return Some(hit) }
    }
    return None
}

private func cardTestBinding(holder: CjguiGeneratedUiStructureHolder, key: String,
    elementKey: String): CjguiCompositeElementBinding {
    for (binding in holder.compositeElementNodeIdsForKey(key)) {
        if (binding.elementKey == elementKey) { return binding }
    }
    return CjguiCompositeElementBinding("", "", -1, "", "")
}

@Test
func presetCardReadableProjectionAndEditabilityFollowTheOwner(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let catalog = form.capabilityCatalog(maxNodes: 96)
    let appearance = MixedAppearance()
    appearance.light = true
    var theme = mixedFormTheme(appearance.light)
    // The factory captures the appearance the CONTROLLER holds, not this local:
    // the theme is swapped by mutating that object, exactly like the window does.
    @Assert(registerPresetCardComposite(catalog, { => mixedFormTheme(appearance.light) }), true)
    @Assert(syncPresetCardNamedStyles(catalog, theme), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    // Mirror the window's REAL provider: the default form is only the fallback;
    // cardA/cardB are routed through the multi-object binding, so per-card lock
    // and availability (not the 6200 form) are what the generated card sees.
    let fallback = MixedPresetProvider(form, domain.cards, domain)
    let provider = CjguiGeneratedUiMultiObjectBinding(
        fallback,
        { key => key.size > 0 && key.startsWith("card") },
        { key => presetCardObjectBinding(domain.cards, key) },
        ownerBlockedReason: { => domain.lockReason() })
    let submitted = holder.submit(cardTestStructure(), provider)
    @Assert(submitted.candidateAccepted, true)
    @Assert(cardTestCommit(holder, provider), true)
    let version = holder.structureVersion()
    let built = holder.buildAccepted(provider)

    // The readable title is an ordinary declared child with the theme's heading
    // paint, and it is really mounted in the card.
    let titleNodeId = holder.nodeIdForKey("cardA-title")
    @Assert(titleNodeId > 0, true)
    let titleNode = cardTestFind(built, titleNodeId).getOrThrow()
    @Assert(titleNode.value, "卡片 A")
    @Assert(titleNode.style.textColor.red, theme.heading.textColor.red)
    @Assert(titleNode.style.textColor.green, theme.heading.textColor.green)
    // The card surface comes from the same theme.
    let rootBinding = cardTestBinding(holder, "cardA", "root")
    let cardNode = cardTestFind(built, rootBinding.nodeId).getOrThrow()
    @Assert(cardNode.style.background.red, theme.card.background.red)
    // A clean, editable card publishes its business state, not an invented one.
    // A clean owner itself refuses CANCEL (nothing to restore). The generated
    // action projection is covered by the action tests; this check stays on the
    // owner fact.
    @Assert(domain.cards.card("cardA").getOrThrow().actionAvailability("CANCEL_DRAFT").isAvailable, false)
    @Assert(cardTestBinding(holder, "cardA", "cardReason").projectionText, "")
    @Assert(cardTestBinding(holder, "cardA", "nameError").projectionText, "")

    // Lock THIS card through the shared action. The visible TEXT control must
    // stop looking editable, exactly like the integer and boolean controls, and
    // the owner's reason must appear as text - all without a structure resubmit.
    let lock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(true))
        ])))
    @Assert(lock.applied, true)
    let locked = holder.buildAccepted(provider)
    let nameBinding = cardTestBinding(holder, "cardA", "name")
    @Assert(nameBinding.ownerAvailable, false)
    let nameNode = cardTestFind(locked, nameBinding.nodeId).getOrThrow()
    @Assert(nameNode.isEnabled, false)
    @Assert(cardTestFind(locked, cardTestBinding(holder, "cardA", "copies").nodeId).getOrThrow().isEnabled,
        false)
    @Assert(cardTestFind(locked, cardTestBinding(holder, "cardA", "duplex").nodeId).getOrThrow().isEnabled,
        false)
    @Assert(cardTestBinding(holder, "cardA", "cardReason").projectionText, "卡片已锁定，暂不可编辑")
    // Card B is untouched by A's lock.
    @Assert(cardTestFind(locked, cardTestBinding(holder, "cardB", "name").nodeId).getOrThrow().isEnabled, true)
    @Assert(holder.structureVersion(), version)

    // Unlock, then make the card invalid through an external write: the owner's
    // per-field error appears at the same stable identity, and Apply is disabled.
    let unlock = domain.executeFromHuman(cardCall(domain, "SET_LOCK", 6301,
        ArrayList<CjguiSharedOperationActionArgument>([
            CjguiSharedOperationActionArgument("locked", CjguiSharedOperationValue.boolean(false))
        ])))
    @Assert(unlock.applied, true)
    let invalidWrite = cardTextAction(domain, "EDIT_DRAFT_TEXT", "copies", "99", 6301, 0)
    @Assert(invalidWrite.applied, true)
    let invalid = holder.buildAccepted(provider)
    @Assert(cardTestBinding(holder, "cardA", "copiesError").projectionText, "份数需在 1–24 之间")
    @Assert(cardTestBinding(holder, "cardA", "apply").actionEnabled, false)
    @Assert(cardTestFind(invalid, cardTestBinding(holder, "cardA", "copies").nodeId).getOrThrow().isEnabled,
        true)
    @Assert(holder.structureVersion(), version)

    // Theme change: the named styles and the card factory read the SAME theme on
    // the next build, so the accepted card repaints without resubmitting.
    appearance.light = true
    theme = mixedFormTheme(appearance.light)
    @Assert(syncPresetCardNamedStyles(catalog, theme), true)
    let repainted = holder.buildAccepted(provider)
    let repaintedTitle = cardTestFind(repainted, titleNodeId).getOrThrow()
    @Assert(repaintedTitle.style.textColor.red, theme.heading.textColor.red)
    @Assert(repaintedTitle.style.textColor.green, theme.heading.textColor.green)
    let repaintedCard = cardTestFind(repainted, rootBinding.nodeId).getOrThrow()
    @Assert(repaintedCard.style.background.red, theme.card.background.red)
    @Assert(repaintedCard.style.background.green, theme.card.background.green)
    @Assert(holder.structureVersion(), version)
}

// ---------------------------------------------------------------------------
// Owner-side range transaction on a card
//
// The framework's owned range session forwards itself to these five entry
// points; the card owns the version, the lock refusal and the selection mapping.
// What is pinned here: one atomic write per version, a named conflict when the
// version moved, the SAME lock reason the projection publishes, and a selection
// mapping that refuses instead of guessing.
// ---------------------------------------------------------------------------

@Test
func presetCardRangeTransactionIsAtomicAndLocked(): Unit {
    let domain = PrintPresetDomain()
    let cardA = domain.cards.card("cardA").getOrThrow()
    let cardB = domain.cards.card("cardB").getOrThrow()
    @Assert(cardA.rangeTextEditSupported("jobName"), true)
    @Assert(cardA.rangeTextEditSupported("copies"), false)
    @Assert(cardA.textVersion("copies"), -1)
    let versionA = cardA.textVersion("jobName")
    // A stale base version is a named conflict, not a silent write.
    let conflict = cardA.applyTextEdit("jobName", versionA + 7, "错版本")
    @Assert(conflict.applied, false)
    @Assert(conflict.isVersionConflict, true)
    @Assert(cardA.draftText("jobName"), "资料 A")
    // One accepted write advances exactly this card's field version.
    let applied = cardA.applyTextEdit("jobName", versionA, "资料 A2")
    @Assert(applied.applied, true)
    @Assert(applied.versionBefore, versionA)
    @Assert(applied.versionAfter, versionA + 1)
    @Assert(cardA.draftText("jobName"), "资料 A2")
    @Assert(cardB.textVersion("jobName"), 0)
    @Assert(cardB.draftText("jobName"), "资料 B")
    // The card's own selection mapping keeps a legal byte range on the SAME body.
    let sameBody = cardA.rebaseTextSelection("jobName", cardA.textVersion("jobName"), 0, 6)
    @Assert(sameBody.isSome(), true)
    // A whole-value write from another surface moves the body: the selection maps
    // to the end (there is no interior position the owner ever published), and a
    // version the owner never had is refused.
    let externalBefore = cardA.textVersion("jobName")
    @Assert(cardA.setText("jobName", "整体改写"), true)
    let mapped = match (cardA.rebaseTextSelection("jobName", externalBefore, 0, 6)) {
        case Some(value) => value
        case None => (-1, -1, -1)
    }
    let expectedEnd = Int64("整体改写".toArray().size)
    @Assert(mapped[0], cardA.textVersion("jobName"))
    @Assert(mapped[1], expectedEnd)
    @Assert(mapped[2], expectedEnd)
    let unknown = cardA.rebaseTextSelection("jobName", 99, 0, 2)
    @Assert(unknown.isNone(), true)
    // Locking refuses with the SAME reason the projection publishes.
    cardA.setLocked(true)
    let refused = cardA.applyTextEdit("jobName", cardA.textVersion("jobName"), "锁定写入")
    @Assert(refused.applied, false)
    @Assert(refused.reason, "卡片已锁定，暂不可编辑")
    @Assert(cardA.draftText("jobName"), "整体改写")
    cardA.setLocked(false)
    let resumed = cardA.applyTextEdit("jobName", cardA.textVersion("jobName"), "解锁写入")
    @Assert(resumed.applied, true)
}

/// The LEGACY single-owner range entries (empty instance key) must answer with
/// the handwritten form's real contract: capability, version, CAS, confirm and
/// rebase all come from the same CjguiGeneratedUiFormBinding the manual preset
/// area edits. Before this delegation an empty-instance probe was answered by
/// the interface defaults (unsupported / -1), so the primary owner 6200 could
/// not use an owned range session at all.
@Test
func mixedPresetProviderDelegatesLegacyRangeEntriesToOneOwnerForm(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let provider = MixedPresetProvider(form, domain.cards, domain)
    // Every declared TEXT field is range-capable, every non-text field is not.
    @Assert(provider.rangeTextEditSupported("jobName"), true)
    @Assert(provider.rangeTextEditSupported("copies"), false)
    @Assert(provider.fieldTextVersion("jobName"), form.fieldTextVersion("jobName"))
    @Assert(provider.fieldTextVersion("copies"), -1)
    // CAS through the delegated entry: stale version is a named conflict.
    let version = provider.fieldTextVersion("jobName")
    let stale = provider.applyTextEdit("jobName", version + 5, "错版本")
    @Assert(stale.applied, false)
    @Assert(stale.isVersionConflict, true)
    @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText != "错版本", true)
    // One accepted write advances the SAME field version the form publishes.
    let applied = provider.applyTextEdit("jobName", version, "手写范围新值")
    @Assert(applied.applied, true)
    @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "手写范围新值")
    @Assert(provider.fieldTextVersion("jobName"), form.fieldTextVersion("jobName"))
    // Confirm is the same serialized version check.
    let confirmed = provider.confirmFieldTextVersion("jobName", provider.fieldTextVersion("jobName"), { => true })
    @Assert(confirmed, true)
    @Assert(provider.confirmFieldTextVersion("jobName", provider.fieldTextVersion("jobName") + 3, { => true }), false)
    // Rebase maps a legal range on the SAME body through the form's own rule.
    let current = provider.fieldTextVersion("jobName")
    let rebased = provider.rebaseFieldTextSelection("jobName", current, 0, 6)
    @Assert(rebased.isSome(), true)
    // A CARD key never falls through to the handwritten owner: unknown and
    // retired cards are refused by name on the instance-aware entries.
    @Assert(provider.rangeTextEditSupported("jobName", "cardZZ"), false)
    @Assert(provider.fieldTextVersion("jobName", "cardZZ"), -1)
    @Assert(provider.applyTextEdit("jobName", 0, "幽灵", "cardZZ").reason, "unknown_instance")
    @Assert(provider.confirmFieldTextVersion("jobName", 0, { => true }, "cardZZ"), false)
    @Assert(provider.rebaseFieldTextSelection("jobName", 0, 0, 1, "cardZZ").isNone(), true)
    // Retire a real card and prove its key is refused, not redirected to 6200.
    @Assert(domain.cards.deleteCard("cardB"), true)
    @Assert(provider.applyTextEdit("jobName", 0, "幽灵", "cardB").reason, "unknown_instance")
    @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "手写范围新值")
}

@Test
func mixedPresetCardBridgeMapsUnprimedRangeAfterExternalWholeValue(): Unit {
    let domain = PrintPresetDomain()
    let form = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let provider = MixedPresetProvider(form, domain.cards, domain)
    let bridge = CjguiGeneratedFieldRangeSession(provider, "jobName", instanceKey: "cardB", ownerTarget: 6302)
    let session = CjguiTextSession(CjguiRangeTextWindow(810004, "cardB", bridge, bridge))
    session.bind()
    session.setSelection16(4, 4)
    let edit = session.replaceRange16(4, 4, "G")
    @Assert(edit.accepted, true)
    if (edit.ticket >= 0) { let _ = session.acknowledge(edit.ticket, edit.contextEpoch) }
    @Assert(session.mirrorText(), "资料 BG")
    // No rebase query primes history before the external write. This is the
    // normal input/owner sequence, including a modal between the two writes.
    @Assert(domain.cards.card("cardB").getOrThrow().setText("jobName", "卡片é👩🏽‍💻"), true)
    let _ = session.refreshMirrorForAcceptedScene("卡片é👩🏽‍💻")
    let mirror = session.mirrorSnapshot()
    // The mapping is prepared for native installation, not already installed.
    // Use its existing semantic ticket rather than the input-authorized range.
    let selected = session.sourceRangeForSelectionTicket(session.freezeSelectionTicket())
    getStdOut().writeln("MIXED_CARD_SELECTION mirror=${mirror.contentVersion} source=${mirror.sourceVersion} " +
        "selection=${selected.isSome()} calibration=${session.awaitingCalibration()}")
    getStdOut().flush()
    @Assert(mirror.contentVersion, 2)
    @Assert(mirror.sourceVersion, 2)
    @Assert(session.needsNativeSelectionRestore(), true)
    @Assert(session.selectedSourceRange().isNone(), true)
    @Assert(selected.isSome(), true)
    if (let Some(range) <- selected) {
        @Assert(range[0], 2)
        @Assert(range[1], 23)
        @Assert(range[2], 23)
    }
    @Assert(domain.formSnapshot().fieldForResourceId(6201).draftText, "资料")
}

/// The range-session owner facts the region entry now checks: the SAME
/// declared fieldId resolves to DIFFERENT owners by instance. The old wiring
/// bound the DEFAULT instance's provider (root form owner 6200) against a
/// handwritten card node whose accepted target is the CARD owner 6301, and
/// the mismatched session then rejected every delta as owner_target_retired
/// while suppressing the node's ordinary writer. The region entry compares
/// the RESOLVED provider owner with the node's frozen target before building
/// any owned session; this pins the three resolutions it relies on.
@Test
func rangeProviderOwnerFollowsInstanceNotGlobalFieldId(): Unit {
    let domain = PrintPresetDomain()
    let formBinding = CjguiGeneratedUiFormBinding(domain, PrintPresetDomain.ownerId)
    let cardObjects = domain.cards
    let fallback = MixedPresetProvider(formBinding, cardObjects, domain)
    let multiObject = CjguiGeneratedUiMultiObjectBinding(
        fallback,
        { key => key.size > 0 && key.startsWith("card") },
        { key => presetCardObjectBinding(cardObjects, key) },
        ownerBlockedReason: { => domain.lockReason() })
    // DEFAULT instance (legal empty instanceKey): the root form owner.
    @Assert(multiObject.fieldOperationResourceId("jobName", ""), PrintPresetDomain.ownerId)
    @Assert(multiObject.fieldOperationResourceId("jobName", ""), 6200)
    // The CARD instance on the same fieldId: its own owner.
    @Assert(multiObject.fieldOperationResourceId("jobName", "cardA"), 6301)
    @Assert(multiObject.fieldOperationResourceId("jobName", "cardB"), 6302)
    // An unknown instance resolves to NO owner; the region check skips it.
    @Assert(multiObject.fieldOperationResourceId("jobName", "nosuch"), -1)
    @Assert(multiObject.rangeTextEditSupported("jobName", "cardA"), true)
}

/// The handwritten-alias seam the mixed consumer uses to point its selected
/// card's HANDWRITTEN editors at the card instance: declare/refresh/clear on
/// the real holder, with no accepted composite involved (an accepted element
/// always wins over the alias for its own nodes).
@Test
func handwrittenInstanceAliasNamesInstanceForRangeBinding(): Unit {
    let holder = CjguiGeneratedUiStructureHolder(CjguiGeneratedUiCapabilityCatalog())
    @Assert(holder.compositeInstanceKeyForNodeId(910), "")
    holder.declareHandwrittenInstanceAlias(910, "cardA")
    @Assert(holder.compositeInstanceKeyForNodeId(910), "cardA")
    // Re-declaration follows the consumer's selection change.
    holder.declareHandwrittenInstanceAlias(910, "cardB")
    @Assert(holder.compositeInstanceKeyForNodeId(910), "cardB")
    holder.clearHandwrittenInstanceAliases()
    @Assert(holder.compositeInstanceKeyForNodeId(910), "")
}
