package cjgui_shared_operation_core

import std.fs.*
import std.sync.*
import std.collection.*

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
    private var persistedDocumentId: Int64
    // One live workspace document owns this binding. A persisted baseline is
    // separate: it records the last successfully opened/saved file and can be
    // cleared when the live owner is retired.
    private var claimedDocumentIdValue: Int64

    public init() {
        this.lock = Mutex()
        this.currentPathValue = ""; this.lastPersistedPayload = ""; this.hasPersistedPayload = false
        this.persistedDocumentId = -1
        this.claimedDocumentIdValue = -1
    }

    public func currentPath(): String { return synchronized(lock) { currentPathValue } }

    /// The document this binding most recently opened or saved. A binding that
    /// only carries an intended new path reports -1 until its first save.
    public func boundDocumentId(): Int64 {
        return synchronized(lock) { if (hasPersistedPayload) { persistedDocumentId } else { -1 } }
    }

    /// The live workspace document currently borrowing this binding, or -1.
    /// Admission is rejected before any file read or binding mutation when
    /// another document already owns it.
    public func claimedDocumentId(): Int64 {
        return synchronized(lock) { claimedDocumentIdValue }
    }

    /// Claims this binding for one live document. Repeating the claim for the
    /// same document is idempotent. A different live owner is never displaced.
    public func claimDocument(documentId: Int64): Bool {
        return synchronized(lock) {
            if (documentId < 0) { return false }
            if (claimedDocumentIdValue >= 0 && claimedDocumentIdValue != documentId) { return false }
            claimedDocumentIdValue = documentId
            return true
        }
    }

    /// Releases a failed admission while preserving the prior persisted
    /// baseline. Use `releaseDocument` when the live owner is actually retired.
    public func unclaimDocument(documentId: Int64): Bool {
        return synchronized(lock) {
            if (claimedDocumentIdValue != documentId) { return false }
            claimedDocumentIdValue = -1
            return true
        }
    }

    /// Retires the live owner and clears its trusted baseline. The file on
    /// disk is untouched; a later claim starts from the new target's content.
    public func releaseDocument(documentId: Int64): Bool {
        return synchronized(lock) {
            if (claimedDocumentIdValue != documentId) { return false }
            claimedDocumentIdValue = -1
            currentPathValue = ""; lastPersistedPayload = ""; hasPersistedPayload = false
            persistedDocumentId = -1
            return true
        }
    }

    /// Experimental, read-only comparison against this binding's last
    /// successfully opened/saved baseline. Returns `no_file_path`, `unbound`,
    /// `different_document`, `different_path`, `dirty`, or `clean`. The document id identifies the
    /// owner within its fixed workspace; this is not a filesystem freshness
    /// check or a cross-workspace instance credential. Actual save still
    /// performs its own external-file conflict check.
    public func persistedState(snapshot: CjguiTextDocumentSnapshot, path: String): String {
        return synchronized(lock) {
            if (path.size == 0) { return "no_file_path" }
            if (!hasPersistedPayload) { return "unbound" }
            if (snapshot.documentId != persistedDocumentId) { return "different_document" }
            if (path != currentPathValue) { return "different_path" }
            return if (snapshot.content == lastPersistedPayload) { "clean" } else { "dirty" }
        }
    }

    public func saveFromHuman(snapshot: CjguiTextDocumentSnapshot, path: String): CjguiTextDocumentFileSaveResult {
        return synchronized(lock) { saveUnlocked(snapshot, path, -1) }
    }

    /// Bounded counterpart for callers that store a framed application state.
    /// It keeps the same cross-process claim, trusted-baseline comparison and
    /// atomic publication as `saveFromHuman`.
    public func saveBoundedFromHuman(snapshot: CjguiTextDocumentSnapshot, path: String,
        maximumBytes: Int64): CjguiTextDocumentFileSaveResult {
        return synchronized(lock) { saveUnlocked(snapshot, path, maximumBytes) }
    }

    private func saveUnlocked(snapshot: CjguiTextDocumentSnapshot, path: String,
        maximumBytes: Int64): CjguiTextDocumentFileSaveResult {
        if (path.size == 0) { return CjguiTextDocumentFileSaveResult(false, path, "no_file_path") }
        if (maximumBytes < -1) {
            return CjguiTextDocumentFileSaveResult(false, path, "invalid_byte_limit")
        }
        if (maximumBytes >= 0 && snapshot.content.toArray().size > maximumBytes) {
            return CjguiTextDocumentFileSaveResult(false, path, "payload_too_large")
        }
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
        let result = saveWhileClaimedUnlocked(snapshot, target, path, maximumBytes)
        try { let _ = removeIfExists(saveLock, recursive: true) } catch (_) {}
        return result
    }

    private func saveWhileClaimedUnlocked(
        snapshot: CjguiTextDocumentSnapshot,
        target: Path,
        path: String,
        maximumBytes: Int64
    ): CjguiTextDocumentFileSaveResult {
        let isExistingBinding = hasPersistedPayload && currentPathValue == path
        if (!isExistingBinding && exists(path)) {
            return CjguiTextDocumentFileSaveResult(false, path, "save_target_exists")
        }
        if (isExistingBinding) {
            try {
                if (!exists(path) || !matchesPersistedBaseline(path, maximumBytes)) {
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
                if (isExistingBinding && (!exists(path) || !matchesPersistedBaseline(path, maximumBytes))) {
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
                persistedDocumentId = snapshot.documentId
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

    /// Opens an existing file, or creates an empty document for a path that
    /// does not exist yet. An existing but unreadable file is a failure and
    /// grants no baseline. The caller decides whether new-target creation is
    /// allowed; this method never overwrites.
    public func openOrCreateFromHuman(documentId: Int64, title: String,
        path: String): CjguiTextDocumentFileOpenResult {
        return synchronized(lock) {
            if (path.size == 0) { return CjguiTextDocumentFileOpenResult(false, None, path, "no_file_path") }
            if (exists(path)) { return openUnlocked(documentId, title, path) }
            var document: ?CjguiTextDocument = None
            try {
                document = Some(CjguiTextDocument(documentId, title, ""))
            } catch (_) {
                return CjguiTextDocumentFileOpenResult(false, None, path, "invalid_text_document")
            }
            currentPathValue = path
            lastPersistedPayload = ""
            hasPersistedPayload = false
            persistedDocumentId = documentId
            return CjguiTextDocumentFileOpenResult(true, document, path, "created")
        }
    }

    /// Reads and validates one bounded candidate before adopting any path or
    /// payload as this binding's trusted save baseline. A rejected or malformed
    /// candidate cannot grant a later overwrite permit.
    public func openValidatedFromHuman(documentId: Int64, title: String, path: String,
        maximumBytes: Int64, validate: (String) -> Bool): CjguiTextDocumentFileOpenResult {
        return openValidatedWithReasonFromHuman(documentId, title, path, maximumBytes, { payload =>
            let accepted = try { validate(payload) } catch (_) { false }
            if (accepted) { "" } else { "validation_refused" }
        })
    }

    /// Variant for an app parser that can return a stable, app-defined refusal
    /// reason. Empty accepts. The validator runs before any path/baseline state
    /// changes and the candidate bytes are still bounded and descriptor-scoped.
    public func openValidatedWithReasonFromHuman(documentId: Int64, title: String, path: String,
        maximumBytes: Int64, validateReason: (String) -> String): CjguiTextDocumentFileOpenResult {
        return synchronized(lock) { openValidatedWithReasonUnlocked(documentId, title, path,
            maximumBytes, validateReason) }
    }

    private func openValidatedWithReasonUnlocked(documentId: Int64, title: String, path: String,
        maximumBytes: Int64, validateReason: (String) -> String): CjguiTextDocumentFileOpenResult {
            if (path.size == 0) {
                return CjguiTextDocumentFileOpenResult(false, None, path, "no_file_path")
            }
            if (maximumBytes < 0) {
                return CjguiTextDocumentFileOpenResult(false, None, path, "invalid_byte_limit")
            }
            let (readOk, readReason, payload) = readBoundedUtf8(path, maximumBytes)
            if (!readOk) {
                return CjguiTextDocumentFileOpenResult(false, None, path, readReason)
            }
            let refusal = try {
                validateReason(payload)
            } catch (_) {
                "validation_refused"
            }
            if (refusal.size > 0) {
                return CjguiTextDocumentFileOpenResult(false, None, path, refusal)
            }
            let document = CjguiTextDocument(documentId, title, payload)
            currentPathValue = path
            lastPersistedPayload = payload
            hasPersistedPayload = true
            persistedDocumentId = documentId
            return CjguiTextDocumentFileOpenResult(true, Some(document), path, "opened")
    }

    private func openUnlocked(documentId: Int64, title: String, path: String): CjguiTextDocumentFileOpenResult {
        if (path.size == 0) { return CjguiTextDocumentFileOpenResult(false, None, path, "no_file_path") }
        try {
            let payload = String.fromUtf8(File.readFrom(path))
            let document = CjguiTextDocument(documentId, title, payload)
            currentPathValue = path; lastPersistedPayload = payload; hasPersistedPayload = true
            persistedDocumentId = documentId
            return CjguiTextDocumentFileOpenResult(true, Some(document), path, "opened")
        } catch (_) {
            return CjguiTextDocumentFileOpenResult(false, None, path, "file_read_failed")
        }
    }

    private func matchesPersistedBaseline(path: String, maximumBytes: Int64): Bool {
        if (maximumBytes < 0) {
            return String.fromUtf8(File.readFrom(path)) == lastPersistedPayload
        }
        let (readOk, _, payload) = readBoundedUtf8(path, maximumBytes)
        return readOk && payload == lastPersistedPayload
    }
}

/// Uses one descriptor and the size observed before reading, then probes for
/// growth. This prevents a growing file or a declared oversized file from
/// being loaded into memory without the caller's budget.
private func readBoundedUtf8(path: String, maximumBytes: Int64): (Bool, String, String) {
    if (maximumBytes < 0) { return (false, "invalid_byte_limit", "") }
    var declared: Int64 = 0
    try {
        declared = FileInfo(path).size
    } catch (_) {
        return (false, "file_read_failed", "")
    }
    if (declared > maximumBytes) { return (false, "payload_too_large", "") }
    let bytes = ArrayList<UInt8>()
    try {
        try (file = File(path, OpenMode.Read)) {
            var remaining = declared
            while (remaining > 0) {
                let chunkSize = if (remaining > 65536) { 65536 } else { remaining }
                let chunk = Array<UInt8>(chunkSize, repeat: 0)
                let read = file.read(chunk)
                if (read <= 0) { return (false, "file_read_failed", "") }
                var index: Int64 = 0
                while (index < read) {
                    bytes.add(chunk[index])
                    index += 1
                }
                remaining -= read
            }
            let probe = Array<UInt8>(1, repeat: 0)
            if (file.read(probe) > 0) { return (false, "payload_too_large", "") }
        }
    } catch (_) {
        return (false, "file_read_failed", "")
    }
    try {
        return (true, "", String.fromUtf8(bytes.toArray()))
    } catch (_) {
        return (false, "file_read_failed", "")
    }
}
