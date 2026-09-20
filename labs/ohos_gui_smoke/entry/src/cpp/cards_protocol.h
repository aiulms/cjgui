// Portable line protocol for the cards state channel. Pure standard C++ so
// the same sources run host-directed logic tests on macOS and inside the
// OHOS app. Framing: one line per request/response, accumulated until '\n',
// bounded by kMaxLineBytes.
#ifndef CARDS_PROTOCOL_H
#define CARDS_PROTOCOL_H

#include "cards_owner.h"

#include <string>

namespace ohos_gui_smoke {

constexpr size_t kMaxLineBytes = 64 * 1024;
constexpr int kMaxSessions = 4;

// One authorized external session. The capability is generated once per
// accepted session from a platform CSPRNG, is never logged, never appears in
// HELLO, and dies with the connection.
class ExternalSession {
public:
    std::string capability;
    bool alive = true;
};

// Builds the HELLO response (no capability material in it).
std::string protocolHello();
// Builds the STATE response from an owner snapshot (card ids 1-based).
std::string protocolState(CardsOwner &owner);
// Parses one request line into an OperationRequest. Returns false when the
// line is not an OP (protocol error). sessionCapability is this
// connection's capability; the request must carry it verbatim and the
// principal is then ExternalSession.
bool protocolParseOp(const std::string &line, const std::string &sessionCapability,
                     OperationRequest *outRequest, std::string *outError);
// Generates a per-session capability (CSPRNG, base64url-ish 22 chars).
std::string protocolNewCapability();

}  // namespace ohos_gui_smoke

#endif  // CARDS_PROTOCOL_H
