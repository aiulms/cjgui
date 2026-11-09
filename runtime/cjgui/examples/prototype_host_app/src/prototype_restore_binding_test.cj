package cjgui_prototype_host

import std.collection.*
import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

private func prototypeH3ProjectRoot(): String {
    let declaration = """
{"schema":"cjgui.prototype-project.v1","id":"restore-binding","title":"恢复绑定",
 "view":"list","records":{"file":"data/records.json","titleField":"title"},
 "fields":[{"id":"title","label":"标题","kind":"text","sourceField":"title"}]}
"""
    var records = "{\"records\":["
    var index: Int64 = 1
    while (index <= 200) {
        if (index > 1) {
            records += ","
        }
        records += "{\"id\":\"record-${index}\",\"title\":\"original-${index}\"}"
        index += 1
    }
    records += "]}"
    return prototypeTestTempProject(declaration, dataFileName: "data/records.json", dataContent: records)
}

private func prototypeH3Seed(session: PrototypeSession): Unit {
    for (index in [0, 49, 198]) {
        let object = session.domain.objectAt(index)
        @Assert(object.setText("title", "applied-${index}"), true)
        let (applied, _) = object.applyDraft()
        @Assert(applied, true)
        @Assert(object.setText("title", "draft-${index}"), true)
    }
    @Assert(session.domain.selectKey("record-199"), true)
    session.binding.rebind()
}

@Test
func prototypeH3RestoreRebindsActualFieldOwnerAndPreservesAllObjectState(): Unit {
    let root = prototypeH3ProjectRoot()
    let project = PrototypeProjectLoader.load(root)
    let original = PrototypeSession(project, true)
    let restored = PrototypeSession(project, false)
    try {
        prototypeH3Seed(original)
        let payload = prototypeSessionPayload(original)
        @Assert(restored.binding.fieldOperationResourceId("title"), 3000)
        @Assert(prototypeRestoreSessionPayload(restored.domain, payload, restored), true)
        let domainOwner = restored.domain.activeObject().ownerId
        let fieldOwner = restored.binding.fieldOperationResourceId("title")
        let detail = restored.binding.draftText("title")
        println("H3_RESTORE domain=${domainOwner} binding=${fieldOwner} detail=${detail}")
        @Assert(restored.domain.activeObject().ownerId, 3198)
        @Assert(restored.binding.fieldOperationResourceId("title"), restored.domain.activeObject().ownerId)
        @Assert(restored.binding.draftText("title"), "draft-198")
        @Assert(restored.binding.appliedText("title"), "applied-198")
        // Exact serialization covers every object's draft/applied/field and object versions,
        // plus selection/query/columns/theme. Restore must not apply any draft.
        @Assert(prototypeSessionPayload(restored), payload)
        let firstBefore = restored.domain.objectAt(0).draftText("title")
        let otherBefore = restored.domain.objectAt(49).draftText("title")
        let applied = restored.binding.executeAction("APPLY_DRAFT", "h3-apply")
        @Assert(applied.applied, true)
        @Assert(restored.domain.activeObject().appliedText("title"), "draft-198")
        @Assert(restored.domain.objectAt(0).draftText("title"), firstBefore)
        @Assert(restored.domain.objectAt(49).draftText("title"), otherBefore)
    } finally {
        restored.close()
        original.close()
        remove(root, recursive: true)
    }
}

@Test
func prototypeH3RejectedRestoreKeepsOldSelectionDraftsVersionsThemeAndBinding(): Unit {
    let root = prototypeH3ProjectRoot()
    let project = PrototypeProjectLoader.load(root)
    let current = PrototypeSession(project, false)
    let incoming = PrototypeSession(project, true)
    try {
        prototypeH3Seed(current)
        @Assert(current.domain.selectKey("record-50"), true)
        current.binding.rebind()
        @Assert(incoming.domain.objectAt(0).setText("title", "must-not-partially-restore"), true)
        @Assert(incoming.domain.selectKey("record-199"), true)
        let before = prototypeSessionPayload(current)
        let bindingOwner = current.binding.fieldOperationResourceId("title")
        let bindingDraft = current.binding.draftText("title")
        // The final object is invalid; earlier objects contain otherwise valid new state.
        let invalid = prototypeSessionPayload(incoming).replace("\"key\":\"record-200\"",
            "\"key\":\"unknown-record\"")
        @Assert(prototypeRestoreSessionPayload(current.domain, invalid, current), false)
        @Assert(prototypeSessionPayload(current), before)
        @Assert(current.domain.activeObject().ownerId, 3049)
        @Assert(current.binding.fieldOperationResourceId("title"), bindingOwner)
        @Assert(current.binding.draftText("title"), bindingDraft)
        let cancelled = current.binding.executeAction("CANCEL_DRAFT", "h3-cancel")
        @Assert(cancelled.applied, true)
        @Assert(current.domain.objectAt(49).draftText("title"), "applied-49")
        @Assert(current.domain.objectAt(0).draftText("title"), "draft-0")
        @Assert(current.domain.objectAt(198).draftText("title"), "draft-198")
    } finally {
        current.close()
        incoming.close()
        remove(root, recursive: true)
    }
}
