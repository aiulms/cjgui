#!/usr/bin/env python3
"""Compile the real OHOS viewport path against same-generation geometry changes."""
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


class ViewportGeometryNativeTest(unittest.TestCase):
    def test_geometry_revision_and_density_reach_viewport(self) -> None:
        source = SOURCE.read_text()
        helper = "\n".join(
            extract_function(source, signature)
            for signature in ("static int32_t physicalToLayout(",
                              "static void cjguiOhosObserveSurfaceLocked(",
                              "static void cjguiOhosRefreshSurfaceLocked(")
            if signature in source
        )
        viewport = extract_function(source,
                                    "CjguiInternalRendererStatus cjgui_internal_renderer_composable_viewport(")
        window_frame = extract_function(source,
                                        "CjguiInternalRendererStatus cjgui_internal_renderer_window_frame(")
        program = r'''
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <mutex>
#define RLOGI(...) ((void)0)
enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INVALID_SESSION = 1,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 2
};
struct CjguiInternalRendererViewport {
  uint32_t width = 0, height = 0;
  uint64_t resizeVersion = 0, resourceCompletionVersion = 0;
};
struct Session {
  uint64_t surfaceGeneration = 0, surfaceGeometryRevision = 0;
  uint64_t surfaceResizeVersion = 0, imageCompletionVersion = 0, loggedResizeVersion = 0;
  int32_t surfaceWidth = 0, surfaceHeight = 0;
  double surfaceDensity = 1.0;
  bool surfaceSeen = false;
};
struct { std::mutex lock; } g_sessions;
Session session;
Session* lookupSessionLocked(uint64_t token) { return token == 1 ? &session : nullptr; }
struct Ingress {
  int (*surfaceActive)(void**, uint64_t*, int32_t*, int32_t*, double*, uint64_t*);
} g_ingress;
struct Fact { uint64_t generation, geometry; int32_t width, height; double density; };
Fact fact{7, 2, 720, 1400, 1.0};
int surfaceActive(void**, uint64_t* generation, int32_t* width, int32_t* height,
                  double* density, uint64_t* geometry) {
  *generation = fact.generation; *width = fact.width; *height = fact.height;
  *density = fact.density; if (geometry) *geometry = fact.geometry;
  return 1;
}
''' + helper + "\n" + viewport + "\n" + window_frame + r'''
int main() {
  g_ingress.surfaceActive = surfaceActive;
  CjguiInternalRendererViewport first{}, resized{}, recreated{}, density{};
  if (cjgui_internal_renderer_composable_viewport(1, &first) != CJGUI_INTERNAL_RENDERER_OK ||
      first.width != 720 || first.height != 1400 || first.resizeVersion < 2) return 1;
  // Device R1: host publishes geo 2->3 under the same generation.
  fact = {7, 3, 360, 700, 1.0};
  int64_t fx = -1, fy = -1, fw = -1, fh = -1;
  if (cjgui_internal_renderer_window_frame(1, &fx, &fy, &fw, &fh) != CJGUI_INTERNAL_RENDERER_OK ||
      fx != 0 || fy != 0 || fw != 360 || fh != 700) return 2;
  if (cjgui_internal_renderer_composable_viewport(1, &resized) != CJGUI_INTERNAL_RENDERER_OK ||
      resized.width != 360 || resized.height != 700 ||
      resized.resizeVersion <= first.resizeVersion) return 3;
  // Surface recreation must also invalidate the viewport at the same size.
  fact = {8, 4, 360, 700, 1.0};
  if (cjgui_internal_renderer_composable_viewport(1, &recreated) != CJGUI_INTERNAL_RENDERER_OK ||
      recreated.resizeVersion <= resized.resizeVersion) return 4;
  // A density change remains observable even if a host omits a new geo id.
  fact = {8, 4, 360, 700, 2.0};
  if (cjgui_internal_renderer_composable_viewport(1, &density) != CJGUI_INTERNAL_RENDERER_OK ||
      density.resizeVersion <= recreated.resizeVersion) return 5;
  // 布局单位是 vp：物理 px 按绑定密度折算（720px / 3 = 240vp，1400/3 四舍五入 467）。
  fact = {9, 5, 720, 1400, 3.0};
  CjguiInternalRendererViewport vp{};
  if (cjgui_internal_renderer_composable_viewport(1, &vp) != CJGUI_INTERNAL_RENDERER_OK ||
      vp.width != 240 || vp.height != 467) return 6;
  int64_t vx = -1, vy = -1, vw = -1, vh = -1;
  if (cjgui_internal_renderer_window_frame(1, &vx, &vy, &vw, &vh) != CJGUI_INTERNAL_RENDERER_OK ||
      vx != 0 || vy != 0 || vw != 240 || vh != 467) return 7;
  // 密度回 1.0：同一物理尺寸恢复 1:1（负控：折算不是常量除法）。
  fact = {9, 6, 720, 1400, 1.0};
  if (cjgui_internal_renderer_composable_viewport(1, &vp) != CJGUI_INTERNAL_RENDERER_OK ||
      vp.width != 720 || vp.height != 1400) return 8;
  return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            cpp = pathlib.Path(directory) / "viewport.cpp"
            binary = pathlib.Path(directory) / "viewport"
            cpp.write_text(program)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(cpp), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
