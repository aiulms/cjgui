package cjgui_rule_set_window_app

import cjgui_rule_set_application.*
import std.fs.*
import std.time.*
import std.unittest.*
import std.unittest.testmacro.*

// The controller's frequently requested scene revision must not materialize an
// entire saved document merely to read the owner's version. Compare actual
// shipping calls on the same 1000-record document; no production counters are
// added. This is a relative cost discriminator, not an input-latency gate.
@Test
func rulesSceneVersionDoesNotMaterializeSavedDocument(): Unit {
    let directory = Directory.createTemp("/tmp")
    try {
        let path = directory.join("rules.rules")
        let data = StringBuilder()
        data.append("CJGUI_RULE_SET 2\nNEXT_ID 1001\nSELECTED 1\n")
        for (i in 1..1001) {
            data.append("RECORD ${i} 1 7 52756C65 6361636865 -\n")
        }
        data.append("END\n")
        File.writeTo(path, data.toString().toArray())
        let domain = CjguiRuleSetEditingDomain.newUntitled()
        @Assert(domain.openFromHuman(path.toString()).applied, true)
        let controller = CjguiRuleSetComposableController(domain)
        let oldDomainVersion = domain.snapshot().version
        let oldSceneVersion = controller.uiSceneVersion()
        @Assert(domain.createRecordFromHuman("version change", true, 7, "cache", "version-test").applied, true)
        let newDomainVersion = domain.snapshot().version
        @Assert(controller.uiSceneVersion() - oldSceneVersion, newDomainVersion - oldDomainVersion)
        @Assert(domain.undoFromHuman().applied, true)
        @Assert(controller.uiSceneVersion() - oldSceneVersion, domain.snapshot().version - oldDomainVersion)
        @Assert(domain.redoFromHuman().applied, true)
        @Assert(controller.uiSceneVersion() - oldSceneVersion, domain.snapshot().version - oldDomainVersion)

        var sum: Int64 = 0
        let referenceStart = MonoTime.now()
        for (_ in 0..40) { sum += domain.snapshot().version }
        let referenceNs = (MonoTime.now() - referenceStart).toNanoseconds()
        let queryStart = MonoTime.now()
        for (_ in 0..40) { sum += controller.uiSceneVersion() }
        let queryNs = (MonoTime.now() - queryStart).toNanoseconds()
        println("rules_scene_version_cost snapshot_ns=${referenceNs} query_ns=${queryNs} sum=${sum}")
        @Assert(queryNs * 3 < referenceNs, true)
    } finally {
        let _ = removeIfExists(directory, recursive: true)
    }
}
