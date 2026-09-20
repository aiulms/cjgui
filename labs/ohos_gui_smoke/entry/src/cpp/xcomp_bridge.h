// XComponent bridge: owns the lifecycle generation, routes touch to the
// CardsOwner, and exposes pumpFrame() to ArkTS. Late callbacks carrying a
// stale surface/window are rejected by the surface lease, so a destroyed
// surface can never be drawn into.
#ifndef XCOMP_BRIDGE_H
#define XCOMP_BRIDGE_H

#include "cards_owner.h"
#include "cards_render.h"
#include "state_server.h"

#include <atomic>
#include <cstdint>

namespace ohos_gui_smoke {

constexpr uint32_t kLogDomain = 0xD001C00;
constexpr const char *kLogTag = "CrossDrag";

extern CardsOwner g_owner;
extern std::atomic<bool> g_dirty;
extern std::atomic<uint64_t> g_generation;

// Called from ArkTS on a short interval; draws when dirty. Returns true
// when a frame was submitted.
bool pumpFrame();
// Application teardown: retire the lease, release the renderer, stop the
// state server, and (as the last owner) release the EGL display.
void shutdownNative();

}  // namespace ohos_gui_smoke

#endif  // XCOMP_BRIDGE_H
