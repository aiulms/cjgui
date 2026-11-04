package cjgui

import std.fs.*
import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func workSessionValidator(payload: String): Bool {
    return payload.startsWith("mixed-work-session-v1\n")
}

@Test
func workSessionSavesLoadsDirtyStateAndUsesFreshProcessBinding(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let payload = "mixed-work-session-v1\nownerA=6301\ndraft=先应用再恢复"
    let first = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    @Assert(first.isDirty(payload), true)
    let saved = first.save(payload)
    @Assert(saved.ok, true)
    @Assert(saved.reason, "saved")
    @Assert(first.isDirty(payload), false)

    // A new object models a new process. It restores only the caller's payload
    // and current file baseline, never the previous window or endpoint.
    let second = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    let opened = second.load()
    @Assert(opened.ok, true)
    @Assert(opened.payload, payload)
    @Assert(second.isDirty(payload), false)
    @Assert(second.isDirty("${payload}\nchanged=true"), true)
    let edited = "${payload}\nchanged=true"
    @Assert(second.save(edited).ok, true)
    @Assert(second.isDirty(edited), false)
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func workSessionRefusesCorruptExternalAndWrongSchemaFilesWithoutReplacingThem(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let payload = "mixed-work-session-v1\nownerA=6301"
    let initial = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    @Assert(initial.save(payload).ok, true)

    let wrongSchema = CjguiComposableUiWorkSession(path, "mixed.print-presets.v2", 65536,
        { value => value.startsWith("mixed-work-session-v1\n") })
    let refusedSchema = wrongSchema.load()
    @Assert(refusedSchema.ok, false)
    @Assert(refusedSchema.reason, "work_session_schema")
    let noBaselineOverwrite = wrongSchema.save("mixed-work-session-v1\nreplacement")
    @Assert(noBaselineOverwrite.ok, false)
    @Assert(noBaselineOverwrite.reason, "save_target_exists")

    let reopened = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    @Assert(reopened.load().ok, true)
    File.writeTo(path, "externally modified".toArray())
    let conflict = reopened.save("${payload}\nnew=true")
    @Assert(conflict.ok, false)
    @Assert(conflict.reason, "external_file_conflict")
    @Assert(String.fromUtf8(File.readFrom(path)), "externally modified")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func workSessionRefusesInvalidCallerPayloadAndOversizeFiles(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let session = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 128,
        workSessionValidator)
    let invalid = session.save("unrelated payload")
    @Assert(invalid.ok, false)
    @Assert(invalid.reason, "work_session_payload_refused")
    let longValue = StringBuilder()
    for (_ in 0..256) { longValue.append("x") }
    let tooLarge = session.save("mixed-work-session-v1\n${longValue.toString()}")
    @Assert(tooLarge.ok, false)
    @Assert(tooLarge.reason, "work_session_too_large")
    @Assert(exists(path), false)

    let oversizedExternal = "x" * 256
    File.writeTo(path, oversizedExternal.toArray())
    let load = session.load()
    @Assert(load.ok, false)
    @Assert(load.reason, "payload_too_large")
    @Assert(String.fromUtf8(File.readFrom(path)), oversizedExternal)
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func workSessionLoadUsesOneCompleteValidationResult(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let payload = "mixed-work-session-v1\none validated payload"
    let writer = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    @Assert(writer.save(payload).ok, true)

    let validations = ArrayList<String>()
    let reader = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        { value =>
            validations.add(value)
            workSessionValidator(value)
        })
    let loaded = reader.load()
    @Assert(loaded.ok, true)
    @Assert(validations.size, 1)
    @Assert(loaded.payload, payload)
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func workSessionRejectsBusinessPayloadBeforeTrustingItsFileBaseline(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let invalidForReader = "mixed-work-session-v1\nwrong-owner"
    let writer = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        workSessionValidator)
    @Assert(writer.save(invalidForReader).ok, true)
    let originalFile = String.fromUtf8(File.readFrom(path))

    let reader = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 65536,
        { value => value == "mixed-work-session-v1\ntrusted-owner" })
    let refused = reader.load()
    @Assert(refused.ok, false)
    @Assert(refused.reason, "work_session_payload_refused")
    let overwrite = reader.save("mixed-work-session-v1\ntrusted-owner")
    @Assert(overwrite.ok, false)
    @Assert(overwrite.reason, "save_target_exists")
    @Assert(String.fromUtf8(File.readFrom(path)), originalFile)
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func workSessionEarlyRejectsOversizeBeforeCallingAppValidatorOrWriting(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("work-session.json").toString()
    let validationCalls = ArrayList<String>()
    let session = CjguiComposableUiWorkSession(path, "mixed.print-presets.v1", 128,
        { value =>
            validationCalls.add(value)
            workSessionValidator(value)
        })
    let largePayload = "mixed-work-session-v1\n" + "x" * 90
    @Assert(largePayload.size < 128, true)
    let tooLarge = session.save(largePayload)
    @Assert(tooLarge.ok, false)
    @Assert(tooLarge.reason, "work_session_too_large")
    @Assert(validationCalls.size, 0)
    @Assert(exists(path), false)
    let _ = removeIfExists(directory, recursive: true)
}
