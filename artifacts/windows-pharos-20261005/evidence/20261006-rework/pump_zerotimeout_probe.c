/* pump(0)/pump(1) 区分实验 harness。
 *
 * 目的（复核 B 项）：证明同一线程、CJGUI FIFO 为空、Win32 线程队列已有就绪消息时，
 *   - pump(0)：现行实现直接返回（未 PeekMessageW），消息仍留在系统队列；
 *   - pump(1)：有等待预算，搬运系统消息（WM_QUIT 被转成 APPLICATION_EXIT_REQUESTED=42）。
 * 修复后 pump(0) 也应有界搬运就绪系统消息，本 harness 的 pump0 行应出现 kind=42。
 *
 * 用法：pump_zerotimeout_probe.exe [after_fix]
 *   不带参数：打印 pump0/pump1 结果并返回 0。
 * 输出行：create / fifo_drained / pump0 kind=.. status=.. / pump1 kind=.. status=..
 */
#include "cjgui_internal_renderer.h"
#include <windows.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    CjguiInternalRendererConfig config;
    memset(&config, 0, sizeof(config));
    config.windowWidth = 640;
    config.windowHeight = 480;
    config.clearColorRed = 1.0;
    config.clearColorGreen = 1.0;
    config.clearColorBlue = 1.0;
    config.clearColorAlpha = 1.0;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = cjgui_internal_renderer_create(&config, &status);
    printf("create token=%llu status=%d\n", (unsigned long long)token, (int)status);
    if (!token) return 2;
    CjguiInternalRendererEvent ev;
    int drainedKind = -1;
    for (int i = 0; i < 8; ++i) {
        memset(&ev, 0, sizeof(ev));
        status = cjgui_internal_renderer_pump_event(token, 0, &ev);
        if (ev.kind != 0u) {
            drainedKind = (int)ev.kind;
            printf("pre_existing_event kind=%u\n", ev.kind);
        }
    }
    printf("fifo_drained pre_existing_kind=%d\n", drainedKind);
    PostQuitMessage(0);
    memset(&ev, 0, sizeof(ev));
    status = cjgui_internal_renderer_pump_event(token, 0, &ev);
    printf("pump0 kind=%u status=%d\n", ev.kind, (int)status);
    memset(&ev, 0, sizeof(ev));
    status = cjgui_internal_renderer_pump_event(token, 1, &ev);
    printf("pump1 kind=%u status=%d\n", ev.kind, (int)status);
    (void)cjgui_internal_renderer_destroy(token);
    return 0;
}
