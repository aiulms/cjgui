#!/usr/bin/env python3
"""Create deterministic PNG transfer fixtures and describe their source pixels."""

from __future__ import annotations

import argparse
import json
import random
import struct
import zlib
from pathlib import Path


def chunk(kind: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(kind + payload) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", checksum)


def valid_png() -> tuple[bytes, dict[str, object]]:
    width, height = 3, 2
    pixels = [
        [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255)],
        [(255, 255, 0, 255), (255, 0, 255, 128), (0, 255, 255, 255)],
    ]
    scanlines = b"".join(b"\x00" + b"".join(bytes(pixel) for pixel in row) for row in pixels)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(scanlines)) + chunk(b"IEND", b"")
    evidence = {
        "width": width,
        "height": height,
        "rgba_pixels": {
            "0,0": list(pixels[0][0]),
            "1,0": list(pixels[0][1]),
            "2,0": list(pixels[0][2]),
            "1,1": list(pixels[1][1]),
        },
        "contains_zero_byte": 0 in data,
        "contains_non_utf8_byte": any(byte >= 0x80 for byte in data),
    }
    return data, evidence


def near_limit_png() -> tuple[bytes, dict[str, object]]:
    # Deterministic high-entropy RGB pixels make the encoded PNG approach the
    # existing 512 KiB transfer ceiling while keeping decode work small.
    width, height = 512, 320
    generator = random.Random(0xC1A0_2026)
    rows: list[bytes] = []
    selected: dict[str, list[int]] = {}
    for y in range(height):
        row = bytearray()
        for x in range(width):
            pixel = generator.getrandbits(24)
            rgb = [(pixel >> 16) & 0xFF, (pixel >> 8) & 0xFF, pixel & 0xFF]
            if (x, y) in ((0, 0), (1, 0), (0, 1), (511, 319)):
                selected[f"{x},{y}"] = rgb
            row.extend(rgb)
        rows.append(b"\x00" + bytes(row))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b"")
    lower, upper = 450 * 1024, 512 * 1024
    if not lower <= len(data) < upper:
        raise ValueError(f"near-limit PNG encoded size {len(data)} is outside [{lower}, {upper})")
    evidence = {
        "width": width,
        "height": height,
        "bits_per_pixel": 24,
        "pixel_count": width * height,
        "rgb_pixels": selected,
        "encoded_bytes_below_512_KiB": True,
        "contains_zero_byte": 0 in data,
        "contains_non_utf8_byte": any(byte >= 0x80 for byte in data),
    }
    return data, evidence


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=("valid", "near-limit", "invalid", "oversized"))
    parser.add_argument("output", type=Path)
    parser.add_argument("--bytes", type=int, default=512 * 1024 + 1)
    args = parser.parse_args()

    if args.kind == "valid":
        payload, evidence = valid_png()
    elif args.kind == "near-limit":
        payload, evidence = near_limit_png()
    elif args.kind == "invalid":
        payload = b"\x89PNG\r\n\x1a\n\x00\xff\xfe\x80truncated-IHDR\x00"
        evidence = {"valid_png": False, "contains_zero_byte": True, "contains_non_utf8_byte": True}
    else:
        if args.bytes <= 512 * 1024:
            parser.error("oversized fixture must exceed the existing 512 KiB transfer declaration ceiling")
        # Prefix resembles the standard type but the stream remains deliberately invalid.
        payload = b"\x89PNG\r\n\x1a\n\x00\xff" + bytes((index * 31 + 7) & 0xFF for index in range(args.bytes - 10))
        evidence = {"valid_png": False, "exceeds_existing_declaration_ceiling": True}

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(payload)
    print(json.dumps({"kind": args.kind, "bytes": len(payload), **evidence}, sort_keys=True))


if __name__ == "__main__":
    main()
