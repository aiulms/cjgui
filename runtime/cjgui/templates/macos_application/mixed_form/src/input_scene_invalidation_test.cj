// Scope: this test isolates the controller sceneVersion getter against a real
// independent card-owner write. It does not cover keyboard delivery, generated
// field callbacks, accepted-scene rendering, or continuous GUI input. The former
// GUI fixture is retained at input-exit-performance/input/scene-invalidation-gui-fixture.cj.txt.
package cjgui_mixed_form_starter

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.*
import cjgui_shared_operation_core.*

@Test
func mixedSceneVersionTracksIndependentCardOwnerWrite(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    let card = domain.cards.card("cardA").getOrThrow()

    let beforeDraft = card.draftText("jobName")
    let beforeApplied = card.appliedText("jobName")
    let beforeFieldVersion = card.fieldVersion("jobName")
    let beforeDraftVersion = card.draftVersionValue()
    let beforeAppliedVersion = card.appliedVersionValue()
    let beforeOwnerRevision = card.ownerRevision()
    let beforeSceneVersion = controller.uiSceneVersion()

    @Assert(card.setText("jobName", "owner-only-write"), true)

    @Assert(card.draftText("jobName"), "owner-only-write")
    @Assert(card.draftText("jobName") != beforeDraft, true)
    @Assert(card.appliedText("jobName"), beforeApplied)
    @Assert(card.fieldVersion("jobName"), beforeFieldVersion + 1)
    @Assert(card.draftVersionValue(), beforeDraftVersion + 1)
    @Assert(card.appliedVersionValue(), beforeAppliedVersion)
    @Assert(card.ownerRevision(), beforeOwnerRevision + 1)
    @Assert(controller.uiSceneVersion() > beforeSceneVersion, true)
}

@Test
func mixedSceneVersionRemainsMonotonicAcrossCardLifecycle(): Unit {
    let domain = PrintPresetDomain()
    let controller = MixedFormController(domain)
    let card = domain.cards.card("cardA").getOrThrow()
    let baseline = domain.cards.workSessionPayload()
    var version = controller.uiSceneVersion()
    // Idempotent delivery does not invent an owner or projection change.
    @Assert(card.setText("jobName", card.draftText("jobName")), true)
    @Assert(controller.uiSceneVersion(), version)
    @Assert(card.setText("jobName", "first"), true)
    @Assert(controller.uiSceneVersion() > version, true)
    version = controller.uiSceneVersion()
    @Assert(card.apply()[0], true)
    @Assert(card.appliedText("jobName"), "first")
    @Assert(controller.uiSceneVersion() > version, true)
    version = controller.uiSceneVersion()
    @Assert(card.setText("jobName", "second"), true)
    version = controller.uiSceneVersion()
    @Assert(card.cancel()[0], true)
    @Assert(card.draftText("jobName"), "first")
    @Assert(controller.uiSceneVersion() > version, true)

    let defaults = ArrayList<CjguiSharedOperationValue>([
        CjguiSharedOperationValue.string("temporary"),
        CjguiSharedOperationValue.integer(1),
        CjguiSharedOperationValue.boolean(false)])
    version = controller.uiSceneVersion()
    let key = domain.cards.addCard("temporary", defaults).getOrThrow()
    @Assert(controller.uiSceneVersion() > version, true)
    let temporary = domain.cards.card(key).getOrThrow()
    @Assert(temporary.setText("jobName", "changed once"), true)
    @Assert(temporary.setText("jobName", "changed twice"), true)
    version = controller.uiSceneVersion()
    @Assert(domain.cards.deleteCard(key), true)
    @Assert(controller.uiSceneVersion() > version, true)
    @Assert(domain.cards.containsKey(key), false)

    version = controller.uiSceneVersion()
    @Assert(domain.cards.rebind("cardB", 6400, "rebound", defaults), true)
    @Assert(controller.uiSceneVersion() > version, true)
    @Assert(domain.cards.ownerFor("cardB"), 6400)
    // Restore requires original owner identity; restore it through the same
    // real rebind before exercising the real work-session restore path.
    @Assert(domain.cards.rebind("cardB", 6302, "卡片 B", defaults), true)
    version = controller.uiSceneVersion()
    @Assert(domain.cards.restoreWorkSessionPayload(baseline), true)
    @Assert(card.draftText("jobName"), "资料 A")
    @Assert(card.appliedText("jobName"), "资料 A")
    @Assert(controller.uiSceneVersion() > version, true)
}
