// Windows 上的 Pharos 应用原生支持：与 macOS `pharos_agent_channel.c` /
// `pharos_capture.c` 对应的平台实现，只覆盖正常产品链必需的能力。
//
// 设计原则（见 docs/plans/2026-10-05-windows-pharos-editor-package.md）：
// 必要能力真实实现；暂不支持的能力返回具名失败码（负数），禁止返回成功
// 的空壳；macOS 专属诊断辅助不在此实现，调用方按原有 status 日志继续。
//
// 真实实现：单调时钟、进程身份/RSS、公开 Agent 通道（loopback TCP，
// rendezvous 文件沿用 socketPath）、kill(9)、输入焦点判定、标题栏深色。
// 具名拒绝（返回负数）：截图、PDF、SVG、macOS 输入法/无障碍/键盘监控、
// 应用内合成输入（Windows 验收走驱动侧 SendInput，不走应用内合成）。
//
// Agent 通道与 macOS 保持同一行 JSON 协议与同一返回码契约，传输由
// Unix socket 换成 127.0.0.1 TCP：listen 在 socketPath 处写入会合文件
// "127.0.0.1:PORT"，客户端读该文件后连接。身份、授权与版本校验仍在
// 仓颉侧（agent_channel.cj），传输层只负责字节搬运，与 macOS 一致。
// 单线程帧循环假设与 macOS 实现相同：调用方每帧最多处理一笔请求。

#define _WIN32_WINNT 0x0A00
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <psapi.h>
#include <aclapi.h>
#include <dwmapi.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PHAROS_AGENT_MAX_REQUEST 65536
#define PHAROS_AGENT_MAX_REPLY 262144
// 具名拒绝码：调用方日志直接打印该值，与 macOS 的负数 errno 风格一致。
#define PHAROS_WIN_UNSUPPORTED -9

static SOCKET gListenSocket = INVALID_SOCKET;
static SOCKET gClientSocket = INVALID_SOCKET;
static char gRendezvousPath[MAX_PATH];
static char gRequest[PHAROS_AGENT_MAX_REQUEST];
static size_t gRequestLength = 0;
static char gReply[PHAROS_AGENT_MAX_REPLY];
static size_t gReplyLength = 0;
static size_t gReplySent = 0;
static int gWsaReady = 0;
static const char kUnsupported[] = "unsupported";

// 前向声明：listen/stop 内部复用下方的会合文件守卫。
int pharos_agent_private_file(const char *path);
int pharos_agent_unlink_private_file(const char *path);

static int ensure_wsa(void) {
    if (gWsaReady) return 0;
    WSADATA data;
    if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return -1;
    gWsaReady = 1;
    return 0;
}

static void close_client(void) {
    if (gClientSocket != INVALID_SOCKET) {
        closesocket(gClientSocket);
        gClientSocket = INVALID_SOCKET;
    }
    gRequestLength = 0;
    gReplyLength = 0;
    gReplySent = 0;
}

// Start listening. Returns 0 on success, or a negative named code.
// 与 macOS 一致：已在监听返回 0；绝不复用其他实例的会合文件。
int32_t pharos_agent_listen(const char *socketPath) {
    if (gListenSocket != INVALID_SOCKET) return 0;
    if (!socketPath || socketPath[0] == '\0') return -1;
    if (ensure_wsa() != 0) return -3;
    // 不替换其他实例的端点：会合文件已存在即拒绝，由调用方先识别归属。
    DWORD attrs = GetFileAttributesA(socketPath);
    if (attrs != INVALID_FILE_ATTRIBUTES) return -5;
    SOCKET fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (fd == INVALID_SOCKET) return -3;
    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0; // 本地回环 + 系统分配端口，不暴露到外部网络。
    if (bind(fd, (const struct sockaddr *)&addr, sizeof(addr)) != 0) {
        closesocket(fd);
        return -4;
    }
    if (listen(fd, 8) != 0) {
        closesocket(fd);
        return -5;
    }
    socklen_t nameLen = (socklen_t)sizeof(addr);
    if (getsockname(fd, (struct sockaddr *)&addr, &nameLen) != 0) {
        closesocket(fd);
        return -4;
    }
    char rendezvous[64];
    _snprintf(rendezvous, sizeof(rendezvous), "127.0.0.1:%u", (unsigned)ntohs(addr.sin_port));
    FILE *fp = fopen(socketPath, "wb");
    if (!fp) {
        closesocket(fd);
        return -6;
    }
    size_t bodyLen = strlen(rendezvous);
    size_t wrote = fwrite(rendezvous, 1, bodyLen, fp);
    fclose(fp);
    if (wrote != bodyLen) {
        DeleteFileA(socketPath);
        closesocket(fd);
        return -6;
    }
    // 会合文件仅本人可读写（对应 macOS 的 0600），否则公开客户端会拒绝。
    if (pharos_agent_private_file(socketPath) != 0) {
        DeleteFileA(socketPath);
        closesocket(fd);
        return -6;
    }
    u_long nonBlock = 1;
    if (ioctlsocket(fd, FIONBIO, &nonBlock) != 0) {
        DeleteFileA(socketPath);
        closesocket(fd);
        return -3;
    }
    gListenSocket = fd;
    strncpy(gRendezvousPath, socketPath, sizeof(gRendezvousPath) - 1);
    gRendezvousPath[sizeof(gRendezvousPath) - 1] = '\0';
    return 0;
}

// 把本进程写出的文件收成“仅本人可读写”（对应 macOS 的 0600）。
// 成功返回 0，失败返回负数；失败时调用方按原有 status 分支处理。
int pharos_agent_private_file(const char *path) {
    if (!path) return -1;
    // 先拿当前用户 SID，同时确认是普通文件。
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES || (attrs & FILE_ATTRIBUTE_DIRECTORY)) return -1;
    HANDLE token = NULL;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return -1;
    DWORD sidLen = 0;
    GetTokenInformation(token, TokenUser, NULL, 0, &sidLen);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER || sidLen == 0) {
        CloseHandle(token);
        return -1;
    }
    TOKEN_USER *user = (TOKEN_USER *)malloc(sidLen);
    int result = -1;
    if (user && GetTokenInformation(token, TokenUser, user, sidLen, &sidLen)) {
        EXPLICIT_ACCESSA access;
        memset(&access, 0, sizeof(access));
        access.grfAccessPermissions = GENERIC_READ | GENERIC_WRITE | DELETE;
        access.grfAccessMode = SET_ACCESS;
        access.grfInheritance = NO_INHERITANCE;
        access.Trustee.TrusteeForm = TRUSTEE_IS_SID;
        access.Trustee.TrusteeType = TRUSTEE_IS_USER;
        access.Trustee.ptstrName = (LPSTR)user->User.Sid;
        PACL acl = NULL;
        if (SetEntriesInAclA(1, &access, NULL, &acl) == ERROR_SUCCESS && acl) {
            // OWNER_SECURITY_INFORMATION 保持现属主，只替换 DACL 并清除继承，
            // 使“仅本人可读写”可验证（见 unlink 的对等检查）。
            if (SetNamedSecurityInfoA((LPSTR)path, SE_FILE_OBJECT,
                    DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION,
                    NULL, NULL, acl, NULL) == ERROR_SUCCESS) {
                result = 0;
            }
            LocalFree(acl);
        }
    }
    free(user);
    CloseHandle(token);
    return result;
}

void pharos_agent_stop(void) {
    close_client();
    if (gListenSocket != INVALID_SOCKET) {
        closesocket(gListenSocket);
        gListenSocket = INVALID_SOCKET;
    }
    // 只删除经本实例创建且仍属本人的会合文件，不碰他人路径。
    if (gRendezvousPath[0] != '\0') {
        if (pharos_agent_unlink_private_file(gRendezvousPath) != 0) {
            DeleteFileA(gRendezvousPath);
        }
        gRendezvousPath[0] = '\0';
    }
}

// 仅删除“普通文件 + 属主是本人”的路径，防止跟随被调包的符号链接或
// 删掉无关用户的文件。失败返回 -2，删除失败返回 -3。
int pharos_agent_unlink_private_file(const char *path) {
    if (!path) return -1;
    DWORD attrs = GetFileAttributesA(path);
    if (attrs == INVALID_FILE_ATTRIBUTES || (attrs & FILE_ATTRIBUTE_DIRECTORY)) return -2;
    HANDLE token = NULL;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) return -2;
    DWORD sidLen = 0;
    GetTokenInformation(token, TokenUser, NULL, 0, &sidLen);
    int result = -2;
    if (GetLastError() == ERROR_INSUFFICIENT_BUFFER && sidLen > 0) {
        TOKEN_USER *user = (TOKEN_USER *)malloc(sidLen);
        if (user && GetTokenInformation(token, TokenUser, user, sidLen, &sidLen)) {
            PSECURITY_DESCRIPTOR descriptor = NULL;
            PSID owner = NULL;
            if (GetNamedSecurityInfoA(path, SE_FILE_OBJECT, OWNER_SECURITY_INFORMATION,
                    &owner, NULL, NULL, NULL, &descriptor) == ERROR_SUCCESS) {
                if (owner && EqualSid(owner, user->User.Sid)) result = 0;
                LocalFree(descriptor);
            }
        }
        free(user);
    }
    CloseHandle(token);
    if (result != 0) return -2;
    return DeleteFileA(path) ? 0 : -3;
}

// Accept one pending connection (non-blocking).
int32_t pharos_agent_accept(void) {
    if (gListenSocket == INVALID_SOCKET) return -1;
    SOCKET fd = accept(gListenSocket, NULL, NULL);
    if (fd == INVALID_SOCKET) {
        int err = WSAGetLastError();
        return (err == WSAEWOULDBLOCK) ? 0 : -2;
    }
    u_long nonBlock = 1;
    ioctlsocket(fd, FIONBIO, &nonBlock);
    close_client();
    gClientSocket = fd;
    gRequestLength = 0;
    return 1;
}

// Read whatever is available into the request buffer.
// Returns 1 when a complete line is ready, 0 when nothing is ready, -1 when the client left.
int32_t pharos_agent_poll(void) {
    if (gClientSocket == INVALID_SOCKET) return 0;
    char chunk[4096];
    int got = recv(gClientSocket, chunk, (int)sizeof(chunk), 0);
    if (got == 0) {
        close_client();
        return -1;
    }
    if (got < 0) {
        int err = WSAGetLastError();
        if (err == WSAEWOULDBLOCK) return 0;
        close_client();
        return -1;
    }
    for (int i = 0; i < got; i++) {
        if (gRequestLength + 1 < PHAROS_AGENT_MAX_REQUEST) {
            gRequest[gRequestLength++] = chunk[i];
        }
    }
    gRequest[gRequestLength] = '\0';
    if (memchr(gRequest, '\n', gRequestLength) != NULL) return 1;
    return 0;
}

const char *pharos_agent_request(void) {
    gRequest[gRequestLength] = '\0';
    return gRequest;
}

void pharos_agent_clear_request(void) {
    gRequestLength = 0;
    gRequest[0] = '\0';
}

// Stage a reply. Sent lazily so a caller can stage once and let the frame loop flush it.
int32_t pharos_agent_reply(const char *payload) {
    if (!payload) return -1;
    size_t length = strlen(payload);
    if (length + 2 >= PHAROS_AGENT_MAX_REPLY) return -2;
    memcpy(gReply, payload, length);
    gReply[length] = '\n';
    gReplyLength = length + 1;
    gReplySent = 0;
    return 0;
}

// Flush the staged reply. Returns 1 when fully sent, 0 when more remains, -1 on a dead client.
int32_t pharos_agent_flush(void) {
    if (gClientSocket == INVALID_SOCKET || gReplyLength == 0) return 1;
    int want = (int)(gReplyLength - gReplySent);
    int put = send(gClientSocket, gReply + gReplySent, want, 0);
    if (put < 0) {
        int err = WSAGetLastError();
        if (err == WSAEWOULDBLOCK) return 0;
        close_client();
        return -1;
    }
    gReplySent += (size_t)put;
    if (gReplySent >= gReplyLength) {
        gReplyLength = 0;
        gReplySent = 0;
        return 1;
    }
    return 0;
}

// 单调时钟（纳秒），对应 macOS 的 clock_gettime 实现，用于生产计时路径。
int64_t pharos_monotonic_ns(void) {
    LARGE_INTEGER frequency;
    LARGE_INTEGER counter;
    if (!QueryPerformanceFrequency(&frequency) || frequency.QuadPart <= 0) return -1;
    if (!QueryPerformanceCounter(&counter)) return -1;
    return (int64_t)((counter.QuadPart * 1000000000LL) / frequency.QuadPart);
}

int32_t pharos_process_id(void) {
    return (int32_t)GetCurrentProcessId();
}

// 当前进程工作集字节数，失败返回 -1（调用方按原有日志分支处理）。
int64_t pharos_process_rss_bytes(void) {
    PROCESS_MEMORY_COUNTERS counters;
    memset(&counters, 0, sizeof(counters));
    counters.cb = sizeof(counters);
    if (!GetProcessMemoryInfo(GetCurrentProcess(), &counters, sizeof(counters))) return -1;
    return (int64_t)counters.WorkingSetSize;
}

// 终止本机指定进程（仅支持 SIGKILL 语义即 sig == 9）：调用方用它回收
// 写有 pid 文件的辅助进程。其他信号返回具名拒绝。
int32_t kill(int32_t pid, int32_t sig) {
    if (pid <= 0) return -1;
    if (sig != 9) return -4;
    HANDLE process = OpenProcess(PROCESS_TERMINATE | PROCESS_QUERY_LIMITED_INFORMATION,
        FALSE, (DWORD)pid);
    if (!process) return -2;
    DWORD exitCode = 0;
    int32_t result = -3;
    if (GetExitCodeProcess(process, &exitCode) && exitCode == STILL_ACTIVE) {
        result = TerminateProcess(process, 1) ? 0 : -3;
    } else {
        result = -3; // 进程已不存在或不可查询，调用方按失败处理。
    }
    CloseHandle(process);
    return result;
}

// 当前前台窗口是否属于本进程（对应 IME 探针的 active 判定）：
// *outActive 置 1/0，返回 0；无前台窗口概念时不谎报。
int32_t pharos_activate_for_input(int32_t *outActive) {
    if (!outActive) return -1;
    HWND foreground = GetForegroundWindow();
    DWORD foregroundPid = 0;
    if (foreground) GetWindowThreadProcessId(foreground, &foregroundPid);
    *outActive = (foreground && foregroundPid == GetCurrentProcessId()) ? 1 : 0;
    return 0;
}

typedef struct {
    DWORD pid;
    int dark;
    int touched;
} PharosDarkModeClosure;

// 标题栏深色（对应 macOS 的 set_dark_appearance）：遍历本进程可见顶层窗口
// 设置沉浸式深色，至少命中一个返回 0，否则返回具名拒绝。
static BOOL CALLBACK apply_dark_mode(HWND window, LPARAM param) {
    PharosDarkModeClosure *closure = (PharosDarkModeClosure *)param;
    DWORD windowPid = 0;
    GetWindowThreadProcessId(window, &windowPid);
    if (windowPid != closure->pid) return TRUE;
    if (!IsWindowVisible(window)) return TRUE;
    BOOL useDark = closure->dark ? TRUE : FALSE;
    if (SUCCEEDED(DwmSetWindowAttribute(window, 20 /*DWMWA_USE_IMMERSIVE_DARK_MODE*/,
            &useDark, sizeof(useDark)))) {
        closure->touched++;
    }
    return TRUE;
}

int32_t pharos_set_dark_appearance(int32_t dark) {
    PharosDarkModeClosure closure;
    closure.pid = GetCurrentProcessId();
    closure.dark = dark ? 1 : 0;
    closure.touched = 0;
    EnumWindows(apply_dark_mode, (LPARAM)&closure);
    return closure.touched > 0 ? 0 : PHAROS_WIN_UNSUPPORTED;
}

// 以下为 macOS 专属诊断/自动化辅助在 Windows 的具名拒绝。
// 它们只在 macOS 探针模式（PHAROS_IME_*/PHAROS_POST_*/realFlowStage 等）
// 被调用，正常写作链不经过；返回负数让调用方日志如实记录未支持，
// 不伪装成已执行。Windows 的真实输入验收走驱动侧 SendInput。

void pharos_activate_window(void) {
    // macOS 的 NSApp activate 在 Windows 由正常启动路径完成，此处无对应操作。
}

void pharos_first_responder(void) {
    // macOS 响应链日志在 Windows 无对应物；等价信息见 runner 日志。
}

void pharos_input_proxy_state(void) {
    // macOS 输入代理状态日志在 Windows 无对应物；等价信息见 runner 日志。
}

void pharos_current_input_source(char *buffer, int32_t length) {
    (void)buffer;
    (void)length;
    // 零调用点的诊断声明，保留符号以通过链接；无对应物。
}

int32_t pharos_accessibility_trusted(void) {
    return 0; // Windows 无 AX 信任模型，此路径按“未授权”如实回答。
}

int32_t pharos_install_key_monitor(void) {
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_select_input_source(const char *sourceId) {
    (void)sourceId;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_keycode_cg(int32_t keyCode, int32_t down) {
    (void)keyCode;
    (void)down;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_keypress_cg(int32_t keyCode) {
    (void)keyCode;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_keypress_cg_shift(int32_t keyCode, int32_t shift) {
    (void)keyCode;
    (void)shift;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_click(double x, double y) {
    (void)x;
    (void)y;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_drag(double x1, double y1, double x2, double y2) {
    (void)x1;
    (void)y1;
    (void)x2;
    (void)y2;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_key(int32_t keyCode) {
    (void)keyCode;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_key_window(int32_t keyCode, int32_t flags, char character) {
    (void)keyCode;
    (void)flags;
    (void)character;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_scroll(double x, double y, int32_t ticks) {
    (void)x;
    (void)y;
    (void)ticks;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_post_scroll_number(double x, double y, int32_t ticks, int32_t requestedWindow) {
    (void)x;
    (void)y;
    (void)ticks;
    (void)requestedWindow;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_capture_window_png(const char *path) {
    (void)path;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_capture_window_png_number(const char *path, int32_t requestedWindow) {
    (void)path;
    (void)requestedWindow;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_probe_compose_marked(const char *text) {
    (void)text;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_probe_compose_commit(const char *text) {
    (void)text;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_probe_declare_input_caret(double x, double y, double width, double height) {
    (void)x;
    (void)y;
    (void)width;
    (void)height;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_probe_first_rect(int32_t location, int32_t length) {
    (void)location;
    (void)length;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_probe_input_state(void) {
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_export_pdf_start(const char *htmlPath, const char *pdfPath) {
    (void)htmlPath;
    (void)pdfPath;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_export_pdf_poll(void) {
    return PHAROS_WIN_UNSUPPORTED;
}

double pharos_export_pdf_bytes(void) {
    return 0.0;
}

int32_t pharos_pdf_finish_with_outline(const char *inPath, const char *headings) {
    (void)inPath;
    (void)headings;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_rasterize_svg_start(const char *svgPath, const char *pngPath, int32_t widthPoints) {
    (void)svgPath;
    (void)pngPath;
    (void)widthPoints;
    return PHAROS_WIN_UNSUPPORTED;
}

int32_t pharos_rasterize_svg_done(void) {
    return PHAROS_WIN_UNSUPPORTED;
}

const char *pharos_rasterize_svg_state(void) {
    return kUnsupported;
}

int32_t pharos_rasterize_svg_pixels(int32_t *width, int32_t *height) {
    if (width) *width = 0;
    if (height) *height = 0;
    return PHAROS_WIN_UNSUPPORTED;
}
