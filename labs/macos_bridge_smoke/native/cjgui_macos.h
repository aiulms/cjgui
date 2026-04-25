#ifndef CJGUI_MACOS_H
#define CJGUI_MACOS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum CjguiErrorCategory {
    CJGUI_ERROR_NONE = 0,
    CJGUI_ERROR_FATAL = 1,
    CJGUI_ERROR_RECOVERABLE = 2,
    CJGUI_ERROR_DEGRADED = 3
} CjguiErrorCategory;

int32_t cjgui_app_run(void);
int32_t cjgui_last_error_code(void);
int32_t cjgui_last_error_category(void);
const char *cjgui_last_error_message(void);

#ifdef __cplusplus
}
#endif

#endif
