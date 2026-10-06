#include "cjgui_internal_renderer.h"
#include <windows.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("before_create\n");
    CjguiInternalRendererConfig config;
    memset(&config, 0, sizeof(config));
    config.windowWidth = 640;
    config.windowHeight = 480;
    config.clearColorAlpha = 1.0;
    CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t token = cjgui_internal_renderer_create(&config, &status);
    printf("create token=%llu status=%d\n", (unsigned long long)token, (int)status);
    if (token) { status = cjgui_internal_renderer_destroy(token); printf("destroy status=%d\n", (int)status); }
    printf("done\n");
    return 0;
}
