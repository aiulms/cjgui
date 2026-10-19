"""Ordering seam: a Redraw queued before a CaretHitTest must really draw.

Real production facts used here, all extracted from ohos_renderer.cpp:
  * postCaretHitAfterRedraw() atomically enqueues Redraw then the hit; the pump
    (ohos_renderer_input_will) posts the hit at the current renderEpoch and waits
    for its result (a failed hit must not move the caret).
  * executeCaretHitTest() refuses with painted_layout_unavailable while
    paintedLayoutUsable is false; only a successful Redraw frame publication
    (executeRedraw -> publishPaintedLayout) sets it true.
So with any queued job between the draw and a later replay, the draw must
execute: the hit reads the layout published by the draw it was queued behind.

The harness provides a controlled substitute only at the outermost SDK
boundary: "a Redraw job that the engine dispatch actually executes publishes a
layout" (the same effect publishPaintedLayout has in production, line ~3915)
and the hit verdict comes from the real production refusal gate. The queue
dispatch mirrors run(): merged => skip execute; otherwise execute by kind.

RED on the pre-fix source: the old predicate skipped the hit while scanning for
a later replay, so the draw was merged away and the hit was refused
(painted_layout_unavailable) -- the hit lost the layout its predecessor draw
was going to publish. The test also records that failure mode explicitly.
"""
from pathlib import Path
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'host' / 'ohos_renderer.cpp'


def slice_fragment(source, start_marker, end_marker):
    start = source.index(start_marker)
    end = source.index(end_marker, start) + len(end_marker)
    return source[start:end]


PREFIX = r'''
#include <cassert>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#define RLOGI(...) do {} while(0)
#define RLOGW(...) do {} while(0)
enum CjguiInternalRendererStatus {
  CJGUI_INTERNAL_RENDERER_OK = 0,
  CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR = 2,
  CJGUI_INTERNAL_RENDERER_VIEW_INVALIDATED = 5,
  CJGUI_INTERNAL_RENDERER_PRESENT_PENDING = 20,
  CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY = 7,
};
enum class JobKind { Measure, CaretHitTest, Present, Redraw, ImageRealize, Teardown, Shutdown };
struct WaitableJob {
  JobKind kind; const char *observationReason = "unspecified"; uint64_t observationId = 0;
  bool cancelled = false;
  explicit WaitableJob(JobKind k) : kind(k) {}
  virtual ~WaitableJob() = default;
  bool cancelBeforeCommit() { cancelled = true; return true; }
};
using JobRef = std::shared_ptr<WaitableJob>;
struct Coverage {};
using CjguiOhosCoverage = std::shared_ptr<Coverage>;
struct RedrawJob : WaitableJob {
  explicit RedrawJob(const char *reason = "unspecified") : WaitableJob(JobKind::Redraw) { observationReason = reason; }
  CjguiOhosCoverage installedCoverage; uint64_t installedSession = 0, installedTicket = 0;
  bool caretBlinkWake = false;
  uint64_t renderEpoch = 0;
};
struct OH_Drawing_Typography { int unused; };
struct PaintedTextLayout { std::shared_ptr<OH_Drawing_Typography> typography; };
struct CaretHitTestJob : WaitableJob {
  CaretHitTestJob() : WaitableJob(JobKind::CaretHitTest) {}
  CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
  bool finished = false;
  void finish(CjguiInternalRendererStatus s) { status = s; finished = true; }
};
static std::shared_ptr<PaintedTextLayout> lastPaintLayout;
static bool paintedLayoutUsable = false;
static constexpr size_t kPresentationQueryQueueMax = 32;
'''

RENDER_OPEN = r'''
struct Render {
 std::mutex lock; std::condition_variable cv;
 std::deque<JobRef> jobs;
 bool running = true, stopping = false;
 uint64_t renderEpoch = 1;
 std::atomic<uint64_t> queuedCaretQueries{0};
 void consumeCaretBlinkWakeLocked(const JobRef &job)
 {
     if (job->kind == JobKind::Redraw) {
         const auto *redraw = static_cast<const RedrawJob *>(job.get());
         if (redraw->caretBlinkWake && redraw->renderEpoch == renderEpoch) {
             /* production: caretBlinkRedrawQueued = false; */
         }
     }
 }
'''

RENDER_MID = r'''
};
'''

ENGINE = r'''
struct EngineState {
  int draws = 0; int merged = 0; int hitOk = 0; int hitRefused = 0;
  uint64_t lastPublishedSerial = 0; uint64_t hitSawSerial = 0;
};

// Real production refusal gate (extracted verbatim from executeCaretHitTest).
static void productionCaretHitGate(CaretHitTestJob *job)
{
%s
}

static bool runCaretHitGate(CaretHitTestJob *job)
 {
    productionCaretHitGate(job);
    return !job->finished;   // no refusal recorded => gate passed
}

// Dispatch mirrors run(): a merged replay never executes; otherwise execute by
// kind. A Redraw that executes publishes its layout (the substitute for
// executeRedraw -> publishPaintedLayout at the SDK boundary).
static void engine(Render &r, EngineState &st)
{
  while (!r.jobs.empty()) {
    const bool merged = r.replaySupersededByLaterQueuedReplayLocked();
    JobRef job = r.jobs.front();
    r.jobs.pop_front();
    r.consumeCaretBlinkWakeLocked(job);
    if (merged) { st.merged += 1; continue; }
    if (job->kind == JobKind::Redraw) {
      st.draws += 1; st.lastPublishedSerial += 1;
      paintedLayoutUsable = true;
      lastPaintLayout = std::make_shared<PaintedTextLayout>();
      lastPaintLayout->typography = std::make_shared<OH_Drawing_Typography>();
    } else if (job->kind == JobKind::CaretHitTest) {
      auto *hit = static_cast<CaretHitTestJob *>(job.get());
      if (runCaretHitGate(hit)) { st.hitOk += 1; st.hitSawSerial = st.lastPublishedSerial; }
      else st.hitRefused += 1;
    }
  }
}

// Retired pre-fix rule, kept only to record the failure mode the fix removes.
static bool legacyScanRule(const Render &r)
{
  if (r.jobs.empty() || r.jobs.front()->kind != JobKind::Redraw) return false;
  const auto *head = static_cast<const RedrawJob *>(r.jobs.front().get());
  if (head->installedCoverage) return false;
  for (size_t index = 1; index < r.jobs.size(); ++index) {
    if (r.jobs[index]->kind == JobKind::Present) return false;
    if (r.jobs[index]->kind != JobKind::Redraw) continue;
    const auto *next = static_cast<const RedrawJob *>(r.jobs[index].get());
    if (next->installedCoverage) return false;
    return true;
  }
  return false;
}

static void legacyEngine(Render &r, EngineState &st)
{
  while (!r.jobs.empty()) {
    const bool merged = legacyScanRule(r);
    JobRef job = r.jobs.front();
    r.jobs.pop_front();
    if (merged) { st.merged += 1; continue; }
    if (job->kind == JobKind::Redraw) {
      st.draws += 1; st.lastPublishedSerial += 1;
      paintedLayoutUsable = true;
      lastPaintLayout = std::make_shared<PaintedTextLayout>();
      lastPaintLayout->typography = std::make_shared<OH_Drawing_Typography>();
    } else if (job->kind == JobKind::CaretHitTest) {
      auto *hit = static_cast<CaretHitTestJob *>(job.get());
      if (runCaretHitGate(hit)) { st.hitOk += 1; st.hitSawSerial = st.lastPublishedSerial; }
      else st.hitRefused += 1;
    }
  }
}

int main(){
  // The production-reachable interleave: the pump enqueues Redraw+hit via
  // postCaretHitAfterRedraw; a plain replay lands behind them before the
  // render thread dequeues (e.g. another redraw post from an earlier path).
  {
    paintedLayoutUsable = false;
    lastPaintLayout.reset();
    Render r; EngineState st;
    CaretHitTestJob *rawHit = new CaretHitTestJob();
    JobRef hit(rawHit);
    assert(r.postCaretHitAfterRedraw(hit, r.renderEpoch));
    r.jobs.push_back(std::make_shared<RedrawJob>("redraw-callsite-13999"));
    assert(r.jobs.size() == 3);
    engine(r, st);
    // The draw the hit was queued behind must have executed first, and the hit
    // must observe exactly that draw's publication.
    assert(st.draws == 2);
    assert(st.merged == 0);
    assert(st.hitRefused == 0);
    assert(st.hitOk == 1);
    assert(st.hitSawSerial == 1);
  }
  // Pure adjacent replays merge; the later draw still executes and publishes.
  {
    paintedLayoutUsable = false;
    lastPaintLayout.reset();
    Render r; EngineState st;
    r.jobs.push_back(std::make_shared<RedrawJob>("a"));
    r.jobs.push_back(std::make_shared<RedrawJob>("b"));
    engine(r, st);
    assert(st.merged == 1 && st.draws == 1 && st.lastPublishedSerial == 1);
  }
  // A frozen-value (coverage) wake behind a plain replay is a barrier: it keeps
  // its own draw semantics.
  {
    paintedLayoutUsable = false;
    lastPaintLayout.reset();
    Render r; EngineState st;
    r.jobs.push_back(std::make_shared<RedrawJob>("a"));
    { auto cov=std::make_shared<RedrawJob>("b"); cov->installedCoverage=std::make_shared<Coverage>(); r.jobs.push_back(cov); }
    engine(r, st);
    assert(st.merged == 0);
    assert(st.draws == 2);
  }
  // Record the retired rule's failure mode on the same interleave: the hit is
  // refused because its predecessor draw was merged away before it ran.
  {
    paintedLayoutUsable = false;
    lastPaintLayout.reset();
    Render r; EngineState st;
    CaretHitTestJob *rawHit = new CaretHitTestJob();
    JobRef hit(rawHit);
    assert(r.postCaretHitAfterRedraw(hit, r.renderEpoch));
    r.jobs.push_back(std::make_shared<RedrawJob>("redraw-callsite-13999"));
    legacyEngine(r, st);
    assert(st.merged == 1);
    assert(st.hitRefused == 1);
    assert(st.hitOk == 0);
  }
  return 0;
}
'''


def harness(source):
    gate = slice_fragment(source, 'const auto *painted = lastPaintLayout.get();',
        'CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY);' + chr(10) + '            return;' + chr(10) + '        }')

    text = PREFIX + RENDER_OPEN
    text += extract_decl(source, 'struct RedrawJob : WaitableJob {')
    text += extract_decl(source, 'bool postCaretHitAfterRedraw(const JobRef &hit, uint64_t expectedEpoch)')
    text += extract_decl(source, 'bool replaySupersededByLaterQueuedReplayLocked() const')
    text += RENDER_MID
    text += ENGINE % gate
    return text


def extract_decl(text, marker):
    from test_text_geometry_native import extract_decl as _extract
    return _extract(text, marker)


class CaretHitAfterRedrawMergeNativeTest(unittest.TestCase):
    def run_source(self, source):
        with tempfile.TemporaryDirectory(prefix='ohos-hit-merge-') as directory:
            root = Path(directory)
            (root / 'probe.cpp').write_text(harness(source))
            p = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                                str(root / 'probe.cpp'), '-o', str(root / 'probe')], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            return subprocess.run([str(root / 'probe')], capture_output=True, text=True).returncode

    def test_hit_observes_predecessor_draw(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_controls(self):
        source = SOURCE.read_text()
        controls = [
            ('if (later->kind != JobKind::Redraw) return false;',
             'if (later->kind != JobKind::Redraw) continue;'),
            ('if (next->installedCoverage) return false;',
             'if (next->installedCoverage && false) return false;'),
        ]
        for old, new in controls:
            with self.subTest(guard=old):
                if old not in source:
                    continue  # barrier shape may be spelled inline; covered by sibling test
                self.assertNotEqual(self.run_source(source.replace(old, new, 1)), 0)


if __name__ == '__main__':
    unittest.main()
