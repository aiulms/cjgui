package cjgui

import std.collection.*
import std.sync.*

// Owner：仓颉 composable 构建期的组件实例身份；Truth：controller 持有的稳定业务 key
// 与其局部 key 映射；Stop-line：不保存 native 对象、不保存领域内容、不扩 public C ABI。
// Same-shape Boundary Brake：registry 只保留有界 live 实例，销毁后同 key 必须分配新 generation，
// 不能把数组下标、hash 或进程级表伪装成稳定身份。
// A bounded Cangjie-only identity allocator.  It assigns no native object and
// holds no process-wide instance table: each registry owns its live keys, and
// a destroyed key receives a fresh generation if it is mounted again.
private class CjguiComposableUiComponentGenerationAllocator {
    private static let lock = Mutex()
    private static var nextGeneration: Int64 = 1

    static func allocate(): Int64 {
        return synchronized(CjguiComposableUiComponentGenerationAllocator.lock) {
            let generation = CjguiComposableUiComponentGenerationAllocator.nextGeneration
            if (generation >= 9000000000000000) {
                return -1
            }
            CjguiComposableUiComponentGenerationAllocator.nextGeneration += 1
            return generation
        }
    }
}

/// One mounted component identity.  Local keys are stable within this
/// lifecycle; callers never manufacture shared numeric ranges.  The 64 local
/// slots are deliberate: a component needing an unbounded list must compose
/// its own keyed list rather than retain an unbounded framework registry.
public class CjguiComposableUiComponentInstance {
    private let instanceKeyValue: String
    private let generationValue: Int64
    private let localKeys: ArrayList<String>
    private var destroyedValue: Bool
    private var issueValue: String

    init(instanceKey: String, generation: Int64) {
        this.instanceKeyValue = instanceKey
        this.generationValue = generation
        this.localKeys = ArrayList<String>()
        this.destroyedValue = generation < 0
        this.issueValue = if (generation < 0) {
            "component_identity_exhausted"
        } else {
            ""
        }
    }

    public func isLive(): Bool {
        return !destroyedValue && generationValue > 0
    }
    public func instanceKey(): String {
        return instanceKeyValue
    }
    public func focusScopeId(): String {
        return "component-${generationValue}"
    }
    public func semanticId(localKey: String): String {
        // Public shared-operation snapshots are whitespace-delimited. Keep
        // business/local keys in this controller-owned registry; expose only
        // an opaque, protocol-safe generation/slot identity to projections.
        let node = nodeId(localKey)
        if (node < 0) {
            return "component-invalid"
        }
        let localSlot = node - generationValue * 1000
        return "component-${generationValue}-${localSlot}"
    }
    public func nodeId(localKey: String): Int64 {
        if (!isLive() || localKey.size == 0) {
            issueValue = "invalid_component_local_key"
            return -1
        }
        var index: Int64 = 0
        while (index < localKeys.size) {
            if (localKeys[index] == localKey) {
                return generationValue * 1000 + index + 1
            }
            index += 1
        }
        if (localKeys.size >= 64) {
            issueValue = "component_local_key_capacity"
            return -1
        }
        localKeys.add(localKey)
        return generationValue * 1000 + localKeys.size
    }
    public func commandId(localKey: String): String {
        return "component:${instanceKeyValue}:${generationValue}:command:${localKey}"
    }
    public func lastIssue(): String {
        return issueValue
    }
    func destroy(): Unit {
        destroyedValue = true
        localKeys.clear()
    }
}

/// Per-controller composition registry. Call `begin`, `use` each mounted
/// stable business key once, optionally `retain` a temporarily hidden key,
/// then `finish` for the legacy immediate path. Composable windows use the
/// explicit transaction methods so a candidate cannot destroy the accepted
/// instance set before layout and native presentation have both succeeded.
public class CjguiComposableUiComponentRegistry {
    // Accepted component identities. `liveCount` reports this set only; a
    // staged candidate never becomes externally live merely because buildUi
    // asked for it.
    private let keys: ArrayList<String>
    private let instances: ArrayList<CjguiComposableUiComponentInstance>
    private let candidateKeys: ArrayList<String>
    private let candidateInstances: ArrayList<CjguiComposableUiComponentInstance>
    private let candidateClaimed: ArrayList<Bool>
    // A retry slot carries scalar identity only. It owns no native object,
    // command binding, callback, or domain data and is discarded once a later
    // candidate no longer declares the same key.
    private let retryKeys: ArrayList<String>
    private let retryInstances: ArrayList<CjguiComposableUiComponentInstance>
    private var composing: Bool
    private var candidatePrepared: Bool
    private var usesExplicitTransaction: Bool
    private var issueValue: String

    public init() {
        this.keys = ArrayList<String>()
        this.instances = ArrayList<CjguiComposableUiComponentInstance>()
        this.candidateKeys = ArrayList<String>()
        this.candidateInstances = ArrayList<CjguiComposableUiComponentInstance>()
        this.candidateClaimed = ArrayList<Bool>()
        this.retryKeys = ArrayList<String>()
        this.retryInstances = ArrayList<CjguiComposableUiComponentInstance>()
        this.composing = false
        this.candidatePrepared = false
        this.usesExplicitTransaction = false
        this.issueValue = ""
    }
    /// Compatibility composition. `finish` still commits immediately for
    /// callers that do not opt into a window-owned refresh transaction.
    public func begin(): Bool {
        return beginComposition(false)
    }
    /// Starts one candidate for a window-owned refresh. The caller must use
    /// `prepareTransaction`, then exactly one of `commitTransaction` or
    /// `rollbackTransaction` after the actual scene outcome is known.
    public func beginTransaction(): Bool {
        return beginComposition(true)
    }
    private func beginComposition(explicitTransaction: Bool): Bool {
        if (composing) {
            issueValue = "component_composition_already_open"
            return false
        }
        if (candidatePrepared) {
            issueValue = "component_transaction_pending"
            return false
        }
        composing = true
        usesExplicitTransaction = explicitTransaction
        issueValue = ""
        candidateKeys.clear();
        candidateInstances.clear();
        candidateClaimed.clear()
        var index: Int64 = 0
        while (index < keys.size) {
            candidateKeys.add(keys[index]);
            candidateInstances.add(instances[index]);
            candidateClaimed.add(false)
            index += 1
        }
        return true
    }
    public func use(instanceKey: String): CjguiComposableUiComponentInstance {
        if (!composing || instanceKey.size == 0) {
            issueValue = "invalid_component_instance_key"
            return CjguiComposableUiComponentInstance("", -1)
        }
        let existing = candidateIndexForKey(instanceKey)
        if (existing >= 0) {
            if (candidateClaimed[existing]) {
                issueValue = "duplicate_component_key"
                return CjguiComposableUiComponentInstance("", -1)
            }
            candidateClaimed[existing] = true
            return candidateInstances[existing]
        }
        if (candidateKeys.size >= 64) {
            issueValue = "component_instance_capacity"
            return CjguiComposableUiComponentInstance("", -1)
        }
        let retry = retryIndexForKey(instanceKey)
        let instance = if (retry >= 0) {
            retryInstances[retry]
        } else {
            CjguiComposableUiComponentInstance(instanceKey, CjguiComposableUiComponentGenerationAllocator.allocate())
        }
        if (!instance.isLive()) {
            issueValue = instance.lastIssue()
            return instance
        }
        candidateKeys.add(instanceKey);
        candidateInstances.add(instance);
        candidateClaimed.add(true)
        return instance
    }
    public func retain(instanceKey: String): Bool {
        if (!composing) {
            issueValue = "component_composition_not_open"
            return false
        }
        let existing = candidateIndexForKey(instanceKey)
        if (existing >= 0 && !candidateClaimed[existing]) {
            candidateClaimed[existing] = true
            return true
        }
        if (existing >= 0) {
            issueValue = "duplicate_component_key"
            return false
        }
        issueValue = "unknown_component_key"
        return false
    }
    /// Completes the candidate declaration without changing accepted
    /// identities. A window calls this after buildUi and before layout/native
    /// submission, so duplicate/capacity faults fail before native work.
    public func prepareTransaction(): Bool {
        if (!composing || !usesExplicitTransaction) {
            issueValue = "component_transaction_not_open"
            return false
        }
        return prepareCandidate()
    }
    public func finish(): Bool {
        if (!composing || usesExplicitTransaction) {
            issueValue = "component_composition_not_open"
            return false
        }
        if (!prepareCandidate()) {
            rollbackTransaction();
            return false
        }
        commitTransaction()
        return issueValue.size == 0
    }
    /// Promotes exactly the prepared candidate. After a successful prepare this
    /// is infallible scalar bookkeeping, so native acceptance cannot be partly
    /// reversed by a second fallible owner operation.
    public func commitTransaction(): Unit {
        if (!candidatePrepared || composing) {
            issueValue = "component_transaction_not_prepared"
            return
        }
        let nextKeys = ArrayList<String>();
        let nextInstances = ArrayList<CjguiComposableUiComponentInstance>()
        var index: Int64 = 0
        while (index < candidateKeys.size) {
            if (candidateClaimed[index]) {
                nextKeys.add(candidateKeys[index]);
                nextInstances.add(candidateInstances[index])
            }
            index += 1
        }
        index = keys.size - 1
        while (index >= 0) {
            if (!hasKey(nextKeys, keys[index])) {
                instances[index].destroy()
            }
            index -= 1
        }
        keys.clear();
        instances.clear()
        for (key in nextKeys) {
            keys.add(key)
        }
        for (instance in nextInstances) {
            instances.add(instance)
        }
        discardUnusedRetryInstances()
        clearCandidate()
        issueValue = ""
    }
    /// Drops candidate bindings/resources while leaving every accepted identity
    /// untouched. A bounded scalar identity is retained only for the same
    /// unaccepted key's next retry; a superseding candidate destroys it.
    public func rollbackTransaction(): Unit {
        var index: Int64 = 0
        while (index < candidateKeys.size) {
            if (candidateClaimed[index] && !hasKey(keys, candidateKeys[index]) &&
                retryIndexForKey(candidateKeys[index]) < 0) {
                retryKeys.add(candidateKeys[index]);
                retryInstances.add(candidateInstances[index])
            }
            index += 1
        }
        clearCandidate()
    }
    public func lastIssue(): String {
        return issueValue
    }
    public func liveCount(): Int64 {
        return keys.size
    }
    private func prepareCandidate(): Bool {
        if (!composing) {
            issueValue = "component_composition_not_open"
            return false
        }
        composing = false
        candidatePrepared = issueValue.size == 0
        discardSupersededRetryInstances()
        return candidatePrepared
    }
    private func clearCandidate() {
        candidateKeys.clear();
        candidateInstances.clear();
        candidateClaimed.clear()
        composing = false
        candidatePrepared = false
        usesExplicitTransaction = false
    }
    private func candidateIndexForKey(key: String): Int64 {
        return indexForKey(candidateKeys, key)
    }
    private func retryIndexForKey(key: String): Int64 {
        return indexForKey(retryKeys, key)
    }
    private func indexForKey(values: ArrayList<String>, key: String): Int64 {
        var index: Int64 = 0
        while (index < values.size) {
            if (values[index] == key) {
                return index
            }
            index += 1
        }
        return -1
    }
    private func hasKey(values: ArrayList<String>, key: String): Bool {
        return indexForKey(values, key) >= 0
    }
    private func discardSupersededRetryInstances() {
        var index = retryKeys.size - 1
        while (index >= 0) {
            let candidate = candidateIndexForKey(retryKeys[index])
            if (candidate < 0 || !candidateClaimed[candidate]) {
                retryInstances[index].destroy();
                retryKeys.remove(at: index);
                retryInstances.remove(at: index)
            }
            index -= 1
        }
    }
    private func discardUnusedRetryInstances() {
        var index = retryKeys.size - 1
        while (index >= 0) {
            if (!hasKey(keys, retryKeys[index])) {
                retryInstances[index].destroy()
            }
            retryKeys.remove(at: index);
            retryInstances.remove(at: index);
            index -= 1
        }
    }
}
