// runtime/cjgui/platforms/linux/native/cjgui_linux_font_resource.h
//
// Linux font-resource generation registry. The shared Cangjie registry owns
// key/version, duplicate declarations and retire order; this module owns the
// immutable native generation: resolved family, bounded file bytes/path and
// lease count. Text instances acquire a lease while they hold a face; a
// window/frozen job that keeps drawing keeps the generation alive after the
// application registration is retired.

#ifndef CJGUI_LINUX_FONT_RESOURCE_H
#define CJGUI_LINUX_FONT_RESOURCE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Same ABI as the macOS side. Kind 1 = system family, 2 = local font file.
// Fallback is the existing 0..3 enum. A failed declaration still returns a
// code >= 4: it is an immutable fallback generation, not an unregistered code.
int32_t cjgui_internal_renderer_font_resource_register(uint32_t kind, const char *source,
                                                       uint32_t fallback, uint32_t *outCode);
int32_t cjgui_internal_renderer_font_resource_release(uint32_t code);
int64_t cjgui_internal_renderer_font_resource_copy_family(uint32_t code, uint8_t *buffer,
                                                          uint64_t capacity);
int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *values);
uint32_t cjgui_internal_renderer_font_resource_version(void);

// Text-engine lease surface. `bytes` is borrowed and remains valid until the
// matching lease release; path is copied into the fixed buffer.
typedef struct CjguiLinuxFontResourceLease {
    uint32_t code;
    int ready;              // 0 ready, 1..4 fallback status
    uint32_t fallback;      // 0..3
    char family[4096];
    char path[4096];
    uint8_t *bytes;         // borrowed; NULL for a system-family generation
    size_t length;
    int face_index;
} CjguiLinuxFontResourceLease;

int cjgui_linux_font_resource_acquire(uint32_t code, CjguiLinuxFontResourceLease *out);
void cjgui_linux_font_resource_lease_release(uint32_t code);

// Monotonic registry revision: changes when a generation becomes resolvable,
// is released, or is retired. Text layout reuse must include this value.
uint64_t cjgui_linux_font_resource_revision(void);

// Diagnostics: active registrations, live generations, registered file bytes,
// file generations, successful registrations.
#define CJGUI_LINUX_FONT_RESOURCE_STAT_COUNT 5u

#ifdef __cplusplus
}
#endif

#endif
