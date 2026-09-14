package cjgui_shared_operation_core

import std.fs.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func textDocumentFileBindingAtomicallySavesReopensAndRefusesAnExternalOverwrite(): Unit {
    let directory = Directory.createTemp("/tmp")
    let documentPath = directory.join("shared-document.txt").toString()
    let binding = CjguiTextDocumentFileBinding()
    let original = CjguiTextDocument(7301, "受控文件", "第一行\n🙂第二行")

    @Assert(binding.saveFromHuman(original.snapshot(), documentPath).applied, true)
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "第一行\n🙂第二行")
    let reopened = binding.openFromHuman(7301, "受控文件", documentPath)
    @Assert(reopened.applied, true)
    if (let Some(document) <- reopened.document) {
        @Assert(document.snapshot().content, "第一行\n🙂第二行")
        @Assert(document.snapshot().version, 0)
    } else {
        @Assert(true, false)
    }

    File.writeTo(Path(documentPath), "外部改写".toArray())
    let conflict = binding.saveFromHuman(original.snapshot(), documentPath)
    @Assert(conflict.applied, false)
    @Assert(conflict.reason, "external_file_conflict")
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "外部改写")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func textDocumentFileBindingCoordinatesInstancesAndNeverClobbersAClaimedNewTarget(): Unit {
    let directory = Directory.createTemp("/tmp")
    let documentPath = directory.join("coordinated-document.txt").toString()
    let lockPath = Path("${documentPath}.cjgui-save-lock")
    let original = CjguiTextDocument(7302, "协调文件", "原始")
    let first = CjguiTextDocumentFileBinding()
    let second = CjguiTextDocumentFileBinding()

    // This lock directory is the cross-process claim. It is created without
    // recursive parents, exactly as another instance would acquire it.
    Directory.create(lockPath, recursive: false)
    let locked = first.saveFromHuman(original.snapshot(), documentPath)
    @Assert(locked.applied, false)
    @Assert(locked.reason, "save_in_progress")
    let _ = removeIfExists(lockPath, recursive: true)

    @Assert(first.saveFromHuman(original.snapshot(), documentPath).applied, true)
    @Assert(second.saveFromHuman(original.snapshot(), documentPath).reason, "save_target_exists")
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "原始")

    @Assert(second.openFromHuman(7302, "协调文件", documentPath).applied, true)
    let newer = CjguiTextDocument(7302, "协调文件", "第一实例")
    @Assert(first.saveFromHuman(newer.snapshot(), documentPath).applied, true)
    let staleSecond = CjguiTextDocument(7302, "协调文件", "第二实例")
    let conflict = second.saveFromHuman(staleSecond.snapshot(), documentPath)
    @Assert(conflict.applied, false)
    @Assert(conflict.reason, "external_file_conflict")
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "第一实例")
    let _ = removeIfExists(directory, recursive: true)
}
