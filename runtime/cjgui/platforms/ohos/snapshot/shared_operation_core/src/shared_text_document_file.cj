package cjgui_shared_operation_core

import std.fs.*
import std.sync.*

/// Result of the local, explicitly user-initiated file write. This is not an
/// external shared-operation result: document truth remains in memory and an
/// I/O error never advances its content version.
public class CjguiTextDocumentFileSaveResult {
    public let applied: Bool
    public let path: String
    public let reason: String
    public init(applied: Bool, path: String, reason: String) {
        this.applied = applied; this.path = path; this.reason = reason
    }
}

/// File open produces a fresh in-memory document at version zero. Callers
/// replace their workspace deliberately; opening does not mutate an existing
/// document behind a UI or external client's back.
public class CjguiTextDocumentFileOpenResult {
    public let applied: Bool
    public let document: ?CjguiTextDocument
    public let path: String
    public let reason: String
    public init(applied: Bool, document: ?CjguiTextDocument, path: String, reason: String) {
        this.applied = applied; this.document = document; this.path = path; this.reason = reason
    }
}

/// Narrow plain UTF-8 file binding for a single document. It atomically
/// writes a private sibling temp file under an actual cross-process directory
/// claim, rechecks the last payload before the rename, and refuses to
/// overwrite a changed open file. It intentionally stores only its persisted
/// baseline, never a second editable document.
public class CjguiTextDocumentFileBinding {
    private let lock: Mutex
    private var currentPathValue: String
    private var lastPersistedPayload: String
    private var hasPersistedPayload: Bool

    public init() {
        this.lock = Mutex()
        this.currentPathValue = ""; this.lastPersistedPayload = ""; this.hasPersistedPayload = false
    }

    public func currentPath(): String { return synchronized(lock) { currentPathValue } }

    public func saveFromHuman(snapshot: CjguiTextDocumentSnapshot, path: String): CjguiTextDocumentFileSaveResult {
        return synchronized(lock) { saveUnlocked(snapshot, path) }
    }

    private func saveUnlocked(snapshot: CjguiTextDocumentSnapshot, path: String): CjguiTextDocumentFileSaveResult {
        if (path.size == 0) { return CjguiTextDocumentFileSaveResult(false, path, "no_file_path") }
        let target = Path(path)
        let saveLock = Path("${path}.cjgui-save-lock")
        if (exists(saveLock)) { return CjguiTextDocumentFileSaveResult(false, path, "save_in_progress") }
        try {
            // mkdir is an atomic filesystem operation. Every CJGUI document
            // binder takes this same sibling lock before it observes or
            // replaces the target, including independent app processes.
            Directory.create(saveLock, recursive: false)
        } catch (_) {
            if (exists(saveLock)) { return CjguiTextDocumentFileSaveResult(false, path, "save_in_progress") }
            return CjguiTextDocumentFileSaveResult(false, path, "file_write_failed")
        }
        let result = saveWhileClaimedUnlocked(snapshot, target, path)
        try { let _ = removeIfExists(saveLock, recursive: true) } catch (_) {}
        return result
    }

    private func saveWhileClaimedUnlocked(
        snapshot: CjguiTextDocumentSnapshot,
        target: Path,
        path: String
    ): CjguiTextDocumentFileSaveResult {
        let isExistingBinding = hasPersistedPayload && currentPathValue == path
        if (!isExistingBinding && exists(path)) {
            return CjguiTextDocumentFileSaveResult(false, path, "save_target_exists")
        }
        if (isExistingBinding) {
            try {
                if (!exists(path) || String.fromUtf8(File.readFrom(path)) != lastPersistedPayload) {
                    return CjguiTextDocumentFileSaveResult(false, path, "external_file_conflict")
                }
            } catch (_) {
                return CjguiTextDocumentFileSaveResult(false, path, "file_read_failed")
            }
        }
        try {
            let temporaryDirectory = Directory.createTemp(target.parent)
            let temporaryPath = temporaryDirectory.join("cjgui-document-write")
            try {
                File.writeTo(temporaryPath, snapshot.content.toArray())
                if (!isExistingBinding && exists(path)) {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                    return CjguiTextDocumentFileSaveResult(false, path, "save_target_exists")
                }
                if (isExistingBinding && (!exists(path) || String.fromUtf8(File.readFrom(path)) != lastPersistedPayload)) {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                    return CjguiTextDocumentFileSaveResult(false, path, "external_file_conflict")
                }
                try {
                    // A new target is never overwritten. If another writer
                    // creates it after the preceding observation, this atomic
                    // no-overwrite rename fails rather than clobbering it.
                    rename(temporaryPath, to: target, overwrite: isExistingBinding)
                } catch (_) {
                    let _ = removeIfExists(temporaryDirectory, recursive: true)
                    if (!isExistingBinding && exists(path)) {
                        return CjguiTextDocumentFileSaveResult(false, path, "save_target_exists")
                    }
                    return CjguiTextDocumentFileSaveResult(false, path, "file_write_failed")
                }
                let _ = removeIfExists(temporaryDirectory, recursive: true)
                currentPathValue = path; lastPersistedPayload = snapshot.content; hasPersistedPayload = true
                return CjguiTextDocumentFileSaveResult(true, path, "saved")
            } catch (_) {
                try { let _ = removeIfExists(temporaryDirectory, recursive: true) } catch (_) {}
                return CjguiTextDocumentFileSaveResult(false, path, "file_write_failed")
            }
        } catch (_) {
            return CjguiTextDocumentFileSaveResult(false, path, "file_write_failed")
        }
    }

    public func openFromHuman(documentId: Int64, title: String, path: String): CjguiTextDocumentFileOpenResult {
        return synchronized(lock) { openUnlocked(documentId, title, path) }
    }

    private func openUnlocked(documentId: Int64, title: String, path: String): CjguiTextDocumentFileOpenResult {
        if (path.size == 0) { return CjguiTextDocumentFileOpenResult(false, None, path, "no_file_path") }
        try {
            let payload = String.fromUtf8(File.readFrom(path))
            let document = CjguiTextDocument(documentId, title, payload)
            currentPathValue = path; lastPersistedPayload = payload; hasPersistedPayload = true
            return CjguiTextDocumentFileOpenResult(true, Some(document), path, "opened")
        } catch (_) {
            return CjguiTextDocumentFileOpenResult(false, None, path, "file_read_failed")
        }
    }
}
