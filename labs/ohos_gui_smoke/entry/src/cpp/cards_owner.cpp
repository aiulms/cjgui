#include "cards_owner.h"

namespace ohos_gui_smoke {

CardsOwner::CardsOwner() {
    cards_[0] = CardState{120.0f, 160.0f, 0.0f};
    cards_[1] = CardState{360.0f, 160.0f, 1.0f};
}

OperationResult CardsOwner::applyOperation(const OperationRequest &request) {
    std::lock_guard<std::mutex> lock(mutex_);
    OperationResult result;
    // The principal is decided by the entry path (XComponent touch vs an
    // authorized external session), never by client-provided strings.
    if (request.principal != "HumanTouch" && request.principal != "ExternalSession") {
        result.reason = "unauthorized";
        result.versionAfter = version_;
        return result;
    }
    if (request.expectedVersion != version_) {
        result.reason = "stale_version";
        result.versionAfter = version_;
        return result;
    }
    // 1-based card ids everywhere; internally the array is 0-based.
    const int index = request.cardId - 1;
    if (index < 0 || index > 1) {
        result.reason = "unknown_card";
        result.versionAfter = version_;
        return result;
    }
    if (request.op == "SELECT") {
        selected_ = index;
        version_ += 1;
    } else if (request.op == "MOVE") {
        cards_[index].x = request.x;
        cards_[index].y = request.y;
        version_ += 1;
    } else if (request.op == "TOGGLE") {
        cards_[index].colorIndex = cards_[index].colorIndex > 0.5 ? 0.0 : 1.0;
        version_ += 1;
    } else {
        result.reason = "unknown_op";
        result.versionAfter = version_;
        return result;
    }
    result.applied = true;
    result.versionAfter = version_;
    return result;
}

void CardsOwner::snapshot(CardState *outCards, int64_t *outVersion, int *outSelected) {
    std::lock_guard<std::mutex> lock(mutex_);
    outCards[0] = cards_[0];
    outCards[1] = cards_[1];
    *outVersion = version_;
    *outSelected = selected_;
}

int CardsOwner::selectedCard() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return selected_;
}

bool CardsOwner::ensureInitialLayout(float width, float height) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (initialLayoutDone_ || width <= 0.0f || height <= 0.0f) {
        return false;
    }
    cards_[0].x = width * 0.30f;
    cards_[0].y = height * 0.45f;
    cards_[1].x = width * 0.70f;
    cards_[1].y = height * 0.45f;
    initialLayoutDone_ = true;
    return true;
}

}  // namespace ohos_gui_smoke
