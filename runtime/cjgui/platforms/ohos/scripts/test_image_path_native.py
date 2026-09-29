#!/usr/bin/env python3
"""Exercise the renderer's real image-path admission and no-follow open."""
import pathlib
import re
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


def compile_and_run(program: str) -> None:
    with tempfile.TemporaryDirectory() as directory:
        source = pathlib.Path(directory) / "image_path.cpp"
        binary = pathlib.Path(directory) / "image_path"
        source.write_text(program)
        subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                        str(source), "-o", str(binary)], check=True)
        subprocess.run([str(binary), directory], check=True)


class ImagePathNativeTest(unittest.TestCase):
    def test_only_current_published_files_dir_and_one_png_basename(self) -> None:
        method = extract_function(SOURCE.read_text(), "static bool cjguiOhosImagePathAllowed(")
        program = r'''
#include <cstdlib>
#include <cstring>
''' + method + r'''
int main() {
  const char* root = "/data/storage/el2/base/haps/entry/files";
  if (setenv("CJGUI_IMAGE_FIXTURE_DIR", root, 1) != 0) return 1;
  if (!cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/cjgui_image_v1.png")) return 2;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/files/cjgui_image_v1.png")) return 3;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/other/files/cjgui_image_v1.png")) return 4;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/nested/icon.png")) return 5;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/../icon.png")) return 6;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/.secret.png")) return 7;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/icon.jpg")) return 8;
  if (unsetenv("CJGUI_IMAGE_FIXTURE_DIR") != 0) return 9;
  if (cjguiOhosImagePathAllowed(
          "/data/storage/el2/base/haps/entry/files/cjgui_image_v1.png")) return 10;
  return 0;
}
'''
        compile_and_run(program)

    def test_decode_open_rejects_final_symlink(self) -> None:
        source = SOURCE.read_text()
        open_call = re.search(r"int fd = (open\(path\.c_str\(\), O_RDONLY \| O_CLOEXEC \| O_NOFOLLOW\));",
                              source)
        self.assertIsNotNone(open_call)
        program = r'''
#include <fcntl.h>
#include <string>
#include <unistd.h>
int main(int argc, char** argv) {
  if (argc != 2) return 1;
  std::string regular = std::string(argv[1]) + "/image.png";
  std::string path = std::string(argv[1]) + "/link.png";
  int writable = open(regular.c_str(), O_CREAT | O_WRONLY, 0600);
  if (writable < 0) return 2;
  close(writable);
  if (symlink(regular.c_str(), path.c_str()) != 0) return 3;
  int fd = ''' + open_call.group(1) + r''';
  if (fd >= 0) { close(fd); return 4; }
  return 0;
}
'''
        compile_and_run(program)


if __name__ == "__main__":
    unittest.main()
