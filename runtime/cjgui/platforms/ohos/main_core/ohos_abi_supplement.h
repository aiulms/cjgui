/* OHOS narrow-adapter ABI supplement (2026-10-27)
 *
 * The common header defines everything the frozen main core calls. The OHOS
 * host also keeps the historical hidden-text proxy-restore ticket channel and
 * a few introspection functions the fork core used; they are platform-local
 * and never required by the main core. Declarations stay inside extern "C". */

#define CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ANCHOR_PENDING ((int32_t)36)

#define CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_END_OF_TEXT (0xFFFFFFFFu)

enum CjguiInternalRendererProxyRestoreState {
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NONE = 0,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_QUEUED = 1,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_SENT = 2,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_INSTALLED = 3,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_ADOPTED = 4,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_NOT_INSTALLED = 5,
    CJGUI_INTERNAL_RENDERER_PROXY_RESTORE_UNCONFIRMED = 6,
};

typedef struct {
    uint64_t requestId;
    int64_t contextId;
    uint64_t contextGeneration;
    uint64_t acceptedBindingEpoch;
    uint64_t acceptedProjectionVersion;
    int64_t deadlineMonoMs;
    uint32_t canonicalStart;   // 签发前的规范目标；INSTALLED 后为观测确认的落点
    uint32_t canonicalEnd;
    int32_t state;
} CjguiInternalRendererProxyRestoreTicket;

_Static_assert(sizeof(CjguiInternalRendererProxyRestoreTicket) == 64,
               "CjguiInternalRendererProxyRestoreTicket layout drifted");

CjguiInternalRendererStatus
cjgui_internal_renderer_recover_text_proxy_ticket(uint64_t session, uint64_t nodeId,
                                                  int64_t resourceId, uint32_t nodeKind,
                                                  uint64_t sceneVersion, const char *acceptedValue,
                                                  uint32_t selectionStart, uint32_t selectionEnd,
                                                  CjguiInternalRendererProxyRestoreTicket *outTicket);

CjguiInternalRendererStatus
cjgui_internal_renderer_query_proxy_restore_ticket(uint64_t session, uint64_t requestId,
                                                   CjguiInternalRendererProxyRestoreTicket *outTicket);

CjguiInternalRendererStatus
cjgui_internal_renderer_consume_proxy_restore_ticket(uint64_t session, uint64_t requestId,
                                                     uint32_t adoptedStart, uint32_t adoptedEnd,
                                                     int32_t *outConsumed);

int32_t cjgui_internal_renderer_take_human_selection_anchor(uint64_t session, uint64_t nodeId,
                                                            int64_t resourceId, uint32_t nodeKind,
                                                            uint64_t projectionVersion,
                                                            uint64_t acceptedBindingEpoch,
                                                            uint32_t selectionStart,
                                                            uint32_t selectionEnd,
                                                            uint64_t *outAnchorSeq);

uint32_t cjgui_internal_renderer_abi_version(void);

CjguiInternalRendererStatus
cjgui_internal_renderer_accepted_scene_version(uint64_t session, uint64_t *outSceneVersion);
