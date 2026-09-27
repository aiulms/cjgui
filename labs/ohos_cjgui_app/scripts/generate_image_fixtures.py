#!/usr/bin/env python3
"""Generate the two applications' small, inspectable RGBA PNG resources."""

from pathlib import Path
import struct
import zlib


WIDTH = 160
HEIGHT = 96
ROOT = Path(__file__).resolve().parents[3]


def chunk(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", zlib.crc32(kind + payload))


def make_png(subject: str, version: int) -> bytes:
    if subject == "settings":
        base = (17, 132, 173) if version == 1 else (176, 44, 117)
        bright = (102, 241, 235) if version == 1 else (255, 205, 70)
    else:
        base = (194, 77, 24) if version == 1 else (22, 119, 151)
        bright = (255, 204, 102) if version == 1 else (97, 238, 197)
    rows = bytearray()
    for y in range(HEIGHT):
        rows.append(0)  # PNG filter: none
        for x in range(WIDTH):
            rounded_outside = (x < 12 and y < 12 and x + y < 12) or (
                x >= WIDTH - 12 and y < 12 and WIDTH - 1 - x + y < 12
            ) or (x < 12 and y >= HEIGHT - 12 and x + HEIGHT - 1 - y < 12) or (
                x >= WIDTH - 12 and y >= HEIGHT - 12 and
                WIDTH + HEIGHT - 2 - x - y < 12
            )
            if rounded_outside:
                rows.extend((0, 0, 0, 0))
                continue
            rgb = base
            alpha = 255
            if x < 24:
                rgb = bright
            elif 31 <= x < 127 and 13 <= y < 83:
                # Off-center, asymmetric diagonal makes fill cropping visible.
                stripe = (x - 31) // 18
                rgb = bright if ((y // 11 + stripe + version) % 3 == 0) else base
            if 127 <= x < 152 and 15 <= y < 81:
                # A visible version marker on the right edge.
                lit = (version == 1 and x < 138) or (version == 2 and x >= 138)
                rgb = bright if lit else (8, 22, 37)
            if 24 <= x < 31:
                alpha = 120
            rows.extend((*rgb, alpha))
    ihdr = struct.pack(">IIBBBBB", WIDTH, HEIGHT, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"sRGB", b"\x00") + (
        chunk(b"IDAT", zlib.compress(bytes(rows), 9)) + chunk(b"IEND", b"")
    )


def main() -> None:
    for subject, lab in (("settings", "ohos_cjgui_app"), ("thermo", "ohos_thermo_app")):
        directory = ROOT / "labs" / lab / "entry/src/main/resources/rawfile"
        directory.mkdir(parents=True, exist_ok=True)
        for version in (1, 2):
            path = directory / f"cjgui_image_v{version}.png"
            path.write_bytes(make_png(subject, version))
            print(f"{path}: {path.stat().st_size} bytes")


if __name__ == "__main__":
    main()
