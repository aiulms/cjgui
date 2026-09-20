#include "cards_protocol.h"

#include <cstdlib>
#include <cstdio>

namespace ohos_gui_smoke {

namespace {
std::string trim(const std::string &value) {
    size_t start = value.find_first_not_of(" \r\n\t");
    if (start == std::string::npos) return "";
    size_t end = value.find_last_not_of(" \r\n\t");
    return value.substr(start, end - start + 1);
}
}  // namespace

std::string protocolHello() {
    // No capability material here: the capability is delivered once on the
    // session's own connection after the handshake.
    return "OK smoke-protocol/1";
}

std::string protocolState(CardsOwner &owner) {
    CardState cards[2];
    int64_t version = 0;
    int selected = 0;
    owner.snapshot(cards, &version, &selected);
    char buffer[160];
    snprintf(buffer, sizeof(buffer),
             "V %lld SELECTED %d CARD 1 %.1f %.1f %.0f CARD 2 %.1f %.1f %.0f",
             static_cast<long long>(version), selected + 1,
             cards[0].x, cards[0].y, cards[0].colorIndex,
             cards[1].x, cards[1].y, cards[1].colorIndex);
    return buffer;
}

bool protocolParseOp(const std::string &line, const std::string &sessionCapability,
                     OperationRequest *outRequest, std::string *outError) {
    std::string trimmed = trim(line);
    *outError = "";
    if (trimmed.empty()) {
        *outError = "PROTOCOL";
        return false;
    }
    std::string parts[8];
    int count = 0;
    size_t start = 0;
    while (start <= trimmed.size() && count < 8) {
        size_t space = trimmed.find(' ', start);
        if (space == std::string::npos) {
            parts[count++] = trimmed.substr(start);
            break;
        }
        parts[count++] = trimmed.substr(start, space - start);
        start = space + 1;
    }
    if (trimmed == "HELLO") {
        *outError = "HANDSHAKE";
        return false;
    }
    if (trimmed == "STATE") {
        *outError = "STATE";
        return false;
    }
    if (parts[0] != "OP" || count < 4) {
        *outError = "PROTOCOL";
        return false;
    }
    // The capability is the principal carrier: "OP <capability> <expected> ...".
    if (parts[1] != sessionCapability || sessionCapability.empty()) {
        *outError = "unauthorized";
        return false;
    }
    outRequest->principal = "ExternalSession";
    outRequest->expectedVersion = strtoll(parts[2].c_str(), nullptr, 10);
    outRequest->op = parts[3];
    outRequest->cardId = atoi(parts[4].c_str());
    if (outRequest->op == "MOVE") {
        if (count < 7) {
            *outError = "PROTOCOL";
            return false;
        }
        outRequest->x = strtof(parts[5].c_str(), nullptr);
        outRequest->y = strtof(parts[6].c_str(), nullptr);
    }
    return true;
}

std::string protocolNewCapability() {
    // 128 bits from the platform CSPRNG, hex encoded (32 chars).
    unsigned char bytes[16];
    FILE *urandom = fopen("/dev/urandom", "rb");
    if (!urandom || fread(bytes, 1, sizeof(bytes), urandom) != sizeof(bytes)) {
        for (size_t i = 0; i < sizeof(bytes); ++i) bytes[i] = static_cast<unsigned char>(rand());
    }
    if (urandom) fclose(urandom);
    std::string hex;
    hex.reserve(32);
    char chunk[3];
    for (unsigned char byte : bytes) {
        snprintf(chunk, sizeof(chunk), "%02X", byte);
        hex += chunk;
    }
    return hex;
}

}  // namespace ohos_gui_smoke
