"""Execute the production owner-pump wait boundary with a controlled event FIFO.

Only the surrounding SDK/Session fixture and deadline are substituted.  The
wait block, event-queue field and (when present) queue notification mechanism
are extracted verbatim from ohos_renderer.cpp.  A 500ms host-only deadline
makes event-before-deadline ordering distinguishable without claiming device
latency.  No native input/selection/owner verdict is simulated by this test.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


SOURCE = Path(__file__).resolve().parents[1] / "host" / "ohos_renderer.cpp"


def wait_block(source):
    start = source.index("CjguiInternalRendererStatus cjgui_internal_renderer_pump_event(")
    start = source.index("    if (s->events.empty()) {", start)
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


PREFIX = r'''
#include <chrono>
#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <future>
#include <iostream>
#include <mutex>
#include <thread>
#include <utility>
#include <time.h>
using namespace std::chrono_literals;
constexpr auto kPumpWaitMax = 500ms; // valid tv_nsec, controlled deadline, not production pacing
constexpr int CJGUI_INTERNAL_RENDERER_INVALID_SESSION = -7;
'''


FIXTURE = r'''
struct QueuedEvent { unsigned kind; uint64_t original; };
struct Session {
    QUEUE_FIELD
};
struct { std::mutex lock; Session one, two; bool liveOne = true; } g_sessions;
std::atomic<unsigned> drained{0};
Session *lookupSessionLocked(uint64_t token) {
    return token == 1 ? (g_sessions.liveOne ? &g_sessions.one : nullptr) : token == 2 ? &g_sessions.two : nullptr;
}
int pumpWait(uint64_t session, uint32_t timeoutMs, std::promise<void> *entered = nullptr) {
    std::unique_lock<std::mutex> g(g_sessions.lock);
    Session *s = lookupSessionLocked(session);
    if (!s) return CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
    auto drainTouches = [] { ++drained; }; // SDK ingress boundary, no synthetic input
    if (entered) entered->set_value(); // still under the production Session mutex
    WAIT_BLOCK
    if (!s->events.empty()) {
        const auto event = s->events.front(); s->events.pop_front();
        return event.kind == 66 && event.original == 171 ? 1 : -9;
    }
    return 0;
}
void push(uint64_t token, bool move = true) {
    std::lock_guard<std::mutex> g(g_sessions.lock);
    const QueuedEvent event{66,171};
    if (move) lookupSessionLocked(token)->events.push_back(QueuedEvent{66,171});
    else lookupSessionLocked(token)->events.push_back(event);
}
int main() {
    bool wake = false, pending = false, unrelated = false, timeout = false;
    bool fifo = false, retired = false;
    {
        std::promise<void> entered;
        auto enteredFuture = entered.get_future();
        auto done = std::async(std::launch::async,[&] { return pumpWait(1,500,&entered); });
        enteredFuture.get(); push(1,false); // the production lvalue enqueue path
        wake = done.wait_for(150ms) == std::future_status::ready;
        wake = done.get() == 1 && wake;
    }
    {
        push(1);
        auto done = std::async(std::launch::async,[] { return pumpWait(1,500); });
        pending = done.wait_for(150ms) == std::future_status::ready;
        pending = done.get() == 1 && pending;
    }
    {
        std::promise<void> entered;
        auto enteredFuture = entered.get_future();
        auto done = std::async(std::launch::async,[&] { return pumpWait(1,500,&entered); });
        enteredFuture.get(); push(2);
        const bool stillWaiting = done.wait_for(80ms) == std::future_status::timeout;
        push(1);
        unrelated = stillWaiting && done.wait_for(150ms) == std::future_status::ready;
        unrelated = done.get() == 1 && unrelated;
        std::lock_guard<std::mutex> g(g_sessions.lock);
        unrelated = unrelated && g_sessions.two.events.size() == 1;
        g_sessions.two.events.clear();
    }
    {
        auto start = std::chrono::steady_clock::now();
        const int result = pumpWait(1,40);
        const auto beforeDrain = drained.load();
        const int zero = pumpWait(1,0);
        timeout = result == 0 && zero == 0 && drained.load() == beforeDrain &&
            std::chrono::steady_clock::now()-start >= 35ms && beforeDrain != 0;
    }
    {
        std::lock_guard<std::mutex> g(g_sessions.lock);
        const QueuedEvent original{66,171};
        g_sessions.one.events.push_back(original);
        g_sessions.one.events.push_back(QueuedEvent{66,172});
        fifo = g_sessions.one.events.front().original == 171 &&
            g_sessions.one.events.back().original == 172;
        g_sessions.one.events.clear();
    }
    {
        std::promise<void> entered;
        auto enteredFuture = entered.get_future();
        auto done = std::async(std::launch::async,[&] { return pumpWait(1,120,&entered); });
        enteredFuture.get();
        { std::lock_guard<std::mutex> g(g_sessions.lock); g_sessions.liveOne = false; }
        push(2); // another queue's wake cannot resurrect the retired original token
        retired = done.get() == CJGUI_INTERNAL_RENDERER_INVALID_SESSION;
        { std::lock_guard<std::mutex> g(g_sessions.lock);
          g_sessions.liveOne = true; g_sessions.two.events.clear(); }
    }
    std::cout << "{\"admitted_event_wakes_before_deadline\":" << (wake?"true":"false")
        << ",\"already_pending_no_wait\":" << (pending?"true":"false")
        << ",\"unrelated_session_not_consumed\":" << (unrelated?"true":"false")
        << ",\"empty_queue_preserves_deadline\":" << (timeout?"true":"false")
        << ",\"payload_FIFO_unchanged\":" << (fifo?"true":"false")
        << ",\"retired_token_not_reused\":" << (retired?"true":"false") << "}\n";
    if (!wake) std::cerr << "owner pump ignored admitted event until its idle deadline\n";
    return wake && pending && unrelated && timeout && fifo && retired ? 0 : 17;
}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--mutation", choices=["omit-notification", "ignore-ready-predicate"])
    args = parser.parse_args()
    source = args.source.read_text()
    original_sha256 = hashlib.sha256(source.encode()).hexdigest()
    if args.mutation == "omit-notification":
        needle = "if (wasEmpty) g_ownerEventReady.notify_all();"
        if source.count(needle) != 2:
            raise ValueError("two production notification paths required")
        source = source.replace(needle, "/* notification withdrawn */")
    elif args.mutation == "ignore-ready-predicate":
        needle = "return !current || !current->events.empty();"
        if source.count(needle) != 1:
            raise ValueError("production readiness predicate required")
        source = source.replace(needle, "return false; /* readiness withdrawn */")
    queue = re.search(r"^    ([^\n;]+<QueuedEvent> events;)$", source, re.M)
    if not queue:
        raise ValueError("production Session FIFO field not found")
    helper = ""
    if "// BEGIN OWNER EVENT READINESS" in source:
        helper = source.split("// BEGIN OWNER EVENT READINESS", 1)[1].split(
            "// END OWNER EVENT READINESS", 1)[0]
    code = PREFIX + helper + FIXTURE.replace("QUEUE_FIELD", queue[1]).replace(
        "WAIT_BLOCK", wait_block(source))
    args.out.mkdir(parents=True, exist_ok=False)
    cpp, binary = args.out / "owner-event-wait.cpp", args.out / "owner-event-wait"
    cpp.write_text(code)
    report = {"source_sha256": hashlib.sha256(source.encode()).hexdigest(),
              "production_sha256": original_sha256, "mutation": args.mutation,
              "scope": "production pump wait and FIFO notification; controlled host deadline, not SDK latency"}
    try:
        build = subprocess.run(["clang++", "-std=c++17", "-pthread", str(cpp), "-o", str(binary)],
                               text=True, capture_output=True, timeout=45)
        (args.out / "build.log").write_text(build.stdout + build.stderr)
        report["build_exit"] = build.returncode
        if build.returncode:
            return build.returncode
        run = subprocess.run([str(binary)], text=True, capture_output=True, timeout=15)
        (args.out / "run.log").write_text(run.stdout + run.stderr)
        report.update(run_exit=run.returncode, cases=json.loads(run.stdout))
        print(json.dumps(report, indent=2))
        return run.returncode
    finally:
        # Exact owned build file, never an application binary or shared target.
        if binary.exists():
            binary.unlink()
        (args.out / "result.json").write_text(json.dumps(report, indent=2))


if __name__ == "__main__":
    raise SystemExit(main())
