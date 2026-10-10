#!/usr/bin/env python3
"""Actual native destroy must release newly owned input/choice receipts.

The Session registry, image/fact notifications and GPU are controlled shims.
The destroy body, input/choice storage classes and renderer status ABI are
production source. Weak handles observe actual payload ownership while the
retired fixed Session slot remains alive. This is not device RSS evidence.
"""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

PLATFORM = Path(__file__).resolve().parents[1]
SOURCE = PLATFORM / "host/ohos_renderer.cpp"


def function(source, signature):
    assert source.count(signature) == 1, signature
    start = source.index(signature)
    opening = source.index("{", start)
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 0
    for match in tokens.finditer(source, opening):
        if match.group() == "{":
            depth += 1
        elif match.group() == "}":
            depth -= 1
            if depth == 0:
                return source[start:match.end()]
    raise ValueError(signature)


PREFIX = r'''
#include "cjgui_internal_renderer.h"
#include "cjgui_ohos_edit_ticket.h"
#include <deque>
#include <map>
#include <mutex>
#include <cstdio>
#define RLOGI(...) do{}while(0)
#define RLOGW(...) do{}while(0)
struct SceneNode {};
struct QueuedEvent {
    CjguiOhosEditTickets::Ticket inputTicket;
    CjguiOhosChoiceSources::Receipt choiceObservation;
};
struct Session {
    bool inUse = false, editing = false;
    uint64_t token = 0, acceptedProjectionVersion = 0;
    int64_t ticketDestroyRefusedCount = 0;
    std::vector<SceneNode> accepted, candidate;
    std::map<uint64_t, int> acceptedRunTable, buildingRunTable, imageObservedSerial;
    std::deque<QueuedEvent> events;
    struct TouchGesture {} gesture;
    std::u16string editingText, previewText;
    CjguiOhosFocusAuthority focusAuthority;
    struct Mirror {CjguiOhosEditTickets::OwnerReceipt ownerAcceptance;} ownedMirrorStaged,ownedMirrorAccepted;
    CjguiOhosEditTickets::Ticket dirtyInputTicket;
    CjguiOhosChoiceSources::Receipt consumedRestoreChoice;
    CjguiOhosEditTickets inputTickets;
    CjguiOhosChoiceSources choiceSources;
    CjguiOhosChoiceSources::Receipt lastEventChoice;
    CjguiOhosEditTickets::Ticket lastCompletedInputTicket, lastEventInputTicket;
    uint64_t inputOwnerCompleted = 0;
    bool inputOwnerFailed = false;
};
struct { std::mutex lock; Session sessions[2]; int occupied = 0; } g_sessions;
struct Pending { bool valid = false; void *job = nullptr; std::vector<int> nodes; } g_pending[2];
struct OhosAcceptedFact {};
struct { uint64_t token = 0, epoch = 0; OhosAcceptedFact fact; } g_acceptedFact[2];
std::mutex g_acceptedFactLock;
static int sessionSlotLocked(uint64_t token) {
    for (int i = 0; i < 2; ++i)
        if (g_sessions.sessions[i].inUse && g_sessions.sessions[i].token == token) return i;
    return -1;
}
static Session *lookupSessionLocked(uint64_t token) {
    const int slot = sessionSlotLocked(token);
    return slot < 0 ? nullptr : &g_sessions.sessions[slot];
}
static void cjguiOhosLogAcceptedImageSwap(const Session &, const std::vector<SceneNode> &,
                                         uint64_t, uint64_t, const char *) {}
static void cjguiOhosPruneReleasedImages() {}
'''

MAIN = r'''
struct Observers {
    std::weak_ptr<const CjguiOhosEditTicket> ticket;
    std::weak_ptr<CjguiOhosChoiceReceipt> choice;
};
static Observers arm(int slot, uint64_t token) {
    Session &s = g_sessions.sessions[slot];
    s.inUse = true; s.token = token; ++g_sessions.occupied;
    CjguiOhosChoiceOrigin origin;
    origin.key = {7, token, 3, 1, 10}; origin.text = u"xyz";
    origin.bodyBasis = "1,1,1,1,0,3,1,2,0,0,0,0";
    auto choice = s.choiceSources.observe(std::move(origin));
    if (!choice || !s.choiceSources.settle(choice, true,
        "1,1,1,1,0,3,1,2,0,0,0,0")) std::abort();
    CjguiOhosEditTicket input;
    input.key = choice->origin->key; input.choice = choice;input.ownerBinding=9;
    input.before = u"xyz"; input.after = u"xyAz"; input.inserted = u"A";
    auto ticket = s.inputTickets.admit(std::move(input));
    if (!ticket) std::abort();
    s.inputTickets.consume(ticket->id,ticket->key,ticket->before,ticket->after);
    s.inputTickets.complete(ticket->id,true,2,0,"1,1,2,2,0,4,2,2,0,0,0,0");
    const auto owner=s.inputTickets.acceptedForBody(9,2,"1,1,2,2,0,4,2,2,0,0,0,0");
    s.ownedMirrorStaged.ownerAcceptance=s.ownedMirrorAccepted.ownerAcceptance=owner;
    s.focusAuthority.transfer.inputOwner=owner;
    s.dirtyInputTicket=ticket;s.consumedRestoreChoice=choice;
    s.lastCompletedInputTicket = s.lastEventInputTicket = ticket;
    s.lastEventChoice = choice;
    s.events.push_back({ticket, choice});
    s.inputOwnerCompleted = ticket->id; s.inputOwnerFailed = true;
    g_acceptedFact[slot].token = token;
    return {ticket, choice};
}
int main() {
    auto first = arm(0, 91); auto other = arm(1, 92);
    // Preserve original unacknowledged-present guard and all payload ownership.
    g_pending[0].valid = true;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_PENDING_SETTLEMENT_UNRESOLVED)
        return 10;
    if (first.ticket.expired() || first.choice.expired() || g_sessions.occupied != 2) return 11;
    // The original presentation has now reached its acknowledged terminal.
    g_pending[0].valid = false;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_OK) return 12;
    Session &retired = g_sessions.sessions[0];
    std::printf("successful_destroy inputExpired=%d choiceExpired=%d pending=%zu liveInput=%zu liveChoice=%zu\n",
        first.ticket.expired(), first.choice.expired(), retired.inputTickets.pendingCount(),
        retired.inputTickets.liveCount(), retired.choiceSources.liveCount());
    if (!first.ticket.expired() || !first.choice.expired() ||
        retired.inputTickets.pendingCount() || retired.inputTickets.liveCount() ||
        retired.choiceSources.liveCount()) return 21;
    if (retired.lastEventInputTicket || retired.lastCompletedInputTicket || retired.lastEventChoice ||
        retired.inputOwnerCompleted || retired.inputOwnerFailed || retired.token || retired.inUse) return 22;
    // Destroy is scoped to the exact original token and leaves another window live.
    if (other.ticket.expired() || other.choice.expired() || g_sessions.occupied != 1 ||
        g_acceptedFact[1].token != 92) return 23;
    if (cjgui_internal_renderer_destroy(91) != CJGUI_INTERNAL_RENDERER_INVALID_SESSION) return 24;
    if (cjgui_internal_renderer_destroy(92) != CJGUI_INTERNAL_RENDERER_OK) return 25;
    if (!other.ticket.expired() || !other.choice.expired() || g_sessions.occupied) return 26;
    std::puts("PASS actual destroy releases input/choice queue + stream + dequeued receipt; original pending guard and other token preserved");
    return 0;
}
'''


def run(withdraw=False):
    production = function(SOURCE.read_text(), "CjguiInternalRendererStatus cjgui_internal_renderer_destroy(uint64_t session)")
    if withdraw:
        begin = "    // Input origins and choice receipts also belong to the retired fixed slot."
        end = "    s->gesture = Session::TouchGesture{};"
        assert production.count(begin) == production.count(end) == 1
        a = production.index(begin)
        b = production.index(end, a)
        production = production[:a] + production[b:]
    with tempfile.TemporaryDirectory(prefix="cjgui-input-destroy-") as tmp:
        cpp = Path(tmp) / "actual.cpp"
        binary = Path(tmp) / "actual"
        cpp.write_text(PREFIX + production + MAIN)
        subprocess.run(["clang++", "-std=c++17", "-I" + str(PLATFORM / "snapshot"),
                        "-I" + str(PLATFORM / "host"), str(cpp), "-o", str(binary)], check=True)
        result = subprocess.run([str(binary)])
        print("withdrawal" if withdraw else "actual", "exit", result.returncode, flush=True)
        return result.returncode


if __name__ == "__main__":
    result = run()
    if result:
        sys.exit(result)
    if "--selftest" in sys.argv:
        negative = run(withdraw=True)
        if negative != 21:
            raise SystemExit("withdrawal failed to discriminate retained receipts")
