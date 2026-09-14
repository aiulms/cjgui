package cjgui

import cjgui_shared_operation_core.*
import std.collection.*
import std.time.*

// Focused, platform-free proof for the composable UI value path.  It starts
// with one horizontally arranged header and a clipped scrolling content area
// containing more than eight independently addressable controls.

private func require(condition: Bool, message: String): Bool {
    if (!condition) { println("composable ui probe: failed ${message}") }
    return condition
}

private func sceneNodeForSemanticId(scene: CjguiComposableUiScene, semanticId: String): CjguiComposableUiLayoutNode {
    for (node in scene.nodes()) {
        if (node.semanticId == semanticId) {
            return node
        }
    }
    return CjguiComposableUiLayoutNode.missing()
}

private func scopedIdentityBenchmarkRoot(label: String, componentCount: Int64, reverse: Bool,
    includeDuplicate!: Bool = false): CjguiComposableUiNode {
    let root = cjguiComposableVertical(7600, "identity-cost-${label}-root", CjguiComposableUiStyle(gap: 2))
    var order: Int64 = 0
    while (order < componentCount) {
        let componentIndex = if (reverse) { componentCount - order - 1 } else { order }
        let componentKey = "component-${componentIndex}"
        let scope = CjguiComposableUiIdentityScope("identity-cost-${label}").child(componentKey)
        let items = ArrayList<CjguiComposableUiActionItem>()
        items.add(CjguiComposableUiActionItem("apply", "apply", "APPLY", componentIndex,
            CjguiComposableUiStyle(fixedHeight: 20), semanticId: "identity-cost-${label}-${componentKey}-apply"))
        root.add(cjguiComposableScopedActionRow(scope, "identity-cost-${label}-${componentKey}", items,
            CjguiComposableUiStyle(gap: 2)))
        order += 1
    }
    if (includeDuplicate && componentCount > 0) {
        let duplicateScope = CjguiComposableUiIdentityScope("identity-cost-${label}").child("component-0")
        let duplicateItems = ArrayList<CjguiComposableUiActionItem>()
        duplicateItems.add(CjguiComposableUiActionItem("apply", "duplicate", "APPLY", 0,
            CjguiComposableUiStyle(fixedHeight: 20), semanticId: "identity-cost-${label}-duplicate-apply"))
        root.add(cjguiComposableScopedActionRow(duplicateScope, "identity-cost-${label}-duplicate", duplicateItems,
            CjguiComposableUiStyle(gap: 2)))
    }
    return root
}

/// Candidate/scene construction is measured in nanoseconds. Tree creation,
/// retained-count reads, semantic checks and output are deliberately outside
/// each timed interval. The four conditions exercise fresh allocation, live
/// remapping, removal/re-add churn, and a rejected candidate followed by an
/// ordinary recovery without presenting a second scene or retaining history.
private func verifyScopedIdentityCost(label: String, componentCount: Int64): Bool {
    var coldMinNs: Int64 = -1; var coldMaxNs: Int64 = 0; var coldTotalNs: Int64 = 0
    var warmMinNs: Int64 = -1; var warmMaxNs: Int64 = 0; var warmTotalNs: Int64 = 0
    var churnMinNs: Int64 = -1; var churnMaxNs: Int64 = 0; var churnTotalNs: Int64 = 0
    var failedMinNs: Int64 = -1; var failedMaxNs: Int64 = 0; var failedTotalNs: Int64 = 0
    var recoveryMinNs: Int64 = -1; var recoveryMaxNs: Int64 = 0; var recoveryTotalNs: Int64 = 0
    var maximumPendingEntries: Int64 = 0; var maximumPendingStringBytes: Int64 = 0
    var expectedWarmAction: Int64 = -1; var expectedChurnAction: Int64 = -1; var expectedRecoveryAction: Int64 = -1
    var sample: Int64 = 0
    while (sample < 30) {
        let root = scopedIdentityBenchmarkRoot(label, componentCount, sample % 2 != 0)
        let registry = CjguiComposableUiIdentityRegistry()
        let started = MonoTime.now()
        let opened = registry.beginCandidate()
        let issue = registry.resolveCandidate(root)
        let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 640, 2048), sample + 200)
        let prepared = registry.prepareCandidate()
        let elapsed = (MonoTime.now() - started).toNanoseconds()
        let pendingEntries = registry.candidateCount(); let pendingStringBytes = registry.candidateRetainedStringBytes()
        if (pendingEntries > maximumPendingEntries) { maximumPendingEntries = pendingEntries }
        if (pendingStringBytes > maximumPendingStringBytes) { maximumPendingStringBytes = pendingStringBytes }
        let actionId = sceneNodeForSemanticId(scene, "identity-cost-${label}-component-0-apply").nodeId
        let valid = opened && issue == "" && scene.isValid() && prepared && actionId >= 8000000000000000000 &&
            registry.candidateCount() == componentCount * 2
        if (prepared) { registry.commitCandidate() } else { registry.rollbackCandidate() }
        if (!valid || registry.liveCount() != componentCount * 2) { return false }
        let safeElapsed = if (elapsed >= 0) { elapsed } else { 0 }
        if (coldMinNs < 0 || safeElapsed < coldMinNs) { coldMinNs = safeElapsed }
        if (safeElapsed > coldMaxNs) { coldMaxNs = safeElapsed }; coldTotalNs += safeElapsed
        sample += 1
    }

    let warmRegistry = CjguiComposableUiIdentityRegistry()
    sample = 0
    while (sample < 30) {
        let root = scopedIdentityBenchmarkRoot(label, componentCount, sample % 2 != 0)
        let started = MonoTime.now()
        let opened = warmRegistry.beginCandidate()
        let issue = warmRegistry.resolveCandidate(root)
        let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 640, 2048), sample + 300)
        let prepared = warmRegistry.prepareCandidate()
        let elapsed = (MonoTime.now() - started).toNanoseconds()
        let pendingEntries = warmRegistry.candidateCount(); let pendingStringBytes = warmRegistry.candidateRetainedStringBytes()
        if (pendingEntries > maximumPendingEntries) { maximumPendingEntries = pendingEntries }
        if (pendingStringBytes > maximumPendingStringBytes) { maximumPendingStringBytes = pendingStringBytes }
        let actionId = sceneNodeForSemanticId(scene, "identity-cost-${label}-component-0-apply").nodeId
        let valid = opened && issue == "" && scene.isValid() && prepared && actionId >= 8000000000000000000
        if (prepared) { warmRegistry.commitCandidate() } else { warmRegistry.rollbackCandidate() }
        if (expectedWarmAction < 0) { expectedWarmAction = actionId }
        if (!valid || actionId != expectedWarmAction || warmRegistry.liveCount() != componentCount * 2) { return false }
        let safeElapsed = if (elapsed >= 0) { elapsed } else { 0 }
        if (warmMinNs < 0 || safeElapsed < warmMinNs) { warmMinNs = safeElapsed }
        if (safeElapsed > warmMaxNs) { warmMaxNs = safeElapsed }; warmTotalNs += safeElapsed
        sample += 1
    }

    let churnRegistry = CjguiComposableUiIdentityRegistry()
    sample = 0
    while (sample < 30) {
        let visibleCount = if (sample % 2 == 0) { componentCount } else { componentCount - 1 }
        let root = scopedIdentityBenchmarkRoot(label, visibleCount, sample % 3 == 0)
        let started = MonoTime.now()
        let opened = churnRegistry.beginCandidate()
        let issue = churnRegistry.resolveCandidate(root)
        let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 640, 2048), sample + 400)
        let prepared = churnRegistry.prepareCandidate()
        let elapsed = (MonoTime.now() - started).toNanoseconds()
        let pendingEntries = churnRegistry.candidateCount(); let pendingStringBytes = churnRegistry.candidateRetainedStringBytes()
        if (pendingEntries > maximumPendingEntries) { maximumPendingEntries = pendingEntries }
        if (pendingStringBytes > maximumPendingStringBytes) { maximumPendingStringBytes = pendingStringBytes }
        let actionId = sceneNodeForSemanticId(scene, "identity-cost-${label}-component-0-apply").nodeId
        let valid = opened && issue == "" && scene.isValid() && prepared && actionId >= 8000000000000000000
        if (prepared) { churnRegistry.commitCandidate() } else { churnRegistry.rollbackCandidate() }
        if (expectedChurnAction < 0) { expectedChurnAction = actionId }
        if (!valid || actionId != expectedChurnAction || churnRegistry.liveCount() != visibleCount * 2) { return false }
        let safeElapsed = if (elapsed >= 0) { elapsed } else { 0 }
        if (churnMinNs < 0 || safeElapsed < churnMinNs) { churnMinNs = safeElapsed }
        if (safeElapsed > churnMaxNs) { churnMaxNs = safeElapsed }; churnTotalNs += safeElapsed
        sample += 1
    }

    let recoveryRegistry = CjguiComposableUiIdentityRegistry()
    sample = 0
    while (sample < 30) {
        let failedRoot = scopedIdentityBenchmarkRoot(label, componentCount, sample % 2 != 0, includeDuplicate: true)
        let failedStarted = MonoTime.now()
        let failedOpened = recoveryRegistry.beginCandidate()
        let failedIssue = recoveryRegistry.resolveCandidate(failedRoot)
        let failedElapsed = (MonoTime.now() - failedStarted).toNanoseconds()
        let failedPendingEntries = recoveryRegistry.candidateCount()
        let failedPendingStringBytes = recoveryRegistry.candidateRetainedStringBytes()
        if (failedPendingEntries > maximumPendingEntries) { maximumPendingEntries = failedPendingEntries }
        if (failedPendingStringBytes > maximumPendingStringBytes) { maximumPendingStringBytes = failedPendingStringBytes }
        recoveryRegistry.rollbackCandidate()
        if (!failedOpened || failedIssue.size == 0) { return false }
        let safeFailedElapsed = if (failedElapsed >= 0) { failedElapsed } else { 0 }
        if (failedMinNs < 0 || safeFailedElapsed < failedMinNs) { failedMinNs = safeFailedElapsed }
        if (safeFailedElapsed > failedMaxNs) { failedMaxNs = safeFailedElapsed }; failedTotalNs += safeFailedElapsed

        let recoveryRoot = scopedIdentityBenchmarkRoot(label, componentCount, sample % 2 != 0)
        let recoveryStarted = MonoTime.now()
        let recoveryOpened = recoveryRegistry.beginCandidate()
        let recoveryIssue = recoveryRegistry.resolveCandidate(recoveryRoot)
        let recoveryScene = CjguiComposableUiLayoutEngine.layout(recoveryRoot,
            CjguiComposableUiRect(0, 0, 640, 2048), sample + 500)
        let recoveryPrepared = recoveryRegistry.prepareCandidate()
        let recoveryElapsed = (MonoTime.now() - recoveryStarted).toNanoseconds()
        let recoveryPendingEntries = recoveryRegistry.candidateCount()
        let recoveryPendingStringBytes = recoveryRegistry.candidateRetainedStringBytes()
        if (recoveryPendingEntries > maximumPendingEntries) { maximumPendingEntries = recoveryPendingEntries }
        if (recoveryPendingStringBytes > maximumPendingStringBytes) { maximumPendingStringBytes = recoveryPendingStringBytes }
        let actionId = sceneNodeForSemanticId(recoveryScene, "identity-cost-${label}-component-0-apply").nodeId
        let recoveryValid = recoveryOpened && recoveryIssue == "" && recoveryScene.isValid() && recoveryPrepared &&
            actionId >= 8000000000000000000
        if (recoveryPrepared) { recoveryRegistry.commitCandidate() } else { recoveryRegistry.rollbackCandidate() }
        if (expectedRecoveryAction < 0) { expectedRecoveryAction = actionId }
        if (!recoveryValid || actionId != expectedRecoveryAction || recoveryRegistry.liveCount() != componentCount * 2) { return false }
        let safeRecoveryElapsed = if (recoveryElapsed >= 0) { recoveryElapsed } else { 0 }
        if (recoveryMinNs < 0 || safeRecoveryElapsed < recoveryMinNs) { recoveryMinNs = safeRecoveryElapsed }
        if (safeRecoveryElapsed > recoveryMaxNs) { recoveryMaxNs = safeRecoveryElapsed }; recoveryTotalNs += safeRecoveryElapsed
        sample += 1
    }
    println("CJGUI_SCOPED_IDENTITY_NS label=${label} condition=cold samples=30 components=${componentCount} min_ns=${coldMinNs} mean_ns=${coldTotalNs / 30} max_ns=${coldMaxNs}")
    println("CJGUI_SCOPED_IDENTITY_NS label=${label} condition=warm samples=30 components=${componentCount} min_ns=${warmMinNs} mean_ns=${warmTotalNs / 30} max_ns=${warmMaxNs}")
    println("CJGUI_SCOPED_IDENTITY_NS label=${label} condition=churn samples=30 components=${componentCount} min_ns=${churnMinNs} mean_ns=${churnTotalNs / 30} max_ns=${churnMaxNs}")
    println("CJGUI_SCOPED_IDENTITY_NS label=${label} condition=failure_recovery samples=30 failed_min_ns=${failedMinNs} failed_mean_ns=${failedTotalNs / 30} failed_max_ns=${failedMaxNs} recovery_min_ns=${recoveryMinNs} recovery_mean_ns=${recoveryTotalNs / 30} recovery_max_ns=${recoveryMaxNs} live_entries=${recoveryRegistry.liveCount()} live_string_bytes=${recoveryRegistry.liveRetainedStringBytes()} pending_entries_max=${maximumPendingEntries} pending_string_bytes_max=${maximumPendingStringBytes}")
    return true
}

private func sameResolvedGeometry(left: CjguiComposableUiScene, right: CjguiComposableUiScene): Bool {
    let leftNodes = left.nodes(); let rightNodes = right.nodes()
    if (!left.isValid() || !right.isValid() || leftNodes.size != rightNodes.size) { return false }
    var index: Int64 = 0
    while (index < leftNodes.size) {
        let a = leftNodes[index]; let b = rightNodes[index]
        if (a.nodeId != b.nodeId || a.nodeKind != b.nodeKind || a.inputScopeId != b.inputScopeId ||
            a.bounds.x != b.bounds.x || a.bounds.y != b.bounds.y ||
            a.bounds.width != b.bounds.width || a.bounds.height != b.bounds.height ||
            a.clip.x != b.clip.x || a.clip.y != b.clip.y ||
            a.clip.width != b.clip.width || a.clip.height != b.clip.height) { return false }
        index += 1
    }
    return true
}

/// The cache-free reference must agree with a replayed scene at every public
/// projection boundary, not just at a few visually convenient rectangles.
private func sameResolvedProjection(left: CjguiComposableUiScene, right: CjguiComposableUiScene): Bool {
    if (!sameResolvedGeometry(left, right) || left.version != right.version ||
        left.layoutError() != right.layoutError()) { return false }
    let leftNodes = left.nodes(); let rightNodes = right.nodes()
    var index: Int64 = 0
    while (index < leftNodes.size) {
        let a = leftNodes[index]; let b = rightNodes[index]
        if (a.semanticId != b.semanticId || a.label != b.label || a.value != b.value ||
            a.actionName != b.actionName || a.resourceId != b.resourceId || a.fieldId != b.fieldId ||
            a.operationActionName != b.operationActionName || a.operationResourceId != b.operationResourceId ||
            a.displayValueRole != b.displayValueRole || a.imageResourcePath != b.imageResourcePath ||
            a.imageResourceId != b.imageResourceId || a.imageResourceVersion != b.imageResourceVersion ||
            a.imageContentMode != b.imageContentMode || a.isEnabled != b.isEnabled ||
            a.isReadOnly != b.isReadOnly || a.tabInsertsText != b.tabInsertsText ||
            a.clipCornerRadius != b.clipCornerRadius || a.layerId != b.layerId || a.layerKind != b.layerKind ||
            a.canReceiveInput() != b.canReceiveInput() || a.canReceiveFocus() != b.canReceiveFocus() ||
            a.style.background.red != b.style.background.red || a.style.background.green != b.style.background.green ||
            a.style.background.blue != b.style.background.blue || a.style.background.alpha != b.style.background.alpha ||
            a.style.border.red != b.style.border.red || a.style.border.green != b.style.border.green ||
            a.style.border.blue != b.style.border.blue || a.style.border.alpha != b.style.border.alpha ||
            a.style.textColor.red != b.style.textColor.red || a.style.textColor.green != b.style.textColor.green ||
            a.style.textColor.blue != b.style.textColor.blue || a.style.textColor.alpha != b.style.textColor.alpha ||
            a.style.padding != b.style.padding || a.style.gap != b.style.gap ||
            a.style.fixedWidth != b.style.fixedWidth || a.style.fixedHeight != b.style.fixedHeight ||
            a.style.growX != b.style.growX || a.style.growY != b.style.growY ||
            a.style.borderWidth != b.style.borderWidth || a.style.cornerRadius != b.style.cornerRadius ||
            a.style.clipsContent != b.style.clipsContent || a.style.fontSize != b.style.fontSize ||
            a.style.fontWeight != b.style.fontWeight || a.style.fontFamily != b.style.fontFamily ||
            a.style.minWidth != b.style.minWidth || a.style.maxWidth != b.style.maxWidth ||
            a.style.idealWidth != b.style.idealWidth || a.style.minHeight != b.style.minHeight ||
            a.style.maxHeight != b.style.maxHeight || a.style.idealHeight != b.style.idealHeight ||
            a.style.alignX != b.style.alignX || a.style.alignY != b.style.alignY) { return false }
        let aClips = a.clipConstraints(); let bClips = b.clipConstraints()
        if (aClips.size != bClips.size) { return false }
        var clipIndex: Int64 = 0
        while (clipIndex < aClips.size) {
            let x = aClips[clipIndex]; let y = bClips[clipIndex]
            if (x.rect.x != y.rect.x || x.rect.y != y.rect.y || x.rect.width != y.rect.width ||
                x.rect.height != y.rect.height || x.cornerRadius != y.cornerRadius) { return false }
            clipIndex += 1
        }
        index += 1
    }
    return true
}

/// Counts calls that reach a real measurer boundary.  The layout engine must
/// not make the same text/style/width query repeatedly during one recursive
/// solve; this intentionally has no cache of its own.
private class CountingTextMeasurer <: CjguiComposableUiTextMeasurer {
    private let fallback: CjguiComposableUiFallbackTextMeasurer
    private var callCountValue: Int64
    init() { this.fallback = CjguiComposableUiFallbackTextMeasurer(); this.callCountValue = 0 }
    public func measure(value: String, style: CjguiComposableUiStyle, maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        callCountValue += 1
        return fallback.measure(value, style, maximumWidth)
    }
    func callCount(): Int64 { return callCountValue }
}

/// Test-only measurer whose environment can change independently of the
/// component tree.  The production cache must bind a cross-pass entry to this
/// actual measurement environment, not only to the value-derived signature.
private class EnvironmentTextMeasurer <: CjguiComposableUiTextMeasurer & CjguiComposableUiLayoutMeasurementEnvironment {
    private var lineHeightValue: Int64
    private let widthValue: Int64
    private var callCountValue: Int64
    private let environmentId: String

    init(lineHeight: Int64, width: Int64, environmentId: String) {
        this.lineHeightValue = lineHeight
        this.widthValue = width
        this.callCountValue = 0
        this.environmentId = environmentId
    }

    public func setLineHeight(lineHeight: Int64): Unit { lineHeightValue = lineHeight }

    public func layoutMeasurementEnvironmentKey(): String {
        return "probe-measurer-${environmentId}-line-height-${lineHeightValue}"
    }

    public func measure(value: String, style: CjguiComposableUiStyle,
        maximumWidth: Int64): CjguiComposableUiTextMeasurement {
        callCountValue += 1
        let boundedWidth = if (maximumWidth > 0 && maximumWidth < widthValue) { maximumWidth } else { widthValue }
        return CjguiComposableUiTextMeasurement(boundedWidth, lineHeightValue, lineHeightValue,
            if (lineHeightValue > 1) { lineHeightValue - 1 } else { 0 })
    }

    func measureCallCount(): Int64 { return callCountValue }
}

private func repeatedProbeText(count: Int64): String {
    let builder = StringBuilder()
    var index: Int64 = 0
    while (index < count) {
        builder.append("x")
        index += 1
    }
    return builder.toString()
}

private func hasProjectionNode(
    nodes: ArrayList<CjguiSharedOperationWindowNode>,
    semanticId: String,
    nodeId: Int64,
    nodeKind: String
): Bool {
    for (node in nodes) {
        if (node.semanticId == semanticId && node.nodeId == nodeId && node.nodeKind == nodeKind) {
            return true
        }
    }
    return false
}

private func hasProjectionRelation(
    relations: ArrayList<CjguiSharedOperationRelation>,
    sourceKind: String,
    sourceId: String,
    relationName: String,
    targetKind: String,
    targetId: String
): Bool {
    for (relation in relations) {
        if (relation.sourceKind == sourceKind && relation.sourceId == sourceId && relation.relation == relationName &&
            relation.targetKind == targetKind && relation.targetId == targetId) {
            return true
        }
    }
    return false
}

private func hasProjectionFieldValue(
    values: ArrayList<CjguiSharedOperationWindowFieldValue>,
    nodeSemanticId: String,
    resourceId: Int64,
    fieldId: String,
    displayValueRole: String,
    valueSource: String,
    value: String
): Bool {
    for (item in values) {
        if (item.nodeSemanticId == nodeSemanticId && item.resourceId == resourceId && item.fieldId == fieldId &&
            item.displayValueRole == displayValueRole && item.valueSource == valueSource &&
            item.value.valueType == "STRING" && item.value.stringValue == value) {
            return true
        }
    }
    return false
}

private func hasProjectionCollection(
    collections: ArrayList<CjguiSharedOperationWindowCollection>, semanticId: String,
    totalCount: Int64, materializedEnd: Int64
): Bool {
    for (collection in collections) {
        if (collection.semanticId == semanticId && collection.totalCount == totalCount &&
            collection.materializedEnd == materializedEnd) { return true }
    }
    return false
}

/// A range-addressable 2,000-row fixture. Its `buildRow` counter is the
/// regression guard: the virtual-list framework must never first construct a
/// full component tree and only then slice it for layout.
private class LargeVirtualListSource <: CjguiComposableUiVirtualListSource {
    private var buildCountValue: Int64

    init() { this.buildCountValue = 0 }

    public func itemCount(): Int64 { return 2000 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return CjguiComposableUiVirtualListItem("row_${index}", 900000 + index, "虚拟规则 ${index}")
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < itemCount()) {
            if (key == "row_${index}") { return index }
            index += 1
        }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        buildCountValue += 1
        return cjguiComposableButton(4000000 + item.resourceId, "virtual-${item.key}", item.title, "SELECT_VIRTUAL",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 20,
                background: if (isSelected || isFocused) { CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0) } else { CjguiComposableUiColor(0.98, 0.98, 0.99, 1.0) }
            ), operationActionName: "SELECT_VIRTUAL")
    }
    public func buildCount(): Int64 { return buildCountValue }
}

/// Small edge fixture used to prove that an empty or one-row logical source
/// still follows the same range path as the large source.
private class FixedVirtualListSource <: CjguiComposableUiVirtualListSource {
    private let countValue: Int64
    private var buildCountValue: Int64
    init(count: Int64) { this.countValue = if (count > 0) { count } else { 0 }; this.buildCountValue = 0 }
    public func itemCount(): Int64 { return countValue }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (index < 0 || index >= countValue) { return CjguiComposableUiVirtualListItem.missing() }
        return CjguiComposableUiVirtualListItem("fixed_${index}", 800000 + index, "固定项 ${index}")
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < countValue) {
            if (itemAt(index).key == key) { return index }
            index += 1
        }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        buildCountValue += 1
        return cjguiComposableButton(5800000 + item.resourceId, "fixed-${item.key}", item.title, "SELECT_FIXED",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 20), operationActionName: "SELECT_FIXED")
    }
    public func buildCount(): Int64 { return buildCountValue }
}

/// A real variable-height source that declares a reusable scoped card only
/// when the layout engine materializes its visible row. Its order changes are
/// projection-only; business identity remains the stable item key.
private class ScopedVariableListSource <: CjguiComposableUiVariableHeightListSource {
    private var reverseValue: Bool
    private var firstRemovedValue: Bool

    init() { this.reverseValue = false; this.firstRemovedValue = false }
    public func reverse(): Unit { reverseValue = !reverseValue }
    public func removeFirst(): Unit { firstRemovedValue = true }
    public func restoreFirst(): Unit { firstRemovedValue = false }
    public func itemCount(): Int64 { return if (firstRemovedValue) { 2 } else { 3 } }
    private func logicalIndex(index: Int64): Int64 {
        let first = if (firstRemovedValue) { 1 } else { 0 }
        let count = itemCount()
        return if (reverseValue) { first + count - index - 1 } else { first + index }
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= itemCount()) { return CjguiComposableUiVariableHeightListItem.missing() }
        let logical = logicalIndex(index)
        return CjguiComposableUiVariableHeightListItem("scoped_${logical}", 9750 + logical,
            "作用域卡片 ${logical}", 1, estimatedHeight: 36)
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < itemCount()) {
            if (itemAt(index).key == key) { return index }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let scope = CjguiComposableUiIdentityScope("scoped-variable-card").child(item.key)
        let card = CjguiComposableUiNode(-1, "scoped-card-${item.key}", CJGUI_COMPOSABLE_UI_LAYER_HOST, "", "", "",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 36), identity: Some(scope.local("card")))
        let base = CjguiComposableUiNode(-1, "scoped-card-base-${item.key}", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "",
            item.resourceId, CjguiComposableUiStyle(), identity: Some(scope.local("base")))
        base.add(CjguiComposableUiNode(-1, "scoped-card-menu-${item.key}", CJGUI_COMPOSABLE_UI_BUTTON,
            "菜单", "", "OPEN_CARD_MENU", item.resourceId, CjguiComposableUiStyle(fixedHeight: 24),
            operationActionName: "OPEN_CARD_MENU", operationResourceId: item.resourceId,
            identity: Some(scope.local("menu-trigger"))))
        card.add(base)
        let menu = CjguiComposableUiNode(-1, "scoped-card-popup-${item.key}", CJGUI_COMPOSABLE_UI_VERTICAL, "", "", "",
            item.resourceId, CjguiComposableUiStyle(fixedWidth: 72, fixedHeight: 20), layerId: "scoped-card-menu-${item.key}",
            layerKind: "menu", layerOwnerSemanticId: "scoped-card-${item.key}",
            layerAnchorSemanticId: "scoped-card-${item.key}",
            layerAnchorReference: Some(CjguiComposableUiNodeReference.scoped(scope, "menu-trigger")),
            identity: Some(scope.local("menu-popup")))
        menu.add(CjguiComposableUiNode(-1, "scoped-card-menu-choice-${item.key}", CJGUI_COMPOSABLE_UI_TEXT,
            "操作", "", "", item.resourceId, CjguiComposableUiStyle(), identity: Some(scope.local("menu-choice"))))
        card.add(menu)
        return card
    }
}

private func scopedVariableRoot(source: CjguiComposableUiVariableHeightListSource,
    state: CjguiComposableUiVirtualListState, nodeId: Int64): CjguiComposableUiNode {
    let root = cjguiComposableVertical(nodeId, "scoped-variable-root-${nodeId}", CjguiComposableUiStyle())
    root.add(cjguiComposableVariableHeightList(nodeId + 1, "scoped-variable-list-${nodeId}", nodeId + 2,
        source, state, 36, 1, 0, CjguiComposableUiStyle(fixedHeight: 120)))
    return root
}

/// Mutable logical order used to reproduce a stale-pixel-offset anchor.  The
/// source deliberately exposes no application mutation API: the probe changes
/// only its projection order, as a filtered or externally refreshed consumer
/// would do between two layouts.
private class DynamicVirtualListSource <: CjguiComposableUiVirtualListSource {
    private var hasPrefix: Bool
    private var reverseOrder: Bool
    private var removedOriginal: Int64

    init() { this.hasPrefix = false; this.reverseOrder = false; this.removedOriginal = -1 }
    public func prepend(): Unit { hasPrefix = true }
    public func reorder(): Unit { reverseOrder = true }
    public func removeStableAnchor(): Unit { removedOriginal = 5 }
    public func removeNonAnchorSelection(): Unit { removedOriginal = 4 }
    public func itemCount(): Int64 {
        let ordinary = if (removedOriginal >= 0) { 11 } else { 12 }
        return ordinary + if (hasPrefix) { 1 } else { 0 }
    }
    private func originalIndex(index: Int64): Int64 {
        var logical = index
        if (hasPrefix) {
            if (logical == 0) { return -2 }
            logical -= 1
        }
        if (reverseOrder) { logical = (if (removedOriginal >= 0) { 10 } else { 11 }) - logical }
        if (removedOriginal >= 0 && logical >= removedOriginal) { logical += 1 }
        return logical
    }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (index < 0 || index >= itemCount()) { return CjguiComposableUiVirtualListItem.missing() }
        let original = originalIndex(index)
        if (original == -2) { return CjguiComposableUiVirtualListItem("prefix", 910000, "前插项") }
        return CjguiComposableUiVirtualListItem("row_${original}", 910000 + original, "动态项 ${original}")
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < itemCount()) {
            if (itemAt(index).key == key) { return index }
            index += 1
        }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableButton(6000000 + item.resourceId, "dynamic-${item.key}", item.title, "SELECT_DYNAMIC",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 72), operationActionName: "SELECT_DYNAMIC")
    }
}

/// The invalid rows are intentionally adjacent: skipping either one would
/// move a later valid row upward and make its visual location disagree with
/// the source range.
private class SparseVirtualListSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 4 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (index == 1) { return CjguiComposableUiVirtualListItem.missing() }
        if (index < 0 || index >= 4) { return CjguiComposableUiVirtualListItem.missing() }
        return CjguiComposableUiVirtualListItem("sparse_${index}", 920000 + index, "稀疏项 ${index}")
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < 4) { if (itemAt(index).key == key) { return index }; index += 1 }
        return -1
    }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableButton(6200000 + item.resourceId, "sparse-${item.key}", item.title, "SELECT_SPARSE",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 96), operationActionName: "SELECT_SPARSE")
    }
}

private class DuplicateKeyVirtualListSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 3 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        if (index < 0 || index >= 3) { return CjguiComposableUiVirtualListItem.missing() }
        return CjguiComposableUiVirtualListItem(if (index == 0 || index == 1) { "duplicate" } else { "key_${index}" }, 930000 + index, "重复身份 ${index}")
    }
    public func indexForKey(key: String): Int64 { return if (key == "duplicate") { 1 } else { -1 } }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableButton(6400000 + item.resourceId, "duplicate-${item.key}", item.title, "SELECT_DUPLICATE",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 20), operationActionName: "SELECT_DUPLICATE")
    }
}

private class DuplicateNodeVirtualListSource <: CjguiComposableUiVirtualListSource {
    public func itemCount(): Int64 { return 2 }
    public func itemAt(index: Int64): CjguiComposableUiVirtualListItem {
        return if (index >= 0 && index < 2) { CjguiComposableUiVirtualListItem("node_${index}", 940000 + index, "重复节点 ${index}") }
        else { CjguiComposableUiVirtualListItem.missing() }
    }
    public func indexForKey(key: String): Int64 { return -1 }
    public func buildRow(item: CjguiComposableUiVirtualListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        return cjguiComposableButton(6500000, "node-${item.key}", item.title, "SELECT_NODE_DUPLICATE",
            item.resourceId, CjguiComposableUiStyle(fixedHeight: 20), operationActionName: "SELECT_NODE_DUPLICATE")
    }
}

/// A representative ordinary composition: independent tools, a stable
/// collection and a changing editor share one canonical layout tree. The
/// controller may rebuild value nodes on every domain revision, so reuse must
/// be based on layout inputs rather than object identity.
private func incrementalReuseDashboard(editorValue: String, collectionCount: Int64,
    fontSize!: Float64 = 14.0, collectionScrollOffset!: Int64 = -1,
    optInReuse!: Bool = true): CjguiComposableUiNode {
    let root = cjguiComposableHorizontal(970000, "incremental-dashboard", CjguiComposableUiStyle(gap: 8))
    let tools = cjguiComposableVertical(970001, "incremental-tools", CjguiComposableUiStyle(fixedWidth: 112, gap: 4),
        layoutReuseKey: if (optInReuse) { "tools-font=${fontSize}" } else { "" })
    tools.add(cjguiComposableText(970002, "incremental-tools-title", "工具", CjguiComposableUiStyle(fontSize: fontSize)))
    tools.add(cjguiComposableButton(970003, "incremental-create", "新增", "CREATE", 1,
        CjguiComposableUiStyle(fixedHeight: 28, fontSize: fontSize)))
    tools.add(cjguiComposableButton(970004, "incremental-save", "保存", "SAVE", 2,
        CjguiComposableUiStyle(fixedHeight: 28, fontSize: fontSize)))

    let collection = cjguiComposableVertical(970100, "incremental-collection", CjguiComposableUiStyle(fixedWidth: 216, gap: 2),
        layoutReuseKey: if (optInReuse) { "collection-count=${collectionCount}|font=${fontSize}" } else { "" })
    var index: Int64 = 0
    while (index < collectionCount) {
        collection.add(cjguiComposableButton(971000 + index, "incremental-row-${index}", "规则 ${index}", "SELECT", 1000 + index,
            CjguiComposableUiStyle(fixedHeight: 20, fontSize: fontSize)))
        index += 1
    }

    let editor = cjguiComposableVertical(970200, "incremental-editor", CjguiComposableUiStyle(growX: 1, gap: 6),
        layoutReuseKey: if (optInReuse) { "editor-value=${editorValue}|font=${fontSize}" } else { "" })
    editor.add(cjguiComposableText(970201, "incremental-editor-title", "编辑区", CjguiComposableUiStyle(fontSize: fontSize + 2.0)))
    editor.add(cjguiComposableMultilineTextInput(970202, "incremental-editor-value", "说明", editorValue, 7101,
        CjguiComposableUiStyle(growY: 1, fontSize: fontSize), fieldId: "description", operationActionName: "REPLACE_RANGE",
        operationResourceId: 7101))

    root.add(tools)
    if (collectionScrollOffset >= 0) {
        let scrollingCollection = cjguiComposableScrollArea(970099, "incremental-scroll", collectionScrollOffset,
            CjguiComposableUiStyle(fixedWidth: 216, growY: 1, clipsContent: true))
        scrollingCollection.add(collection)
        root.add(scrollingCollection)
    } else {
        root.add(collection)
    }
    root.add(editor)
    return root
}

/// Normal macOS consumers put ordinary content below a layer host. This small
/// representative tree proves that the host remains canonical for layer
/// ordering while its base's direct stable regions still reach the cache.
private func hostedIncrementalDashboard(detail: String): CjguiComposableUiNode {
    let host = cjguiComposableLayerHost(972000, "hosted-incremental-host", CjguiComposableUiStyle())
    let base = cjguiComposableVertical(972001, "hosted-incremental-base", CjguiComposableUiStyle(gap: 4))
    let header = cjguiComposableVertical(972002, "hosted-incremental-header",
        CjguiComposableUiStyle(fixedHeight: 32), layoutReuseKey: "hosted-header-v1")
    header.add(cjguiComposableText(972003, "hosted-incremental-title", "固定工具栏", CjguiComposableUiStyle(fontSize: 14.0)))
    base.add(header)
    base.add(cjguiComposableText(972004, "hosted-incremental-detail", detail,
        CjguiComposableUiStyle(fontSize: 14.0)))
    host.add(base)
    return host
}

private func incrementalBenchmarkTree(condition: String, collectionCount: Int64,
    optInReuse: Bool, target: Bool): CjguiComposableUiNode {
    if (condition == "warm") {
        return incrementalReuseDashboard("初始说明", collectionCount, optInReuse: optInReuse)
    }
    if (condition == "local") {
        return incrementalReuseDashboard(if (target) { "仅编辑区修改 ${collectionCount}" } else { "初始说明" },
            collectionCount, optInReuse: optInReuse)
    }
    if (condition == "resize") {
        return incrementalReuseDashboard("初始说明", collectionCount, optInReuse: optInReuse)
    }
    if (condition == "font") {
        return incrementalReuseDashboard("初始说明", collectionCount,
            fontSize: if (target) { 18.0 } else { 14.0 }, optInReuse: optInReuse)
    }
    if (condition == "scroll") {
        return incrementalReuseDashboard("初始说明", collectionCount,
            collectionScrollOffset: if (target) { 160 } else { 0 }, optInReuse: optInReuse)
    }
    // Deliberately changes every keyed region's layout input. This is the
    // full-invalidation fallback condition: no region hit is a requirement,
    // and the canonical solve must remain correct and bounded.
    return incrementalReuseDashboard(if (target) { "全量失效 ${collectionCount}" } else { "初始说明" },
        if (target) { collectionCount + 1 } else { collectionCount },
        fontSize: if (target) { 18.0 } else { 14.0 },
        collectionScrollOffset: if (target) { -1 } else { -1 }, optInReuse: optInReuse)
}

private func incrementalBenchmarkViewport(condition: String, target: Bool): CjguiComposableUiRect {
    return if (condition == "resize" && target) {
        CjguiComposableUiRect(0, 0, 720, 480)
    } else if (condition == "full_invalidation" && target) {
        CjguiComposableUiRect(0, 0, 720, 480)
    } else {
        CjguiComposableUiRect(0, 0, 960, 480)
    }
}

private func elapsedNanoseconds(started: MonoTime): Int64 {
    let elapsed = (MonoTime.now() - started).toNanoseconds()
    return if (elapsed >= 0) { elapsed } else { 0 }
}

private func printIncrementalLayoutBenchmarkSample(sample: Int64, mode: String, condition: String,
    collectionCount: Int64, buildNanoseconds: Int64, layoutNanoseconds: Int64,
    result: CjguiComposableUiLayoutResult): Unit {
    let metrics = result.metrics
    println("CJGUI_INCREMENTAL_LAYOUT_BENCHMARK_SAMPLE sample=${sample} mode=${mode} condition=${condition} rows=${collectionCount} build_ns=${buildNanoseconds} layout_ns=${layoutNanoseconds} total_ns=${buildNanoseconds + layoutNanoseconds} nodes=${result.scene.nodes().size} recursive_nodes=${metrics.recursiveNodeLayoutCount} vertical_solves=${metrics.verticalContainerSolveCount} horizontal_solves=${metrics.horizontalContainerSolveCount} layer_solves=${metrics.layerHostSolveCount} scroll_solves=${metrics.scrollAreaSolveCount} measurement_requests=${metrics.measurementRequestCount} measurer_calls=${metrics.measurerCallCount} measurement_hits=${metrics.measurementReuseHitCount} region_hits=${metrics.subtreeReuseHitCount} region_misses=${metrics.subtreeReuseMissCount} revalidation_nodes=${metrics.subtreeReuseRevalidationNodeCount} replayed_nodes=${metrics.subtreeReuseReplayedNodeCount} cache_entries=${metrics.subtreeReuseEntryCount} retained_nodes=${metrics.subtreeReuseRetainedNodeCount} retained_string_bytes=${metrics.subtreeReuseRetainedStringBytes} retained_bytes=${metrics.subtreeReuseRetainedBytes} pending_nodes=${metrics.subtreeReusePendingNodeCount} pending_string_bytes=${metrics.subtreeReusePendingStringBytes} pending_bytes=${metrics.subtreeReusePendingBytes} budget_skips=${metrics.subtreeReuseBudgetSkipCount}")
}

private func runIncrementalLayoutBenchmarkMode(sample: Int64, mode: String, condition: String,
    collectionCount: Int64, optInReuse: Bool, cache: CjguiComposableUiLayoutReuseCache,
    timed: Bool): Bool {
    let baselineBuildStarted = MonoTime.now()
    let baselineTree = incrementalBenchmarkTree(condition, collectionCount, optInReuse, false)
    let baselineBuildNanoseconds = elapsedNanoseconds(baselineBuildStarted)
    let baselineLayoutStarted = MonoTime.now()
    let baseline = if (mode == "canonical_no_cache") {
        CjguiComposableUiLayoutEngine.layoutWithMetrics(
            baselineTree, incrementalBenchmarkViewport(condition, false), 400000 + if (sample >= 0) { sample } else { 0 },
            CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: true)
    } else {
        CjguiComposableUiLayoutEngine.layoutWithMetrics(
            baselineTree, incrementalBenchmarkViewport(condition, false), 400000 + if (sample >= 0) { sample } else { 0 },
            CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: true, reuseCache: cache)
    }
    let baselineLayoutNanoseconds = elapsedNanoseconds(baselineLayoutStarted)
    let targetBuildStarted = MonoTime.now()
    let targetTree = incrementalBenchmarkTree(condition, collectionCount, optInReuse, true)
    let targetBuildNanoseconds = elapsedNanoseconds(targetBuildStarted)
    let targetLayoutStarted = MonoTime.now()
    let result = if (mode == "canonical_no_cache") {
        CjguiComposableUiLayoutEngine.layoutWithMetrics(
            targetTree, incrementalBenchmarkViewport(condition, true), 400000 + if (sample >= 0) { sample } else { 0 },
            CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: true)
    } else {
        CjguiComposableUiLayoutEngine.layoutWithMetrics(
            targetTree, incrementalBenchmarkViewport(condition, true), 400000 + if (sample >= 0) { sample } else { 0 },
            CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: true, reuseCache: cache)
    }
    let targetLayoutNanoseconds = elapsedNanoseconds(targetLayoutStarted)
    // Correctness is deliberately checked after the timed region. Every
    // cache-enabled target must be projection-identical to the same target
    // solved with this pass's cross-pass cache disabled.
    let canonicalTarget = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        targetTree, incrementalBenchmarkViewport(condition, true), 400000 + if (sample >= 0) { sample } else { 0 },
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: true)
    if (!baseline.scene.isValid() || !result.scene.isValid() || !canonicalTarget.scene.isValid() ||
        !sameResolvedProjection(result.scene, canonicalTarget.scene)) { return false }
    if (timed) {
        printIncrementalLayoutBenchmarkSample(sample, mode, condition, collectionCount,
            baselineBuildNanoseconds + targetBuildNanoseconds,
            baselineLayoutNanoseconds + targetLayoutNanoseconds, result)
    }
    return true
}

/// One process owns all samples. Each condition/row pair is warmed once and
/// then sampled with three interleaved modes: canonical has this cache disabled,
/// default_signature explicitly enables the diagnostic structural-signature
/// policy, and opt_in_reuse uses the production explicit-key default. Build and
/// layout are timed separately with MonoTime; validation and printing happen
/// after the timed section.
private func runIncrementalLayoutBenchmark(sampleCount: Int64): Bool {
    let counts = ArrayList<Int64>([24, 248, 760])
    let conditions = ArrayList<String>(["warm", "local", "resize", "font", "scroll", "full_invalidation"])
    for (condition in conditions) {
        for (count in counts) {
            let canonicalCache = CjguiComposableUiLayoutReuseCache()
            let defaultCache = CjguiComposableUiLayoutReuseCache(allowStructuralSignatures: true)
            let optInCache = CjguiComposableUiLayoutReuseCache()
            if (!runIncrementalLayoutBenchmarkMode(-1, "canonical_no_cache", condition, count, false,
                canonicalCache, false) ||
                !runIncrementalLayoutBenchmarkMode(-1, "default_signature", condition, count, false,
                    defaultCache, false) ||
                !runIncrementalLayoutBenchmarkMode(-1, "opt_in_reuse", condition, count, true,
                    optInCache, false)) { return false }
            var sample: Int64 = 0
            while (sample < sampleCount) {
                if (sample % 3 == 0) {
                    if (!runIncrementalLayoutBenchmarkMode(sample, "canonical_no_cache", condition, count, false,
                        canonicalCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "default_signature", condition, count, false,
                            defaultCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "opt_in_reuse", condition, count, true,
                            optInCache, true)) { return false }
                } else if (sample % 3 == 1) {
                    if (!runIncrementalLayoutBenchmarkMode(sample, "opt_in_reuse", condition, count, true,
                        optInCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "canonical_no_cache", condition, count, false,
                            canonicalCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "default_signature", condition, count, false,
                            defaultCache, true)) { return false }
                } else {
                    if (!runIncrementalLayoutBenchmarkMode(sample, "default_signature", condition, count, false,
                        defaultCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "opt_in_reuse", condition, count, true,
                            optInCache, true) ||
                        !runIncrementalLayoutBenchmarkMode(sample, "canonical_no_cache", condition, count, false,
                            canonicalCache, true)) { return false }
                }
                sample += 1
            }
        }
    }
    println("CJGUI_INCREMENTAL_LAYOUT_BENCHMARK_TOTAL samples=${sampleCount} conditions=18 modes=3 samples_per_condition_mode=${sampleCount} records=${sampleCount * 54}")
    return true
}

/// A range-addressable variable-height fixture.  It deliberately keeps only
/// metadata and a direct key index in memory: the long body is constructed
/// solely when the composable list asks for a visible row.  The mutable
/// methods model an owner update that changes one item's content revision,
/// not a second UI-owned document.
private class VariableHeightVirtualListSource <: CjguiComposableUiVariableHeightListSource {
    private let countValue: Int64
    private let indexes: HashMap<String, Int64>
    private var expandedIndex: Int64
    private var externallyChangedIndex: Int64
    private var itemReadCountValue: Int64
    private var buildCountValue: Int64
    private var externallyChangedWasBuiltValue: Bool

    init(count: Int64) {
        this.countValue = if (count > 0) { count } else { 0 }
        this.indexes = HashMap<String, Int64>()
        this.expandedIndex = -1; this.externallyChangedIndex = -1
        this.itemReadCountValue = 0; this.buildCountValue = 0
        this.externallyChangedWasBuiltValue = false
        var index: Int64 = 0
        while (index < countValue) {
            let _ = indexes.add("variable_${index}", index)
            index += 1
        }
    }

    public func itemCount(): Int64 { return countValue }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        itemReadCountValue += 1
        if (index < 0 || index >= countValue) { return CjguiComposableUiVariableHeightListItem.missing() }
        let changed = index == expandedIndex || index == externallyChangedIndex
        let longForm = index % 5 == 0 || changed
        return CjguiComposableUiVariableHeightListItem(
            "variable_${index}", 970000 + index, "可变条目 ${index}",
            if (changed) { 2 } else { 1 }, estimatedHeight: if (changed) { 142 } else if (longForm) { 92 } else { 34 }
        )
    }
    public func indexForKey(key: String): Int64 {
        if (let Some(index) <- indexes.get(key)) { return index }
        return -1
    }
    /// The fixture's type and font do not change.  Per-item revisions above
    /// are intentionally separate so one record mutation cannot invalidate
    /// unrelated measurements.
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        buildCountValue += 1
        let index = indexForKey(item.key)
        let changed = index == expandedIndex || index == externallyChangedIndex
        let row = cjguiComposableVertical(8000000 + item.resourceId, "variable-row-${item.key}",
            CjguiComposableUiStyle(padding: 4, gap: 2,
                background: if (isSelected || isFocused) {
                    CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0)
                } else { CjguiComposableUiColor(0.98, 0.98, 0.99, 1.0) }))
        row.add(cjguiComposableText(8100000 + item.resourceId, "variable-title-${item.key}", item.title,
            CjguiComposableUiStyle(fontWeight: 1)))
        row.add(cjguiComposableText(8200000 + item.resourceId, "variable-summary-${item.key}",
            if (index % 5 == 0 || changed) {
                "这是一段会根据实际列宽自动换行的摘要，用于证明高度来自普通文本子树，而非来源预填的高度数组。"
            } else { "短摘要" }, CjguiComposableUiStyle(fontSize: 12.0)))
        if (index == expandedIndex) {
            row.add(cjguiComposableText(8300000 + item.resourceId, "variable-expanded-${item.key}",
                "展开的字段组也参与同一轮真实测量和最终命中布局。", CjguiComposableUiStyle(fontSize: 12.0)))
        }
        if (index == externallyChangedIndex) {
            externallyChangedWasBuiltValue = true
            row.add(cjguiComposableText(8400000 + item.resourceId, "variable-external-${item.key}",
                "外部 owner 已修改这一屏外条目；现在由人主动滚动后才显示。", CjguiComposableUiStyle(fontSize: 12.0)))
        }
        return row
    }
    public func expandBeforeAnchor(index: Int64): Unit { expandedIndex = index }
    public func applyExternalScreenOffChange(index: Int64): Unit { externallyChangedIndex = index }
    public func buildCount(): Int64 { return buildCountValue }
    public func itemReadCount(): Int64 { return itemReadCountValue }
    public func externallyChangedWasBuilt(): Bool { return externallyChangedWasBuiltValue }
}

/// Deliberately adversarial fixture for the variable range solver.  Its
/// estimate is much taller than the ordinary row subtree, so a correct
/// materializer must continue within its fixed budget until real rows cover
/// the viewport instead of publishing the estimate-only first range.
private class ExactHeightVariableListSource <: CjguiComposableUiVariableHeightListSource {
    private let countValue: Int64
    private let indexes: HashMap<String, Int64>
    private let actualHeightValue: Int64
    private let alternateHeightValue: Int64
    private let estimatedHeightValue: Int64
    private var firstBuildCountValue: Int64
    private var lastBuildCountValue: Int64

    init(count: Int64, actualHeight: Int64, estimatedHeight: Int64, alternateHeight!: Int64 = 0) {
        this.countValue = if (count > 0) { count } else { 0 }
        this.indexes = HashMap<String, Int64>()
        this.actualHeightValue = if (actualHeight > 0) { actualHeight } else { 1 }
        this.estimatedHeightValue = if (estimatedHeight > 0) { estimatedHeight } else { 1 }
        this.alternateHeightValue = if (alternateHeight > 0) { alternateHeight } else { 0 }
        this.firstBuildCountValue = 0; this.lastBuildCountValue = 0
        var index: Int64 = 0
        while (index < countValue) {
            let _ = indexes.add("exact_${index}", index)
            index += 1
        }
    }

    public func itemCount(): Int64 { return countValue }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        return if (index >= 0 && index < countValue) {
            CjguiComposableUiVariableHeightListItem("exact_${index}", 995000 + index, "精确高度 ${index}", 1,
                estimatedHeight: estimatedHeightValue)
        } else { CjguiComposableUiVariableHeightListItem.missing() }
    }
    public func indexForKey(key: String): Int64 {
        if (let Some(index) <- indexes.get(key)) { return index }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let index = indexForKey(item.key)
        if (index == 0) { firstBuildCountValue += 1 }
        if (index == countValue - 1) { lastBuildCountValue += 1 }
        return cjguiComposableText(9900000 + item.resourceId, "exact-row-${item.key}", item.title,
            CjguiComposableUiStyle(fixedHeight: if (alternateHeightValue > 0 && index % 2 == 1) {
                alternateHeightValue
            } else { actualHeightValue }))
    }
    public func firstBuildCount(): Int64 { return firstBuildCountValue }
    public func lastBuildCount(): Int64 { return lastBuildCountValue }
}

/// Small mutable source for the variable path's stable-anchor fallback. The
/// test keeps this lookup intentionally tiny; scale evidence uses the direct
/// indexed fixture above instead of hiding a full scan in navigation.
private class MutableVariableHeightListSource <: CjguiComposableUiVariableHeightListSource {
    private var hasPrefix: Bool
    private var removedId: Int64
    init() { this.hasPrefix = false; this.removedId = -1 }
    public func prepend(): Unit { hasPrefix = true }
    public func remove(id: Int64): Unit { removedId = id }
    public func itemCount(): Int64 { return 5 + if (hasPrefix) { 1 } else { 0 } - if (removedId >= 0) { 1 } else { 0 } }
    private func idAt(index: Int64): Int64 {
        if (index < 0 || index >= itemCount()) { return -1 }
        if (hasPrefix && index == 0) { return 99 }
        var id = if (hasPrefix) { index - 1 } else { index }
        if (removedId >= 0 && id >= removedId) { id += 1 }
        return id
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        let id = idAt(index)
        return if (id >= 0) {
            CjguiComposableUiVariableHeightListItem("mutable_${id}", 980000 + id, "可变身份 ${id}", 1,
                estimatedHeight: if (id % 2 == 0) { 72 } else { 34 })
        } else { CjguiComposableUiVariableHeightListItem.missing() }
    }
    public func indexForKey(key: String): Int64 {
        var index: Int64 = 0
        while (index < itemCount()) {
            if (itemAt(index).key == key) { return index }
            index += 1
        }
        return -1
    }
    public func measurementGeneration(): Int64 { return 1 }
    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool,
        isFocused: Bool): CjguiComposableUiNode {
        let row = cjguiComposableVertical(8500000 + item.resourceId, "mutable-row-${item.key}",
            CjguiComposableUiStyle(padding: 4, background: if (isSelected || isFocused) {
                CjguiComposableUiColor(0.20, 0.45, 0.82, 1.0)
            } else { CjguiComposableUiColor(0.98, 0.98, 0.99, 1.0) }))
        row.add(cjguiComposableText(8600000 + item.resourceId, "mutable-title-${item.key}", item.title,
            CjguiComposableUiStyle()))
        if (item.resourceId % 2 == 0) {
            row.add(cjguiComposableText(8700000 + item.resourceId, "mutable-detail-${item.key}",
                "一个较长的可换行说明，用于让相邻项拥有不同的真实行高。", CjguiComposableUiStyle(fontSize: 12.0)))
        }
        return row
    }
}

main(args: Array<String>): Int64 {
    let incrementalBenchmarkMode = args.size == 1 && args[0] == "--incremental-layout-benchmark"
    if (args.size != 0 && !incrementalBenchmarkMode) { return 2 }
    if (incrementalBenchmarkMode) {
        return if (runIncrementalLayoutBenchmark(30)) { 0 } else { 73 }
    }
    let root = cjguiComposableVertical(
        1, "root", CjguiComposableUiStyle(background: CjguiComposableUiColor(0.94, 0.95, 0.97, 1.0), padding: 12, gap: 10)
    )
    let header = cjguiComposableHorizontal(
        2, "header", CjguiComposableUiStyle(fixedHeight: 34, gap: 8)
    )
    header.add(cjguiComposableText(3, "title", "规则集", CjguiComposableUiStyle(growX: 1)))
    header.add(cjguiComposableButton(4, "create", "新增", "CREATE_RECORD", 0, CjguiComposableUiStyle(fixedWidth: 72, fixedHeight: 30)))
    header.add(cjguiComposableButton(5, "save", "保存", "SAVE_RULE_SET", 0, CjguiComposableUiStyle(fixedWidth: 72, fixedHeight: 30)))
    root.add(header)

    let scrolling = cjguiComposableScrollArea(
        6, "records", 236,
        CjguiComposableUiStyle(fixedHeight: 96, background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0), border: CjguiComposableUiColor(0.72, 0.74, 0.78, 1.0))
    )
    let records = cjguiComposableVertical(7, "record-list", CjguiComposableUiStyle(gap: 4))
    var index: Int64 = 0
    while (index < 12) {
        records.add(cjguiComposableButton(
            100 + index, "record-${index}", "规则 ${index}", "SELECT_RECORD", 9000 + index,
            CjguiComposableUiStyle(fixedHeight: 24, background: CjguiComposableUiColor(0.98, 0.98, 0.99, 1.0), border: CjguiComposableUiColor(0.78, 0.80, 0.84, 1.0)),
            operationActionName: "SELECT_RECORD"
        ))
        index += 1
    }
    scrolling.add(records)
    root.add(scrolling)

    let scene = CjguiComposableUiLayoutEngine.layout(root, CjguiComposableUiRect(0, 0, 420, 180), 41)
    if (!require(scene.version == 41 && scene.nodes().size == 19, "scene_count_and_version")) { return 1 }
    if (!require(scene.nodeForId(4).bounds.width == 72 && scene.nodeForId(3).bounds.width > 100, "fixed_and_grow_width")) { return 1 }
    let last = scene.nodeForId(111)
    if (!require(last.bounds.height == 24 && scene.nodeForId(6).clip.height == 96 && last.clip.height == 24, "scroll_clip_geometry")) { return 1 }
    if (!require(scene.hitTest(last.bounds.x + 4, last.bounds.y + 4).nodeId == 111, "scrolled_hit_target")) { return 1 }
    if (!require(scene.resolveInput(111, 9011, CJGUI_COMPOSABLE_UI_BUTTON, 41).actionName == "SELECT_RECORD", "stable_semantic_target")) { return 1 }
    if (!require(scene.resolveInput(111, 9011, CJGUI_COMPOSABLE_UI_BUTTON, 40).nodeId == -1, "stale_projection_rejected")) { return 1 }
    if (!require(scene.resolveInput(111, 9011, CJGUI_COMPOSABLE_UI_BUTTON, 41).actionName == "SELECT_RECORD" &&
        scene.resolveInput(111, 9012, CJGUI_COMPOSABLE_UI_BUTTON, 41).nodeId == -1 &&
        scene.resolveInput(111, 9011, CJGUI_COMPOSABLE_UI_TEXT_INPUT, 41).nodeId == -1,
        "resource_and_kind_identity_rejected")) { return 1 }
    if (!require(scene.hitTest(410, 170).nodeId == -1, "clip_excludes_outside_content")) { return 1 }

    // RED: composite internals must not derive `nodeId + offset` from a
    // caller-owned number. A window-owned candidate registry resolves the
    // scoped container/handle pair only after the full declaration exists;
    // distinct child scopes may reuse the same local keys, while a duplicate
    // within one scope and an explicit manual/scoped collision remain
    // diagnosable failures rather than a silent overwritten scene node.
    let identityRegistry = CjguiComposableUiIdentityRegistry()
    let identityRoot = cjguiComposableVertical(7000, "identity-root", CjguiComposableUiStyle())
    let identityScope = CjguiComposableUiIdentityScope("layout-safe-split")
    identityRoot.add(cjguiComposableScopedSplitView(identityScope,
        "identity-safe-split",
        cjguiComposableButton(7001, "identity-left", "左侧", "LEFT", 1,
            CjguiComposableUiStyle(fixedHeight: 20)),
        cjguiComposableButton(22, "identity-manual-22", "右侧", "RIGHT", 2,
            CjguiComposableUiStyle(fixedHeight: 20)),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    let identityStarted = identityRegistry.beginCandidate()
    let identityIssue = identityRegistry.resolveCandidate(identityRoot)
    let identityPrepared = identityRegistry.prepareCandidate()
    let identityScene = CjguiComposableUiLayoutEngine.layout(
        identityRoot, CjguiComposableUiRect(0, 0, 240, 80), 42)
    let identityHandle = sceneNodeForSemanticId(identityScene, "identity-safe-split-handle")
    identityRegistry.commitCandidate()
    if (!require(identityStarted && identityIssue == "" && identityPrepared && identityScene.isValid() &&
        identityScene.nodeForId(22).semanticId == "identity-manual-22" && identityHandle.nodeId > 0 &&
        identityHandle.nodeId != 22 && identityRegistry.liveCount() == 2,
        "scoped_split_resolves_internal_nodes_without_claiming_manual_ids")) { return 1 }

    let siblingRoot = cjguiComposableVertical(7010, "identity-siblings", CjguiComposableUiStyle())
    siblingRoot.add(cjguiComposableScopedSplitView(identityScope.child("first"), "identity-first-split",
        cjguiComposableText(7011, "identity-first-left", "一", CjguiComposableUiStyle()),
        cjguiComposableText(7012, "identity-first-right", "二", CjguiComposableUiStyle()),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    siblingRoot.add(cjguiComposableScopedSplitView(identityScope.child("second"), "identity-second-split",
        cjguiComposableText(7013, "identity-second-left", "三", CjguiComposableUiStyle()),
        cjguiComposableText(7014, "identity-second-right", "四", CjguiComposableUiStyle()),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    let siblingsStarted = identityRegistry.beginCandidate()
    let siblingsIssue = identityRegistry.resolveCandidate(siblingRoot)
    let siblingsPrepared = identityRegistry.prepareCandidate()
    let siblingsScene = CjguiComposableUiLayoutEngine.layout(
        siblingRoot, CjguiComposableUiRect(0, 0, 240, 120), 43)
    let firstScopedHandleId = sceneNodeForSemanticId(siblingsScene, "identity-first-split-handle").nodeId
    let secondScopedHandleId = sceneNodeForSemanticId(siblingsScene, "identity-second-split-handle").nodeId
    identityRegistry.commitCandidate()
    if (!require(siblingsStarted && siblingsIssue == "" && siblingsPrepared && siblingsScene.isValid() &&
        firstScopedHandleId > 0 && secondScopedHandleId > 0 && firstScopedHandleId != secondScopedHandleId,
        "child_scopes_reuse_local_component_keys_without_collision")) { return 1 }

    let identityDuplicateRoot = cjguiComposableVertical(7020, "identity-duplicate", CjguiComposableUiStyle())
    let duplicateScope = identityScope.child("duplicate")
    identityDuplicateRoot.add(cjguiComposableScopedSplitView(duplicateScope, "identity-duplicate-a",
        cjguiComposableText(7021, "identity-duplicate-a-left", "甲", CjguiComposableUiStyle()),
        cjguiComposableText(7022, "identity-duplicate-a-right", "乙", CjguiComposableUiStyle()),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    identityDuplicateRoot.add(cjguiComposableScopedSplitView(duplicateScope, "identity-duplicate-b",
        cjguiComposableText(7023, "identity-duplicate-b-left", "丙", CjguiComposableUiStyle()),
        cjguiComposableText(7024, "identity-duplicate-b-right", "丁", CjguiComposableUiStyle()),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    let duplicateStarted = identityRegistry.beginCandidate()
    let duplicateIssue = identityRegistry.resolveCandidate(identityDuplicateRoot)
    identityRegistry.rollbackCandidate()
    let collisionRoot = cjguiComposableVertical(7030, "identity-manual-collision", CjguiComposableUiStyle())
    collisionRoot.add(cjguiComposableButton(firstScopedHandleId, "identity-manual-collision-button", "冲突", "COLLIDE", 3,
        CjguiComposableUiStyle(fixedHeight: 20)))
    collisionRoot.add(cjguiComposableScopedSplitView(identityScope.child("first"), "identity-first-reused",
        cjguiComposableText(7031, "identity-first-reused-left", "戊", CjguiComposableUiStyle()),
        cjguiComposableText(7032, "identity-first-reused-right", "己", CjguiComposableUiStyle()),
        CjguiComposableUiSplitAxis.HORIZONTAL, 80, 20, 20, CjguiComposableUiStyle()))
    let collisionStarted = identityRegistry.beginCandidate()
    let collisionIssue = identityRegistry.resolveCandidate(collisionRoot)
    identityRegistry.rollbackCandidate()
    if (!require(duplicateStarted &&
        duplicateIssue == "identity_duplicate_scope_layout-safe-split--duplicate_key_container" && collisionStarted &&
        collisionIssue == "identity_manual_scope_key_layout-safe-split--first--handle",
        "scoped_identity_reports_duplicate_key_and_manual_collision")) { return 1 }

    // RED: local keys must follow the same safe-token rule as scope segments.
    // Otherwise a later diagnostic would splice arbitrary caller text into an
    // externally projected failure string. A full accepted table must also
    // reject a new-first candidate before it can exceed the public capacity.
    let boundaryScope = CjguiComposableUiIdentityScope("identity-boundary")
    if (!require(!boundaryScope.local("has space").isValid() && !boundaryScope.local("line\nbreak").isValid() &&
        !boundaryScope.local("中文").isValid(), "scoped_identity_rejects_unsafe_local_keys")) { return 1 }
    let capacityRegistry = CjguiComposableUiIdentityRegistry()
    let capacityAcceptedRoot = cjguiComposableVertical(7040, "identity-capacity-accepted", CjguiComposableUiStyle())
    var capacityIndex: Int64 = 0
    while (capacityIndex < 1024) {
        capacityAcceptedRoot.add(CjguiComposableUiNode(-1, "identity-capacity-old-${capacityIndex}",
            CJGUI_COMPOSABLE_UI_TEXT, "", "", "", -1, CjguiComposableUiStyle(),
            identity: Some(boundaryScope.local("old-${capacityIndex}"))))
        capacityIndex += 1
    }
    let capacityAccepted = capacityRegistry.beginCandidate() && capacityRegistry.resolveCandidate(capacityAcceptedRoot).size == 0 &&
        capacityRegistry.prepareCandidate()
    if (capacityAccepted) { capacityRegistry.commitCandidate() } else { capacityRegistry.rollbackCandidate() }
    let capacityNewFirstRoot = cjguiComposableVertical(7041, "identity-capacity-new-first", CjguiComposableUiStyle())
    capacityNewFirstRoot.add(CjguiComposableUiNode(-1, "identity-capacity-new", CJGUI_COMPOSABLE_UI_TEXT, "", "", "", -1,
        CjguiComposableUiStyle(), identity: Some(boundaryScope.local("new"))))
    capacityIndex = 0
    while (capacityIndex < 1024) {
        capacityNewFirstRoot.add(CjguiComposableUiNode(-1, "identity-capacity-old-again-${capacityIndex}",
            CJGUI_COMPOSABLE_UI_TEXT, "", "", "", -1, CjguiComposableUiStyle(),
            identity: Some(boundaryScope.local("old-${capacityIndex}"))))
        capacityIndex += 1
    }
    let capacityNewFirstStarted = capacityRegistry.beginCandidate()
    let capacityNewFirstIssue = capacityRegistry.resolveCandidate(capacityNewFirstRoot)
    capacityRegistry.rollbackCandidate()
    if (!require(capacityAccepted && capacityRegistry.liveCount() == 1024 && capacityNewFirstStarted &&
        capacityNewFirstIssue == "identity_capacity_scope_key_identity-boundary--old-1023",
        "scoped_identity_capacity_rejects_new_first_candidate_without_mutating_accepted")) { return 1 }

    // RED: visible variable-height rows are built after root identity
    // resolution. They must still participate in the same candidate, retain
    // their scoped action through a reorder, and get a fresh node after an
    // accepted remove/re-add instead of reviving a delayed event target.
    let scopedVariableSource = ScopedVariableListSource()
    let scopedVariableState = CjguiComposableUiVirtualListState()
    let scopedVariableRegistry = CjguiComposableUiIdentityRegistry()
    let scopedVariableFirstRoot = scopedVariableRoot(scopedVariableSource, scopedVariableState, 7050)
    let scopedVariableFirstStarted = scopedVariableRegistry.beginCandidate()
    let scopedVariableFirstRootIssue = scopedVariableRegistry.resolveCandidate(scopedVariableFirstRoot)
    let scopedVariableFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(scopedVariableFirstRoot,
        CjguiComposableUiRect(0, 0, 180, 120), 91, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(scopedVariableRegistry))
    let scopedVariableFirstPrepared = scopedVariableRegistry.prepareCandidate()
    if (scopedVariableFirstPrepared) { scopedVariableRegistry.commitCandidate() } else { scopedVariableRegistry.rollbackCandidate() }
    let firstMenuId = sceneNodeForSemanticId(scopedVariableFirst.scene, "scoped-card-menu-scoped_0").nodeId
    let firstMenuTrigger = sceneNodeForSemanticId(scopedVariableFirst.scene, "scoped-card-menu-scoped_0")
    let firstMenuPopup = sceneNodeForSemanticId(scopedVariableFirst.scene, "scoped-card-popup-scoped_0")
    scopedVariableSource.reverse()
    let scopedVariableReorderedRoot = scopedVariableRoot(scopedVariableSource, scopedVariableState, 7053)
    let scopedVariableReorderedStarted = scopedVariableRegistry.beginCandidate()
    let scopedVariableReorderedRootIssue = scopedVariableRegistry.resolveCandidate(scopedVariableReorderedRoot)
    let scopedVariableReordered = CjguiComposableUiLayoutEngine.layoutWithMetrics(scopedVariableReorderedRoot,
        CjguiComposableUiRect(0, 0, 180, 120), 92, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(scopedVariableRegistry))
    let scopedVariableReorderedPrepared = scopedVariableRegistry.prepareCandidate()
    if (scopedVariableReorderedPrepared) { scopedVariableRegistry.commitCandidate() } else { scopedVariableRegistry.rollbackCandidate() }
    let reorderedMenuId = sceneNodeForSemanticId(scopedVariableReordered.scene, "scoped-card-menu-scoped_0").nodeId
    let reorderedMenuTrigger = sceneNodeForSemanticId(scopedVariableReordered.scene, "scoped-card-menu-scoped_0")
    let reorderedMenuPopup = sceneNodeForSemanticId(scopedVariableReordered.scene, "scoped-card-popup-scoped_0")
    scopedVariableSource.removeFirst()
    let scopedVariableRemovedRoot = scopedVariableRoot(scopedVariableSource, scopedVariableState, 7056)
    let scopedVariableRemovedStarted = scopedVariableRegistry.beginCandidate()
    let scopedVariableRemovedRootIssue = scopedVariableRegistry.resolveCandidate(scopedVariableRemovedRoot)
    let scopedVariableRemoved = CjguiComposableUiLayoutEngine.layoutWithMetrics(scopedVariableRemovedRoot,
        CjguiComposableUiRect(0, 0, 180, 120), 93, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(scopedVariableRegistry))
    let scopedVariableRemovedPrepared = scopedVariableRegistry.prepareCandidate()
    if (scopedVariableRemovedPrepared) { scopedVariableRegistry.commitCandidate() } else { scopedVariableRegistry.rollbackCandidate() }
    scopedVariableSource.restoreFirst()
    let scopedVariableReaddedRoot = scopedVariableRoot(scopedVariableSource, scopedVariableState, 7059)
    let scopedVariableReaddedStarted = scopedVariableRegistry.beginCandidate()
    let scopedVariableReaddedRootIssue = scopedVariableRegistry.resolveCandidate(scopedVariableReaddedRoot)
    let scopedVariableReadded = CjguiComposableUiLayoutEngine.layoutWithMetrics(scopedVariableReaddedRoot,
        CjguiComposableUiRect(0, 0, 180, 120), 94, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(scopedVariableRegistry))
    let scopedVariableReaddedPrepared = scopedVariableRegistry.prepareCandidate()
    if (scopedVariableReaddedPrepared) { scopedVariableRegistry.commitCandidate() } else { scopedVariableRegistry.rollbackCandidate() }
    let readdedMenuId = sceneNodeForSemanticId(scopedVariableReadded.scene, "scoped-card-menu-scoped_0").nodeId
    if (!require(scopedVariableFirstStarted && scopedVariableFirstRootIssue == "" && scopedVariableFirst.scene.isValid() &&
        scopedVariableFirstPrepared && firstMenuId > 0 && scopedVariableReorderedStarted &&
        scopedVariableReorderedRootIssue == "" && scopedVariableReordered.scene.isValid() &&
        scopedVariableReorderedPrepared && reorderedMenuId == firstMenuId && firstMenuPopup.nodeId > 0 &&
        firstMenuPopup.bounds.x == firstMenuTrigger.bounds.x &&
        firstMenuPopup.bounds.y >= firstMenuTrigger.bounds.y - firstMenuPopup.bounds.height &&
        firstMenuPopup.bounds.y <= firstMenuTrigger.bounds.y + firstMenuTrigger.bounds.height &&
        reorderedMenuPopup.bounds.x == reorderedMenuTrigger.bounds.x &&
        reorderedMenuPopup.bounds.y >= reorderedMenuTrigger.bounds.y - reorderedMenuPopup.bounds.height &&
        reorderedMenuPopup.bounds.y <= reorderedMenuTrigger.bounds.y + reorderedMenuTrigger.bounds.height &&
        scopedVariableRemovedStarted &&
        scopedVariableRemovedRootIssue == "" && scopedVariableRemoved.scene.isValid() && scopedVariableRemovedPrepared &&
        scopedVariableRemoved.scene.nodeForId(firstMenuId).nodeId < 0 && scopedVariableReaddedStarted &&
        scopedVariableReaddedRootIssue == "" && scopedVariableReadded.scene.isValid() && scopedVariableReaddedPrepared &&
        readdedMenuId > 0 && readdedMenuId != firstMenuId,
        "variable_height_scoped_rows_and_references_resolve_with_candidate_reorder_remove_and_readd")) { return 1 }

    // RED: layers must be able to name a stable scoped declaration instead
    // of forcing component authors to pre-compute numeric node IDs.  A
    // missing declaration is a candidate failure, never an arbitrary anchor
    // chosen by layout order.
    let referenceScope = CjguiComposableUiIdentityScope("declarative-reference").child("card")
    let referenceRoot = cjguiComposableLayerHost(7060, "declarative-reference-host", CjguiComposableUiStyle())
    let referenceBase = cjguiComposableVertical(7061, "declarative-reference-base", CjguiComposableUiStyle(gap: 4))
    referenceBase.add(CjguiComposableUiNode(-1, "declarative-reference-trigger", CJGUI_COMPOSABLE_UI_BUTTON,
        "菜单", "", "OPEN", 701, CjguiComposableUiStyle(fixedWidth: 64, fixedHeight: 24),
        identity: Some(referenceScope.local("menu-trigger"))))
    referenceBase.add(CjguiComposableUiNode(-1, "declarative-reference-field", CJGUI_COMPOSABLE_UI_TEXT_INPUT,
        "名称", "", "EDIT", 701, CjguiComposableUiStyle(fixedWidth: 120, fixedHeight: 28),
        identity: Some(referenceScope.local("editor-name"))))
    referenceRoot.add(referenceBase)
    let referenceMenu = cjguiComposableAnchoredLayerWithReference(7062, "declarative-reference-menu", "reference-menu",
        "menu", "card", CjguiComposableUiNodeReference.scoped(referenceScope, "menu-trigger"),
        CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 32))
    referenceMenu.add(cjguiComposableText(7063, "declarative-reference-menu-copy", "操作", CjguiComposableUiStyle()))
    let referenceDialog = cjguiComposableDialogLayerWithReference(7064, "declarative-reference-dialog", "reference-dialog",
        "card", CjguiComposableUiNodeReference.scoped(referenceScope, "menu-trigger"),
        CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 72),
        initialFocus: Some(CjguiComposableUiNodeReference.scoped(referenceScope, "editor-name")))
    referenceDialog.add(cjguiComposableText(7065, "declarative-reference-dialog-copy", "编辑", CjguiComposableUiStyle()))
    referenceRoot.add(referenceMenu); referenceRoot.add(referenceDialog)
    let referenceRegistry = CjguiComposableUiIdentityRegistry()
    let referenceStarted = referenceRegistry.beginCandidate()
    let referenceRootIssue = referenceRegistry.resolveCandidate(referenceRoot)
    let referenceScene = CjguiComposableUiLayoutEngine.layoutWithMetrics(referenceRoot,
        CjguiComposableUiRect(0, 0, 220, 140), 95, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(referenceRegistry))
    let referencePrepared = referenceRegistry.prepareCandidate()
    if (referencePrepared) { referenceRegistry.commitCandidate() } else { referenceRegistry.rollbackCandidate() }
    let referenceTrigger = sceneNodeForSemanticId(referenceScene.scene, "declarative-reference-trigger")
    let referenceMenuNode = sceneNodeForSemanticId(referenceScene.scene, "declarative-reference-menu")
    let referenceField = sceneNodeForSemanticId(referenceScene.scene, "declarative-reference-field")
    let referenceDialogNode = sceneNodeForSemanticId(referenceScene.scene, "declarative-reference-dialog")
    let missingReferenceRoot = cjguiComposableLayerHost(7066, "declarative-reference-missing-host", CjguiComposableUiStyle())
    missingReferenceRoot.add(cjguiComposableVertical(7067, "declarative-reference-missing-base", CjguiComposableUiStyle()))
    missingReferenceRoot.add(cjguiComposableAnchoredLayerWithReference(7068, "declarative-reference-missing-menu",
        "missing-reference-menu", "menu", "card", CjguiComposableUiNodeReference.scoped(referenceScope, "missing"),
        CjguiComposableUiStyle(fixedWidth: 80, fixedHeight: 32)))
    let missingReferenceStarted = referenceRegistry.beginCandidate()
    let missingReferenceRootIssue = referenceRegistry.resolveCandidate(missingReferenceRoot)
    let missingReferenceScene = CjguiComposableUiLayoutEngine.layoutWithMetrics(missingReferenceRoot,
        CjguiComposableUiRect(0, 0, 220, 140), 96, CjguiComposableUiFallbackTextMeasurer(),
        identityRegistry: Some(referenceRegistry))
    let missingReferencePrepared = referenceRegistry.prepareCandidate()
    let missingReferenceIssue = referenceRegistry.lastIssue()
    referenceRegistry.rollbackCandidate()
    if (!require(referenceStarted && referenceRootIssue == "" && referenceScene.scene.isValid() && referencePrepared &&
        referenceMenuNode.bounds.y == referenceTrigger.bounds.y + referenceTrigger.bounds.height &&
        referenceDialogNode.nodeId >= 0 && referenceField.nodeId >= 0 && referenceRegistry.liveCount() == 2 &&
        missingReferenceStarted && missingReferenceRootIssue == "" && missingReferenceScene.scene.isValid() &&
        !missingReferencePrepared && missingReferenceIssue == "identity_reference_missing_scope_declarative-reference--card_key_missing" &&
        referenceRegistry.liveCount() == 2,
        "declarative_scoped_layer_references_resolve_and_missing_target_preserves_accepted")) { return 1 }

    // Rounded clipping is resolved once in the platform-free scene. The
    // native renderer receives this scalar beside the same clip rectangle;
    // it does not infer a separate AppKit containment hierarchy.
    let roundedRoot = cjguiComposableVertical(2000, "rounded-root", CjguiComposableUiStyle(
        padding: 8, cornerRadius: 20, clipsContent: true
    ))
    roundedRoot.add(cjguiComposableButton(2001, "rounded-child", "覆盖", "COVER", 1,
        CjguiComposableUiStyle(fixedHeight: 32, cornerRadius: 6)))
    let roundedScene = CjguiComposableUiLayoutEngine.layout(roundedRoot, CjguiComposableUiRect(0, 0, 200, 100), 411)
    let roundedChild = roundedScene.nodeForId(2001)
    if (!require(roundedScene.nodeForId(2000).style.cornerRadius == 20 && roundedChild.clip.x == 8 &&
        roundedChild.clip.y == 8 && roundedChild.clip.width == 184 && roundedChild.clip.height == 32 &&
        roundedChild.clipCornerRadius == 12,
        "rounded_style_and_child_clip_are_canonical_scene_data")) { return 1 }

    // A rounded ancestor keeps its original centre and radius. The centred
    // child below has a small rectangular intersection, so assigning the
    // ancestor radius to that smaller rectangle would incorrectly reject its
    // own top-left corner.
    let roundedCentreRoot = cjguiComposableVertical(2010, "rounded-centre-root", CjguiComposableUiStyle(
        cornerRadius: 40, clipsContent: true
    ))
    roundedCentreRoot.add(cjguiComposableVertical(2011, "rounded-centre-spacer", CjguiComposableUiStyle(fixedHeight: 60)))
    roundedCentreRoot.add(cjguiComposableButton(2012, "rounded-centre-child", "中心", "CENTER", 2012,
        CjguiComposableUiStyle(fixedWidth: 60, fixedHeight: 60, alignX: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)))
    let roundedCentreScene = CjguiComposableUiLayoutEngine.layout(roundedCentreRoot, CjguiComposableUiRect(0, 0, 200, 200), 412)
    let centredChild = roundedCentreScene.nodeForId(2012)
    if (!require(centredChild.bounds.x == 70 && centredChild.bounds.y == 60 &&
        centredChild.containsResolvedClip(70, 60) && roundedCentreScene.hitTest(70, 60).nodeId == 2012,
        "rounded_ancestor_does_not_round_centre_child_intersection")) { return 1 }

    // A later square clipping container must not erase the original rounded
    // ancestor. Its upper-left grandchild remains outside the ancestor's
    // corner even though it is inside the newer rectangular clip.
    let retainedAncestorRoot = cjguiComposableVertical(2020, "retained-ancestor-root", CjguiComposableUiStyle(
        cornerRadius: 40, clipsContent: true
    ))
    let squareClip = cjguiComposableVertical(2021, "square-descendant-clip", CjguiComposableUiStyle(
        growY: 1, clipsContent: true
    ))
    squareClip.add(cjguiComposableButton(2022, "ancestor-corner-child", "角", "CORNER", 2022,
        CjguiComposableUiStyle(fixedHeight: 40)))
    retainedAncestorRoot.add(squareClip)
    let retainedAncestorScene = CjguiComposableUiLayoutEngine.layout(retainedAncestorRoot, CjguiComposableUiRect(0, 0, 200, 200), 413)
    let cornerChild = retainedAncestorScene.nodeForId(2022)
    if (!require(cornerChild.clipConstraints().size == 3 && !cornerChild.containsResolvedClip(2, 2) &&
        retainedAncestorScene.hitTest(2, 2).nodeId == -1 && retainedAncestorScene.hitTest(80, 20).nodeId == 2022,
        "nested_clip_chain_retains_rounded_ancestor")) { return 1 }

    // The tree that produces the rendered scene must also produce the read-
    // only component context. No consumer-maintained relation table is read.
    let componentProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(
        root,
        scene,
        focusedNodeId: 100,
        selectionStart: 2,
        selectionEnd: 2
    )
    if (!require(componentProjection.isActive && componentProjection.sceneVersion == 41 &&
        componentProjection.presentationState == "unavailable" &&
        hasProjectionNode(componentProjection.nodes, "record-0", 100, "control") &&
        hasProjectionRelation(componentProjection.relations, "group", "record-list", "CONTAINS", "control", "record-0") &&
        hasProjectionRelation(componentProjection.relations, "control", "record-0", "TARGETS", "resource", "resource9000") &&
        hasProjectionRelation(componentProjection.relations, "control", "record-0", "INVOKES", "action", "SELECT_RECORD"),
        "component_tree_derives_window_context")) { return 1 }

    // A controller may keep a stable field slot for dispatch while the actual
    // business target is the selected record. Context must publish the latter.
    let routedRoot = cjguiComposableVertical(800, "routed-root", CjguiComposableUiStyle())
    routedRoot.add(cjguiComposableTextInput(801, "routed-label", "名称", "草稿", 81001,
        CjguiComposableUiStyle(), fieldId: "label", operationActionName: "EDIT_DRAFT_TEXT", operationResourceId: 42))
    let routedScene = CjguiComposableUiLayoutEngine.layout(routedRoot, CjguiComposableUiRect(0, 0, 220, 80), 45)
    let routedProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(routedRoot, routedScene)
    if (!require(hasProjectionRelation(routedProjection.relations, "control", "routed-label", "TARGETS", "resource", "resource42") &&
        hasProjectionRelation(routedProjection.relations, "control", "routed-label", "BINDS", "field", "resource42_label"),
        "operation_target_overrides_local_field_slot")) { return 1 }

    // An empty grouping node is a normal result of conditional composition.
    // It must occupy its padding only rather than recursively measuring itself.
    let emptyRoot = cjguiComposableVertical(500, "empty-root", CjguiComposableUiStyle(padding: 4, gap: 3))
    emptyRoot.add(cjguiComposableVertical(501, "conditionally-empty-column", CjguiComposableUiStyle(padding: 6)))
    emptyRoot.add(cjguiComposableHorizontal(502, "conditionally-empty-row", CjguiComposableUiStyle(padding: 8)))
    let emptyScene = CjguiComposableUiLayoutEngine.layout(emptyRoot, CjguiComposableUiRect(0, 0, 160, 100), 42)
    if (!require(emptyScene.nodes().size == 3 && emptyScene.nodeForId(501).bounds.height == 12 &&
        emptyScene.nodeForId(502).bounds.height == 16, "empty_container_measurement")) { return 1 }

    // Intrinsic width must follow the actual declared text instead of a
    // constant placeholder: consumers may compose fields in either language.
    let measured = cjguiComposableHorizontal(600, "measured", CjguiComposableUiStyle(gap: 2))
    measured.add(cjguiComposableText(601, "short", "A", CjguiComposableUiStyle()))
    measured.add(cjguiComposableText(602, "long", "通知阈值配置", CjguiComposableUiStyle()))
    let measuredScene = CjguiComposableUiLayoutEngine.layout(measured, CjguiComposableUiRect(0, 0, 400, 40), 43)
    if (!require(measuredScene.nodeForId(602).bounds.width > measuredScene.nodeForId(601).bounds.width, "text_intrinsic_measurement")) { return 1 }

    // The public style descriptor selects only supported system families and
    // fails closed to system instead of forwarding arbitrary native names.
    let monospaceStyle = CjguiComposableUiStyle(fontFamily: "monospaced")
    let fallbackFontStyle = CjguiComposableUiStyle(fontFamily: "unsupported-font")
    if (!require(monospaceStyle.fontFamily == "monospaced" && fallbackFontStyle.fontFamily == "system", "bounded_font_family_fallback")) { return 1 }

    // Native input may arrive continuously. A UI turn must put a finite
    // ceiling on one drain so rendering and external connection work cannot
    // be starved by a full FIFO.
    let drainBudget = CjguiComposableUiEventDrainBudget()
    var acceptedEvents: Int64 = 0
    while (drainBudget.consumeOne()) { acceptedEvents += 1 }
    if (!require(acceptedEvents == 64 && !drainBudget.consumeOne(), "bounded_event_drain")) { return 1 }

    // Disabled controls and read-only fields are semantically distinct from
    // merely hidden nodes: neither can be resolved as an edit target.
    let interactionRoot = cjguiComposableVertical(700, "interaction-root", CjguiComposableUiStyle())
    interactionRoot.add(cjguiComposableButton(701, "disabled-action", "不可用", "DO_NOT_RUN", 1,
        CjguiComposableUiStyle(), enabled: false))
    interactionRoot.add(cjguiComposableTextInput(702, "read-only-field", "只读", "不可编辑", 1,
        CjguiComposableUiStyle(), readOnly: true))
    let interactionScene = CjguiComposableUiLayoutEngine.layout(interactionRoot, CjguiComposableUiRect(0, 0, 240, 100), 44)
    if (!require(!interactionScene.nodeForId(701).isEnabled && interactionScene.nodeForId(702).isReadOnly &&
        interactionScene.resolveInput(701, 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT, 44).nodeId == -1 && interactionScene.resolveInput(702, 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT, 44).nodeId == -1,
        "disabled_and_read_only_input_boundaries")) { return 1 }
    if (!require(interactionScene.nodeForId(702).canReceiveFocus() &&
        interactionScene.resolveSelection(702, 1, CJGUI_COMPOSABLE_UI_TEXT_INPUT, 44).nodeId == 702 &&
        interactionScene.resolveSelection(702, 2, CJGUI_COMPOSABLE_UI_TEXT_INPUT, 44).nodeId == -1,
        "read_only_text_selection_without_editing")) { return 1 }

    // A document editor is one composable control, not a page-wide native
    // product. It keeps a multi-line value, participates in the same stable
    // input resolution, and exposes an ordinary text selection to context.
    let documentRoot = cjguiComposableVertical(760, "document-root", CjguiComposableUiStyle())
    documentRoot.add(cjguiComposableMultilineTextInput(761, "document-editor", "", "第一行\n第二行🙂", 7101,
        CjguiComposableUiStyle(fixedHeight: 120), fieldId: "document", operationActionName: "REPLACE_RANGE",
        operationResourceId: 7101))
    let documentScene = CjguiComposableUiLayoutEngine.layout(documentRoot, CjguiComposableUiRect(0, 0, 280, 160), 47)
    let documentProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(
        documentRoot, documentScene, focusedNodeId: 761, selectionStart: 3, selectionEnd: 8
    )
    if (!require(documentScene.nodeForId(761).bounds.height == 120 &&
        documentScene.resolveInput(761, 7101, CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT, 47).nodeKind == CJGUI_COMPOSABLE_UI_MULTILINE_TEXT_INPUT &&
        documentProjection.hasTextSelection &&
        hasProjectionNode(documentProjection.nodes, "document-editor", 761, "control"),
        "multiline_editor_is_composable_and_has_text_selection")) { return 1 }

    // Text sizing is rune-aware rather than UTF-8-byte based.  The combining
    // mark must stay with its base glyph, while a CJK label wraps at a real
    // line boundary when constrained.
    let fallbackMeasurer = CjguiComposableUiFallbackTextMeasurer()
    let combining = fallbackMeasurer.measure("e\u{301}", CjguiComposableUiStyle(fontSize: 16.0), 200)
    let base = fallbackMeasurer.measure("e", CjguiComposableUiStyle(fontSize: 16.0), 200)
    let cjkSmall = fallbackMeasurer.measure("通知阈值", CjguiComposableUiStyle(fontSize: 12.0), 200)
    let cjkLarge = fallbackMeasurer.measure("通知阈值", CjguiComposableUiStyle(fontSize: 20.0), 200)
    let wrapRoot = cjguiComposableVertical(900, "wrap-root", CjguiComposableUiStyle())
    wrapRoot.add(cjguiComposableText(901, "wrapped-cjk", "通知阈值配置需要在狭窄窗口中安全换行", CjguiComposableUiStyle(fontSize: 18.0)))
    let wrapScene = CjguiComposableUiLayoutEngine.layout(wrapRoot, CjguiComposableUiRect(0, 0, 72, 160), 46, fallbackMeasurer)
    if (!require(combining.width == base.width && cjkLarge.width > cjkSmall.width &&
        wrapScene.nodeForId(901).bounds.height > cjkLarge.lineHeight,
        "rune_safe_font_measurement_and_wrapping")) { return 1 }

    // Text bounds must include the vertical breathing room used by the draw
    // rectangle. A heading whose layout height is exactly its font line
    // height would otherwise be clipped by the renderer's inset.
    let headingRoot = cjguiComposableVertical(902, "heading-root", CjguiComposableUiStyle())
    let headingStyle = CjguiComposableUiStyle(fontSize: 20.0, fontWeight: 1)
    headingRoot.add(cjguiComposableText(903, "heading", "当前规则草稿", headingStyle))
    let headingScene = CjguiComposableUiLayoutEngine.layout(headingRoot, CjguiComposableUiRect(0, 0, 320, 80), 51, fallbackMeasurer)
    let headingMetrics = fallbackMeasurer.measure("当前规则草稿", headingStyle, 320)
    if (!require(headingScene.nodeForId(903).bounds.height >= headingMetrics.height + 4,
        "text_bounds_include_draw_inset")) { return 1 }

    // The text layout width must be the same inner content width consumed by
    // the native draw rectangle.  Measuring against the whole node makes a
    // narrow label appear to fit one fewer line than AppKit can actually draw.
    let insetRoot = cjguiComposableVertical(950, "inset-root", CjguiComposableUiStyle())
    let insetStyle = CjguiComposableUiStyle(fontSize: 16.0)
    insetRoot.add(cjguiComposableText(951, "inset-text", "ABCDE", insetStyle))
    let insetScene = CjguiComposableUiLayoutEngine.layout(insetRoot, CjguiComposableUiRect(0, 0, 30, 100), 52, fallbackMeasurer)
    let insetMetrics = fallbackMeasurer.measure("ABCDE", insetStyle, 16)
    if (!require(insetScene.nodeForId(951).bounds.height >= insetMetrics.height + 4,
        "text_measurement_uses_native_draw_content_width")) { return 1 }

    // Stretch fills only the cross-axis space permitted by the child's own
    // fixed/min/max constraints; it is not permission to override them.
    let constrainedStretchColumn = cjguiComposableVertical(952, "constrained-stretch-column", CjguiComposableUiStyle())
    constrainedStretchColumn.add(cjguiComposableText(953, "fixed-width-stretch", "fixed", CjguiComposableUiStyle(
        fixedWidth: 40, alignX: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    let constrainedStretchColumnScene = CjguiComposableUiLayoutEngine.layout(
        constrainedStretchColumn, CjguiComposableUiRect(0, 0, 120, 60), 53, fallbackMeasurer)
    if (!require(constrainedStretchColumnScene.nodeForId(953).bounds.width == 40,
        "stretch_honors_cross_axis_fixed_width")) { return 1 }
    let constrainedStretchRow = cjguiComposableHorizontal(954, "constrained-stretch-row", CjguiComposableUiStyle())
    constrainedStretchRow.add(cjguiComposableText(955, "fixed-height-stretch", "fixed", CjguiComposableUiStyle(
        fixedHeight: 26, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    let constrainedStretchRowScene = CjguiComposableUiLayoutEngine.layout(
        constrainedStretchRow, CjguiComposableUiRect(0, 0, 120, 90), 54, fallbackMeasurer)
    if (!require(constrainedStretchRowScene.nodeForId(955).bounds.height == 26,
        "stretch_honors_cross_axis_fixed_height")) { return 1 }

    // A row's cross axis is its available height, while a wrapped child's
    // natural height still needs that child's resolved width.  Passing the
    // width for both values makes an unconstrained stretch child stop at its
    // 80-point primary-axis width instead of filling this 100-point row.
    let unconstrainedStretchRow = cjguiComposableHorizontal(9560, "unconstrained-stretch-row", CjguiComposableUiStyle())
    unconstrainedStretchRow.add(cjguiComposableText(9561, "unconstrained-stretch", "fill", CjguiComposableUiStyle(
        fixedWidth: 80, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    let unconstrainedStretchScene = CjguiComposableUiLayoutEngine.layout(
        unconstrainedStretchRow, CjguiComposableUiRect(0, 0, 300, 100), 541, fallbackMeasurer)
    if (!require(unconstrainedStretchScene.nodeForId(9561).bounds.width == 80 &&
        unconstrainedStretchScene.nodeForId(9561).bounds.height == 100,
        "horizontal_stretch_uses_available_cross_axis_height")) { return 1 }

    // Stretch applies the actual row height before the child constraints:
    // min below the row does not reduce it, whereas max caps it.  Neither
    // assertion is allowed to accidentally use the 80-point primary width.
    let constrainedHeightStretchRow = cjguiComposableHorizontal(9562, "constrained-height-stretch-row", CjguiComposableUiStyle())
    constrainedHeightStretchRow.add(cjguiComposableText(9563, "min-height-stretch", "min", CjguiComposableUiStyle(
        fixedWidth: 80, minHeight: 90, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    constrainedHeightStretchRow.add(cjguiComposableText(9564, "max-height-stretch", "max", CjguiComposableUiStyle(
        fixedWidth: 80, maxHeight: 90, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)))
    let constrainedHeightStretchScene = CjguiComposableUiLayoutEngine.layout(
        constrainedHeightStretchRow, CjguiComposableUiRect(0, 0, 300, 100), 542, fallbackMeasurer)
    if (!require(constrainedHeightStretchScene.nodeForId(9563).bounds.height == 100 &&
        constrainedHeightStretchScene.nodeForId(9564).bounds.height == 90,
        "horizontal_stretch_honors_min_and_max_against_row_height")) { return 1 }

    // The same split values must propagate through a nested column: stretch
    // fills the 100-point row while its wrapped descendant measures against
    // the column's 80-point allocated width.
    let nestedStretchTextStyle = CjguiComposableUiStyle(fontSize: 16.0)
    let nestedStretchRow = cjguiComposableHorizontal(9565, "nested-stretch-row", CjguiComposableUiStyle())
    let nestedStretchColumn = cjguiComposableVertical(9566, "nested-stretch-column", CjguiComposableUiStyle(
        fixedWidth: 80, alignY: CJGUI_COMPOSABLE_UI_ALIGN_STRETCH))
    nestedStretchColumn.add(cjguiComposableText(9567, "nested-stretch-copy",
        "This nested adaptive label wraps by the resolved column width.", nestedStretchTextStyle))
    nestedStretchRow.add(nestedStretchColumn)
    let nestedStretchScene = CjguiComposableUiLayoutEngine.layout(
        nestedStretchRow, CjguiComposableUiRect(0, 0, 300, 100), 543, fallbackMeasurer)
    if (!require(nestedStretchScene.nodeForId(9566).bounds.height == 100 &&
        nestedStretchScene.nodeForId(9567).bounds.height > fallbackMeasurer.measure(
            "This nested adaptive label wraps by the resolved column width.", nestedStretchTextStyle, 80).lineHeight,
        "horizontal_stretch_and_nested_wrap_keep_axis_values_separate")) { return 1 }

    // A horizontal container used as a vertical child must allocate its row
    // widths before deriving its natural height.  Otherwise its own bound is
    // shorter than a wrapped child after the real row distribution.
    let nestedRowRoot = cjguiComposableVertical(956, "nested-row-root", CjguiComposableUiStyle())
    let nestedRow = cjguiComposableHorizontal(957, "nested-row", CjguiComposableUiStyle(gap: 2))
    nestedRow.add(cjguiComposableText(958, "nested-row-copy", "A long row label wraps after allocation", CjguiComposableUiStyle(growX: 1, fontSize: 16.0)))
    nestedRow.add(cjguiComposableImage(959, "nested-row-image", "placeholder.png", CjguiComposableUiStyle(fixedWidth: 50, fixedHeight: 20)))
    nestedRowRoot.add(nestedRow)
    let nestedRowScene = CjguiComposableUiLayoutEngine.layout(nestedRowRoot, CjguiComposableUiRect(0, 0, 120, 180), 55, fallbackMeasurer)
    if (!require(nestedRowScene.nodeForId(957).bounds.height >= nestedRowScene.nodeForId(958).bounds.height,
        "horizontal_natural_height_uses_allocated_child_width")) { return 1 }

    // The vertical parent first asks the nested row for its natural height,
    // then lays that same row out. These passes share exact measurement
    // queries. A layout-local reuse layer must collapse the 18 requests here
    // to seven true measurer calls: empty label, three intrinsic widths, and
    // three allocated-width text heights.
    let repeatedMeasureRoot = cjguiComposableVertical(960, "repeated-measure-root", CjguiComposableUiStyle())
    let repeatedMeasureRow = cjguiComposableHorizontal(961, "repeated-measure-row", CjguiComposableUiStyle())
    repeatedMeasureRow.add(cjguiComposableText(962, "repeated-one", "one", CjguiComposableUiStyle(growX: 1, fontSize: 14.0)))
    repeatedMeasureRow.add(cjguiComposableText(963, "repeated-two", "two", CjguiComposableUiStyle(growX: 1, fontSize: 14.0)))
    repeatedMeasureRow.add(cjguiComposableText(964, "repeated-three", "three", CjguiComposableUiStyle(growX: 1, fontSize: 14.0)))
    repeatedMeasureRoot.add(repeatedMeasureRow)
    let countingMeasurer = CountingTextMeasurer()
    let repeatedMeasureResult = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        repeatedMeasureRoot, CjguiComposableUiRect(0, 0, 300, 120), 56, countingMeasurer)
    let referenceMeasurer = CountingTextMeasurer()
    let repeatedMeasureReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        repeatedMeasureRoot, CjguiComposableUiRect(0, 0, 300, 120), 56, referenceMeasurer, reuseMeasurements: false)
    if (!require(repeatedMeasureResult.scene.nodes().size == 5 && countingMeasurer.callCount() == 7 &&
        repeatedMeasureResult.metrics.measurementRequestCount == 18 &&
        repeatedMeasureResult.metrics.measurerCallCount == 7 && repeatedMeasureResult.metrics.measurementReuseHitCount == 11 &&
        repeatedMeasureResult.metrics.recursiveNodeLayoutCount == 5 &&
        repeatedMeasureReference.metrics.measurementRequestCount == 18 && referenceMeasurer.callCount() == 18 &&
        repeatedMeasureReference.metrics.measurementReuseHitCount == 0 &&
        sameResolvedGeometry(repeatedMeasureReference.scene, repeatedMeasureResult.scene),
        "same_layout_reuses_exact_text_measurements")) { return 1 }
    println("CJGUI_LAYOUT_METRICS requests=${repeatedMeasureResult.metrics.measurementRequestCount} measurer_calls=${repeatedMeasureResult.metrics.measurerCallCount} reuse_hits=${repeatedMeasureResult.metrics.measurementReuseHitCount} recursive_nodes=${repeatedMeasureResult.metrics.recursiveNodeLayoutCount} reference_calls=${repeatedMeasureReference.metrics.measurerCallCount}")

    // RED: production's default cross-pass policy must not infer reuse for an
    // ordinary direct region without an explicit layoutReuseKey. The second
    // solve uses the same cache as the first, but must remain canonical work.
    let unkeyedDefaultRoot = cjguiComposableVertical(9670, "unkeyed-default-root", CjguiComposableUiStyle())
    let unkeyedDefaultRegion = cjguiComposableVertical(9671, "unkeyed-default-region",
        CjguiComposableUiStyle(fixedWidth: 180))
    unkeyedDefaultRegion.add(cjguiComposableText(9672, "unkeyed-default-copy",
        "普通直系区域必须显式声明 layoutReuseKey 才能跨轮复用", CjguiComposableUiStyle(fixedHeight: 20)))
    unkeyedDefaultRoot.add(unkeyedDefaultRegion)
    let unkeyedDefaultCache = CjguiComposableUiLayoutReuseCache()
    let unkeyedDefaultFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        unkeyedDefaultRoot, CjguiComposableUiRect(0, 0, 220, 80), 567,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: unkeyedDefaultCache)
    let unkeyedDefaultSecond = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        unkeyedDefaultRoot, CjguiComposableUiRect(0, 0, 220, 80), 568,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: unkeyedDefaultCache)
    let unkeyedDefaultCanonical = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        unkeyedDefaultRoot, CjguiComposableUiRect(0, 0, 220, 80), 568,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(unkeyedDefaultFirst.scene.isValid() && unkeyedDefaultSecond.scene.isValid() &&
        unkeyedDefaultCanonical.scene.isValid() && unkeyedDefaultSecond.metrics.subtreeReuseHitCount == 0 &&
        sameResolvedProjection(unkeyedDefaultSecond.scene, unkeyedDefaultCanonical.scene),
        "production_default_requires_explicit_layout_reuse_key")) { return 1 }

    // A domain edit rebuilds the value tree, but its stable tool and
    // collection siblings retain exactly the same layout inputs. The
    // cross-pass cache must skip their recursive solve while producing the
    // same geometry as the uncached canonical reference.
    let incrementalCache = CjguiComposableUiLayoutReuseCache()
    let incrementalFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), CjguiComposableUiRect(0, 0, 720, 360), 570,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: incrementalCache)
    let incrementalChanged = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("外部更新后的编辑说明", 24), CjguiComposableUiRect(0, 0, 720, 360), 571,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: incrementalCache)
    let incrementalReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("外部更新后的编辑说明", 24), CjguiComposableUiRect(0, 0, 720, 360), 571,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(sameResolvedGeometry(incrementalChanged.scene, incrementalReference.scene) &&
        incrementalChanged.metrics.subtreeReuseHitCount >= 2 &&
        incrementalChanged.metrics.recursiveNodeLayoutCount < incrementalFirst.metrics.recursiveNodeLayoutCount,
        "cross_pass_layout_reuses_unchanged_sibling_regions")) { return 1 }

    // Each dependent change starts from the same accepted derived scene. The
    // cache-free reference compares geometry, traversal order, every clip
    // constraint, semantic payload and input/focus target, so reuse cannot
    // hide a stale coordinate or old interaction identity.
    let incrementalViewport = CjguiComposableUiRect(0, 0, 720, 360)
    let warmCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 580,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: warmCache)
    let warmReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 581,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: warmCache)
    let warmReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 581,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)

    let localCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 582,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: localCache)
    let localReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("只变更编辑字段", 24), incrementalViewport, 583,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: localCache)
    let localReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("只变更编辑字段", 24), incrementalViewport, 583,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)

    let resizeCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 584,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: resizeCache)
    let resizeReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), CjguiComposableUiRect(0, 0, 640, 360), 585,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: resizeCache)
    let resizeReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), CjguiComposableUiRect(0, 0, 640, 360), 585,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)

    let fontCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 586,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: fontCache)
    let fontReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24, fontSize: 18.0), incrementalViewport, 587,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: fontCache)
    let fontReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24, fontSize: 18.0), incrementalViewport, 587,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)

    let scrollCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24, collectionScrollOffset: 0), incrementalViewport, 588,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: scrollCache)
    let scrollReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24, collectionScrollOffset: 120), incrementalViewport, 589,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: scrollCache)
    let scrollReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24, collectionScrollOffset: 120), incrementalViewport, 589,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)

    let structureCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 590,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: structureCache)
    let structureReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 25), incrementalViewport, 591,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: structureCache)
    let structureReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 25), incrementalViewport, 591,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(sameResolvedProjection(warmReused.scene, warmReference.scene) &&
        sameResolvedProjection(localReused.scene, localReference.scene) &&
        sameResolvedProjection(resizeReused.scene, resizeReference.scene) &&
        sameResolvedProjection(fontReused.scene, fontReference.scene) &&
        sameResolvedProjection(scrollReused.scene, scrollReference.scene) &&
        sameResolvedProjection(structureReused.scene, structureReference.scene) &&
        warmReused.metrics.subtreeReuseHitCount == 3 && localReused.metrics.subtreeReuseHitCount == 2 &&
        resizeReused.metrics.subtreeReuseHitCount == 0 && fontReused.metrics.subtreeReuseHitCount == 0 &&
        scrollReused.metrics.subtreeReuseHitCount == 2 && structureReused.metrics.subtreeReuseHitCount == 2,
        "cross_pass_layout_dependency_invalidation_projection_reference")) { return 1 }

    // An invalid submission cannot promote candidates. The following valid
    // pass is still compared against canonical output after a duplicate-ID
    // failure, and a two-entry cache must evict rather than grow.
    let recoveryCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 592,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: recoveryCache)
    let duplicateRoot = incrementalReuseDashboard("冲突说明", 24)
    duplicateRoot.add(cjguiComposableText(970001, "duplicate-tools", "重复节点", CjguiComposableUiStyle()))
    let failedReuse = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        duplicateRoot, incrementalViewport, 593, CjguiComposableUiFallbackTextMeasurer(), reuseCache: recoveryCache)
    let recoveredReuse = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("恢复后的编辑说明", 24), incrementalViewport, 594,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: recoveryCache)
    let recoveredReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("恢复后的编辑说明", 24), incrementalViewport, 594,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    let evictionCache = CjguiComposableUiLayoutReuseCache(maxEntries: 2)
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 595,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: evictionCache)
    let evictionWarm = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("初始说明", 24), incrementalViewport, 596,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: evictionCache)
    let evictionRecovered = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("淘汰后的编辑说明", 24), incrementalViewport, 597,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: evictionCache)
    let evictionReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("淘汰后的编辑说明", 24), incrementalViewport, 597,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(!failedReuse.scene.isValid() && failedReuse.scene.layoutError() == "duplicate_node_id" &&
        sameResolvedProjection(recoveredReuse.scene, recoveredReference.scene) &&
        sameResolvedProjection(evictionRecovered.scene, evictionReference.scene) &&
        evictionWarm.metrics.subtreeReuseHitCount == 2 && evictionWarm.metrics.subtreeReuseEntryCount == 2 &&
        evictionRecovered.metrics.subtreeReuseEntryCount == 2,
        "cross_pass_layout_failed_candidate_and_bounded_eviction_recover")) { return 1 }
    println("CJGUI_INCREMENTAL_LAYOUT_CORRECTNESS warm_hits=${warmReused.metrics.subtreeReuseHitCount} local_hits=${localReused.metrics.subtreeReuseHitCount} resize_hits=${resizeReused.metrics.subtreeReuseHitCount} font_hits=${fontReused.metrics.subtreeReuseHitCount} scroll_hits=${scrollReused.metrics.subtreeReuseHitCount} structural_hits=${structureReused.metrics.subtreeReuseHitCount} eviction_entries=${evictionRecovered.metrics.subtreeReuseEntryCount}")

    let hostedCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        hostedIncrementalDashboard("初始详情"), CjguiComposableUiRect(0, 0, 360, 180), 598,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: hostedCache)
    let hostedReused = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        hostedIncrementalDashboard("更新后的详情"), CjguiComposableUiRect(0, 0, 360, 180), 599,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: hostedCache)
    let hostedReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        hostedIncrementalDashboard("更新后的详情"), CjguiComposableUiRect(0, 0, 360, 180), 599,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(sameResolvedProjection(hostedReused.scene, hostedReference.scene) &&
        hostedReused.metrics.subtreeReuseHitCount == 1 && hostedReused.metrics.recursiveNodeLayoutCount <
            hostedReference.metrics.recursiveNodeLayoutCount,
        "layer_host_base_regions_reach_layout_reuse")) { return 1 }

    // The normal window defers promotion until Cangjie/native acceptance.
    // Discarding its staged candidate must leave no reusable failure result;
    // an explicit acceptance then makes exactly the same candidate reusable.
    let deferredCache = CjguiComposableUiLayoutReuseCache()
    let stagedForRejectedAcceptance = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("暂存说明", 24), incrementalViewport, 600,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: deferredCache, commitReusePass: false)
    if (!require(stagedForRejectedAcceptance.metrics.subtreeReusePendingNodeCount > 0 &&
        stagedForRejectedAcceptance.metrics.subtreeReusePendingStringBytes > 0 &&
        stagedForRejectedAcceptance.metrics.subtreeReusePendingBytes > 0,
        "cross_pass_layout_reports_pending_candidate_retention")) { return 1 }
    deferredCache.discardPass()
    let discardedCandidate = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("暂存说明", 24), incrementalViewport, 601,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: deferredCache)
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("已接受说明", 24), incrementalViewport, 602,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: deferredCache, commitReusePass: false)
    deferredCache.commitPass()
    let acceptedCandidate = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        incrementalReuseDashboard("已接受说明", 24), incrementalViewport, 603,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: deferredCache)
    if (!require(discardedCandidate.metrics.subtreeReuseHitCount == 0 &&
        acceptedCandidate.metrics.subtreeReuseHitCount == 3,
        "cross_pass_layout_promotes_only_after_acceptance")) { return 1 }

    // Reuse is confined to one solve. A later width or font declaration must
    // reach the provided measurer again and produce the newly measured height.
    let widthSensitiveRoot = cjguiComposableVertical(965, "width-sensitive-root", CjguiComposableUiStyle())
    widthSensitiveRoot.add(cjguiComposableText(966, "width-sensitive-copy",
        "A long adaptive label must be measured again after its available width changes.", CjguiComposableUiStyle(fontSize: 14.0)))
    let widthSensitiveMeasurer = CountingTextMeasurer()
    let narrowTextLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        widthSensitiveRoot, CjguiComposableUiRect(0, 0, 96, 160), 57, widthSensitiveMeasurer)
    let wideTextLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        widthSensitiveRoot, CjguiComposableUiRect(0, 0, 320, 160), 58, widthSensitiveMeasurer)
    let smallFontRoot = cjguiComposableVertical(967, "small-font-root", CjguiComposableUiStyle())
    smallFontRoot.add(cjguiComposableText(968, "font-sensitive-copy", "font change", CjguiComposableUiStyle(fontSize: 12.0)))
    let largeFontRoot = cjguiComposableVertical(969, "large-font-root", CjguiComposableUiStyle())
    largeFontRoot.add(cjguiComposableText(970, "font-sensitive-copy", "font change", CjguiComposableUiStyle(fontSize: 24.0)))
    let fontSensitiveMeasurer = CountingTextMeasurer()
    let smallFontLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        smallFontRoot, CjguiComposableUiRect(0, 0, 240, 100), 59, fontSensitiveMeasurer)
    let largeFontLayout = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        largeFontRoot, CjguiComposableUiRect(0, 0, 240, 100), 60, fontSensitiveMeasurer)
    if (!require(narrowTextLayout.scene.nodeForId(966).bounds.height > wideTextLayout.scene.nodeForId(966).bounds.height &&
        narrowTextLayout.metrics.measurerCallCount > 0 && wideTextLayout.metrics.measurerCallCount > 0 &&
        smallFontLayout.scene.nodeForId(968).bounds.height < largeFontLayout.scene.nodeForId(970).bounds.height &&
        fontSensitiveMeasurer.callCount() == smallFontLayout.metrics.measurerCallCount + largeFontLayout.metrics.measurerCallCount,
        "width_and_font_change_start_new_exact_measurement_passes")) { return 1 }

    // Width constraints are resolved from min/ideal/max before flexible
    // growth.  A narrow viewport shrinks toward the declared minima and the
    // cross-axis alignment remains inside its parent clip.
    let adaptive = cjguiComposableHorizontal(910, "adaptive", CjguiComposableUiStyle(gap: 4))
    adaptive.add(cjguiComposableText(911, "start", "开始", CjguiComposableUiStyle(minWidth: 40, idealWidth: 72, maxWidth: 90, alignY: CJGUI_COMPOSABLE_UI_ALIGN_START)))
    adaptive.add(cjguiComposableText(912, "grow", "中间", CjguiComposableUiStyle(minWidth: 48, idealWidth: 84, maxWidth: 160, growX: 1, alignY: CJGUI_COMPOSABLE_UI_ALIGN_CENTER)))
    adaptive.add(cjguiComposableText(913, "end", "结束", CjguiComposableUiStyle(minWidth: 40, idealWidth: 72, maxWidth: 90, alignY: CJGUI_COMPOSABLE_UI_ALIGN_END)))
    let narrowAdaptive = CjguiComposableUiLayoutEngine.layout(adaptive, CjguiComposableUiRect(0, 0, 156, 48), 47, fallbackMeasurer)
    let wideAdaptive = CjguiComposableUiLayoutEngine.layout(adaptive, CjguiComposableUiRect(0, 0, 420, 48), 48, fallbackMeasurer)
    if (!require(narrowAdaptive.nodeForId(911).bounds.width >= 40 && narrowAdaptive.nodeForId(912).bounds.width >= 48 &&
        narrowAdaptive.nodeForId(913).bounds.width >= 40 && wideAdaptive.nodeForId(912).bounds.width > narrowAdaptive.nodeForId(912).bounds.width &&
        wideAdaptive.nodeForId(912).bounds.width <= 160,
        "adaptive_min_ideal_max_grow_shrink")) { return 1 }

    // The same growth solver serves columns.  A capped child must not strand
    // available main-axis height when a later sibling can still grow.
    let saturatedHeightGrowth = cjguiComposableVertical(1917, "saturated-height-growth", CjguiComposableUiStyle())
    saturatedHeightGrowth.add(cjguiComposableText(1918, "capped-height-grow", "cap", CjguiComposableUiStyle(
        idealHeight: 40, maxHeight: 60, growY: 1)))
    saturatedHeightGrowth.add(cjguiComposableText(1919, "remaining-height-grow", "fill", CjguiComposableUiStyle(
        idealHeight: 40, growY: 1)))
    let saturatedHeightGrowthScene = CjguiComposableUiLayoutEngine.layout(
        saturatedHeightGrowth, CjguiComposableUiRect(0, 0, 120, 200), 49, fallbackMeasurer)
    if (!require(saturatedHeightGrowthScene.nodeForId(1918).bounds.height == 60 &&
        saturatedHeightGrowthScene.nodeForId(1919).bounds.height == 140,
        "height_growth_reallocates_surplus_after_max_saturation")) { return 1 }

    // Growth that reaches one child's max must reallocate the unconsumed
    // surplus to remaining growable siblings; leaving it unused creates an
    // avoidable gap even though the row still has a valid flexible child.
    let saturatedGrowth = cjguiComposableHorizontal(917, "saturated-growth", CjguiComposableUiStyle())
    saturatedGrowth.add(cjguiComposableText(918, "capped-grow", "cap", CjguiComposableUiStyle(
        idealWidth: 40, maxWidth: 60, growX: 1)))
    saturatedGrowth.add(cjguiComposableText(919, "remaining-grow", "fill", CjguiComposableUiStyle(
        idealWidth: 40, growX: 1)))
    let saturatedGrowthScene = CjguiComposableUiLayoutEngine.layout(
        saturatedGrowth, CjguiComposableUiRect(0, 0, 200, 48), 49, fallbackMeasurer)
    if (!require(saturatedGrowthScene.nodeForId(918).bounds.width == 60 &&
        saturatedGrowthScene.nodeForId(919).bounds.width == 140,
        "growth_reallocates_surplus_after_max_saturation")) { return 1 }

    // A vertical child of a horizontal row must measure wrapped text against
    // its allocated width, not the row's height. Otherwise a normal hero
    // column is needlessly made tall and then clipped by the row.
    let horizontalTextRoot = cjguiComposableHorizontal(914, "horizontal-text-root", CjguiComposableUiStyle(fixedHeight: 90))
    let horizontalTextColumn = cjguiComposableVertical(915, "horizontal-text-column", CjguiComposableUiStyle(growX: 1))
    horizontalTextColumn.add(cjguiComposableText(916, "horizontal-text", "A descriptive label that fits in a wide hero column", CjguiComposableUiStyle(fontSize: 12.0)))
    horizontalTextRoot.add(horizontalTextColumn)
    let horizontalTextScene = CjguiComposableUiLayoutEngine.layout(horizontalTextRoot, CjguiComposableUiRect(0, 0, 420, 90), 50, fallbackMeasurer)
    if (!require(horizontalTextScene.nodeForId(915).bounds.height < 40,
        "horizontal_child_text_uses_allocated_width")) { return 1 }

    // A field's presentation role is declarative: a draft editor and an
    // applied-value display must not be inferred from their semantic names.
    let roleRoot = cjguiComposableVertical(920, "role-root", CjguiComposableUiStyle())
    roleRoot.add(cjguiComposableTextInput(921, "channel-editor", "通道", "草稿邮件", 77, CjguiComposableUiStyle(),
        fieldId: "channel", operationActionName: "EDIT_DRAFT_TEXT", displayValueRole: "draft"))
    roleRoot.add(cjguiComposableText(922, "channel-applied", "当前已应用：短信", CjguiComposableUiStyle(),
        resourceId: 77, fieldId: "channel", displayValueRole: "applied"))
    let roleScene = CjguiComposableUiLayoutEngine.layout(roleRoot, CjguiComposableUiRect(0, 0, 260, 100), 49, fallbackMeasurer)
    let roleProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(roleRoot, roleScene)
    if (!require(hasProjectionFieldValue(roleProjection.fieldValues, "channel-editor", 77, "channel", "draft", "component_value", "草稿邮件") &&
        hasProjectionFieldValue(roleProjection.fieldValues, "channel-applied", 77, "channel", "applied", "component_value", "当前已应用：短信"),
        "direct_draft_and_applied_field_values")) { return 1 }

    // A large fixed-row collection asks its source only for the visible rows
    // plus a bounded overscan. The logical height still represents all 2,000
    // records, so a direct key reveal jumps to an off-screen row without
    // constructing 1,999 preceding buttons.
    let virtualSource = LargeVirtualListSource()
    let virtualState = CjguiComposableUiVirtualListState()
    virtualState.setSelectedKey("row_0")
    let virtualRoot = cjguiComposableVertical(1000, "virtual-root", CjguiComposableUiStyle())
    virtualRoot.add(cjguiComposableVirtualList(1001, "virtual-scroll", 1002, virtualSource, virtualState,
        20, 2, 2, CjguiComposableUiStyle(fixedHeight: 100)))
    let virtualInitial = CjguiComposableUiLayoutEngine.layout(virtualRoot, CjguiComposableUiRect(0, 0, 280, 108), 56)
    if (!require(virtualState.materializedStart() == 0 && virtualState.materializedEnd() <= 7 &&
        virtualInitial.nodes().size <= 10 && virtualSource.buildCount() <= 7 &&
        virtualInitial.nodeForId(4900000).nodeId == 4900000,
        "virtual_list_materializes_only_viewport_and_buffer")) { return 1 }
    if (!require(virtualState.revealKey(virtualSource, "row_1500"), "virtual_list_reveals_offscreen_stable_key")) { return 1 }
    let virtualJumped = CjguiComposableUiLayoutEngine.layout(virtualRoot, CjguiComposableUiRect(0, 0, 280, 108), 57)
    if (!require(virtualState.materializedStart() <= 1500 && virtualState.materializedEnd() > 1500 &&
        virtualJumped.nodeForId(4901500).nodeId == 4901500 && virtualSource.buildCount() <= 16,
        "virtual_list_fast_jump_keeps_work_bounded")) { return 1 }
    let endItem = virtualState.moveFocus(virtualSource, "end")
    if (!require(endItem.key == "row_1999" && virtualState.focusedKey() == "row_1999" &&
        virtualState.revealKey(virtualSource, endItem.key),
        "virtual_list_keyboard_anchor_uses_stable_key")) { return 1 }
    let virtualEnd = CjguiComposableUiLayoutEngine.layout(virtualRoot, CjguiComposableUiRect(0, 0, 280, 108), 58)
    let virtualProjection = CjguiComposableUiWindowProjectionBuilder.fromScene(virtualRoot, virtualEnd)
    if (!require(virtualEnd.nodeForId(4901999).nodeId == 4901999 && virtualState.materializedEnd() == 2000 &&
        hasProjectionCollection(virtualProjection.collections, "virtual-scroll", 2000, 2000),
        "virtual_list_tail_and_small_buffer")) { return 1 }
    // A pathological viewport must not bypass the native 1,024-node ceiling
    // through one giant list range. The logical source remains all 2,000
    // items; only this scene's materialized projection is bounded.
    virtualState.scrollToIndex(0)
    let buildBeforeOversizedViewport = virtualSource.buildCount()
    let oversizedVirtualRoot = cjguiComposableVertical(1010, "oversized-virtual-root", CjguiComposableUiStyle())
    oversizedVirtualRoot.add(cjguiComposableVirtualList(1011, "oversized-virtual-scroll", 1012, virtualSource, virtualState,
        20, 2, 2, CjguiComposableUiStyle(growY: 1)))
    let oversizedVirtualScene = CjguiComposableUiLayoutEngine.layout(
        oversizedVirtualRoot, CjguiComposableUiRect(0, 0, 420, 100000), 59
    )
    if (!require(virtualState.materializedStart() == 0 &&
        virtualState.materializedEnd() == CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        virtualSource.buildCount() - buildBeforeOversizedViewport == CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        oversizedVirtualScene.nodes().size <= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS + 3,
        "virtual_list_preserves_native_scene_ceiling")) { return 1 }

    // Empty, one-row and one-pixel viewports are ordinary range states, not
    // exceptional full-list fallbacks. A huge index must saturate before the
    // total-height clamp rather than wrapping to an unrelated row.
    let emptyVirtualSource = FixedVirtualListSource(0); let emptyVirtualState = CjguiComposableUiVirtualListState()
    let emptyVirtualRoot = cjguiComposableVertical(1020, "empty-virtual-root", CjguiComposableUiStyle())
    emptyVirtualRoot.add(cjguiComposableVirtualList(1021, "empty-virtual-scroll", 1022, emptyVirtualSource, emptyVirtualState,
        20, 2, 2, CjguiComposableUiStyle(fixedHeight: 1)))
    let emptyVirtualScene = CjguiComposableUiLayoutEngine.layout(emptyVirtualRoot, CjguiComposableUiRect(0, 0, 100, 8), 60)
    let oneSource = FixedVirtualListSource(1); let oneState = CjguiComposableUiVirtualListState()
    let oneRoot = cjguiComposableVertical(1030, "one-virtual-root", CjguiComposableUiStyle())
    oneRoot.add(cjguiComposableVirtualList(1031, "one-virtual-scroll", 1032, oneSource, oneState,
        20, 2, 2, CjguiComposableUiStyle(fixedHeight: 1)))
    let oneScene = CjguiComposableUiLayoutEngine.layout(oneRoot, CjguiComposableUiRect(0, 0, 100, 8), 61)
    virtualState.scrollToIndex(1000000000000000000)
    let overflowScene = CjguiComposableUiLayoutEngine.layout(virtualRoot, CjguiComposableUiRect(0, 0, 280, 108), 62)
    if (!require(emptyVirtualState.materializedStart() == 0 && emptyVirtualState.materializedEnd() == 0 && emptyVirtualSource.buildCount() == 0 &&
        emptyVirtualScene.nodes().size == 3 && oneState.materializedStart() == 0 && oneState.materializedEnd() == 1 &&
        oneSource.buildCount() == 1 && oneScene.nodeForId(6600000).nodeId == 6600000 &&
        virtualState.materializedEnd() == 2000 && overflowScene.nodeForId(4901999).nodeId == 4901999,
        "virtual_list_empty_single_tiny_and_large_offset_boundaries")) { return 1 }

    // The same logical source recomputes just a larger near-viewport window
    // after a resized host gives its list more vertical space.
    let resizedSource = LargeVirtualListSource(); let resizedState = CjguiComposableUiVirtualListState()
    let resizedRoot = cjguiComposableVertical(1040, "resized-virtual-root", CjguiComposableUiStyle())
    resizedRoot.add(cjguiComposableVirtualList(1041, "resized-virtual-scroll", 1042, resizedSource, resizedState,
        20, 2, 2, CjguiComposableUiStyle(growY: 1)))
    let _ = CjguiComposableUiLayoutEngine.layout(resizedRoot, CjguiComposableUiRect(0, 0, 240, 80), 63)
    let shortViewportEnd = resizedState.materializedEnd()
    let _ = CjguiComposableUiLayoutEngine.layout(resizedRoot, CjguiComposableUiRect(0, 0, 240, 180), 64)
    if (!require(shortViewportEnd > 0 && resizedState.materializedEnd() > shortViewportEnd &&
        resizedState.materializedEnd() <= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        resizedSource.buildCount() <= resizedState.materializedEnd() + shortViewportEnd,
        "virtual_list_resize_recomputes_bounded_range")) { return 1 }

    // A stable anchor owns the row and the intra-row offset, not a stale
    // pixel coordinate. Insert, reorder and filtering-style removal occur
    // between layouts without an intervening scroll gesture.
    let dynamicSource = DynamicVirtualListSource(); let dynamicState = CjguiComposableUiVirtualListState()
    dynamicState.setSelectedKey("row_5"); dynamicState.setFocusedKey("row_5")
    let dynamicRoot = cjguiComposableVertical(1100, "dynamic-anchor-root", CjguiComposableUiStyle())
    dynamicRoot.add(cjguiComposableVirtualList(1101, "dynamic-anchor-scroll", 1102, dynamicSource, dynamicState,
        20, 2, 0, CjguiComposableUiStyle(fixedHeight: 44)))
    if (!dynamicState.revealKey(dynamicSource, "row_5")) { return 1 }
    let _ = CjguiComposableUiLayoutEngine.layout(dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 65)
    dynamicSource.prepend()
    let afterInsert = CjguiComposableUiLayoutEngine.layout(dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 66)
    if (!require(dynamicState.scrollOffset() == 132 && dynamicState.materializedStart() == 6 &&
        afterInsert.nodeForId(6910005).bounds.y == 0,
        "virtual_list_anchor_repositions_after_prefix_insert")) { return 1 }
    dynamicSource.reorder()
    let afterReorder = CjguiComposableUiLayoutEngine.layout(dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 67)
    if (!require(dynamicState.scrollOffset() == 154 && dynamicState.materializedStart() == 7 &&
        afterReorder.nodeForId(6910005).bounds.y == 0,
        "virtual_list_anchor_repositions_after_reorder")) { return 1 }
    dynamicSource.removeStableAnchor()
    let afterRemoval = CjguiComposableUiLayoutEngine.layout(dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 68)
    if (!require(dynamicState.anchorKey() != "row_5" && dynamicState.selectedKey() == "" &&
        dynamicState.focusedKey() == "" && afterRemoval.nodes().size > 2,
        "virtual_list_anchor_deletion_clears_stale_selection_without_rebinding")) { return 1 }
    // The reference path recomputes the same dynamic materialized tree with
    // no measurement reuse. It must retain exactly the canonical rectangles,
    // clips and input scopes produced by the normal layout call.
    let dynamicCached = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 69, fallbackMeasurer)
    let dynamicReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        dynamicRoot, CjguiComposableUiRect(0, 0, 200, 44), 69, fallbackMeasurer, reuseMeasurements: false)
    if (!require(dynamicCached.metrics.recursiveNodeLayoutCount == dynamicCached.scene.nodes().size &&
        sameResolvedGeometry(dynamicCached.scene, dynamicReference.scene),
        "dynamic_tree_matches_cache_free_reference_geometry")) { return 1 }

    // A selected/focused item can disappear independently of the stable
    // viewport anchor. Both state roles must clear instead of rebinding to
    // the source row now occupying that old materialized index.
    let independentSource = DynamicVirtualListSource(); let independentState = CjguiComposableUiVirtualListState()
    independentState.setSelectedKey("row_4"); independentState.setFocusedKey("row_4")
    let independentRoot = cjguiComposableVertical(1105, "independent-state-root", CjguiComposableUiStyle())
    independentRoot.add(cjguiComposableVirtualList(1106, "independent-state-scroll", 1107, independentSource, independentState,
        20, 2, 0, CjguiComposableUiStyle(fixedHeight: 44)))
    if (!independentState.revealKey(independentSource, "row_5")) { return 1 }
    let _ = CjguiComposableUiLayoutEngine.layout(independentRoot, CjguiComposableUiRect(0, 0, 200, 44), 681)
    independentSource.removeNonAnchorSelection()
    let _ = CjguiComposableUiLayoutEngine.layout(independentRoot, CjguiComposableUiRect(0, 0, 200, 44), 682)
    if (!require(independentState.anchorKey() == "row_5" && independentState.selectedKey() == "" &&
        independentState.focusedKey() == "" && independentState.lastDataIssue() == "selected_missing",
        "virtual_list_independent_selection_and_focus_deletion_do_not_rebind")) { return 1 }

    // Every logical fixed row reserves exactly its declared stride even when
    // source data is missing or its row builder asks for a taller node. A
    // duplicate key is rejected into the same stable placeholder path, while
    // duplicate generated node IDs fail the full scene closed before native
    // submission could make input identity ambiguous.
    let sparseSource = SparseVirtualListSource(); let sparseState = CjguiComposableUiVirtualListState()
    let sparseRoot = cjguiComposableVertical(1110, "sparse-row-root", CjguiComposableUiStyle())
    sparseRoot.add(cjguiComposableVirtualList(1111, "sparse-row-scroll", 1112, sparseSource, sparseState,
        20, 2, 0, CjguiComposableUiStyle(fixedHeight: 66)))
    let sparseScene = CjguiComposableUiLayoutEngine.layout(sparseRoot, CjguiComposableUiRect(0, 0, 200, 66), 69)
    if (!require(sparseScene.nodeForId(7120002).bounds.y == 44 && sparseScene.nodeForId(7120002).bounds.height == 20 &&
        sparseState.lastDataIssue() == "missing_key",
        "virtual_list_missing_row_preserves_fixed_stride")) { return 1 }
    let duplicateKeyState = CjguiComposableUiVirtualListState()
    let duplicateKeyRoot = cjguiComposableVertical(1120, "duplicate-key-root", CjguiComposableUiStyle())
    duplicateKeyRoot.add(cjguiComposableVirtualList(1121, "duplicate-key-scroll", 1122, DuplicateKeyVirtualListSource(), duplicateKeyState,
        20, 2, 0, CjguiComposableUiStyle(fixedHeight: 66)))
    let duplicateKeyScene = CjguiComposableUiLayoutEngine.layout(duplicateKeyRoot, CjguiComposableUiRect(0, 0, 200, 66), 70)
    if (!require(duplicateKeyState.lastDataIssue() == "duplicate_key" && duplicateKeyScene.nodeForId(7330002).bounds.y == 44,
        "virtual_list_duplicate_key_reserves_placeholder")) { return 1 }
    let duplicateNodeRoot = cjguiComposableVertical(1130, "duplicate-node-root", CjguiComposableUiStyle())
    duplicateNodeRoot.add(cjguiComposableVirtualList(1131, "duplicate-node-scroll", 1132, DuplicateNodeVirtualListSource(),
        CjguiComposableUiVirtualListState(), 20, 2, 0, CjguiComposableUiStyle(fixedHeight: 44)))
    let duplicateNodeScene = CjguiComposableUiLayoutEngine.layout(duplicateNodeRoot, CjguiComposableUiRect(0, 0, 200, 44), 71)
    if (!require(!duplicateNodeScene.isValid() && duplicateNodeScene.layoutError() == "duplicate_node_id",
        "virtual_list_duplicate_generated_node_id_fails_closed")) { return 1 }

    // Variable-height collections retain the existing stable-key state and
    // range limits, but derive each revealed row from its ordinary subtree at
    // the current width. A 10,000-row logical source may provide estimates;
    // it must not build or measure every body before the first viewport.
    let variableSource = VariableHeightVirtualListSource(10000)
    let variableState = CjguiComposableUiVirtualListState()
    let variableRoot = cjguiComposableVertical(1140, "variable-height-root", CjguiComposableUiStyle())
    variableRoot.add(cjguiComposableVariableHeightList(1141, "variable-height-scroll", 1142,
        variableSource, variableState, 34, 3, 2, CjguiComposableUiStyle(fixedHeight: 132)))
    let variableInitial = CjguiComposableUiLayoutEngine.layout(
        variableRoot, CjguiComposableUiRect(0, 0, 168, 132), 72)
    let variableLongHeight = variableInitial.nodeForId(8970000).bounds.height
    let variableShortHeight = variableInitial.nodeForId(8970001).bounds.height
    if (!require(variableLongHeight > variableShortHeight && variableState.materializedEnd() <= 8 &&
        variableSource.buildCount() <= 12 && variableSource.itemReadCount() < 128,
        "variable_height_materializes_and_measures_only_revealed_subtrees")) { return 1 }

    // An already measured change before the stable anchor first falls back to
    // its fresh source estimate, then converges when revealed. The anchored
    // row remains at the same viewport position rather than inheriting a
    // stale pixel offset from its old neighbour geometry.
    if (!variableState.revealKey(variableSource, "variable_40")) { return 1 }
    let variableAnchored = CjguiComposableUiLayoutEngine.layout(
        variableRoot, CjguiComposableUiRect(0, 0, 168, 132), 73)
    let offsetBeforeExpansion = variableState.scrollOffset()
    variableSource.expandBeforeAnchor(0)
    let variableAfterExpansion = CjguiComposableUiLayoutEngine.layout(
        variableRoot, CjguiComposableUiRect(0, 0, 168, 132), 74)
    if (!require(variableState.anchorKey() == "variable_40" &&
        variableAfterExpansion.nodeForId(8970040).bounds.y == variableAnchored.nodeForId(8970040).bounds.y &&
        variableState.scrollOffset() >= offsetBeforeExpansion,
        "variable_height_anchor_preserves_key_and_intra_row_position_after_prior_change")) { return 1 }

    // A real owner may update an off-screen record between refreshes. It must
    // not steal the user's selection or viewport. Once the human explicitly
    // reveals that stable key, its changed ordinary subtree is built and
    // measured at the current width.
    variableState.setSelectedKey("variable_40")
    let offsetBeforeExternal = variableState.scrollOffset()
    variableSource.applyExternalScreenOffChange(7000)
    let _ = CjguiComposableUiLayoutEngine.layout(variableRoot, CjguiComposableUiRect(0, 0, 168, 132), 75)
    if (!require(variableState.selectedKey() == "variable_40" && variableState.anchorKey() == "variable_40" &&
        variableState.scrollOffset() == offsetBeforeExternal && !variableSource.externallyChangedWasBuilt() &&
        variableState.revealKey(variableSource, "variable_7000"),
        "variable_height_screen_off_external_change_does_not_auto_reveal")) { return 1 }
    let variableRevealed = CjguiComposableUiLayoutEngine.layout(
        variableRoot, CjguiComposableUiRect(0, 0, 168, 132), 76)
    let changedHeightAtNarrowWidth = variableRevealed.nodeForId(8977000).bounds.height
    let variableWide = CjguiComposableUiLayoutEngine.layout(
        variableRoot, CjguiComposableUiRect(0, 0, 360, 132), 77)
    if (!require(variableSource.externallyChangedWasBuilt() && changedHeightAtNarrowWidth > 34 &&
        variableWide.nodeForId(8977000).bounds.height < changedHeightAtNarrowWidth &&
        variableState.materializedEnd() - variableState.materializedStart() <= 8,
        "variable_height_external_row_and_width_invalidation_use_actual_geometry")) { return 1 }

    // Stable anchors are keys plus an intra-row offset, not an index. A
    // prefix insertion keeps the visible object in place; deleting that
    // object deterministically adopts its next neighbour while selection and
    // focus still clear rather than silently rebinding to the neighbour.
    let mutableVariableSource = MutableVariableHeightListSource()
    let mutableVariableState = CjguiComposableUiVirtualListState()
    mutableVariableState.setSelectedKey("mutable_2"); mutableVariableState.setFocusedKey("mutable_2")
    let mutableVariableRoot = cjguiComposableVertical(1150, "mutable-variable-root", CjguiComposableUiStyle())
    mutableVariableRoot.add(cjguiComposableVariableHeightList(1151, "mutable-variable-scroll", 1152,
        mutableVariableSource, mutableVariableState, 34, 2, 1, CjguiComposableUiStyle(fixedHeight: 72)))
    if (!mutableVariableState.revealKey(mutableVariableSource, "mutable_2")) { return 1 }
    let mutableBefore = CjguiComposableUiLayoutEngine.layout(
        mutableVariableRoot, CjguiComposableUiRect(0, 0, 150, 72), 78)
    mutableVariableSource.prepend()
    let mutableAfterPrefix = CjguiComposableUiLayoutEngine.layout(
        mutableVariableRoot, CjguiComposableUiRect(0, 0, 150, 72), 79)
    mutableVariableSource.remove(2)
    let mutableAfterDelete = CjguiComposableUiLayoutEngine.layout(
        mutableVariableRoot, CjguiComposableUiRect(0, 0, 150, 72), 80)
    if (!require(mutableBefore.nodeForId(9480002).bounds.y == mutableAfterPrefix.nodeForId(9480002).bounds.y &&
        mutableVariableState.anchorKey() == "mutable_3" && mutableVariableState.selectedKey() == "" &&
        mutableVariableState.focusedKey() == "" && mutableVariableState.lastDataIssue() == "anchor_deleted_next" &&
        mutableAfterDelete.nodeForId(9480003).bounds.y == mutableAfterPrefix.nodeForId(9480002).bounds.y,
        "variable_height_anchor_insert_and_deletion_fallback_preserve_identity_boundaries")) { return 1 }

    // Regression: estimates can be much taller than ordinary measured rows.
    // The final published range must still contain enough real rows to cover
    // the viewport, and a large requested overscan must never exceed the
    // collection's materialization cap.
    let exactFillSource = ExactHeightVariableListSource(512, 10, 1000)
    let exactFillState = CjguiComposableUiVirtualListState()
    let exactFillRoot = cjguiComposableVertical(1160, "exact-fill-root", CjguiComposableUiStyle())
    exactFillRoot.add(cjguiComposableVariableHeightList(1161, "exact-fill-scroll", 1162,
        exactFillSource, exactFillState, 1000, 0, 0, CjguiComposableUiStyle(fixedHeight: 500)))
    let exactFillScene = CjguiComposableUiLayoutEngine.layout(
        exactFillRoot, CjguiComposableUiRect(0, 0, 180, 500), 80)
    let exactFillLast = exactFillScene.nodeForId(10895049)
    let exactFillPass = exactFillState.materializedStart() == 0 && exactFillState.materializedEnd() >= 50 &&
        exactFillState.materializedEnd() <= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        exactFillLast.bounds.y == 490 && exactFillLast.bounds.height == 10

    let exactOverscanSource = ExactHeightVariableListSource(512, 10, 1000)
    let exactOverscanState = CjguiComposableUiVirtualListState()
    let exactOverscanRoot = cjguiComposableVertical(1170, "exact-overscan-root", CjguiComposableUiStyle())
    exactOverscanRoot.add(cjguiComposableVariableHeightList(1171, "exact-overscan-scroll", 1172,
        exactOverscanSource, exactOverscanState, 1000, 0, 1000, CjguiComposableUiStyle(fixedHeight: 500)))
    if (!exactOverscanState.revealKey(exactOverscanSource, "exact_256")) { return 1 }
    let exactOverscanScene = CjguiComposableUiLayoutEngine.layout(
        exactOverscanRoot, CjguiComposableUiRect(0, 0, 180, 500), 81)
    let exactOverscanPass = exactOverscanScene.isValid() && exactOverscanState.materializedStart() == 256 &&
        exactOverscanState.materializedEnd() > 256 && exactOverscanState.lastDataIssue() == "" &&
        exactOverscanState.materializedEnd() - exactOverscanState.materializedStart() <=
            CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS
    let exactVariableRegressionPass = require(exactFillPass,
        "variable_height_real_measurements_fill_viewport_within_budget")
    let exactOverscanRegressionPass = require(exactOverscanPass,
        "variable_height_overscan_never_exceeds_materialization_budget")
    if (!exactVariableRegressionPass || !exactOverscanRegressionPass) { return 1 }

    // One state may encounter more than 128 distinct keys. Its cache must
    // evict old measurements rather than expand, re-measuring an evicted key
    // on return; mixed row heights, a tail reveal, and a width invalidation
    // all remain bounded independent of the warm-scroll benchmark.
    let cacheSource = ExactHeightVariableListSource(300, 10, 10, alternateHeight: 70)
    let cacheState = CjguiComposableUiVirtualListState()
    let cacheInitialRoot = cjguiComposableVertical(1180, "cache-initial-root", CjguiComposableUiStyle())
    cacheInitialRoot.add(cjguiComposableVariableHeightList(1181, "cache-initial-scroll", 1182,
        cacheSource, cacheState, 10, 0, 0, CjguiComposableUiStyle(fixedHeight: 5120)))
    let cacheInitialScene = CjguiComposableUiLayoutEngine.layout(
        cacheInitialRoot, CjguiComposableUiRect(0, 0, 180, 5120), 82)
    let cacheInitialPass = cacheState.materializedStart() == 0 && cacheState.materializedEnd() == 128 &&
        cacheInitialScene.nodeForId(10895000).bounds.height == 10 &&
        cacheInitialScene.nodeForId(10895001).bounds.height == 70
    let cacheMiddleRoot = cjguiComposableVertical(1190, "cache-middle-root", CjguiComposableUiStyle())
    cacheMiddleRoot.add(cjguiComposableVariableHeightList(1191, "cache-middle-scroll", 1192,
        cacheSource, cacheState, 10, 0, 0, CjguiComposableUiStyle(fixedHeight: 10)))
    if (!cacheState.revealKey(cacheSource, "exact_128")) { return 1 }
    let _ = CjguiComposableUiLayoutEngine.layout(cacheMiddleRoot, CjguiComposableUiRect(0, 0, 180, 10), 83)
    if (!cacheState.revealKey(cacheSource, "exact_0")) { return 1 }
    let cacheReturnScene = CjguiComposableUiLayoutEngine.layout(
        cacheMiddleRoot, CjguiComposableUiRect(0, 0, 180, 10), 84)

    let tailSource = ExactHeightVariableListSource(300, 10, 10)
    let tailState = CjguiComposableUiVirtualListState()
    let tailRoot = cjguiComposableVertical(1195, "tail-root", CjguiComposableUiStyle())
    tailRoot.add(cjguiComposableVariableHeightList(1196, "tail-scroll", 1197,
        tailSource, tailState, 10, 0, 0, CjguiComposableUiStyle(fixedHeight: 80)))
    if (!tailState.revealKey(tailSource, "exact_299")) { return 1 }
    let tailNarrowScene = CjguiComposableUiLayoutEngine.layout(
        tailRoot, CjguiComposableUiRect(0, 0, 180, 80), 85)
    let tailWideScene = CjguiComposableUiLayoutEngine.layout(
        tailRoot, CjguiComposableUiRect(0, 0, 360, 80), 86)
    let cacheBoundaryPass = cacheInitialPass && cacheReturnScene.isValid() && cacheSource.firstBuildCount() == 2 &&
        cacheState.materializedEnd() - cacheState.materializedStart() <= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        tailNarrowScene.nodeForId(10895299).bounds.height == 10 && tailWideScene.nodeForId(10895299).bounds.height == 10 &&
        tailState.materializedEnd() - tailState.materializedStart() <= CJGUI_COMPOSABLE_UI_MAX_VIRTUAL_MATERIALIZED_ROWS &&
        tailSource.lastBuildCount() == 2
    if (!require(cacheBoundaryPass,
        "variable_height_cache_eviction_mixed_rows_tail_reveal_and_width_invalidation")) { return 1 }

    // RED: a shared cache must not replay a region measured by a different
    // actual measurer.  The current production signature has no environment
    // binding, so this intentionally fails until Terra adds that contract.
    let environmentRoot = cjguiComposableVertical(1210, "environment-root", CjguiComposableUiStyle())
    let environmentRegion = cjguiComposableVertical(1211, "environment-region", CjguiComposableUiStyle(fixedHeight: 80),
        layoutReuseKey: "same-key-different-measurer")
    environmentRegion.add(cjguiComposableText(1212, "environment-copy", "环境度量", CjguiComposableUiStyle()))
    environmentRoot.add(environmentRegion)
    let environmentCache = CjguiComposableUiLayoutReuseCache()
    let environmentFirst = EnvironmentTextMeasurer(12, 48, "first")
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 87, environmentFirst,
        reuseCache: environmentCache)
    let environmentSecond = EnvironmentTextMeasurer(40, 48, "second")
    let environmentChanged = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 87, environmentSecond,
        reuseCache: environmentCache)
    let environmentReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 87, environmentSecond,
        reuseMeasurements: false)
    if (!require(sameResolvedProjection(environmentChanged.scene, environmentReference.scene) &&
        environmentChanged.metrics.subtreeReuseHitCount == 0 && environmentSecond.measureCallCount() > 0,
        "layout_cache_binds_actual_measurer_identity")) { return 1 }

    // RED: the same measurer instance may advance its font/platform
    // generation.  Reusing the old entry after that mutation is equally
    // stale, even though object identity is unchanged.
    let mutableEnvironmentCache = CjguiComposableUiLayoutReuseCache()
    let mutableEnvironment = EnvironmentTextMeasurer(14, 52, "mutable")
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 88, mutableEnvironment,
        reuseCache: mutableEnvironmentCache)
    mutableEnvironment.setLineHeight(36)
    let mutableEnvironmentChanged = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 88, mutableEnvironment,
        reuseCache: mutableEnvironmentCache)
    let mutableEnvironmentReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        environmentRoot, CjguiComposableUiRect(0, 0, 200, 120), 88, mutableEnvironment,
        reuseMeasurements: false)
    if (!require(sameResolvedProjection(mutableEnvironmentChanged.scene, mutableEnvironmentReference.scene) &&
        mutableEnvironmentChanged.metrics.subtreeReuseHitCount == 0 &&
        mutableEnvironmentChanged.scene.nodeForId(1212).bounds.height == 40,
        "layout_cache_revalidates_same_measurer_after_environment_change")) { return 1 }

    // RED: an explicit short key must not turn a very large retained output
    // into a cache entry merely because the key itself is small.
    let largeOutputRoot = cjguiComposableVertical(1220, "large-output-root", CjguiComposableUiStyle())
    let largeOutputRegion = cjguiComposableVertical(1221, "large-output-region",
        CjguiComposableUiStyle(fixedWidth: 180), layoutReuseKey: "short")
    largeOutputRegion.add(cjguiComposableText(1222, "large-output-copy", repeatedProbeText(300000),
        CjguiComposableUiStyle(fixedHeight: 20)))
    largeOutputRoot.add(largeOutputRegion)
    let largeOutputCache = CjguiComposableUiLayoutReuseCache()
    let largeOutputFirst = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        largeOutputRoot, CjguiComposableUiRect(0, 0, 200, 60), 89,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: largeOutputCache)
    let largeOutputSecond = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        largeOutputRoot, CjguiComposableUiRect(0, 0, 200, 60), 89,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: largeOutputCache)
    let largeOutputReference = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        largeOutputRoot, CjguiComposableUiRect(0, 0, 200, 60), 89,
        CjguiComposableUiFallbackTextMeasurer(), reuseMeasurements: false)
    if (!require(largeOutputFirst.scene.isValid() && largeOutputSecond.scene.isValid() &&
        sameResolvedProjection(largeOutputSecond.scene, largeOutputReference.scene) &&
        largeOutputFirst.metrics.subtreeReuseBudgetSkipCount > 0 &&
        largeOutputSecond.metrics.subtreeReuseHitCount == 0 && largeOutputSecond.metrics.subtreeReuseEntryCount == 0 &&
        largeOutputSecond.metrics.subtreeReuseRetainedStringBytes == 0,
        "short_layout_key_rejects_large_retained_output")) { return 1 }

    // RED: an ordinary keyed ancestor is still unsafe when its descendants
    // contain mutable scroll materialization or layer ordering. Both cases
    // must remain on the canonical path; a short key cannot waive that rule.
    let nestedScrollRoot = cjguiComposableVertical(1230, "nested-scroll-root", CjguiComposableUiStyle())
    let nestedScrollRegion = cjguiComposableVertical(1231, "nested-scroll-region", CjguiComposableUiStyle(),
        layoutReuseKey: "short-scroll-key")
    let nestedScroll = cjguiComposableScrollArea(1232, "nested-scroll", 0,
        CjguiComposableUiStyle(fixedHeight: 40, clipsContent: true))
    nestedScroll.add(cjguiComposableText(1233, "nested-scroll-copy", "可变滚动内容", CjguiComposableUiStyle()))
    nestedScrollRegion.add(nestedScroll); nestedScrollRoot.add(nestedScrollRegion)
    let nestedScrollCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        nestedScrollRoot, CjguiComposableUiRect(0, 0, 200, 60), 90,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: nestedScrollCache)
    let nestedScrollSecond = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        nestedScrollRoot, CjguiComposableUiRect(0, 0, 200, 60), 90,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: nestedScrollCache)

    let nestedLayerRoot = cjguiComposableVertical(1240, "nested-layer-root", CjguiComposableUiStyle())
    let nestedLayerRegion = cjguiComposableVertical(1241, "nested-layer-region", CjguiComposableUiStyle(),
        layoutReuseKey: "short-layer-key")
    let nestedLayer = cjguiComposableLayerHost(1242, "nested-layer-host", CjguiComposableUiStyle())
    nestedLayer.add(cjguiComposableText(1243, "nested-layer-copy", "可变层内容", CjguiComposableUiStyle()))
    nestedLayerRegion.add(nestedLayer); nestedLayerRoot.add(nestedLayerRegion)
    let nestedLayerCache = CjguiComposableUiLayoutReuseCache()
    let _ = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        nestedLayerRoot, CjguiComposableUiRect(0, 0, 200, 60), 91,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: nestedLayerCache)
    let nestedLayerSecond = CjguiComposableUiLayoutEngine.layoutWithMetrics(
        nestedLayerRoot, CjguiComposableUiRect(0, 0, 200, 60), 91,
        CjguiComposableUiFallbackTextMeasurer(), reuseCache: nestedLayerCache)
    if (!require(nestedScrollSecond.metrics.subtreeReuseRevalidationNodeCount > 0 &&
        nestedScrollSecond.metrics.subtreeReuseHitCount == 0 &&
        nestedScrollSecond.metrics.subtreeReuseEntryCount == 0 &&
        nestedLayerSecond.metrics.subtreeReuseRevalidationNodeCount > 0 &&
        nestedLayerSecond.metrics.subtreeReuseHitCount == 0 && nestedLayerSecond.metrics.subtreeReuseEntryCount == 0,
        "short_layout_key_rejects_nested_scroll_and_layer_regions")) { return 1 }

    // A layer host has one base branch and z-ordered Cangjie-owned layers.
    // The modal backdrop blocks a background visual click, menu content wins
    // its own hit test, and an anchored popup flips above an edge trigger.
    let layerRoot = cjguiComposableLayerHost(1200, "layer-host", CjguiComposableUiStyle())
    let layerBase = cjguiComposableVertical(1201, "layer-base", CjguiComposableUiStyle())
    layerBase.add(cjguiComposableButton(1202, "background-action", "背景动作", "BACKGROUND", 1,
        CjguiComposableUiStyle(fixedWidth: 180, fixedHeight: 80), operationActionName: "BACKGROUND"))
    layerRoot.add(layerBase)
    let edgeTrigger = cjguiComposableButton(1203, "edge-trigger", "打开菜单", "OPEN_MENU", 1,
        CjguiComposableUiStyle(fixedWidth: 60, fixedHeight: 24, alignX: CJGUI_COMPOSABLE_UI_ALIGN_END), operationActionName: "OPEN_MENU")
    layerBase.add(edgeTrigger)
    let menu = cjguiComposableAnchoredLayer(1204, "layer-menu", "menu-1", "menu", "edge-trigger", 1203,
        CjguiComposableUiStyle(fixedWidth: 100, fixedHeight: 52, background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)))
    menu.add(cjguiComposableButton(1205, "menu-choice", "菜单动作", "MENU_ACTION", 1,
        CjguiComposableUiStyle(fixedHeight: 26), operationActionName: "MENU_ACTION"))
    let dialog = cjguiComposableDialogLayer(1206, "layer-dialog", "dialog-1", "rule-detail", 1202,
        CjguiComposableUiStyle(fixedWidth: 140, fixedHeight: 90, background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0)),
        initialFocusNodeId: 1208)
    dialog.add(cjguiComposableTextInput(1208, "dialog-input", "名称", "草稿", 1,
        CjguiComposableUiStyle(fixedHeight: 30), fieldId: "name", operationActionName: "EDIT_DRAFT_TEXT"))
    layerRoot.add(menu); layerRoot.add(dialog)
    let layerScene = CjguiComposableUiLayoutEngine.layout(layerRoot, CjguiComposableUiRect(0, 0, 200, 120), 72)
    if (!require(layerScene.nodeForId(1205).bounds.y < layerScene.nodeForId(1203).bounds.y &&
        layerScene.hitTest(8, 8).nodeId != 1202 && layerScene.hitTest(
            layerScene.nodeForId(1208).bounds.x + 2, layerScene.nodeForId(1208).bounds.y + 2
        ).nodeId == 1208 && layerScene.focusScopeForNode(1208) == "dialog-1",
        "layer_host_z_order_modal_hit_and_anchor_flip")) { return 1 }
    if (!require(verifyScopedIdentityCost("small", 4) && verifyScopedIdentityCost("medium", 24) &&
        verifyScopedIdentityCost("large", 128), "scoped_identity_cost_and_retention_30_samples")) { return 1 }
    println("composable ui probe: scene nodes=${scene.nodes().size} hit=111 version=41")
    return 0
}
