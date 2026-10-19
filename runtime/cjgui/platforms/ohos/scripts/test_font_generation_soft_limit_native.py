#!/usr/bin/env python3
"""Keep the SDK candidate reproducible; production retains the baseline policy."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile

HOST = Path(__file__).resolve().parents[1] / 'host'
HEADER = HOST / 'cjgui_ohos_font_lease.h'

CODE = r'''
#include "cjgui_ohos_font_lease.h"
#include <cstdio>
#include <cstdlib>
#define CHECK(x, why) do { if (!(x)) { puts("FAIL " why); std::exit(1); } } while (0)
struct Collection {};
using Pool = CjguiOhosFontPool<Collection>;
int main() {
  int alive = 0, peak = 0;
  auto create = [&] { ++alive; peak = std::max(peak, alive); return new Collection; };
  auto destroy = [&](Collection *p) { --alive; delete p; };
  {
    Pool p(create, destroy, {}, 65536);
    auto old = p.acquire(60000, 1);
    auto next = p.acquire(10000, 1);
    CHECK(old && next && old->id != next->id, "soft boundary did not rotate real work");
    CHECK(p.stats().admittedUnits == 70000 && p.liveGenerations() == 2,
          "soft boundary charged synthetic work or hid a generation");
    old.reset(); CHECK(p.retireOneUnused() && alive == 1, "old owner was not explicitly retired");
    next.reset(); p.clear(); CHECK(alive == 0, "soft close leaked");
  }
  {
    Pool p(create, destroy, {}, 65536);
    auto large = p.acquire(200000, 1);
    CHECK(large && large->workUnits == 200000 && large->sealed,
          "single legal request over soft limit was refused, split, or left issuing leases");
    CHECK(!p.acquire(Pool::kWorkUnitsPerGeneration + 1, 1), "hard request limit changed");
    large.reset(); p.clear(); CHECK(alive == 0, "large request close leaked");
  }
  {
    Pool p(create, destroy, {}, 65536);
    std::vector<Pool::Lease> accepted, candidate;
    // Real A2 capacity: old 16 x 8192 plus a complete unpublished replacement.
    // Keep every old lease until all replacement nodes have been admitted.
    for (int i = 0; i < 16; ++i) {
      auto x = p.acquire(8192, 1);
      CHECK(x, "soft threshold reduced complete old frame capacity"); accepted.push_back(x);
    }
    for (int i = 0; i < 16; ++i) {
      auto x = p.acquire(8192, 1);
      CHECK(x, "soft threshold reduced A2 replacement capacity at three live generations");
      candidate.push_back(x);
    }
    CHECK(alive <= 3 && peak <= 3 && p.stats().admittedUnits == 262144,
          "capacity fallback exceeded cap or changed actual work");
    accepted.clear(); while (p.retireOneUnused()) {}
    candidate.clear(); p.clear(); CHECK(alive == 0, "A2 owner close leaked");
  }
  {
    Pool p(create, destroy); // Normal default remains baseline until fixed SDK decision.
    auto first = p.acquire(60000, 1), next = p.acquire(10000, 1);
    CHECK(first && next && first->id == next->id, "candidate was silently enabled by default");
    first.reset(); next.reset(); p.clear();
  }
  puts("PASS soft rollover, actual charges, hard request, A2 pressure fallback and baseline default");
}
'''


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--baseline-behavior', action='store_true')
    ap.add_argument('--mutation', choices=['disable-soft', 'hard-as-soft', 'seal-full-slot', 'restore-renderer-soft'])
    ap.add_argument('--renderer-wiring', action='store_true')
    ap.add_argument('--expected-renderer-soft', type=int, choices=[262144, 65536], default=262144,
                    help='65536 reproduces the historical SDK candidate; current production must use262144.')
    args = ap.parse_args()
    if args.mutation == 'restore-renderer-soft' and not args.renderer_wiring:
        ap.error('--mutation restore-renderer-soft requires --renderer-wiring')
    args.out.mkdir(parents=True, exist_ok=True)
    header = HEADER.read_text()
    if args.mutation == 'disable-soft':
        header = header.replace('softWorkUnits_(softWorkUnits)', 'softWorkUnits_(kWorkUnitsPerGeneration)')
    elif args.mutation == 'hard-as-soft':
        old = 'units > kWorkUnitsPerGeneration || retiringCount_'
        assert header.count(old) == 1
        header = header.replace(old, 'units > softWorkUnits_ || retiringCount_')
    elif args.mutation == 'seal-full-slot':
        old = 'if (liveGenerations() < kMaxGenerations) sealCurrent();'
        assert header.count(old) == 1
        header = header.replace(old, 'sealCurrent();')
        header = header.replace('liveGenerations() < kMaxGenerations) sealCurrent();', 'true) sealCurrent();')
    # Compile the unmodified old production header with its actual old constructor.
    # This is a behavioral RED, not a missing-constructor compilation failure.
    code = CODE.replace(', {}, 65536', '') if args.baseline_behavior else CODE
    if args.renderer_wiring:
        renderer = (HOST / 'ohos_renderer.cpp').read_text()
        start = renderer.index('    OhosFontPool fontPool{')
        end = renderer.index('    // Current production names an explicit family.', start)
        field = renderer[start:end]
        if args.mutation == 'restore-renderer-soft':
            assert '}, 65536}' not in field, 'This withdrawal control needs the production baseline first.'
            old = '        }};'
            assert field.count(old) == 1
            field = field.replace(old, '        }, 65536};')
        code = r'''
#include "cjgui_ohos_font_lease.h"
#include <cstdio>
#define RLOGI(...) ((void)0)
struct OH_Drawing_FontCollection {};
OH_Drawing_FontCollection *OH_Drawing_CreateSharedFontCollection() { return new OH_Drawing_FontCollection; }
void OH_Drawing_DestroyFontCollection(OH_Drawing_FontCollection *p) { delete p; }
using OhosFontPool = CjguiOhosFontPool<OH_Drawing_FontCollection>;
struct ActualRendererOwner {
''' + field + r'''
};
int main() {
  ActualRendererOwner owner;
  auto accepted = owner.fontPool.acquire(60000, 1), next = owner.fontPool.acquire(10000, 1);
  const bool experimental = @@EXPERIMENTAL@@;
  const bool applied = accepted && next && (accepted->id != next->id) == experimental &&
      owner.fontPool.stats().admittedUnits == 70000 && owner.fontPool.liveGenerations() == (experimental ? 2 : 1);
  accepted.reset(); next.reset(); owner.fontPool.clear();
  if (!applied) { puts("FAIL actual renderer policy differs from the declared baseline/candidate"); return 1; }
  puts("PASS actual renderer policy and real work/generation accounting match the declared baseline/candidate");
}
'''.replace('@@EXPERIMENTAL@@', 'true' if args.expected_renderer_soft == 65536 else 'false')
    with tempfile.TemporaryDirectory(prefix='cjgui-font-soft-') as directory:
        temp = Path(directory)
        (temp / HEADER.name).write_text(header)
        cpp = temp / 'test.cpp'
        cpp.write_text(code)
        command = ['clang++', '-std=c++17', '-pthread', str(cpp), '-o', str(temp / 'test')]
        built = subprocess.run(command, capture_output=True, text=True, timeout=30)
        ran = subprocess.run([str(temp / 'test')], capture_output=True, text=True, timeout=10) if not built.returncode else None
        record = {'header_SHA256': hashlib.sha256(header.encode()).hexdigest(),
                  'baseline_behavior': args.baseline_behavior, 'mutation': args.mutation,
                  'renderer_wiring': args.renderer_wiring, 'compile_exit': built.returncode,
                  'expected_renderer_soft': args.expected_renderer_soft if args.renderer_wiring else None,
                  'renderer_SHA256': hashlib.sha256((HOST / 'ohos_renderer.cpp').read_bytes()).hexdigest(),
                  'run_exit': ran.returncode if ran else None,
                  'stdout': ran.stdout if ran else '', 'stderr': built.stderr + (ran.stderr if ran else '')}
        (args.out / 'contract.cpp').write_text(code)
        (args.out / 'compiled-header.h').write_text(header)
        (args.out / 'result.json').write_text(json.dumps(record, indent=2) + '\n')
        print(json.dumps(record, ensure_ascii=False))
        return built.returncode or ran.returncode


if __name__ == '__main__':
    raise SystemExit(main())
