#ifndef CJGUI_OHOS_ORIGINAL_INSERT_H
#define CJGUI_OHOS_ORIGINAL_INSERT_H
#include "cjgui_ohos_selection_command.h"

// A cancelled SDK InsertValue is a command, never a completed SDK delta.
// One live carrier and one original Q own this bounded FIFO. No history graph.
struct CjguiOhosOriginalInsert {
    uint64_t id=0,callback=0,ordinal=0;
    int64_t receivedAt=0;
    uint32_t sdkOffset=0;
    std::u16string text;
    std::shared_ptr<const CjguiOhosSelectionCommandExecution> execution;
};
// Frozen by actual owner completion. It retains no raw text or predecessor
// graph, and never rewrites the original Q's installed source.
struct CjguiOhosOriginalInsertOwnerResult {
    std::shared_ptr<const CjguiOhosSelectionCommandExecution> root;
    uint64_t id=0,callback=0,ordinal=0,prefix=0,predecessor=0;
    int64_t beforeVersion=-1,beforeAnchor=-1,beforeFocus=-1;
    std::string beforeBasis;
    int64_t version=-1,anchor=-1,focus=-1;
    std::string basis;
    bool accepted=false;
};
class CjguiOhosOriginalInserts {
public:
    using Command=std::shared_ptr<const CjguiOhosOriginalInsert>;
    using OwnerResult=std::shared_ptr<const CjguiOhosOriginalInsertOwnerResult>;
    static constexpr size_t kMaxCount=32,kMaxUnits=1048576;
    uint64_t nextId=0,lastCallback=0,received=0,completed=0;
    int64_t version=-1,anchor=-1,focus=-1;
    std::string basis,reason;
    std::shared_ptr<const CjguiOhosSelectionCommandExecution> root;
    std::deque<Command> pending;
    std::vector<std::weak_ptr<const CjguiOhosOriginalInsert>> live;
    std::vector<std::weak_ptr<const CjguiOhosOriginalInsertOwnerResult>> liveResults;
    std::vector<std::weak_ptr<const CjguiOhosTextCoverage>> liveCoverages;
    OwnerResult result;
    Command executing;
    bool installed=false,terminal=false,feedbackComplete=false,feedbackConsumed=false,ownerStarted=false;
    uint64_t completedId=0;
    bool completedAccepted=false;
    int64_t completedVersion=-1,completedAnchor=-1,completedFocus=-1;
    std::string completedBasis;
    static size_t coverageUnits(std::vector<CjguiOhosCoverage> &proofs) {
        size_t n=0;std::vector<const std::u16string*> texts;
        for(size_t i=0;i<proofs.size();++i){const auto c=proofs[i];
            n+=(sizeof(*c)+c->bodyBasis.capacity()+1)/2+
                (c->layoutBytes.capacity()+c->platformBytes.capacity())*sizeof(int32_t)/sizeof(char16_t);
            for(const auto &t:{c->layout,c->platform})if(t && std::find(texts.begin(),texts.end(),t.get())==texts.end()){
                texts.push_back(t.get());n+=t->capacity();
            }
            if(c->body && std::find(proofs.begin(),proofs.end(),c->body)==proofs.end())proofs.push_back(c->body);
        }return n;
    }
    static size_t rootUnits(const std::shared_ptr<const CjguiOhosSelectionCommandExecution>&e) {
        if(!e)return 0;std::vector<CjguiOhosCoverage> proofs;
        for(const auto &c:{e->acceptedBody,e->installedBody})if(c && std::find(proofs.begin(),proofs.end(),c)==proofs.end())proofs.push_back(c);
        return (sizeof(*e)+sizeof(*e->target)+sizeof(*e->target->owner)+e->target->owner->basis.capacity()+1)/2+coverageUnits(proofs);
    }
    size_t units()const {
        size_t n=(sizeof(*this)+basis.capacity()+reason.capacity()+completedBasis.capacity()+1)/2;
        std::vector<const CjguiOhosSelectionCommandExecution*> seen;
        std::vector<const CjguiOhosSelectionCommandTarget*> targets;
        std::vector<const CjguiOhosSelectionCommandOwnerResult*> owners;
        std::vector<CjguiOhosCoverage> proofs;
        auto hold=[&](const CjguiOhosCoverage&c){if(c && std::find(proofs.begin(),proofs.end(),c)==proofs.end())proofs.push_back(c);};
        auto charge=[&](const std::shared_ptr<const CjguiOhosSelectionCommandExecution>&e){
            if(!e || std::find(seen.begin(),seen.end(),e.get())!=seen.end())return;
            seen.push_back(e.get());n+=(sizeof(*e)+1)/2;
            if(std::find(targets.begin(),targets.end(),e->target.get())==targets.end()){
                targets.push_back(e->target.get());n+=(sizeof(*e->target)+1)/2;
            }
            if(std::find(owners.begin(),owners.end(),e->target->owner.get())==owners.end()){
                owners.push_back(e->target->owner.get());n+=(sizeof(*e->target->owner)+e->target->owner->basis.capacity()+1)/2;
            }
            hold(e->acceptedBody);hold(e->installedBody);
        };
        charge(root);
        for(const auto &w:live)if(const auto c=w.lock()){n+=(sizeof(*c)+1)/2+c->text.capacity();charge(c->execution);}
        for(const auto &w:liveResults)if(const auto r=w.lock()){
            n+=(sizeof(*r)+r->beforeBasis.capacity()+r->basis.capacity()+1)/2;charge(r->root);
        }
        for(const auto &w:liveCoverages)if(const auto c=w.lock())hold(c);
        return n+coverageUnits(proofs);
    }
    bool holdCoverage(const CjguiOhosCoverage&c,size_t otherUnits){
        liveCoverages.erase(std::remove_if(liveCoverages.begin(),liveCoverages.end(),[](const auto&w){return w.expired();}),liveCoverages.end());
        for(const auto&w:liveCoverages)if(w.lock()==c)return true;
        liveCoverages.push_back(c);
        const auto retained=units();if(otherUnits>kMaxUnits || retained>kMaxUnits-otherUnits){liveCoverages.pop_back();return false;}
        return true;
    }
    bool active()const{return root && !terminal && !feedbackConsumed;}
    Command receive(const std::shared_ptr<const CjguiOhosSelectionCommandExecution>&e,
        uint64_t callback,uint32_t offset,const std::u16string&text,int64_t now,
        size_t otherCount,size_t otherUnits) {
        if(!e || !e->target || !e->target->owner || !callback || text.empty() || now>=e->notAfter ||
           callback<=lastCallback || terminal || feedbackConsumed ||
           (root && root!=e))return {};
        live.erase(std::remove_if(live.begin(),live.end(),[](const auto&w){return w.expired();}),live.end());
        liveResults.erase(std::remove_if(liveResults.begin(),liveResults.end(),[](const auto&w){return w.expired();}),liveResults.end());
        std::vector<uint64_t> origins;
        for(const auto&w:live)if(auto c=w.lock())origins.push_back(c->id);
        for(const auto&w:liveResults)if(auto r=w.lock())if(std::find(origins.begin(),origins.end(),r->id)==origins.end())origins.push_back(r->id);
        std::u16string frozen(text);
        // Charge root ownership at the first admission too, including the
        // bounded compact owner receipt that will replace the source basis.
        const size_t charge=(sizeof(CjguiOhosOriginalInsert)+sizeof(CjguiOhosOriginalInsertOwnerResult)+513)/2+frozen.capacity()+
            (root?0:rootUnits(e)+256);
        if(otherCount+origins.size()>=kMaxCount || otherUnits>kMaxUnits ||
           units()>kMaxUnits-otherUnits || charge>kMaxUnits-otherUnits-units())return {};
        if(!root){root=e;version=e->target->owner->version;anchor=e->target->owner->anchor;
            focus=e->target->owner->focus;basis=e->target->owner->basis;}
        auto c=std::make_shared<const CjguiOhosOriginalInsert>(CjguiOhosOriginalInsert{
            ++nextId,callback,++received,now,offset,std::move(frozen),e});
        feedbackComplete=false;lastCallback=callback;pending.push_back(c);live.push_back(c);return c;
    }
    Command takeReady(int64_t now) {
        if(!active() || executing || pending.empty() || !installed)return {};
        if(now>=root->notAfter){cancel("original_deadline");return {};}
        executing=pending.front();return executing;
    }
    bool begin(uint64_t id,int64_t now) {
        if(!active() || !installed || !executing || executing->id!=id || ownerStarted || now>=root->notAfter)return false;
        ownerStarted=true;return true;
    }
    bool complete(uint64_t id,bool accepted,int64_t newVersion,int64_t newAnchor,int64_t newFocus,
        const std::string &newBasis) {
        if(id && id==completedId)return completedAccepted==accepted && completedVersion==newVersion &&
            completedAnchor==newAnchor && completedFocus==newFocus && completedBasis==newBasis;
        if((accepted && !ownerStarted) || !executing || executing->id!=id || pending.empty() || pending.front()!=executing)return false;
        if(accepted && (newVersion<version || newAnchor<0 || newFocus!=newAnchor || newBasis.empty() ||
            newBasis.size()>256))return false;
        if(accepted){
            result=std::make_shared<const CjguiOhosOriginalInsertOwnerResult>(CjguiOhosOriginalInsertOwnerResult{
                root,id,executing->callback,executing->ordinal,completed+1,completedId,
                version,anchor,focus,basis,newVersion,newAnchor,newFocus,newBasis,true});
            liveResults.push_back(result);
        }
        ++completed;completedId=id;pending.pop_front();executing.reset();ownerStarted=false;
        completedAccepted=accepted;completedVersion=newVersion;completedAnchor=newAnchor;completedFocus=newFocus;completedBasis=newBasis;
        if(!accepted){cancel("owner_refused");return true;}
        version=newVersion;anchor=newAnchor;focus=newFocus;basis=newBasis;return true;
    }
    // Cancellation before begin wins. After begin only the original owner
    // result may settle; successors are retired and the insertion is not replayed.
    void cancel(const char *why){terminal=true;reason=why;
        if(ownerStarted){pending.clear();pending.push_back(executing);}
        else{pending.clear();executing.reset();}}
    void clear(){const auto identity=nextId;auto retained=std::move(live);auto results=std::move(liveResults);auto coverages=std::move(liveCoverages);*this=CjguiOhosOriginalInserts{};
        nextId=identity;live=std::move(retained);liveResults=std::move(results);liveCoverages=std::move(coverages);}
};
#endif
