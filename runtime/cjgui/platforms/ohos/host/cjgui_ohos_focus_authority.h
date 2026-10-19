#ifndef CJGUI_OHOS_FOCUS_AUTHORITY_H
#define CJGUI_OHOS_FOCUS_AUTHORITY_H
#include <cstdint>
#include <string>
#include <memory>
#include <vector>
#include <algorithm>
struct CjguiOhosEditOwnerReceipt;

// Private, Session-lock confined. Owner versions and component echoes never issue a token.
struct CjguiOhosProxyKey {
    uint64_t app = 0, session = 0, edit = 0, mount = 0;
    int64_t context = 0;
    bool operator==(const CjguiOhosProxyKey &b) const {
        return app == b.app && session == b.session && context == b.context && edit == b.edit && mount == b.mount;
    }
    bool valid() const { return app && session && context > 0 && edit && mount; }
};
// A native focus origin, captured before asynchronous UI notification. This
// deliberately has no mount member: it authorizes scheduling, never input.
struct CjguiOhosPendingFocusSource {
    uint64_t app = 0, session = 0, edit = 0, focus = 0;
    int64_t context = 0;
    bool valid() const { return app && session && edit && focus && context > 0; }
    bool operator==(const CjguiOhosPendingFocusSource &b) const {
        return app == b.app && session == b.session && edit == b.edit &&
            focus == b.focus && context == b.context;
    }
};
struct CjguiOhosFocusAuthority {
    uint64_t generation = 0, operationSeq = 0;
    bool active = false, foreground = true;
    uint64_t node = 0, binding = 0;
    int64_t resource = -1;
    uint32_t kind = 0;
    std::string field;
    CjguiOhosProxyKey mounted;
    CjguiOhosProxyKey reservedProxy;
    struct Transfer {
        uint64_t operation = 0, generation = 0, restoreRequest = 0;
        int64_t targetContext = 0, deadline = 0;
        uint64_t targetEdit = 0;
        CjguiOhosProxyKey old;
        bool registered = false;
        std::shared_ptr<const CjguiOhosEditOwnerReceipt> inputOwner;
        std::vector<uint64_t> inputPrefix;
        uint64_t ownerBinding=0;
        uint64_t inputGeneration=0;
        bool retainedByFocus=false;
        std::vector<uint64_t> inputGenerations;
        int64_t inputDeadline=0;
        CjguiOhosPendingFocusSource pendingFocusSource;
    } transfer;
    uint64_t issue(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) {
        if (!foreground) return 0;
        const bool sameLiveTarget = active && node == n && resource == r && kind == k && binding == b && field == f;
        const auto previousMount = mounted;
        auto retained = sameLiveTarget && transfer.retainedByFocus ? transfer : Transfer{};
        ++generation; active = true; node = n; resource = r; kind = k; binding = b; field = f;
        mounted = sameLiveTarget ? previousMount : CjguiOhosProxyKey{};
        reservedProxy = {};
        transfer=std::move(retained);
        if(transfer.retainedByFocus)transfer.generation=generation;
        return generation;
    }
    bool eligible(uint64_t expected) const { return foreground && active && expected && expected == generation; }
    bool target(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) const {
        return eligible(generation) && n == node && r == resource && k == kind && b == binding && f == field;
    }
    bool continueOwnedTarget(uint64_t n, int64_t r, uint32_t k, uint64_t b, const std::string &f) {
        if (!eligible(generation) || r != resource || f != field) return false;
        // This is called only after the accepted owned declaration and geometry checks.
        node = n; kind = k; binding = b; return true;
    }
    bool bind(const CjguiOhosProxyKey &key) {
        if (!eligible(generation) || !key.valid()) return false;
        if (mounted.valid()) return mounted == key;
        if (transfer.pendingFocusSource.valid() &&
            (!transfer.registered || transfer.generation != generation ||
             key.app != transfer.pendingFocusSource.app || key.session != transfer.pendingFocusSource.session ||
             key.context != transfer.targetContext || key.edit != transfer.targetEdit)) return false;
        mounted = key; reservedProxy = {}; return true;
    }
    bool reserveProxy(const CjguiOhosProxyKey &key) {
        if (!eligible(generation) || !key.valid()) return false;
        if (mounted.valid()) return mounted == key;
        if (reservedProxy.valid()) return reservedProxy == key;
        if (!transfer.operation || !transfer.registered || transfer.generation != generation ||
            transfer.targetContext != key.context || transfer.targetEdit != key.edit) return false;
        if (transfer.pendingFocusSource.valid() &&
            (key.app != transfer.pendingFocusSource.app || key.session != transfer.pendingFocusSource.session)) return false;
        if (transfer.old.valid() && (key.app != transfer.old.app || key.session != transfer.old.session)) return false;
        reservedProxy = key; return true;
    }
    bool proxyEligible(const CjguiOhosProxyKey &key,uint64_t expected) const {
        return permits(key,expected) || (eligible(expected) && reservedProxy.valid() && reservedProxy == key);
    }
    bool componentMounted(const CjguiOhosProxyKey &key,uint64_t expected) {
        if (permits(key,expected)) return true;
        return eligible(expected) && reservedProxy.valid() && reservedProxy == key && bind(key);
    }
    bool permits(const CjguiOhosProxyKey &key, uint64_t expected) const {
        return eligible(expected) && mounted.valid() && mounted == key;
    }
    bool preparePendingMount(uint64_t app, uint64_t session, int64_t context, uint64_t edit) {
        if (!eligible(generation) || !app || !session || context <= 0 || !edit ||
            mounted.valid() || transfer.old.valid()) return false;
        if (transfer.pendingFocusSource.valid()) {
            return transfer.generation == generation && transfer.pendingFocusSource.app == app &&
                transfer.pendingFocusSource.session == session && transfer.targetContext == context &&
                transfer.targetEdit == edit;
        }
        transfer = {++operationSeq, generation, 0, context, 0, edit, {}, false};
        transfer.pendingFocusSource = {app, session, edit, generation, context};
        return true;
    }
    void prepareTransfer(int64_t context, uint64_t edit, uint64_t request, int64_t deadline) {
        if (!eligible(generation) || context <= 0 || !edit) return;
        if (reservedProxy.valid() && (reservedProxy.context != context || reservedProxy.edit != edit)) reservedProxy = {};
        // Keep the first mounted predecessor while native advances before the UI can unmount.
        if (!mounted.valid() && !transfer.old.valid()) {
            if (!transfer.pendingFocusSource.valid() || transfer.generation != generation) return;
            if (transfer.targetContext != context || transfer.targetEdit != edit) {
                transfer.operation = ++operationSeq;
                transfer.targetContext = context; transfer.targetEdit = edit;
                transfer.registered = false;
            }
            if (!transfer.restoreRequest && request) transfer.restoreRequest = request;
            if (deadline > 0 && (!transfer.deadline || deadline < transfer.deadline)) transfer.deadline = deadline;
            return;
        }
        if (mounted.valid()) {
            auto prefix=transfer.retainedByFocus && transfer.old==mounted ? transfer : Transfer{};
            transfer = {++operationSeq, generation, request, context, deadline, edit, mounted, false};
            transfer.inputOwner=std::move(prefix.inputOwner);transfer.inputPrefix=std::move(prefix.inputPrefix);
            transfer.inputGenerations=std::move(prefix.inputGenerations);transfer.inputGeneration=prefix.inputGeneration;
            transfer.ownerBinding=prefix.ownerBinding;transfer.inputDeadline=prefix.inputDeadline;
            transfer.retainedByFocus=prefix.retainedByFocus;
        } else if(transfer.targetContext!=context || transfer.targetEdit!=edit) {
            // Another real structural target is a new operation. A retired
            // component cannot carry the former request into this target.
            transfer.operation=++operationSeq;transfer.generation=generation;
            transfer.restoreRequest=request;transfer.targetContext=context;transfer.targetEdit=edit;
            transfer.registered=false;
            if(!transfer.deadline || (deadline>0 && deadline<transfer.deadline))transfer.deadline=deadline;
        }
        mounted = {};
    }
    // Freeze once at the structural handoff. Later Will arrivals cannot extend
    // this prefix or its deadline. Retired-terminal permission stays separate.
    void freezeInputPrefix(std::shared_ptr<const CjguiOhosEditOwnerReceipt> owner,
        const std::vector<uint64_t> &prefix,uint64_t binding,int64_t deadline,
        const std::vector<uint64_t> &generations={}) {
        if(!eligible(transfer.generation) || !transfer.operation || transfer.inputOwner ||
           prefix.empty() || prefix.size()>32 || !binding || deadline<=0 ||
           (!generations.empty() && generations.size()!=prefix.size()))return;
        transfer.inputOwner=std::move(owner);transfer.inputPrefix=prefix;transfer.ownerBinding=binding;
        transfer.inputGeneration=transfer.generation;
        transfer.inputGenerations=generations.empty()?std::vector<uint64_t>(prefix.size(),transfer.generation):generations;
        if(!transfer.inputDeadline || deadline<transfer.inputDeadline)transfer.inputDeadline=deadline;
    }
    bool permitsTransferredInput(const CjguiOhosProxyKey &key,uint64_t expected,
        uint64_t ticket,uint64_t binding,int64_t now) const {
        const auto at=std::find(transfer.inputPrefix.begin(),transfer.inputPrefix.end(),ticket);
        const size_t index=static_cast<size_t>(at-transfer.inputPrefix.begin());
        const uint64_t original=transfer.inputGenerations.empty() ?
            (transfer.inputGeneration?transfer.inputGeneration:transfer.generation) :
            (index<transfer.inputGenerations.size()?transfer.inputGenerations[index]:0);
        return eligible(transfer.generation) && expected==original &&
            transfer.inputGeneration &&
            transfer.old==key && transfer.ownerBinding==binding && now<transfer.inputDeadline &&
            at!=transfer.inputPrefix.end();
    }
    // Completion permission for an already admitted FIFO prefix, never new Will authority.
    // The caller freezes the registry's original IDs before issuing the new gesture.
    bool retainAdmittedInput(const CjguiOhosProxyKey &key,uint64_t original,
        const std::vector<uint64_t> &prefix,uint64_t binding,int64_t deadline) {
        if(prefix.empty())return true;
        if(!eligible(generation) || !key.valid() || !(mounted==key) || !original ||
           original>=generation || prefix.size()>32 || !binding || deadline<=0)return false;
        if(!transfer.inputPrefix.empty()) {
            if(!transfer.retainedByFocus || !(transfer.old==key) || transfer.ownerBinding!=binding ||
               transfer.inputGenerations.size()!=transfer.inputPrefix.size())return false;
            size_t extra=0;
            for(auto id:prefix)if(std::find(transfer.inputPrefix.begin(),transfer.inputPrefix.end(),id)==transfer.inputPrefix.end())++extra;
            if(extra>32-transfer.inputPrefix.size())return false;
            for(auto id:prefix)if(std::find(transfer.inputPrefix.begin(),transfer.inputPrefix.end(),id)==transfer.inputPrefix.end()) {
                transfer.inputPrefix.push_back(id);transfer.inputGenerations.push_back(original);
            }
            return true; // The first completion deadline never renews on another gesture.
        }
        transfer.generation=generation;transfer.old=key;transfer.inputGeneration=original;
        transfer.inputPrefix=prefix;transfer.ownerBinding=binding;transfer.inputDeadline=deadline;
        transfer.inputGenerations.assign(prefix.size(),original);
        transfer.retainedByFocus=true;
        return true;
    }
    uint64_t registerTransfer(const CjguiOhosProxyKey &old, uint64_t expected, int64_t targetContext, uint64_t targetEdit) {
        if (!old.valid() || !transfer.old.valid() || !eligible(expected) || !transfer.operation || transfer.generation != expected ||
            !(transfer.old == old) || transfer.targetContext != targetContext || transfer.targetEdit != targetEdit) return 0;
        transfer.registered = true; return transfer.operation;
    }
    uint64_t registeredTransfer(const CjguiOhosProxyKey &old,uint64_t expected,int64_t context,uint64_t edit) const {
        return old.valid() && transfer.old.valid() && eligible(expected) && transfer.registered && transfer.generation==expected &&
            transfer.old==old && transfer.targetContext==context && transfer.targetEdit==edit ? transfer.operation : 0;
    }
    bool retiredTerminal(const CjguiOhosProxyKey &key, uint64_t expected) const {
        return key.valid() && transfer.old.valid() && transfer.registered && transfer.generation == expected && transfer.old == key;
    }
    uint64_t registerPendingTransfer(const CjguiOhosPendingFocusSource &source,
        int64_t context, uint64_t edit) {
        if (mounted.valid() || !source.valid() || !eligible(source.focus) || !transfer.operation ||
            transfer.generation != source.focus || !(transfer.pendingFocusSource == source) ||
            transfer.old.valid() || transfer.targetContext != context || transfer.targetEdit != edit) return 0;
        transfer.registered = true;
        return transfer.operation;
    }
    uint64_t registeredPendingTransfer(const CjguiOhosPendingFocusSource &source,
        int64_t context, uint64_t edit) const {
        return !mounted.valid() && source.valid() && eligible(source.focus) && transfer.operation && transfer.registered &&
            transfer.generation == source.focus && transfer.pendingFocusSource == source &&
            !transfer.old.valid() && transfer.targetContext == context && transfer.targetEdit == edit ?
            transfer.operation : 0;
    }
    bool revoke(uint64_t expected) {
        if (!active || expected != generation) return false;
        active = false; mounted = {}; reservedProxy = {}; transfer={}; return true;
    }
    void setForeground(bool value) { foreground = value; if (!value) revoke(generation); }
};
#endif
