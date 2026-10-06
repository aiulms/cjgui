#include <stdio.h>
#include <string.h>
#include "cjgui_internal_renderer.h"

CjguiInternalRendererStatus cjgui_internal_renderer_grapheme_cluster_range(
    const char *utf8, uint64_t declaredLength, uint64_t offsetByte,
    uint64_t *outStartByte, uint64_t *outEndByte);
CjguiInternalRendererStatus cjgui_internal_renderer_composed_prefix_utf8_length(
    const char *utf8, uint64_t inputBytes, uint64_t maxOutputBytes,
    uint64_t maxClusters, uint8_t inputComplete, uint64_t *outPrefixBytes);

static int expect_cluster(const char *name, const char *text, uint64_t offset,
    uint64_t expectedStart, uint64_t expectedEnd) {
    uint64_t start = 0u, end = 0u;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_grapheme_cluster_range(
        text, (uint64_t)strlen(text), offset, &start, &end);
    if (status != CJGUI_INTERNAL_RENDERER_OK || start != expectedStart || end != expectedEnd) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL %s status=%d range=[%llu,%llu)\n",
            name, status, (unsigned long long)start, (unsigned long long)end);
        return 1;
    }
    return 0;
}

int main(void) {
    static const char combining[] = "Ae\xcc\x81" "B";
    static const char family[] =
        "A\xf0\x9f\x91\xa8\xe2\x80\x8d\xf0\x9f\x91\xa9"
        "\xe2\x80\x8d\xf0\x9f\x91\xa7\xe2\x80\x8d\xf0\x9f\x91\xa6" "B";
    static const char crlf[] = "A\r\nB";
    if (expect_cluster("combining_scalar_start", combining, 2u, 1u, 4u) ||
        expect_cluster("combining_scalar_middle", combining, 3u, 1u, 4u) ||
        expect_cluster("zwj_family_member", family, 9u, 1u, 26u) ||
        expect_cluster("crlf", crlf, 2u, 1u, 3u)) return 1;

    uint64_t start = 0u, end = 0u;
    CjguiInternalRendererStatus status = cjgui_internal_renderer_grapheme_cluster_range(
        combining, (uint64_t)strlen(combining), (uint64_t)strlen(combining), &start, &end);
    if (status != CJGUI_INTERNAL_RENDERER_GRAPHEME_BOUNDARY_INVALID) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL past_end status=%d\n", status); return 1;
    }
    const char invalid[] = {(char)0xff, 0};
    status = cjgui_internal_renderer_grapheme_cluster_range(invalid, 1u, 0u, &start, &end);
    if (status != CJGUI_INTERNAL_RENDERER_INVALID_UTF8) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL invalid_utf8 status=%d\n", status); return 1;
    }

    uint64_t prefix = 0u;
    status = cjgui_internal_renderer_composed_prefix_utf8_length(
        combining, (uint64_t)strlen(combining), 2u, 10u, 1u, &prefix);
    if (status != CJGUI_INTERNAL_RENDERER_OK || prefix != 1u) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL max_bytes status=%d prefix=%llu\n",
            status, (unsigned long long)prefix); return 1;
    }
    status = cjgui_internal_renderer_composed_prefix_utf8_length(
        combining, (uint64_t)strlen(combining), 32u, 2u, 1u, &prefix);
    if (status != CJGUI_INTERNAL_RENDERER_OK || prefix != 4u) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL max_clusters status=%d prefix=%llu\n",
            status, (unsigned long long)prefix); return 1;
    }
    status = cjgui_internal_renderer_composed_prefix_utf8_length(
        combining, (uint64_t)strlen(combining), 32u, 10u, 0u, &prefix);
    if (status != CJGUI_INTERNAL_RENDERER_OK || prefix != 4u) {
        fprintf(stderr, "GRAPHEME_CONTRACT FAIL incomplete_scan status=%d prefix=%llu\n",
            status, (unsigned long long)prefix); return 1;
    }
    puts("CJGUI_WINDOWS_GRAPHEME_CONTRACT PASS combining=1:4 family=1:26 crlf=1:3 prefix_bytes=1 prefix_clusters=4 incomplete=4 invalid_utf8=22 past_end=24");
    return 0;
}
