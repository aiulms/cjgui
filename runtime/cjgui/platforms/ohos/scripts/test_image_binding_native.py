#!/usr/bin/env python3
"""Exercise native image admission beyond 256 versions and held identity conflicts."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def extract_method(source: str, signature: str) -> str:
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for index in range(opening, len(source)):
        depth += (source[index] == "{") - (source[index] == "}")
        if depth == 0:
            return source[start:index + 1]
    raise ValueError("unterminated method")


class ImageBindingNativeTest(unittest.TestCase):
    def test_300_versions_reclaim_idle_binding_but_keep_held_conflict(self) -> None:
        source = SOURCE.read_text()
        release = extract_method(source, "void OhosImageDomain::releaseReservationLocked(")
        trim = extract_method(source, "void OhosImageDomain::trimIdleLocked(")
        access = extract_method(source, "CjguiInternalRendererStatus OhosImageDomain::access(")
        retirement_start = source.index("struct OhosImageRetirementWake {")
        retirement_end = source.index("\n};", retirement_start) + len("\n};")
        retirement = source[retirement_start:retirement_end]
        program = r'''
#include <algorithm>
#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>
constexpr size_t kImageMaxEncoded = 4u * 1024u * 1024u;
constexpr size_t kImageMaxDecoded = 16u * 1024u * 1024u;
constexpr size_t kImageMaxOutstanding = 8u;
constexpr size_t kImageMaxRecords = 64u;
constexpr size_t kImageMaxBindings = 256u;
constexpr size_t kImageIdleBytes = 16u * 1024u * 1024u;
constexpr size_t kImageProcessBytes = 128u * 1024u * 1024u;
std::atomic<size_t> g_imageLiveBytes{0};
std::atomic<size_t> g_pruneWakeCount{0};
void cjguiOhosRequestImageBitmapPrune() { g_pruneWakeCount.fetch_add(1); }
bool cjguiOhosImagePathAllowed(const char*) { return true; }
enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 1
};
struct Decoded { std::vector<uint8_t> pixels; };
struct OhosImageEntry {
  const uint64_t id, epoch;
  const std::string key;
  const uint64_t version;
  const std::string path;
  uint64_t attempt = 0, completionSerial = 0, lastUse = 0;
  uint32_t state = 0;
  size_t reservation = 0;
  std::string failure;
  std::shared_ptr<Decoded> decoded;
  OhosImageEntry(uint64_t i, uint64_t e, std::string k, uint64_t v, std::string p)
      : id(i), epoch(e), key(std::move(k)), version(v), path(std::move(p)) {}
};
using OhosImageRef = std::shared_ptr<OhosImageEntry>;
struct OhosImageDomain {
  std::mutex lock;
  std::condition_variable cv;
  std::thread decoder;
  bool decoderStarted = true;
  uint64_t epoch = 1, nextEntryId = 1, accessClock = 0;
  std::map<std::pair<std::string, uint64_t>, std::string> bindings;
  std::map<std::pair<std::string, uint64_t>, OhosImageRef> entries;
  std::deque<OhosImageRef> pending;
  size_t outstanding = 0, reservedBytes = 0, peakTrackedBytes = 0, queued = 0;
  uint64_t cacheHits = 0;
  void decoderLoop() {}
  void releaseReservationLocked(const OhosImageRef&);
  void trimIdleLocked(std::vector<OhosImageRef>*, bool);
  CjguiInternalRendererStatus access(const char*, const char*, uint64_t, bool, bool,
                                     OhosImageRef*, uint32_t*);
};
''' + retirement + "\n" + release + "\n" + trim + "\n" + access + r'''
int main() {
  OhosImageDomain domain;
  const char* a = "/sandbox/a.png";
  const char* b = "/sandbox/b.png";
  OhosImageRef held;
  uint32_t state = 0;
  if (domain.access(a, "held", 900, true, false, &held, &state) != CJGUI_INTERNAL_RENDERER_OK ||
      !held || state != 1) return 1;
  domain.pending.clear(); domain.queued = 0;
  domain.releaseReservationLocked(held);
  held->decoded = std::make_shared<Decoded>();
  held->decoded->pixels.resize(1);
  held->state = 2;

  for (uint64_t version = 1; version <= 300; ++version) {
    OhosImageRef transient;
    if (domain.access(a, "icon", version, true, false, &transient, &state) !=
          CJGUI_INTERNAL_RENDERER_OK || !transient || state != 1) return 2;
    domain.pending.clear(); domain.queued = 0;
    domain.releaseReservationLocked(transient);
    transient->decoded = std::make_shared<Decoded>();
    transient->decoded->pixels.resize(1);
    transient->state = 2;
    transient.reset();
  }
  if (domain.entries.size() > kImageMaxRecords || domain.bindings.size() > kImageMaxRecords ||
      domain.entries.count({"held", 900}) != 1) return 3;
  if (g_pruneWakeCount.load() == 0) return 11;
  OhosImageRef conflict;
  if (domain.access(b, "held", 900, true, false, &conflict, &state) !=
      CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR || conflict) return 4;
  held.reset();
  // Once no scene/job/queue holds it, admission pressure may reclaim the old
  // identity and its path; a later declaration can use that identity afresh.
  for (uint64_t version = 301; version <= 370; ++version) {
    OhosImageRef transient;
    if (domain.access(a, "icon", version, true, false, &transient, &state) !=
          CJGUI_INTERNAL_RENDERER_OK || !transient) return 5;
    domain.pending.clear(); domain.queued = 0;
    domain.releaseReservationLocked(transient);
    transient.reset();
  }
  if (domain.bindings.count({"held", 900}) != 0) return 6;
  if (domain.access(b, "held", 900, true, false, &conflict, &state) !=
      CJGUI_INTERNAL_RENDERER_OK || !conflict) return 7;
  domain.pending.clear(); domain.queued = 0;
  domain.releaseReservationLocked(conflict);
  conflict.reset();

  // A queued decode is another live owner even before any scene accepts it.
  OhosImageRef queued;
  if (domain.access(a, "queued", 901, true, false, &queued, &state) !=
      CJGUI_INTERNAL_RENDERER_OK || !queued) return 8;
  queued.reset();  // keep only the map plus decoder queue references
  for (uint64_t version = 371; version <= 440; ++version) {
    OhosImageRef transient;
    if (domain.access(a, "icon", version, true, false, &transient, &state) !=
          CJGUI_INTERNAL_RENDERER_OK || !transient) return 9;
    domain.pending.pop_back(); domain.queued -= 1;
    domain.releaseReservationLocked(transient);
    transient.reset();
  }
  if (domain.entries.count({"queued", 901}) != 1 ||
      domain.access(b, "queued", 901, true, false, &conflict, &state) !=
        CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR) return 10;
  return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            cpp = pathlib.Path(directory) / "image_binding.cpp"
            binary = pathlib.Path(directory) / "image_binding"
            cpp.write_text(program)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(cpp), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
