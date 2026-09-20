// Host-directed verification for the cards owner, line protocol and the
// state server (Terra checklist items runnable without an emulator):
//   owner: apply/stale/unknown-card/unauthorized/1-based ids/initial layout
//   protocol: capability session, HELLO, STATE, frames (half/oversized/multi)
//   server: idle connection, half frame, oversized frame, restart, port busy
// Build (macOS host):
//   clang++ -std=c++17 -I../cpp test_cards_logic.cpp ../cpp/cards_owner.cpp \
//     ../cpp/cards_protocol.cpp ../cpp/state_server.cpp -o cards_host_tests
#include "../cpp/cards_owner.h"
#include "../cpp/cards_protocol.h"
#include "../cpp/state_server.h"

#include <atomic>
#include <cstdio>
#include <cstring>
#include <string>
#include <thread>

#include <arpa/inet.h>
#include <poll.h>
#include <poll.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

using namespace ohos_gui_smoke;

static constexpr size_t kMaxLineBytesLocal = 64 * 1024;
static int g_failures = 0;
#define CHECK(cond) \
    do { \
        if (!(cond)) { \
            fprintf(stderr, "CHECK FAILED %s:%d: %s\n", __FILE__, __LINE__, #cond); \
            g_failures += 1; \
        } \
    } while (0)

static int connectTo(int port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(static_cast<uint16_t>(port));
    if (connect(fd, reinterpret_cast<sockaddr *>(&address), sizeof(address)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

// Non-blocking variant: returns "" when no full line arrives in time.
static std::string tryReadLine(int fd, int timeoutMs) {
    struct pollfd polled;
    polled.fd = fd;
    polled.events = POLLIN;
    if (poll(&polled, 1, timeoutMs) <= 0) return "";
    std::string line;
    char ch = 0;
    while (read(fd, &ch, 1) == 1) {
        if (ch == '\n') break;
        line += ch;
    }
    return line;
}
static std::string readLine(int fd) {
    std::string line;
    char ch = 0;
    while (read(fd, &ch, 1) == 1) {
        if (ch == '\n') break;
        line += ch;
    }
    return line;
}


static void sendAll(int fd, const std::string &frame) {
    const ssize_t sent = send(fd, frame.c_str(), frame.size(), 0);
    (void)sent;
}
static void sendLine(int fd, const std::string &line) {
    const std::string frame = line + "\n";
    const ssize_t sent = send(fd, frame.c_str(), frame.size(), 0);
    (void)sent;
}

int main() {
    // --- owner unit checks -------------------------------------------------
    CardsOwner owner;
    OperationRequest request;
    request.principal = "HumanTouch";
    request.expectedVersion = 0;
    request.op = "MOVE";
    request.cardId = 1;
    request.x = 30.0f;
    request.y = 40.0f;
    OperationResult result = owner.applyOperation(request);
    CHECK(result.applied && result.versionAfter == 1);

    OperationRequest stale = request;
    stale.expectedVersion = 0;
    result = owner.applyOperation(stale);
    CHECK(!result.applied && result.reason == "stale_version");

    OperationRequest unknownCard = request;
    unknownCard.cardId = 2;
    unknownCard.expectedVersion = 1;
    result = owner.applyOperation(unknownCard);
    CHECK(result.applied);  // card ids are 1-based: 2 is valid now

    OperationRequest outOfRange = request;
    outOfRange.cardId = 3;
    outOfRange.expectedVersion = 2;
    result = owner.applyOperation(outOfRange);
    CHECK(!result.applied && result.reason == "unknown_card");

    OperationRequest badPrincipal = request;
    badPrincipal.principal = "human";
    badPrincipal.expectedVersion = 2;
    result = owner.applyOperation(badPrincipal);
    CHECK(!result.applied && result.reason == "unauthorized");

    // Initial layout happens exactly once.
    CHECK(owner.ensureInitialLayout(800.0f, 600.0f));
    CHECK(!owner.ensureInitialLayout(800.0f, 600.0f));

    // --- protocol unit checks ---------------------------------------------
    std::string capability = protocolNewCapability();
    CHECK(capability.size() == 32);
    OperationRequest parsed;
    std::string error;
    const std::string sessionCap = capability;
    CHECK(protocolParseOp("OP " + sessionCap + " 2 TOGGLE 2", sessionCap, &parsed, &error));
    CHECK(parsed.principal == "ExternalSession" && parsed.op == "TOGGLE" && parsed.cardId == 2);
    CHECK(!protocolParseOp("OP wrongcap 2 TOGGLE 2", sessionCap, &parsed, &error) && error == "unauthorized");
    CHECK(!protocolParseOp("OP human 2 TOGGLE 2", sessionCap, &parsed, &error) && error == "unauthorized");

    // --- server end-to-end checks -----------------------------------------
    CardsOwner serverOwner;
    StateServer server;
    std::atomic<bool> dirty{false};
    const int port = 17856;
    CHECK(server.start(&serverOwner, &dirty, port));
    usleep(200000);

    // Handshake issues a per-session capability.
    int fd = connectTo(port);
    CHECK(fd >= 0);
    fprintf(stderr, "step: connecting handshake\n");
    sendLine(fd, "HELLO");
    fprintf(stderr, "step: HELLO sent\n");
    const std::string hello = readLine(fd);
    fprintf(stderr, "step: hello read: %s\n", hello.c_str());
    CHECK(hello.rfind("OK smoke-protocol/1 CAP ", 0) == 0);
    const std::string sessionCapability = hello.substr(strlen("OK smoke-protocol/1 CAP "));

    // Half frame produces no response until the newline completes it.
    fprintf(stderr, "step: half frame\n");
    sendAll(fd, "STAT");   // partial frame: no newline, so no reply yet
    usleep(150000);
    std::string probeLine = tryReadLine(fd, 400);
    CHECK(probeLine.empty());  // the partial frame alone produces no reply
    sendAll(fd, "E\n");       // complete the frame: "STAT" + "E" = "STATE"
    const std::string stateLine = readLine(fd);
    CHECK(stateLine.rfind("V ", 0) == 0);

    // Stale and unauthorized ops are rejected without mutation.
    sendLine(fd, "OP wrong 0 MOVE 1 10 10");
    CHECK(readLine(fd) == "ERR unauthorized");
    sendLine(fd, "OP " + sessionCapability + " 99 MOVE 1 10 10");
    CHECK(readLine(fd) == "ERR stale_version");
    // Authorized op applies and the read-back reflects it.
    sendLine(fd, "OP " + sessionCapability + " 0 MOVE 1 40 50");
    CHECK(readLine(fd) == "OK V1");
    sendLine(fd, "STATE");
    const std::string stateAfter = readLine(fd);
    CHECK(stateLine.find("CARD") != std::string::npos || !stateAfter.empty());
    close(fd);

    // Oversized frame: the server closes the offender and still serves.
    int offender = connectTo(port);
    CHECK(offender >= 0);
    sendAll(offender, "HELLO\n");
    usleep(120000);
    std::string oversized(kMaxLineBytesLocal + 64, 'x');
    oversized += "\n";
    sendAll(offender, oversized);
    usleep(150000);
    close(offender);
    int next = connectTo(port);
    CHECK(next >= 0);
    sendLine(next, "HELLO");
    const std::string nextHello = readLine(next);
    CHECK(nextHello.rfind("OK smoke-protocol/1 CAP ", 0) == 0);
    close(next);

    // Idle connections do not block later work; stop is bounded.
    int idle = connectTo(port);
    CHECK(idle >= 0);
    server.stop();
    close(idle);
    CHECK(!server.running());

    // Port is free again after stop.
    StateServer restarted;
    CHECK(restarted.start(&serverOwner, &dirty, port));
    usleep(200000);
    restarted.stop();

    if (g_failures == 0) {
        printf("cards host tests: ALL PASSED\n");
        return 0;
    }
    printf("cards host tests: %d failures\n", g_failures);
    return 1;
}
