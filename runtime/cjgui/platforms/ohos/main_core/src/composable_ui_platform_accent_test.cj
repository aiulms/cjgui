package cjgui

import std.unittest.*
import std.unittest.testmacro.*
import std.env.*

@Test
func platformAccentLastGoodAndFixedPolicy(): Unit {
    let fact = CjguiComposableUiPlatformAccentTracker()
    @Assert(fact.color().isNone(), true)
    @Assert(fact.observePacked(16777216 + 0x123456), true)
    @Assert(fact.colorToken(), "#123456ff")
    @Assert(fact.readStatus(), "available")
    @Assert(fact.valueRevision(), 1)
    @Assert(fact.observePacked(16777216 + 0x123456), false)
    @Assert(fact.observationRevision(), 1)
    @Assert(fact.observePacked(-1), true)
    @Assert(fact.colorToken(), "#123456ff")
    @Assert(fact.readStatus(), "unavailable")
    @Assert(fact.valueRevision(), 1)
    @Assert(fact.observePacked(-1), false)
    let system = CjguiComposableUiAccentPreference.systemFollow()
    @Assert(system.effectiveSource(fact), "retained_system")
    let fixed = match (CjguiComposableUiAccentPreference.fromToken("#ABCDEF")) {
        case Some(value) => value
        case None => CjguiComposableUiAccentPreference.systemFollow()
    }
    @Assert(fixed.effectiveSource(fact), "fixed")
    if (let Some(color) <- fixed.effectiveColor(fact)) {
        @Assert(cjguiComposableUiColorToken(color), "#abcdefff")
    } else {
        @Assert(false, true)
    }
    @Assert(CjguiComposableUiAccentPreference.fromToken("red").isNone(), true)
}

private class AccentAcceptedController <: CjguiComposableUiController &
    CjguiComposableUiPlatformAccentConsumer & CjguiComposableUiWindowBackgroundProvider {
    var revision: Int64 = 1
    var color: CjguiComposableUiColor = CjguiComposableUiColor(0.2, 0.2, 0.2, 1.0)
    var reject: Bool = false
    var buildCount: Int64 = 0

    public func applyPlatformAccentColor(next: CjguiComposableUiColor, source: String): Bool {
        let _ = source
        color = next
        revision += 1
        return true
    }
    public func candidateWindowBackground(): String {
        return if (reject) { "invalid_material" } else { CjguiWindowBackgroundPolicy.OPAQUE }
    }
    public func uiSceneVersion(): Int64 { return revision }
    public func buildUi(): CjguiComposableUiNode {
        buildCount += 1
        let root = cjguiComposableVertical(1, "accent-root", CjguiComposableUiStyle())
        root.add(cjguiComposableButton(2, "accent-button", "Accent", "PRESS", 0,
            CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 32, border: color, borderWidth: 2)))
        return root
    }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func platformAccentAcceptedPaintRejectRecoverAndIdle(): Unit {
    let owner = AccentAcceptedController()
    let window = CjguiComposableUiWindow(owner)
    @Assert(window.observeAccentPacked(16777216 + 0x204080), true)
    @Assert(window.start(), true)
    let first = window.platformAccentStatus()
    @Assert(first.observedToken, "#204080ff")
    @Assert(first.adoptedToken, "#204080ff")
    @Assert(first.adoptedSource, "system")
    @Assert(first.adoptedSceneVersion, window.windowProgress().acceptedSceneVersion)

    owner.reject = true
    @Assert(window.observeAccentPacked(16777216 + 0x902040), true)
    @Assert(window.refreshIfNeeded(), false)
    let refused = window.platformAccentStatus()
    @Assert(refused.observedToken, "#902040ff")
    @Assert(refused.adoptedToken, "#204080ff")
    @Assert(refused.adoptedSceneVersion, first.adoptedSceneVersion)

    owner.reject = false
    owner.revision += 1
    @Assert(window.refresh(), true)
    let recovered = window.platformAccentStatus()
    @Assert(recovered.adoptedToken, "#902040ff")
    @Assert(recovered.adoptedSceneVersion, window.windowProgress().acceptedSceneVersion)
    @Assert(window.observeAccentPacked(16777216 + 0x902040), false)
    // A stable refreshIfNeeded returns true for an already accepted scene; it
    // must not rebuild or submit when the platform fact remains equal.
    @Assert(window.refreshIfNeeded(), true)
    let stableVersion = window.platformAccentStatus().adoptedSceneVersion
    let stableBuilds = owner.buildCount
    @Assert(window.refreshIfNeeded(), true)
    @Assert(window.platformAccentStatus().adoptedSceneVersion, stableVersion)
    @Assert(owner.buildCount, stableBuilds)

    @Assert(window.selectAccentPreference("#336699"), true)
    @Assert(window.refreshIfNeeded(), true)
    let fixed = window.platformAccentStatus()
    @Assert(fixed.adoptedToken, "#336699ff")
    @Assert(fixed.adoptedSource, "fixed")
    @Assert(window.selectAccentPreference("bogus"), false)
    @Assert(window.platformAccentStatus().adoptedToken, fixed.adoptedToken)
    window.close()
}
