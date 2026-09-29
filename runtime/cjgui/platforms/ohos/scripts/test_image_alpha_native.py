#!/usr/bin/env python3
"""Compile the renderer's UNKNOWN-alpha inference against exact pixel cases."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def extract_function(source: str, signature: str) -> str:
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for index in range(opening, len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[start:index + 1]
    raise ValueError("unterminated function")


class ImageAlphaNativeTest(unittest.TestCase):
    def test_unknown_alpha_witness_and_conversion(self) -> None:
        text = SOURCE.read_text()
        infer = extract_function(text, "static bool cjguiOhosUnknownAlphaNeedsPremultiply(")
        premultiply = extract_function(text, "static void cjguiOhosPremultiplyBgra(")
        program = r'''
#include <cstddef>
#include <cstdint>
''' + infer + "\n" + premultiply + r'''
int main() {
  uint32_t x = 99, y = 99;
  // settings v1 (24,0): source RGBA=(17,132,173,120); device BGRA is
  // (81,62,8,120), so a second multiply would darken the accepted image.
  uint8_t premul[8] = {81, 62, 8, 120, 7, 7, 7, 7};
  if (cjguiOhosUnknownAlphaNeedsPremultiply(premul, 1, 1, 8, &x, &y)) return 1;
  if (x != 99 || y != 99) return 2;
  cjguiOhosPremultiplyBgra(premul, 1, 1, 8);
  if (premul[0] != 38) return 3;  // Caller must skip conversion for this case.

  uint8_t raw[8] = {173, 132, 17, 120, 7, 7, 7, 7};
  if (!cjguiOhosUnknownAlphaNeedsPremultiply(raw, 1, 1, 8, &x, &y) || x != 0 || y != 0) return 4;
  cjguiOhosPremultiplyBgra(raw, 1, 1, 8);
  if (raw[0] != 81 || raw[1] != 62 || raw[2] != 8 || raw[3] != 120 || raw[4] != 7) return 5;

  uint8_t v2Premul[4] = {55, 21, 83, 120};
  uint8_t v2Raw[4] = {117, 44, 176, 120};
  if (cjguiOhosUnknownAlphaNeedsPremultiply(v2Premul, 1, 1, 4, &x, &y)) return 6;
  if (!cjguiOhosUnknownAlphaNeedsPremultiply(v2Raw, 1, 1, 4, &x, &y)) return 7;

  // Transparent nonzero channels prove straight-alpha data; row padding is
  // not a pixel and must not create a false witness.
  uint8_t rows[16] = {20, 30, 40, 120, 255, 255, 255, 255,
                      4, 5, 6, 0,       255, 255, 255, 255};
  if (!cjguiOhosUnknownAlphaNeedsPremultiply(rows, 1, 2, 8, &x, &y) || x != 0 || y != 1) return 8;
  cjguiOhosPremultiplyBgra(rows, 1, 2, 8);
  if (rows[0] != 9 || rows[1] != 14 || rows[2] != 19 ||
      rows[8] != 0 || rows[9] != 0 || rows[10] != 0 || rows[12] != 255) return 9;

  uint8_t opaque[4] = {255, 128, 0, 255};
  if (cjguiOhosUnknownAlphaNeedsPremultiply(opaque, 1, 1, 4, &x, &y)) return 10;
  // This dark straight-alpha pixel is genuinely ambiguous without an exact
  // source-pixel contract; the current SDK policy keeps it as premultiplied.
  uint8_t ambiguous[4] = {20, 30, 40, 120};
  if (cjguiOhosUnknownAlphaNeedsPremultiply(ambiguous, 1, 1, 4, &x, &y)) return 11;
  return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "image_alpha.cpp"
            binary = pathlib.Path(directory) / "image_alpha"
            source.write_text(program)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(source), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
