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
struct CjguiOhosSelectionCommandExecution;
struct CjguiOhosEditTicket {
    uint64_t id = 0, predecessor = 0, focusGeneration = 0;
    CjguiOhosProxyKey key;
    uint64_t node = 0, projection = 0, acceptedBinding = 0, ownerBinding = 0;
    int64_t resource = -1; uint32_t kind = 0;
    std::string field, sourceBasis;
    CjguiOhosChoiceSources::Receipt choice;
    std::shared_ptr<const CjguiOhosSelectionCommandExecution> commandExecution;
    std::shared_ptr<const CjguiOhosInputSourceLeaf> sourceLeaf;
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

// Value facts from one actual SDK Change. observation is only a diagnostic label.
struct CjguiOhosPlatformChangeEvidence {
    CjguiOhosProxyKey key;
    uint64_t focus = 0, anchor = 0, observation = 0;
    std::u16string before, after, preview, oldPreview;
    uint32_t start = 0, end = 0, afterStart = 0, afterEnd = 0;
    int32_t previewOffset = -2, oldPreviewOffset = -2;
};

class CjguiOhosEditTickets {
public:
    using Ticket = std::shared_ptr<const CjguiOhosEditTicket>;
    using OwnerReceipt = std::shared_ptr<const CjguiOhosEditOwnerReceipt>;
    static constexpr size_t kMaxTickets = 32;
    static constexpr size_t kMaxUnits = 1048576;
    Ticket admit(CjguiOhosEditTicket origin) {
        reap();
        size_t units = origin.before.size() + origin.after.size() + origin.inserted.size()+
            (origin.sourceLeaf?origin.sourceLeaf->retainedUnits():0);
        size_t liveUnits = 0;
        for (const auto &w : live_) if (auto p = w.lock()) liveUnits += p->before.size()+p->after.size()+p->inserted.size()+
            (p->sourceLeaf?p->sourceLeaf->retainedUnits():0);
        liveUnits+=dependencyUnits();
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
    struct PlatformPrefix { uint64_t boundary = 0; size_t covered = 0, newlyReady = 0; };
    template<class Permit>
    PlatformPrefix platformChangedPrefix(const CjguiOhosPlatformChangeEvidence &e, Permit permit) {
        if(!e.key.valid() || !e.focus || !e.anchor || !e.observation ||
           e.previewOffset!=-1 || e.oldPreviewOffset!=-1 || !e.preview.empty() || !e.oldPreview.empty())return {};
        const auto anchor=std::find_if(pending_.begin(),pending_.end(),[&](const Ticket&t){return t->id==e.anchor;});
        if(anchor==pending_.end())return {};
        const auto &a=**anchor;
        if(a.before==a.after || a.before!=e.before || a.after!=e.after || a.start!=e.start ||
           a.end!=e.end || a.afterStart!=e.afterStart || a.afterEnd!=e.afterEnd)return {};
        if(std::count_if(pending_.begin(),pending_.end(),[&](const Ticket&t){
            return t->before!=t->after && t->after==e.after;})!=1)return {};
        Ticket previous;
        for(auto it=pending_.begin();it!=anchor+1;++it) {
            const auto &t=*it;
            if(!(t->key==e.key) || t->focusGeneration!=e.focus || terminalResult(t->id)!=0 ||
               !sameInputSource(*t,a) || !validInputSplice(*t) ||
               (t->choice && t->choice->settled && !t->choice->accepted))return {};
            if(!previous && t->predecessor) {
                previous=find(t->predecessor);
                if(!previous || (terminalResult(previous->id)!=1 && !hasPairedChange(previous->id)))return {};
            }
            if(previous && (t->predecessor!=previous->id || t->before!=previous->after ||
                            !sameInputSource(*t,*previous)))return {};
            previous=t;
        }
        // Check every original authority/deadline before adding any ready fact.
        for(auto it=pending_.begin();it!=anchor+1;++it)if(!permit(*it))return {};
        reap();
        PlatformPrefix result{e.anchor,static_cast<size_t>(anchor-pending_.begin()+1),0};
        for(auto it=pending_.begin();it!=anchor+1;++it) {
            const auto &t=*it;
            if(std::find(ready_.begin(),ready_.end(),t->id)==ready_.end()) {
                ready_.push_back(t->id);++result.newlyReady;
                prefixProof_.push_back({t,e.anchor,e.observation});
            }
        }
        return result;
    }
    bool platformPrefixProof(uint64_t id,uint64_t &anchor,uint64_t &observation)const {
        if(id<=retiredThrough_)return false;
        for(const auto &p:prefixProof_)if(auto t=p.origin.lock())if(t->id==id) {
            anchor=p.anchor;observation=p.observation;return true;
        }
        return false;
    }
    Ticket takeReady() {
        if(pending_.empty())return {};
        const auto t=pending_.front();const auto at=std::find(ready_.begin(),ready_.end(),t->id);
        if(at==ready_.end())return {};
        ready_.erase(at);const auto delivered=consume(t->id,t->key,t->before,t->after);
        if(delivered)paired_.push_back(delivered);
        return delivered;
    }
    // Only the exact current pending tail can grant a proposed successor.
    // This is a causal reference, not a paired Change or an owner result.
    Ticket pendingPredecessor(uint64_t id) const {
        if(!id || pending_.empty() || pending_.back()->id!=id || terminalResult(id)!=0)return {};
        return pending_.back();
    }
    bool hasPairedChange(uint64_t id)const {
        // Means platform completion, not one SDK callback for each Will.
        if(id<=retiredThrough_)return false;
        for(const auto&w:paired_)if(auto t=w.lock())if(t->id==id)return true;
        return false;
    }
    // Waiting evidence only: a real admitted Will whose completion has not
    // occurred. Never use its proposed after as a platform or display fact.
    bool hasUnpairedAfter(uint64_t frontier,const CjguiOhosProxyKey &key,uint64_t focus,
        uint64_t node,int64_t resource,uint32_t kind,uint64_t ownerBinding)const {
        for(const auto &t:pending_)if(t->id>frontier && t->key==key && t->focusGeneration==focus &&
            t->node==node && t->resource==resource && t->kind==kind && t->ownerBinding==ownerBinding &&
            terminalResult(t->id)==0 && !hasPairedChange(t->id))return true;
        return false;
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
        if(!accepted) {
            pending_.erase(std::remove_if(pending_.begin(),pending_.end(),[id](const auto&p){return p->id==id;}),pending_.end());
            ready_.erase(std::remove(ready_.begin(),ready_.end(),id),ready_.end());
            // At most 32 live origins. Refusal closes every dependent origin,
            // including a later Change already waiting in ready_. Accepted
            // terminals are immutable and are never replayed or overwritten.
            for(const auto&w:live_)if(auto child=w.lock())
                if(child->predecessor==id && terminalResult(child->id)==0)complete(child->id,false);
        }
        // Compact terminals carry no input body and remain bounded independently
        // of the unchanged 32-live-ticket / 1Mi UTF-16 payload budget.
        // Keep every still-live origin's terminal even when newer results arrive.
        // At most 32 live origins plus 32 recent compact confirmations.
        if(terminals_.size()>kMaxTickets) {
            auto endRecent=terminals_.end()-kMaxTickets;
            for(auto it=terminals_.begin();it!=endRecent;) {
                if(it->source.expired() && !dependencyHeld(it->id)){it=terminals_.erase(it);endRecent=terminals_.end()-kMaxTickets;}
                else ++it;
            }
        }
        return true;
    }
    int terminalResult(uint64_t id)const {
        for(const auto &r:terminals_)if(r.id==id)return r.accepted?1:-1;
        return id<=retiredThrough_?-1:0;
    }
    bool acceptedResult(uint64_t id,int64_t &version,int64_t &origin)const {
        for(const auto&r:terminals_)if(r.id==id && r.accepted && r.version>=0 && r.origin>=0) {
            version=r.version;origin=r.origin;return true;
        }
        return false;
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
    // Owner completion does not mean the body has been published. This compact
    // query freezes IDs without manufacturing or retaining a new observation.
    std::vector<uint64_t> unpublishedPrefix(const CjguiOhosProxyKey &key,uint64_t focus,int64_t publishedVersion) const {
        std::vector<uint64_t> ids;
        for(const auto &w:live_)if(auto t=w.lock()) {
            if(t->id<=retiredThrough_ || !(t->key==key) || t->focusGeneration!=focus)continue;
            const Terminal *done=nullptr;for(const auto &r:terminals_)if(r.id==t->id){done=&r;break;}
            if(!done || (done->accepted && done->version>publishedVersion))ids.push_back(t->id);
        }
        return ids;
    }
    bool retainsPublication(uint64_t id,int64_t publishedVersion) const {
        if(dependencyHeld(id) || (latestAccepted_ && latestAccepted_->origin->id==id))return true;
        for(const auto &r:terminals_)if(r.id==id)return r.accepted && r.version>publishedVersion;
        return static_cast<bool>(find(id));
    }
    // Selection-only query: owner completion is not publication. Transfer keeps unresolvedPrefix semantics.
    bool publicationDependencies(const CjguiOhosProxyKey &key,uint64_t focus,int64_t publishedVersion,
        std::vector<std::shared_ptr<const CjguiOhosPublicationDependency>> &out) {
        size_t units=dependencyUnits();for(const auto&w:live_)if(auto t=w.lock())units+=t->before.size()+t->after.size()+t->inserted.size()+
            (t->sourceLeaf?t->sourceLeaf->retainedUnits():0);
        if(units>kMaxUnits)return false;
        for(const auto&w:live_)if(auto t=w.lock()) {
            if(t->id<=retiredThrough_ || !(t->key==key) || t->focusGeneration!=focus)continue;
            const Terminal *done=nullptr;for(const auto&r:terminals_)if(r.id==t->id){done=&r;break;}
            if(done && (!done->accepted || done->version<=publishedVersion))continue;
            auto d=std::make_shared<CjguiOhosPublicationDependency>();
            d->id=t->id;d->predecessor=t->predecessor;d->key=t->key;d->focusGeneration=t->focusGeneration;
            d->node=t->node;d->resource=t->resource;d->kind=t->kind;d->acceptedBinding=t->acceptedBinding;d->ownerBinding=t->ownerBinding;
            d->field=t->field;d->before=t->before;d->after=t->after;d->start=t->start;d->end=t->end;d->afterStart=t->afterStart;d->afterEnd=t->afterEnd;
            // Only the command root supplies an alternate published starting
            // prestate. A continuation starts at its actual prior owner body.
            if(!t->predecessor)d->sourceLeaf=t->sourceLeaf;
            if(done){d->frozenVersion=done->version;d->frozenOrigin=done->origin;d->frozenBasis=done->basis;}
            const size_t retained=d->retainedUnits()+(d->sourceLeaf?d->sourceLeaf->retainedUnits():0);
            if(retained>kMaxUnits-units)return false;
            units+=retained;out.push_back(d);
        }
        for(const auto&d:out)dependencies_.push_back(d);
        return true;
    }
    bool dependencyResult(const CjguiOhosPublicationDependency &d,int64_t &version,int64_t &origin,std::string &basis)const {
        for(const auto&r:terminals_)if(r.id==d.id && r.accepted && r.version>=0 && r.origin>=0) {
            if(d.frozenVersion>=0 && (d.frozenVersion!=r.version || d.frozenOrigin!=r.origin || d.frozenBasis!=r.basis))return false;
            version=r.version;origin=r.origin;basis=r.basis;return true;
        }
        return false;
    }
    void clear(bool dispose=false) {
        std::vector<uint64_t> unfinished;
        for(const auto &t:pending_)unfinished.push_back(t->id);
        if(dispose)for(const auto &t:delivered_)unfinished.push_back(t->id);
        for(auto id:unfinished){bool done=false;for(const auto &r:terminals_)if(r.id==id){done=true;break;}if(!done)complete(id,false);}
        retiredThrough_=nextId_;
        ready_.clear();pending_.clear();prefixProof_.clear();if(dispose)delivered_.clear();latestAccepted_.reset();reap();
        // Weak payload accounting includes retained retired candidates. Their
        // bytes still count against admission, while the identity floor forbids
        // those old origins from re-entering a fresh instance or mount.
    }
    size_t retainedUnits()const {
        size_t n=dependencyUnits();for(const auto&w:live_)if(auto t=w.lock())n+=t->before.capacity()+t->after.capacity()+t->inserted.capacity()+
            (t->sourceLeaf?t->sourceLeaf->retainedUnits():0);return n;
    }
    size_t pendingCount() const { return pending_.size(); }
    size_t liveCount() { reap(); return live_.size(); }
private:
    static bool sameInputSource(const CjguiOhosEditTicket &a,const CjguiOhosEditTicket &b) {
        return a.key==b.key && a.focusGeneration==b.focusGeneration && a.node==b.node && a.resource==b.resource &&
            a.kind==b.kind && a.field==b.field && a.acceptedBinding==b.acceptedBinding && a.ownerBinding==b.ownerBinding &&
            a.sourceBasis==b.sourceBasis && a.choice==b.choice && a.commandExecution==b.commandExecution && a.sourceLeaf==b.sourceLeaf;
    }
    static bool scalarBoundary(const std::u16string&s,size_t i) {
        return i<=s.size() && !(i>0 && i<s.size() && s[i-1]>=0xd800 && s[i-1]<=0xdbff && s[i]>=0xdc00 && s[i]<=0xdfff);
    }
    static bool wellFormed(const std::u16string&s) {
        for(size_t i=0;i<s.size();++i) {
            if(s[i]>=0xd800 && s[i]<=0xdbff) {if(++i>=s.size() || s[i]<0xdc00 || s[i]>0xdfff)return false;}
            else if(s[i]>=0xdc00 && s[i]<=0xdfff)return false;
        }
        return true;
    }
    static bool validInputSplice(const CjguiOhosEditTicket&t) {
        return t.start<=t.end && t.end<=t.before.size() && t.afterStart==t.start && t.afterEnd>=t.afterStart &&
            t.afterEnd<=t.after.size() && wellFormed(t.before) && wellFormed(t.after) &&
            scalarBoundary(t.before,t.start) && scalarBoundary(t.before,t.end) &&
            scalarBoundary(t.after,t.afterStart) && scalarBoundary(t.after,t.afterEnd) &&
            t.inserted==t.after.substr(t.afterStart,t.afterEnd-t.afterStart) &&
            t.before.substr(0,t.start)+t.inserted+t.before.substr(t.end)==t.after;
    }
    struct PrefixProof {std::weak_ptr<const CjguiOhosEditTicket> origin;uint64_t anchor,observation;};
    std::vector<PrefixProof> prefixProof_;
    bool dependencyHeld(uint64_t id)const {for(const auto&w:dependencies_)if(auto d=w.lock())if(d->id==id)return true;return false;}
    size_t dependencyUnits()const {size_t n=0;for(const auto&w:dependencies_)if(auto d=w.lock())n+=d->retainedUnits()+
        (d->sourceLeaf?d->sourceLeaf->retainedUnits():0);return n;}
    std::vector<std::weak_ptr<const CjguiOhosPublicationDependency>> dependencies_;
    void reap() {prefixProof_.erase(std::remove_if(prefixProof_.begin(),prefixProof_.end(),[](const PrefixProof&p){return p.origin.expired();}),prefixProof_.end()); paired_.erase(std::remove_if(paired_.begin(),paired_.end(),[](const auto&w){return w.expired();}),paired_.end()); dependencies_.erase(std::remove_if(dependencies_.begin(),dependencies_.end(),[](const auto&w){return w.expired();}),dependencies_.end()); live_.erase(std::remove_if(live_.begin(),live_.end(),[](const auto &w){return w.expired();}),live_.end()); }
    struct Terminal { uint64_t id;bool accepted;int64_t version,origin;std::string basis;std::weak_ptr<const CjguiOhosEditTicket> source; };
    std::deque<Terminal> terminals_;
    OwnerReceipt latestAccepted_;
    uint64_t nextId_ = 0,retiredThrough_=0;
    std::vector<Ticket> pending_,delivered_;
    std::vector<uint64_t> ready_;
    std::vector<std::weak_ptr<const CjguiOhosEditTicket>> live_;
    std::vector<std::weak_ptr<const CjguiOhosEditTicket>> paired_;
};
#endif
