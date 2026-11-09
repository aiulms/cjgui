package cjgui_shared_operation_core

import std.collection.ArrayList
import std.sync.*

private const CJGUI_SHARED_IMAGE_HISTORY_LIMIT: Int64 = 4
private const CJGUI_SHARED_IMAGE_HISTORY_BYTE_LIMIT: Int64 = 2 * 1024 * 1024

/// One application's image slot. Human paste/drop and authorized external
/// selection call this same owner transaction; a UI candidate never writes it.
/// Methods serialize the owner version and retained-resource catalog together.
public class CjguiSharedOperationImageOwner {
    private let lock = Mutex()
    private var revision: Int64 = 0
    private var current: ?CjguiSharedOperationTransferOffer = None
    private var pixelWidth: Int64 = 0
    private var pixelHeight: Int64 = 0
    private let retained = ArrayList<CjguiSharedOperationOwnedImage>()
    private var retainedBytes: Int64 = 0

    public init() {}

    public func version(): Int64 {
        return synchronized(lock) { revision }
    }

    public func snapshot(): CjguiSharedOperationImageSnapshot {
        return synchronized(lock) {
            CjguiSharedOperationImageSnapshot(revision, current, pixelWidth, pixelHeight,
                ownedResourcesUnlocked())
        }
    }

    /// Returns metadata only. It never returns encoded image bytes or a source
    /// path, so an external context projection can safely describe available
    /// application-owned resources without granting access to the payload.
    public func ownedResources(): ArrayList<CjguiSharedOperationImageResource> {
        return synchronized(lock) { ownedResourcesUnlocked() }
    }

    public func retainedByteCount(): Int64 {
        return synchronized(lock) { retainedBytes }
    }

    /// `width/height` are the framework decoder's checked facts, not fields
    /// claimed by the sender. Call only after framework decode/preflight has
    /// succeeded. The owner repeats bounds before committing the CAS.
    public func accept(offer: CjguiSharedOperationTransferOffer, expectedVersion: Int64,
        width: Int64, height: Int64): CjguiSharedOperationTransferResult {
        return synchronized(lock) {
            if (expectedVersion != revision) {
                return CjguiSharedOperationTransferResult.rejected(revision, "version_conflict",
                    format: Some(offer.format), isVersionConflict: true)
            }
            if (!isAdmissibleImage(offer, width, height) || revision >= 0x7FFFFFFFFFFFFFFE) {
                return CjguiSharedOperationTransferResult.rejected(revision, "image_not_admitted",
                    format: Some(offer.format))
            }
            commitUnlocked(offer, width, height)
        }
    }

    /// External actions may select only an offer previously imported by this
    /// owner. The expected version is checked in the same critical section as
    /// lookup and commit, matching paste/drop CAS semantics.
    public func selectOwnedImage(resourceId: String, expectedVersion: Int64): CjguiSharedOperationTransferResult {
        return synchronized(lock) {
            if (expectedVersion != revision) {
                return CjguiSharedOperationTransferResult.rejected(revision, "version_conflict",
                    isVersionConflict: true)
            }
            if (revision >= 0x7FFFFFFFFFFFFFFE) {
                return CjguiSharedOperationTransferResult.rejected(revision, "version_exhausted")
            }
            var index: Int64 = 0
            while (index < retained.size) {
                let entry = retained[index]
                if (entry.resourceId == resourceId) {
                    if (!isAdmissibleImage(entry.offer, entry.width, entry.height)) {
                        return CjguiSharedOperationTransferResult.rejected(revision, "image_not_admitted",
                            format: Some(entry.offer.format))
                    }
                    return commitUnlocked(entry.offer, entry.width, entry.height)
                }
                index += 1
            }
            CjguiSharedOperationTransferResult.rejected(revision, "unknown_owned_image")
        }
    }

    /// Numeric offer identities are convenient for the existing shared
    /// operation action protocol, whose targets and integer arguments are
    /// already bounded numeric values. The ID remains an owner-local lookup,
    /// not a capability by itself.
    public func selectOwnedImageByIdentity(offerIdentity: Int64,
        expectedVersion: Int64): CjguiSharedOperationTransferResult {
        return synchronized(lock) {
            if (expectedVersion != revision) {
                return CjguiSharedOperationTransferResult.rejected(revision,
                    "version_conflict", isVersionConflict: true)
            }
            if (revision >= 0x7FFFFFFFFFFFFFFE) {
                return CjguiSharedOperationTransferResult.rejected(revision, "version_exhausted")
            }
            var index: Int64 = 0
            while (index < retained.size) {
                let entry = retained[index]
                if (entry.offer.offerIdentity == offerIdentity) {
                    if (!isAdmissibleImage(entry.offer, entry.width, entry.height)) {
                        return CjguiSharedOperationTransferResult.rejected(revision,
                            "image_not_admitted", format: Some(entry.offer.format))
                    }
                    return commitUnlocked(entry.offer, entry.width, entry.height)
                }
                index += 1
            }
            CjguiSharedOperationTransferResult.rejected(revision, "unknown_owned_image")
        }
    }

    private func isAdmissibleImage(offer: CjguiSharedOperationTransferOffer, width: Int64, height: Int64): Bool {
        return offer.format.kind == "BINARY" && offer.format.identifier == "image/png" &&
            offer.payloadByteCount > 0 && offer.payloadByteCount <= 512 * 1024 &&
            width > 0 && height > 0 && width <= 2048 && height <= 2048 &&
            height <= 1048576 / width
    }

    private func commitUnlocked(offer: CjguiSharedOperationTransferOffer, width: Int64,
        height: Int64): CjguiSharedOperationTransferResult {
        let before = revision
        current = Some(offer)
        pixelWidth = width
        pixelHeight = height
        retainUnlocked(offer, width, height)
        revision += 1
        return CjguiSharedOperationTransferResult.fromActionResult(
            CjguiSharedOperationActionResult(true, false, before, revision, "applied"), offer)
    }

    private func retainUnlocked(offer: CjguiSharedOperationTransferOffer, width: Int64, height: Int64): Unit {
        var index: Int64 = 0
        while (index < retained.size) {
            if (retained[index].offer.offerIdentity == offer.offerIdentity) {
                retainedBytes -= retained[index].offer.payloadByteCount
                let _ = retained.remove(at: index)
                break
            }
            index += 1
        }
        retained.add(CjguiSharedOperationOwnedImage(offer, width, height))
        retainedBytes += offer.payloadByteCount

        // The newly committed offer is now current and therefore cannot be
        // evicted. Oldest retained entries leave first until both bounds hold.
        while (retained.size > CJGUI_SHARED_IMAGE_HISTORY_LIMIT ||
            retainedBytes > CJGUI_SHARED_IMAGE_HISTORY_BYTE_LIMIT) {
            var evictionIndex: Int64 = 0
            let currentIdentity = if (let Some(value) <- current) { value.offerIdentity } else { -1 }
            while (evictionIndex < retained.size &&
                retained[evictionIndex].offer.offerIdentity == currentIdentity) {
                evictionIndex += 1
            }
            if (evictionIndex >= retained.size) { return }
            retainedBytes -= retained[evictionIndex].offer.payloadByteCount
            let _ = retained.remove(at: evictionIndex)
        }
    }

    private func ownedResourcesUnlocked(): ArrayList<CjguiSharedOperationImageResource> {
        let result = ArrayList<CjguiSharedOperationImageResource>()
        for (entry in retained) {
            result.add(CjguiSharedOperationImageResource(entry.resourceId, entry.offer.offerIdentity,
                entry.offer.contentDigest, entry.offer.payloadByteCount, entry.width, entry.height, revision))
        }
        return result
    }
}

private class CjguiSharedOperationOwnedImage {
    public let offer: CjguiSharedOperationTransferOffer
    public let width: Int64
    public let height: Int64
    public let resourceId: String
    public init(offer: CjguiSharedOperationTransferOffer, width: Int64, height: Int64) {
        this.offer = offer
        this.width = width
        this.height = height
        this.resourceId = CjguiSharedOperationImageResource.identityFor(offer.offerIdentity)
    }
}

/// Safe external discovery projection for one imported image. It contains a
/// stable opaque ID and bounded metadata, never the offer or its byte array.
public class CjguiSharedOperationImageResource {
    public let resourceId: String
    public let offerIdentity: Int64
    public let contentDigest: String
    public let encodedBytes: Int64
    public let width: Int64
    public let height: Int64
    public let ownerVersion: Int64

    public init(resourceId: String, offerIdentity: Int64, contentDigest: String,
        encodedBytes: Int64, width: Int64, height: Int64, ownerVersion: Int64) {
        this.resourceId = resourceId
        this.offerIdentity = offerIdentity
        this.contentDigest = contentDigest
        this.encodedBytes = encodedBytes
        this.width = width
        this.height = height
        this.ownerVersion = ownerVersion
    }

    public static func identityFor(offerIdentity: Int64): String {
        return "cjgui-owned-image:${offerIdentity}"
    }
}

public class CjguiSharedOperationImageSnapshot {
    public let version: Int64
    /// In-process application convenience only; external projections should
    /// publish `ownedResources`, which contains metadata and no encoded bytes.
    public let offer: ?CjguiSharedOperationTransferOffer
    public let width: Int64
    public let height: Int64
    public let contentDigest: String
    public let encodedBytes: Int64
    public let ownedResources: ArrayList<CjguiSharedOperationImageResource>

    public init(version: Int64, offer: ?CjguiSharedOperationTransferOffer, width: Int64,
        height: Int64, ownedResources: ArrayList<CjguiSharedOperationImageResource>) {
        this.version = version
        this.offer = offer
        this.width = width
        this.height = height
        this.contentDigest = if (let Some(value) <- offer) { value.contentDigest } else { "" }
        this.encodedBytes = if (let Some(value) <- offer) { value.payloadByteCount } else { 0 }
        this.ownedResources = ArrayList<CjguiSharedOperationImageResource>(ownedResources)
    }
}

/// Adapter for the existing application-owned domain and authorized local
/// connection. Discovery publishes a single stable owner slot plus metadata
/// for retained images. The SELECT action takes the imported offer identity
/// as an INTEGER argument; authorization still applies to the stable slot.
public class CjguiSharedOperationImageOwnerDomain <: CjguiSharedOperationDomain {
    private let owner: CjguiSharedOperationImageOwner
    private let ownerResourceId: Int64

    public init(owner: CjguiSharedOperationImageOwner, ownerResourceId: Int64) {
        if (ownerResourceId <= 0) {
            throw IllegalArgumentException("image_owner_resource_id_must_be_positive")
        }
        this.owner = owner
        this.ownerResourceId = ownerResourceId
    }

    public func resourceType(): String { return "owned_png_image_slot" }

    public func contextSnapshot(): CjguiSharedOperationContextSnapshot {
        let state = owner.snapshot()
        let fields = ArrayList<CjguiSharedOperationField>()
        fields.add(CjguiSharedOperationField("ownerVersion", CjguiSharedOperationValue.integer(state.version)))
        fields.add(CjguiSharedOperationField("currentImageResourceId", CjguiSharedOperationValue.integer(
            if (let Some(value) <- state.offer) { value.offerIdentity } else { -1 })))
        fields.add(CjguiSharedOperationField("currentImageDigest", CjguiSharedOperationValue.string(state.contentDigest)))
        fields.add(CjguiSharedOperationField("currentImageWidth", CjguiSharedOperationValue.integer(state.width)))
        fields.add(CjguiSharedOperationField("currentImageHeight", CjguiSharedOperationValue.integer(state.height)))
        fields.add(CjguiSharedOperationField("ownedImageCount",
            CjguiSharedOperationValue.integer(state.ownedResources.size)))

        var index: Int64 = 0
        for (image in state.ownedResources) {
            let prefix = "ownedImage${index}"
            fields.add(CjguiSharedOperationField("${prefix}ResourceId",
                CjguiSharedOperationValue.integer(image.offerIdentity)))
            fields.add(CjguiSharedOperationField("${prefix}Digest",
                CjguiSharedOperationValue.string(image.contentDigest)))
            fields.add(CjguiSharedOperationField("${prefix}EncodedBytes",
                CjguiSharedOperationValue.integer(image.encodedBytes)))
            fields.add(CjguiSharedOperationField("${prefix}Width",
                CjguiSharedOperationValue.integer(image.width)))
            fields.add(CjguiSharedOperationField("${prefix}Height",
                CjguiSharedOperationValue.integer(image.height)))
            index += 1
        }
        return CjguiSharedOperationContextSnapshot(state.version, "PNG 图像槽",
            resourceType(), ArrayList<CjguiSharedOperationResource>([
                CjguiSharedOperationResource(ownerResourceId, "导入图像", fields)
            ]), streamIdentity: "png-image-owner-${ownerResourceId}")
    }

    public func actionDescriptors(): ArrayList<CjguiSharedOperationActionDescriptor> {
        return ArrayList<CjguiSharedOperationActionDescriptor>([
            CjguiSharedOperationActionDescriptor("SELECT_OWNED_IMAGE", "选择已导入图像",
                ArrayList<CjguiSharedOperationParameterDescriptor>([
                    CjguiSharedOperationParameterDescriptor("resourceId", "INTEGER", true)
                ]), 1, 1)
        ])
    }

    public func executeFromHuman(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeSelection(invocation, owner.version())
    }

    public func executeFromExternal(invocation: CjguiSharedOperationActionInvocation): CjguiSharedOperationActionResult {
        return executeSelection(invocation, invocation.expectedVersion)
    }

    private func executeSelection(invocation: CjguiSharedOperationActionInvocation,
        expectedVersion: Int64): CjguiSharedOperationActionResult {
        let before = owner.version()
        if (invocation.actionName != "SELECT_OWNED_IMAGE") {
            return CjguiSharedOperationActionResult(false, false, before, before, "unknown_action")
        }
        if (invocation.targetResourceIds.size != 1 || invocation.targetResourceIds[0] != ownerResourceId) {
            return CjguiSharedOperationActionResult(false, false, before, before, "unknown_resource")
        }
        if (invocation.arguments.size != 1 || invocation.arguments[0].name != "resourceId" ||
            invocation.arguments[0].value.valueType != "INTEGER") {
            return CjguiSharedOperationActionResult(false, false, before, before, "invalid_parameters")
        }
        let result = owner.selectOwnedImageByIdentity(
            invocation.arguments[0].value.integerValue, expectedVersion)
        return CjguiSharedOperationActionResult(result.applied, result.isVersionConflict,
            result.versionBefore, result.versionAfter, result.reason)
    }
}
