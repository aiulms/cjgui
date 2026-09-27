package cjgui_shared_operation_core

import std.collection.*
import std.unittest.*
import std.unittest.testmacro.*

private func ownerFixtureOffer(byteCount: Int64, fill: Byte, sourceId: Int64):
    ?CjguiSharedOperationTransferOffer {
    return CjguiSharedOperationTransferOffer.createBinary(
        "COPY", "fixture", "window-image-owner", sourceId,
        CjguiSharedOperationTransferFormat.png(), Array<Byte>(byteCount, repeat: fill))
}

private func imageOwnerAuthorization(ownerResourceId: Int64, allowSelect: Bool):
    CjguiSharedOperationExternalAuthorization {
    let scopes = ArrayList<CjguiSharedOperationExternalActionScope>([
        CjguiSharedOperationExternalActionScope("GET_CONTEXT",
            ArrayList<Int64>([ownerResourceId]), false)
    ])
    if (allowSelect) {
        scopes.add(CjguiSharedOperationExternalActionScope("SELECT_OWNED_IMAGE",
            ArrayList<Int64>([ownerResourceId]), false))
    }
    return CjguiSharedOperationExternalAuthorization("image-owner-test", "image-owner-capability", scopes)
}

private func selectOwnedImagePayload(ownerResourceId: Int64, expectedVersion: Int64,
    offerIdentity: Int64): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH image-owner-capability\n" +
        "INVOKE ${expectedVersion} SELECT_OWNED_IMAGE 1 1\nID ${ownerResourceId}\n" +
        "ARG resourceId INTEGER ${offerIdentity}"
}

@Test
func importedImageOwnerWillAcceptOnceAndPreserveOldOnConflict(): Unit {
    let image = CjguiSharedOperationImageOwner()
    let format = CjguiSharedOperationTransferFormat.png()
    let bytes: Array<Byte> = [0x89u8, 0u8, 0xffu8]
    let offer = CjguiSharedOperationTransferOffer.createBinary(
        "COPY", "fixture", "window-a", 1, format, bytes)
    if (let Some(value) <- offer) {
        let first = image.accept(value, 0, 3, 2)
        @Assert(first.applied, true)
        @Assert(image.snapshot().version, 1)
        @Assert(image.snapshot().contentDigest, value.contentDigest)
        let conflict = image.accept(value, 0, 3, 2)
        @Assert(conflict.applied, false)
        @Assert(conflict.isVersionConflict, true)
        @Assert(image.snapshot().version, 1)
        let invalid = image.accept(value, 1, 4096, 2)
        @Assert(invalid.applied, false)
        @Assert(image.snapshot().version, 1)
    } else {
        @Assert(false, true)
    }
}

@Test
func ownerPublishesSafeMetadataAndSelectsOnlyPreviouslyImportedImages(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    let original = ownerFixtureOffer(3, 0x2au8, 11)
    let replacement = ownerFixtureOffer(4, 0x51u8, 12)
    if (let Some(first) <- original) {
        if (let Some(second) <- replacement) {
            @Assert(owner.selectOwnedImage(
                CjguiSharedOperationImageResource.identityFor(first.offerIdentity), 0).reason,
                "unknown_owned_image")
            let imported = owner.accept(first, 0, 3, 2)
            @Assert(imported.applied, true)
            let listed = owner.ownedResources()
            @Assert(listed.size, 1)
            @Assert(listed[0].resourceId,
                CjguiSharedOperationImageResource.identityFor(first.offerIdentity))
            @Assert(listed[0].contentDigest, first.contentDigest)
            @Assert(listed[0].encodedBytes, 3)
            @Assert(listed[0].width, 3)
            @Assert(listed[0].height, 2)
            @Assert(listed[0].ownerVersion, 1)

            let swapped = owner.accept(second, 1, 2, 2)
            @Assert(swapped.applied, true)
            let oldSelected = owner.selectOwnedImage(listed[0].resourceId, 2)
            @Assert(oldSelected.applied, true)
            @Assert(oldSelected.versionBefore, 2)
            @Assert(oldSelected.versionAfter, 3)
            @Assert(owner.snapshot().contentDigest, first.contentDigest)
            @Assert(owner.version(), 3)

            // Repeating the same owner command is a normal new CAS transaction,
            // matching another paste of the exact same immutable offer.
            let repeated = owner.selectOwnedImage(listed[0].resourceId, 3)
            @Assert(repeated.applied, true)
            @Assert(repeated.versionBefore, 3)
            @Assert(repeated.versionAfter, 4)
            @Assert(owner.snapshot().contentDigest, first.contentDigest)
        } else {
            @Assert(false, true)
        }
    } else {
        @Assert(false, true)
    }
}

@Test
func ownedImageSelectionUsesOwnerCasAndCannotMutateForUnknownOrStaleIds(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    let image = ownerFixtureOffer(5, 0x63u8, 13)
    if (let Some(offer) <- image) {
        let accepted = owner.accept(offer, 0, 2, 2)
        @Assert(accepted.applied, true)
        let resourceId = CjguiSharedOperationImageResource.identityFor(offer.offerIdentity)
        let unknown = owner.selectOwnedImage("cjgui-owned-image:999999999", 1)
        @Assert(unknown.applied, false)
        @Assert(unknown.reason, "unknown_owned_image")
        @Assert(owner.version(), 1)
        let stale = owner.selectOwnedImage(resourceId, 0)
        @Assert(stale.applied, false)
        @Assert(stale.isVersionConflict, true)
        @Assert(stale.reason, "version_conflict")
        @Assert(owner.version(), 1)
        @Assert(owner.snapshot().contentDigest, offer.contentDigest)
    } else {
        @Assert(false, true)
    }
}

@Test
func retainedImageHistoryEvictsOldestNonCurrentAndStaysWithinTwoMiB(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    let ids = ArrayList<String>()
    var index: Int64 = 0
    var expectedVersion: Int64 = 0
    while (index < 5) {
        let fill: Byte = if (index == 0) { 0x01u8 } else if (index == 1) { 0x02u8 } else if
            (index == 2) { 0x03u8 } else if (index == 3) { 0x04u8 } else { 0x05u8 }
        if (let Some(offer) <- ownerFixtureOffer(512 * 1024, fill, index)) {
            let accepted = owner.accept(offer, expectedVersion, 16, 16)
            @Assert(accepted.applied, true)
            expectedVersion += 1
            ids.add(CjguiSharedOperationImageResource.identityFor(offer.offerIdentity))
        } else {
            @Assert(false, true)
        }
        index += 1
    }
    let resources = owner.ownedResources()
    @Assert(resources.size, 4)
    @Assert(owner.retainedByteCount(), 2 * 1024 * 1024)
    if (let Some(_) <- owner.snapshot().offer) {
        @Assert(true, true)
    } else {
        @Assert(false, true)
    }
    @Assert(resources[3].resourceId, ids[4])

    let evicted = owner.selectOwnedImage(ids[0], expectedVersion)
    @Assert(evicted.applied, false)
    @Assert(evicted.reason, "unknown_owned_image")
    @Assert(owner.version(), expectedVersion)
    let retained = owner.selectOwnedImage(ids[1], expectedVersion)
    @Assert(retained.applied, true)
    @Assert(owner.snapshot().version, expectedVersion + 1)
    @Assert(owner.retainedByteCount(), 2 * 1024 * 1024)
}

@Test
func imageOfferByteLimitRejectsOversizedPayloadBeforeOwnerMutation(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    let oversized = ownerFixtureOffer(512 * 1024 + 1, 0x77u8, 22)
    @Assert(oversized.isNone(), true)
    @Assert(owner.version(), 0)
    @Assert(owner.ownedResources().size, 0)
    @Assert(owner.retainedByteCount(), 0)
}

@Test
func externalImageOwnerDomainUsesExistingAuthorizationAndCasWithoutExposingBytes(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    let source = CjguiSharedOperationTransferOffer.createBinary("COPY", "fixture",
        "window-image-owner", 31, CjguiSharedOperationTransferFormat.png(),
        [0x41u8, 0x42u8, 0x43u8])
    let ownerResourceId: Int64 = 91001
    if (let Some(offer) <- source) {
        @Assert(owner.accept(offer, 0, 1, 1).applied, true)
        let domain = CjguiSharedOperationImageOwnerDomain(owner, ownerResourceId)
        let unauthorized = CjguiSharedOperationExternalConnection(domain,
            imageOwnerAuthorization(ownerResourceId, false))
        let denied = unauthorized.dispatchPayload(selectOwnedImagePayload(
            ownerResourceId, 1, offer.offerIdentity))
        @Assert(denied.contains("ERROR unauthorized_action"), true)
        @Assert(owner.version(), 1)

        let authorized = CjguiSharedOperationExternalConnection(domain,
            imageOwnerAuthorization(ownerResourceId, true))
        let discovered = authorized.dispatchPayload(
            "PROTOCOL CJGUI_SHARED_OPERATION/2\nAUTH image-owner-capability\nGET_CONTEXT 1\nID ${ownerResourceId}")
        @Assert(discovered.contains("ACTION SELECT_OWNED_IMAGE PARAMETERS 1 TARGETS 1 1"), true)
        @Assert(discovered.contains("FIELD ${ownerResourceId} ownerVersion INTEGER 1"), true)
        @Assert(discovered.contains("FIELD ${ownerResourceId} ownedImage0ResourceId INTEGER ${offer.offerIdentity}"), true)
        // STRING values are hex-encoded on this wire; the real socket client
        // below decodes and compares the exact digest text.
        @Assert(discovered.contains("currentImageDigest STRING"), true)
        @Assert(discovered.contains("ownedImage0Digest STRING"), true)
        @Assert(discovered.contains("ABC"), false)

        let unknown = authorized.dispatchPayload(selectOwnedImagePayload(
            ownerResourceId, 1, offer.offerIdentity + 999999))
        @Assert(unknown.contains("APPLIED false"), true)
        @Assert(owner.version(), 1)

        let stale = authorized.dispatchPayload(selectOwnedImagePayload(
            ownerResourceId, 0, offer.offerIdentity))
        @Assert(stale.contains("APPLIED false"), true)
        @Assert(stale.contains("CONFLICT true"), true)
        @Assert(owner.version(), 1)

        let selected = authorized.dispatchPayload(selectOwnedImagePayload(
            ownerResourceId, 1, offer.offerIdentity))
        @Assert(selected.contains("APPLIED true"), true)
        @Assert(selected.contains("VERSION_AFTER 2"), true)
        @Assert(owner.version(), 2)
    } else {
        @Assert(false, true)
    }
}

@Test
func imageOwnerDomainRejectsNonPositiveSlotIdentity(): Unit {
    let owner = CjguiSharedOperationImageOwner()
    try {
        let _ = CjguiSharedOperationImageOwnerDomain(owner, 0)
        @Assert(false, true)
    } catch (_: IllegalArgumentException) {
        @Assert(true, true)
    }
}
