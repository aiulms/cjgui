// runtime/cjgui/platforms/linux/native/cjgui_linux_aux.c
//
// Linux 平台的 C ABI "长尾"入口：共享操作投影、命令菜单、数据搬运声明、图片资源、
// 组合输入、平台事实查询，以及它们自己的按槽状态表。
//
// 分工（契约见 cjgui_linux_aux.h）：
//   * cjgui_linux_session.c —— 会话生命周期、窗口/GPU/文字、场景暂存与呈现、事件翻译。
//   * 本文件               —— 上述长尾入口 + 自己的静态状态表（按 slot 索引）。
// 本文件只通过 cjgui_linux_session_slot(token) 判断"这个 token 还活着、它在哪一格"，
// 不触碰会话内部结构。所有函数都在会话所属线程上被调用（与 window/vulkan/text 同约定），
// 因此状态表不需要锁；跨线程调用不在本层契约内。
//
// ============================================================================
// 一、本阶段"真实保存并读回"的部分（返回 CJGUI_INTERNAL_RENDERER_OK 的含义）
// ============================================================================
// 下列入口在 aux 里保存真实状态，并让后续调用**观测到**这份状态（门在状态上生效）：
//   * 共享操作投影：configure_shared_operation 保存可见行数；
//     set_shared_operation_title 拒绝 recordIndex >= 已保存行数（VIEW_INVALIDATED）；
//     set_shared_operation_state 用同一行数与 viewport/total/selection 的一致性校验，
//     不符即 VIEW_INVALIDATED 且不改动已保存状态。
//   * 共享表单/集合：configure_shared_form 保存字段数，set_shared_form_field 拒绝越界；
//     configure_shared_collection_form 另存可见记录数，set_shared_collection_row 用
//     rowIndex < 可见记录数、totalRecordCount >= 可见记录数、viewportStart 不越界做门；
//     set_shared_collection_filter 在未启用集合投影时拒绝。
//   * 命令菜单：configure 建 staging（projectionVersion == 0 或 itemCount > 128 拒绝），
//     set_item 在未 staging/越界/必填串为空时拒绝，commit 在
//     "staging 未建立或未填满（commandId/title 为空）" 时拒绝；成功后 staged → accepted
//     提升（与 macOS 的 CjguiCommitStagedComposableCommandMenu 同语义）。
//   * 数据搬运声明：configure 建 staging；set_item 校验角色/字节上限/字段完整性；
//     set_item_bytes 只对 SOURCE + bindingEpoch != 0 + format == "image/png" +
//     payload 为空 + length <= maximumPayloadBytes + 全局 2 MiB 预算 的条目受理。
//   * 诊断开关：set_diagnostic_timing / set_diagnostic_overlay 保存开关与选中态；
//     overlay flags 越界（& ~15）拒绝，与 macOS 同规则。
//   * context-menu guard：set_composable_context_menu_guard 保存守卫声明；enabled == 0 时
//     只按 requestId 匹配撤回（旧请求的迟到关闭不会撤掉新菜单的守卫，与 macOS 同规则）。
//
// 【重要】上面这些 OK 只表示"声明已受理并保存"，**不表示屏幕上出现了任何东西**：
// Linux 第一阶段 aux 不绘制任何 overlay（既没有 AppKit overlay，也没有自绘通道）。
// 本层与 macOS 之间存在四条已知差异，消费方不得从返回值推断画面/场景事实：
//   (a) 不绘制 overlay：命令菜单、共享操作、表单、诊断 overlay 都只有状态，没有像素；
//       状态目前也没有读通道（aux.h 已冻结，只有 slot 查询与 create/destroy 钩子），
//       即"保存下来但本阶段无人消费"。要真正上屏需要 session.c 读这份状态。
//   (b) configure_composable_command_menu / configure_composable_data_transfer 不校验
//       projectionVersion == 已 staged 场景版本（macOS 会）；aux 看不到场景版本。
//   (c) set_composable_data_transfer_item 不校验 nodeId/resourceId/nodeKind 是否存在于
//       已 staged 场景且 isInteractive && !isReadOnly（macOS 会返回 DATA_TRANSFER_REJECTED）。
//   (d) set_composable_context_menu_guard 不返回 SCENE_STALE / NODE_NOT_FOUND：既不比对
//       已接受场景版本，也不确认 layerNodeId 真在场景里；OK 只表示声明本身合法且已保存。
//
// ============================================================================
// 二、本阶段"具名拒绝"的部分（消费方会看到什么）
// ============================================================================
// 以下入口**不假装成功**，全部返回具名状态、并把 out 参数清零（不写"已完成"的假状态）：
//   * PNG 二进制传输：传输来源与本地文件共用 session.c 的图片域。
//       prepare_composable_png_transfer -> 头边界 + 真实解码 + 解码字节预算准入；
//          非法/损坏/尺寸超限/预算不足分别返回 25/27/26/28，width/height/decode_us
//          清零；成功时 decode_us 是真实解码耗时，并保留同身份准入供场景节点接管。
//       finish_composable_png_transfer  -> 接受只结算本层 hold（准入留给场景）；
//          拒绝撤回准入并释放预算；没有对应 hold 时仍返回 DATA_TRANSFER_REJECTED。
//     本层不另造图片缓存或第二个 decoder；像素、纹理与候选持有仍归图片域。
//   * X11 组合输入（IME 属第二阶段；session.c 与本层都只做 ASCII 直输）：
//       arm_composition_reanchor / reanchor_composition
//                                          -> CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED(32)，
//                                             所有 out 清零（mechanism/marked/inner 全 0）
//       cancel_composition                 -> 32，*outHadMarked = 0、*outCancelReturned = 0
//     （没有组合态可取消/可重挂，所以"取消返回 0"是事实而不是失败码的替代品。）
//
// ============================================================================
// 三、归属 session.c、本文件**一律不定义**的 15 个符号（权威清单，勿重复定义）
// ============================================================================
// 这 15 个入口都必须读 session 侧状态，且 aux.h（已冻结）没有任何通路把那些状态送进来；
// aux 里返回空串/0/全零 POD 会是对真实事件的假否定或假数据，因此归属 session.c，
// 本文件不提供任何一份（避免重复符号）：
//   1) data_transfer_event_format / data_transfer_event_source_kind /
//      data_transfer_event_source_identity / data_transfer_event_source_id /
//      data_transfer_event_expected_owner_version / data_transfer_event_delivery_ordinal /
//      data_transfer_event_binary_size / copy_data_transfer_event_binary（8 个）：
//      事件载荷存在 session 的 transferFormat/transferSourceKind/... 字段里
//      （cjgui_linux_session.c L173-186），契约是"借用到下一次事件泵"。
//   2) cancel_composable_pointer_capture / cancel_composable_pointer_capture_epoch /
//      cancel_composable_pointer_capture_gesture_key（3 个）：活状态是 session 的
//      pointerDown/pointerNodeId/... （cjgui_linux_session.c L187-192），"清掉按下目标"
//      必须发生在那份状态上。session.c 已实现真实现，不是本阶段的缺口。
//   3) diagnostic_timing / diagnostic_resources / diagnostic_workload /
//      diagnostic_node_geometry（4 个读取器）：要回答已接受场景版本、已提交帧号、
//      节点几何与 GPU/文字/effect 计数，这些事实 aux 一个都拿不到。特别地，
//      composable_ui_window.cj 的 @When[os != "macOS"] readWorkloadAttemptCounts 把
//      workload 计数当"做功增量基线"用，返回 OK+全 0 就是假数据。由 session.c 用真实
//      计数点实现；本阶段真为 0 的项（imageDecodeStartCount、effect 资源、overlay）
//      保持 0 并注明"这就是真实值"。
//   本文件出现这几个符号的缺席，含义是"归属在 session.c"，不是"aux 忘了写"。
//
// ============================================================================
// 四、平台事实查询（cjgui_macos_* 的 Linux 等价物）的真实依据
// ============================================================================
// 这些都是无会话参数的全局查询，读环境与 GTK 设置文件，**不 fork、不启动子进程、
// 不连接显示服务器**。查不到证据时返回保守值，理由逐条写在各函数上方：
//   * 深色模式：CJGUI_LINUX_DARK_MODE 覆盖 > GTK_THEME/GDK_THEME 含 "dark" >
//     gtk-{3,4}.0/settings.ini 的 gtk-application-prefer-dark-theme / gtk-theme-name
//     > 默认 light(0)。桌面级 color-scheme 存在 dconf 二进制里，本层不解析。
//   * 减少动效：CJGUI_LINUX_REDUCE_MOTION 覆盖 > settings.ini 的 gtk-enable-animations
//     为假 > 默认 0（未声明"减少"就不缩减；与 macOS 缺设置时返回 0 一致）。
//   * 强调色：CJGUI_LINUX_ACCENT_SRGB8 覆盖 > gtk CSS 的 @define-color accent_bg_color /
//     accent_color > 0（unavailable）。返回 0 是 Cangjie 侧既有的"一次不可用样本"。
//   * 窗口可见/最小化：本层没有窗口句柄（窗口在 session.c 里），无法查询
//     map state / _NET_WM_STATE_HIDDEN。返回保守值 visible=1、minimized=0：Cangjie 侧
//     composable_ui_window.cj:21683 用它们判断"初始文字焦点是否可恢复"，报可见/未最小化
//     不会静默关掉正常功能（与 composable_ui_platform_state.cj 里"不可断言不可见就报可见"
//     的既有约定同向）。真实值需要 session.c 用 X11 状态提供。
//
// 环境变量覆盖（CJGUI_LINUX_*）是本层的显式测试缝：只接受明确的真假取值，其余取值忽略
// （不猜），因此它不会把"没设置"伪装成"设置了"。

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "cjgui_linux_aux.h"
#include "cjgui_linux_image.h"

// 会话所属的图片域；aux 只借它在受理前做真实解码与预算准入。
CjguiLinuxImageDomain *cjgui_linux_session_image_domain(uint64_t token);

// ---------------------------------------------------------------- 跨语言声明
// 下面这些入口在本文件实现，但**C 头文件里没有它们的声明**：它们只出现在仓颉侧的
// foreign 块（runtime/cjgui/src/runtime_renderer_session.cj、
// composable_ui_platform_state.cj、composable_ui_platform_accent.cj）。这里按那些
// foreign 声明逐字复述原型，作为编译期自检（签名一旦不一致会直接报错），也让
// "谁声明了什么"在 C 侧可见。改签名要改仓颉 foreign 块，不是改这里。
CjguiInternalRendererStatus cjgui_internal_renderer_cancel_composition(uint64_t session,
                                                                       int32_t *outHadMarked,
                                                                       int32_t *outCancelReturned);
int64_t cjgui_macos_control_accent_srgb8(void);
int32_t cjgui_macos_effective_dark_mode(void);
int32_t cjgui_macos_reduce_motion_enabled(void);
int32_t cjgui_macos_window_visible(int64_t windowNumber);
int32_t cjgui_macos_window_minimized(int64_t windowNumber);

// ---------------------------------------------------------------- 容量
// 与 macOS 实现同量级的边界（见 cjgui_internal_renderer.m 的
// kCjguiComposableDataTransferItemCapacity = 128、
// kCjguiComposableDataTransferPayloadByteCapacity = 512 KiB、
// 以及 set_composable_data_transfer_item_bytes 里的 2 MiB 全局预算）。
#define AUX_MAX_OPERATION_ROWS 8u
#define AUX_MAX_FORM_FIELDS 8u
#define AUX_MAX_MENU_ITEMS 128u
#define AUX_MAX_TRANSFER_ITEMS 128u
#define AUX_MAX_PAYLOAD_BYTES (512u * 1024u)
#define AUX_MAX_RETAINED_BINARY_BYTES (2u * 1024u * 1024u)
#define AUX_MAX_STRING_BYTES 128u

#define AUX_PATH_CAPACITY 1024u
#define AUX_LINE_CAPACITY 1024u

// ---------------------------------------------------------------- 小工具

static char aux_ascii_lower(unsigned char value) {
    return (value >= (unsigned char)'A' && value <= (unsigned char)'Z')
        ? (char)(value - (unsigned char)'A' + (unsigned char)'a')
        : (char)value;
}

static char *aux_strdup(const char *value) {
    if (!value) return NULL;
    size_t length = strlen(value);
    char *copy = (char *)malloc(length + 1u);
    if (!copy) return NULL;
    memcpy(copy, value, length + 1u);
    return copy;
}

static void aux_free_string(char **slot) {
    if (slot && *slot) {
        free(*slot);
        *slot = NULL;
    }
}

// 复制并替换。value == NULL 表示"清空为未设置"（成功）。分配失败时**不改动**旧值，
// 返回 0，调用方据此返回具名错误，绝不静默丢字符串。
static int aux_set_string(char **slot, const char *value) {
    char *copy = aux_strdup(value);
    if (value && !copy) return 0;
    aux_free_string(slot);
    *slot = copy;
    return 1;
}

static int aux_ascii_equals_ci(const char *left, const char *right) {
    if (!left || !right) return 0;
    while (*left && *right) {
        if (aux_ascii_lower((unsigned char)*left) != aux_ascii_lower((unsigned char)*right)) return 0;
        left += 1;
        right += 1;
    }
    return *left == '\0' && *right == '\0';
}

static int aux_contains_ci(const char *haystack, const char *needle) {
    if (!haystack || !needle || !needle[0]) return 0;
    size_t needleLength = strlen(needle);
    for (const char *start = haystack; *start; start += 1) {
        size_t index = 0u;
        while (index < needleLength && start[index] &&
               aux_ascii_lower((unsigned char)start[index]) == aux_ascii_lower((unsigned char)needle[index])) {
            index += 1u;
        }
        if (index == needleLength) return 1;
    }
    return 0;
}

// 显式布尔环境变量：只有明确取值才生效，返回 1 表示 outValue 有效。
static int aux_env_flag(const char *name, int *outValue) {
    const char *value = getenv(name);
    if (!value || !value[0] || !outValue) return 0;
    if (aux_ascii_equals_ci(value, "1") || aux_ascii_equals_ci(value, "true") ||
        aux_ascii_equals_ci(value, "yes") || aux_ascii_equals_ci(value, "on")) {
        *outValue = 1;
        return 1;
    }
    if (aux_ascii_equals_ci(value, "0") || aux_ascii_equals_ci(value, "false") ||
        aux_ascii_equals_ci(value, "no") || aux_ascii_equals_ci(value, "off")) {
        *outValue = 0;
        return 1;
    }
    return 0;
}

// ---------------------------------------------------------------- 状态表

typedef struct CjguiLinuxAuxOperationRow {
    char *title;   // NULL = 未设置标题（消费方按空标题处理）
} CjguiLinuxAuxOperationRow;

typedef struct CjguiLinuxAuxFormField {
    int present;
    char *label;
    char *draftText;
    char *validationError;
    uint32_t editorKind;
    uint8_t isFocused;
    uint32_t selectionStart;
    uint32_t selectionEnd;
} CjguiLinuxAuxFormField;

typedef struct CjguiLinuxAuxCollectionRow {
    int present;
    char *title;
    uint8_t isSelected;
    uint32_t viewportStart;
    uint32_t totalRecordCount;
} CjguiLinuxAuxCollectionRow;

typedef struct CjguiLinuxAuxCommandMenuItem {
    int present;
    char *commandId;
    char *title;
    char *menuGroup;
    char *shortcut;
    uint32_t menuSection;
    uint64_t focusScope;
    uint8_t enabled;
    uint8_t checked;
} CjguiLinuxAuxCommandMenuItem;

typedef struct CjguiLinuxAuxTransferItem {
    int present;
    CjguiInternalRendererComposableDataTransferItem item;   // 值拷贝，不保存调用方指针
    char *format;
    char *payload;
    char *sourceKind;
    char *sourceIdentity;
    uint8_t *bytes;        // 只对 SOURCE + image/png 受理；其余恒为 NULL/0
    uint32_t byteLength;
} CjguiLinuxAuxTransferItem;

// PNG 传输准备的本层持有：只保存校验后的尺寸与次数，不把字节或纹理
// 泄漏成公共接口。已接受项在下一次同 identity 准备或会话销毁时退休。
#define AUX_MAX_TRANSFER_HOLDS 8u
typedef struct CjguiLinuxAuxTransferHold {
    int present;
    int accepted;
    char identity[256];
    uint32_t width;
    uint32_t height;
    uint32_t preparations;
} CjguiLinuxAuxTransferHold;

typedef struct CjguiLinuxAuxSlot {
    int inUse;
    uint64_t token;

    // 共享操作投影
    int operationConfigured;
    uint32_t operationRecordCount;
    CjguiLinuxAuxOperationRow operationRows[AUX_MAX_OPERATION_ROWS];
    int operationStatePresent;
    CjguiInternalRendererSharedOperationState operationState;

    // 共享编辑表单 + 集合
    int formConfigured;
    uint32_t formFieldCount;
    CjguiLinuxAuxFormField formFields[AUX_MAX_FORM_FIELDS];
    char *formStatus;
    int collectionEnabled;
    uint32_t collectionVisibleRecordCount;
    CjguiLinuxAuxCollectionRow collectionRows[AUX_MAX_OPERATION_ROWS];
    char *collectionFilter;

    // 诊断开关（本阶段只有状态，没有消费方；见文件头 (a)）
    int diagnosticTimingEnabled;
    uint32_t diagnosticOverlayFlags;
    uint64_t diagnosticOverlaySelectedNodeId;
    uint8_t diagnosticOverlayHasSelection;

    // 命令菜单：staged → accepted（commit 提升）
    int menuStagedActive;
    uint64_t menuStagedVersion;
    uint32_t menuStagedCount;
    CjguiLinuxAuxCommandMenuItem menuStaged[AUX_MAX_MENU_ITEMS];
    int menuAcceptedActive;
    uint64_t menuAcceptedVersion;
    uint32_t menuAcceptedCount;
    CjguiLinuxAuxCommandMenuItem menuAccepted[AUX_MAX_MENU_ITEMS];

    // context-menu outside-click 守卫
    int guardEnabled;
    uint64_t guardSceneVersion;
    uint64_t guardLayerScope;
    uint64_t guardRequestId;
    uint64_t guardLayerNodeId;
    int64_t guardResourceId;
    uint32_t guardNodeKind;
    int64_t guardX;
    int64_t guardY;
    int64_t guardWidth;
    int64_t guardHeight;

    // 数据搬运声明（promote 到"已接受"发生在 present_composable_scene 路径，属 session.c；
    // 本层保存 staged 声明并让后续声明的门生效）
    int transferStaging;
    uint64_t transferStagedVersion;
    uint32_t transferStagedCount;
    CjguiLinuxAuxTransferItem transferStaged[AUX_MAX_TRANSFER_ITEMS];
    // 已接受声明：只在场景候选成功提交时整体替换。候选失败/丢弃不能把
    // 上一代已接受声明清空，否则旧场景节点会突然失去收发能力。
    int transferAcceptedActive;
    uint64_t transferAcceptedVersion;
    uint32_t transferAcceptedCount;
    CjguiLinuxAuxTransferItem transferAccepted[AUX_MAX_TRANSFER_ITEMS];
    CjguiLinuxAuxTransferHold transferHolds[AUX_MAX_TRANSFER_HOLDS];
} CjguiLinuxAuxSlot;

static CjguiLinuxAuxSlot g_auxSlots[CJGUI_LINUX_MAX_SESSIONS];

// ---------------------------------------------------------------- 清理

static void aux_clear_operation_rows(CjguiLinuxAuxSlot *state) {
    for (uint32_t index = 0u; index < AUX_MAX_OPERATION_ROWS; index += 1u) {
        aux_free_string(&state->operationRows[index].title);
    }
}

static void aux_clear_form(CjguiLinuxAuxSlot *state) {
    for (uint32_t index = 0u; index < AUX_MAX_FORM_FIELDS; index += 1u) {
        CjguiLinuxAuxFormField *field = &state->formFields[index];
        aux_free_string(&field->label);
        aux_free_string(&field->draftText);
        aux_free_string(&field->validationError);
        memset(field, 0, sizeof(*field));
    }
    aux_free_string(&state->formStatus);
    for (uint32_t index = 0u; index < AUX_MAX_OPERATION_ROWS; index += 1u) {
        aux_free_string(&state->collectionRows[index].title);
    }
    aux_free_string(&state->collectionFilter);
}

static void aux_clear_command_menu(CjguiLinuxAuxCommandMenuItem *items, uint32_t count) {
    for (uint32_t index = 0u; index < count && index < AUX_MAX_MENU_ITEMS; index += 1u) {
        CjguiLinuxAuxCommandMenuItem *item = &items[index];
        aux_free_string(&item->commandId);
        aux_free_string(&item->title);
        aux_free_string(&item->menuGroup);
        aux_free_string(&item->shortcut);
        memset(item, 0, sizeof(*item));
    }
}

static void aux_clear_transfer(CjguiLinuxAuxTransferItem *items, uint32_t count) {
    for (uint32_t index = 0u; index < count && index < AUX_MAX_TRANSFER_ITEMS; index += 1u) {
        CjguiLinuxAuxTransferItem *item = &items[index];
        aux_free_string(&item->format);
        aux_free_string(&item->payload);
        aux_free_string(&item->sourceKind);
        aux_free_string(&item->sourceIdentity);
        if (item->bytes) {
            free(item->bytes);
            item->bytes = NULL;
        }
        item->byteLength = 0u;
        memset(item, 0, sizeof(*item));
    }
}

// 释放该槽位所有 strdup/堆块，并把整格清零。幂等：可以重复调用。
static void aux_slot_reset(int slot) {
    if (slot < 0 || slot >= (int)CJGUI_LINUX_MAX_SESSIONS) return;
    CjguiLinuxAuxSlot *state = &g_auxSlots[slot];
    aux_clear_operation_rows(state);
    aux_clear_form(state);
    aux_clear_command_menu(state->menuStaged, AUX_MAX_MENU_ITEMS);
    aux_clear_command_menu(state->menuAccepted, AUX_MAX_MENU_ITEMS);
    aux_clear_transfer(state->transferStaged, AUX_MAX_TRANSFER_ITEMS);
    aux_clear_transfer(state->transferAccepted, AUX_MAX_TRANSFER_ITEMS);
    memset(state, 0, sizeof(*state));
}

// token 活着返回状态格；否则 NULL（调用方一律返回 INVALID_SESSION）。
// 若 session.c 没有调用 create 钩子（或槽位被复用于新 token 而 destroy 被漏掉），
// 这里做一次幂等的重置而不是把长尾入口全判成 INVALID_SESSION：宁可重新开始一格，
// 也不让旧会话的字符串漏到新会话，也不伪造"会话不存在"。
static CjguiLinuxAuxSlot *aux_acquire(uint64_t token) {
    int slot = cjgui_linux_session_slot(token);
    if (slot < 0 || slot >= (int)CJGUI_LINUX_MAX_SESSIONS) return NULL;
    CjguiLinuxAuxSlot *state = &g_auxSlots[slot];
    if (!state->inUse || state->token != token) {
        aux_slot_reset(slot);
        state->inUse = 1;
        state->token = token;
    }
    return state;
}

void cjgui_linux_aux_on_create(int slot) {
    if (slot < 0 || slot >= (int)CJGUI_LINUX_MAX_SESSIONS) return;
    aux_slot_reset(slot);
    g_auxSlots[slot].inUse = 1;
}

void cjgui_linux_aux_on_destroy(int slot) {
    aux_slot_reset(slot);   // 释放全部 strdup 串与字节块，并 inUse = 0
}

// ---------------------------------------------------------------- 共享操作投影

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_operation(uint64_t session, uint32_t visibleRecordCount) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (visibleRecordCount == 0u || visibleRecordCount > AUX_MAX_OPERATION_ROWS) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    aux_clear_operation_rows(state);
    state->operationConfigured = 1;
    state->operationRecordCount = visibleRecordCount;
    // 与 macOS 的初始投影一致：选中项为"无"（UINT32_MAX），viewport 从 0 起，
    // total 先等于可见行数，version/mask/id 清零。
    memset(&state->operationState, 0, sizeof(state->operationState));
    state->operationState.selectedRecordIndex = UINT32_MAX;
    state->operationState.recordCount = visibleRecordCount;
    state->operationState.viewportStart = 0u;
    state->operationState.totalRecordCount = visibleRecordCount;
    state->operationStatePresent = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_title(uint64_t session, uint32_t recordIndex,
                                                    const char *title) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->operationConfigured || recordIndex >= state->operationRecordCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    if (!aux_set_string(&state->operationRows[recordIndex].title, title)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_operation_state(
    uint64_t session, const CjguiInternalRendererSharedOperationState *stateValue) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->operationConfigured || !stateValue) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    // 与 macOS 同一组一致性门：行数必须与当前投影一致，total 不能小于可见行数，
    // viewport 不能越过末尾，选中索引必须落在可见行内（或"无选中"）。
    if (stateValue->recordCount != state->operationRecordCount ||
        stateValue->totalRecordCount < stateValue->recordCount ||
        stateValue->totalRecordCount == 0u ||
        stateValue->viewportStart > stateValue->totalRecordCount - stateValue->recordCount ||
        (stateValue->selectedRecordIndex != UINT32_MAX &&
         stateValue->selectedRecordIndex >= stateValue->recordCount)) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    state->operationState = *stateValue;
    state->operationStatePresent = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 共享表单 / 集合

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_form(uint64_t session, uint32_t fieldCount) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (fieldCount == 0u || fieldCount > AUX_MAX_FORM_FIELDS) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    aux_clear_form(state);
    state->formConfigured = 1;
    state->formFieldCount = fieldCount;
    state->collectionEnabled = 0;
    state->collectionVisibleRecordCount = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_shared_collection_form(uint64_t session, uint32_t fieldCount,
                                                          uint32_t visibleRecordCount) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (visibleRecordCount > AUX_MAX_OPERATION_ROWS) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererStatus status =
        cjgui_internal_renderer_configure_shared_form(session, fieldCount);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return status;
    state->collectionEnabled = 1;
    state->collectionVisibleRecordCount = visibleRecordCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_row(uint64_t session, uint32_t rowIndex,
                                                   const char *title, uint8_t isSelected,
                                                   uint32_t viewportStart, uint32_t totalRecordCount) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->formConfigured || !state->collectionEnabled ||
        rowIndex >= state->collectionVisibleRecordCount ||
        totalRecordCount < state->collectionVisibleRecordCount ||
        viewportStart > totalRecordCount - state->collectionVisibleRecordCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    // macOS 对 NULL 标题使用 "未命名记录"；这里保持同一默认，避免两端语义分叉。
    if (!aux_set_string(&state->collectionRows[rowIndex].title, title ? title : "未命名记录")) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    state->collectionRows[rowIndex].present = 1;
    state->collectionRows[rowIndex].isSelected = isSelected ? 1u : 0u;
    state->collectionRows[rowIndex].viewportStart = viewportStart;
    state->collectionRows[rowIndex].totalRecordCount = totalRecordCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_collection_filter(uint64_t session, const char *filterText) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->formConfigured || !state->collectionEnabled) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    if (!aux_set_string(&state->collectionFilter, filterText ? filterText : "")) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_field(
    uint64_t session, uint32_t fieldIndex, const char *label, const char *draftText,
    const char *validationError, uint32_t editorKind, uint8_t isFocused,
    uint32_t selectionStart, uint32_t selectionEnd) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->formConfigured || fieldIndex >= state->formFieldCount) {
        return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    }
    CjguiLinuxAuxFormField *field = &state->formFields[fieldIndex];
    // 三个字符串按 macOS 的默认值补齐；任何一个分配失败都不改动本字段（返回具名错误）。
    char *labelCopy = aux_strdup(label ? label : "字段");
    char *draftCopy = aux_strdup(draftText ? draftText : "");
    char *errorCopy = aux_strdup(validationError ? validationError : "");
    if (!labelCopy || !draftCopy || !errorCopy) {
        free(labelCopy);
        free(draftCopy);
        free(errorCopy);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    aux_free_string(&field->label);
    aux_free_string(&field->draftText);
    aux_free_string(&field->validationError);
    field->label = labelCopy;
    field->draftText = draftCopy;
    field->validationError = errorCopy;
    field->editorKind = editorKind;
    field->isFocused = isFocused ? 1u : 0u;
    field->selectionStart = selectionStart;
    field->selectionEnd = selectionEnd;
    field->present = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_shared_form_status(uint64_t session, const char *statusText) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->formConfigured) return CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED;
    if (!aux_set_string(&state->formStatus, statusText ? statusText : "")) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 诊断开关
// 只有"开关/选中态"是可保存的真实事实；四个读取器（timing/resources/workload/
// node_geometry）需要场景、帧号与 GPU/文字计数，属 session.c，本文件不定义（见文件头三）。

CjguiInternalRendererStatus
cjgui_internal_renderer_set_diagnostic_timing(uint64_t session, uint32_t enabled) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    state->diagnosticTimingEnabled = enabled ? 1 : 0;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_diagnostic_overlay(uint64_t session, uint32_t flags,
                                                uint64_t selectedNodeId, uint8_t hasSelection) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 与 macOS 同一条位域门：只有低 4 位是已定义 flags。
    if (flags & ~15u) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    state->diagnosticOverlayFlags = flags;
    state->diagnosticOverlaySelectedNodeId = selectedNodeId;
    state->diagnosticOverlayHasSelection = hasSelection ? 1u : 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 命令菜单

static int aux_menu_staging_complete(const CjguiLinuxAuxSlot *state) {
    if (!state->menuStagedActive || state->menuStagedVersion == 0u) return 0;
    for (uint32_t index = 0u; index < state->menuStagedCount; index += 1u) {
        const CjguiLinuxAuxCommandMenuItem *item = &state->menuStaged[index];
        if (!item->present || !item->commandId || !item->commandId[0] ||
            !item->title || !item->title[0]) {
            return 0;
        }
    }
    return 1;
}

// 深拷贝一条菜单项：先把新串全部备好，再替换旧串；失败时不改动目标项。
static int aux_menu_item_assign(CjguiLinuxAuxCommandMenuItem *destination, const char *commandId,
                                const char *title, const char *menuGroup, const char *shortcut,
                                uint32_t menuSection, uint64_t focusScope, uint8_t enabled,
                                uint8_t checked) {
    char *commandCopy = aux_strdup(commandId);
    char *titleCopy = aux_strdup(title);
    char *groupCopy = aux_strdup(menuGroup ? menuGroup : "");
    char *shortcutCopy = aux_strdup(shortcut ? shortcut : "");
    if (!commandCopy || !titleCopy || !groupCopy || !shortcutCopy) {
        free(commandCopy);
        free(titleCopy);
        free(groupCopy);
        free(shortcutCopy);
        return 0;
    }
    aux_free_string(&destination->commandId);
    aux_free_string(&destination->title);
    aux_free_string(&destination->menuGroup);
    aux_free_string(&destination->shortcut);
    destination->commandId = commandCopy;
    destination->title = titleCopy;
    destination->menuGroup = groupCopy;
    destination->shortcut = shortcutCopy;
    destination->menuSection = menuSection;
    destination->focusScope = focusScope;
    destination->enabled = enabled ? 1u : 0u;
    destination->checked = checked ? 1u : 0u;
    destination->present = 1;
    return 1;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_command_menu(uint64_t session,
                                                           uint64_t projectionVersion,
                                                           uint32_t itemCount) {
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX configure_composable_command_menu\n");
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (projectionVersion == 0u || itemCount > AUX_MAX_MENU_ITEMS) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    // 与 macOS 同规则：重新 configure 丢弃上一份 staging（未提交的声明不会残留）。
    aux_clear_command_menu(state->menuStaged, AUX_MAX_MENU_ITEMS);
    state->menuStagedActive = 1;
    state->menuStagedVersion = projectionVersion;
    state->menuStagedCount = itemCount;
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX menu_configure OK count=%u\n", itemCount);
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_command_menu_item(
    uint64_t session, uint32_t itemIndex, const char *commandId, const char *title,
    const char *menuGroup, const char *shortcut, uint32_t menuSection, uint64_t focusScope,
    uint8_t enabled, uint8_t checked, uint8_t presentationOnly) {
    (void)presentationOnly;
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX set_composable_command_menu_item\n");
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->menuStagedActive || itemIndex >= state->menuStagedCount ||
        !commandId || !title || !menuGroup || !shortcut || !commandId[0] || !title[0]) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (!aux_menu_item_assign(&state->menuStaged[itemIndex], commandId, title, menuGroup, shortcut,
                              menuSection, focusScope, enabled, checked)) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    if (getenv("CJGUI_LINUX_AUX_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_AUX item index=%u id=%s shortcut=[%s] scope=%llu enabled=%u\n",
                itemIndex, commandId, shortcut, (unsigned long long)focusScope, (unsigned)enabled);
    }
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_commit_composable_command_menu(uint64_t session) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 与 macOS 的 CjguiCommitComposableCommandMenuWithInstallationOnMain 同门：
    // staging 不存在、或任一条目的 commandId/title 仍为空 -> INTERNAL_ERROR，不提升。
    // （macOS 还要求 staged version == 已接受场景版本；aux 看不到场景版本，(b) 差异见文件头。）
    if (getenv("CJGUI_LINUX_AUX_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_AUX menu_commit active=%d count=%u complete=%d\n", state->menuStagedActive,
                state->menuStagedCount, aux_menu_staging_complete(state));
    }
    if (!aux_menu_staging_complete(state)) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiLinuxAuxCommandMenuItem promoted[AUX_MAX_MENU_ITEMS];
    memset(promoted, 0, sizeof(promoted));
    for (uint32_t index = 0u; index < state->menuStagedCount; index += 1u) {
        const CjguiLinuxAuxCommandMenuItem *source = &state->menuStaged[index];
        if (!aux_menu_item_assign(&promoted[index], source->commandId, source->title,
                                  source->menuGroup, source->shortcut, source->menuSection,
                                  source->focusScope, source->enabled, source->checked)) {
            aux_clear_command_menu(promoted, state->menuStagedCount);
            return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;   // 旧 accepted 保持原样
        }
    }
    aux_clear_command_menu(state->menuAccepted, AUX_MAX_MENU_ITEMS);
    memcpy(state->menuAccepted, promoted, sizeof(promoted));
    state->menuAcceptedActive = 1;
    state->menuAcceptedVersion = state->menuStagedVersion;
    state->menuAcceptedCount = state->menuStagedCount;
    // 这份 staging 已被本代接受；后续普通 present 不得重复提升它。
    state->menuStagedActive = 0;
    state->menuStagedVersion = 0u;
    return CJGUI_INTERNAL_RENDERER_OK;
}

int cjgui_linux_aux_command_menu_staged(uint64_t token) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (!state) return 0;
    return aux_menu_staging_complete(state);
}

uint64_t cjgui_linux_aux_context_menu_request(uint64_t token) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (!state || !state->guardEnabled) return 0u;
    return state->guardRequestId;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_context_menu_guard(
    uint64_t session, uint64_t sceneVersion, uint64_t layerScope, uint64_t requestId,
    uint64_t layerNodeId, int64_t resourceId, uint32_t nodeKind, int64_t x, int64_t y,
    int64_t width, int64_t height, uint32_t enabled) {
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX set_composable_context_menu_guard\n");
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!enabled) {
        // 与 macOS 同规则：迟到的旧请求关闭不得撤掉新守卫，只有 requestId 对得上才撤。
        if (state->guardRequestId == requestId) {
            state->guardEnabled = 0;
            state->guardSceneVersion = 0u;
            state->guardLayerScope = 0u;
            state->guardRequestId = 0u;
            state->guardLayerNodeId = 0u;
            state->guardResourceId = -1;
            state->guardNodeKind = 0u;
            state->guardX = 0;
            state->guardY = 0;
            state->guardWidth = 0;
            state->guardHeight = 0;
        }
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (requestId == 0u || layerScope == 0u || layerNodeId == 0u || width <= 0 || height <= 0) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    // (d)：不比对已接受场景版本、也不在此确认 layer 节点在场景里（aux 看不到场景），
    // 因此这里不会返回 SCENE_STALE / NODE_NOT_FOUND；OK 仅表示守卫声明合法且已保存。
    state->guardSceneVersion = sceneVersion;
    state->guardLayerScope = layerScope;
    state->guardRequestId = requestId;
    state->guardLayerNodeId = layerNodeId;
    state->guardResourceId = resourceId;
    state->guardNodeKind = nodeKind;
    state->guardX = x;
    state->guardY = y;
    state->guardWidth = width;
    state->guardHeight = height;
    state->guardEnabled = 1;
    return CJGUI_INTERNAL_RENDERER_OK;
}

// ---------------------------------------------------------------- 数据搬运声明

static int aux_transfer_format_is_valid(const char *format) {
    if (!format || !format[0]) return 0;
    size_t length = strlen(format);
    if (length > AUX_MAX_STRING_BYTES) return 0;
    if (strcmp(format, "text/plain") == 0 || strcmp(format, "image/png") == 0) return 1;
    if (strncmp(format, "application/", 12u) != 0 && strncmp(format, "cjgui.", 6u) != 0) return 0;
    for (size_t index = 0u; index < length; index += 1u) {
        const char character = format[index];
        const int allowed = (character >= 'a' && character <= 'z') ||
                            (character >= '0' && character <= '9') ||
                            character == '/' || character == '.' || character == '-' || character == '+';
        if (!allowed) return 0;
    }
    return 1;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_configure_composable_data_transfer(uint64_t session,
                                                            uint64_t projectionVersion,
                                                            uint32_t itemCount) {
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX configure_composable_data_transfer\n");
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    // 与 macOS 同边界：version == 0 或 itemCount > 128 -> DATA_TRANSFER_REJECTED。
    // （macOS 还要求 version == 已 staged 场景版本；(b) 差异见文件头。）
    if (projectionVersion == 0u || itemCount > AUX_MAX_TRANSFER_ITEMS) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    aux_clear_transfer(state->transferStaged, AUX_MAX_TRANSFER_ITEMS);
    state->transferStaging = 1;
    state->transferStagedVersion = projectionVersion;
    state->transferStagedCount = itemCount;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_data_transfer_item(
    uint64_t session, uint32_t itemIndex,
    const CjguiInternalRendererComposableDataTransferItem *item,
    const char *format, const char *payload, const char *sourceKind, const char *sourceIdentity) {
    if (getenv("CJGUI_LINUX_AUX_TRACE")) fprintf(stderr, "CJGUI_LINUX_AUX set_composable_data_transfer_item\n");
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!item || !state->transferStaging || itemIndex >= state->transferStagedCount ||
        item->projectionVersion == 0u || item->projectionVersion != state->transferStagedVersion ||
        (item->role != CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_SOURCE &&
         item->role != CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_TARGET) ||
        item->maximumPayloadBytes == 0u || item->maximumPayloadBytes > AUX_MAX_PAYLOAD_BYTES ||
        !aux_transfer_format_is_valid(format) || !payload || !sourceKind || !sourceIdentity) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    // (c)：不校验 nodeId/resourceId/nodeKind 是否在已 staged 场景里（aux 看不到场景）。
    CjguiLinuxAuxTransferItem staged;
    memset(&staged, 0, sizeof(staged));
    staged.present = 1;
    staged.item = *item;
    if (!aux_set_string(&staged.format, format) ||
        !aux_set_string(&staged.payload, payload) ||
        !aux_set_string(&staged.sourceKind, sourceKind) ||
        !aux_set_string(&staged.sourceIdentity, sourceIdentity)) {
        aux_clear_transfer(&staged, 1u);
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    CjguiLinuxAuxTransferItem *destination = &state->transferStaged[itemIndex];
    // 重新声明同一格会作废该格此前的字节载荷（与 macOS 的 placeholder 重建同义）。
    aux_clear_transfer(destination, 1u);
    *destination = staged;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_set_composable_data_transfer_item_bytes(uint64_t session, uint32_t itemIndex,
                                                                 const uint8_t *bytes,
                                                                 uint32_t length) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!state->transferStaging || itemIndex >= state->transferStagedCount) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    CjguiLinuxAuxTransferItem *destination = &state->transferStaged[itemIndex];
    if (!destination->present) return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    // 与 macOS 同一组门：只有 SOURCE + 已绑定 epoch + image/png + 空文本载荷 +
    // 不超过本项 maximumPayloadBytes 的条目才受理字节。
    if (destination->item.role != CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_SOURCE ||
        destination->item.bindingEpoch == 0u ||
        !destination->format || strcmp(destination->format, "image/png") != 0 ||
        length > destination->item.maximumPayloadBytes ||
        (destination->payload && destination->payload[0] != '\0')) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    if (length > 0u && !bytes) return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    // 全局预算：其它条目已保留的字节 + 本次 <= 2 MiB。
    uint64_t retained = 0u;
    for (uint32_t index = 0u; index < state->transferStagedCount; index += 1u) {
        if (&state->transferStaged[index] == destination) continue;
        retained += (uint64_t)state->transferStaged[index].byteLength;
        if (retained > (uint64_t)AUX_MAX_RETAINED_BINARY_BYTES) {
            return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
        }
    }
    if ((uint64_t)length > (uint64_t)AUX_MAX_RETAINED_BINARY_BYTES - retained) {
        return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    }
    uint8_t *copy = NULL;
    if (length > 0u) {
        copy = (uint8_t *)malloc((size_t)length);
        if (!copy) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        memcpy(copy, bytes, (size_t)length);
    }
    if (destination->bytes) free(destination->bytes);
    destination->bytes = copy;
    destination->byteLength = length;
    return CJGUI_INTERNAL_RENDERER_OK;
}

int cjgui_linux_aux_transfer_find(uint64_t token, uint64_t acceptedVersion,
                                  uint64_t nodeId, int64_t resourceId, uint32_t nodeKind,
                                  uint32_t role, uint32_t wantFormat,
                                  CjguiInternalRendererComposableDataTransferItem *outItem,
                                  const char **outPayload,
                                  const uint8_t **outBytes, uint32_t *outByteLength) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    // Only the accepted declaration set is visible to OS input. Staging belongs
    // to a candidate scene and must never answer a drop, paste or copy.
    if (!state || acceptedVersion == 0u || state->transferAcceptedActive == 0 ||
        state->transferAcceptedVersion != acceptedVersion) return 0;
    const char *format = wantFormat == 2u ? "image/png" : "text/plain";
    for (uint32_t index = 0u; index < state->transferAcceptedCount; index += 1u) {
        CjguiLinuxAuxTransferItem *item = &state->transferAccepted[index];
        if (!item->present || item->item.role != role ||
            item->item.nodeId != nodeId || item->item.resourceId != resourceId ||
            item->item.nodeKind != nodeKind || !item->format ||
            strcmp(item->format, format) != 0) continue;
        if (outItem) *outItem = item->item;
        if (outPayload) *outPayload = item->payload ? item->payload : "";
        if (outBytes) *outBytes = item->bytes;
        if (outByteLength) *outByteLength = item->byteLength;
        return 1;
    }
    return 0;
}

int cjgui_linux_aux_transfer_declared(uint64_t token, uint64_t acceptedVersion,
                                      uint32_t role, uint32_t wantFormat,
                                      int *outLocalPngFileAllowed) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (outLocalPngFileAllowed) *outLocalPngFileAllowed = 0;
    if (!state || acceptedVersion == 0u || state->transferAcceptedActive == 0 ||
        state->transferAcceptedVersion != acceptedVersion) return 0;
    const char *format = wantFormat == 2u ? "image/png" : "text/plain";
    int found = 0;
    for (uint32_t index = 0u; index < state->transferAcceptedCount; index += 1u) {
        CjguiLinuxAuxTransferItem *item = &state->transferAccepted[index];
        if (!item->present || item->item.role != role || !item->format ||
            strcmp(item->format, format) != 0) continue;
        found = 1;
        if (outLocalPngFileAllowed && item->item.localPngFileAllowed) {
            *outLocalPngFileAllowed = 1;
        }
    }
    return found;
}

// 场景候选成功提交后调用：staging 与已接受代相同才整体替换；没有对应
// staging 的提交保留原已接受声明，不做“空代覆盖”。
void cjgui_linux_aux_commit_transfer(uint64_t token, uint64_t acceptedVersion) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (!state || !state->transferStaging || state->transferStagedVersion != acceptedVersion) return;
    aux_clear_transfer(state->transferAccepted, state->transferAcceptedCount);
    memcpy(state->transferAccepted, state->transferStaged, sizeof(state->transferAccepted));
    state->transferAcceptedCount = state->transferStagedCount;
    state->transferAcceptedVersion = state->transferStagedVersion;
    state->transferAcceptedActive = 1;
    memset(state->transferStaged, 0, sizeof(state->transferStaged));
    state->transferStaging = 0;
    state->transferStagedVersion = 0u;
    state->transferStagedCount = 0u;
    if (getenv("CJGUI_LINUX_AUX_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_AUX transfer_commit version=%llu items=%u\n",
                (unsigned long long)acceptedVersion, state->transferAcceptedCount);
    }
}

// 候选丢弃/取消：只撤 staging；已接受声明保持原样。
void cjgui_linux_aux_discard_transfer(uint64_t token) {
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (!state) return;
    aux_clear_transfer(state->transferStaged, state->transferStagedCount);
    memset(state->transferStaged, 0, sizeof(state->transferStaged));
    state->transferStaging = 0;
    state->transferStagedVersion = 0u;
    state->transferStagedCount = 0u;
}

// ---------------------------------------------------------------- PNG 传输
// 共同层在目标受理前要求一次同步的 PNG 准备：完整校验签名/IHDR/尺寸，
// 给出真实的解码微秒，并把准备次数记在本层有界 hold 表里；finish 只做
// 接受/拒绝结算。像素解码和纹理仍由 session 的图片域/scene 消费，不在
// 这里另造图片缓存。

static uint32_t aux_read_be32(const uint8_t *bytes) {
    return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) |
           ((uint32_t)bytes[2] << 8) | (uint32_t)bytes[3];
}

CjguiInternalRendererStatus
cjgui_internal_renderer_prepare_composable_png_transfer(uint64_t session, const char *resourceIdentity,
                                                         const uint8_t *bytes, uint32_t length,
                                                         uint32_t *outWidth, uint32_t *outHeight,
                                                         uint64_t *outDecodeMicros) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outWidth || !outHeight || !outDecodeMicros) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    *outWidth = 0u;
    *outHeight = 0u;
    *outDecodeMicros = 0u;
    if (!resourceIdentity || !resourceIdentity[0] || strlen(resourceIdentity) >= 256u ||
        !bytes || length < 33u || length > 512u * 1024u) {
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    }
    static const uint8_t signature[8] = {0x89u, 'P', 'N', 'G', 0x0Du, 0x0Au, 0x1Au, 0x0Au};
    if (memcmp(bytes, signature, 8u) != 0) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    // IHDR 必须是第一个块：4 字节长度 + 4 字节类型 + 13 字节数据。
    if (aux_read_be32(bytes + 8u) != 13u || memcmp(bytes + 12u, "IHDR", 4u) != 0) {
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    }
    uint32_t width = aux_read_be32(bytes + 16u);
    uint32_t height = aux_read_be32(bytes + 20u);
    uint8_t bitDepth = bytes[24];
    uint8_t colorType = bytes[25];
    if (bytes[26] != 0u || bytes[27] != 0u || bytes[28] > 1u) {
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    }
    int depthOk = bitDepth == 1u || bitDepth == 2u || bitDepth == 4u ||
                  bitDepth == 8u || bitDepth == 16u;
    int colorOk = colorType == 0u || colorType == 2u || colorType == 3u ||
                  colorType == 4u || colorType == 6u;
    if (!depthOk || !colorOk) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    if (width == 0u || height == 0u) return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    // 与图片域同一边界：超过 2048 的图不可能进入纹理缓存，不能在受理前
    // 用一个比消费端更宽的头检查放行。
    if (width > 2048u || height > 2048u ||
        (uint64_t)width * (uint64_t)height > 2048u * 2048u) {
        return CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED;
    }
    CjguiLinuxImageDomain *image = cjgui_linux_session_image_domain(session);
    if (!image) return CJGUI_INTERNAL_RENDERER_PNG_UNSUPPORTED;
    uint32_t decodedWidth = 0u;
    uint32_t decodedHeight = 0u;
    uint64_t decodeMicros = 0u;
    int admitted = cjgui_linux_image_admit_transfer_png(image, resourceIdentity, bytes, length,
                                                         &decodedWidth, &decodedHeight,
                                                         &decodeMicros);
    if (admitted != CJGUI_LINUX_IMAGE_ADMIT_OK) {
        if (admitted == CJGUI_LINUX_IMAGE_ADMIT_DIMENSION) {
            return CJGUI_INTERNAL_RENDERER_PNG_DIMENSION_EXCEEDED;
        }
        if (admitted == CJGUI_LINUX_IMAGE_ADMIT_DECODE) {
            return CJGUI_INTERNAL_RENDERER_PNG_DECODE_FAILED;
        }
        if (admitted == CJGUI_LINUX_IMAGE_ADMIT_BUDGET) {
            return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED;
        }
        return CJGUI_INTERNAL_RENDERER_PNG_INVALID;
    }
    CjguiLinuxAuxTransferHold *hold = NULL;
    for (uint32_t index = 0u; index < AUX_MAX_TRANSFER_HOLDS; index += 1u) {
        CjguiLinuxAuxTransferHold *candidate = &state->transferHolds[index];
        if (candidate->present && strcmp(candidate->identity, resourceIdentity) == 0) {
            hold = candidate;
            break;
        }
        if (!candidate->present && hold == NULL) hold = candidate;
    }
    if (hold == NULL) {
        // 预算满：优先退休已接受、preparations 已归零的最老项。
        for (uint32_t index = 0u; index < AUX_MAX_TRANSFER_HOLDS; index += 1u) {
            CjguiLinuxAuxTransferHold *candidate = &state->transferHolds[index];
            if (candidate->preparations == 0u) { hold = candidate; break; }
        }
        if (hold == NULL) {
            cjgui_linux_image_release_transfer_admission(image, resourceIdentity);
            return CJGUI_INTERNAL_RENDERER_PNG_RESOURCE_BUDGET_EXCEEDED;
        }
    }
    memset(hold, 0, sizeof(*hold));
    hold->present = 1;
    snprintf(hold->identity, sizeof(hold->identity), "%s", resourceIdentity);
    hold->width = decodedWidth;
    hold->height = decodedHeight;
    hold->preparations = 1u;
    *outWidth = decodedWidth;
    *outHeight = decodedHeight;
    *outDecodeMicros = decodeMicros;
    return CJGUI_INTERNAL_RENDERER_OK;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_finish_composable_png_transfer(uint64_t session, const char *resourceIdentity,
                                                        uint8_t accepted) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!resourceIdentity) return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
    for (uint32_t index = 0u; index < AUX_MAX_TRANSFER_HOLDS; index += 1u) {
        CjguiLinuxAuxTransferHold *hold = &state->transferHolds[index];
        if (!hold->present || strcmp(hold->identity, resourceIdentity) != 0) continue;
        if (hold->preparations > 0u) hold->preparations -= 1u;
        if (accepted) {
            // 受理：准入由随后接管同一身份的场景节点消费。
            hold->accepted = 1;
            return CJGUI_INTERNAL_RENDERER_OK;
        }
        cjgui_linux_image_release_transfer_admission(
            cjgui_linux_session_image_domain(session), resourceIdentity);
        if (hold->preparations == 0u) memset(hold, 0, sizeof(*hold));
        return CJGUI_INTERNAL_RENDERER_OK;
    }
    if (!accepted) {
        cjgui_linux_image_release_transfer_admission(
            cjgui_linux_session_image_domain(session), resourceIdentity);
    }
    return CJGUI_INTERNAL_RENDERER_DATA_TRANSFER_REJECTED;
}

// ---------------------------------------------------------------- 组合输入（具名拒绝）
// session.c 与本层本阶段都只做 ASCII 直输（不建 XIM/XIC），因此没有 marked text、
// 没有 booking，也就没有可重挂/可取消的组合态。三个入口返回
// TEXT_SERVICE_UNSUPPORTED(32)（枚举中"本后端文本服务未接通"的具名拒绝）并清零 out。

CjguiInternalRendererStatus
cjgui_internal_renderer_arm_composition_reanchor(uint64_t session, uint64_t nodeId, int64_t resourceId,
                                                  uint32_t nodeKind, const char *baseText,
                                                  uint32_t replacementStart16,
                                                  uint32_t replacementLength16) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)baseText;
    (void)replacementStart16;
    (void)replacementLength16;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_cancel_composition(uint64_t session, int32_t *outHadMarked,
                                            int32_t *outCancelReturned) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outHadMarked || !outCancelReturned) return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    // 没有组合态：had_marked = 0 是事实，cancel 没跑过所以 returned = 0（不是"取消成功"）。
    *outHadMarked = 0;
    *outCancelReturned = 0;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

CjguiInternalRendererStatus
cjgui_internal_renderer_reanchor_composition(uint64_t session, uint64_t nodeId, int64_t resourceId,
                                              uint32_t nodeKind, uint64_t sceneVersion,
                                              const char *newBaseText, uint32_t replacementStart16,
                                              uint32_t replacementLength16, uint32_t *outMechanism,
                                              uint32_t *outMarkedStart16, uint32_t *outMarkedLength16,
                                              uint32_t *outInnerStart16, uint32_t *outInnerEnd16) {
    CjguiLinuxAuxSlot *state = aux_acquire(session);
    if (!state) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    if (!outMechanism || !outMarkedStart16 || !outMarkedLength16 || !outInnerStart16 ||
        !outInnerEnd16 || !newBaseText) {
        return CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    }
    (void)nodeId;
    (void)resourceId;
    (void)nodeKind;
    (void)sceneVersion;
    (void)replacementStart16;
    (void)replacementLength16;
    *outMechanism = 0u;
    *outMarkedStart16 = 0u;
    *outMarkedLength16 = 0u;
    *outInnerStart16 = 0u;
    *outInnerEnd16 = 0u;
    return CJGUI_INTERNAL_RENDERER_TEXT_SERVICE_UNSUPPORTED;
}

// ---------------------------------------------------------------- 平台事实查询

static int aux_config_directory(char *outPath, size_t capacity) {
    const char *xdg = getenv("XDG_CONFIG_HOME");
    if (xdg && xdg[0]) {
        int written = snprintf(outPath, capacity, "%s", xdg);
        return written > 0 && (size_t)written < capacity;
    }
    const char *home = getenv("HOME");
    if (home && home[0]) {
        int written = snprintf(outPath, capacity, "%s/.config", home);
        return written > 0 && (size_t)written < capacity;
    }
    return 0;
}

// 读取 INI 风格设置文件里的 key = value。返回 1 表示找到并有值写入 outValue。
static int aux_read_settings_value(const char *directory, const char *file, const char *key,
                                   char *outValue, size_t capacity) {
    if (!directory || !file || !key || !outValue || capacity == 0u) return 0;
    char path[AUX_PATH_CAPACITY];
    int written = snprintf(path, sizeof(path), "%s/%s", directory, file);
    if (written <= 0 || (size_t)written >= sizeof(path)) return 0;
    FILE *stream = fopen(path, "r");
    if (!stream) return 0;
    char line[AUX_LINE_CAPACITY];
    int found = 0;
    while (!found && fgets(line, (int)sizeof(line), stream)) {
        const char *cursor = line;
        while (*cursor == ' ' || *cursor == '\t') cursor += 1;
        if (*cursor == '#' || *cursor == ';' || *cursor == '[' || *cursor == '\0' || *cursor == '\n') continue;
        const char *equals = strchr(cursor, '=');
        if (!equals) continue;
        const char *keyEnd = equals;
        while (keyEnd > cursor && (keyEnd[-1] == ' ' || keyEnd[-1] == '\t')) keyEnd -= 1;
        size_t keyLength = (size_t)(keyEnd - cursor);
        if (keyLength != strlen(key) || strncmp(cursor, key, keyLength) != 0) continue;
        const char *value = equals + 1;
        while (*value == ' ' || *value == '\t') value += 1;
        size_t valueLength = strlen(value);
        while (valueLength > 0u) {
            const char last = value[valueLength - 1u];
            if (last == '\n' || last == '\r' || last == ' ' || last == '\t') {
                valueLength -= 1u;
            } else {
                break;
            }
        }
        if (valueLength + 1u > capacity) valueLength = capacity - 1u;
        memcpy(outValue, value, valueLength);
        outValue[valueLength] = '\0';
        found = 1;
    }
    fclose(stream);
    return found;
}

// 在若干 settings.ini 里找一个键；返回 1 表示至少一个文件给出了该键。
static int aux_find_settings_value(const char *key, char *outValue, size_t capacity) {
    char configDirectory[AUX_PATH_CAPACITY];
    if (aux_config_directory(configDirectory, sizeof(configDirectory))) {
        if (aux_read_settings_value(configDirectory, "gtk-4.0/settings.ini", key, outValue, capacity)) return 1;
        if (aux_read_settings_value(configDirectory, "gtk-3.0/settings.ini", key, outValue, capacity)) return 1;
    }
    if (aux_read_settings_value("/etc/gtk-4.0", "settings.ini", key, outValue, capacity)) return 1;
    if (aux_read_settings_value("/etc/gtk-3.0", "settings.ini", key, outValue, capacity)) return 1;
    return 0;
}

static int aux_settings_value_is_false(const char *value) {
    return aux_ascii_equals_ci(value, "0") || aux_ascii_equals_ci(value, "false") ||
           aux_ascii_equals_ci(value, "no") || aux_ascii_equals_ci(value, "off");
}

static int aux_settings_value_is_true(const char *value) {
    return aux_ascii_equals_ci(value, "1") || aux_ascii_equals_ci(value, "true") ||
           aux_ascii_equals_ci(value, "yes") || aux_ascii_equals_ci(value, "on");
}

static int aux_environment_declares_dark(void) {
    const char *variables[2] = { "GTK_THEME", "GDK_THEME" };
    for (size_t index = 0u; index < 2u; index += 1u) {
        const char *value = getenv(variables[index]);
        if (value && aux_contains_ci(value, "dark")) return 1;
    }
    return 0;
}

// 深色模式：环境覆盖 > 主题名 > GTK 设置 > 默认 light。
// 依据：桌面级 color-scheme（GNOME 42+ 的 org.gnome.desktop.interface color-scheme、
// KDE 的 kdeglobals ColorScheme）分别存在 dconf 二进制与另一套键名里；本层不 fork
// gsettings、不解析 dconf，拿不到证据就报 light（保守值，注释写明依据，不编造"已完成"）。
int32_t cjgui_macos_effective_dark_mode(void) {
    int forced = 0;
    if (aux_env_flag("CJGUI_LINUX_DARK_MODE", &forced)) return forced ? 1 : 0;
    if (aux_environment_declares_dark()) return 1;
    char value[256];
    if (aux_find_settings_value("gtk-application-prefer-dark-theme", value, sizeof(value)) &&
        aux_settings_value_is_true(value)) {
        return 1;
    }
    if (aux_find_settings_value("gtk-theme-name", value, sizeof(value)) && aux_contains_ci(value, "dark")) {
        return 1;
    }
    return 0;   // 未发现"声明深色"的证据 -> light
}

// 减少动效：环境覆盖 > gtk-enable-animations 为假 > 默认 0（不缩减）。
// 依据：GTK 的动效开关就是 gtk-enable-animations（GNOME 的 enable-animations 键在
// dconf 里，本层不解析）；未声明"减少"就不缩减，与 macOS 缺设置时返回 0 同向。
int32_t cjgui_macos_reduce_motion_enabled(void) {
    int forced = 0;
    if (aux_env_flag("CJGUI_LINUX_REDUCE_MOTION", &forced)) return forced ? 1 : 0;
    const char *environment = getenv("GTK_ENABLE_ANIMATIONS");
    if (environment && aux_settings_value_is_false(environment)) return 1;
    char value[256];
    if (aux_find_settings_value("gtk-enable-animations", value, sizeof(value)) &&
        aux_settings_value_is_false(value)) {
        return 1;
    }
    return 0;   // 未声明"减少动效" -> 保持动效
}

static int aux_parse_hex_color(const char *text, int64_t *outPacked) {
    if (!text || text[0] != '#' || !outPacked) return 0;
    uint32_t rgb = 0u;
    for (size_t index = 1u; index <= 6u; index += 1u) {
        const char character = text[index];
        uint32_t digit = 0u;
        if (character >= '0' && character <= '9') {
            digit = (uint32_t)(character - '0');
        } else if (character >= 'a' && character <= 'f') {
            digit = (uint32_t)(character - 'a') + 10u;
        } else if (character >= 'A' && character <= 'F') {
            digit = (uint32_t)(character - 'A') + 10u;
        } else {
            return 0;
        }
        rgb = (rgb << 4) | digit;
    }
    // 与 macOS 的打包约定一致：bit 24 置位 + RRGGBB（Cangjie observePacked 校验
    // 16777216 <= packed < 33554432）。
    *outPacked = (int64_t)(0x1000000u | rgb);
    return 1;
}

// 在 GTK CSS 里找强调色定义（GNOME/libadwaita 42+ 把用户强调色写进这些文件）：
//   @define-color accent_bg_color #RRGGBB;   （优先）
//   @define-color accent_color #RRGGBB;
static int aux_scan_css_accent(const char *directory, const char *file, int64_t *outPacked) {
    if (!directory || !file || !outPacked) return 0;
    char path[AUX_PATH_CAPACITY];
    int written = snprintf(path, sizeof(path), "%s/%s", directory, file);
    if (written <= 0 || (size_t)written >= sizeof(path)) return 0;
    FILE *stream = fopen(path, "r");
    if (!stream) return 0;
    char line[AUX_LINE_CAPACITY];
    int64_t backgroundAccent = 0;
    int64_t plainAccent = 0;
    while (fgets(line, (int)sizeof(line), stream)) {
        const char *marker = strstr(line, "@define-color");
        if (!marker) continue;
        const char *cursor = marker + strlen("@define-color");
        while (*cursor == ' ' || *cursor == '\t') cursor += 1;
        const char *nameStart = cursor;
        while (*cursor && *cursor != ' ' && *cursor != '\t' && *cursor != '\n') cursor += 1;
        size_t nameLength = (size_t)(cursor - nameStart);
        int isBackground = nameLength == strlen("accent_bg_color") &&
                           strncmp(nameStart, "accent_bg_color", nameLength) == 0;
        int isPlain = nameLength == strlen("accent_color") &&
                      strncmp(nameStart, "accent_color", nameLength) == 0;
        if (!isBackground && !isPlain) continue;
        while (*cursor == ' ' || *cursor == '\t') cursor += 1;
        if (*cursor != '#') continue;
        int64_t packed = 0;
        if (!aux_parse_hex_color(cursor, &packed)) continue;
        if (isBackground && backgroundAccent == 0) backgroundAccent = packed;
        if (isPlain && plainAccent == 0) plainAccent = packed;
    }
    fclose(stream);
    if (backgroundAccent != 0) {
        *outPacked = backgroundAccent;
        return 1;
    }
    if (plainAccent != 0) {
        *outPacked = plainAccent;
        return 1;
    }
    return 0;
}

// 强调色：环境覆盖 > GTK CSS 定义 > 0（unavailable）。
// 返回 0 就是"一次不可用样本"（Cangjie observePacked 的既有语义），不是假颜色。
int64_t cjgui_macos_control_accent_srgb8(void) {
    const char *forced = getenv("CJGUI_LINUX_ACCENT_SRGB8");
    if (forced && forced[0]) {
        int64_t packed = 0;
        if (forced[0] == '#') {
            if (aux_parse_hex_color(forced, &packed)) return packed;
        } else {
            char withHash[8];
            if (strlen(forced) == 6u) {
                withHash[0] = '#';
                memcpy(withHash + 1, forced, 6u);
                withHash[7] = '\0';
                if (aux_parse_hex_color(withHash, &packed)) return packed;
            }
        }
        // 取值不合法则继续走真实来源，不猜。
    }
    static const char *const cssFiles[3] = { "gtk-4.0/gtk.css", "gtk-4.0/libadwaita.css", "gtk-3.0/gtk.css" };
    char configDirectory[AUX_PATH_CAPACITY];
    if (aux_config_directory(configDirectory, sizeof(configDirectory))) {
        for (size_t index = 0u; index < 3u; index += 1u) {
            int64_t packed = 0;
            if (aux_scan_css_accent(configDirectory, cssFiles[index], &packed)) return packed;
        }
    }
    int64_t packed = 0;
    if (aux_scan_css_accent("/etc/gtk-4.0", "gtk.css", &packed)) return packed;
    if (aux_scan_css_accent("/etc/gtk-3.0", "gtk.css", &packed)) return packed;
    return 0;   // 没有可用的强调色样本
}

// 窗口可见性：本层没有窗口句柄（窗口在 session.c 里），无法读取 map state。
// 保守值 1（可见）的理由：Cangjie 侧 composable_ui_window.cj:21683 把它当作
// "初始文字焦点是否可恢复"的条件之一，报不可见会静默关掉正常功能；而
// composable_ui_platform_state.cj 已有"不可断言不可见就报可见"的既有约定。
// 真实值需要 session.c 从 X11（map state / _NET_WM_STATE_HIDDEN）提供。
int32_t cjgui_macos_window_visible(int64_t windowNumber) {
    (void)windowNumber;
    return 1;
}

// 窗口最小化：同上，保守值 0（未最小化）。报 1 会禁止初始文字焦点安装，
// 而本层并无证据证明窗口被最小化。
int32_t cjgui_macos_window_minimized(int64_t windowNumber) {
    (void)windowNumber;
    return 0;
}

int cjgui_linux_aux_shortcut_declared(uint64_t token, const char *shortcut, uint64_t focusScope) {
    if (!shortcut || !shortcut[0]) return 0;
    CjguiLinuxAuxSlot *state = aux_acquire(token);
    if (!state || !state->menuAcceptedActive) return 0;
    for (uint32_t index = 0u; index < state->menuAcceptedCount; index += 1u) {
        const CjguiLinuxAuxCommandMenuItem *item = &state->menuAccepted[index];
        if (!item->present || !item->shortcut || strcmp(item->shortcut, shortcut) != 0) continue;
        if (item->focusScope != 0u && item->focusScope != focusScope) continue;
        return 1;
    }
    if (getenv("CJGUI_LINUX_AUX_TRACE")) {
        fprintf(stderr, "CJGUI_LINUX_AUX shortcut_miss=[%s] scope=%llu accepted=%u active=%d\n",
                shortcut, (unsigned long long)focusScope, state->menuAcceptedCount,
                state->menuAcceptedActive);
    }
    return 0;
}
