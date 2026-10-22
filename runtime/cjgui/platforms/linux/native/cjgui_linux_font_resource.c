// runtime/cjgui/platforms/linux/native/cjgui_linux_font_resource.c
//
// Linux font-resource generations. Registration resolves a system family or a
// bounded local font file once; text instances lease the immutable generation
// while they hold a face. Retiring the application reference only drops the
// registration ref: a window/frozen layout that still has a lease keeps the
// bytes and family alive until the last lease ends.

#define _GNU_SOURCE
#include "cjgui_linux_font_resource.h"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/stat.h>
#include <unistd.h>

#include <fontconfig/fontconfig.h>
#include <ft2build.h>
#include FT_FREETYPE_H

#define FR_MAX_ACTIVE 128
#define FR_MAX_GENERATIONS 256
#define FR_MAX_FILE_BYTES (16u * 1024u * 1024u)
#define FR_MAX_TOTAL_BYTES (32u * 1024u * 1024u)
#define FR_MAX_FAMILY 4096

typedef struct FontGeneration {
    int used;
    int active;
    int refs;
    int status;          // 0 ready, 1..4 explicit fallback
    uint32_t code;
    uint32_t fallback;
    char *family;
    char *path;
    uint8_t *bytes;
    size_t length;
    int face_index;
} FontGeneration;

static FontGeneration g_generations[FR_MAX_GENERATIONS];
static pthread_mutex_t g_lock = PTHREAD_MUTEX_INITIALIZER;
static uint32_t g_next_code = 4u;
static uint64_t g_registrations = 0u;
static uint64_t g_file_generations = 0u;
static uint64_t g_live_bytes = 0u;
// Bumped whenever a generation becomes resolvable or disappears. The text
// engine folds this into its layout-reuse key so a version switch cannot keep
// drawing with the previous generation's prepared faces.
static uint64_t g_revision = 1u;

static const char *fr_fallback_family(uint32_t fallback) {
    return (fallback == 1u || fallback == 3u) ? "monospace" : "sans-serif";
}

static int fr_generic_family(const char *family) {
    return strcasecmp(family, "sans-serif") == 0 || strcasecmp(family, "serif") == 0 ||
           strcasecmp(family, "monospace") == 0 || strcasecmp(family, "system-ui") == 0 ||
           strcasecmp(family, "cursive") == 0 || strcasecmp(family, "fantasy") == 0;
}

// Resolve a requested family through fontconfig. We deliberately reject a
// silent substitution of an unrelated family: a missing declaration becomes a
// named fallback generation instead of pretending the requested font loaded.
static int fr_resolve_system(const char *family, char **out_path, char **out_family,
                             int *out_index) {
    *out_path = NULL;
    *out_family = NULL;
    *out_index = 0;
    FcPattern *pat = FcPatternCreate();
    if (!pat) return 4;
    FcPatternAddString(pat, FC_FAMILY, (const FcChar8 *)family);
    FcPatternAddInteger(pat, FC_WEIGHT, FC_WEIGHT_REGULAR);
    FcPatternAddInteger(pat, FC_SLANT, FC_SLANT_ROMAN);
    FcConfigSubstitute(NULL, pat, FcMatchPattern);
    FcDefaultSubstitute(pat);
    FcResult result = FcResultNoMatch;
    FcFontSet *set = FcFontSort(NULL, pat, FcTrue, NULL, &result);
    FcPatternDestroy(pat);
    if (!set || set->nfont == 0) {
        if (set) FcFontSetDestroy(set);
        return 1;
    }
    const int generic = fr_generic_family(family);
    int chosen = -1;
    for (int i = 0; i < set->nfont; i++) {
        FcChar8 *matched = NULL;
        if (FcPatternGetString(set->fonts[i], FC_FAMILY, 0, &matched) != FcResultMatch || !matched)
            continue;
        if (generic || strcasecmp((const char *)matched, family) == 0) {
            chosen = i;
            break;
        }
    }
    if (chosen < 0) {
        FcFontSetDestroy(set);
        return 1;
    }
    FcChar8 *file = NULL;
    FcChar8 *matched = NULL;
    int index = 0;
    if (FcPatternGetString(set->fonts[chosen], FC_FILE, 0, &file) != FcResultMatch || !file) {
        FcFontSetDestroy(set);
        return 1;
    }
    (void)FcPatternGetInteger(set->fonts[chosen], FC_INDEX, 0, &index);
    (void)FcPatternGetString(set->fonts[chosen], FC_FAMILY, 0, &matched);
    char *path_copy = strdup((const char *)file);
    char *family_copy = strdup(matched && matched[0] ? (const char *)matched : family);
    FcFontSetDestroy(set);
    if (!path_copy || !family_copy || strlen(family_copy) >= FR_MAX_FAMILY) {
        free(path_copy);
        free(family_copy);
        return 4;
    }
    *out_path = path_copy;
    *out_family = family_copy;
    *out_index = index;
    return 0;
}

// Bounded single read. The file is validated through FreeType before it is
// published; a bad or changing file never leaves a half-valid generation.
static int fr_read_font_file(const char *path, uint8_t **out_bytes, size_t *out_length,
                             char **out_family) {
    *out_bytes = NULL;
    *out_length = 0;
    *out_family = NULL;
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return 2;
    struct stat before;
    if (fstat(fd, &before) != 0 || !S_ISREG(before.st_mode) || before.st_size <= 0) {
        close(fd);
        return 2;
    }
    if ((uint64_t)before.st_size > FR_MAX_FILE_BYTES) {
        close(fd);
        return 4;
    }
    uint8_t *bytes = (uint8_t *)malloc((size_t)before.st_size);
    if (!bytes) {
        close(fd);
        return 4;
    }
    size_t offset = 0u;
    while (offset < (size_t)before.st_size) {
        ssize_t count = read(fd, bytes + offset, (size_t)before.st_size - offset);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) {
            free(bytes);
            close(fd);
            return 2;
        }
        offset += (size_t)count;
    }
    struct stat after;
    if (fstat(fd, &after) != 0 || after.st_size != before.st_size ||
        after.st_ino != before.st_ino || after.st_dev != before.st_dev) {
        free(bytes);
        close(fd);
        return 2;
    }
    close(fd);

    FT_Library library = NULL;
    FT_Face face = NULL;
    if (FT_Init_FreeType(&library) != 0) {
        free(bytes);
        return 3;
    }
    if (FT_New_Memory_Face(library, bytes, (FT_Long)offset, 0, &face) != 0 || !face) {
        FT_Done_FreeType(library);
        free(bytes);
        return 3;
    }
    const char *family = face->family_name;
    char *family_copy = (family && family[0] && strlen(family) < FR_MAX_FAMILY) ? strdup(family) : NULL;
    FT_Done_Face(face);
    FT_Done_FreeType(library);
    if (!family_copy) {
        free(bytes);
        return 3;
    }
    *out_bytes = bytes;
    *out_length = offset;
    *out_family = family_copy;
    return 0;
}

static void fr_free_generation(FontGeneration *generation) {
    if (!generation) return;
    free(generation->family);
    free(generation->path);
    free(generation->bytes);
    memset(generation, 0, sizeof(*generation));
}

static FontGeneration *fr_find_locked(uint32_t code) {
    for (uint32_t i = 0u; i < FR_MAX_GENERATIONS; i++) {
        if (g_generations[i].used && g_generations[i].code == code) return &g_generations[i];
    }
    return NULL;
}

int32_t cjgui_internal_renderer_font_resource_register(uint32_t kind, const char *source,
                                                       uint32_t fallback, uint32_t *outCode) {
    if (!outCode || !source || !source[0] || strlen(source) >= FR_MAX_FAMILY ||
        (kind != 1u && kind != 2u) || fallback > 3u || !FcInit()) {
        return -1;
    }
    *outCode = 0u;

    char *family = NULL;
    char *path = NULL;
    uint8_t *bytes = NULL;
    size_t length = 0u;
    int face_index = 0;
    int status = (kind == 1u) ? fr_resolve_system(source, &path, &family, &face_index)
                              : fr_read_font_file(source, &bytes, &length, &family);
    if (status != 0) {
        free(family);
        free(path);
        free(bytes);
        family = strdup(fr_fallback_family(fallback));
        path = NULL;
        bytes = NULL;
        length = 0u;
        face_index = 0;
        if (!family) return -1;
    } else if (kind == 2u) {
        path = strdup(source);
    }
    if (!family) {
        free(path);
        free(bytes);
        return -1;
    }
    if (strlen(family) >= FR_MAX_FAMILY) {
        free(family);
        free(path);
        free(bytes);
        return -1;
    }

    pthread_mutex_lock(&g_lock);
    uint32_t active = 0u;
    for (uint32_t i = 0u; i < FR_MAX_GENERATIONS; i++) {
        if (g_generations[i].used && g_generations[i].active) active += 1u;
    }
    if (active >= FR_MAX_ACTIVE) status = 4;
    if (status == 0 && bytes && g_live_bytes + length > FR_MAX_TOTAL_BYTES) status = 4;
    if (status == 4) {
        free(bytes);
        bytes = NULL;
        length = 0u;
        free(path);
        path = NULL;
        free(family);
        family = strdup(fr_fallback_family(fallback));
        if (!family) {
            pthread_mutex_unlock(&g_lock);
            return -1;
        }
    }
    FontGeneration *slot = NULL;
    for (uint32_t i = 0u; i < FR_MAX_GENERATIONS; i++) {
        if (!g_generations[i].used) {
            slot = &g_generations[i];
            break;
        }
    }
    if (!slot || g_next_code == UINT32_MAX) {
        pthread_mutex_unlock(&g_lock);
        free(family);
        free(path);
        free(bytes);
        return -1;
    }
    uint32_t code = g_next_code++;
    memset(slot, 0, sizeof(*slot));
    slot->used = 1;
    slot->active = 1;
    slot->refs = 1;
    slot->status = status;
    slot->code = code;
    slot->fallback = fallback;
    slot->family = family;
    slot->path = path;
    slot->bytes = bytes;
    slot->length = length;
    slot->face_index = face_index;
    g_registrations += 1u;
    if (bytes) g_file_generations += 1u;
    g_live_bytes += length;
    g_revision += 1u;
    pthread_mutex_unlock(&g_lock);

    *outCode = code;
    if (getenv("CJGUI_LINUX_FONT_TRACE")) {
        fprintf(stderr, "CJGUI_FONT_RESOURCE register code=%u kind=%u status=%d bytes=%zu family=%s\n",
                code, kind, status, length, slot->family ? slot->family : "");
    }
    return status;
}

int32_t cjgui_internal_renderer_font_resource_release(uint32_t code) {
    if (code < 4u) return -1;
    pthread_mutex_lock(&g_lock);
    FontGeneration *generation = fr_find_locked(code);
    if (!generation || generation->refs <= 0) {
        pthread_mutex_unlock(&g_lock);
        return -1;
    }
    generation->active = 0;
    generation->refs -= 1;
    if (generation->refs == 0) {
        g_live_bytes -= generation->length;
        fr_free_generation(generation);
        g_revision += 1u;
    }
    pthread_mutex_unlock(&g_lock);
    if (getenv("CJGUI_LINUX_FONT_TRACE")) {
        fprintf(stderr, "CJGUI_FONT_RESOURCE release code=%u\n", code);
    }
    return 0;
}

int64_t cjgui_internal_renderer_font_resource_copy_family(uint32_t code, uint8_t *buffer,
                                                          uint64_t capacity) {
    if (!buffer || capacity == 0u || code < 4u) return -1;
    pthread_mutex_lock(&g_lock);
    FontGeneration *generation = fr_find_locked(code);
    if (!generation || generation->refs <= 0 || !generation->family) {
        pthread_mutex_unlock(&g_lock);
        return -1;
    }
    size_t length = strlen(generation->family);
    if (length > capacity) {
        pthread_mutex_unlock(&g_lock);
        return -1;
    }
    memcpy(buffer, generation->family, length);
    pthread_mutex_unlock(&g_lock);
    return (int64_t)length;
}

int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *values) {
    if (!values) return -1;
    memset(values, 0, CJGUI_LINUX_FONT_RESOURCE_STAT_COUNT * sizeof(uint64_t));
    pthread_mutex_lock(&g_lock);
    for (uint32_t i = 0u; i < FR_MAX_GENERATIONS; i++) {
        const FontGeneration *generation = &g_generations[i];
        if (!generation->used) continue;
        if (generation->active) values[0] += 1u;
        if (generation->refs > 0) values[1] += 1u;
    }
    values[2] = g_live_bytes;
    values[3] = g_file_generations;
    values[4] = g_registrations;
    pthread_mutex_unlock(&g_lock);
    return 0;
}

uint32_t cjgui_internal_renderer_font_resource_version(void) { return 1u; }

int cjgui_linux_font_resource_acquire(uint32_t code, CjguiLinuxFontResourceLease *out) {
    if (!out || code < 4u) return -1;
    memset(out, 0, sizeof(*out));
    pthread_mutex_lock(&g_lock);
    FontGeneration *generation = fr_find_locked(code);
    if (!generation || generation->refs <= 0) {
        pthread_mutex_unlock(&g_lock);
        return -1;
    }
    generation->refs += 1;
    out->code = code;
    out->ready = generation->status;
    out->fallback = generation->fallback;
    out->bytes = generation->bytes;
    out->length = generation->length;
    out->face_index = generation->face_index;
    if (generation->family) {
        size_t length = strlen(generation->family);
        if (length >= sizeof(out->family)) length = sizeof(out->family) - 1u;
        memcpy(out->family, generation->family, length);
        out->family[length] = '\0';
    }
    if (generation->path) {
        size_t length = strlen(generation->path);
        if (length >= sizeof(out->path)) length = sizeof(out->path) - 1u;
        memcpy(out->path, generation->path, length);
        out->path[length] = '\0';
    }
    pthread_mutex_unlock(&g_lock);
    return 0;
}

void cjgui_linux_font_resource_lease_release(uint32_t code) {
    if (code < 4u) return;
    pthread_mutex_lock(&g_lock);
    FontGeneration *generation = fr_find_locked(code);
    if (generation && generation->refs > 0) {
        generation->refs -= 1;
        if (generation->refs == 0) {
            g_live_bytes -= generation->length;
            fr_free_generation(generation);
            g_revision += 1u;
        }
    }
    pthread_mutex_unlock(&g_lock);
}

uint64_t cjgui_linux_font_resource_revision(void) {
    // Aligned 64-bit load: readers never hold g_lock on the text hot path.
    return g_revision;
}
