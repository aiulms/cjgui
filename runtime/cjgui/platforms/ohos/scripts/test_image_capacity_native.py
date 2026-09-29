#!/usr/bin/env python3
"""Compile the renderer's real idle-trim method against a 64-entry counterexample."""
import pathlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "host" / "ohos_renderer.cpp"


def extract_method(text: str, signature: str) -> str:
    start = text.index(signature)
    opening = text.index("{", start)
    depth = 0
    for index in range(opening, len(text)):
        depth += (text[index] == "{") - (text[index] == "}")
        if depth == 0:
            return text[start:index + 1]
    raise ValueError("unterminated method")


class ImageCapacityNativeTest(unittest.TestCase):
    def test_full_table_reuses_an_idle_slot_without_dropping_active_entries(self) -> None:
        method = extract_method(SOURCE.read_text(), "void OhosImageDomain::trimIdleLocked(")
        harness = r'''
#include <cstdint>
#include <map>
#include <memory>
#include <vector>
constexpr size_t kImageMaxRecords = 64;
constexpr size_t kImageIdleBytes = 16u * 1024u * 1024u;
struct Decoded { std::vector<uint8_t> pixels; };
struct Entry {
  std::shared_ptr<Decoded> decoded;
  size_t reservation = 0;
  uint64_t lastUse = 0;
};
using OhosImageRef = std::shared_ptr<Entry>;
struct OhosImageDomain {
  std::map<int, OhosImageRef> entries;
  std::map<int, int> bindings;
  void trimIdleLocked(std::vector<OhosImageRef>* retired, bool reserveAdmissionSlot);
};
''' + method + r'''
int main() {
  OhosImageDomain domain;
  std::vector<OhosImageRef> active;
  for (int i = 0; i < 64; ++i) {
    auto entry = std::make_shared<Entry>();
    entry->lastUse = static_cast<uint64_t>(i);
    entry->decoded = std::make_shared<Decoded>();
    entry->decoded->pixels.resize(1);
    domain.entries.emplace(i, entry);
    domain.bindings.emplace(i, i);
    if (i != 0) active.push_back(entry);
  }
  std::vector<OhosImageRef> retired;
  domain.trimIdleLocked(&retired, true);
  if (domain.entries.size() != 63 || domain.bindings.size() != 63 ||
      retired.size() != 1 || domain.entries.count(0) != 0 ||
      domain.bindings.count(0) != 0) return 1;
  for (int i = 1; i < 64; ++i) {
    if (domain.entries.count(i) != 1) return 2;
  }
  domain.entries.emplace(64, std::make_shared<Entry>());
  return domain.entries.size() == 64 ? 0 : 3;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            source = pathlib.Path(directory) / "image_capacity.cpp"
            binary = pathlib.Path(directory) / "image_capacity"
            source.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(source), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)

    def test_released_large_images_trim_without_another_image_request(self) -> None:
        source = SOURCE.read_text()
        method = extract_method(source, "void OhosImageDomain::trimIdleLocked(")
        prune = extract_method(source, "bool OhosImageDomain::pruneReleasedIdle()")
        harness = r'''
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <utility>
#include <vector>
constexpr size_t kImageMaxRecords = 64;
constexpr size_t kImageIdleBytes = 16u * 1024u * 1024u;
struct Decoded { std::vector<uint8_t> pixels; };
struct Entry {
  std::shared_ptr<Decoded> decoded;
  size_t reservation = 0;
  uint64_t lastUse = 0;
};
using OhosImageRef = std::shared_ptr<Entry>;
struct OhosImageDomain {
  std::mutex lock;
  std::map<int, OhosImageRef> entries;
  std::map<int, int> bindings;
  void trimIdleLocked(std::vector<OhosImageRef>* retired, bool reserveAdmissionSlot);
  bool pruneReleasedIdle();
};
''' + method + prune + r'''
int main() {
  OhosImageDomain domain;
  OhosImageRef accepted;
  for (int i = 0; i < 3; ++i) {
    auto entry = std::make_shared<Entry>();
    entry->lastUse = static_cast<uint64_t>(i);
    entry->decoded = std::make_shared<Decoded>();
    entry->decoded->pixels.resize(12u * 1024u * 1024u);
    domain.entries.emplace(i, entry);
    domain.bindings.emplace(i, i);
    if (i == 2) accepted = entry;
  }
  // The preceding scene has already released its first two image references.
  // There is no fourth image request to opportunistically run admission trim.
  if (!domain.pruneReleasedIdle()) return 1;
  size_t idleBytes = 0;
  for (const auto& pair : domain.entries) {
    if (pair.second.use_count() == 1) idleBytes += pair.second->decoded->pixels.size();
  }
  if (idleBytes > kImageIdleBytes) return 2;
  if (domain.entries.count(2) != 1 || domain.entries.at(2) != accepted) return 3;
  if (domain.entries.size() != 2 || domain.bindings.size() != 2) return 4;
  return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "image_idle.cpp"
            binary = pathlib.Path(directory) / "image_idle"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)

        sync = extract_method(source,
            "CjguiInternalRendererStatus cjgui_internal_renderer_present_composable_scene(")
        pending = extract_method(source,
            "CjguiInternalRendererStatus cjgui_internal_renderer_query_present(")
        configure = extract_method(source,
            "CjguiInternalRendererStatus cjgui_internal_renderer_configure_composable_scene(")
        replace = extract_method(source,
            "CjguiInternalRendererStatus cjgui_internal_renderer_set_composable_scene_node(")
        destroy = extract_method(source,
            "CjguiInternalRendererStatus cjgui_internal_renderer_destroy(")
        owner_prune = extract_method(source, "void cjguiOhosPruneReleasedImages()\n{")
        renderer_prune = extract_method(source,
            "void cjguiOhosRequestImageBitmapPrune()\n{")
        self.assertIn("nodes.clear();", sync)
        self.assertIn("cjguiOhosPruneReleasedImages()", sync)
        self.assertIn("cjguiOhosPruneReleasedImages()", pending)
        for release in (configure, replace, destroy):
            self.assertIn("cjguiOhosPruneReleasedImages()", release)
        self.assertIn("cjguiOhosRequestImageBitmapPrune()", owner_prune)
        self.assertIn("requestImagePrune()", renderer_prune)
        self.assertNotIn("RedrawJob", owner_prune)

    def test_admission_eviction_wakes_after_retirement_refs_die(self) -> None:
        source = SOURCE.read_text()
        guard = extract_method(source, "struct OhosImageRetirementWake")
        access = extract_method(source, "CjguiInternalRendererStatus OhosImageDomain::access(")
        self.assertIn("OhosImageRetirementWake retirement;", access)
        self.assertIn("trimIdleLocked(&retirement.retired, true)", access)
        harness = r'''
#include <memory>
#include <vector>
struct Entry {};
using OhosImageRef = std::shared_ptr<Entry>;
std::weak_ptr<Entry> watched;
int wakes = 0;
void cjguiOhosRequestImageBitmapPrune();
''' + guard + r''';
void cjguiOhosRequestImageBitmapPrune() {
  if (watched.expired()) ++wakes;
}
int main() {
  {
    OhosImageRetirementWake retirement;
    auto entry = std::make_shared<Entry>();
    watched = entry;
    retirement.retired.push_back(entry);
    entry.reset();
    // A failed capacity return exits this same scope without a new render job.
  }
  if (wakes != 1) return 1;
  { OhosImageRetirementWake empty; }
  return wakes == 1 ? 0 : 2;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "image_retirement.cpp"
            binary = pathlib.Path(directory) / "image_retirement"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


    def test_observation_table_converges_across_retired_entry_rotations(self) -> None:
        source = SOURCE.read_text()
        valid = extract_method(source, "bool OhosImageDomain::validLocked(")
        reconcile = extract_method(source, "static bool reconcileAcceptedImagesLocked(")
        harness = r'''
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>
struct Entry {
  uint64_t id = 0;
  uint64_t epoch = 1;
  std::string key;
  uint64_t version = 0;
  uint32_t state = 0;
  uint64_t completionSerial = 0;
  uint64_t lastUse = 0;
};
using OhosImageRef = std::shared_ptr<Entry>;
struct SceneNode { OhosImageRef image; };
struct Session {
  std::vector<SceneNode> accepted;
  std::map<uint64_t, uint64_t> imageObservedSerial;
  uint64_t imageCompletionVersion = 0;
};
struct OhosImageDomain {
  std::mutex lock;
  std::map<std::pair<std::string, uint64_t>, OhosImageRef> entries;
  uint64_t epoch = 1;
  uint64_t nextEntryId = 1;
  uint64_t accessClock = 0;
  bool validLocked(const OhosImageRef &entry) const;
  OhosImageRef admit(const std::string& key, uint64_t version, uint64_t serial) {
    auto identity = std::make_pair(key, version);
    if (entries.find(identity) == entries.end()) {
      if (entries.size() >= 64) {
        auto victim = entries.end();
        for (auto it = entries.begin(); it != entries.end(); ++it) {
          if (it->second.use_count() != 1) continue;
          if (victim == entries.end() || it->second->lastUse < victim->second->lastUse) victim = it;
        }
        if (victim != entries.end()) entries.erase(victim);
      }
      auto entry = std::make_shared<Entry>();
      entry->id = nextEntryId++;
      entry->epoch = epoch;
      entry->key = key;
      entry->version = version;
      entries.emplace(identity, entry);
    }
    OhosImageRef entry = entries[identity];
    entry->lastUse = ++accessClock;
    entry->state = 2;
    entry->completionSerial = serial;
    return entry;
  }
};
static OhosImageDomain g_images;
''' + valid + reconcile + r'''
int main() {
  Session session;
  uint64_t serial = 0;
  auto show = [&](const std::string& key) {
    OhosImageRef entry = g_images.admit(key, 1, ++serial);
    session.accepted.clear();
    SceneNode node;
    node.image = entry;
    session.accepted.push_back(node);
    reconcileAcceptedImagesLocked(&session);
    if (g_images.entries.size() > 64) return false;
    return true;
  };
  for (int round = 0; round < 2; ++round) {
    for (int i = 0; i < 65; ++i) {
      if (!show("img" + std::to_string(i))) return 1;
    }
    if (session.imageObservedSerial.size() > 65) return 2;
  }
  size_t converged = session.imageObservedSerial.size();
  for (int i = 0; i < 65; ++i) {
    if (!show("img" + std::to_string(i))) return 3;
  }
  // 第二轮全部是全新 entry 身份；观察表必须收敛而不是逐轮增大。
  if (session.imageObservedSerial.size() != converged) return 4;
  for (const auto& pair : session.imageObservedSerial) {
    bool live = false;
    for (const auto& candidate : g_images.entries) {
      if (candidate.second->id == pair.first) { live = true; break; }
    }
    if (!live) return 5;
  }
  // 同资源多节点去重：两个 accepted 节点引用同一 entry 只推进一次。
  OhosImageRef shared = g_images.admit("shared", 1, ++serial);
  uint64_t before = session.imageCompletionVersion;
  session.accepted.clear();
  for (int i = 0; i < 2; ++i) {
    SceneNode node;
    node.image = shared;
    session.accepted.push_back(node);
  }
  if (!reconcileAcceptedImagesLocked(&session)) return 6;
  if (session.imageCompletionVersion != before + 1) return 7;
  if (reconcileAcceptedImagesLocked(&session)) return 8;
  // 存活但暂不在 accepted 的 entry 保留记录：再次显示不重复完成通知。
  OhosImageRef cached = g_images.admit("cached", 1, ++serial);
  session.accepted.clear();
  { SceneNode node; node.image = cached; session.accepted.push_back(node); }
  reconcileAcceptedImagesLocked(&session);
  before = session.imageCompletionVersion;
  session.accepted.clear();
  { SceneNode node; node.image = shared; session.accepted.push_back(node); }
  reconcileAcceptedImagesLocked(&session);
  session.accepted.clear();
  { SceneNode node; node.image = cached; session.accepted.push_back(node); }
  if (reconcileAcceptedImagesLocked(&session)) return 9;
  if (session.imageCompletionVersion != before) return 10;
  session.imageObservedSerial.clear();
  return session.imageObservedSerial.empty() ? 0 : 11;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "image_observed.cpp"
            binary = pathlib.Path(directory) / "image_observed"
            path.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(path), "-o", str(binary)], check=True)
            subprocess.run([str(binary)], check=True)


if __name__ == "__main__":
    unittest.main()
