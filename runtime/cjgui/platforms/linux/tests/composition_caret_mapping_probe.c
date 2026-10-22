// Composition caret geometry probe.
//
// ibus-libpinyin 1.16.5 only reports the caret at the end of the preedit in
// this environment, so the running-window counterexample cannot produce a
// non-tail draw->caret. This probe exercises the same layout service and the
// same UTF-16 -> UTF-8 byte rule the session uses, and prints the caret
// position for a non-tail offset and for the end. A zero difference would
// mean the composition bar/spot cannot follow draw->caret.
#include "cjgui_linux_text.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

// Same rule as cjgui_linux_byte_offset_for_utf16 in cjgui_linux_session.c:
// UTF-16 units count one for BMP scalars and two for astral scalars; a caret
// inside a surrogate pair stays before the scalar.
static size_t byte_offset_for_utf16(const char *text, size_t length, uint32_t units) {
    uint32_t seen = 0u;
    size_t index = 0u;
    while (index < length && seen < units) {
        size_t start = index;
        uint32_t scalar = 0u;
        unsigned char first = (unsigned char)text[index];
        if (first < 0x80u) {
            scalar = first;
            index += 1u;
        } else if ((first & 0xE0u) == 0xC0u && index + 1u < length) {
            scalar = ((uint32_t)(first & 0x1Fu) << 6) |
                     ((uint32_t)((unsigned char)text[index + 1u] & 0x3Fu));
            index += 2u;
        } else if ((first & 0xF0u) == 0xE0u && index + 2u < length) {
            scalar = ((uint32_t)(first & 0x0Fu) << 12) |
                     ((uint32_t)((unsigned char)text[index + 1u] & 0x3Fu) << 6) |
                     ((uint32_t)((unsigned char)text[index + 2u] & 0x3Fu));
            index += 3u;
        } else if ((first & 0xF8u) == 0xF0u && index + 3u < length) {
            scalar = ((uint32_t)(first & 0x07u) << 18) |
                     ((uint32_t)((unsigned char)text[index + 1u] & 0x3Fu) << 12) |
                     ((uint32_t)((unsigned char)text[index + 2u] & 0x3Fu) << 6) |
                     ((uint32_t)((unsigned char)text[index + 3u] & 0x3Fu));
            index += 4u;
        } else {
            scalar = first;
            index += 1u;
        }
        seen += (scalar > 0xFFFFu) ? 2u : 1u;
        if (seen > units) return start;
    }
    return index;
}

static int caret_x(CjguiLinuxText *text, const char *body, uint32_t units, double *outX,
                   double *outTop, double *outLineHeight) {
    size_t length = strlen(body);
    size_t byteOffset = byte_offset_for_utf16(body, length, units);
    uint32_t lineIndex = 0u;
    size_t lineStart = 0u, lineEnd = 0u;
    double x = 0.0, top = 0.0, lineHeight = 0.0;
    int status = cjgui_linux_text_caret_position(text, body, length, 15.0, 0u, 0u, 260.0, byteOffset,
                                                 &x, &top, &lineHeight, &lineIndex, &lineStart, &lineEnd);
    if (status != CJGUI_LINUX_TEXT_OK) return status;
    *outX = x;
    *outTop = top;
    *outLineHeight = lineHeight;
    printf("units=%u byte=%zu x=%.2f top=%.2f lineHeight=%.2f line=%u start=%zu end=%zu\n", units,
           byteOffset, x, top, lineHeight, lineIndex, lineStart, lineEnd);
    return 0;
}

int main(void) {
    int status = 0;
    CjguiLinuxText *text = cjgui_linux_text_create(&status);
    if (text == NULL || status != CJGUI_LINUX_TEXT_OK) {
        fprintf(stderr, "text_create failed: %d\n", status);
        return 3;
    }
    // "邮件" is already accepted; the preedit is "你好". The non-tail caret
    // is after 你, the end caret is after 好.
    const char *body = "邮件你好";
    double nonTailX = 0.0, nonTailTop = 0.0, nonTailHeight = 0.0;
    double endX = 0.0, endTop = 0.0, endHeight = 0.0;
    if (caret_x(text, body, 3u, &nonTailX, &nonTailTop, &nonTailHeight) != 0 ||
        caret_x(text, body, 4u, &endX, &endTop, &endHeight) != 0) {
        cjgui_linux_text_destroy(text);
        return 4;
    }
    printf("NONTAIL_VS_END deltaX=%.2f deltaTop=%.2f\n", nonTailX - endX, nonTailTop - endTop);
    // Astral scalar: "😀" is two UTF-16 units and four UTF-8 bytes. A caret
    // after it must map to byte 4, not byte 2.
    const char *astral = "😀好";
    printf("ASTRAL after_emoji_byte=%zu end_byte=%zu\n", byte_offset_for_utf16(astral, strlen(astral), 2u),
           byte_offset_for_utf16(astral, strlen(astral), 3u));
    int passed = nonTailX > 0.0 && nonTailX < endX &&
                 byte_offset_for_utf16(astral, strlen(astral), 2u) == 4u &&
                 byte_offset_for_utf16(astral, strlen(astral), 3u) == 7u;
    printf("%s\n", passed ? "MAPPING_PROBE_PASS" : "MAPPING_PROBE_FAIL");
    cjgui_linux_text_destroy(text);
    return passed ? 0 : 5;
}
