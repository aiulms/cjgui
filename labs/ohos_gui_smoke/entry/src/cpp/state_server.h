// Local state server (ordinary sandboxed app capability). Loopback bind, one
// authorized session at a time (kMaxSessions), poll-based so stop is bounded
// and fds are owned exclusively by the server thread. No hdc forwarding is
// involved in the protocol itself; the capability is issued per session.
#ifndef STATE_SERVER_H
#define STATE_SERVER_H

#include "cards_owner.h"

#include <atomic>
#include <cstdint>
#include <string>
#include <thread>

namespace ohos_gui_smoke {

class StateServer {
public:
    // Application-level lifecycle: start once, stop on teardown. Not tied to
    // surface recreation.
    bool start(CardsOwner *owner, std::atomic<bool> *dirty, int port);
    void stop();
    bool running() const { return running_; }
    std::string lastError() const { return lastError_; }

private:
    void serve(CardsOwner *owner, std::atomic<bool> *dirty, int port);

    std::atomic<bool> running_{false};
    std::atomic<bool> stopFlag_{false};
    std::string lastError_;
    std::thread thread_;
};

}  // namespace ohos_gui_smoke

#endif  // STATE_SERVER_H
