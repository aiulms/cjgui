#include "state_server.h"
#include "cards_protocol.h"

#ifdef OHOS_PLATFORM
#include <hilog/log.h>
#define SLOG_INFO(...) OH_LOG_Print(LOG_APP, LOG_INFO, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)
#define SLOG_ERROR(...) OH_LOG_Print(LOG_APP, LOG_ERROR, LOG_DOMAIN, LOG_TAG, __VA_ARGS__)
#else
// Host-directed verification build (macOS): plain stderr logging.
#include <cstdio>
#define SLOG_INFO(...) do { fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)
#define SLOG_ERROR(...) do { fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while (0)
#endif

#include <arpa/inet.h>
#include <fcntl.h>
#include <poll.h>
#include <cstring>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

namespace ohos_gui_smoke {

namespace {
constexpr uint32_t LOG_DOMAIN = 0xD001C00;
constexpr const char *LOG_TAG = "StateServer";
// (Logging goes through SLOG_INFO/SLOG_ERROR; see the platform shim above.)
constexpr int kPollTimeoutMs = 100;
constexpr size_t kServerMaxLineBytes = 64 * 1024;

void setNonBlocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags >= 0) fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

struct ClientFds {
    int fd = -1;
    std::string capability;  // empty until the session handshake
    std::string pending;     // partial line buffer
};

// Serves one buffered client; returns false when the client must be closed
// (error, closed peer, oversized frame). Responses are written best-effort;
// a failed send closes the client (slow-reader policy).
bool serveClient(int fd, const std::string &capability, CardsOwner *owner,
                 std::string *pending, std::atomic<bool> *dirty, std::string *capabilityOut) {
    char buffer[2048];
    for (;;) {
        ssize_t received = recv(fd, buffer, sizeof(buffer), 0);
        if (received == 0) return false;                    // peer closed
        if (received < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                SLOG_ERROR("recv failed errno=%d", errno);
            }
            return (errno == EAGAIN || errno == EWOULDBLOCK) ? true : false;
        }
        SLOG_INFO("recv %zd bytes", received);
        pending->append(buffer, static_cast<size_t>(received));
        if (pending->size() > kServerMaxLineBytes) return false;  // oversized frame
        size_t newline = pending->find('\n');
        while (newline != std::string::npos) {
            std::string line = pending->substr(0, newline);
            pending->erase(0, newline + 1);
            std::string trimmed;
            size_t start = line.find_first_not_of(" \r\t");
            if (start != std::string::npos) trimmed = line.substr(start);
            if (!trimmed.empty()) {
                std::string response;
                if (trimmed == "HELLO") {
                    // One capability per connection; a repeated HELLO does
                    // not re-issue it.
                    if (capabilityOut->empty()) {
                        *capabilityOut = protocolNewCapability();
                        response = "OK smoke-protocol/1 CAP " + *capabilityOut;
                    } else {
                        response = "ERR already";
                    }
                } else if (capabilityOut->empty()) {
                    response = "ERR unauthorized";
                } else if (trimmed == "STATE") {
                    response = protocolState(*owner);
                } else if (trimmed.rfind("OP ", 0) == 0) {
                    OperationRequest request;
                    std::string error;
                    if (!protocolParseOp(trimmed, *capabilityOut, &request, &error)) {
                        response = (error == "unauthorized") ? "ERR unauthorized" : "ERR " + error;
                    } else {
                        OperationResult result = owner->applyOperation(request);
                        dirty->store(true);
                        response = result.applied ? "OK V" + std::to_string(result.versionAfter)
                                                  : "ERR " + result.reason;
                    }
                } else {
                    response = "ERR PROTOCOL";
                }
                const std::string frame = response + "\n";
                const ssize_t sentBytes = send(fd, frame.c_str(), frame.size(), 0);
                SLOG_INFO("respond %zd bytes: %s", sentBytes, response.c_str());
                if (sentBytes < 0) return false;
                if (pending->size() > kServerMaxLineBytes) return false;
            }
            newline = pending->find('\n');
        }
    }
}
}  // namespace

void StateServer::serve(CardsOwner *owner, std::atomic<bool> *dirty, int port) {
    int listener = socket(AF_INET, SOCK_STREAM, 0);
    if (listener < 0) {
        lastError_ = "socket failed errno=" + std::to_string(errno);
        SLOG_ERROR("%s", lastError_.c_str());
        running_ = false;
        return;
    }
    int reuse = 1;
    setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    address.sin_port = htons(static_cast<uint16_t>(port));
    if (bind(listener, reinterpret_cast<sockaddr *>(&address), sizeof(address)) < 0 ||
        listen(listener, 2) < 0) {
        lastError_ = "bind/listen failed errno=" + std::to_string(errno);
        SLOG_ERROR("%s", lastError_.c_str());
        close(listener);  // this thread owns the fd
        running_ = false;
        return;
    }
    setNonBlocking(listener);
    SLOG_INFO("listening on 127.0.0.1:%d", port);

    std::vector<ClientFds> clients;
    while (!stopFlag_.load()) {
        struct pollfd polled[1 + kMaxSessions];
        nfds_t count = 0;
        polled[count].fd = listener;
        polled[count].events = POLLIN;
        count += 1;
        for (const ClientFds &client : clients) {
            polled[count].fd = client.fd;
            polled[count].events = POLLIN;
            count += 1;
        }
        int ready = poll(polled, count, kPollTimeoutMs);
        if (ready < 0) {
            if (errno == EINTR) continue;
            break;
        }
        // Clients first (reverse index walk keeps removals safe).
        for (int index = static_cast<int>(count) - 1; index >= 1; --index) {
            if (polled[index].revents & POLLIN) {
                int clientIndex = index - 1;
                bool keep = serveClient(clients[clientIndex].fd, clients[clientIndex].capability,
                                        owner, &clients[clientIndex].pending,
                                        dirty, &clients[clientIndex].capability);
                if (clients[clientIndex].pending.size() > kServerMaxLineBytes) keep = false;
                if (!keep) {
                    close(clients[clientIndex].fd);  // server thread owns it
                    clients.erase(clients.begin() + clientIndex);
                }
            }
        }
        if (polled[0].revents & POLLIN) {
            if (static_cast<int>(clients.size()) < kMaxSessions) {
                int connection = accept(listener, nullptr, nullptr);
                if (connection >= 0) {
                    setNonBlocking(connection);
                    ClientFds client;
                    client.fd = connection;
                    clients.push_back(client);
                }
            }
            // Over capacity: refuse by not accepting; the backlog backs up.
        }
        // The dirty flag is owned by the bridge; rendering is driven by the
        // UI-thread pump, so no additional signalling is needed here.
    }
    for (ClientFds &client : clients) {
        close(client.fd);  // server thread owns these fds
    }
    clients.clear();
    close(listener);  // the same thread that opened it closes it
    running_ = false;
}

bool StateServer::start(CardsOwner *owner, std::atomic<bool> *dirty, int port) {
    if (running_) return true;
    stopFlag_ = false;
    running_ = true;
    thread_ = std::thread([this, owner, dirty, port]() { serve(owner, dirty, port); });
    return true;
}

void StateServer::stop() {
    stopFlag_.store(true);
    if (thread_.joinable()) thread_.join();
}

}  // namespace ohos_gui_smoke
