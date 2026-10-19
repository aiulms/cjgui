// runtime/cjgui/platforms/linux/native/cjgui_linux_window.c
//
// Linux/X11 窗口与输入子系统（窄平台实现）。契约见 cjgui_linux_window.h。
//
// 设计要点（和契约头一起读）：
//  * 全部状态挂在 CjguiLinuxWindow 上；只有 cjgui_linux_window_wake 允许跨线程
//    （往自唤醒管道写一个字节），其余函数只在渲染会话所属线程调用。
//  * X11 错误是异步的。这里装进程级 XSetErrorHandler：计数 + stderr 打印，并且
//    在"必须知道成败"的调用（XCreateWindow / XSetWMProtocols）外围一个 probe 区间
//    + XSync，失败就整体清理返回 NULL，绝不带着坏窗口继续跑。
//  * 事件只搬运，不合并、不重排、不丢弃。搬运目的地有两个：调用方数组，或本模块的
//    暂存环形队列（有界，256 条）。size() 排空、剪贴板 round-trip 这类"顺路把事件
//    取走"的路径会把事件放进暂存队列，下一次带缓冲的 pump 按原顺序交付。队列真的满
//    时按条丢最晚的，并计数 + stderr 限速打印 + cjgui_linux_window_take_input_overflow
//    可取走，绝不静默丢弃后假装成功。
//  * 坐标一律 像素 / 整数DPR -> 逻辑点；X11 本来就是左上原点、+y 向下。
//  * DPR：第一阶段只做整数 1x/2x，来源是 GDK_SCALE 或 Xft.dpi（默认 1）。
//  * IME：XIM/XIC 用 XIMPreeditCallbacks 接入系统输入法（ibus/fcitx 的 XIM 服务）。
//    预编辑由本层缓存并作为 COMPOSITION_* 事件上报，提交文本进入既有 owner 路径；
//    被 XFilterEvent 消费的按键不产生普通 KEY_DOWN/KEY_UP。候选窗位置由会话在
//    已接受场景里声明的光标几何（set_ime_spot）决定。
//
// 链接依赖：libX11、libX11-xcb（XGetXCBConnection 给 Vulkan WSI 用 xcb surface）。

#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

#include "cjgui_linux_window.h"

#include <X11/XKBlib.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xlib-xcb.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

#include <errno.h>
#include <fcntl.h>
#include <locale.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <wchar.h>

// 暂存队列容量：剪贴板 round-trip 最长等 2 秒，期间的手势事件要有地方放。
#define CJGUI_LINUX_PENDING_CAPACITY 256u
// 剪贴板 round-trip 上限；超时返回失败，绝不无限等。
#define CJGUI_LINUX_CLIPBOARD_TIMEOUT_MS 2000u
// X11 协议里窗口尺寸是 16 位有符号；超过这个值建窗会被服务端拒绝。
#define CJGUI_LINUX_MAX_WINDOW_SIDE 32767u

// ---------------------------------------------------------------------------
// Xlib 错误处理（进程级）
// ---------------------------------------------------------------------------

static unsigned long g_x_error_count = 0;   // 异步错误累计（诊断用）
static int g_x_probe_active = 0;            // 是否处于"必须知道成败"的探测区间
static int g_x_probe_hit = 0;               // 探测区间内是否发生过错误
static int g_x_probe_code = 0;              // 探测区间内第一条错误的错误码

static int cjgui_linux_x_error_handler(Display *display, XErrorEvent *event) {
    char text[256];
    text[0] = '\0';
    XGetErrorText(display, event->error_code, text, (int)sizeof(text));
    g_x_error_count += 1;
    if (g_x_probe_active != 0) {
        if (g_x_probe_hit == 0) {
            g_x_probe_code = (int)event->error_code;
        }
        g_x_probe_hit = 1;
    }
    fprintf(stderr,
            "[cjgui-linux-window] X11 error #%lu: code=%d (%s) request=%d.%d resource=0x%lx\n",
            g_x_error_count, (int)event->error_code, text, (int)event->request_code,
            (int)event->minor_code, (unsigned long)event->resourceid);
    fflush(stderr);
    return 0;   // 不让默认 handler 终止进程；错误已记录
}

static int cjgui_linux_x_io_error_handler(Display *display) {
    (void)display;
    // 连接断了就没有可恢复的路径：留下可读日志，返回后由 Xlib 结束进程。
    fputs("[cjgui-linux-window] X11 I/O error: display connection lost\n", stderr);
    fflush(stderr);
    return 0;
}

static void cjgui_linux_install_error_handlers(void) {
    XSetErrorHandler(cjgui_linux_x_error_handler);
    XSetIOErrorHandler(cjgui_linux_x_io_error_handler);
}

static void cjgui_linux_probe_begin(void) {
    g_x_probe_active = 1;
    g_x_probe_hit = 0;
    g_x_probe_code = 0;
}

// 返回 1 表示区间内发生过 X11 错误。XSync 保证异步错误已经递到 handler。
static int cjgui_linux_probe_end(Display *display) {
    XSync(display, False);
    g_x_probe_active = 0;
    return g_x_probe_hit;
}

// ---------------------------------------------------------------------------
// 窗口状态
// ---------------------------------------------------------------------------

struct CjguiLinuxWindow {
    Display *display;
    int screen;
    Window window;
    Colormap colormap;
    void *xcb_connection;   // xcb_connection_t*，给 Vulkan WSI 用

    Atom wm_protocols;
    Atom wm_delete_window;
    Atom net_wm_name;
    Atom net_wm_pid;
    Atom utf8_string;
    Atom text_atom;
    Atom targets_atom;
    Atom clipboard_atom;
    Atom clipboard_property;

    uint32_t logical_width;    // 逻辑点
    uint32_t logical_height;
    int scale_int;             // 整数 DPR（1 或 2）
    double scale;

    int close_requested;
    int resized_since_query;
    int saw_configure;         // 是否已收到过服务端的第一条 ConfigureNotify
    int window_destroyed;
    uint64_t last_server_time_ms;

    int wake_read_fd;
    int wake_write_fd;

    char *clipboard_text;      // 自己持有的 CLIPBOARD 内容（UTF-8，NUL 结尾）
    size_t clipboard_length;
    int clipboard_owner;

    // 异步读取：SelectionNotify 在 pump 内完成，结果在这里等会话取走。
    int clipboard_request_active;
    uint64_t clipboard_request_deadline_ms;
    int clipboard_result_status;
    char *clipboard_result_text;
    size_t clipboard_result_length;

    // XIM/XIC。预编辑缓冲区只保存纯文本；caret 是 preedit 内部的字符位置。
    XIM xim;
    XIC xic;
    int ime_available;
    int ime_focused;
    char ime_preedit[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    size_t ime_preedit_length;
    int ime_preedit_active;
    int ime_preedit_caret;
    char ime_last_preedit[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    size_t ime_last_preedit_length;
    int ime_last_active;
    int ime_last_caret;
    double ime_spot_x;
    double ime_spot_y;
    double ime_spot_height;
    int ime_spot_valid;
    // Xlib 不复制回调记录；它们必须活得和 IC 一样久。
    XIMCallback ime_start_cb;
    XIMCallback ime_done_cb;
    XIMCallback ime_draw_cb;
    XIMCallback ime_caret_cb;

    // 事件暂存环（见文件头"搬运目的地"说明）
    CjguiLinuxWindowEvent pending[CJGUI_LINUX_PENDING_CAPACITY];
    uint32_t pending_head;
    uint32_t pending_count;
    uint64_t pending_dropped;          // 累计丢弃（日志限速用）
    uint64_t pending_dropped_unreported;   // 尚未被 take_input_overflow 取走的丢弃数
};

// ---------------------------------------------------------------------------
// 小工具
// ---------------------------------------------------------------------------

static uint64_t cjgui_linux_now_ms(void) {
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return 0;
    }
    return (uint64_t)ts.tv_sec * 1000u + (uint64_t)(ts.tv_nsec / 1000000);
}

static double cjgui_linux_to_logical(int pixels, double scale) {
    return (double)pixels / scale;
}

static uint32_t cjgui_linux_pixels_to_logical(uint32_t pixels, int scale) {
    if (scale < 1) {
        scale = 1;
    }
    return (pixels + (uint32_t)scale / 2u) / (uint32_t)scale;
}

static uint32_t cjgui_linux_pixels_from_logical(uint32_t points, int scale) {
    if (scale < 1) {
        scale = 1;
    }
    uint64_t pixels = (uint64_t)points * (uint64_t)scale;
    if (pixels < 1u) {
        pixels = 1u;
    }
    if (pixels > CJGUI_LINUX_MAX_WINDOW_SIDE) {
        pixels = CJGUI_LINUX_MAX_WINDOW_SIDE;
    }
    return (uint32_t)pixels;
}

static uint64_t cjgui_linux_event_time(CjguiLinuxWindow *window, Time server_time) {
    // 事件时间统一留在 X11 服务器时间轴上（单调不减）。ConfigureNotify/Expose/
    // Focus 这些事件本身没有 time 字段，沿用最近一次服务器时间。
    if ((uint64_t)server_time >= window->last_server_time_ms) {
        window->last_server_time_ms = (uint64_t)server_time;
    }
    return window->last_server_time_ms;
}

static void cjgui_linux_event_init(CjguiLinuxWindowEvent *event, uint32_t kind, uint64_t time_ms) {
    memset(event, 0, sizeof(*event));
    event->kind = kind;
    event->timeMs = time_ms;
}

static void cjgui_linux_pending_push(CjguiLinuxWindow *window, const CjguiLinuxWindowEvent *event) {
    if (window->pending_count >= CJGUI_LINUX_PENDING_CAPACITY) {
        // 队列有界；满了必须留痕（累计计数 + 限速日志 + take_input_overflow 可取走），
        // 绝不静默丢弃后假装成功。
        window->pending_dropped += 1;
        window->pending_dropped_unreported += 1;
        if (window->pending_dropped == 1 || (window->pending_dropped % 128u) == 0) {
            fprintf(stderr, "[cjgui-linux-window] event backlog full (%u), dropped %llu event(s)\n",
                    CJGUI_LINUX_PENDING_CAPACITY, (unsigned long long)window->pending_dropped);
            fflush(stderr);
        }
        return;
    }
    uint32_t slot = (window->pending_head + window->pending_count) % CJGUI_LINUX_PENDING_CAPACITY;
    window->pending[slot] = *event;
    window->pending_count += 1;
}

static int cjgui_linux_pending_pop(CjguiLinuxWindow *window, CjguiLinuxWindowEvent *out_event) {
    if (window->pending_count == 0) {
        return 0;
    }
    *out_event = window->pending[window->pending_head];
    window->pending_head = (window->pending_head + 1u) % CJGUI_LINUX_PENDING_CAPACITY;
    window->pending_count -= 1;
    return 1;
}

// 交付一条事件：有调用方缓冲就写进去，否则进暂存队列（不丢）。
static void cjgui_linux_deliver(CjguiLinuxWindow *window, const CjguiLinuxWindowEvent *event,
                                CjguiLinuxWindowEvent *out_events, uint32_t limit,
                                uint32_t *out_count) {
    if (*out_count < limit) {
        out_events[*out_count] = *event;
        *out_count += 1;
        return;
    }
    cjgui_linux_pending_push(window, event);
}

// ---------------------------------------------------------------------------
// 修饰键 / 文本
// ---------------------------------------------------------------------------

static uint32_t cjgui_linux_modifiers_from_state(unsigned int state) {
    uint32_t modifiers = 0;
    if ((state & ShiftMask) != 0) {
        modifiers |= CJGUI_LINUX_MOD_SHIFT;
    }
    if ((state & ControlMask) != 0) {
        modifiers |= CJGUI_LINUX_MOD_CONTROL;
    }
    if ((state & Mod1Mask) != 0) {
        modifiers |= CJGUI_LINUX_MOD_ALT;
    }
    if ((state & Mod4Mask) != 0) {
        modifiers |= CJGUI_LINUX_MOD_SUPER;
    }
    if ((state & LockMask) != 0) {
        modifiers |= CJGUI_LINUX_MOD_CAPS;
    }
    return modifiers;
}

// 修饰键自身的按下/抬起：事件里的 state 不含"正在被按下的这个键"，这里补上，
// 上层才能从 KEY_DOWN 直接读到 SHIFT/CONTROL 位。
static uint32_t cjgui_linux_modifier_of_keysym(KeySym keysym) {
    switch (keysym) {
        case XK_Shift_L:
        case XK_Shift_R:
            return CJGUI_LINUX_MOD_SHIFT;
        case XK_Control_L:
        case XK_Control_R:
            return CJGUI_LINUX_MOD_CONTROL;
        case XK_Alt_L:
        case XK_Alt_R:
        case XK_Meta_L:
        case XK_Meta_R:
            return CJGUI_LINUX_MOD_ALT;
        case XK_Super_L:
        case XK_Super_R:
        case XK_Hyper_L:
        case XK_Hyper_R:
            return CJGUI_LINUX_MOD_SUPER;
        case XK_Caps_Lock:
            return CJGUI_LINUX_MOD_CAPS;
        default:
            return 0;
    }
}

static int cjgui_linux_is_ascii_printable(unsigned char c) {
    return c >= 0x20u && c <= 0x7eu;
}

// 正式验收默认安静；排查输入法链路时用 CJGUI_IME_DEBUG=1 打开逐键诊断。
static int cjgui_linux_ime_debug_enabled(void) {
    static int enabled = -1;
    if (enabled < 0) {
        const char *value = getenv("CJGUI_IME_DEBUG");
        enabled = (value != NULL && value[0] != '\0' && strcmp(value, "0") != 0) ? 1 : 0;
    }
    return enabled;
}

#define CJGUI_IME_LOG(...)                                                        \
    do {                                                                          \
        if (cjgui_linux_ime_debug_enabled()) {                                    \
            fprintf(stderr, "[cjgui-linux-ime] " __VA_ARGS__);                    \
            fflush(stderr);                                                       \
        }                                                                         \
    } while (0)

// 预编辑字符索引 -> UTF-8 字节偏移（不切开多字节字符）。
static size_t cjgui_linux_ime_char_offset(const char *text, size_t length, int chars) {
    size_t offset = 0u;
    int seen = 0;
    while (offset < length && seen < chars) {
        unsigned char c = (unsigned char)text[offset];
        size_t step = 1u;
        if ((c & 0xE0u) == 0xC0u) step = 2u;
        else if ((c & 0xF0u) == 0xE0u) step = 3u;
        else if ((c & 0xF8u) == 0xF0u) step = 4u;
        if (offset + step > length) step = 1u;
        offset += step;
        seen += 1;
    }
    return offset;
}

static uint32_t cjgui_linux_utf16_for_prefix(const char *text, size_t length, size_t byte_offset) {
    if (byte_offset > length) byte_offset = length;
    uint32_t units = 0u;
    size_t index = 0u;
    while (index < byte_offset) {
        unsigned char c = (unsigned char)text[index];
        size_t step = 1u;
        uint32_t scalar = c;
        if ((c & 0xE0u) == 0xC0u) { step = 2u; scalar = c & 0x1Fu; }
        else if ((c & 0xF0u) == 0xE0u) { step = 3u; scalar = c & 0x0Fu; }
        else if ((c & 0xF8u) == 0xF0u) { step = 4u; scalar = c & 0x07u; }
        if (index + step > length) step = 1u;
        for (size_t i = 1u; i < step; i++) {
            scalar = (scalar << 6) | ((uint32_t)text[index + i] & 0x3Fu);
        }
        units += (scalar > 0xFFFFu) ? 2u : 1u;
        index += step;
    }
    return units;
}

static void cjgui_linux_ime_clear_preedit(CjguiLinuxWindow *window) {
    window->ime_preedit_length = 0u;
    window->ime_preedit[0] = '\0';
    window->ime_preedit_active = 0;
    window->ime_preedit_caret = 0;
}

// 应用一次增量 preedit 更新。容量不足时整条拒绝（保留上一份 preedit），
// 绝不截断成半个字符；提交路径不依赖这份缓存，所以不会因此丢已提交文本。
static void cjgui_linux_ime_apply_draw(CjguiLinuxWindow *window, XIMPreeditDrawCallbackStruct *draw) {
    int first = draw->chg_first;
    int remove = draw->chg_length;
    if (first < 0) first = 0;
    if (remove < 0) remove = 0;
    const char *old = window->ime_preedit;
    size_t old_length = window->ime_preedit_length;
    size_t before = cjgui_linux_ime_char_offset(old, old_length, first);
    size_t after = cjgui_linux_ime_char_offset(old, old_length, first + remove);

    char inserted[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    size_t insert_length = 0u;
    if (draw->text != NULL) {
        if (draw->text->encoding_is_wchar) {
            const wchar_t *wtext = draw->text->string.wide_char;
            if (wtext != NULL) {
                size_t space = sizeof(inserted) - 1u;
                size_t converted = wcstombs(inserted, wtext, space);
                if (converted == (size_t)-1) return;
                insert_length = converted;
            }
        } else {
            const char *mtext = draw->text->string.multi_byte;
            if (mtext != NULL) {
                // XIMText.length 计的是字符数；多字节串按 NUL 结尾的字节数
                // 合并，否则中文会被截成半个 UTF-8 字符。
                insert_length = strlen(mtext);
                if (insert_length >= sizeof(inserted)) return;
                memcpy(inserted, mtext, insert_length);
            }
        }
    }
    inserted[insert_length] = '\0';

    size_t new_length = before + insert_length + (old_length - after);
    if (new_length >= sizeof(window->ime_preedit)) {
        fprintf(stderr, "[cjgui-linux-window] preedit rejected: %zu bytes exceed capacity\n",
                new_length);
        fflush(stderr);
        return;
    }
    char merged[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    memcpy(merged, old, before);
    if (insert_length > 0u) memcpy(merged + before, inserted, insert_length);
    memcpy(merged + before + insert_length, old + after, old_length - after);
    merged[new_length] = '\0';
    memcpy(window->ime_preedit, merged, new_length + 1u);
    window->ime_preedit_length = new_length;
    window->ime_preedit_active = 1;
    if (window->ime_preedit_caret > (int)new_length) window->ime_preedit_caret = (int)new_length;
}

static void cjgui_linux_ime_preedit_start_cb(XIC ic, XPointer client, XPointer call) {
    (void)ic; (void)call;
    CjguiLinuxWindow *window = (CjguiLinuxWindow *)client;
    if (window == NULL) return;
    window->ime_preedit_active = 1;
    window->ime_preedit_caret = 0;
    CJGUI_IME_LOG("preedit start\n");
}

static void cjgui_linux_ime_preedit_done_cb(XIC ic, XPointer client, XPointer call) {
    (void)ic; (void)call;
    CjguiLinuxWindow *window = (CjguiLinuxWindow *)client;
    if (window == NULL) return;
    window->ime_preedit_active = 0;
    CJGUI_IME_LOG("preedit done (len=%zu)\n", window->ime_preedit_length);
}

static void cjgui_linux_ime_preedit_draw_cb(XIC ic, XPointer client, XIMPreeditDrawCallbackStruct *draw) {
    (void)ic;
    CjguiLinuxWindow *window = (CjguiLinuxWindow *)client;
    if (window == NULL || draw == NULL) return;
    CJGUI_IME_LOG("preedit draw first=%d remove=%d text=%s\n", draw->chg_first, draw->chg_length,
                  (draw->text != NULL && !draw->text->encoding_is_wchar &&
                   draw->text->string.multi_byte != NULL)
                      ? draw->text->string.multi_byte
                      : "<wchar/none>");
    cjgui_linux_ime_apply_draw(window, draw);
}

static void cjgui_linux_ime_preedit_caret_cb(XIC ic, XPointer client, XIMPreeditCaretCallbackStruct *caret) {
    (void)ic;
    CjguiLinuxWindow *window = (CjguiLinuxWindow *)client;
    if (window == NULL || caret == NULL) return;
    if (caret->position >= 0) window->ime_preedit_caret = (int)caret->position;
    CJGUI_IME_LOG("preedit caret pos=%d\n", caret->position);
}

static void cjgui_linux_ime_fill_event(CjguiLinuxWindow *window, uint32_t kind, uint64_t time_ms,
                                       const char *text, size_t length, CjguiLinuxWindowEvent *event) {
    cjgui_linux_event_init(event, kind, time_ms);
    if (text == NULL) length = 0u;
    if (length >= sizeof(event->utf8)) length = sizeof(event->utf8) - 1u;
    if (length > 0u) memcpy(event->utf8, text, length);
    event->utf8[length] = '\0';
    event->utf8Length = (uint32_t)length;
    if (kind == CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_UPDATE) {
        size_t caret_bytes = cjgui_linux_ime_char_offset(text, length, window->ime_preedit_caret);
        event->compositionCaret16 = cjgui_linux_utf16_for_prefix(text, length, caret_bytes);
    }
}

// 把输入法回调积累的状态变化变成上层的 update/cancel。提交文本走单独事件，
// 不在这里推 cancel；没有变化不重复上报。
static void cjgui_linux_ime_flush(CjguiLinuxWindow *window, uint64_t time_ms,
                                  CjguiLinuxWindowEvent *out_events, uint32_t limit,
                                  uint32_t *out_count) {
    int active = window->ime_preedit_active && window->ime_preedit_length > 0u;
    size_t length = window->ime_preedit_length;
    int caret = window->ime_preedit_caret;
    if (active) {
        if (window->ime_last_active && window->ime_last_preedit_length == length &&
            window->ime_last_caret == caret &&
            memcmp(window->ime_last_preedit, window->ime_preedit, length) == 0) {
            return;
        }
        CjguiLinuxWindowEvent event;
        cjgui_linux_ime_fill_event(window, CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_UPDATE, time_ms,
                                   window->ime_preedit, length, &event);
        cjgui_linux_deliver(window, &event, out_events, limit, out_count);
    } else if (window->ime_last_active) {
        CjguiLinuxWindowEvent event;
        cjgui_linux_ime_fill_event(window, CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_CANCEL, time_ms,
                                   NULL, 0u, &event);
        cjgui_linux_deliver(window, &event, out_events, limit, out_count);
    }
    window->ime_last_active = active;
    window->ime_last_caret = caret;
    window->ime_last_preedit_length = length;
    if (length > 0u) memcpy(window->ime_last_preedit, window->ime_preedit, length);
    window->ime_last_preedit[length] = '\0';
}

// 普通（非组合）键文本。XLookupString 把 Shift/Level 应用到 keymap；控制字符
// 不进 utf8，快捷键由 keySym+modifiers 表达。
static void cjgui_linux_fill_key_text(CjguiLinuxWindow *window, const XKeyEvent *key,
                                      int pressed, CjguiLinuxWindowEvent *event) {
    char text[64];
    KeySym keysym = NoSymbol;
    int text_length = XLookupString((XKeyEvent *)key, text, (int)sizeof(text), &keysym, NULL);
    if (keysym == NoSymbol) {
        keysym = XkbKeycodeToKeysym(window->display, (KeyCode)key->keycode, 0, 0);
    }

    cjgui_linux_event_init(event,
                           pressed ? CJGUI_LINUX_WINDOW_EVENT_KEY_DOWN
                                   : CJGUI_LINUX_WINDOW_EVENT_KEY_UP,
                           cjgui_linux_event_time(window, key->time));
    event->modifiers = cjgui_linux_modifiers_from_state(key->state) |
                       cjgui_linux_modifier_of_keysym(keysym);
    event->keySym = (uint32_t)keysym;
    event->keyCode = (uint32_t)key->keycode;
    event->x = cjgui_linux_to_logical(key->x, window->scale);
    event->y = cjgui_linux_to_logical(key->y, window->scale);

    if (pressed != 0) {
        uint32_t length = 0;
        for (int i = 0; i < text_length && length + 1u < (uint32_t)sizeof(event->utf8); i++) {
            if (cjgui_linux_is_ascii_printable((unsigned char)text[i])) {
                event->utf8[length] = text[i];
                length += 1u;
            }
        }
        event->utf8[length] = '\0';
        event->utf8Length = length;
    } else {
        event->utf8[0] = '\0';
        event->utf8Length = 0;
    }
}

// ---------------------------------------------------------------------------
// 剪贴板（CLIPBOARD，owner + 响应 SelectionRequest）
// ---------------------------------------------------------------------------

// 把属性写成我们持有的文本；type 决定声明的属性类型。
static void cjgui_linux_clipboard_write_property(CjguiLinuxWindow *window, Window requestor,
                                                 Atom property, Atom type) {
    const unsigned char *data = (const unsigned char *)(window->clipboard_text != NULL
                                                           ? window->clipboard_text
                                                           : "");
    XChangeProperty(window->display, requestor, property, type, 8, PropModeReplace, data,
                    (int)window->clipboard_length);
}

static void cjgui_linux_handle_selection_request(CjguiLinuxWindow *window,
                                                 XSelectionRequestEvent *request) {
    XSelectionEvent notify;
    memset(&notify, 0, sizeof(notify));
    notify.type = SelectionNotify;
    notify.display = request->display;
    notify.requestor = request->requestor;
    notify.selection = request->selection;
    notify.target = request->target;
    notify.property = None;
    notify.time = request->time;

    // 过时的客户端会把 property 留成 None，约定用 target 当属性名。
    Atom property = (request->property != None) ? request->property : request->target;

    if (request->selection == window->clipboard_atom && window->clipboard_text != NULL) {
        if (request->target == window->utf8_string || request->target == window->text_atom ||
            request->target == XA_STRING) {
            cjgui_linux_clipboard_write_property(window, request->requestor, property,
                                                 request->target);
            notify.property = property;
        } else if (request->target == window->targets_atom) {
            Atom supported[3];
            supported[0] = window->utf8_string;
            supported[1] = window->text_atom;
            supported[2] = XA_STRING;
            XChangeProperty(window->display, request->requestor, property, XA_ATOM, 32,
                            PropModeReplace, (const unsigned char *)supported, 3);
            notify.property = property;
        }
        // 其它 target：property 保持 None，请求方会看到"不支持"。
    }

    XSendEvent(window->display, request->requestor, False, 0, (XEvent *)&notify);
    XFlush(window->display);
}

static void cjgui_linux_release_clipboard(CjguiLinuxWindow *window) {
    window->clipboard_owner = 0;
    free(window->clipboard_text);
    window->clipboard_text = NULL;
    window->clipboard_length = 0;
}

static void cjgui_linux_clipboard_clear_result(CjguiLinuxWindow *window) {
    window->clipboard_result_status = CJGUI_LINUX_CLIPBOARD_READ_IDLE;
    free(window->clipboard_result_text);
    window->clipboard_result_text = NULL;
    window->clipboard_result_length = 0u;
    window->clipboard_request_active = 0;
}

static void cjgui_linux_clipboard_set_text(CjguiLinuxWindow *window, int status,
                                           const char *text, size_t length) {
    cjgui_linux_clipboard_clear_result(window);
    window->clipboard_result_status = status;
    if (status != CJGUI_LINUX_CLIPBOARD_READ_READY) return;
    char *copy = (char *)malloc(length + 1u);
    if (copy == NULL) {
        window->clipboard_result_status = CJGUI_LINUX_CLIPBOARD_READ_ERROR;
        return;
    }
    if (length > 0u) memcpy(copy, text, length);
    copy[length] = '\0';
    window->clipboard_result_text = copy;
    window->clipboard_result_length = length;
}

// SelectionNotify 到达：一次性把属性读全。bytes_after > 0 表示超过显式容量，
// 整笔 TOO_LARGE 且不保留任何前缀；不支持的类型明确记 UNSUPPORTED。
static void cjgui_linux_clipboard_finish(CjguiLinuxWindow *window, XSelectionEvent *notify) {
    window->clipboard_request_active = 0;
    if (notify->property == None) {
        cjgui_linux_clipboard_set_text(window, CJGUI_LINUX_CLIPBOARD_READ_UNSUPPORTED, NULL, 0u);
        return;
    }
    Atom type = None;
    int format = 0;
    unsigned long items = 0u;
    unsigned long bytes_after = 0u;
    unsigned char *data = NULL;
    long long_length = (long)((CJGUI_LINUX_CLIPBOARD_CAPACITY + 3u) / 4u) + 1;
    int ok = XGetWindowProperty(window->display, window->window, window->clipboard_property, 0,
                                long_length, False, AnyPropertyType, &type, &format, &items,
                                &bytes_after, &data);
    int text_type = (type == window->utf8_string || type == window->text_atom ||
                     type == XA_STRING);
    int status = CJGUI_LINUX_CLIPBOARD_READ_ERROR;
    if (ok == Success && format == 8 && text_type != 0) {
        // 容量含终止 NUL：take 要求 length < capacity，这里同一判据，
        // 避免运输成功后才在取走时才发现放不下。
        if (bytes_after > 0u || items >= CJGUI_LINUX_CLIPBOARD_CAPACITY) {
            status = CJGUI_LINUX_CLIPBOARD_READ_TOO_LARGE;
        } else if (items == 0u) {
            status = CJGUI_LINUX_CLIPBOARD_READ_EMPTY;
        } else {
            status = CJGUI_LINUX_CLIPBOARD_READ_READY;
            cjgui_linux_clipboard_set_text(window, status, (const char *)data, (size_t)items);
        }
    } else if (ok == Success && text_type != 0) {
        status = CJGUI_LINUX_CLIPBOARD_READ_UNSUPPORTED;
    }
    if (data != NULL) XFree(data);
    if (status != CJGUI_LINUX_CLIPBOARD_READ_READY) {
        cjgui_linux_clipboard_set_text(window, status, NULL, 0u);
    }
    XDeleteProperty(window->display, window->window, window->clipboard_property);
}

static void cjgui_linux_clipboard_check_timeout(CjguiLinuxWindow *window) {
    if (window->clipboard_request_active == 0) return;
    if (cjgui_linux_now_ms() < window->clipboard_request_deadline_ms) return;
    window->clipboard_request_active = 0;
    cjgui_linux_clipboard_set_text(window, CJGUI_LINUX_CLIPBOARD_READ_TIMEOUT, NULL, 0u);
    fprintf(stderr, "[cjgui-linux-window] clipboard read timed out; text unchanged\n");
    fflush(stderr);
}

// ---------------------------------------------------------------------------
// 事件翻译
// ---------------------------------------------------------------------------

static void cjgui_linux_handle_event(CjguiLinuxWindow *window, XEvent *xevent,
                                     CjguiLinuxWindowEvent *out_events, uint32_t limit,
                                     uint32_t *out_count) {
    CjguiLinuxWindowEvent event;
    // XIM 的协议事件（属性/客户端消息）也要经过 XFilterEvent，否则输入法
    // 内部状态与按键不同步；按键在各自的 case 里过滤，避免重复投递。
    if (window->xic != NULL && xevent->type != KeyPress && xevent->type != KeyRelease) {
        int filtered = XFilterEvent(xevent, None);
        // 输入法可以在服务端结束组合（Escape 被它抓走时客户端收不到按键），
        // 这里把回调累积的状态变化补发成 cancel/update。
        cjgui_linux_ime_flush(window, cjgui_linux_event_time(window, 0), out_events, limit,
                              out_count);
        if (filtered) {
            return;
        }
    }

    switch (xevent->type) {
        case ConfigureNotify: {
            // 真实与合成（客户端自己请求导致的）ConfigureNotify 都处理：两者都描述
            // 服务端认可的几何，后到的会覆盖先到的。
            int pixel_width = xevent->xconfigure.width;
            int pixel_height = xevent->xconfigure.height;
            if (pixel_width <= 0 || pixel_height <= 0) {
                break;   // 0 尺寸（收起/未映射）不作为新尺寸上报
            }
            uint32_t logical_width =
                cjgui_linux_pixels_to_logical((uint32_t)pixel_width, window->scale_int);
            uint32_t logical_height =
                cjgui_linux_pixels_to_logical((uint32_t)pixel_height, window->scale_int);
            int changed = (logical_width != window->logical_width ||
                           logical_height != window->logical_height);
            window->logical_width = logical_width;
            window->logical_height = logical_height;
            if (changed == 0 && window->saw_configure != 0) {
                break;   // 尺寸没变且服务端已确认过一次：不重复上报
            }
            // 第一条 ConfigureNotify 无条件上报：它是服务端对"窗口真实尺寸"的确认
            // （WM 可能已经改过尺寸），上层据此建/重建交换链。
            window->saw_configure = 1;
            window->resized_since_query = 1;
            cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_RESIZE,
                                   cjgui_linux_event_time(window, 0));
            event.x = (double)logical_width;     // RESIZE 用 x/y 承载新宽高（逻辑点）
            event.y = (double)logical_height;
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case Expose: {
            // 契约要求不合并：X11 的 Expose 连发（count 递减）原样透传，上层按
            // "收到任意一条即整窗重绘"消费即可。x/y 是暴露矩形原点（逻辑点）。
            cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_EXPOSE,
                                   cjgui_linux_event_time(window, 0));
            event.x = cjgui_linux_to_logical(xevent->xexpose.x, window->scale);
            event.y = cjgui_linux_to_logical(xevent->xexpose.y, window->scale);
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case ClientMessage: {
            if (xevent->xclient.message_type == window->wm_protocols &&
                (Atom)xevent->xclient.data.l[0] == window->wm_delete_window) {
                window->close_requested = 1;
                cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_CLOSE,
                                       cjgui_linux_event_time(window, xevent->xclient.data.l[1]));
                cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            }
            break;
        }

        case MotionNotify: {
            cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE,
                                   cjgui_linux_event_time(window, xevent->xmotion.time));
            event.modifiers = cjgui_linux_modifiers_from_state(xevent->xmotion.state);
            event.x = cjgui_linux_to_logical(xevent->xmotion.x, window->scale);
            event.y = cjgui_linux_to_logical(xevent->xmotion.y, window->scale);
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case ButtonPress:
        case ButtonRelease: {
            uint32_t button = (uint32_t)xevent->xbutton.button;
            int pressed = (xevent->type == ButtonPress);
            double px = cjgui_linux_to_logical(xevent->xbutton.x, window->scale);
            double py = cjgui_linux_to_logical(xevent->xbutton.y, window->scale);
            uint32_t modifiers = cjgui_linux_modifiers_from_state(xevent->xbutton.state);
            uint64_t time_ms = cjgui_linux_event_time(window, xevent->xbutton.time);

            if (button >= 4u && button <= 7u) {
                // 4/5 竖直滚轮，6/7 水平滚轮；只在按下时发一条，对应的
                // ButtonRelease 是同一动作的尾部，不再重复发。
                if (pressed == 0) {
                    break;
                }
                cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_WHEEL, time_ms);
                event.modifiers = modifiers;
                event.x = px;
                event.y = py;
                event.button = button;
                switch (button) {
                    case 4u: event.scrollY = -1.0; break;   // 上滚：内容向上
                    case 5u: event.scrollY = 1.0; break;    // 下滚：内容向下
                    case 6u: event.scrollX = -1.0; break;   // 左滚
                    case 7u: event.scrollX = 1.0; break;    // 右滚
                    default: break;
                }
                cjgui_linux_deliver(window, &event, out_events, limit, out_count);
                break;
            }

            cjgui_linux_event_init(&event,
                                   pressed ? CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN
                                           : CJGUI_LINUX_WINDOW_EVENT_POINTER_UP,
                                   time_ms);
            event.modifiers = modifiers;
            event.x = px;
            event.y = py;
            event.button = button;   // X11 button 编号原样保留
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case EnterNotify:
        case LeaveNotify: {
            // 抓取导致的进出不是真实指针移动（菜单/自建模态会触发），跳过。
            if (xevent->xcrossing.mode == NotifyGrab || xevent->xcrossing.mode == NotifyUngrab) {
                break;
            }
            int entering = (xevent->type == EnterNotify);
            cjgui_linux_event_init(&event,
                                   entering ? CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE
                                            : CJGUI_LINUX_WINDOW_EVENT_POINTER_LEAVE,
                                   cjgui_linux_event_time(window, xevent->xcrossing.time));
            event.modifiers = cjgui_linux_modifiers_from_state(xevent->xcrossing.state);
            event.x = cjgui_linux_to_logical(xevent->xcrossing.x, window->scale);
            event.y = cjgui_linux_to_logical(xevent->xcrossing.y, window->scale);
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case KeyPress: {
            uint64_t time_ms = cjgui_linux_event_time(window, xevent->xkey.time);
            int composing_before = window->ime_preedit_active && window->ime_preedit_length > 0u;
            int filtered = 0;
            if (window->xic != NULL) {
                filtered = XFilterEvent(xevent, window->window);
            }
            if (filtered) {
                // XFilterEvent 返回 True 表示输入法已消费这次按键。此时不能再
                // XmbLookupString：IBus 会把当前 preedit 当作提交文本返回，
                // 造成组合态提前落字。提交文本由未被过滤的按键取出（SDL 同序）。
                CJGUI_IME_LOG("key filtered=1 composing_before=%d\n", composing_before);
                cjgui_linux_ime_flush(window, time_ms, out_events, limit, out_count);
                break;
            }
            char committed[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
            size_t committed_length = 0u;
            KeySym keysym = NoSymbol;
            Status lookup_status = XLookupNone;
            if (window->xic != NULL) {
                KeySym looked = NoSymbol;
                Status status = XLookupNone;
                int n = XmbLookupString(window->xic, &xevent->xkey, committed,
                                        (int)sizeof(committed) - 1, &looked, &status);
                if (status == XBufferOverflow) {
                    // 整条拒绝而不是截断：提交文本拿不全时绝不提交半截。
                    fprintf(stderr,
                            "[cjgui-linux-window] IME commit rejected: text exceeds %u bytes\n",
                            CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY);
                    fflush(stderr);
                    committed_length = 0u;
                    lookup_status = XLookupNone;
                } else {
                    committed_length = (n > 0) ? (size_t)n : 0u;
                    committed[committed_length] = '\0';
                    keysym = looked;
                    lookup_status = status;
                }
            }
            CJGUI_IME_LOG("key filtered=0 status=%d keysym=0x%lx n=%zu composing_before=%d\n",
                          (int)lookup_status, (unsigned long)keysym, committed_length,
                          composing_before);
            if (committed_length > 0u) {
                if (composing_before) {
                    // 组字提交：进入共同层的 commit 相位，不再作为普通按键。
                    CjguiLinuxWindowEvent commit;
                    cjgui_linux_ime_fill_event(window, CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_COMMIT,
                                               time_ms, committed, committed_length, &commit);
                    cjgui_linux_deliver(window, &commit, out_events, limit, out_count);
                    cjgui_linux_ime_clear_preedit(window);
                    window->ime_last_active = 0;
                    window->ime_last_preedit_length = 0u;
                    window->ime_last_preedit[0] = '\0';
                    if (lookup_status == XLookupBoth && !filtered) {
                        cjgui_linux_fill_key_text(window, &xevent->xkey, 1, &event);
                        event.utf8[0] = '\0';
                        event.utf8Length = 0u;
                        cjgui_linux_deliver(window, &event, out_events, limit, out_count);
                    }
                    break;
                }
                // 非组合态的多字节直输（XIC 也会返回普通字符）。
                cjgui_linux_fill_key_text(window, &xevent->xkey, 1, &event);
                if (committed_length >= sizeof(event.utf8)) committed_length = sizeof(event.utf8) - 1u;
                memcpy(event.utf8, committed, committed_length);
                event.utf8[committed_length] = '\0';
                event.utf8Length = (uint32_t)committed_length;
                cjgui_linux_deliver(window, &event, out_events, limit, out_count);
                cjgui_linux_ime_flush(window, time_ms, out_events, limit, out_count);
                break;
            }
            if (!filtered) {
                if (window->xic == NULL || lookup_status == XLookupKeySym ||
                    lookup_status == XLookupBoth || lookup_status == XLookupNone) {
                    cjgui_linux_fill_key_text(window, &xevent->xkey, 1, &event);
                    if (window->xic != NULL && lookup_status != XLookupNone && keysym != NoSymbol) {
                        event.keySym = (uint32_t)keysym;
                    }
                    if (window->xic == NULL || lookup_status != XLookupNone) {
                        cjgui_linux_deliver(window, &event, out_events, limit, out_count);
                    }
                }
            }
            // 输入法消费的按键不上报普通键；预编辑变化仍要上报。
            cjgui_linux_ime_flush(window, time_ms, out_events, limit, out_count);
            break;
        }
        case KeyRelease: {
            uint64_t time_ms = cjgui_linux_event_time(window, xevent->xkey.time);
            if (window->xic != NULL && XFilterEvent(xevent, window->window)) {
                break;
            }
            cjgui_linux_fill_key_text(window, &xevent->xkey, 0, &event);
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            break;
        }

        case FocusIn:
        case FocusOut: {
            // NotifyGrab/NotifyUngrab 是临时抓取期间的焦点抖动，不当作焦点转移。
            if (xevent->xfocus.mode == NotifyGrab || xevent->xfocus.mode == NotifyUngrab) {
                break;
            }
            uint64_t time_ms = cjgui_linux_event_time(window, 0);
            cjgui_linux_event_init(&event,
                                   (xevent->type == FocusIn) ? CJGUI_LINUX_WINDOW_EVENT_FOCUS_IN
                                                             : CJGUI_LINUX_WINDOW_EVENT_FOCUS_OUT,
                                   time_ms);
            cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            if (window->xic != NULL) {
                if (xevent->type == FocusIn) {
                    XSetICFocus(window->xic);
                    window->ime_focused = 1;
                    CJGUI_IME_LOG("focus in -> XSetICFocus\n");
                    cjgui_linux_window_set_ime_spot(window, window->ime_spot_x, window->ime_spot_y,
                                                    window->ime_spot_height);
                } else {
                    XUnsetICFocus(window->xic);
                    window->ime_focused = 0;
                    CJGUI_IME_LOG("focus out -> XUnsetICFocus\n");
                    // 失焦即结束本次组合：共同层把 preedit 当作已取消，不写正文。
                    cjgui_linux_ime_clear_preedit(window);
                    cjgui_linux_ime_flush(window, time_ms, out_events, limit, out_count);
                }
            }
            break;
        }

        case SelectionNotify:
            if (xevent->xselection.selection == window->clipboard_atom &&
                window->clipboard_request_active != 0) {
                cjgui_linux_clipboard_finish(window, &xevent->xselection);
            }
            break;

        case SelectionRequest:
            cjgui_linux_handle_selection_request(window, &xevent->xselectionrequest);
            break;

        case SelectionClear:
            if (xevent->xselectionclear.selection == window->clipboard_atom) {
                cjgui_linux_release_clipboard(window);
            }
            break;

        case DestroyNotify:
            if (xevent->xdestroywindow.window == window->window) {
                // 窗口已经没了（WM 强杀等）。当作关闭请求上报，避免上层对着
                // 一个不存在的窗口继续提交帧。
                window->window_destroyed = 1;
                window->close_requested = 1;
                cjgui_linux_event_init(&event, CJGUI_LINUX_WINDOW_EVENT_CLOSE,
                                       cjgui_linux_event_time(window, 0));
                cjgui_linux_deliver(window, &event, out_events, limit, out_count);
            }
            break;

        case MappingNotify:
            XRefreshKeyboardMapping(&xevent->xmapping);
            break;

        default:
            break;
    }
}

// 把 X11 队列里已经到达的事件全部取走（转进暂存队列）。用于 size()/剪贴板
// round-trip 这类必须看到最新状态的路径；事件不会丢，只是延后交付。
static void cjgui_linux_drain_queue(CjguiLinuxWindow *window) {
    if (window->display == NULL) {
        return;
    }
    uint32_t sink = 0;
    while (XPending(window->display) > 0) {
        XEvent xevent;
        XNextEvent(window->display, &xevent);
        cjgui_linux_handle_event(window, &xevent, NULL, 0, &sink);
    }
}

static void cjgui_linux_drain_wake_pipe(CjguiLinuxWindow *window) {
    if (window->wake_read_fd < 0) {
        return;
    }
    char buffer[64];
    for (;;) {
        ssize_t n = read(window->wake_read_fd, buffer, sizeof(buffer));
        if (n > 0) {
            continue;
        }
        if (n < 0 && errno == EINTR) {
            continue;
        }
        break;   // 0 = 写端已关；-1/EAGAIN = 已排空
    }
}

// ---------------------------------------------------------------------------
// 标题
// ---------------------------------------------------------------------------

static void cjgui_linux_apply_title(CjguiLinuxWindow *window, const char *title) {
    const char *text = (title != NULL) ? title : "";
    // ICCCM 的 WM_NAME 走 XStoreName（受 locale 编码限制），UTF-8 真身在
    // _NET_WM_NAME 上；两者都写，老 WM 与新 WM 各取所需。
    XStoreName(window->display, window->window, text);
    XChangeProperty(window->display, window->window, window->net_wm_name, window->utf8_string, 8,
                    PropModeReplace, (const unsigned char *)text, (int)strlen(text));
}

// ---------------------------------------------------------------------------
// DPR（整数 1x/2x）
// ---------------------------------------------------------------------------

// 从资源管理器字符串里找 "Xft.dpi: <number>"。
static int cjgui_linux_lookup_dpi(const char *resources, double *out_dpi) {
    if (resources == NULL || out_dpi == NULL) {
        return 0;
    }
    const char *cursor = resources;
    while (*cursor != '\0') {
        const char *line_end = strchr(cursor, '\n');
        size_t line_length = (line_end != NULL) ? (size_t)(line_end - cursor) : strlen(cursor);
        if (line_length > 7u && strncmp(cursor, "Xft.dpi", 7u) == 0) {
            size_t i = 7u;
            while (i < line_length && (cursor[i] == ' ' || cursor[i] == '\t' || cursor[i] == ':')) {
                i += 1u;
            }
            char number[32];
            size_t n = 0;
            while (i < line_length && n + 1u < sizeof(number) &&
                   ((cursor[i] >= '0' && cursor[i] <= '9') || cursor[i] == '.')) {
                number[n] = cursor[i];
                n += 1u;
                i += 1u;
            }
            number[n] = '\0';
            if (n > 0) {
                double value = strtod(number, NULL);
                if (value > 0.0) {
                    *out_dpi = value;
                    return 1;
                }
            }
        }
        if (line_end == NULL) {
            break;
        }
        cursor = line_end + 1;
    }
    return 0;
}

// 第一阶段只支持整数 1x/2x：GDK_SCALE 优先（工具包显式覆盖），否则 Xft.dpi/96
// 四舍五入，最后夹到 [1, 2]。
static int cjgui_linux_resolve_scale_int(Display *display) {
    int scale = 0;
    const char *gdk_scale = getenv("GDK_SCALE");
    if (gdk_scale != NULL && *gdk_scale != '\0') {
        long value = strtol(gdk_scale, NULL, 10);
        if (value >= 1) {
            scale = (int)value;
        }
    }
    if (scale == 0) {
        double dpi = 0.0;
        if (cjgui_linux_lookup_dpi(XResourceManagerString(display), &dpi) != 0) {
            scale = (int)((dpi + 48.0) / 96.0);
        }
    }
    if (scale < 1) {
        scale = 1;
    }
    if (scale > 2) {
        scale = 2;
    }
    return scale;
}

// ---------------------------------------------------------------------------
// 公共接口
// ---------------------------------------------------------------------------

CjguiLinuxWindow *cjgui_linux_window_create(uint32_t width, uint32_t height, const char *title,
                                            int *out_status) {
    if (out_status != NULL) {
        *out_status = CJGUI_LINUX_WINDOW_OK;
    }
    cjgui_linux_install_error_handlers();

    Display *display = XOpenDisplay(NULL);
    if (display == NULL) {
        fprintf(stderr, "[cjgui-linux-window] XOpenDisplay failed (DISPLAY=%s)\n",
                getenv("DISPLAY") != NULL ? getenv("DISPLAY") : "(unset)");
        fflush(stderr);
        if (out_status != NULL) {
            *out_status = CJGUI_LINUX_WINDOW_UNAVAILABLE;
        }
        return NULL;
    }

    CjguiLinuxWindow *window = (CjguiLinuxWindow *)calloc(1, sizeof(*window));
    if (window == NULL) {
        XCloseDisplay(display);
        if (out_status != NULL) {
            *out_status = CJGUI_LINUX_WINDOW_CREATE_FAILED;
        }
        return NULL;
    }
    window->display = display;
    window->screen = DefaultScreen(display);
    window->window = None;
    window->colormap = None;
    window->wake_read_fd = -1;
    window->wake_write_fd = -1;
    window->scale_int = cjgui_linux_resolve_scale_int(display);
    window->scale = (double)window->scale_int;
    window->xcb_connection = (void *)XGetXCBConnection(display);
    if (window->xcb_connection == NULL) {
        fprintf(stderr, "[cjgui-linux-window] XGetXCBConnection returned NULL; "
                        "Vulkan 侧只能走 Xlib surface\n");
        fflush(stderr);
    }

    int wake_fds[2];
    if (pipe(wake_fds) != 0) {
        fprintf(stderr, "[cjgui-linux-window] pipe() failed: %s\n", strerror(errno));
        fflush(stderr);
        XCloseDisplay(display);
        free(window);
        if (out_status != NULL) {
            *out_status = CJGUI_LINUX_WINDOW_CREATE_FAILED;
        }
        return NULL;
    }
    for (int i = 0; i < 2; i++) {
        int flags = fcntl(wake_fds[i], F_GETFL, 0);
        if (flags >= 0) {
            (void)fcntl(wake_fds[i], F_SETFL, flags | O_NONBLOCK);
        }
        (void)fcntl(wake_fds[i], F_SETFD, FD_CLOEXEC);
    }
    window->wake_read_fd = wake_fds[0];
    window->wake_write_fd = wake_fds[1];

    window->wm_protocols = XInternAtom(display, "WM_PROTOCOLS", False);
    window->wm_delete_window = XInternAtom(display, "WM_DELETE_WINDOW", False);
    window->net_wm_name = XInternAtom(display, "_NET_WM_NAME", False);
    window->net_wm_pid = XInternAtom(display, "_NET_WM_PID", False);
    window->utf8_string = XInternAtom(display, "UTF8_STRING", False);
    window->text_atom = XInternAtom(display, "TEXT", False);
    window->targets_atom = XInternAtom(display, "TARGETS", False);
    window->clipboard_atom = XInternAtom(display, "CLIPBOARD", False);
    window->clipboard_property = XInternAtom(display, "CJGUI_CLIPBOARD", False);

    Visual *visual = DefaultVisual(display, window->screen);
    int depth = DefaultDepth(display, window->screen);
    Window root = RootWindow(display, window->screen);
    window->colormap = XCreateColormap(display, root, visual, AllocNone);

    uint32_t pixel_width =
        cjgui_linux_pixels_from_logical(width > 0u ? width : 1u, window->scale_int);
    uint32_t pixel_height =
        cjgui_linux_pixels_from_logical(height > 0u ? height : 1u, window->scale_int);

    XSetWindowAttributes attributes;
    memset(&attributes, 0, sizeof(attributes));
    attributes.background_pixmap = None;   // 内容由 Vulkan 提供，先不画背景
    attributes.border_pixel = 0;
    attributes.colormap = window->colormap;
    attributes.event_mask = StructureNotifyMask | ExposureMask | KeyPressMask | KeyReleaseMask |
                            ButtonPressMask | ButtonReleaseMask | PointerMotionMask |
                            EnterWindowMask | LeaveWindowMask | FocusChangeMask;

    // XCreateWindow 的错误是异步的：必须 XSync 之后才能判定成败（失败也必须
    // 整体清理返回 NULL，不能带着坏窗口继续跑）。
    cjgui_linux_probe_begin();
    Window xwindow = XCreateWindow(display, root, 0, 0, pixel_width, pixel_height, 0, depth,
                                   InputOutput, visual,
                                   CWBackPixmap | CWBorderPixel | CWColormap | CWEventMask,
                                   &attributes);
    int create_failed = cjgui_linux_probe_end(display);
    if (create_failed != 0 || xwindow == None) {
        fprintf(stderr, "[cjgui-linux-window] XCreateWindow failed (probe code=%d)\n",
                g_x_probe_code);
        fflush(stderr);
        XFreeColormap(display, window->colormap);
        close(window->wake_read_fd);
        close(window->wake_write_fd);
        XCloseDisplay(display);
        free(window);
        if (out_status != NULL) {
            *out_status = CJGUI_LINUX_WINDOW_CREATE_FAILED;
        }
        return NULL;
    }
    window->window = xwindow;
    window->logical_width = width > 0u ? width : 1u;
    window->logical_height = height > 0u ? height : 1u;

    Atom protocols[1];
    protocols[0] = window->wm_delete_window;
    if (XSetWMProtocols(display, xwindow, protocols, 1) == 0) {
        fprintf(stderr, "[cjgui-linux-window] XSetWMProtocols(WM_DELETE_WINDOW) failed\n");
        fflush(stderr);
        XDestroyWindow(display, xwindow);
        XFreeColormap(display, window->colormap);
        close(window->wake_read_fd);
        close(window->wake_write_fd);
        XCloseDisplay(display);
        free(window);
        if (out_status != NULL) {
            *out_status = CJGUI_LINUX_WINDOW_CREATE_FAILED;
        }
        return NULL;
    }

    cjgui_linux_apply_title(window, title);

    XClassHint class_hint;
    class_hint.res_name = (char *)"cjgui";
    class_hint.res_class = (char *)"Cjgui";
    XSetClassHint(display, xwindow, &class_hint);

    long pid = (long)getpid();
    XChangeProperty(display, xwindow, window->net_wm_pid, XA_CARDINAL, 32, PropModeReplace,
                    (const unsigned char *)&pid, 1);

    // XIM 的 focus window 必须在映射之后才参与资源查找；先映射并同步再建 IC。
    XMapWindow(display, xwindow);
    XSync(display, False);
    // XIM 接入系统输入法（ibus/fcitx 的 XIM 服务）。locale 必须与用户会话一致，
    // 否则 XmbLookupString 的提交编码不是 UTF-8。创建失败不影响 ASCII 直输。
    if (setlocale(LC_CTYPE, "") == NULL) {
        fprintf(stderr, "[cjgui-linux-window] setlocale(LC_CTYPE) failed; XIM may be unavailable\n");
    }
    XSetLocaleModifiers("");
    window->xim = XOpenIM(display, NULL, NULL, NULL);
    if (window->xim != NULL) {
        XIMStyles *styles = NULL;
        XIMStyle chosen = 0;
        if (XGetIMValues(window->xim, XNQueryInputStyle, &styles, NULL) == NULL && styles != NULL) {
            for (unsigned int i = 0u; i < styles->count_styles; i++) {
                XIMStyle style = styles->supported_styles[i];
                // 只选 preedit callbacks + status nothing：没有注册 status 回调时，
                // 带 XIMStatusCallbacks 的 IC 会让 Xlib 在创建期解引用空回调。
                if ((style & XIMPreeditCallbacks) && (style & XIMStatusNothing)) {
                    chosen = style;
                    break;
                }
            }
            XFree(styles);
        }
        if (chosen != 0) {
            window->ime_start_cb.client_data = (XPointer)window;
            window->ime_start_cb.callback = (XIMProc)cjgui_linux_ime_preedit_start_cb;
            window->ime_done_cb.client_data = (XPointer)window;
            window->ime_done_cb.callback = (XIMProc)cjgui_linux_ime_preedit_done_cb;
            window->ime_draw_cb.client_data = (XPointer)window;
            window->ime_draw_cb.callback = (XIMProc)cjgui_linux_ime_preedit_draw_cb;
            window->ime_caret_cb.client_data = (XPointer)window;
            window->ime_caret_cb.callback = (XIMProc)cjgui_linux_ime_preedit_caret_cb;
            // 回调必须用 XVaCreateNestedList 组成 preedit 子属性表；裸 vararg
            // 嵌套会在 Xlib 内崩溃，顶层回调则会被 IM 拒绝。
            XVaNestedList preedit = XVaCreateNestedList(
                0, XNPreeditStartCallback, &window->ime_start_cb,
                XNPreeditDoneCallback, &window->ime_done_cb,
                XNPreeditDrawCallback, &window->ime_draw_cb,
                XNPreeditCaretCallback, &window->ime_caret_cb, NULL);
            window->xic = XCreateIC(window->xim,
                                    XNInputStyle, chosen,
                                    XNClientWindow, xwindow,
                                    XNFocusWindow, xwindow,
                                    XNPreeditAttributes, preedit,
                                    NULL);
            if (preedit != NULL) XFree(preedit);
        }
        if (window->xic == NULL) {
            fprintf(stderr, "[cjgui-linux-window] XCreateIC(callbacks) failed; XIM disabled\n");
            XCloseIM(window->xim);
            window->xim = NULL;
        } else {
            window->ime_available = 1;
            // 窗口映射时 WM 可能已把焦点给了我们；FocusIn 若在 IC 建好前就到达，
            // 事件泵不会再补发一次。这里按当前输入焦点补设 IC 焦点，
            // 否则 XFilterEvent 不会把按键交给输入法。
            Window focus = None;
            int revert = 0;
            XGetInputFocus(display, &focus, &revert);
            if (focus == xwindow || focus == PointerRoot || focus == None) {
                XSetICFocus(window->xic);
                window->ime_focused = 1;
            }
            CJGUI_IME_LOG("IC created style=0x%lx focus=0x%lx ime_focused=%d\n",
                          (unsigned long)chosen, (unsigned long)focus, window->ime_focused);
        }
    } else {
        fprintf(stderr, "[cjgui-linux-window] XOpenIM failed; ASCII input only\n");
    }

    // 建窗返回后窗口在服务端确实存在且已映射：Vulkan 建 surface 不会踩空。
    return window;
}

void cjgui_linux_window_destroy(CjguiLinuxWindow *window) {
    if (window == NULL) {
        return;
    }
    if (window->display != NULL) {
        if (window->window != None && window->window_destroyed == 0) {
            XDestroyWindow(window->display, window->window);
            window->window = None;
        }
        if (window->colormap != None) {
            XFreeColormap(window->display, window->colormap);
            window->colormap = None;
        }
        if (window->xic != NULL) {
            XDestroyIC(window->xic);
            window->xic = NULL;
        }
        if (window->xim != NULL) {
            XCloseIM(window->xim);
            window->xim = NULL;
        }
        window->ime_available = 0;
        window->ime_focused = 0;
        XSync(window->display, False);
        XCloseDisplay(window->display);
        window->display = NULL;
    }
    free(window->clipboard_text);
    window->clipboard_text = NULL;
    free(window->clipboard_result_text);
    window->clipboard_result_text = NULL;
    if (window->wake_read_fd >= 0) {
        close(window->wake_read_fd);
        window->wake_read_fd = -1;
    }
    if (window->wake_write_fd >= 0) {
        close(window->wake_write_fd);
        window->wake_write_fd = -1;
    }
    free(window);
}

int cjgui_linux_window_native(CjguiLinuxWindow *window, void **out_display,
                              unsigned long *out_window_id, int *out_screen, void **out_connection) {
    if (window == NULL || window->display == NULL || window->window == None) {
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    if (out_display != NULL) {
        *out_display = (void *)window->display;
    }
    if (out_window_id != NULL) {
        *out_window_id = (unsigned long)window->window;
    }
    if (out_screen != NULL) {
        *out_screen = window->screen;
    }
    if (out_connection != NULL) {
        // 可能是 NULL（XGetXCBConnection 失败），调用方据此退回 Xlib surface。
        *out_connection = window->xcb_connection;
    }
    return CJGUI_LINUX_WINDOW_OK;
}

int cjgui_linux_window_pump(CjguiLinuxWindow *window, CjguiLinuxWindowEvent *out_events,
                            uint32_t max_events, uint32_t timeout_ms, uint32_t *out_count) {
    if (window == NULL || window->display == NULL) {
        if (out_count != NULL) {
            *out_count = 0;
        }
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    if (out_events == NULL) {
        max_events = 0;   // 没有缓冲就没有容量
    }
    const uint32_t limit = max_events;
    uint32_t count = 0;
    const uint64_t deadline = cjgui_linux_now_ms() + (uint64_t)timeout_ms;

    for (;;) {
        // 异步剪贴板请求不能让界面无限等：到点把结果置 TIMEOUT，会话照常泵键鼠/关闭。
        cjgui_linux_clipboard_check_timeout(window);
        // 1) 暂存队列优先：里面的事件比 X11 队列里的更早。
        while (count < limit) {
            CjguiLinuxWindowEvent stashed;
            if (cjgui_linux_pending_pop(window, &stashed) == 0) {
                break;
            }
            out_events[count] = stashed;
            count += 1u;
        }
        if (count > 0u) {
            if (out_count != NULL) {
                *out_count = count;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }
        if (limit == 0u && window->pending_count > 0u) {
            // 有缓冲的调用还欠着事件：算"有活动"，立刻返回让上层去取。
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }

        // 2) X11 队列。取满即停，剩余留在队列里等下次调用（不丢）。
        int had_x_events = 0;
        while (XPending(window->display) > 0) {
            if (limit != 0u && count >= limit) {
                break;
            }
            XEvent xevent;
            XNextEvent(window->display, &xevent);
            had_x_events = 1;
            cjgui_linux_handle_event(window, &xevent, out_events, limit, &count);
        }
        if (count > 0u) {
            if (out_count != NULL) {
                *out_count = count;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }
        if (limit == 0u && had_x_events != 0) {
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }

        // 3) 等待：X11 连接 fd 或自唤醒管道。
        if (timeout_ms == 0u) {
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }
        uint64_t now = cjgui_linux_now_ms();
        if (now >= deadline) {
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }
        uint64_t remaining = deadline - now;
        int wait_ms = (remaining > 2147483647u) ? 2147483647 : (int)remaining;

        struct pollfd fds[2];
        fds[0].fd = ConnectionNumber(window->display);
        fds[0].events = POLLIN;
        fds[0].revents = 0;
        fds[1].fd = window->wake_read_fd;
        fds[1].events = POLLIN;
        fds[1].revents = 0;

        int ready;
        do {
            ready = poll(fds, 2, wait_ms);
        } while (ready < 0 && errno == EINTR);

        if (ready < 0) {
            fprintf(stderr, "[cjgui-linux-window] poll() failed: %s\n", strerror(errno));
            fflush(stderr);
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_INVALID;
        }
        if (ready == 0) {
            continue;   // 超时：回到循环顶部收尾（deadline 检查会结束它）
        }
        if ((fds[1].revents & POLLIN) != 0) {
            cjgui_linux_drain_wake_pipe(window);
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_OK;
        }
        if ((fds[0].revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
            fprintf(stderr, "[cjgui-linux-window] X11 connection poll flags: 0x%x\n",
                    (unsigned)fds[0].revents);
            fflush(stderr);
            if (out_count != NULL) {
                *out_count = 0;
            }
            return CJGUI_LINUX_WINDOW_INVALID;
        }
        // X11 可读：回到循环顶部把它取走（可能只有非交付事件）。
    }
}

int cjgui_linux_window_size(CjguiLinuxWindow *window, uint32_t *out_width, uint32_t *out_height,
                            int *out_resized) {
    if (window == NULL || window->display == NULL) {
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    // 先把已到达的 ConfigureNotify 处理掉：不排空就返回，刚被 WM 改过尺寸的窗口
    // 会给出旧值（选型报告里记过的坑）。事件不丢，只是排进暂存队列。
    cjgui_linux_drain_queue(window);
    if (out_width != NULL) {
        *out_width = window->logical_width;
    }
    if (out_height != NULL) {
        *out_height = window->logical_height;
    }
    if (out_resized != NULL) {
        *out_resized = window->resized_since_query;
        window->resized_since_query = 0;
    }
    return CJGUI_LINUX_WINDOW_OK;
}

int cjgui_linux_window_close_requested(CjguiLinuxWindow *window) {
    if (window == NULL) {
        return 0;
    }
    return window->close_requested != 0 ? 1 : 0;
}

int cjgui_linux_window_take_input_overflow(CjguiLinuxWindow *window) {
    if (window == NULL) {
        return 0;
    }
    uint64_t dropped = window->pending_dropped_unreported;
    window->pending_dropped_unreported = 0;
    if (dropped > 2147483647u) {
        return 2147483647;   // int 范围上限：上层只需要知道"丢了、丢了多少"
    }
    return (int)dropped;
}

void cjgui_linux_window_wake(CjguiLinuxWindow *window) {
    if (window == NULL || window->wake_write_fd < 0) {
        return;
    }
    // 唯一允许跨线程的函数：写一个字节即可。管道满（说明已经有一次待处理唤醒）
    // 或写端已关闭都当作"无需再写"，忽略错误码。
    const char byte = 'w';
    ssize_t written;
    do {
        written = write(window->wake_write_fd, &byte, 1);
    } while (written < 0 && errno == EINTR);
    (void)written;
}

int cjgui_linux_window_set_title(CjguiLinuxWindow *window, const char *title) {
    if (window == NULL || window->display == NULL || window->window == None) {
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    cjgui_linux_apply_title(window, title);
    XFlush(window->display);
    return CJGUI_LINUX_WINDOW_OK;
}

double cjgui_linux_window_scale(CjguiLinuxWindow *window) {
    if (window == NULL) {
        return 1.0;
    }
    return window->scale;
}

void cjgui_linux_window_sync(CjguiLinuxWindow *window) {
    if (window == NULL || window->display == NULL) {
        return;
    }
    XSync(window->display, False);
}

void cjgui_linux_window_set_ime_spot(CjguiLinuxWindow *window, double x, double y, double height) {
    if (window == NULL) return;
    window->ime_spot_x = x;
    window->ime_spot_y = y;
    window->ime_spot_height = height;
    window->ime_spot_valid = 1;
    if (getenv("CJGUI_IME_DEBUG")) {
        fprintf(stderr, "CJGUI_IME_SPOT x=%.1f y=%.1f h=%.1f focused=%d\n",
                x, y, height, window->ime_focused);
        fflush(stderr);
    }
    if (window->xic == NULL || window->ime_focused == 0) return;
    Window child = None;
    int root_x = 0;
    int root_y = 0;
    int pixel_x = (int)(x * window->scale);
    int pixel_y = (int)((y + height) * window->scale);
    if (XTranslateCoordinates(window->display, window->window,
                              DefaultRootWindow(window->display), pixel_x, pixel_y,
                              &root_x, &root_y, &child) == 0) {
        root_x = pixel_x;
        root_y = pixel_y;
    }
    XPoint spot;
    spot.x = (short)root_x;
    spot.y = (short)root_y;
    XVaNestedList preedit = XVaCreateNestedList(0, XNSpotLocation, &spot, NULL);
    if (preedit != NULL) {
        XSetICValues(window->xic, XNPreeditAttributes, preedit, NULL);
        XFree(preedit);
    }
}

int cjgui_linux_window_request_clipboard(CjguiLinuxWindow *window) {
    if (window == NULL || window->display == NULL || window->window == None) {
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    // 新请求丢弃上一次未取走的结果：它属于上一笔粘贴，不能当本次输入。
    cjgui_linux_clipboard_clear_result(window);
    if (window->clipboard_owner != 0 && window->clipboard_text != NULL) {
        cjgui_linux_clipboard_set_text(window, CJGUI_LINUX_CLIPBOARD_READ_READY,
                                       window->clipboard_text, window->clipboard_length);
        return CJGUI_LINUX_WINDOW_OK;
    }
    if (XGetSelectionOwner(window->display, window->clipboard_atom) == None) {
        cjgui_linux_clipboard_set_text(window, CJGUI_LINUX_CLIPBOARD_READ_EMPTY, NULL, 0u);
        return CJGUI_LINUX_WINDOW_OK;
    }
    XDeleteProperty(window->display, window->window, window->clipboard_property);
    XConvertSelection(window->display, window->clipboard_atom, window->utf8_string,
                      window->clipboard_property, window->window, CurrentTime);
    XFlush(window->display);
    window->clipboard_request_active = 1;
    // take_clipboard 只认结果状态；请求在途必须是 PENDING，否则第一次轮询
    // 会把 IDLE 当成"已完成但没有数据"，SelectionNotify 到达后就无人取走。
    window->clipboard_result_status = CJGUI_LINUX_CLIPBOARD_READ_PENDING;
    window->clipboard_request_deadline_ms = cjgui_linux_now_ms() + CJGUI_LINUX_CLIPBOARD_TIMEOUT_MS;
    return CJGUI_LINUX_WINDOW_OK;
}

int cjgui_linux_window_take_clipboard(CjguiLinuxWindow *window, char *outUtf8, size_t capacity,
                                      size_t *outLength) {
    if (window == NULL) return CJGUI_LINUX_CLIPBOARD_READ_ERROR;
    if (outLength != NULL) *outLength = 0u;
    cjgui_linux_clipboard_check_timeout(window);
    int status = window->clipboard_result_status;
    if (status == CJGUI_LINUX_CLIPBOARD_READ_PENDING ||
        status == CJGUI_LINUX_CLIPBOARD_READ_IDLE) {
        return status;
    }
    if (status == CJGUI_LINUX_CLIPBOARD_READ_READY) {
        if (outUtf8 == NULL || capacity == 0u ||
            window->clipboard_result_length >= capacity) {
            cjgui_linux_clipboard_set_text(window, CJGUI_LINUX_CLIPBOARD_READ_TOO_LARGE, NULL, 0u);
            return window->clipboard_result_status;
        }
        if (window->clipboard_result_length > 0u) {
            memcpy(outUtf8, window->clipboard_result_text, window->clipboard_result_length);
        }
        outUtf8[window->clipboard_result_length] = '\0';
        if (outLength != NULL) *outLength = window->clipboard_result_length;
    }
    cjgui_linux_clipboard_clear_result(window);
    return status;
}

int cjgui_linux_window_set_clipboard(CjguiLinuxWindow *window, const char *utf8, size_t length) {
    if (window == NULL || window->display == NULL || window->window == None) {
        return CJGUI_LINUX_WINDOW_INVALID;
    }
    char *copy = NULL;
    if (utf8 != NULL && length > 0u) {
        copy = (char *)malloc(length + 1u);
        if (copy == NULL) {
            // 状态枚举里没有 OOM：用 CREATE_FAILED 表达"本层资源不足"，并在
            // stderr 说清原因（不静默失败）。
            fprintf(stderr, "[cjgui-linux-window] set_clipboard: out of memory (%zu bytes)\n",
                    length);
            fflush(stderr);
            return CJGUI_LINUX_WINDOW_CREATE_FAILED;
        }
        memcpy(copy, utf8, length);
        copy[length] = '\0';
    }
    cjgui_linux_release_clipboard(window);
    window->clipboard_text = copy;
    window->clipboard_length = (copy != NULL) ? length : 0u;

    XSetSelectionOwner(window->display, window->clipboard_atom, window->window, CurrentTime);
    XFlush(window->display);
    // 抢 owner 是 round-trip 判定（用户动作路径，不在帧循环里）：抢不到就是失败。
    window->clipboard_owner =
        (XGetSelectionOwner(window->display, window->clipboard_atom) == window->window) ? 1 : 0;
    if (window->clipboard_owner == 0) {
        fprintf(stderr, "[cjgui-linux-window] set_clipboard: CLIPBOARD owner is another client\n");
        fflush(stderr);
        return CJGUI_LINUX_WINDOW_SELECTION_EXTENSION_UNAVAILABLE;
    }
    return CJGUI_LINUX_WINDOW_OK;
}

int cjgui_linux_window_get_clipboard(CjguiLinuxWindow *window, char *out_utf8, size_t capacity) {
    if (window == NULL || window->display == NULL || out_utf8 == NULL || capacity == 0u) {
        return -1;
    }
    out_utf8[0] = '\0';

    // 自己就是 owner：本地取，省一次 round-trip（也避开"请求自己"的极端情况）。
    if (window->clipboard_owner != 0 && window->clipboard_text != NULL) {
        size_t n = window->clipboard_length;
        if (n > capacity - 1u) {
            // 与外部 owner 分支同一政策：放不下就整笔拒绝，不交前缀。
            fprintf(stderr,
                    "[cjgui-linux-window] get_clipboard: rejected, text exceeds %zu bytes\n",
                    capacity - 1u);
            fflush(stderr);
            return -2;
        }
        memcpy(out_utf8, window->clipboard_text, n);
        out_utf8[n] = '\0';
        return (int)n;
    }

    if (XGetSelectionOwner(window->display, window->clipboard_atom) == None) {
        return 0;   // 没有 owner：合法地"没有文本"，不是失败
    }

    XDeleteProperty(window->display, window->window, window->clipboard_property);
    XConvertSelection(window->display, window->clipboard_atom, window->utf8_string,
                      window->clipboard_property, window->window, CurrentTime);
    XFlush(window->display);

    const uint64_t deadline = cjgui_linux_now_ms() + CJGUI_LINUX_CLIPBOARD_TIMEOUT_MS;
    for (;;) {
        while (XPending(window->display) > 0) {
            XEvent xevent;
            XNextEvent(window->display, &xevent);
            if (xevent.type == SelectionNotify &&
                xevent.xselection.selection == window->clipboard_atom) {
                if (xevent.xselection.property == None) {
                    return 0;   // owner 不提供这个 target
                }
                Atom type = None;
                int format = 0;
                unsigned long items = 0;
                unsigned long bytes_after = 0;
                unsigned char *data = NULL;
                long long_length = (long)((capacity + 3u) / 4u) + 1;
                int ok = XGetWindowProperty(window->display, window->window,
                                            window->clipboard_property, 0, long_length, False,
                                            AnyPropertyType, &type, &format, &items, &bytes_after,
                                            &data);
                int text_type = (type == window->utf8_string || type == window->text_atom ||
                                 type == XA_STRING);
                size_t n = 0;
                int too_large = 0;
                if (ok == Success && data != NULL && format == 8 && text_type != 0) {
                    n = (size_t)items;
                    if (n > capacity - 1u || bytes_after > 0u) {
                        // 超长整笔拒绝：绝不把前缀当成功交出去。
                        too_large = 1;
                        n = 0u;
                    } else {
                        memcpy(out_utf8, data, n);
                    }
                }
                if (data != NULL) {
                    XFree(data);
                }
                XDeleteProperty(window->display, window->window, window->clipboard_property);
                if (too_large) {
                    fprintf(stderr,
                            "[cjgui-linux-window] get_clipboard: rejected, text exceeds %zu bytes\n",
                            capacity - 1u);
                    fflush(stderr);
                    out_utf8[0] = '\0';
                    return -2;
                }
                out_utf8[n] = '\0';
                return (int)n;
            }
            // 等待期间到达的其它事件一条都不能丢：排进暂存队列，交给下一次 pump。
            uint32_t sink = 0;
            cjgui_linux_handle_event(window, &xevent, NULL, 0, &sink);
        }
        uint64_t now = cjgui_linux_now_ms();
        if (now >= deadline) {
            fprintf(stderr, "[cjgui-linux-window] get_clipboard: SelectionNotify timeout\n");
            fflush(stderr);
            return -1;
        }
        uint64_t remaining = deadline - now;
        struct pollfd fd;
        fd.fd = ConnectionNumber(window->display);
        fd.events = POLLIN;
        fd.revents = 0;
        int ready;
        do {
            ready = poll(&fd, 1, (int)remaining);
        } while (ready < 0 && errno == EINTR);
        if (ready < 0) {
            fprintf(stderr, "[cjgui-linux-window] get_clipboard: poll() failed: %s\n",
                    strerror(errno));
            fflush(stderr);
            return -1;
        }
        if (ready == 0) {
            continue;   // 回到顶部由 deadline 判定失败
        }
    }
}
