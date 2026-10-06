#define COBJMACROS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <objbase.h>
#include <wincodec.h>
#include <stdint.h>
#include <limits.h>
#include <string.h>

#include "cjgui_windows_wic.h"

static uint32_t read_be32(const uint8_t *value) {
    return ((uint32_t)value[0] << 24) | ((uint32_t)value[1] << 16) |
        ((uint32_t)value[2] << 8) | (uint32_t)value[3];
}

static int has_png_ihdr(const uint8_t *bytes, uint64_t length,
    uint32_t *width, uint32_t *height) {
    static const uint8_t signature[8] = { 137, 80, 78, 71, 13, 10, 26, 10 };
    if (bytes == NULL || length < 33 || memcmp(bytes, signature, sizeof(signature)) != 0 ||
        read_be32(bytes + 8) != 13 || memcmp(bytes + 12, "IHDR", 4) != 0) {
        return 0;
    }
    *width = read_be32(bytes + 16);
    *height = read_be32(bytes + 20);
    return *width > 0 && *height > 0;
}

int32_t cjgui_windows_wic_decode_png_rgba8(
    const uint8_t *png_bytes,
    uint64_t png_length,
    uint64_t maximum_encoded_bytes,
    uint32_t maximum_width,
    uint32_t maximum_height,
    uint64_t maximum_decoded_bytes,
    uint8_t *output_rgba,
    uint64_t output_capacity,
    uint32_t *output_width,
    uint32_t *output_height,
    uint64_t *output_bytes) {
    uint32_t width = 0;
    uint32_t height = 0;
    uint64_t decoded_bytes = 0;
    HRESULT hr;
    int owns_com_initialization = 0;
    IWICImagingFactory *factory = NULL;
    IWICStream *stream = NULL;
    IWICBitmapDecoder *decoder = NULL;
    IWICBitmapFrameDecode *frame = NULL;
    IWICFormatConverter *converter = NULL;
    int32_t result = CJGUI_WINDOWS_WIC_DECODE_FAILED;

    if (output_width == NULL || output_height == NULL || output_bytes == NULL) {
        return CJGUI_WINDOWS_WIC_INVALID_PNG;
    }
    *output_width = 0;
    *output_height = 0;
    *output_bytes = 0;

    if (!has_png_ihdr(png_bytes, png_length, &width, &height)) {
        return CJGUI_WINDOWS_WIC_INVALID_PNG;
    }
    *output_width = width;
    *output_height = height;
    if (png_length > maximum_encoded_bytes || png_length > UINT_MAX) {
        return CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED;
    }
    if (width > maximum_width || height > maximum_height) {
        return CJGUI_WINDOWS_WIC_DIMENSION_EXCEEDED;
    }
    if ((uint64_t)width > UINT64_MAX / (uint64_t)height / 4u) {
        return CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED;
    }
    decoded_bytes = (uint64_t)width * (uint64_t)height * 4u;
    if (decoded_bytes > maximum_decoded_bytes) {
        return CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED;
    }
    if (output_rgba == NULL || decoded_bytes > output_capacity || decoded_bytes > UINT_MAX ||
        width > UINT_MAX / 4u) {
        return CJGUI_WINDOWS_WIC_OUTPUT_TOO_SMALL;
    }
    *output_bytes = decoded_bytes;

    hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    if (SUCCEEDED(hr)) {
        owns_com_initialization = 1;
    } else if (hr != RPC_E_CHANGED_MODE) {
        goto cleanup;
    }

    hr = CoCreateInstance(&CLSID_WICImagingFactory, NULL, CLSCTX_INPROC_SERVER,
        &IID_IWICImagingFactory, (void **)&factory);
    if (FAILED(hr)) goto cleanup;
    hr = IWICImagingFactory_CreateStream(factory, &stream);
    if (FAILED(hr)) goto cleanup;
    hr = IWICStream_InitializeFromMemory(stream, (BYTE *)png_bytes, (DWORD)png_length);
    if (FAILED(hr)) goto cleanup;
    hr = IWICImagingFactory_CreateDecoderFromStream(factory, (IStream *)stream, NULL,
        WICDecodeMetadataCacheOnDemand, &decoder);
    if (FAILED(hr)) goto cleanup;
    hr = IWICBitmapDecoder_GetFrame(decoder, 0, &frame);
    if (FAILED(hr)) goto cleanup;

    {
        UINT decoded_width = 0;
        UINT decoded_height = 0;
        hr = IWICBitmapSource_GetSize((IWICBitmapSource *)frame, &decoded_width, &decoded_height);
        if (FAILED(hr) || decoded_width != width || decoded_height != height) goto cleanup;
    }

    hr = IWICImagingFactory_CreateFormatConverter(factory, &converter);
    if (FAILED(hr)) goto cleanup;
    hr = IWICFormatConverter_Initialize(converter, (IWICBitmapSource *)frame,
        &GUID_WICPixelFormat32bppRGBA, WICBitmapDitherTypeNone, NULL, 0.0,
        WICBitmapPaletteTypeCustom);
    if (FAILED(hr)) goto cleanup;
    hr = IWICBitmapSource_CopyPixels((IWICBitmapSource *)converter, NULL, width * 4u,
        (UINT)decoded_bytes, output_rgba);
    if (FAILED(hr)) goto cleanup;
    result = CJGUI_WINDOWS_WIC_OK;

cleanup:
    if (converter != NULL) IWICFormatConverter_Release(converter);
    if (frame != NULL) IWICBitmapFrameDecode_Release(frame);
    if (decoder != NULL) IWICBitmapDecoder_Release(decoder);
    if (stream != NULL) IWICStream_Release(stream);
    if (factory != NULL) IWICImagingFactory_Release(factory);
    if (owns_com_initialization) CoUninitialize();
    if (result != CJGUI_WINDOWS_WIC_OK) *output_bytes = 0;
    return result;
}
