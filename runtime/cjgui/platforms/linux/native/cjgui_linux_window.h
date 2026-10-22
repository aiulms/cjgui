// runtime/cjgui/platforms/linux/native/cjgui_linux_window.h
//
// Linux/X11 窗口与输入子系统（窄平台实现）。
//
// 这一层只负责"系统窗口 + 系统输入"：X11 连接、窗口创建与映射、WM 关闭协议、
// ConfigureNotify 尺寸变化、键鼠/滚轮/焦点事件，以及阻塞等待。它不做布局、不做
// 选择、不做撤销——那些是共同层（runtime/cjgui/src）的责任。
//
// 事件以 UTF-8 文本和 keysym/keycode 原样交给上层，上层的 inputSequence 契约再
// 决定顺序与消费。本层不合并、不丢弃、不重排已产生的事件。键文本优先走 XIM：
// 系统输入法消费的按键不上报为普通字符；预编辑/提交/取消作为独立事件上报。
//
// 线程约定：所有函数都只允许在渲染会话所属的那一个线程上调用；Display 连接不在
// 多线程间共享。唯一例外是 cjgui_linux_window_wake（自唤醒管道，可从任意线程写）。
//
// 实现备注（已与 Lead 确认，语义固定）：
//  * 事件顺序 = X11 产生顺序，不合并、不重排。Expose 连发原样透传（上层按"收到一条
//    即整窗重绘"消费即可）。事件不会丢，除非内部暂存队列（256 条）满：满时丢弃、
//    累计计数、stderr 限速打印，并由 cjgui_linux_window_take_input_overflow 取走。
//  * 本模块安装进程级 Xlib error handler / IO error handler（X11 错误是异步的）：
//    异步错误计数并打印到 stderr；XCreateWindow 这类"必须知道成败"的调用用 probe
//    区间 + XSync 判定，失败直接返回 NULL，绝不带着坏窗口继续跑。
//  * 链接依赖：libX11、libX11-xcb（后者只为 XGetXCBConnection）。

#ifndef CJGUI_LINUX_WINDOW_H
#define CJGUI_LINUX_WINDOW_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum CjguiLinuxWindowEventKind {
    CJGUI_LINUX_WINDOW_EVENT_NONE = 0,
    // WM_DELETE_WINDOW：用户请求关闭。这不是"立即销毁"，上层仍需走完退出握手。
    // 该状态是闩锁：一旦收到，cjgui_linux_window_close_requested 恒为 1。
    CJGUI_LINUX_WINDOW_EVENT_CLOSE = 1,
    // ConfigureNotify 生效后的新尺寸（逻辑点），由 x/y 承载：x = 新逻辑宽，
    // y = 新逻辑高，与 cjgui_linux_window_size() 共用同一份缓存值。窗口创建后的
    // 第一条 ConfigureNotify 无条件上报（服务端对真实尺寸的确认，WM 可能改过尺寸）；
    // 之后只在尺寸真的变化时上报。上层收到即可重建交换链。
    CJGUI_LINUX_WINDOW_EVENT_RESIZE = 2,
    // 需要重绘（Expose / 首次映射）。x/y 为暴露矩形原点（逻辑点）；X11 可能连发多条。
    CJGUI_LINUX_WINDOW_EVENT_EXPOSE = 3,
    // 窗口本地坐标，逻辑点（像素 / 整数DPR）。EnterNotify 也会产生一条 MOVE（指针
    // 确实到了那个位置）；NotifyGrab/NotifyUngrab 的进出与焦点抖动不上报。
    CJGUI_LINUX_WINDOW_EVENT_POINTER_MOVE = 4,
    CJGUI_LINUX_WINDOW_EVENT_POINTER_DOWN = 5,
    CJGUI_LINUX_WINDOW_EVENT_POINTER_UP = 6,
    CJGUI_LINUX_WINDOW_EVENT_POINTER_LEAVE = 7,
    // 滚轮：button 4/5 = 竖直（4 -> scrollY=-1，5 -> scrollY=+1），button 6/7 = 水平
    // （6 -> scrollX=-1，7 -> scrollX=+1）。只在 ButtonPress 上发一条；对应的
    // ButtonRelease 是同一动作的尾部，不重复发。
    CJGUI_LINUX_WINDOW_EVENT_WHEEL = 8,
    // 键盘：keySym 是 XLookupString/XmbLookupString 给出的 keysym（Shift 等已应用），
    // 修饰键按下面 CJGUI_LINUX_MOD_* 位（含"正在按下的这个修饰键"本身）。被系统
    // 输入法消费的按键不会产生 KEY_DOWN/KEY_UP；utf8 只承载非 IME 的直输文本。
    CJGUI_LINUX_WINDOW_EVENT_KEY_DOWN = 9,
    CJGUI_LINUX_WINDOW_EVENT_KEY_UP = 10,
    // 焦点转移；NotifyGrab/NotifyUngrab 期间的焦点抖动不上报。
    CJGUI_LINUX_WINDOW_EVENT_FOCUS_IN = 11,
    CJGUI_LINUX_WINDOW_EVENT_FOCUS_OUT = 12,
    // XIM 组合态（与共同层 kind 52 的 update/commit/cancel 一一对应）。
    // utf8 是本条事件的 preedit/提交文本，compositionCaret16 是 preedit 内部的
    // UTF-16 光标位置（相对 preedit，不是文档坐标）。
    CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_UPDATE = 13,
    CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_COMMIT = 14,
    CJGUI_LINUX_WINDOW_EVENT_COMPOSITION_CANCEL = 15
} CjguiLinuxWindowEventKind;

// 单条窗口事件的文本容量。组合提交可以包含多个字符；超限整条拒绝，绝不截断
// 成半个字符。剪贴板另有更大的显式容量（见下）。
#define CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY 4096u

// 修饰键位（与既有 inputSequence 修饰语义对齐）。
#define CJGUI_LINUX_MOD_SHIFT   0x0001u
#define CJGUI_LINUX_MOD_CONTROL 0x0002u
#define CJGUI_LINUX_MOD_ALT     0x0004u
#define CJGUI_LINUX_MOD_SUPER   0x0008u
#define CJGUI_LINUX_MOD_CAPS    0x0010u

// 指针按键（X11 button 编号，原样保留）。
#define CJGUI_LINUX_BUTTON_LEFT   1u
#define CJGUI_LINUX_BUTTON_MIDDLE 2u
#define CJGUI_LINUX_BUTTON_RIGHT  3u

// 一次输入事件。全部为值类型，不含任何 X11/系统指针。
typedef struct CjguiLinuxWindowEvent {
    uint32_t kind;       // CjguiLinuxWindowEventKind
    uint32_t modifiers;  // CJGUI_LINUX_MOD_*
    // 窗口本地坐标，逻辑点（已按 scale 反算，左上原点，+y 向下）。
    double x;
    double y;
    // 滚轮增量，逻辑点；+y 表示内容向下滚动（与 X11 button 5 一致）。
    double scrollX;
    double scrollY;
    uint32_t button;     // 指针/滚轮按键编号
    uint32_t keySym;     // X11 keysym
    uint32_t keyCode;    // X11 keycode
    // 该事件的 UTF-8 文本（直输/组合提交/preedit）。非 NUL 终止，以 utf8Length
    // 为准；数组本身保证 NUL 结尾便于调试打印。
    uint32_t utf8Length;
    char utf8[CJGUI_LINUX_WINDOW_EVENT_TEXT_CAPACITY];
    // 组合相位：preedit 内部光标（UTF-16，相对 preedit）。
    uint32_t compositionCaret16;
    // 事件时间戳（毫秒，X11 服务器时间轴；仅用于顺序与节流，不作 truth）。
    uint64_t timeMs;
} CjguiLinuxWindowEvent;

typedef struct CjguiLinuxWindow CjguiLinuxWindow;

typedef enum CjguiLinuxWindowStatus {
    CJGUI_LINUX_WINDOW_OK = 0,
    CJGUI_LINUX_WINDOW_UNAVAILABLE = 1,       // 无法打开 X11 Display
    CJGUI_LINUX_WINDOW_CREATE_FAILED = 2,     // 窗口/视件创建失败，或本层资源不足（分配失败）
    CJGUI_LINUX_WINDOW_SELECTION_EXTENSION_UNAVAILABLE = 3,   // 抢不到 selection owner
    CJGUI_LINUX_WINDOW_INVALID = 4            // 入参无效 / 连接或事件循环硬失败
} CjguiLinuxWindowStatus;

// 创建 X11 窗口。width/height 为逻辑点。title 可为 NULL。
// 失败返回 NULL 并把原因写入 *outStatus。
CjguiLinuxWindow *cjgui_linux_window_create(uint32_t width, uint32_t height, const char *title,
                                            int *outStatus);

// 释放窗口、XIM/XIC、剪贴板原子与 X11 连接。允许传 NULL。
void cjgui_linux_window_destroy(CjguiLinuxWindow *window);

// 取出 X11 Display* 与 Window（XID）供 Vulkan WSI 建 surface 使用。
// 输出为不透明句柄；调用方只把它们交给 vkCreateXcbSurfaceKHR / vkCreateXlibSurfaceKHR。
// 返回 0 表示成功。
// outConnection 是 xcb_connection_t*（可能为 NULL：XGetXCBConnection 失败，此时只能
// 走 Xlib surface）。该连接归窗口所有，生命周期与窗口一致：cjgui_linux_window_destroy
// 之后不得再引用（调用方须把 Vulkan 销毁排在窗口销毁之前）。
int cjgui_linux_window_native(CjguiLinuxWindow *window, void **outDisplay, unsigned long *outWindowId,
                              int *outScreen, void **outConnection);

// 泵事件。最多取 maxEvents 条，timeoutMs 为阻塞上限（0 = 不阻塞）。
// 返回 0 表示成功。事件按 X11 产生顺序写入 outEvents（不合并、不重排）。
// *outCount 写本次取到的事件数。若窗口收到关闭请求，事件流中会出现 CLOSE。
//
// maxEvents 同时是 outEvents 的容量：0（或 outEvents == NULL）表示"本次不搬运事件"，
// 只把已经到达的事件处理掉（更新尺寸/关闭/剪贴板状态，事件转入内部队列），并在
// 有活动（X 事件到达 / 内部队列非空 / 被 wake）时立即返回，否则最多阻塞 timeoutMs。
// 取满 maxEvents 条即返回，剩余事件留在队列里由下次调用继续取。
int cjgui_linux_window_pump(CjguiLinuxWindow *window, CjguiLinuxWindowEvent *outEvents,
                            uint32_t maxEvents, uint32_t timeoutMs, uint32_t *outCount);

// 查询当前逻辑尺寸。*outResized 在自上次调用后尺寸发生过变化时为 1（读后清零）。
// 该值来自已排空事件队列后的 ConfigureNotify，不做 round-trip 猜测：本函数在返回前
// 会先把已到达的 X11 事件处理掉（事件排进内部队列，不丢），所以不会给出旧尺寸。
int cjgui_linux_window_size(CjguiLinuxWindow *window, uint32_t *outWidth, uint32_t *outHeight,
                            int *outResized);

// 是否已收到 WM_DELETE_WINDOW。闩锁语义：收到后恒为 1，不会被本层清零。
int cjgui_linux_window_close_requested(CjguiLinuxWindow *window);

// 核心的 requestClose：只给这个窗口立关闭闩锁，核心随后 destroy 本会话。
// 不得触碰进程级 application-stop；多窗口时那会让其它窗口的泵变成退出请求。
void cjgui_linux_window_request_close(CjguiLinuxWindow *window);

// 取走"因内部事件队列（256 条）满而被丢弃"的事件数（读后清零，0 = 没有丢弃）。
// 队列满时绝不静默丢弃：丢弃数在这里如实暴露，上层据此上报
// CJGUI_INTERNAL_RENDERER_EVENT_HUMAN_INPUT_QUEUE_FULL，说明已接受的事件仍然保留。
int cjgui_linux_window_take_input_overflow(CjguiLinuxWindow *window);

// 从任意线程唤醒正在 cjgui_linux_window_pump 阻塞的会话（自唤醒 pipe）。
void cjgui_linux_window_wake(CjguiLinuxWindow *window);

// 等待 X11 连接或自唤醒 pipe 就绪，不取事件。deadline 为 CLOCK_MONOTONIC 纳秒。
// 返回 2 = 自唤醒已排空，1 = X11 可读需调用方 pump，0 = 到期/无窗口，-1 = poll 失败。
// 只允许会话线程调用；跨线程唤醒仍只走 cjgui_linux_window_wake。
int cjgui_linux_window_wait_ready(CjguiLinuxWindow *window, uint64_t deadline_ns, uint64_t *out_idle_ns);
// Poll every window at once; result: 1 X11 ready, 2 wake, 0 deadline, -1 error.
int cjgui_linux_window_wait_ready_multi(CjguiLinuxWindow **windows, uint32_t count,
                                        uint64_t deadline_ns, uint64_t *out_idle_ns);

// 设置窗口标题（标题被复制，不保留调用方指针）。返回 0 表示成功。
int cjgui_linux_window_set_title(CjguiLinuxWindow *window, const char *title);

// 设备像素比（整数阶；第一阶段只支持 1x/2x）。恒 >= 1.0。
double cjgui_linux_window_scale(CjguiLinuxWindow *window);

// 让 X11 立即处理完待决请求（仅用于收尾路径，不在帧循环里调用）。
void cjgui_linux_window_sync(CjguiLinuxWindow *window);

// 把系统剪贴板（CLIPBOARD）设为给定 UTF-8 文本；返回 0 表示成功。
// owner 是窗口自身（XSetSelectionOwner + 响应 SelectionRequest），跨进程读取由 X11
// selection 协议承担；抢占 owner 成功与否用一次 round-trip 判定。length 为 0 时清空。
// 同一模块的 get_clipboard 在自己是 owner 时直接本地读，不走 round-trip。
int cjgui_linux_window_set_clipboard(CjguiLinuxWindow *window, const char *utf8, size_t length);

// 显式剪贴板容量：完整 UTF-8 文本超过它时整笔拒绝（不复制前缀、不截断半个字符）。
#define CJGUI_LINUX_CLIPBOARD_CAPACITY 65536u

// 异步读取状态。Ctrl+V 只发起请求并继续泵键鼠/关闭事件；结果由 take 取走。
typedef enum CjguiLinuxClipboardReadStatus {
    CJGUI_LINUX_CLIPBOARD_READ_IDLE = 0,
    CJGUI_LINUX_CLIPBOARD_READ_PENDING = 1,
    CJGUI_LINUX_CLIPBOARD_READ_READY = 2,
    CJGUI_LINUX_CLIPBOARD_READ_EMPTY = 3,        // 无 owner 或合法空文本
    CJGUI_LINUX_CLIPBOARD_READ_UNSUPPORTED = 4,  // owner 不提供已实现的数据类型
    CJGUI_LINUX_CLIPBOARD_READ_TOO_LARGE = 5,    // 超过显式容量，未复制任何字节
    CJGUI_LINUX_CLIPBOARD_READ_TIMEOUT = 6,
    CJGUI_LINUX_CLIPBOARD_READ_ERROR = 7
} CjguiLinuxClipboardReadStatus;

// 发起一次 CLIPBOARD→UTF8_STRING 读取。自己就是 owner 时立即进入 READY。
// 返回 0 表示请求已受理；非 0 为 CjguiLinuxWindowStatus。
int cjgui_linux_window_request_clipboard(CjguiLinuxWindow *window);

// 取走当前结果。READY 时把完整文本复制到 outUtf8（容量不足则改为 TOO_LARGE，
// 一个字节都不写），其它状态不写 outUtf8。PENDING 会在内部按既有超时判定。
// 返回读取状态；0 长度文本是合法的 EMPTY。取走后状态回到 IDLE。
int cjgui_linux_window_take_clipboard(CjguiLinuxWindow *window, char *outUtf8, size_t capacity,
                                      size_t *outLength);

// 由会话在已接受场景给出光标几何后调用（逻辑点，窗口本地坐标）；用于候选窗定位。
void cjgui_linux_window_set_ime_spot(CjguiLinuxWindow *window, double x, double y, double height);

// 旧的同步读取入口。保留给一次性调用；超长时返回 -2 且一个字节都不写，
// 不再"截断但返回成功"。新的粘贴路径只用上面的异步接口。
int cjgui_linux_window_get_clipboard(CjguiLinuxWindow *window, char *outUtf8, size_t capacity);

#ifdef __cplusplus
}
#endif

#endif // CJGUI_LINUX_WINDOW_H
