#ifndef CJGUI_OHOS_EDIT_TICKET_H
#define CJGUI_OHOS_EDIT_TICKET_H
#include "cjgui_ohos_choice_source.h"
#include <algorithm>
#include <cstdint>
#include <memory>
#include <deque>
#include <string>
#include <vector>

// Private immutable Will origin. No public renderer POD or platform pointer escapes.
struct CjguiOhosEditTicket {
    uint64_t id = 0, predecessor = 0, focusGeneration = 0;
    CjguiOhosProxyKey key;
    uint64_t node = 0, projection = 0, acceptedBinding = 0, ownerBinding = 0;
    int64_t resource = -1; uint32_t kind = 0;
    std::string field, sourceBasis;
    CjguiOhosChoiceSources::Receipt choice;
    std::u16string before, after, inserted;
    uint32_t start = 0, end = 0, afterStart = 0, afterEnd = 0;
};

// Separate immutable owner result. Platform Change and owner acceptance
// never overwrite the Will origin or confer a new mount/focus generation.
struct CjguiOhosEditOwnerReceipt {
    std::shared_ptr<const CjguiOhosEditTicket> origin;
    bool accepted = false;
    int64_t ownerVersion = -1, postOrigin = -1;
    std::string resultBasis;
};

class CjguiOhosEditTickets {
public:
    using Ticket = std::shared_ptr<const CjguiOhosEditTicket>;
    using OwnerReceipt = std::shared_ptr<const CjguiOhosEditOwnerReceipt>;
    static constexpr size_t kMaxTickets = 32;
    static constexpr size_t kMaxUnits = 1048576;
    Ticket admit(CjguiOhosEditTicket origin) {
        reap();
        size_t units = origin.before.size() + origin.after.size() + origin.inserted.size();
        size_t liveUnits = 0;
        for (const auto &w : live_) if (auto p = w.lock()) liveUnits += p->before.size()+p->after.size()+p->inserted.size();
        if (live_.size() >= kMaxTickets || units > kMaxUnits || liveUnits > kMaxUnits-units) return {};
        origin.id = ++nextId_;
        auto t = std::make_shared<const CjguiOhosEditTicket>(std::move(origin));
        pending_.push_back(t); live_.push_back(t); return t;
    }
    Ticket consume(uint64_t id, const CjguiOhosProxyKey &key, const std::u16string &before,
        const std::u16string &after) {
        if (pending_.empty()) return {};
        const auto t = pending_.front(); // FIFO is checked, never substituted for an arbitrary Change.
        if (t->id != id || !(t->key == key) || t->before != before || t->after != after) return {};
        pending_.erase(pending_.begin()); delivered_.push_back(t); return t;
    }
    bool platformChanged(uint64_t id,const CjguiOhosProxyKey &key,const std::u16string &after) {
        for(const auto &t:pending_) if(t->id==id) {
            if(!(t->key==key) || t->after!=after ||
               std::find(ready_.begin(),ready_.end(),id)!=ready_.end())return false;
            ready_.push_back(id);return true;
        }
        return false;
    }
    Ticket takeReady() {
        if(pending_.empty())return {};
        const auto t=pending_.front();const auto at=std::find(ready_.begin(),ready_.end(),t->id);
        if(at==ready_.end())return {};
        ready_.erase(at);return consume(t->id,t->key,t->before,t->after);
    }
    Ticket find(uint64_t id) const {
        if(id<=retiredThrough_) {
            for(const auto &t:delivered_)if(t->id==id)return t; // confirmation only; no new producer grant
            return {};
        }
        for(const auto &w:live_) if(auto t=w.lock()) if(t->id==id)return t;
        return {};
    }
    bool complete(uint64_t id,bool accepted,int64_t version=-1,int64_t origin=-1,const std::string &basis="") {
        for(const auto &done:terminals_) if(done.id==id) {
            // A confirmation-only caller can verify the existing terminal;
            // a typed duplicate must match all original owner result facts.
            return done.accepted==accepted && (version<0 ||
                (done.version==version && done.origin==origin && done.basis==basis));
        }
        const auto t=find(id);if(!t)return false;
        auto r=std::make_shared<const CjguiOhosEditOwnerReceipt>(CjguiOhosEditOwnerReceipt{t,accepted,version,origin,basis});
        if(accepted)latestAccepted_=r;
        terminals_.push_back({id,accepted,version,origin,basis,t});
        delivered_.erase(std::remove_if(delivered_.begin(),delivered_.end(),[id](const auto &p){return p->id==id;}),delivered_.end());
        // Compact terminals carry no input body and remain bounded independently
        // of the unchanged 32-live-ticket / 1Mi UTF-16 payload budget.
        // Keep every still-live origin's terminal even when newer results arrive.
        // At most 32 live origins plus 32 recent compact confirmations.
        if(terminals_.size()>kMaxTickets) {
            auto endRecent=terminals_.end()-kMaxTickets;
            for(auto it=terminals_.begin();it!=endRecent;) {
                if(it->source.expired()){it=terminals_.erase(it);endRecent=terminals_.end()-kMaxTickets;}
                else ++it;
            }
        }
        return true;
    }
    OwnerReceipt acceptedForBody(uint64_t binding,int64_t version,const std::string &basis) const {
        const auto r=latestAccepted_;
        if(!r || !r->accepted || r->postOrigin<0 || r->ownerVersion!=version ||
            r->origin->ownerBinding!=binding || !CjguiOhosSourceBasis(r->resultBasis).sameBody(CjguiOhosSourceBasis(basis)))return {};
        return r;
    }
    std::vector<uint64_t> unresolvedPrefix(const CjguiOhosProxyKey &key,uint64_t focus) const {
        std::vector<uint64_t> ids;
        for(const auto &w:live_) if(auto t=w.lock()) {
            if(t->id<=retiredThrough_ || !(t->key==key) || t->focusGeneration!=focus)continue;
            bool terminal=false;for(const auto &done:terminals_)if(done.id==t->id){terminal=true;break;}
            if(!terminal)ids.push_back(t->id);
        }
        return ids;
    }
    void clear(bool dispose=false) {
        std::vector<uint64_t> unfinished;
        for(const auto &t:pending_)unfinished.push_back(t->id);
        if(dispose)for(const auto &t:delivered_)unfinished.push_back(t->id);
        for(auto id:unfinished){bool done=false;for(const auto &r:terminals_)if(r.id==id){done=true;break;}if(!done)complete(id,false);}
        retiredThrough_=nextId_;
        ready_.clear();pending_.clear();if(dispose)delivered_.clear();latestAccepted_.reset();reap();
        // Weak payload accounting includes retained retired candidates. Their
        // bytes still count against admission, while the identity floor forbids
        // those old origins from re-entering a fresh instance or mount.
    }
    size_t pendingCount() const { return pending_.size(); }
    size_t liveCount() { reap(); return live_.size(); }
private:
    void reap() { live_.erase(std::remove_if(live_.begin(),live_.end(),[](const auto &w){return w.expired();}),live_.end()); }
    struct Terminal { uint64_t id;bool accepted;int64_t version,origin;std::string basis;std::weak_ptr<const CjguiOhosEditTicket> source; };
    std::deque<Terminal> terminals_;
    OwnerReceipt latestAccepted_;
    uint64_t nextId_ = 0,retiredThrough_=0;
    std::vector<Ticket> pending_,delivered_;
    std::vector<uint64_t> ready_;
    std::vector<std::weak_ptr<const CjguiOhosEditTicket>> live_;
};
#endif
