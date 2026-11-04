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

@Test
func textDocumentFileBindingDoesNotTrustAnApplicationRejectedLoad(): Unit {
    let directory = Directory.createTemp("/tmp")
    let documentPath = directory.join("invalid-session.txt").toString()
    File.writeTo(documentPath, "bad schema".toArray())
    let binding = CjguiTextDocumentFileBinding()
    let opened = binding.openValidatedFromHuman(7303, "业务会话", documentPath,
        64, { text => text == "expected schema" })
    @Assert(opened.applied, false)
    @Assert(opened.reason, "validation_refused")
    let overwritten = binding.saveFromHuman(
        CjguiTextDocument(7303, "业务会话", "replacement").snapshot(), documentPath)
    @Assert(overwritten.applied, false)
    @Assert(overwritten.reason, "save_target_exists")
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "bad schema")
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func textDocumentFileBindingBoundsWritesAndReadsBeforeAdopting(): Unit {
    let directory = Directory.createTemp("/tmp")
    let documentPath = directory.join("bounded-document.txt").toString()
    let binding = CjguiTextDocumentFileBinding()
    let tooLarge = binding.saveBoundedFromHuman(
        CjguiTextDocument(7304, "有界文件", "超过限制").snapshot(),
        documentPath, 2)
    @Assert(tooLarge.applied, false)
    @Assert(tooLarge.reason, "payload_too_large")
    @Assert(exists(documentPath), false)

    File.writeTo(documentPath, "valid candidate".toArray())
    let oversized = binding.openValidatedFromHuman(7304, "有界文件", documentPath,
        4, { _ => true })
    @Assert(oversized.applied, false)
    @Assert(oversized.reason, "payload_too_large")
    let rejectedWrite = binding.saveFromHuman(
        CjguiTextDocument(7304, "有界文件", "replacement").snapshot(), documentPath)
    @Assert(rejectedWrite.applied, false)
    @Assert(rejectedWrite.reason, "save_target_exists")
    @Assert(String.fromUtf8(File.readFrom(documentPath)), "valid candidate")

    let valid = binding.openValidatedFromHuman(7304, "有界文件", documentPath,
        64, { text => text == "valid candidate" })
    @Assert(valid.applied, true)
    match (valid.document) {
        case Some(document) => @Assert(document.snapshot().content, "valid candidate")
        case None => @Assert(true, false)
    }
    let _ = removeIfExists(directory, recursive: true)
}

@Test
func textDocumentFilePersistedStateKeepsExactOwnerAndPriorBaseline(): Unit {
    let directory = Directory.createTemp("/tmp")
    let path = directory.join("owner.txt").toString()
    let otherPath = directory.join("other.txt").toString()
    let binding = CjguiTextDocumentFileBinding()
    let original = CjguiTextDocument(7310, "Owner A", "相同🙂").snapshot()
    let otherOwner = CjguiTextDocument(7311, "Owner B", "相同🙂").snapshot()
    let changed = CjguiTextDocumentSnapshot(7310, "Owner A", "相同🙂!", 1)
    try {
        @Assert(binding.persistedState(original, ""), "no_file_path")
        @Assert(binding.persistedState(original, path), "unbound")
        @Assert(binding.saveFromHuman(original, path).applied, true)
        @Assert(binding.persistedState(original, path), "clean")
        @Assert(binding.persistedState(changed, path), "dirty")
        @Assert(binding.persistedState(otherOwner, path), "different_document")
        @Assert(binding.persistedState(original, otherPath), "different_path")

        // A failed save/open never grants a baseline or changes its owner.
        File.writeTo(Path(otherPath), "already exists".toArray())
        @Assert(binding.saveFromHuman(otherOwner, otherPath).reason, "save_target_exists")
        @Assert(binding.openFromHuman(7311, "Owner B", directory.join("missing").toString()).applied, false)
        @Assert(binding.persistedState(original, path), "clean")
        @Assert(binding.persistedState(otherOwner, path), "different_document")

        // State is explicitly an in-memory baseline comparison; a changed
        // external file still fails the existing actual save conflict guard.
        File.writeTo(Path(path), "external change".toArray())
        @Assert(binding.persistedState(original, path), "clean")
        @Assert(binding.saveFromHuman(changed, path).reason, "external_file_conflict")
        @Assert(binding.persistedState(original, path), "clean")
        @Assert(binding.persistedState(changed, path), "dirty")

        // A successful explicit open adopts that owner and its own baseline.
        @Assert(binding.openFromHuman(7311, "Owner B", path).applied, true)
        let reopened = CjguiTextDocumentSnapshot(7311, "Owner B", "external change", 0)
        @Assert(binding.persistedState(reopened, path), "clean")
        @Assert(binding.persistedState(original, path), "different_document")
    } finally { let _ = removeIfExists(directory, recursive: true) }
}
