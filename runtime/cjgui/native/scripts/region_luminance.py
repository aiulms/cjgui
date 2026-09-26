#!/usr/bin/env python3
"""Measure the luminance distribution of a screenshot region.

`region_pixel.py` answers "what colour is this one pixel". This tool answers the
question a readability check actually asks of a whole region: does the window
really show light foreground pixels on a dark surface, and are they spread across
several separated bands (title / body / status) rather than one incidental glyph?

It decodes the PNG the platform compositor wrote (no third-party libraries) and
prints one line per statement:

    IMAGE width=<w> height=<h> channels=<n>
    GLOBAL pixels=<n> dark_fraction=<f> bright_pixels=<n> bright_fraction=<f> \
max_luminance=<f> mean_luminance=<f>
    BANDS bands=<n> populated=<n> counts=<c0,c1,...>

`bright` defaults to 0.5 relative luminance (WCAG 2.x), `dark` to 0.15. The
measurement is an observation of the captured image, never a value the
application reported about itself.

Usage:
  region_luminance.py <png> [--crop x,y,w,h] [--bands N] [--bright F] [--dark F]
"""
import struct
import sys
import zlib

_CHANNELS = {0: 1, 2: 3, 4: 2, 6: 4}


def _linear(value: float) -> float:
    if value <= 0.03928:
        return value / 12.92
    return ((value + 0.055) / 1.055) ** 2.4


def _luminance(r: int, g: int, b: int) -> float:
    return (0.2126 * _linear(r / 255.0) + 0.7152 * _linear(g / 255.0) +
            0.0722 * _linear(b / 255.0))


def read_pixels(path: str):
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit("not a PNG file")
    pos = 8
    idat = bytearray()
    width = height = bit_depth = color_type = None
    while pos + 8 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", chunk[:10])
        elif kind == b"IDAT":
            idat += chunk
        elif kind == b"IEND":
            break
    if bit_depth != 8 or color_type not in _CHANNELS:
        raise SystemExit(f"unsupported PNG (depth={bit_depth} color={color_type})")
    raw = zlib.decompress(bytes(idat))
    bpp = _CHANNELS[color_type]
    stride = width * bpp
    previous = bytearray(stride)
    rows = []
    offset = 0
    for _ in range(height):
        filt = raw[offset]
        offset += 1
        row = bytearray(raw[offset:offset + stride])
        offset += stride
        if filt == 1:
            for i in range(bpp, stride):
                row[i] = (row[i] + row[i - bpp]) & 0xFF
        elif filt == 2:
            for i in range(stride):
                row[i] = (row[i] + previous[i]) & 0xFF
        elif filt == 3:
            for i in range(stride):
                left = row[i - bpp] if i >= bpp else 0
                row[i] = (row[i] + ((left + previous[i]) >> 1)) & 0xFF
        elif filt == 4:
            for i in range(stride):
                a = row[i - bpp] if i >= bpp else 0
                b = previous[i]
                c = previous[i - bpp] if i >= bpp else 0
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                predictor = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                row[i] = (row[i] + predictor) & 0xFF
        previous = row
        rows.append(row)
    return width, height, bpp, rows


def main(argv):
    if len(argv) < 2:
        raise SystemExit("usage: region_luminance.py <png> [--crop x,y,w,h] [--bands N] "
                         "[--bright F] [--dark F]")
    path = argv[1]
    crop = None
    bands = 12
    bright_level = 0.5
    dark_level = 0.15
    index = 2
    while index < len(argv):
        flag = argv[index]
        value = argv[index + 1] if index + 1 < len(argv) else ""
        if flag == "--crop":
            crop = [int(part) for part in value.split(",")]
        elif flag == "--bands":
            bands = int(value)
        elif flag == "--bright":
            bright_level = float(value)
        elif flag == "--dark":
            dark_level = float(value)
        else:
            raise SystemExit(f"unknown flag {flag}")
        index += 2

    width, height, bpp, rows = read_pixels(path)
    x0, y0, cw, ch = 0, 0, width, height
    if crop:
        x0, y0, cw, ch = crop
        if x0 < 0 or y0 < 0 or x0 + cw > width or y0 + ch > height:
            raise SystemExit(f"crop {crop} outside {width}x{height}")
    print(f"IMAGE width={width} height={height} channels={bpp}")

    pixels = 0
    dark = 0
    bright = 0
    total = 0.0
    peak = 0.0
    band_counts = [0] * bands
    band_height = max(1, ch // bands)
    for y in range(y0, y0 + ch):
        row = rows[y]
        band = min(bands - 1, (y - y0) // band_height)
        for x in range(x0, x0 + cw):
            off = x * bpp
            r, g, b = row[off], row[off + 1], row[off + 2]
            value = _luminance(r, g, b)
            pixels += 1
            total += value
            if value > peak:
                peak = value
            if value < dark_level:
                dark += 1
            if value >= bright_level:
                bright += 1
                band_counts[band] += 1
    populated = sum(1 for count in band_counts if count > 0)
    print(f"GLOBAL pixels={pixels} dark_fraction={dark / pixels:.4f} bright_pixels={bright} "
          f"bright_fraction={bright / pixels:.4f} max_luminance={peak:.4f} "
          f"mean_luminance={total / pixels:.4f}")
    print(f"BANDS bands={bands} populated={populated} "
          f"counts={','.join(str(count) for count in band_counts)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
