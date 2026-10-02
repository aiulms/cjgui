"""Production pump phase and queue decisions; no clock or render-loop imitation.

The real HAP supplies visibility/Flush evidence. This harness isolates boundary
times, coalescing, retired epochs, and cached surface identity deterministically.
"""
from pathlib import Path
import subprocess
import tempfile
import unittest
from test_text_geometry_native import extract_decl

SOURCE = Path(__file__).resolve().parents[1] / 'host' / 'ohos_renderer.cpp'

PREFIX = r'''
#include <cassert>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
struct Session {
 bool caretBlinkVisible=false,caretBlinkActive=false,caretBlinkResetPending=false;
 int64_t caretBlinkNextMs=0;
};
enum class JobKind { Redraw, Present };
struct WaitableJob { JobKind kind; explicit WaitableJob(JobKind k):kind(k){} };
using JobRef=std::shared_ptr<WaitableJob>;
'''
RENDER = r'''
struct Render {
 std::mutex lock;std::condition_variable cv;std::deque<JobRef> jobs;
 bool running=false,stopping=false,caretBlinkRedrawQueued=false;
 uint64_t renderEpoch=0;
 bool hasLastFrame=false;void *surface=nullptr,*lastFrameWindow=nullptr,*boundWindow=nullptr;
 uint64_t lastFrameSession=0,lastFrameGeneration=0,boundGeneration=0;
'''
MAIN = r'''
int main(){
 Session s;
 assert(advanceCaretBlinkLocked(s,0,true));assert(s.caretBlinkVisible&&s.caretBlinkNextMs==500);
 assert(!advanceCaretBlinkLocked(s,499,true));assert(s.caretBlinkVisible);
 assert(advanceCaretBlinkLocked(s,500,true));assert(!s.caretBlinkVisible&&s.caretBlinkNextMs==1000);
 assert(advanceCaretBlinkLocked(s,2300,true));assert(s.caretBlinkVisible&&s.caretBlinkNextMs==2800);
 assert(!advanceCaretBlinkLocked(s,2301,true));
 s.caretBlinkResetPending=true;
 assert(advanceCaretBlinkLocked(s,2800,true));assert(s.caretBlinkVisible&&s.caretBlinkNextMs==3300);
 assert(!s.caretBlinkResetPending);
 assert(advanceCaretBlinkLocked(s,2801,false));assert(!s.caretBlinkActive&&!s.caretBlinkVisible&&s.caretBlinkNextMs==0);
 assert(!advanceCaretBlinkLocked(s,10000,false));
 assert(advanceCaretBlinkLocked(s,10001,true));assert(s.caretBlinkVisible&&s.caretBlinkNextMs==10501);
 Render r;assert(r.currentRunEpoch()==0);assert(!r.postCaretBlink(1));assert(r.jobs.empty());
 r.running=true;r.renderEpoch=1;assert(r.currentRunEpoch()==1);
 assert(!r.postCaretBlink(0));assert(!r.postCaretBlink(2));assert(r.jobs.empty());
 assert(r.postCaretBlink(1));assert(r.postCaretBlink(1));assert(r.jobs.size()==1);
 JobRef old=r.jobs.front();r.jobs.pop_front();r.consumeCaretBlinkWakeLocked(old);
 assert(!r.caretBlinkRedrawQueued);assert(r.postCaretBlink(1));assert(r.jobs.size()==1);
 // An executing wake cannot clear the newer queued wake when it completes.
 auto ordinary=std::make_shared<RedrawJob>();r.consumeCaretBlinkWakeLocked(ordinary);
 assert(r.caretBlinkRedrawQueued);r.stopping=true;
 assert(r.currentRunEpoch()==0);assert(!r.postCaretBlink(1));assert(r.jobs.size()==1);
 r.jobs.clear();r.caretBlinkRedrawQueued=false;r.stopping=false;r.renderEpoch=2;
 assert(!r.postCaretBlink(1));assert(r.postCaretBlink(2));assert(r.jobs.size()==1);
 r.consumeCaretBlinkWakeLocked(old);assert(r.caretBlinkRedrawQueued);
 r.consumeCaretBlinkWakeLocked(r.jobs.front());assert(!r.caretBlinkRedrawQueued);
 r.hasLastFrame=true;r.surface=reinterpret_cast<void*>(3);r.lastFrameSession=42;
 r.lastFrameGeneration=r.boundGeneration=7;r.lastFrameWindow=r.boundWindow=reinterpret_cast<void*>(9);
 assert(r.cachedFrameMatchesSurface());r.boundGeneration=8;assert(!r.cachedFrameMatchesSurface());
 r.boundGeneration=7;r.boundWindow=reinterpret_cast<void*>(10);assert(!r.cachedFrameMatchesSurface());
 r.boundWindow=r.lastFrameWindow;r.lastFrameSession=0;assert(!r.cachedFrameMatchesSurface());
 return 0;
}
'''


def harness(source):
    text = PREFIX + extract_decl(source, 'struct RedrawJob : WaitableJob {')
    text += extract_decl(source, 'bool advanceCaretBlinkLocked(Session &s, int64_t nowMs, bool eligible)')
    text += RENDER
    for marker in ['uint64_t currentRunEpoch()', 'bool postCaretBlink(uint64_t expectedEpoch)',
                   'void consumeCaretBlinkWakeLocked(const JobRef &job)', 'bool cachedFrameMatchesSurface() const']:
        text += extract_decl(source, marker)
    return text + '};\n' + MAIN


class CaretBlinkNativeTest(unittest.TestCase):
    def run_source(self, source):
        with tempfile.TemporaryDirectory(prefix='ohos-caret-blink-') as directory:
            root = Path(directory)
            (root / 'probe.cpp').write_text(harness(source))
            p = subprocess.run(['clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                                str(root / 'probe.cpp'), '-o', str(root / 'probe')], capture_output=True, text=True)
            self.assertEqual(p.returncode, 0, p.stderr)
            return subprocess.run([str(root / 'probe')], capture_output=True, text=True).returncode

    def test_phase_queue_and_surface_identity(self):
        self.assertEqual(self.run_source(SOURCE.read_text()), 0)

    def test_negative_controls(self):
        source = SOURCE.read_text()
        controls = [
            ('nowMs >= s.caretBlinkNextMs', 'nowMs > s.caretBlinkNextMs'),
            ('!s.caretBlinkActive || s.caretBlinkResetPending', '!s.caretBlinkActive'),
            ('expectedEpoch != renderEpoch', 'false'),
            ('if (caretBlinkRedrawQueued) return true;', 'if (false && caretBlinkRedrawQueued) return true;'),
            ('redraw->caretBlinkWake && redraw->renderEpoch == renderEpoch', 'redraw->caretBlinkWake'),
            ('lastFrameGeneration == boundGeneration', 'true'),
        ]
        for old, new in controls:
            with self.subTest(guard=old):
                self.assertIn(old, source)
                self.assertNotEqual(self.run_source(source.replace(old, new, 1)), 0)


if __name__ == '__main__':
    unittest.main()
