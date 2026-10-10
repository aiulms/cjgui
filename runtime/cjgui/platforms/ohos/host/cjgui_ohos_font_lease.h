#ifndef CJGUI_OHOS_FONT_LEASE_H
#define CJGUI_OHOS_FONT_LEASE_H
#include <algorithm>
#include <cassert>
#include <chrono>
#include <cstdint>
#include <functional>
#include <memory>
#include <thread>
#include <vector>

// Private render-thread resource owner. Work units bound admission, not SDK cache bytes.
template <class Collection> class CjguiOhosFontPool {
public:
    struct Stats { uint64_t created = 0, destroyed = 0, destroyMicros = 0, admittedUnits = 0, refused = 0; };
    struct Generation {
        Collection *collection = nullptr;
        uint64_t id = 0, fontConfiguration = 0;
        size_t workUnits = 0;
        std::thread::id thread;
        std::function<void(Collection *)> destroy;
        std::shared_ptr<Stats> stats;
        ~Generation() {
            assert(thread == std::this_thread::get_id());
            const auto start = std::chrono::steady_clock::now();
            destroy(collection);
            stats->destroyMicros += std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now() - start).count();
            ++stats->destroyed;
        }
    };
    using Lease = std::shared_ptr<Generation>;
    static constexpr size_t kMaxGenerations = 3;
    // Two complete A2 bounded live-frame workloads fit in a fresh generation.
    static constexpr size_t kWorkUnitsPerGeneration = 262144;
    CjguiOhosFontPool(std::function<Collection *()> create, std::function<void(Collection *)> destroy)
        : create_(std::move(create)), destroy_(std::move(destroy)), stats_(std::make_shared<Stats>()) {}
    Lease acquire(size_t units, uint64_t configuration) {
        if (!configuration || units > kWorkUnitsPerGeneration) { ++stats_->refused; return {}; }
        if (current_ && (current_->fontConfiguration != configuration ||
            units > kWorkUnitsPerGeneration - current_->workUnits)) current_.reset();
        reap();
        if (!current_) {
            if (generations_.size() >= kMaxGenerations) { ++stats_->refused; return {}; }
            auto *collection = create_();
            if (!collection) { ++stats_->refused; return {}; }
            current_ = std::make_shared<Generation>();
            current_->collection = collection; current_->id = ++stats_->created;
            current_->fontConfiguration = configuration; current_->thread = std::this_thread::get_id();
            current_->destroy = destroy_; current_->stats = stats_;
            generations_.push_back(current_);
        }
        assert(current_->thread == std::this_thread::get_id());
        current_->workUnits += units; stats_->admittedUnits += units; // failures also consume work
        return current_;
    }
    uint64_t currentId() const { return current_ ? current_->id : 0; }
    const Stats &stats() const { return *stats_; }
    size_t liveGenerations() { reap(); return generations_.size(); }
    // Existing Typography leases survive this call. Production clears them first at teardown.
    void clear() { current_.reset(); reap(); }
private:
    void reap() { generations_.erase(std::remove_if(generations_.begin(), generations_.end(),
        [](const auto &w) { return w.expired(); }), generations_.end()); }
    std::function<Collection *()> create_;
    std::function<void(Collection *)> destroy_;
    std::shared_ptr<Stats> stats_;
    Lease current_;
    std::vector<std::weak_ptr<Generation>> generations_;
};
#endif
