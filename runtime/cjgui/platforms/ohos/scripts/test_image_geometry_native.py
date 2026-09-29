"""Compile the renderer's image geometry with host C++ and check fit/fill bounds."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


RENDERER = Path(__file__).resolve().parents[1] / "host" / "ohos_renderer.cpp"
START = "// BEGIN CJGUI OHOS IMAGE GEOMETRY"
END = "// END CJGUI OHOS IMAGE GEOMETRY"


class ImageGeometryNativeTest(unittest.TestCase):
    def test_fit_fill_and_invalid_dimensions(self):
        source = RENDERER.read_text(encoding="utf-8")
        self.assertTrue(START in source and END in source,
                        "renderer image geometry is not implemented")
        body = source.split(START, 1)[1].split(END, 1)[0]
        compiler = shutil.which("clang++")
        if not compiler:
            self.skipTest("host clang++ unavailable")
        harness = """
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
""" + body + """
static bool near(float a, float b) { return std::fabs(a - b) < 0.001f; }
int main() {
    OhosImageGeometry g{};
    if (!cjguiOhosImageGeometry(200, 100, 0, 0, 100, 100, 1, &g)) return 1;
    if (!near(g.sourceLeft, 0) || !near(g.sourceTop, 0) ||
        !near(g.sourceRight, 200) || !near(g.sourceBottom, 100) ||
        !near(g.destLeft, 0) || !near(g.destTop, 25) ||
        !near(g.destRight, 100) || !near(g.destBottom, 75)) return 2;
    if (!cjguiOhosImageGeometry(200, 100, 10, 20, 100, 100, 2, &g)) return 3;
    if (!near(g.sourceLeft, 50) || !near(g.sourceTop, 0) ||
        !near(g.sourceRight, 150) || !near(g.sourceBottom, 100) ||
        !near(g.destLeft, 10) || !near(g.destTop, 20) ||
        !near(g.destRight, 110) || !near(g.destBottom, 120)) return 4;
    if (cjguiOhosImageGeometry(0, 100, 0, 0, 100, 100, 1, &g)) return 5;
    if (cjguiOhosImageGeometry(100, 100, 0, 0, 0, 100, 1, &g)) return 6;
    return 0;
}
"""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "image_geometry.cpp"
            exe = Path(tmp) / "image_geometry"
            path.write_text(harness, encoding="utf-8")
            subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(path), "-o", str(exe)], check=True)
            subprocess.run([str(exe)], check=True)


if __name__ == "__main__":
    unittest.main()
