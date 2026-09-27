// Shared image-resource capability tests: ONE application declaration, published
// for discovery, referenced by logical key + exact version from a generated
// candidate, resolved into the SAME native image node the handwritten tree uses.
//
// What is pinned here:
//   * declaration validation (supported type, positive version, key/name/path),
//     duplicate/update/remove semantics and the declaration revision;
//   * public discovery carries key/type/version/name and never the raster path;
//   * a candidate is rejected as a whole when the key is unknown, the version
//     does not match, the reference is missing or the content mode is not one the
//     native path implements;
//   * the accepted instance read-back reports WHICH logical resource and version
//     the window accepted, without exposing the path.
package cjgui

import std.collection.*
import cjgui_shared_operation_core.*

private func imageTestCatalog(): CjguiGeneratedUiCapabilityCatalog {
    let catalog = CjguiGeneratedUiCapabilityCatalog()
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("vertical",
        CjguiGeneratedUiPresentation.containerStyleProperties(), true, childLimit: 8))
    let imageProperties = ArrayList<CjguiGeneratedUiPropertySpec>([
        CjguiGeneratedUiPropertySpec("resource", "STRING", required: true, maxLength: 64),
        CjguiGeneratedUiPropertySpec("resourceVersion", "INTEGER", required: true, minimum: 1, maximum: 1000000),
        CjguiGeneratedUiPropertySpec("contentMode", "STRING", values: ArrayList<String>(["fit", "fill"]))
    ])
    for (property in CjguiGeneratedUiPresentation.leafStyleProperties()) {
        imageProperties.add(property)
    }
    let _ = catalog.registerComponent(CjguiGeneratedUiComponentSpec("image", imageProperties, false))
    return catalog
}

private func imageTestSpec(key: String, version: Int64, rasterPath: String,
                           name!: String = "测试图标"): CjguiGeneratedUiImageResourceSpec {
    return CjguiGeneratedUiImageResourceSpec(key, "PNG", version, name, rasterPath)
}

private class ImageBuilt {
    let holder: CjguiGeneratedUiStructureHolder
    let node: CjguiComposableUiNode

    init(holder: CjguiGeneratedUiStructureHolder, node: CjguiComposableUiNode) {
        this.holder = holder
        this.node = node
    }
}

private func imageTestBuild(catalog: CjguiGeneratedUiCapabilityCatalog,
                            spec: CjguiGeneratedUiNodeSpec): ImageBuilt {
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    let submitted = holder.submit(spec, provider)
    if (!submitted.candidateAccepted) {
        return ImageBuilt(holder, cjguiComposableText(-1, "rejected:${submitted.reason}", "",
            CjguiComposableUiStyle()))
    }
    let _ = holder.beginCandidateRefresh()
    let node = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    let _ = holder.commitCandidateRefresh()
    return ImageBuilt(holder, node)
}

/// Accepts one image structure through the REAL holder lifecycle (submit →
/// begin → build → prepare → commit) and reports whether it reached the accepted
/// scene.
private func imageTestAcceptImage(holder: CjguiGeneratedUiStructureHolder,
                                  provider: GeneratedTestProvider,
                                  key: String, version: String): Bool {
    if (!holder.submit(imageTestNode(key, version), provider).candidateAccepted) {
        return false
    }
    if (!holder.beginCandidateRefresh()) {
        return false
    }
    let _ = holder.buildRefreshNode(provider)
    if (!holder.prepareCandidateRefresh()) {
        return false
    }
    return holder.commitCandidateRefresh()
}

private func imageTestFind(node: CjguiComposableUiNode, nodeId: Int64): ?CjguiComposableUiNode {
    if (node.nodeId == nodeId) {
        return Some(node)
    }
    for (child in node.children()) {
        if (let Some(found) <- imageTestFind(child, nodeId)) {
            return Some(found)
        }
    }
    return None
}

private func imageTestNode(resource: String, version: String, contentMode!: String = "fit"):
    CjguiGeneratedUiNodeSpec {
    let properties = HashMap<String, String>()
    if (resource.size > 0) {
        properties.add("resource", resource)
    }
    if (version.size > 0) {
        properties.add("resourceVersion", version)
    }
    if (contentMode.size > 0) {
        properties.add("contentMode", contentMode)
    }
    properties.add("fixedWidth", "64")
    properties.add("fixedHeight", "64")
    let children = ArrayList<CjguiGeneratedUiNodeSpec>()
    children.add(CjguiGeneratedUiNodeSpec("icon", "image", properties: properties))
    return CjguiGeneratedUiNodeSpec("root", "vertical", children: children)
}

@Test
func generatedImageResourceDeclarationIsValidatedAndPublished(): Unit {
    let catalog = imageTestCatalog()
    // Unsupported type, non-positive version, empty name/path are refused.
    @Assert(catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("bad-type", "JPEG", 1, "名称", "a.jpeg")), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("image_resource_declaration_invalid"), true)
    @Assert(catalog.registerImageResource(imageTestSpec("zero", 0, "a.png")), false)
    @Assert(catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("empty-name", "PNG", 1, "", "a.png")), false)
    @Assert(catalog.registerImageResource(
        CjguiGeneratedUiImageResourceSpec("empty-path", "PNG", 1, "名称", "")), false)

    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 1, "composable-beacon.png")), true)
    // One declaration per logical key: a duplicate is a registration error, a
    // version change goes through update.
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 2, "composable-beacon-coral.png")), false)
    @Assert(catalog.lastRegistrationRejection().startsWith("duplicate_image_resource_key"), true)
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 2, "composable-beacon-coral.png")), true)
    @Assert(catalog.updateImageResource(imageTestSpec("missing", 1, "x.png")), false)

    // Strict resolution: the old version no longer resolves after the update.
    @Assert(catalog.imageResourceFor("beacon", 2).isSome(), true)
    @Assert(catalog.imageResourceFor("beacon", 1).isNone(), true)
    @Assert(catalog.imageResourceFor("beacon", 3).isNone(), true)

    // Discovery publishes identity/type/version/name and NEVER the raster path.
    let described = CjguiGeneratedUiEncoding.describe(catalog)
    @Assert(described.contains("IMAGE_RESOURCE beacon PNG 2 测试图标"), true)
    @Assert(described.contains("composable-beacon-coral.png"), false)
    @Assert(described.contains("path_hex"), false)

    // The declaration revision moves with the declaration.
    let revision = catalog.imageResourceRevision()
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 3, "third.png")), true)
    @Assert(catalog.imageResourceRevision() != revision, true)
    // A metadata-only NAME change invalidates the published discovery and
    // observation identity without needing a new image version.
    let namedRevision = catalog.imageResourceRevision()
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 3, "third.png", name: "改名后的图标")), true)
    @Assert(catalog.imageResourceRevision() != namedRevision, true)
    @Assert(CjguiGeneratedUiEncoding.describe(catalog).contains(
        "IMAGE_RESOURCE beacon PNG 3 改名后的图标"), true)
    @Assert(catalog.removeImageResource("beacon"), true)
    @Assert(catalog.removeImageResource("beacon"), false)
    @Assert(catalog.imageResourceFor("beacon", 3).isNone(), true)
}

@Test
func generatedImageCandidateRejectsUnresolvableReferences(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 1, "composable-beacon.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()

    let unknown = holder.submit(imageTestNode("missing", "1"), provider)
    @Assert(unknown.candidateAccepted, false)
    @Assert(unknown.reason, "image_resource_not_registered")

    let wrongVersion = holder.submit(imageTestNode("beacon", "2"), provider)
    @Assert(wrongVersion.candidateAccepted, false)
    @Assert(wrongVersion.reason, "image_resource_version_mismatch")

    // Omitting the required property is the generic required-property refusal;
    // an explicitly EMPTY reference is the image-specific one.
    let missingReference = holder.submit(imageTestNode("", "1"), provider)
    @Assert(missingReference.candidateAccepted, false)
    @Assert(missingReference.reason, "missing_required_property")
    let emptyReference = HashMap<String, String>()
    emptyReference.add("resource", "")
    emptyReference.add("resourceVersion", "1")
    let emptyChildren = ArrayList<CjguiGeneratedUiNodeSpec>()
    emptyChildren.add(CjguiGeneratedUiNodeSpec("icon", "image", properties: emptyReference))
    let emptyNode = holder.submit(CjguiGeneratedUiNodeSpec("root", "vertical", children: emptyChildren), provider)
    @Assert(emptyNode.candidateAccepted, false)
    @Assert(emptyNode.reason, "image_resource_missing")

    let badMode = holder.submit(imageTestNode("beacon", "1", contentMode: "stretch"), provider)
    @Assert(badMode.candidateAccepted, false)
    @Assert(badMode.reason, "image_content_mode_unsupported")

    // A rejected candidate never disturbs the accepted interface (none yet).
    @Assert(holder.structureVersion(), 0)
    @Assert(holder.hasPendingCandidate(), false)

    // The valid reference is accepted and really builds the native image node.
    let built = imageTestBuild(catalog, imageTestNode("beacon", "1", contentMode: "fill"))
    @Assert(built.holder.structureVersion(), 1)
    let nodeId = built.holder.nodeIdForKey("icon")
    @Assert(nodeId > 0, true)
    var found = false
    for (node in CjguiComposableUiLayoutEngine.layout(built.node,
        CjguiComposableUiRect(0, 0, 200, 200), 1).nodes()) {
        if (node.nodeId == nodeId) {
            found = true
            @Assert(node.nodeKind, CJGUI_COMPOSABLE_UI_IMAGE)
            @Assert(node.imageResourceId, "beacon")
            @Assert(node.imageResourceVersion, 1)
            @Assert(node.imageResourcePath, "composable-beacon.png")
            @Assert(node.imageContentMode, 2)
            @Assert(node.bounds.width, 64)
        }
    }
    @Assert(found, true)
}

@Test
func generatedImageReadBackNamesTheResourceNotThePath(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 1, "composable-beacon.png")), true)
    let controller = ImageTestController(catalog)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let holder = controller.imageTestHolder()
    // The controller submitted nothing; drive the holder directly through the
    // same scene transaction the window runs.
    let provider = GeneratedTestProvider()
    let built = imageTestBuild(catalog, imageTestNode("beacon", "1"))
    let _ = built
    @Assert(holder.submit(imageTestNode("beacon", "1"), provider).candidateAccepted, true)
    controller.bump()
    let refreshed = window.refreshIfNeeded()
    println("IMAGE_TEST_READBACK refreshed=${refreshed} pending=${holder.hasPendingCandidate()} outcome='${holder.lastSceneOutcome()}' version=${holder.structureVersion()}")
    @Assert(refreshed, true)
    @Assert(holder.structureVersion(), 1)

    let payload = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(payload.contains("kind=image"), true)
    @Assert(payload.contains("resource=beacon"), true)
    @Assert(payload.contains("resource_version=1"), true)
    @Assert(payload.contains("composable-beacon.png"), false)
    window.close()
}

/// An ORDINARY refresh after the application redeclares the SAME key at a NEW
/// version must not clear the accepted generated interface. The accepted scene
/// keeps the resource binding it was accepted with; only a NEW candidate is
/// validated against the current catalog. Removal behaves the same until a valid
/// replacement is accepted.
@Test
func generatedAcceptedImageSurvivesCatalogVersionSwap(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 1, "composable-beacon.png")), true)
    let controller = ImageTestController(catalog)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    let holder = controller.imageTestHolder()
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(imageTestNode("beacon", "1"), provider).candidateAccepted, true)
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    @Assert(holder.structureVersion(), 1)
    let before = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(before.contains("kind=image"), true)
    @Assert(before.contains("resource=beacon"), true)
    @Assert(before.contains("resource_version=1"), true)

    // The application redeclares the SAME key at v2, exactly like the rule
    // window's own control does.
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 2, "composable-beacon-coral.png")), true)
    @Assert(catalog.imageResourceFor("beacon", 1).isNone(), true)
    // An ORDINARY refresh, with NO structure resubmission: the accepted scene and
    // its editor must stay addressable on the version it was accepted with.
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let after = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(after.contains("kind=image"), true)
    @Assert(after.contains("resource=beacon"), true)
    @Assert(after.contains("resource_version=1"), true)

    // A NEW submission may not use the withdrawn version; the current one can.
    let withdrawn = holder.submit(imageTestNode("beacon", "1"), provider)
    @Assert(withdrawn.candidateAccepted, false)
    @Assert(withdrawn.reason, "image_resource_version_mismatch")
    @Assert(holder.submit(imageTestNode("beacon", "2"), provider).candidateAccepted, true)
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let second = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(second.contains("kind=image"), true)
    @Assert(second.contains("resource_version=2"), true)

    // Removal is the same policy: the accepted scene holds the binding it was
    // accepted with until a valid structure replacement is accepted.
    @Assert(catalog.removeImageResource("beacon"), true)
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let removed = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(removed.contains("kind=image"), true)
    @Assert(removed.contains("resource_version=2"), true)
    // ... but a new candidate can no longer reference the withdrawn key.
    @Assert(holder.submit(imageTestNode("beacon", "2"), provider).candidateAccepted, false)

    // Re-registration uses the same change source: the accepted scene is still
    // the one it accepted, and a new candidate can use the key again.
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 3, "composable-beacon.png")), true)
    @Assert(holder.submit(imageTestNode("beacon", "3"), provider).candidateAccepted, true)
    controller.bump()
    @Assert(window.refreshIfNeeded(), true)
    let reregistered = CjguiGeneratedUiEncoding.acceptedInstancesPayload(
        cjguiGeneratedUiAcceptedInstances(window, holder))
    @Assert(reregistered.contains("kind=image"), true)
    @Assert(reregistered.contains("resource_version=3"), true)
    window.close()
}

/// Minimal controller exposing one image-capable holder to the window.
private class ImageTestController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let catalog: CjguiGeneratedUiCapabilityCatalog
    let holder: CjguiGeneratedUiStructureHolder
    private var versionValue: Int64 = 1

    init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        this.catalog = catalog
        this.holder = CjguiGeneratedUiStructureHolder(catalog)
    }

    public func imageTestHolder(): CjguiGeneratedUiStructureHolder {
        return holder
    }

    /// A declared scene revision change is what makes the window run one
    /// begin/build/prepare/commit transaction, exactly like the real consumers.
    public func bump(): Unit {
        versionValue += 1
    }

    public func uiSceneVersion(): Int64 {
        return versionValue
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "image-test-root", CjguiComposableUiStyle())
        // The refresh hook builds the PENDING candidate; building the accepted
        // node here would leave the candidate unprepared and never commit.
        root.add(holder.buildRefreshNode(GeneratedTestProvider()))
        return root
    }

    public func beginSceneRefresh(): Bool {
        return holder.beginCandidateRefresh()
    }

    public func prepareSceneRefresh(): Bool {
        return holder.prepareCandidateRefresh()
    }

    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }

    public func commitSceneRefresh(): Unit {
        holder.commitCandidateRefresh()
    }

    public func rollbackSceneRefresh(): Unit {
        holder.rollbackCandidateRefresh()
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// A generated region shares the window's already prepared image. Its first
/// accepted snapshot must report that native fact even when no later loader
/// completion will request another frame.
private class ImageRegionTestBinding <: CjguiGeneratedUiRegionBinding {
    public func ownerRevision(): Int64 { return 1 }
    public func fieldResourceId(fieldId: String): Int64 { return -1 }
    public func fieldOperationResourceId(fieldId: String): Int64 { return -1 }
    public func draftText(fieldId: String): String { return "" }
    public func appliedText(fieldId: String): String { return "" }
    public func draftBoolean(fieldId: String): ?Bool { return None }
    public func executeAction(actionName: String, nodeKey: String): CjguiGeneratedUiActionResult {
        return CjguiGeneratedUiActionResult(false, "")
    }
    public func actionAvailable(actionName: String): Bool { return false }
    public func applyFieldIntent(intent: CjguiGeneratedUiIntent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
}

private class ImageRegionTestController <: CjguiComposableUiController & CjguiComposableUiSceneRefreshParticipant {
    let region: CjguiGeneratedUiWindowRegion

    init(catalog: CjguiGeneratedUiCapabilityCatalog) {
        region = CjguiGeneratedUiWindowRegion(catalog, ImageRegionTestBinding(), "image-hot-region")
    }

    public func uiSceneVersion(): Int64 { return region.revision() }
    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(81000, "image-hot-root", CjguiComposableUiStyle())
        root.add(region.buildNode())
        return root
    }
    public func beginSceneRefresh(): Bool { return region.beginSceneRefresh() }
    public func prepareSceneRefresh(): Bool { return region.prepareSceneRefresh() }
    public func candidateSceneCommands(): ArrayList<CjguiComposableUiCommand> {
        return ArrayList<CjguiComposableUiCommand>()
    }
    public func commitSceneRefresh(): Unit { region.commitSceneRefresh() }
    public func rollbackSceneRefresh(): Unit { region.rollbackSceneRefresh() }
    public func disposeSceneRefreshResources(): Unit { region.disposeSceneRefreshResources() }
    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return region.handleEvent(event)
    }
    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }
    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

@Test
func hotImageAcceptedByGeneratedRegionPublishesReadyWithoutAnotherCompletion(): Unit {
    let path = "resources/composable-beacon.png"
    let key = "image-hot-icon"
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec(key, 1, path)), true)
    let controller = ImageRegionTestController(catalog)
    let window = CjguiComposableUiWindow(controller)
    @Assert(window.start(), true)
    controller.region.attachWindow(window)
    let requested = window.prepareImageResource(path, key, 1)
    @Assert(requested.state == "loading" || requested.state == "ready", true)
    var ready = requested.state == "ready"
    var turns: Int64 = 0
    while (!ready && turns < 80) {
        let _ = CjguiComposableUiWindowTurnScheduler.pumpWithoutExternal(window, turnBudgetMs: 4u32)
        ready = window.imageResourceStatus(path, key, 1).state == "ready"
        turns += 1
    }
    @Assert(ready, true)
    // Consume the loader's completion BEFORE the generated candidate. There is
    // no subsequent completion epoch to repair a stale public state snapshot.
    @Assert(window.refreshIfNeeded(), true)
    let submitted = controller.region.submitStructure("""
GENERATED_UI_STRUCTURE 1
NODE 0 imageRoot vertical
NODE 1 icon image
PROPERTY 1 icon resource image-hot-icon
PROPERTY 1 icon resourceVersion 1
PROPERTY 1 icon fixedWidth 48
PROPERTY 1 icon fixedHeight 48
END
""", 0)
    @Assert(submitted.candidateAccepted, true)
    @Assert(window.refreshIfNeeded(), true)
    @Assert(controller.region.acceptedStructureVersion(), 1)
    @Assert(controller.region.acceptedInstancesPayload().contains(
        "resource=image-hot-icon resource_version=1 resource_state=ready"), true)
    window.close()
}

/// Content identity: ONE published `(key, version)` denotes ONE resolved raster.
/// Replacing the actual resource description behind the same identity would make
/// two different results share a public identity — an accepted instance still
/// holding the old path would be described as the same thing as a new one. A
/// content change therefore requires a NEW version; a metadata (display name)
/// change may stay on the same version and still publish an observation change.
/// Removing the declaration does not lift the rule: re-registering the same
/// version with another raster is the same conflict, because an accepted
/// instance may still be holding the retired identity.
@Test
func generatedImageResourceKeepsContentIdentityPerVersion(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 1, "beacon-v1.png")), true)

    // Same key + same version + different raster is refused, and the published
    // declaration is untouched.
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 1, "beacon-v1-swapped.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_content_identity_conflict")
    let kept = match (catalog.imageResourceFor("beacon", 1)) {
        case Some(value) => value
        case None => CjguiGeneratedUiImageResourceSpec("", "", 0, "", "")
    }
    @Assert(kept.rasterPath, "beacon-v1.png")

    // A metadata-only change on the same version stays legal and publishes.
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 1, "beacon-v1.png", name: "改名后的图标")), true)

    // A new version may carry a different raster, and the old identity is not
    // silently re-pointed.
    @Assert(catalog.updateImageResource(imageTestSpec("beacon", 2, "beacon-v2.png")), true)
    let current = match (catalog.imageResourceFor("beacon", 2)) {
        case Some(value) => value
        case None => CjguiGeneratedUiImageResourceSpec("", "", 0, "", "")
    }
    @Assert(current.rasterPath, "beacon-v2.png")

    // Removal, then re-registration of the SAME identity with the same raster is
    // legal; the same identity with a different raster is still refused.
    @Assert(catalog.removeImageResource("beacon"), true)
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 2, "beacon-v2.png")), true)
    @Assert(catalog.removeImageResource("beacon"), true)
    @Assert(catalog.registerImageResource(imageTestSpec("beacon", 2, "beacon-v2-other.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_content_identity_conflict")
}

/// The identity table is bounded, but it may only forget identities NO live
/// accepted/candidate binding references: evicting a live `icon@1 -> rasterA`
/// would let the same published identity be re-registered as another raster while
/// an accepted window still shows A.
@Test
func boundedImageIdentityTableNeverEvictsALiveReference(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    let _ = holder.beginCandidateRefresh()
    let built = holder.buildRefreshNode(provider)
    let _ = holder.prepareCandidateRefresh()
    @Assert(holder.commitCandidateRefresh(), true)
    let iconId = holder.nodeIdForKey("icon")
    @Assert(iconId > 0, true)
    let acceptedImage = match (imageTestFind(built, iconId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(acceptedImage.imageResourcePath, "rasterA.png")

    // Enough legal declarations to push the oldest identity out of the FIFO.
    var index: Int64 = 0
    while (index < 300) {
        let key = "filler${index}"
        @Assert(catalog.registerImageResource(imageTestSpec(key, 1, "${key}.png")), true)
        index += 1
    }

    // The still-referenced identity must NOT be re-pointed at another raster.
    @Assert(catalog.removeImageResource("icon"), true)
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterB.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_content_identity_conflict")

    // The accepted window still shows A and re-registering the SAME raster is legal.
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    @Assert(catalog.imageContentIdentityRasterFor("icon", 1), "rasterA.png")
    let rebuilt = holder.buildRefreshNode(provider)
    let keptImage = match (imageTestFind(rebuilt, iconId)) {
        case Some(value) => value
        case None => cjguiComposableText(-1, "missing", "", CjguiComposableUiStyle())
    }
    @Assert(keptImage.imageResourcePath, "rasterA.png")
    // Releasing the holder's hold is what allows the record to be reclaimed.
    holder.releaseAcceptedImageIdentities()
}

/// When every slot is held by a live reference, a new identity is refused
/// explicitly instead of silently evicting live state.
@Test
func fullImageIdentityTableRefusesNewIdentitiesInsteadOfEvictingLiveOnes(): Unit {
    let catalog = imageTestCatalog()
    // Every slot is held by a live reference.
    var index: Int64 = 0
    while (index < 256) {
        catalog.retainImageIdentity("live${index}", 1)
        index += 1
    }
    @Assert(catalog.registerImageResource(imageTestSpec("overflow", 1, "overflow.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_identity_capacity")
    // The refusal is a capacity decision, not a permanent block: releasing ONE
    // live hold frees a slot and the same declaration is then accepted.
    catalog.releaseImageIdentity("live0", 1)
    @Assert(catalog.registerImageResource(imageTestSpec("overflow", 1, "overflow.png")), true)
}

/// One accepted binding owns exactly ONE hold, so repeated successful commits of
/// the same image must not accumulate counts, and the window's release must free
/// everything the shared catalog was keeping for it.
@Test
func repeatedSuccessfulCommitsOfTheSameImageKeepExactlyOneHold(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    var round = 0
    while (round < 5) {
        @Assert(imageTestAcceptImage(holder, provider, "icon", "1"), true)
        @Assert(catalog.liveImageIdentityHoldCount(), 1)
        @Assert(catalog.liveImageIdentityCount(), 1)
        round += 1
    }
    // The real dispose path: the window calls this when it is torn down.
    holder.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
    @Assert(catalog.liveImageIdentityCount(), 0)
}

/// Two windows share one catalog: closing A must not release B's hold, and the
/// identity stays protected until the LAST holder releases it.
@Test
func closingOneHolderKeepsTheOtherHoldersImageIdentity(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    let holderA = CjguiGeneratedUiStructureHolder(catalog)
    let holderB = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(imageTestAcceptImage(holderA, provider, "icon", "1"), true)
    @Assert(imageTestAcceptImage(holderB, provider, "icon", "1"), true)
    @Assert(catalog.liveImageIdentityHoldCount(), 2)
    holderA.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    // B still holds it: the published identity may not be re-pointed.
    @Assert(catalog.updateImageResource(imageTestSpec("icon", 1, "rasterB.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_content_identity_conflict")
    holderB.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
}

/// A rejected, superseded or simply rolled-back attempt releases ONLY its own
/// holds: the accepted scene keeps its reference, and no path double-releases it.
@Test
func rejectedAndSupersededCandidatesReleaseOnlyTheirOwnHolds(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(imageTestAcceptImage(holder, provider, "icon", "1"), true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)

    // A candidate whose scene is rejected: build it (it resolves and holds the
    // image), then roll back.
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    holder.rollbackCandidateRefresh()
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    @Assert(catalog.liveImageIdentityCount(), 1)

    // A rollback with NO pending candidate (for example a refresh rejected before
    // the build) must not release the accepted binding through an aliased map.
    holder.rollbackCandidateRefresh()
    @Assert(catalog.liveImageIdentityHoldCount(), 1)

    // Superseding an uncommitted candidate drops only the superseded attempt.
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    @Assert(imageTestAcceptImage(holder, provider, "icon", "1"), true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    holder.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
}

/// A declared key/version is authoritative even when no window displays it and
/// its bounded history slot was reclaimed: the SAME identity may not be
/// re-pointed at another raster.
@Test
func declaredIdentityCannotBeRepointedAfterHistoryEviction(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "rasterA.png")), true)
    var index: Int64 = 0
    while (index < 300) {
        @Assert(catalog.registerImageResource(imageTestSpec("filler${index}", 1, "filler${index}.png")), true)
        index += 1
    }
    @Assert(catalog.updateImageResource(imageTestSpec("icon", 1, "rasterB.png")), false)
    @Assert(catalog.lastRegistrationRejection(), "image_resource_content_identity_conflict")
    let kept = match (catalog.imageResourceFor("icon", 1)) {
        case Some(value) => value
        case None => CjguiGeneratedUiImageResourceSpec("", "", 0, "", "")
    }
    @Assert(kept.rasterPath, "rasterA.png")
    @Assert(catalog.imageContentIdentityRasterFor("icon", 1), "rasterA.png")
    // A different VERSION is a different identity and stays legal.
    @Assert(catalog.updateImageResource(imageTestSpec("icon", 2, "rasterA-v2.png")), true)
}

/// ONE pending candidate may be built more than once (a refresh that is retried
/// or rebuilt before it is prepared). Every build resolves and retains the same
/// published identity, so the candidate must END with exactly one hold for it:
/// the second build has to return the hold the first build recorded, and commit
/// must transfer exactly that one hold.
@Test
func samePendingCandidateBuiltTwiceKeepsOneImageHold(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "icon.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let first = holder.buildRefreshNode(provider)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    let second = holder.buildRefreshNode(provider)
    @Assert(first.nodeId >= 0 && second.nodeId >= 0, true)
    // The repeated build of the SAME candidate must not accumulate a second hold.
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    @Assert(holder.rejectedReason(), "")
    @Assert(holder.prepareCandidateRefresh(), true)
    @Assert(holder.commitCandidateRefresh(), true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    holder.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
}

/// The same repeated build on a candidate that is then REJECTED: rolling back
/// must return every hold this candidate took, not only the last build's.
@Test
func rejectedCandidateBuiltTwiceReleasesEveryImageHold(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "icon.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let _ = holder.buildRefreshNode(provider)
    let _ = holder.buildRefreshNode(provider)
    @Assert(holder.prepareCandidateRefresh(), true)
    holder.rollbackCandidateRefresh()
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
}

/// The SECOND build of one pending candidate can itself FAIL (its identity is
/// withdrawn between the two passes). That path must return every hold the first
/// build recorded and leave the holder with none - a failed rebuild is not an
/// excuse for a leaked reference.
@Test
func failedSecondBuildOfOneCandidateReleasesItsFirstHold(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "icon.png")), true)
    let holder = CjguiGeneratedUiStructureHolder(catalog)
    let provider = GeneratedTestProvider()
    @Assert(holder.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(holder.beginCandidateRefresh(), true)
    let first = holder.buildRefreshNode(provider)
    @Assert(first.nodeId >= 0, true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    // The application re-declares the SAME key at v2: v1 no longer resolves, so the
    // rebuild of this candidate cannot be produced.
    @Assert(catalog.updateImageResource(imageTestSpec("icon", 2, "icon-v2.png")), true)
    let second = holder.buildRefreshNode(provider)
    @Assert(holder.lastSceneOutcome(), "scene_rejected:image_resource_not_registered")
    // The build failed, so the scene was refused - and NO hold survived it: the
    // candidate gave back the reference its first build took.
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
    // The window then rolls the attempt back; the accepted (empty) structure is
    // unchanged and nothing else is released.
    holder.rollbackCandidateRefresh()
    @Assert(holder.hasPendingCandidate(), false)
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
    @Assert(second.nodeId >= 0, true)
}

/// Superseding a repeated-build candidate drops exactly its own holds and leaves
/// another holder's reference to the SAME published identity untouched.
@Test
func supersededRepeatedBuildCandidateDoesNotDisturbAnotherHolder(): Unit {
    let catalog = imageTestCatalog()
    @Assert(catalog.registerImageResource(imageTestSpec("icon", 1, "icon.png")), true)
    let provider = GeneratedTestProvider()
    let stable = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(imageTestAcceptImage(stable, provider, "icon", "1"), true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)

    let superseding = CjguiGeneratedUiStructureHolder(catalog)
    @Assert(superseding.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(superseding.beginCandidateRefresh(), true)
    let _ = superseding.buildRefreshNode(provider)
    let _ = superseding.buildRefreshNode(provider)
    @Assert(catalog.liveImageIdentityHoldCount(), 2)
    // A new submission supersedes the uncommitted candidate: only ITS hold goes.
    @Assert(superseding.submit(imageTestNode("icon", "1"), provider).candidateAccepted, true)
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    superseding.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 1)
    stable.releaseAcceptedImageIdentities()
    @Assert(catalog.liveImageIdentityHoldCount(), 0)
}
