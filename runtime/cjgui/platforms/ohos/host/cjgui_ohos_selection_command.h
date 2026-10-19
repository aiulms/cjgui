#ifndef CJGUI_OHOS_SELECTION_COMMAND_H
#define CJGUI_OHOS_SELECTION_COMMAND_H
#include "cjgui_ohos_edit_ticket.h"

// Private Session-lock facts. The retained receipt/origin is charged by the
// original choice/input ledgers; this record does not create another choice.
struct CjguiOhosAcceptedSelectionFact {
    CjguiOhosChoiceSources::Receipt receipt;
    CjguiOhosCoverage coverage;
    CjguiOhosEditTickets::OwnerReceipt acceptance;
    std::string basis;
    int64_t ownerVersion=-1,postOrigin=-1,anchor=-1,focus=-1;
    size_t retainedUnits()const{return (sizeof(*this)+basis.capacity()+1)/sizeof(char16_t);}

    static std::shared_ptr<const CjguiOhosAcceptedSelectionFact> freeze(
        const CjguiOhosChoiceSources::Receipt &r,const char **firstRefusal=nullptr) {
        auto refuse=[&](const char *why)->std::shared_ptr<const CjguiOhosAcceptedSelectionFact>{
            if(firstRefusal)*firstRefusal=why;return {};
        };
        if(firstRefusal)*firstRefusal=nullptr;
        if(!r || !r->settled || !r->accepted || !r->origin ||
           (r->origin->sourceKind!=1 && r->origin->sourceKind!=3))return refuse("receipt_or_kind");
        const auto &o=*r->origin;
        const auto c=r->resolvedCoverage?r->resolvedCoverage:o.coverage;
        if(!c || !c->qualified || !c->layout || !c->platform ||
           !(c->key==o.key) || c->focus!=o.focus || c->node!=o.node ||
           c->resource!=o.resource || c->kind!=o.kind || c->acceptedBinding!=o.acceptedBinding ||
           c->ownerBinding!=o.ownerBinding || c->ownerVersion!=r->ownerVersion ||
           r->postOrigin!=(o.sourceKind==3?c->layoutOrigin:c->platformOrigin) ||
           !CjguiOhosSourceBasis(c->bodyBasis).sameBody(CjguiOhosSourceBasis(r->basis)))return refuse("coverage_key_focus_owner_basis");
        const auto acceptance=c->acceptance.lock();
        if(acceptance) {
            const auto &t=acceptance->origin;
            if(!t || !acceptance->accepted || acceptance->ownerVersion!=c->ownerVersion ||
               acceptance->postOrigin!=c->platformOrigin || t->node!=c->node ||
               t->resource!=c->resource || t->kind!=c->kind || t->ownerBinding!=c->ownerBinding ||
               t->acceptedBinding!=c->acceptedBinding || t->after!=*c->platform ||
               !CjguiOhosSourceBasis(acceptance->resultBasis).sameBody(CjguiOhosSourceBasis(c->bodyBasis)))return refuse("typed_receipt_after");
        } else if(c->layoutOrigin!=c->platformOrigin || *c->layout!=*c->platform)return refuse("exact_mirror");
        CjguiOhosAcceptedSelectionFact f;
        f.receipt=r;f.coverage=c;f.acceptance=acceptance;f.basis=r->basis;
        f.ownerVersion=r->ownerVersion;f.postOrigin=r->postOrigin;
        f.anchor=r->anchorByte;f.focus=r->focusByte;
        return std::make_shared<const CjguiOhosAcceptedSelectionFact>(std::move(f));
    }
};
using CjguiOhosAcceptedSelection=std::shared_ptr<const CjguiOhosAcceptedSelectionFact>;

// Origin and newly accepted Flush are separate identities. A structural link
// is immutable and receives its deadline once, before the mounted source retires.
struct CjguiOhosSelectionCaptureFact {
    CjguiOhosAcceptedSelection source;
    CjguiOhosCoverage acceptedBody;
    std::string field;
    uint64_t paintTicket=0,paintSerial=0,paintProjection=0,surface=0,geometry=0;
    uint64_t operation=0,targetEdit=0;
    int64_t targetContext=0,notAfter=0;
    size_t retainedUnits()const{return (sizeof(*this)+field.capacity()+1)/sizeof(char16_t);}
    static std::shared_ptr<const CjguiOhosSelectionCaptureFact> bind(
        const std::shared_ptr<const CjguiOhosSelectionCaptureFact> &f,
        const CjguiOhosFocusAuthority &authority) {
        if(!f || !f->source || !f->source->coverage || f->operation || !f->notAfter)return {};
        const auto &c=*f->source->coverage;const auto &t=authority.transfer;
        if(!authority.eligible(c.focus) || !t.operation || t.generation!=c.focus ||
           !(t.old==c.key) || t.targetContext<=0 || !t.targetEdit)return {};
        auto linked=*f;linked.operation=t.operation;linked.targetContext=t.targetContext;
        linked.targetEdit=t.targetEdit;
        if(t.deadline>0)linked.notAfter=std::min(linked.notAfter,t.deadline);
        return std::make_shared<const CjguiOhosSelectionCaptureFact>(std::move(linked));
    }
};
using CjguiOhosSelectionCapture=std::shared_ptr<const CjguiOhosSelectionCaptureFact>;

struct CjguiOhosSelectionCommandOwnerResult {
    std::string basis;
    int64_t version=-1,origin=-1,anchor=-1,focus=-1,selectionRevision=-1;
};
struct CjguiOhosSelectionCommandTarget {
    uint64_t sequence=0,operation=0,edit=0;
    int64_t context=0;
    CjguiOhosProxyKey predecessor;
    std::shared_ptr<const CjguiOhosSelectionCommandOwnerResult> owner;
};
// A target reservation is not an installation. This immutable record is made
// only for the actual op8 mount, its attached session and accepted/painted body.
struct CjguiOhosSelectionCommandExecution {
    uint64_t sequence=0,command=0,publication=0,attach=0,install=0;
    uint64_t paintTicket=0,paintSerial=0,projection=0,surface=0,geometry=0;
    CjguiOhosProxyKey key;
    uint64_t focus=0;
    uint32_t start=0,end=0;
    int64_t notAfter=0;
    std::shared_ptr<const CjguiOhosSelectionCommandTarget> target;
    CjguiOhosCoverage acceptedBody,installedBody;
    uint32_t sourceKind=4; // 4 physical command; 1 an actual ordinary choice installation.
};
// One current association. Capture origin never becomes a target context.
// Owner execution and platform installation are independent terminals.
struct CjguiOhosSelectionCommandState {
    static constexpr size_t kReservedUnits=512; // fixed metadata + bounded owner basis, within the existing cap
    CjguiOhosSelectionCapture capture;
    CjguiOhosChoiceSources::Receipt choice;
    std::shared_ptr<const CjguiOhosSelectionCommandOwnerResult> owner;
    std::shared_ptr<const CjguiOhosSelectionCommandTarget> target;
    std::shared_ptr<const CjguiOhosSelectionCommandExecution> execution;
    uint64_t targetSequence=0,executionSequence=0;
    int64_t ordinaryNotAfter=0;
    uint64_t ordinaryAttach=0;
    bool ordinaryNotificationPending=false,ordinaryNotificationOffered=false;
    int64_t firstObservation=-1;
    bool setterSent=false,installed=false,firstInputConsumed=false;
    bool terminal=false;
    std::string reason;
    bool begin(const CjguiOhosSelectionCapture &source,const CjguiOhosChoiceSources::Receipt &q) {
        if((choice && !terminal) || !source || !source->operation || !source->source || !source->source->coverage || !q ||
           !q->origin->capturedCommand || q->origin->sourceKind!=4 ||
           q->origin->coverage!=source->source->coverage || q->origin->text!=*source->source->coverage->platform ||
           q->origin->ownerBinding!=source->source->coverage->ownerBinding ||
           !(q->origin->key==source->source->coverage->key) ||
           q->origin->focus!=source->source->coverage->focus || q->origin->deadline!=source->notAfter)return false;
        clear();capture=source;choice=q;return true;
    }
    bool beginOrdinary(const CjguiOhosAcceptedSelection &source,int64_t deadline) {
        if(!source || !source->receipt || !source->coverage || deadline<=0 ||
           source->receipt->origin->sourceKind!=1 || source->receipt->origin->capturedCommand ||
           source->basis.size()>256)return false;
        clear();choice=source->receipt;ordinaryNotAfter=deadline;
        const CjguiOhosSourceBasis b(source->basis);if(!b.valid){clear();return false;}
        CjguiOhosSelectionCommandOwnerResult result{source->basis,source->ownerVersion,source->postOrigin,
            source->anchor,source->focus,b.value[7]};
        owner=std::make_shared<const CjguiOhosSelectionCommandOwnerResult>(std::move(result));
        const auto &key=choice->origin->key;
        CjguiOhosSelectionCommandTarget t{++targetSequence,0,key.edit,key.context,key,owner};
        target=std::make_shared<const CjguiOhosSelectionCommandTarget>(std::move(t));
        ordinaryNotificationPending=true;return true;
    }
    bool completeOwner(CjguiOhosChoiceSources &ledger,const std::string &basis,int64_t version,
        int64_t origin,int64_t anchor,int64_t focus) {
        if(terminal || !choice || basis.size()>256)return false;
        if(owner)return owner->basis==basis && owner->version==version && owner->origin==origin &&
            owner->anchor==anchor && owner->focus==focus;
        if(!ledger.settleCapturedCommand(choice,basis,version,origin,anchor,focus))return false;
        CjguiOhosSelectionCommandOwnerResult result{basis,version,origin,anchor,focus,
            CjguiOhosSourceBasis(basis).value[7]};
        owner=std::make_shared<const CjguiOhosSelectionCommandOwnerResult>(std::move(result));return true;
    }
    void expire(int64_t now) {
        const int64_t deadline=capture?capture->notAfter:ordinaryNotAfter;
        if(choice && !terminal && !firstInputConsumed && !choice->platformInstalled && deadline>0 && now>=deadline) {
            terminal=true;reason=owner?"platform_unconfirmed_deadline":"owner_unconfirmed_deadline";
        }
    }
    void retireExecution(){execution.reset();firstObservation=-1;setterSent=false;installed=false;ordinaryAttach=0;}
    void clear(){ordinaryNotificationPending=false;ordinaryNotificationOffered=false;capture.reset();choice.reset();owner.reset();target.reset();retireExecution();ordinaryNotAfter=0;firstInputConsumed=false;terminal=false;reason.clear();}
};
static_assert(sizeof(CjguiOhosSelectionCommandOwnerResult)+sizeof(CjguiOhosSelectionCommandTarget)+
    sizeof(CjguiOhosSelectionCommandExecution)+256<=CjguiOhosSelectionCommandState::kReservedUnits*sizeof(char16_t),
    "command metadata must fit its reserved units inside the original choice budget");
#endif
