#!/usr/bin/env python3
"""Run the renderer's epoch and reservation methods through STOP/ABA cases."""
import pathlib
import subprocess
import tempfile
import unittest

RENDERER = pathlib.Path(__file__).resolve().parents[1] / "host" / "ohos_renderer.cpp"


def method(source: str, signature: str) -> str:
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 0
    for i in range(opening, len(source)):
        depth += (source[i] == "{") - (source[i] == "}")
        if depth == 0:
            return source[start:i + 1]
    raise ValueError(signature)


class ImageEpochNativeTest(unittest.TestCase):
    def test_stop_drops_queued_without_forgetting_running_reservation(self):
        source = RENDERER.read_text()
        methods = "\n".join(method(source, signature) for signature in (
            "bool OhosImageDomain::validLocked(",
            "void OhosImageDomain::releaseReservationLocked(",
            "void OhosImageDomain::invalidate(",
        ))
        harness = r'''
#include <cstdint>
#include <deque>
#include <map>
#include <memory>
#include <mutex>
#include <string>
#include <utility>
#include <vector>
struct Entry {
  uint64_t epoch = 0, version = 0;
  std::string key;
  size_t reservation = 0;
  bool decoding = false;
};
using OhosImageRef = std::shared_ptr<Entry>;
struct OhosImageDomain {
  std::mutex lock;
  uint64_t epoch = 1;
  std::map<std::pair<std::string,uint64_t>, std::string> bindings;
  std::map<std::pair<std::string,uint64_t>, OhosImageRef> entries;
  std::deque<OhosImageRef> pending;
  size_t outstanding = 0, reservedBytes = 0, queued = 0;
  bool validLocked(const OhosImageRef&) const;
  void releaseReservationLocked(const OhosImageRef&);
  void invalidate();
};
''' + methods + r'''
int main() {
  OhosImageDomain d;
  auto running = std::make_shared<Entry>();
  running->epoch = 1; running->version = 1; running->key = "shared";
  running->reservation = 100; running->decoding = true;
  d.entries.emplace(std::make_pair("shared", 1), running);
  auto queued = std::make_shared<Entry>();
  queued->epoch = 1; queued->version = 2; queued->key = "shared";
  queued->reservation = 100;
  d.entries.emplace(std::make_pair("shared", 2), queued);
  d.pending.push_back(queued);
  d.outstanding = 2; d.reservedBytes = 200; d.queued = 1;
  d.invalidate();
  if (d.epoch != 2 || !d.entries.empty() || !d.pending.empty() ||
      d.outstanding != 1 || d.reservedBytes != 100 || d.queued != 0) return 1;
  auto reopened = std::make_shared<Entry>();
  reopened->epoch = 2; reopened->version = 1; reopened->key = "shared";
  d.entries.emplace(std::make_pair("shared", 1), reopened);
  if (d.validLocked(running) || !d.validLocked(reopened)) return 2;
  d.releaseReservationLocked(running);
  if (d.outstanding != 0 || d.reservedBytes != 0 || !d.validLocked(reopened)) return 3;
  return 0;
}
'''
        with tempfile.TemporaryDirectory() as directory:
            cpp = pathlib.Path(directory) / "image_epoch.cpp"
            exe = pathlib.Path(directory) / "image_epoch"
            cpp.write_text(harness)
            subprocess.run(["clang++", "-std=c++17", "-Wall", "-Wextra", "-Werror",
                            str(cpp), "-o", str(exe)], check=True)
            subprocess.run([str(exe)], check=True)


if __name__ == "__main__":
    unittest.main()
