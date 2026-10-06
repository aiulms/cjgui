/* 线程对照实验（Astra 实验组 1 的 Windows 实现）：
 * 主线程创建会话（窗口归 renderer 自持 UI 线程所有），工作线程调用 pump。
 * 旧实现应返回线程错误（NOT_MAIN_THREAD=1）；泵线程设计下应在固定 UI tid
 * 执行成功。通过窗口句柄反查泵线程 ID，再向其投递 WM_QUIT，验证任一驱动
 * 线程的后续 pump 能取到 kind=42。
 * 输出：create / pumpA / pumpB / quit / done；任意失败返回非零。
 */
#include "cjgui_internal_renderer.h"
#include <windows.h>
#include <stdio.h>
#include <string.h>

static uint64_t g_token = 0;
static DWORD g_pumpTid = 0;
static int g_fail = 0;

static DWORD WINAPI worker_main(LPVOID param) {
    (void)param;
    CjguiInternalRendererEvent ev;
    memset(&ev, 0, sizeof(ev));
    CjguiInternalRendererStatus st = cjgui_internal_renderer_pump_event(g_token, 0, &ev);
    printf("pumpB kind=%u status=%d\n", ev.kind, (int)st);
    if (st != CJGUI_INTERNAL_RENDERER_OK) g_fail = 1;
    /* 等待主线程投递的 WM_QUIT：泵线程搬运后任一驱动线程应能取到 kind=42。
       轮询代替单次长等待（泵调用方按回合推进）。 */
    int got42 = 0;
    for (int i = 0; i < 100; ++i) {
        memset(&ev, 0, sizeof(ev));
        st = cjgui_internal_renderer_pump_event(g_token, 50, &ev);
        if (st == CJGUI_INTERNAL_RENDERER_OK && ev.kind == 42u) { got42 = 1; break; }
        if (st != CJGUI_INTERNAL_RENDERER_OK) { g_fail = 1; break; }
        Sleep(30);
    }
    printf("pumpB_poll got42=%d fail=%d\n", got42, g_fail);
    if (!got42) g_fail = 1;
    return 0;
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    CjguiInternalRendererConfig config;
    memset(&config, 0, sizeof(config));
    config.windowWidth = 640;
    config.windowHeight = 480;
    config.clearColorAlpha = 1.0;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    g_token = cjgui_internal_renderer_create(&config, &status);
    printf("create token=%llu status=%d\n", (unsigned long long)g_token, (int)status);
    if (!g_token) return 2;
    HWND hwnd = FindWindowW(L"CjguiWindowsRendererWindowV1", NULL);
    if (!hwnd) {
        printf("no_window_found\n");
        return 3;
    }
    g_pumpTid = GetWindowThreadProcessId(hwnd, NULL);
    printf("window_tid=%lu\n", (unsigned long)g_pumpTid);
    if (!g_pumpTid) return 4;
    CjguiInternalRendererEvent ev;
    memset(&ev, 0, sizeof(ev));
    status = cjgui_internal_renderer_pump_event(g_token, 0, &ev);
    printf("pumpA kind=%u status=%d\n", ev.kind, (int)status);
    if (status != CJGUI_INTERNAL_RENDERER_OK) return 5;
    HANDLE worker = CreateThread(NULL, 0, worker_main, NULL, 0, NULL);
    if (!worker) return 6;
    Sleep(500);
    if (!PostThreadMessageW(g_pumpTid, WM_QUIT, 0, 0)) {
        printf("post_quit_failed=%lu\n", GetLastError());
        return 7;
    }
    WaitForSingleObject(worker, 15000);
    CloseHandle(worker);
    (void)cjgui_internal_renderer_destroy(g_token);
    printf("done fail=%d\n", g_fail);
    return g_fail ? 8 : 0;
}
