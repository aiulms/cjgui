// 中文维护注释：本文件是 stage205 component demo RenderCommand admission owner。
// Owner: 消费 stage204 component demo state-update dry-run 与既有 RenderCommandPacket，
// 生成 internal admission preview，作为最小 UI framework demo 的可渲染命令输入。
// Truth: admission preview 是后端无关 value facts，不是 renderer submission。
// Stop-line: 不提交 renderer，不写 renderer/runtime state，不扩 public/native surface。
package cjgui

struct CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts {
    let didConsumeStage204ComponentDemoStateUpdateDryRun: Bool
    let didConsumeInternalRenderCommandPacket: Bool
    let didMapComponentDemoSemanticFixtureToRenderCommandPacket: Bool
    let didMaterializeRenderCommandAdmissionPreview: Bool
    let didBindAdmissionPreviewToOwnerLocalRollbackBoundary: Bool
    let didConfirmCommandPacketBackendAgnostic: Bool
    let didConfirmCommandPacketAvoidedRenderSideEffect: Bool
    let didPrepareStage206ComponentDemoPreviewPacketInput: Bool
    let didKeepRendererSubmissionBlocked: Bool
    let didKeepRendererStateWriteBlocked: Bool
    let didKeepRuntimeStateWriteBlocked: Bool
    let didKeepNativeBridgeExpansionBlocked: Bool
    let didKeepPublicComponentApiBlocked: Bool

    init(
        didConsumeStage204ComponentDemoStateUpdateDryRun: Bool,
        didConsumeInternalRenderCommandPacket: Bool,
        didMapComponentDemoSemanticFixtureToRenderCommandPacket: Bool,
        didMaterializeRenderCommandAdmissionPreview: Bool,
        didBindAdmissionPreviewToOwnerLocalRollbackBoundary: Bool,
        didConfirmCommandPacketBackendAgnostic: Bool,
        didConfirmCommandPacketAvoidedRenderSideEffect: Bool,
        didPrepareStage206ComponentDemoPreviewPacketInput: Bool,
        didKeepRendererSubmissionBlocked: Bool,
        didKeepRendererStateWriteBlocked: Bool,
        didKeepRuntimeStateWriteBlocked: Bool,
        didKeepNativeBridgeExpansionBlocked: Bool,
        didKeepPublicComponentApiBlocked: Bool
    ) {
        this.didConsumeStage204ComponentDemoStateUpdateDryRun =
            didConsumeStage204ComponentDemoStateUpdateDryRun
        this.didConsumeInternalRenderCommandPacket =
            didConsumeInternalRenderCommandPacket
        this.didMapComponentDemoSemanticFixtureToRenderCommandPacket =
            didMapComponentDemoSemanticFixtureToRenderCommandPacket
        this.didMaterializeRenderCommandAdmissionPreview =
            didMaterializeRenderCommandAdmissionPreview
        this.didBindAdmissionPreviewToOwnerLocalRollbackBoundary =
            didBindAdmissionPreviewToOwnerLocalRollbackBoundary
        this.didConfirmCommandPacketBackendAgnostic =
            didConfirmCommandPacketBackendAgnostic
        this.didConfirmCommandPacketAvoidedRenderSideEffect =
            didConfirmCommandPacketAvoidedRenderSideEffect
        this.didPrepareStage206ComponentDemoPreviewPacketInput =
            didPrepareStage206ComponentDemoPreviewPacketInput
        this.didKeepRendererSubmissionBlocked = didKeepRendererSubmissionBlocked
        this.didKeepRendererStateWriteBlocked =
            didKeepRendererStateWriteBlocked
        this.didKeepRuntimeStateWriteBlocked = didKeepRuntimeStateWriteBlocked
        this.didKeepNativeBridgeExpansionBlocked =
            didKeepNativeBridgeExpansionBlocked
        this.didKeepPublicComponentApiBlocked =
            didKeepPublicComponentApiBlocked
    }
}

struct CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness {
    let componentDemoStateUpdateDryRun:
        CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness
    let renderCommandPacket: CjguiInternalRenderCommandPacket
    let componentDemoRenderCommandAdmissionFacts:
        CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts
    let didPrepareStage205ComponentDemoRenderCommandAdmissionReadiness: Bool
    let didConfirmComponentDemoRenderCommandAdmissionReady: Bool
    let didConfirmRenderCommandAdmissionPreviewMaterialized: Bool
    let didConfirmComponentDemoSemanticFixtureMappedToRenderCommandPacket: Bool
    let didConfirmStage206ComponentDemoPreviewPacketInputPrepared: Bool
    let didConfirmRendererSubmissionBlocked: Bool
    let didConfirmRendererStateWriteBlocked: Bool
    let didConfirmRuntimeStateWriteBlocked: Bool
    let didConfirmNativeBridgeExpansionBlocked: Bool
    let didConfirmPublicComponentApiAdded: Bool

    init(
        componentDemoStateUpdateDryRun:
            CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness,
        renderCommandPacket: CjguiInternalRenderCommandPacket,
        componentDemoRenderCommandAdmissionFacts:
            CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts,
        didPrepareStage205ComponentDemoRenderCommandAdmissionReadiness: Bool,
        didConfirmComponentDemoRenderCommandAdmissionReady: Bool,
        didConfirmRenderCommandAdmissionPreviewMaterialized: Bool,
        didConfirmComponentDemoSemanticFixtureMappedToRenderCommandPacket: Bool,
        didConfirmStage206ComponentDemoPreviewPacketInputPrepared: Bool,
        didConfirmRendererSubmissionBlocked: Bool,
        didConfirmRendererStateWriteBlocked: Bool,
        didConfirmRuntimeStateWriteBlocked: Bool,
        didConfirmNativeBridgeExpansionBlocked: Bool,
        didConfirmPublicComponentApiAdded: Bool
    ) {
        this.componentDemoStateUpdateDryRun = componentDemoStateUpdateDryRun
        this.renderCommandPacket = renderCommandPacket
        this.componentDemoRenderCommandAdmissionFacts =
            componentDemoRenderCommandAdmissionFacts
        this.didPrepareStage205ComponentDemoRenderCommandAdmissionReadiness =
            didPrepareStage205ComponentDemoRenderCommandAdmissionReadiness
        this.didConfirmComponentDemoRenderCommandAdmissionReady =
            didConfirmComponentDemoRenderCommandAdmissionReady
        this.didConfirmRenderCommandAdmissionPreviewMaterialized =
            didConfirmRenderCommandAdmissionPreviewMaterialized
        this.didConfirmComponentDemoSemanticFixtureMappedToRenderCommandPacket =
            didConfirmComponentDemoSemanticFixtureMappedToRenderCommandPacket
        this.didConfirmStage206ComponentDemoPreviewPacketInputPrepared =
            didConfirmStage206ComponentDemoPreviewPacketInputPrepared
        this.didConfirmRendererSubmissionBlocked =
            didConfirmRendererSubmissionBlocked
        this.didConfirmRendererStateWriteBlocked =
            didConfirmRendererStateWriteBlocked
        this.didConfirmRuntimeStateWriteBlocked =
            didConfirmRuntimeStateWriteBlocked
        this.didConfirmNativeBridgeExpansionBlocked =
            didConfirmNativeBridgeExpansionBlocked
        this.didConfirmPublicComponentApiAdded = didConfirmPublicComponentApiAdded
    }
}

func cjguiInternalBuildRendererStage205ComponentDemoRenderCommandAdmissionFacts(
    componentDemoStateUpdateDryRun:
        CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket
): CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts {
    let semanticFixture =
        componentDemoStateUpdateDryRun.semanticNodeFixture
    let sceneBridge = semanticFixture.sceneRenderCommandBridge

    return CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts(
        componentDemoStateUpdateDryRun
            .didConfirmComponentDemoStateUpdateDryRunReady,
        renderCommandPacket.isRenderCommandPacketReady,
        semanticFixture.didConfirmInternalRectSemanticNodeMaterialized &&
            semanticFixture.didConfirmInternalTextSemanticNodeMaterialized &&
            semanticFixture.didConfirmInternalButtonLikeSemanticNodeMaterialized &&
            renderCommandPacket.didPreserveRenderCommandList,
        true,
        componentDemoStateUpdateDryRun
            .didConfirmOwnerLocalRollbackPreviewMaterialized,
        renderCommandPacket.didKeepCommandPacketRendererAgnostic,
        renderCommandPacket.didAvoidRenderSideEffect,
        true,
        renderCommandPacket.commandList.didAvoidRendererSubmission &&
            componentDemoStateUpdateDryRun.didConfirmVisibilityPublished == false,
        componentDemoStateUpdateDryRun.didConfirmRendererStateWriteBlocked,
        componentDemoStateUpdateDryRun.didConfirmRuntimeStateWriteBlocked,
        sceneBridge.didConfirmNoNativeBridgeExpansion,
        componentDemoStateUpdateDryRun.didConfirmPublicComponentApiAdded == false
    )
}

func cjguiInternalBuildRendererStage205ComponentDemoRenderCommandAdmissionReadiness(
    componentDemoStateUpdateDryRun:
        CjguiInternalRendererStage204ComponentDemoStateUpdateDryRunReadiness,
    renderCommandPacket: CjguiInternalRenderCommandPacket,
    componentDemoRenderCommandAdmissionFacts:
        CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionFacts
): CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness {
    let admissionReady =
        componentDemoRenderCommandAdmissionFacts
            .didConsumeStage204ComponentDemoStateUpdateDryRun &&
        componentDemoRenderCommandAdmissionFacts
            .didConsumeInternalRenderCommandPacket &&
        componentDemoRenderCommandAdmissionFacts
            .didMapComponentDemoSemanticFixtureToRenderCommandPacket &&
        componentDemoRenderCommandAdmissionFacts
            .didMaterializeRenderCommandAdmissionPreview &&
        componentDemoRenderCommandAdmissionFacts
            .didBindAdmissionPreviewToOwnerLocalRollbackBoundary &&
        componentDemoRenderCommandAdmissionFacts
            .didConfirmCommandPacketBackendAgnostic &&
        componentDemoRenderCommandAdmissionFacts
            .didConfirmCommandPacketAvoidedRenderSideEffect &&
        componentDemoRenderCommandAdmissionFacts
            .didPrepareStage206ComponentDemoPreviewPacketInput
    let stopLineReady =
        componentDemoRenderCommandAdmissionFacts
            .didKeepRendererSubmissionBlocked &&
        componentDemoRenderCommandAdmissionFacts
            .didKeepRendererStateWriteBlocked &&
        componentDemoRenderCommandAdmissionFacts
            .didKeepRuntimeStateWriteBlocked &&
        componentDemoRenderCommandAdmissionFacts
            .didKeepNativeBridgeExpansionBlocked &&
        componentDemoRenderCommandAdmissionFacts
            .didKeepPublicComponentApiBlocked

    return CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness(
        componentDemoStateUpdateDryRun,
        renderCommandPacket,
        componentDemoRenderCommandAdmissionFacts,
        admissionReady && stopLineReady,
        admissionReady && stopLineReady,
        componentDemoRenderCommandAdmissionFacts
            .didMaterializeRenderCommandAdmissionPreview,
        componentDemoRenderCommandAdmissionFacts
            .didMapComponentDemoSemanticFixtureToRenderCommandPacket,
        componentDemoRenderCommandAdmissionFacts
            .didPrepareStage206ComponentDemoPreviewPacketInput,
        componentDemoRenderCommandAdmissionFacts
            .didKeepRendererSubmissionBlocked,
        componentDemoRenderCommandAdmissionFacts
            .didKeepRendererStateWriteBlocked,
        componentDemoRenderCommandAdmissionFacts
            .didKeepRuntimeStateWriteBlocked,
        componentDemoRenderCommandAdmissionFacts
            .didKeepNativeBridgeExpansionBlocked,
        false
    )
}

func cjguiInternalExecuteDefaultRendererStage205ComponentDemoRenderCommandAdmissionDraft():
    CjguiInternalRendererStage205ComponentDemoRenderCommandAdmissionReadiness {
    let dryRun =
        cjguiInternalExecuteDefaultRendererStage204ComponentDemoStateUpdateDryRunDraft()
    let commandPacket = cjguiInternalExecuteDefaultRenderCommandShapeDraft()
    let facts = cjguiInternalBuildRendererStage205ComponentDemoRenderCommandAdmissionFacts(
        dryRun,
        commandPacket
    )
    return cjguiInternalBuildRendererStage205ComponentDemoRenderCommandAdmissionReadiness(
        dryRun,
        commandPacket,
        facts
    )
}
