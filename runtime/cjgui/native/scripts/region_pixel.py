#!/usr/bin/env python3
"""Read ONE pixel from a bounded region screenshot.

The verification driver captures a small screen region with `screencapture`
(the platform compositor's own output) and this tool decodes the PNG that was
written. It exists so a chain can correlate an ACCEPTED paint value with what the
screen actually shows, instead of inferring output from the value it wrote.

Usage: region_pixel.py <png> <x> <y>   -> prints "RRGGBB" (uppercase hex)
"""
import struct
import sys
import zlib

_CHANNELS = {0: 1, 2: 3, 4: 2, 6: 4}


def read_pixel(path: str, px: int, py: int) -> tuple:
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
    if px < 0 or py < 0 or px >= width or py >= height:
        raise SystemExit(f"pixel {px},{py} outside {width}x{height}")
    raw = zlib.decompress(bytes(idat))
    bpp = _CHANNELS[color_type]
    stride = width * bpp
    previous = bytearray(stride)
    offset = 0
    row = bytearray(stride)
    for y in range(height):
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
        if y == py:
            off = px * bpp
            return row[off], row[off + 1], row[off + 2]
    raise SystemExit("row not reached")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        raise SystemExit("usage: region_pixel.py <png> <x> <y>")
    r, g, b = read_pixel(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]))
    print(f"{r:02X}{g:02X}{b:02X}")
