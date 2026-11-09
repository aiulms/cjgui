package cjgui

import std.collection.*
import std.sync.*

// --- DS51 §12: holder-scoped view state identities ---------------------------

private let cjguiGeneratedUiHolderIdentityLock = Mutex()
private var cjguiGeneratedUiHolderIdentityNext: Int64 = 1
private let cjguiGeneratedUiParticipantIdentityLock = Mutex()
private var cjguiGeneratedUiParticipantIdentityNext: Int64 = 1

/// Process-local identity of one REAL structure holder. A mount belongs to the
/// holder that built it; a canonical scope string alone cannot express that.
func cjguiNextGeneratedUiHolderIdentity(): Int64 {
    synchronized(cjguiGeneratedUiHolderIdentityLock) {
        let value = cjguiGeneratedUiHolderIdentityNext
        cjguiGeneratedUiHolderIdentityNext += 1
        return value
    }
}

func cjguiNextGeneratedUiViewStateParticipantIdentity(): Int64 {
    synchronized(cjguiGeneratedUiParticipantIdentityLock) {
        let value = cjguiGeneratedUiParticipantIdentityNext
        cjguiGeneratedUiParticipantIdentityNext += 1
        return value
    }
}

/// Stability: experimental (DS51 §12). A composite factory whose build
/// materialises per-mount view state (scroll viewport, virtual-list geometry,
/// reveal target) exposes this so the structure holder publishes, rolls back and
/// disposes that state inside its OWN accept transaction.
///
/// The holder is the only publisher: a build that will not be accepted must
/// never publish or retire an accepted mount, and the retirement of the last
/// instance has no replacement build at all, so only the holder's committed
/// structure can say a mount is gone. `acceptedInstances` maps every composite
/// instance key the accepted structure declares to its component kind.
public interface CjguiGeneratedUiViewStateParticipant {
    /// Stable identity of the participant object (dedupe inside one holder).
    func viewStateParticipantIdentity(): Int64
    /// Publishes the mounts ONE holder transaction staged. Must be total.
    func commitViewStateTransaction(holderIdentity: Int64, transaction: Int64,
        acceptedInstances: HashMap<String, String>): Unit
    /// Drops the mounts ONE rejected/abandoned holder transaction staged. Only
    /// its own staging is touched; accepted mounts are never changed here.
    func rollbackViewStateTransaction(holderIdentity: Int64, transaction: Int64): Unit
    /// Releases every accepted and staged mount of one holder (window/region
    /// disposal). Repeating it is harmless; other holders stay untouched.
    func disposeViewState(holderIdentity: Int64): Unit
}

/// One ACCEPTED mount of a registered collection. The view owns only view
/// state (viewport, virtual-list geometry, reveal target); business data,
/// filtering and selection stay with the application's one source.
public class CjguiGeneratedCollectionView {
    public let instanceKey: String
    public let incarnation: Int64
    public let mountKey: String
    public var viewport: CjguiComposableUiScrollViewport
    private let pathValue: String
    private let holderIdentityValue: Int64
    private var presentationValue: String
    private let mountScopeValue: ?CjguiComposableUiIdentityScope
    private var stateValue: CjguiComposableUiVirtualListState
    private var rowsValue: ?CjguiGeneratedCollectionRows = None
    private var retiredValue: Bool = false

    init(instanceKey: String, incarnation: Int64, path: String, mountKey: String,
        holderIdentity: Int64, presentation: String, mountScope: ?CjguiComposableUiIdentityScope,
        viewport: CjguiComposableUiScrollViewport) {
        this.instanceKey = instanceKey
        this.incarnation = incarnation
        this.pathValue = path
        this.mountKey = mountKey
        this.holderIdentityValue = holderIdentity
        this.presentationValue = presentation
        this.mountScopeValue = mountScope
        this.viewport = viewport
        this.stateValue = CjguiComposableUiVirtualListState()
    }

    /// A removed/re-added instance retires its old view. A retired handle can
    /// no longer move scroll or resolve a reveal target.
    public func isRetired(): Bool {
        return retiredValue
    }

    func retire(): Unit {
        retiredValue = true
        rowsValue = None
    }

    func noteAcceptedRows(rows: CjguiGeneratedCollectionRows): Unit {
        if (retiredValue) { return }
        rowsValue = Some(rows)
    }

    /// The rows of the last ACCEPTED scene this mount belongs to (None before a
    /// commit publishes the mount). They are only evidence/diagnostic input; the
    /// data itself stays in the application's table source.
    func acceptedRows(): ?CjguiGeneratedCollectionRows {
        return rowsValue
    }

    func listState(): CjguiComposableUiVirtualListState {
        return stateValue
    }

    func path(): String {
        return pathValue
    }

    public func holderIdentity(): Int64 {
        return holderIdentityValue
    }

    func presentation(): String {
        return presentationValue
    }

    func mountScope(): ?CjguiComposableUiIdentityScope {
        return mountScopeValue
    }

    /// A candidate copy: same accepted identity, its OWN viewport and list state,
    /// seeded from the accepted facts. A candidate layout may therefore measure,
    /// scroll and re-declare without changing the accepted mount; a commit
    /// promotes the copies, a rollback drops them.
    func candidateCopy(presentation: String): CjguiGeneratedCollectionView {
        let copiedViewport = CjguiComposableUiScrollViewport()
        copiedViewport.stageExtents(viewport.contentExtent(), viewport.viewportExtent(), viewport.offset())
        copiedViewport.commitStagedExtents()
        let copy = CjguiGeneratedCollectionView(instanceKey, incarnation, pathValue, mountKey,
            holderIdentityValue, presentation, mountScopeValue, copiedViewport)
        copy.stateValue = stateValue.preparedLayoutCopy()
        return copy
    }

    /// Promotes the staged candidate's view state into THIS accepted handle, so
    /// the live scene (which references the candidate objects) and the accepted
    /// lookup keep naming one default and one offset. The staged wrapper itself
    /// is retired; the objects the scene holds are adopted, not copied again.
    func adoptStaged(staged: CjguiGeneratedCollectionView): Unit {
        this.viewport = staged.viewport
        this.stateValue = staged.stateValue
        this.presentationValue = staged.presentationValue
        this.rowsValue = None
        staged.retire()
    }

    /// Scrolls THIS mount's viewport to one business key using the existing
    /// variable-height sparse geometry. It never changes selection or data.
    public func revealItem(key: String): Bool {
        if (retiredValue || key.isEmpty()) { return false }
        if (let None <- rowsValue) { return false }
        let rows = rowsValue.getOrThrow()
        if (!stateValue.revealKey(rows, "data:${key}")) { return false }
        // Already at the target offset is a successful reveal, not a refusal:
        // requestOffset's false means "no change", not "target missing".
        let target = stateValue.scrollOffset()
        if (viewport.offset() == target) { return true }
        return viewport.requestOffset(target)
    }

    public func scrollOffset(): Int64 {
        return viewport.offset()
    }

    public func acceptedOffset(): Int64 {
        return viewport.acceptedOffset()
    }
}

/// Experimental compiled collection adapter. The application registers ONE real
/// source/table/selection declaration; a description can choose only its key and
/// list/table presentation. Data, callbacks and permission scopes never arrive
/// in the description. Register distinct, scoped sources for simultaneous views.
///
/// The existing table owns filtering/sorting, selection remains caller-owned,
/// and builds perform no owner writes. Each accepted (holder, region, instance,
/// incarnation) mount owns its own viewport, materialization state and reveal
/// target; the handwritten single-mount entry keeps its previous behavior.
///
/// Mount lifecycle belongs to the holder's accept transaction: a candidate
/// build only STAGES a view, and the holder publishes, rolls back or disposes
/// it. A build outside every transaction (handwritten/direct) keeps the legacy
/// immediate publication.
public class CjguiGeneratedUiCollection <: CjguiCompositeComponentFactory &
    CjguiGeneratedUiViewStateParticipant {
    public let key: String
    public let kind: String
    public let table: CjguiComposableUiTableSource
    public let selection: CjguiComposableUiCollectionSelection
    /// The handwritten/manual single-mount viewport. Generated mounts never
    /// share this object; each one is addressed by its accepted instance.
    public let viewport: CjguiComposableUiScrollViewport
    private let listSource: CjguiComposableUiVariableHeightListSource
    private let legacyState = CjguiComposableUiVirtualListState()
    private let participantIdentityValue: Int64 = cjguiNextGeneratedUiViewStateParticipantIdentity()
    // The rows wrapper the CURRENT manual build materialized.
    private var lastRowsSource: ?CjguiGeneratedCollectionRows = None
    // PUBLISHED accepted mounts only, keyed by holder + region path + incarnation.
    private let mounts = HashMap<String, CjguiGeneratedCollectionView>()
    // holder identity + region path (scope/instance key) -> published mount key.
    // The holder dimension is part of the identity: two independent holders may
    // legitimately use the SAME local scope and instance key (the default holder
    // scope is `generated-root` in both windows), so a path-only index would let
    // one scene retire the other holder's accepted mount. Removal is reconciled
    // against the accepted structure, never by "last built".
    private let acceptedMountKeys = HashMap<String, String>()
    // Candidate/staging mounts, keyed "<holder>:<transaction>" then mount key.
    // A rejected or abandoned transaction only ever drops its own staging.
    private let stagedMounts = HashMap<String, HashMap<String, CjguiGeneratedCollectionView>>()

    public init(key: String, kind: String, listSource: CjguiComposableUiVariableHeightListSource,
        table: CjguiComposableUiTableSource, selection: CjguiComposableUiCollectionSelection,
        viewport!: CjguiComposableUiScrollViewport = CjguiComposableUiScrollViewport()) {
        this.key = key
        this.kind = kind
        this.listSource = listSource
        this.table = table
        this.selection = selection
        this.viewport = viewport
    }

    public func viewStateParticipantIdentity(): Int64 {
        return participantIdentityValue
    }

    /// The same compiled declaration used by handwritten buildNode. Explicit
    /// collection enum is discoverable in the existing catalog; no new RPC.
    public func register(catalog: CjguiGeneratedUiCapabilityCatalog): Bool {
        if (key.isEmpty() || key.size > 80 || kind.isEmpty()) {
            return false
        }
        let properties = CjguiGeneratedUiPresentation.leafStyleProperties()
        properties.add(
            CjguiGeneratedUiPropertySpec("collection", "STRING", required: true, maxLength: 80,
                values: ArrayList<String>([key]),
                semantics: "application-registered collection reference; data and actions stay application-owned",
                stability: "experimental", backendSupport: "macOS verified; other backends not_run"))
        properties.add(
            CjguiGeneratedUiPropertySpec("presentation", "STRING", required: true,
                values: ArrayList<String>(["list", "table"]),
                semantics: "view projection only; preserves source, selection and owner draft"))
        return catalog.registerComposite(
            CjguiCompositeComponentSpec(kind, properties,
                ArrayList<CjguiCompositeElementSpec>(
                    [CjguiCompositeElementSpec("viewport", CJGUI_COMPOSITE_ELEMENT_CONTAINER),
                        CjguiCompositeElementSpec("content", CJGUI_COMPOSITE_ELEMENT_CONTAINER, parentKey: "viewport")]),
                expandedNodeLimit: 2, expandedDepthLimit: 2), this)
    }

    public func buildComposite(context: CjguiCompositeBuildContext): CjguiComposableUiNode {
        let root = context.element("viewport").getOrThrow()
        let content = context.element("content").getOrThrow()
        var mount: ?CjguiGeneratedCollectionView = None
        var holder: ?CjguiComposableUiIdentityScope = None
        var rowScope: ?CjguiComposableUiIdentityScope = context.holderScope()
        if (let Some(scope) <- context.holderScope()) {
            if (scope.isValid()) {
                holder = Some(scope)
                mount = Some(mountFor(context, scope))
                rowScope = Some(scope.child(context.instanceKey))
            }
        }
        // Immediate publication is reserved for a build OUTSIDE a holder
        // transaction (handwritten/direct use). Inside a transaction the holder
        // owns publication, rollback and disposal.
        let publishNow = context.acceptedBuild() && context.viewStateTransaction() == 0
        let node = buildNode(root.nodeId, root.semanticId, content.nodeId, content.semanticId,
            context.property("presentation"), context.resolvedStyle,
            identityScope: rowScope, mountView: mount, accepted: publishNow)
        if (publishNow) {
            // The accepted scene, not this call, says which instances exist:
            // an instance the new structure no longer declares has no
            // replacement build, so its mount must be retired here.
            if (let Some(scope) <- holder) {
                if (let Some(keys) <- context.acceptedSceneKeys()) {
                    retireRemovedMounts(context.holderIdentity(), scope, keys)
                }
            }
            retireReplacedMounts(context, context.holderScope())
        }
        return node
    }

    private func mountKeyFor(holderIdentity: Int64, path: String, incarnation: Int64): String {
        return "${holderIdentity}:${path}#${incarnation}"
    }

    private func acceptedKeyFor(holderIdentity: Int64, path: String): String {
        return "${holderIdentity}:${path}"
    }

    private func freshView(context: CjguiCompositeBuildContext, scope: CjguiComposableUiIdentityScope,
        path: String): CjguiGeneratedCollectionView {
        return CjguiGeneratedCollectionView(context.instanceKey, context.instanceIncarnation(), path,
            mountKeyFor(context.holderIdentity(), path, context.instanceIncarnation()),
            context.holderIdentity(), context.property("presentation"), Some(scope.child(context.instanceKey)),
            CjguiComposableUiScrollViewport())
    }

    private func mountFor(context: CjguiCompositeBuildContext,
        scope: CjguiComposableUiIdentityScope): CjguiGeneratedCollectionView {
        let path = "${scope.canonicalPath()}/${context.instanceKey}"
        let mountKey = mountKeyFor(context.holderIdentity(), path, context.instanceIncarnation())
        let transaction = context.viewStateTransaction()
        if (transaction > 0) {
            let stagedKey = "${context.holderIdentity()}:${transaction}"
            var staged = match (stagedMounts.get(stagedKey)) {
                case Some(value) => value
                case None => HashMap<String, CjguiGeneratedCollectionView>()
            }
            if (let Some(existing) <- staged.get(mountKey)) {
                return existing
            }
            // A candidate/render build prepares its OWN objects. Reusing the
            // accepted viewport/state and mutating it would make a rejected
            // attempt change facts the accepted scene is still using.
            let created = match (mounts.get(mountKey)) {
                case Some(published) => published.candidateCopy(context.property("presentation"))
                case None => freshView(context, scope, path)
            }
            staged.add(mountKey, created)
            stagedMounts.add(stagedKey, staged)
            return created
        }
        if (mounts.contains(mountKey)) {
            return mounts.get(mountKey).getOrThrow()
        }
        let created = freshView(context, scope, path)
        mounts.add(mountKey, created)
        if (!context.acceptedBuild()) {
            // Keep at most ONE unaccepted candidate per path: a rejected
            // candidate must not accumulate permanent view state. The accepted
            // incarnation is never touched here.
            let acceptedKey = match (acceptedMountKeys.get(
                acceptedKeyFor(context.holderIdentity(), path))) {
                case Some(value) => value
                case None => ""
            }
            let stale = ArrayList<String>()
            for ((candidateKey, view) in mounts) {
                if (candidateKey != mountKey && view.path() == path && !view.isRetired() &&
                    candidateKey != acceptedKey) {
                    stale.add(candidateKey)
                }
            }
            for (candidateKey in stale) {
                if (let Some(view) <- mounts.remove(candidateKey)) {
                    view.retire()
                }
            }
        }
        return created
    }

    /// Legacy/direct build only: no holder transaction owns this build, so the
    /// accepted scene's key set retires a mount whose instance disappeared.
    private func retireRemovedMounts(holderIdentity: Int64,
        scope: CjguiComposableUiIdentityScope, acceptedKeys: HashSet<String>): Unit {
        let stale = ArrayList<String>()
        for ((acceptedKey, _) in acceptedMountKeys) {
            let keyPrefix = "${holderIdentity}:"
            if (!acceptedKey.startsWith(keyPrefix)) { continue }
            let path = acceptedKey[keyPrefix.size..]
            let prefix = "${scope.canonicalPath()}/"
            if (!path.startsWith(prefix)) { continue }
            let instanceKey = path[prefix.size..]
            if (!acceptedKeys.contains(instanceKey)) {
                stale.add(acceptedKey)
            }
        }
        for (acceptedKey in stale) {
            if (let Some(mountKey) <- acceptedMountKeys.remove(acceptedKey)) {
                if (let Some(view) <- mounts.remove(mountKey)) {
                    view.retire()
                }
            }
        }
    }

    /// Legacy/direct build only: only an ACCEPTED build retires state. A
    /// candidate that talks about a new generation must not make the still
    /// accepted mount unusable.
    private func retireReplacedMounts(context: CjguiCompositeBuildContext,
        holder: ?CjguiComposableUiIdentityScope): Unit {
        if (let None <- holder) { return }
        let scope = holder.getOrThrow()
        let path = "${scope.canonicalPath()}/${context.instanceKey}"
        let keep = mountKeyFor(context.holderIdentity(), path, context.instanceIncarnation())
        let stale = ArrayList<String>()
        for ((mountKey, view) in mounts) {
            if (view.holderIdentity() == context.holderIdentity() && view.path() == path && mountKey != keep) {
                stale.add(mountKey)
            }
        }
        for (mountKey in stale) {
            if (let Some(view) <- mounts.remove(mountKey)) {
                // Only drop the accepted INDEX entry when it still points at
                // this stale mount: the freshly published replacement shares the
                // same (holder, path) key and must keep its entry.
                let acceptedKey = acceptedKeyFor(view.holderIdentity(), view.path())
                let indexed = match (acceptedMountKeys.get(acceptedKey)) {
                    case Some(value) => value == mountKey
                    case None => false
                }
                if (indexed) { acceptedMountKeys.remove(acceptedKey) }
                view.retire()
            }
        }
    }

    /// Handwritten and generated consumers call this same projection. The table
    /// header is a normal first virtual row (scrolls with content in this slice).
    /// No row node is created until the existing bounded materializer asks for it.
    public func buildNode(nodeId: Int64, semanticId: String, contentId: Int64, contentSemanticId: String,
        presentation: String, style: CjguiComposableUiStyle,
        identityScope!: ?CjguiComposableUiIdentityScope = None,
        mountView!: ?CjguiGeneratedCollectionView = None, accepted!: Bool = false): CjguiComposableUiNode {
        let rows = CjguiGeneratedCollectionRows(key, listSource, table, selection, presentation == "table",
            identityScope: identityScope)
        let activeViewport = match (mountView) {
            case Some(view) => view.viewport
            case None => viewport
        }
        let state = match (mountView) {
            case Some(view) => view.listState()
            case None => legacyState
        }
        match (mountView) {
            case Some(view) =>
                if (accepted) { view.noteAcceptedRows(rows) }
            case None =>
                this.lastRowsSource = rows
        }
        if (accepted) {
            if (let Some(view) <- mountView) {
                acceptedMountKeys.add(acceptedKeyFor(view.holderIdentity(), view.path()),
                    view.mountKey)
            }
        }
        state.setSelectedKey("data:${selection.focus()}")
        state.setFocusedKey("data:${selection.focus()}")
        let root = CjguiComposableUiNode(nodeId, semanticId, CJGUI_COMPOSABLE_UI_SCROLL_AREA, "", "", "SCROLL", -1,
            style, scrollOffset: activeViewport.offset(), scrollViewport: Some(activeViewport),
            variableHeightListSource: Some(rows),
            virtualListState: Some(state), virtualListContentNodeId: contentId,
            virtualListRowHeight: table.style().rowHeight, virtualListRowGap: 0, virtualListOverscan: 2,
            semanticRole: CJGUI_COMPOSABLE_UI_SEMANTIC_SCROLL_AREA)
        // Reuse the materializer's existing content-template seam.
        root.add(cjguiComposableVertical(contentId, contentSemanticId, CjguiComposableUiStyle()))
        return root
    }

    public func order(): CjguiComposableUiCollectionOrder {
        return CjguiComposableUiFlatCollectionOrder(table, {item => !item.key.isEmpty()})
    }

    private func acceptedRowsFor(view: CjguiGeneratedCollectionView): CjguiGeneratedCollectionRows {
        return CjguiGeneratedCollectionRows(key, listSource, table, selection,
            view.presentation() == "table", identityScope: view.mountScope())
    }

    private func refreshAcceptedRows(view: CjguiGeneratedCollectionView): Unit {
        view.noteAcceptedRows(acceptedRowsFor(view))
    }

    /// Publishes the mounts ONE holder transaction staged. The holder calls this
    /// only for a scene it really accepted, with every composite instance key the
    /// new accepted structure declares and its kind.
    public func commitViewStateTransaction(holderIdentity: Int64, transaction: Int64,
        acceptedInstances: HashMap<String, String>): Unit {
        let stagedKey = "${holderIdentity}:${transaction}"
        let staged = match (stagedMounts.remove(stagedKey)) {
            case Some(value) => value
            case None => HashMap<String, CjguiGeneratedCollectionView>()
        }
        for ((mountKey, view) in staged) {
            if (acceptedInstances.get(view.instanceKey) != Some(this.kind)) {
                // The accepted structure declares this key as another kind (or
                // not at all): the staged object never becomes an accepted view.
                view.retire()
                continue
            }
            let path = view.path()
            let acceptedKey = acceptedKeyFor(holderIdentity, path)
            let previous = acceptedMountKeys.get(acceptedKey)
            match (previous) {
                case Some(previousKey) =>
                    if (previousKey == mountKey) {
                        // Compatible reorder/refresh: the accepted handle keeps
                        // its identity and adopts the candidate-built state.
                        match (mounts.get(previousKey)) {
                            case Some(accepted) =>
                                accepted.adoptStaged(view)
                                refreshAcceptedRows(accepted)
                            case None =>
                                mounts.add(mountKey, view)
                                refreshAcceptedRows(view)
                        }
                    } else {
                        // Incompatible rebind: a new generation replaces the old.
                        if (let Some(old) <- mounts.remove(previousKey)) {
                            old.retire()
                        }
                        mounts.add(mountKey, view)
                        acceptedMountKeys.add(acceptedKey, mountKey)
                        refreshAcceptedRows(view)
                    }
                case None =>
                    mounts.add(mountKey, view)
                    acceptedMountKeys.add(acceptedKey, mountKey)
                    refreshAcceptedRows(view)
            }
        }
        // Reconcile removals against the accepted structure: this covers the
        // LAST instance (no replacement build exists), an area release and a
        // same-key kind replacement.
        let stale = ArrayList<String>()
        let holderPrefix = "${holderIdentity}:"
        for ((acceptedKey, mountKey) in acceptedMountKeys) {
            if (!acceptedKey.startsWith(holderPrefix)) { continue }
            match (mounts.get(mountKey)) {
                case Some(view) =>
                    if (view.holderIdentity() != holderIdentity) { continue }
                    if (acceptedInstances.get(view.instanceKey) != Some(this.kind)) {
                        stale.add(acceptedKey)
                    }
                case None =>
                    stale.add(acceptedKey)
            }
        }
        for (acceptedKey in stale) {
            if (let Some(mountKey) <- acceptedMountKeys.remove(acceptedKey)) {
                if (let Some(view) <- mounts.remove(mountKey)) {
                    view.retire()
                }
            }
        }
    }

    public func rollbackViewStateTransaction(holderIdentity: Int64, transaction: Int64): Unit {
        let stagedKey = "${holderIdentity}:${transaction}"
        if (let Some(staged) <- stagedMounts.remove(stagedKey)) {
            for ((_, view) in staged) {
                view.retire()
            }
        }
    }

    public func disposeViewState(holderIdentity: Int64): Unit {
        let prefix = "${holderIdentity}:"
        let stagedKeys = ArrayList<String>()
        for ((stagedKey, _) in stagedMounts) {
            if (stagedKey.startsWith(prefix)) {
                stagedKeys.add(stagedKey)
            }
        }
        for (stagedKey in stagedKeys) {
            if (let Some(staged) <- stagedMounts.remove(stagedKey)) {
                for ((_, view) in staged) {
                    view.retire()
                }
            }
        }
        let stale = ArrayList<String>()
        for ((acceptedKey, mountKey) in acceptedMountKeys) {
            if (!acceptedKey.startsWith(prefix)) { continue }
            if (let Some(view) <- mounts.get(mountKey)) {
                if (view.holderIdentity() == holderIdentity) {
                    stale.add(acceptedKey)
                }
            }
        }
        for (acceptedKey in stale) {
            if (let Some(mountKey) <- acceptedMountKeys.remove(acceptedKey)) {
                if (let Some(view) <- mounts.remove(mountKey)) {
                    view.retire()
                }
            }
        }
    }

    /// The accepted mount for one region scope and one declared instance key
    /// when the answer is UNIQUE. Two independent holders may legally use the
    /// same local scope and key (the default holder scope is `generated-root`),
    /// so ambiguity is a named miss: callers resolve their own holder through
    /// holder/region, never "the last accepted mount wins".
    public func acceptedView(scope: CjguiComposableUiIdentityScope,
        instanceKey: String): ?CjguiGeneratedCollectionView {
        let path = "${scope.canonicalPath()}/${instanceKey}"
        var found: ?CjguiGeneratedCollectionView = None
        for ((acceptedKey, mountKey) in acceptedMountKeys) {
            if (!acceptedKey.endsWith(":${path}")) { continue }
            if (let Some(view) <- mounts.get(mountKey)) {
                if (view.isRetired()) { continue }
                if (found.isSome()) { return None }
                found = Some(view)
            }
        }
        return found
    }

    /// The accepted view owned by ONE holder for a region path. A holder/region
    /// resolves its own mount with this overload; the scope-only query above is
    /// kept for the handwritten single-holder path and refuses ambiguity.
    public func acceptedView(scope: CjguiComposableUiIdentityScope,
        instanceKey: String, holderIdentity: Int64): ?CjguiGeneratedCollectionView {
        let path = "${scope.canonicalPath()}/${instanceKey}"
        let mountKey = match (acceptedMountKeys.get(acceptedKeyFor(holderIdentity, path))) {
            case Some(value) => value
            case None => return None
        }
        let view = match (mounts.get(mountKey)) {
            case Some(value) => value
            case None => return None
        }
        return if (view.isRetired()) { None } else { Some(view) }
    }

    /// Resolve the ONE accepted mount that owns this exact viewport object.
    /// This is how a focused/key event finds its own mount: a stale generation,
    /// a staged candidate copy or another holder's viewport does not match any
    /// accepted entry and resolves to None (never "the last built mount").
    public func acceptedViewForViewport(viewport: CjguiComposableUiScrollViewport): ?CjguiGeneratedCollectionView {
        var found: ?CjguiGeneratedCollectionView = None
        for ((_, mountKey) in acceptedMountKeys) {
            if (let Some(view) <- mounts.get(mountKey)) {
                if (view.isRetired() || !refEq(view.viewport, viewport)) { continue }
                if (found.isSome()) { return None }
                found = Some(view)
            }
        }
        return found
    }

    /// True only while this exact object is the published accepted view of its
    /// own holder and path. A stale handle from an earlier generation, an
    /// uncommitted staging copy, or the retired generation answers false.
    public func isAcceptedMount(view: CjguiGeneratedCollectionView): Bool {
        if (view.isRetired()) { return false }
        let acceptedKey = acceptedKeyFor(view.holderIdentity(), view.path())
        let mountKey = match (acceptedMountKeys.get(acceptedKey)) {
            case Some(value) => value
            case None => return false
        }
        let current = match (mounts.get(mountKey)) {
            case Some(value) => value
            case None => return false
        }
        return refEq(current, view)
    }

    public func mountCount(): Int64 {
        return mounts.size
    }

    /// Staged (unpublished) mounts across every open transaction. Test/diagnostic
    /// surface: a rejected candidate must leave this at zero.
    func stagedMountCount(): Int64 {
        var total: Int64 = 0
        for ((_, staged) in stagedMounts) {
            total += staged.size
        }
        return total
    }

    /// Addresses ONE accepted mount. A missing/retired target refuses; it never
    /// falls back to the last built or to every mount.
    public func revealItem(key: String, scope: CjguiComposableUiIdentityScope,
        instanceKey: String): Bool {
        if (let None <- acceptedView(scope, instanceKey)) { return false }
        return acceptedView(scope, instanceKey).getOrThrow().revealItem(key)
    }

    /// Reveals in the accepted mount of ONE holder. The scope-only overload
    /// above refuses ambiguous local scopes; the holder/region uses this one.
    public func revealItem(key: String, scope: CjguiComposableUiIdentityScope,
        instanceKey: String, holderIdentity: Int64): Bool {
        if (let None <- acceptedView(scope, instanceKey, holderIdentity)) { return false }
        return acceptedView(scope, instanceKey, holderIdentity).getOrThrow().revealItem(key)
    }

    /// Handwritten single-mount compatibility. Multi-mount consumers must name
    /// their accepted target above.
    public func revealItem(key: String): Bool {
        if (key.isEmpty()) { return false }
        if (let None <- lastRowsSource) { return false }
        let rows = lastRowsSource.getOrThrow()
        if (!legacyState.revealKey(rows, "data:${key}")) { return false }
        let target = legacyState.scrollOffset()
        if (viewport.offset() == target) { return true }
        return viewport.requestOffset(target)
    }
}

class CjguiGeneratedCollectionRows <: CjguiComposableUiVariableHeightListSource {
    private let headerKey: String
    private let list: CjguiComposableUiVariableHeightListSource
    private let table: CjguiComposableUiTableSource
    private let selection: CjguiComposableUiCollectionSelection
    private let showTable: Bool
    // The mount this materialisation belongs to. Row identities from the
    // application source are re-based below it, so two independent mounts
    // of one declaration do not compete for one registry key.
    private let identityScope: ?CjguiComposableUiIdentityScope
    init(key: String, list: CjguiComposableUiVariableHeightListSource, table: CjguiComposableUiTableSource,
        selection: CjguiComposableUiCollectionSelection, showTable: Bool,
        identityScope!: ?CjguiComposableUiIdentityScope = None) {
        // Prefix a length-framed key, impossible to equal an unchanged data key
        // in this wrapper: all data keys below are framed in the other namespace.
        this.headerKey = "header:${key.size}:${key}"
        this.list = list
        this.table = table
        this.selection = selection
        this.showTable = showTable
        this.identityScope = identityScope
    }
    public func itemCount(): Int64 {
        return table.itemCount() + if (showTable) {
            1
        } else {
            0
        }
    }
    public func itemAt(index: Int64): CjguiComposableUiVariableHeightListItem {
        if (index < 0 || index >= itemCount()) {
            return CjguiComposableUiVariableHeightListItem.missing()
        }
        if (showTable && index == 0) {
            return CjguiComposableUiVariableHeightListItem(headerKey, -1, "", table.layoutRevision(),
                estimatedHeight: table.style().headerHeight)
        }
        let item = table.itemAt(index - if (showTable) {
            1
        } else {
            0
        })
        return CjguiComposableUiVariableHeightListItem("data:${item.key}", item.resourceId, item.title,
            item.layoutRevision, estimatedHeight: item.estimatedHeight)
    }
    public func indexForKey(key: String): Int64 {
        if (showTable && key == headerKey) {
            return 0
        }
        if (!key.startsWith("data:")) {
            return -1
        }
        let index = table.indexForKey(key[5..])
        return if (index >= 0) {
            index + if (showTable) {
                1
            } else {
                0
            }
        } else {
            -1
        }
    }
    public func measurementGeneration(): Int64 {
        return table.measurementGeneration()
    }

    public func buildRow(item: CjguiComposableUiVariableHeightListItem, isSelected: Bool, isFocused: Bool): CjguiComposableUiNode {
        if (showTable && item.key == headerKey) {
            // The header is part of the same mount as its rows; leaving it
            // un-rebased would make two mounts compete for one identity.
            let header = table.buildHeader()
            return match (identityScope) {
                case Some(scope) => header.cloneForWindowCandidate(identityPrefix: scope)
                case None => header
            }
        }
        let index = table.indexForKey(item.key[5..])
        let original = table.itemAt(index)
        let selected = selection.isSelected(original.key)
        let focused = selection.focus() == original.key
        let row = if (showTable) {
            table.buildRow(original, selected, focused)
        } else {
            list.buildRow(original, selected, focused)
        }
        return match (identityScope) {
            case Some(scope) => row.cloneForWindowCandidate(identityPrefix: scope)
            case None => row
        }
    }
}
