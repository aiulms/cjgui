// Cards owner: the single business state for the cross-window/cards smoke.
// Human touches and external clients enter the same applyOperation; stale
// versions and unauthorized sessions are rejected without mutation.
// Card identity is 1-based everywhere (protocol, display, owner mapping).
#ifndef CARDS_OWNER_H
#define CARDS_OWNER_H

#include <mutex>
#include <string>

namespace ohos_gui_smoke {

struct CardState {
    float x = 0.0f;
    float y = 0.0f;
    float colorIndex = 0.0f;
};

struct OperationRequest {
    std::string principal;   // "HumanTouch" or "ExternalSession" — set by the
                             // entry path, never by the client payload
    int64_t expectedVersion = -1;
    std::string op;          // SELECT | MOVE | TOGGLE
    int cardId = 0;          // 1-based
    float x = 0.0f;
    float y = 0.0f;
};

struct OperationResult {
    bool applied = false;
    std::string reason;      // "" | stale_version | unauthorized | unknown_op | unknown_card
    int64_t versionAfter = 0;
};

class CardsOwner {
public:
    CardsOwner();

    OperationResult applyOperation(const OperationRequest &request);
    void snapshot(CardState *outCards, int64_t *outVersion, int *outSelected);
    int selectedCard() const;
    // One-time initial layout: centers both cards for the first non-zero
    // surface size. Later surface recreations must NOT call this — the
    // business snapshot survives recreate.
    bool ensureInitialLayout(float width, float height);

private:
    mutable std::mutex mutex_;
    CardState cards_[2];
    int64_t version_ = 0;
    int selected_ = 0;
    bool initialLayoutDone_ = false;
};

}  // namespace ohos_gui_smoke

#endif  // CARDS_OWNER_H
