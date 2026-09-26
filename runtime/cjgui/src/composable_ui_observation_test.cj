// Observation-seam tests (package B3/B4): one atomic snapshot and one bounded
// change cursor over the SAME source.
//
// What is pinned here:
//   * a draft-only change, a rebind, a resize and an interaction change each
//     produce their own cursor even when the structure version is unchanged;
//   * a structure change reports STRUCTURE + INSTANCES + SCENE together;
//   * the first sample is a baseline (the accompanying snapshot is the state);
//   * a truncated history, a cursor from the future and a replaced endpoint all
//     ask for RESYNC_REQUIRED instead of a fabricated increment;
//   * the snapshot carries the separated owner/scene facts and prefixes every
//     section line, so one response can be sliced without a second framing.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private func observationSource(endpoint: String, owner: Int64, draft: Int64, binding: Int64,
                              structure: Int64, candidateToken: Int64, candidateState: String,
                              scene: Int64, geometry: Int64, interaction: Int64,
                              instances: Int64, pendingScene!: Bool = false,
                              resourceRevision!: Int64 = 0,
                              structurePending!: Bool = false,
                              styleRevision!: Int64 = 0):
    CjguiGeneratedUiObservationSource {
    return CjguiGeneratedUiObservationSource(endpoint, owner, draft, binding, structure,
        candidateToken, candidateState, scene, geometry, interaction, instances, pendingScene,
        resourceRevision: resourceRevision, structureCandidatePending: structurePending,
        styleRevision: styleRevision)
}

@Test
func generatedObservationTracksEachSourceIndependently(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker(historyLimit: 8)
    let baseline = observationSource("session-1", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4)
    @Assert(tracker.observeSource(baseline), 0)
    @Assert(tracker.currentCursor(), 0)
    // The epoch identifies one endpoint instance; only its positivity is
    // guaranteed (a restarted endpoint must not reuse it).
    @Assert(tracker.streamEpoch() > 0, true)

    // A draft-only edit: FIELDS, and NOT a structure change.
    @Assert(tracker.observeSource(observationSource("session-1", 1, 1, 10, 1, 0, "scene_accepted",
        5, 100, 7, 4)), 1)
    let draftOnly = tracker.changesPayload(tracker.streamEpoch(), 0)
    @Assert(draftOnly.contains("CHANGE 1 FIELDS"), true)
    @Assert(draftOnly.contains("STRUCTURE"), false)
    @Assert(draftOnly.contains("SCENE"), false)

    // A rebind: BINDINGS, structure version untouched.
    @Assert(tracker.observeSource(observationSource("session-1", 1, 1, 11, 1, 0, "scene_accepted",
        5, 100, 7, 4)), 2)
    @Assert(tracker.changesPayload(tracker.streamEpoch(), 1).contains("CHANGE 2 BINDINGS"), true)

    // A resize: SCENE (geometry), structure and bindings untouched.
    let resized = tracker.observeSource(observationSource("session-1", 1, 1, 11, 1, 0,
        "scene_accepted", 5, 101, 7, 4))
    @Assert(resized, 3)
    let resizeChanges = tracker.changesPayload(tracker.streamEpoch(), 2)
    @Assert(resizeChanges.contains("CHANGE 3 SCENE"), true)
    @Assert(resizeChanges.contains("STRUCTURE"), false)
    @Assert(resizeChanges.contains("FIELDS"), false)

    // An interaction (focus/selection) change: SCENE.
    @Assert(tracker.observeSource(observationSource("session-1", 1, 1, 11, 1, 0, "scene_accepted",
        5, 101, 8, 4)), 4)

    // A structure change with a business write re-creates instances and the
    // scene, and reports the field revision, in the same sample.
    @Assert(tracker.observeSource(observationSource("session-1", 2, 1, 11, 2, 0,
        "scene_accepted", 6, 101, 8, 5)), 8)
    let structureChanges = tracker.changesPayload(tracker.streamEpoch(), 4)
    @Assert(structureChanges.contains("CHANGE 5 STRUCTURE"), true)
    @Assert(structureChanges.contains("CHANGE 6 FIELDS"), true)
    @Assert(structureChanges.contains("CHANGE 7 INSTANCES"), true)
    @Assert(structureChanges.contains("CHANGE 8 SCENE"), true)

    // A candidate that is waiting for the scene: CANDIDATE only (the business
    // and draft revisions did not move).
    @Assert(tracker.observeSource(observationSource("session-1", 2, 1, 11, 2, 5,
        "scene_pending", 6, 101, 8, 5, pendingScene: true)), 9)
    @Assert(tracker.changesPayload(tracker.streamEpoch(), 8).contains("CHANGE 9 CANDIDATE"), true)

    // No change at all: the cursor does not move and the increment is empty.
    @Assert(tracker.observeSource(observationSource("session-1", 2, 1, 11, 2, 5,
        "scene_pending", 6, 101, 8, 5, pendingScene: true)), 9)
    let noChange = tracker.changesPayload(tracker.streamEpoch(), 9)
    @Assert(noChange.contains("CURRENT 9"), true)
    @Assert(noChange.contains("RESYNC_REQUIRED 0"), true)
    @Assert(noChange.contains("CHANGE "), false)
}

@Test
func generatedObservationAsksForResyncWhenContinuityIsNotProvable(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker(historyLimit: 2)
    let _ = tracker.observeSource(observationSource("session-1", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4))
    // Three distinct changes against a two-entry history: the oldest cursor is
    // no longer retained, so a reader behind the floor must resync.
    let _ = tracker.observeSource(observationSource("session-1", 1, 1, 10, 1, 0, "scene_accepted", 5, 100, 7, 4))
    let _ = tracker.observeSource(observationSource("session-1", 1, 1, 11, 1, 0, "scene_accepted", 5, 100, 7, 4))
    let _ = tracker.observeSource(observationSource("session-1", 1, 1, 11, 1, 0, "scene_accepted", 5, 101, 7, 4))
    @Assert(tracker.currentCursor(), 3)
    @Assert(tracker.historyFloor() > 0, true)
    @Assert(tracker.resyncRequired(tracker.streamEpoch(), 0), true)
    let truncated = tracker.changesPayload(tracker.streamEpoch(), 0)
    @Assert(truncated.contains("RESYNC_REQUIRED 1"), true)
    @Assert(truncated.contains("CHANGE "), false)

    // A cursor from the future is not a valid increment either.
    @Assert(tracker.resyncRequired(tracker.streamEpoch(), 99), true)

    // A replaced endpoint starts a new stream epoch: the old history must not be
    // replayed as if it belonged to the new one.
    let epochBefore = tracker.streamEpoch()
    let _ = tracker.observeSource(observationSource("session-2", 9, 0, 0, 3, 0, "scene_accepted", 1, 5, 1, 3))
    @Assert(tracker.streamEpoch() > epochBefore, true)
    @Assert(tracker.streamIdentity(), "session-2")
    let replaced = tracker.changesPayload(epochBefore, tracker.currentCursor())
    @Assert(replaced.contains("RESYNC_REQUIRED 1"), true)
    @Assert(replaced.contains("CHANGE "), false)
}

@Test
func generatedSnapshotCarriesOwnerAndSceneFactsInOnePayload(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker()
    let source = observationSource("session-9", 12, 3, 21, 4, 0, "scene_accepted", 44, 55, 66, 77)
    let _ = tracker.observeSource(source)
    let payload = cjguiGeneratedUiSnapshotPayload(tracker, source,
        "FIELD label 81001 DRAFT_HEX 41 VERSION 3\nEND",
        "GENERATED_UI_STRUCTURE 1\nNODE 0 root vertical\nEND",
        "INSTANCE edit element=root role=field id=812001 kind=textInput")
    // The owner and the scene stay separate facts.
    @Assert(payload.contains("OWNER_FIELD_REVISION 12"), true)
    @Assert(payload.contains("OWNER_DRAFT_REVISION 3"), true)
    @Assert(payload.contains("BINDING_REVISION 21"), true)
    @Assert(payload.contains("ACCEPTED_STRUCTURE_VERSION 4"), true)
    @Assert(payload.contains("WINDOW_ACCEPTED_SCENE_VERSION 44"), true)
    @Assert(payload.contains("WINDOW_GEOMETRY_REVISION 55"), true)
    @Assert(payload.contains("WINDOW_INTERACTION_REVISION 66"), true)
    @Assert(payload.contains("INSTANCE_REVISION 77"), true)
    @Assert(payload.contains("OWNER_PENDING_SCENE 0"), true)
    @Assert(payload.contains("CURSOR 0"), true)
    @Assert(payload.contains("STREAM_IDENTITY session-9"), true)
    // Every section line is prefixed, so the client can slice one response.
    @Assert(payload.contains("SNAPSHOT_FIELD FIELD label 81001"), true)
    @Assert(payload.contains("SNAPSHOT_STRUCTURE NODE 0 root vertical"), true)
    @Assert(payload.contains("SNAPSHOT_INSTANCE INSTANCE edit element=root"), true)
    @Assert(payload.endsWith("END"), true)
    // An owner write that the scene has not shown yet is reported as pending.
    let pending = observationSource("session-9", 13, 3, 21, 4, 6, "scene_pending", 44, 55, 66, 77, pendingScene: true)
    let _ = tracker.observeSource(pending)
    let pendingPayload = cjguiGeneratedUiSnapshotPayload(tracker, pending, "", "", "")
    @Assert(pendingPayload.contains("OWNER_PENDING_SCENE 1"), true)
    // The pending sample moved both the candidate state and the owner revision.
    @Assert(pendingPayload.contains("CURSOR 2"), true)
}

/// A section read is guarded by the cursor the caller's snapshot belongs to: a
/// moved cursor publishes NO section content, so a caller can never stitch an
/// unguarded fields/instances response into an older state.
@Test
func generatedObservationSectionReadIsGuardedByItsCursor(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker()
    let source = observationSource("session-7", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4)
    @Assert(tracker.observeSource(source), 0)

    // The requested cursor matches: exactly that section is published.
    let fields = cjguiGeneratedUiSectionPayload(tracker, "FIELDS", 0,
        "FIELD label 81001 DRAFT_HEX 41 VERSION 3\nEND")
    @Assert(fields.contains("SECTION FIELDS"), true)
    @Assert(fields.contains("STREAM_EPOCH "), true)
    @Assert(fields.contains("CURSOR 0"), true)
    @Assert(fields.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    @Assert(fields.contains("SNAPSHOT_FIELD FIELD label 81001"), true)
    @Assert(fields.contains("SNAPSHOT_STRUCTURE"), false)
    @Assert(fields.contains("SNAPSHOT_INSTANCE"), false)

    let instances = cjguiGeneratedUiSectionPayload(tracker, "INSTANCES", 0, "INSTANCE edit id=812001")
    @Assert(instances.contains("SECTION INSTANCES"), true)
    @Assert(instances.contains("SNAPSHOT_INSTANCE INSTANCE edit id=812001"), true)
    @Assert(instances.contains("SNAPSHOT_FIELD"), false)

    // Anything moved: the section is NOT published, only the revision flag.
    let _ = tracker.observeSource(observationSource("session-7", 1, 1, 10, 1, 0, "scene_accepted", 5, 100, 7, 4))
    let stale = cjguiGeneratedUiSectionPayload(tracker, "FIELDS", 0,
        "FIELD label 81001 DRAFT_HEX 41 VERSION 3\nEND")
    @Assert(stale.contains("CURSOR 1"), true)
    @Assert(stale.contains("SNAPSHOT_REVISION_CHANGED 1"), true)
    @Assert(stale.contains("SNAPSHOT_FIELD"), false)
    @Assert(stale.contains("FIELD label"), false)

    // An unknown section is never answered with a different one.
    let unknown = cjguiGeneratedUiSectionPayload(tracker, "SECRETS", 1, "FIELD label 81001")
    @Assert(unknown.contains("SNAPSHOT_REVISION_CHANGED 1"), true)
    @Assert(unknown.contains("FIELD label"), false)
}

/// A resource-declaration change is its own observation category: the accepted
/// instance section is what goes stale, and the snapshot publishes the
/// declaration revision explicitly.
@Test
func generatedObservationTracksResourceDeclarationChanges(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker()
    let baseline = observationSource("session-r", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4)
    @Assert(tracker.observeSource(baseline), 0)
    let payload = cjguiGeneratedUiSnapshotPayload(tracker, baseline, "", "", "")
    @Assert(payload.contains("RESOURCE_REVISION 0"), true)

    let swapped = observationSource("session-r", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4,
        resourceRevision: 99)
    @Assert(tracker.observeSource(swapped), 1)
    let changes = tracker.changesPayload(tracker.streamEpoch(), 0)
    @Assert(changes.contains("CHANGE 1 RESOURCES"), true)
    @Assert(changes.contains("STRUCTURE"), false)
    let after = cjguiGeneratedUiSnapshotPayload(tracker, swapped, "", "", "")
    @Assert(after.contains("RESOURCE_REVISION 99"), true)
    // No other change at all: the revision is stable between samples.
    @Assert(tracker.observeSource(swapped), 1)
}

/// A named-style directory change is observable on its OWN category. A client
/// must learn that style DEFINITIONS need re-reading; folding it into the scene
/// or structure revision would misreport a theme change as a business/structural
/// one, and re-reading only INSTANCES could not discover the new definitions.
@Test
func generatedObservationTracksStyleDirectoryChanges(): Unit {
    let tracker = CjguiGeneratedUiObservationTracker()
    let baseline = observationSource("session-s", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4)
    @Assert(tracker.observeSource(baseline), 0)
    let payload = cjguiGeneratedUiSnapshotPayload(tracker, baseline, "", "", "")
    @Assert(payload.contains("STYLE_REVISION 0"), true)

    // Directory-only change: STYLES and nothing that looks like a business,
    // structure, scene or resource change.
    let restyled = observationSource("session-s", 1, 0, 10, 1, 0, "scene_accepted", 5, 100, 7, 4,
        styleRevision: 42)
    @Assert(tracker.observeSource(restyled), 1)
    let changes = tracker.changesPayload(tracker.streamEpoch(), 0)
    @Assert(changes.contains("CHANGE 1 STYLES revision=42"), true)
    @Assert(changes.contains("STRUCTURE"), false)
    @Assert(changes.contains("SCENE"), false)
    @Assert(changes.contains("FIELDS"), false)
    @Assert(changes.contains("RESOURCES"), false)

    // The fresh snapshot carries the revision AND the definitions, so one
    // response is enough; a client that only wants definitions can re-read the
    // STYLES section alone.
    let after = cjguiGeneratedUiSnapshotPayload(tracker, restyled, "", "", "",
        stylesPayload: "STYLE panel_accent background=#e63333ff")
    @Assert(after.contains("STYLE_REVISION 42"), true)
    @Assert(after.contains("STYLE panel_accent"), true)
    let styles = cjguiGeneratedUiSectionPayload(tracker, "STYLES", 1, "STYLE panel_accent")
    @Assert(styles.contains("SECTION STYLES"), true)
    @Assert(styles.contains("SNAPSHOT_REVISION_CHANGED 0"), true)
    // A stale cursor is refused instead of being answered with another section.
    let stale = cjguiGeneratedUiSectionPayload(tracker, "STYLES", 0, "STYLE panel_accent")
    @Assert(stale.contains("SNAPSHOT_REVISION_CHANGED 1"), true)

    // No further change: the cursor stays where it was.
    @Assert(tracker.observeSource(restyled), 1)
}
