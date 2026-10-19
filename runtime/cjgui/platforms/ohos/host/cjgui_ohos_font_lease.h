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
    using Observer = std::function<void(const char *,uint64_t,uint64_t,size_t)>;
    struct Stats {
        uint64_t created = 0, destroyed = 0, destroyMicros = 0, admittedUnits = 0, refused = 0;
        uint64_t sealed = 0, retired = 0, maxRetiredSealAgeMicros = 0;
    };
    struct Generation {
        Collection *collection = nullptr;
        uint64_t id = 0, fontConfiguration = 0;
        size_t workUnits = 0;
        bool sealed = false;
        std::chrono::steady_clock::time_point sealedAt{};
        std::thread::id thread;
        std::function<void(Collection *)> destroy;
        std::shared_ptr<Stats> stats;
        Observer observer;
        ~Generation() {
            assert(thread == std::this_thread::get_id());
            if(observer)observer("destroy-begin",id,fontConfiguration,workUnits);
            const auto start = std::chrono::steady_clock::now();
            destroy(collection);
            stats->destroyMicros += std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now() - start).count();
            ++stats->destroyed;
            if(observer)observer("destroyed",id,fontConfiguration,workUnits);
        }
    };
    using Lease = std::shared_ptr<Generation>;
    static constexpr size_t kMaxGenerations = 3;
    // Two complete A2 bounded live-frame workloads fit in a fresh generation.
    static constexpr size_t kWorkUnitsPerGeneration = 262144;
    CjguiOhosFontPool(std::function<Collection *()> create, std::function<void(Collection *)> destroy,
        Observer observer = {}, size_t softWorkUnits = kWorkUnitsPerGeneration)
        : create_(std::move(create)), destroy_(std::move(destroy)), stats_(std::make_shared<Stats>()),
          observer_(std::move(observer)), softWorkUnits_(softWorkUnits) {
        assert(softWorkUnits_ > 0 && softWorkUnits_ <= kWorkUnitsPerGeneration);
    }
    CjguiOhosFontPool(const CjguiOhosFontPool &) = delete;
    CjguiOhosFontPool &operator=(const CjguiOhosFontPool &) = delete;
    ~CjguiOhosFontPool() {
        clear();
        // The render-thread pool must outlive every Typography/private lease.
        assert(generations_.empty() && retiringCount_ == 0);
    }
    Lease acquire(size_t units, uint64_t configuration) {
        if (!configuration || units > kWorkUnitsPerGeneration || retiringCount_) {
            ++stats_->refused; return {};
        }
        // Soft sealing is only an opportunity, not another admission limit.
        // Preserve a hard-capacity active slot when all three generations are
        // held by real old/candidate Typography leases (notably an A2 frame).
        if (softWorkUnits_ < kWorkUnitsPerGeneration && current_ &&
            current_->fontConfiguration == configuration && current_->workUnits &&
            (current_->workUnits >= softWorkUnits_ || units > softWorkUnits_ - current_->workUnits)) {
            while (liveGenerations() >= kMaxGenerations && retireOneUnused()) {}
            if (liveGenerations() < kMaxGenerations) sealCurrent();
        }
        if (current_ && (current_->fontConfiguration != configuration ||
            units > kWorkUnitsPerGeneration - current_->workUnits)) sealCurrent();
        if (!current_) {
            // Admission pressure is a legal render-thread boundary. Reclaim
            // only already-unleased sealed generations, never a fourth slot.
            while (liveGenerations() >= kMaxGenerations && retireOneUnused()) {}
            if (liveGenerations() >= kMaxGenerations) { ++stats_->refused; return {}; }
            if(observer_)observer_("create-begin",stats_->created+1,configuration,0);
            auto *collection = create_();
            if (!collection) {
                if(observer_)observer_("create-failed",stats_->created+1,configuration,0);
                ++stats_->refused; return {};
            }
            current_ = std::make_shared<Generation>();
            current_->collection = collection; current_->id = ++stats_->created;
            current_->fontConfiguration = configuration; current_->thread = std::this_thread::get_id();
            current_->destroy = destroy_; current_->stats = stats_;
            current_->observer = observer_;
            generations_.push_back(current_);
            if(observer_)observer_("created",current_->id,configuration,0);
        }
        assert(current_->thread == std::this_thread::get_id());
        current_->workUnits += units; stats_->admittedUnits += units; // failures also consume work
        auto lease = current_;
        if (softWorkUnits_ < kWorkUnitsPerGeneration && current_->workUnits >= softWorkUnits_ &&
            liveGenerations() < kMaxGenerations) sealCurrent();
        return lease;
    }
    uint64_t currentId() const { return current_ ? current_->id : 0; }
    const Stats &stats() const { return *stats_; }
    // Read-only diagnostics must not perform SDK destruction.
    size_t liveGenerations() const { return generations_.size() + retiringCount_; }
    size_t sealedGenerations() const {
        return std::count_if(generations_.begin(), generations_.end(),
            [](const Lease &g) { return g->sealed; });
    }
    size_t retirableGenerations() const {
        return std::count_if(generations_.begin(), generations_.end(),
            [](const Lease &g) { return g->sealed && g.use_count() == 1; });
    }
    bool hasRetirable() const { return retirableGenerations() != 0; }
    size_t retiringGenerations() const { return retiringCount_; }
    uint64_t oldestRetirableSealAgeMicros() const {
        uint64_t age = 0;
        for (const auto &g : generations_) {
            if (g->sealed && g.use_count() == 1) age = std::max(age, sealAgeMicros(*g));
        }
        return age;
    }
    // Called at the existing idle/job boundary, or when admission needs a slot.
    // One synchronous SDK Destroy is indivisible. Keep its slot accounted for
    // throughout the callback, including any observation made inside Destroy.
    bool retireOneUnused() {
        if (retiringCount_) return false;
        for (auto it = generations_.begin(); it != generations_.end(); ++it) {
            if (!(*it)->sealed || it->use_count() != 1) continue;
            assert((*it)->thread == std::this_thread::get_id());
            auto retiring = std::move(*it);
            generations_.erase(it);
            ++retiringCount_;
            const auto sealedAt = retiring->sealedAt;
            retiring.reset(); // the only permitted SDK destruction opportunity
            --retiringCount_;
            ++stats_->retired;
            const auto age = std::chrono::duration_cast<std::chrono::microseconds>(
                std::chrono::steady_clock::now() - sealedAt).count();
            stats_->maxRetiredSealAgeMicros = std::max(stats_->maxRetiredSealAgeMicros,
                static_cast<uint64_t>(std::max<int64_t>(0, age)));
            return true;
        }
        return false;
    }
    // Existing Typography leases survive clear. Teardown first releases those
    // objects on this thread, then drains the now-unleased generations here.
    void clear() { sealCurrent(); while (retireOneUnused()) {} }
private:
    static uint64_t sealAgeMicros(const Generation &g) {
        const auto age = std::chrono::duration_cast<std::chrono::microseconds>(
            std::chrono::steady_clock::now() - g.sealedAt).count();
        return static_cast<uint64_t>(std::max<int64_t>(0, age));
    }
    void sealCurrent() {
        if (!current_) return;
        assert(current_->thread == std::this_thread::get_id());
        auto *g = current_.get(); // generations_ retains the actual owner
        g->sealed = true;
        g->sealedAt = std::chrono::steady_clock::now();
        ++stats_->sealed;
        current_.reset();
        if (observer_) observer_("sealed", g->id, g->fontConfiguration, g->workUnits);
    }
    std::function<Collection *()> create_;
    std::function<void(Collection *)> destroy_;
    std::shared_ptr<Stats> stats_;
    Observer observer_;
    const size_t softWorkUnits_;
    Lease current_;
    std::vector<Lease> generations_; // at most three, including pending retirement
    size_t retiringCount_ = 0;
};
#endif
