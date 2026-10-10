// Standing freeze→submit counterexample driver (plain main, cjc-linked).
// Drives the REAL extracted decide/apply/freeze/submit/verify with stub
// scene/session/FFI. exit 0 = all shapes hold; nonzero = mechanism broken.
//
// Source contract: bind only REUSES a proven-equivalent source (same node,
// same D, same mirror text/version/context); otherwise it retires to pending
// and the record is (re)published by a lawful candidate freeze + same-ticket
// success (stageAndPromote models exactly that). No present-less bind ever
// promotes a new source onto an old D.
func hasSource(w: PresentationSourceHarnessWindow): Bool {
    return match (w.currentSource()) {
        case Some(_) => true
        case None => false
    }
}

func check(name: String, cond: Bool): Int64 {
    if (!cond) {
        println("CASE_FAIL ${name}")
        return 1
    }
    println("CASE_OK ${name}")
    return 0
}

func snapshotSel(w: PresentationSourceHarnessWindow): (Int64, Int64, Int64, Bool, String) {
    if (let Some(s) <- w.ownedTextSession) {
        return (s.selStart16, s.selEnd16, s.selectionVersion, s.restoreMarked, s.owner.body)
    }
    return (-9, -9, -9, false, "?")
}

// candidate build + original-ticket success: decide now, apply on success.
func stageAndPromote(w: PresentationSourceHarnessWindow): (Int64, Bool) {
    let d = w.decideCandidatePresentationSource(w.nativeInputScene)
    w.applyCandidatePresentationSource(d[0], d[1])
    return (d[0], hasSource(w))
}

main(): Int64 {
    var failures: Int64 = 0

    // 1 control: bind M(éA/v1) → pending (bind never promotes); lawful
    // candidate+success publishes → freeze → submit 0.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        failures += check("control-bind-pending", !hasSource(w))
        let st = stageAndPromote(w)
        failures += check("control-decide-promote", st[0] == 1 && st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("control-freeze-ticket", match (t) {
            case Some(v) => v.mirrorText == "éA" && v.mirrorVersion == 1
            case None => false
        })
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("control-submit-ok", r[0] == 0 && r[1] == 1 && r[2] == 1)
        let s = snapshotSel(w)
        failures += check("control-selection-set", s[0] == 1 && s[1] == 1 && s[2] == 1 && s[3])
    }

    // 2 M-before, no record: bind M(AB/v2), candidate D=éA → clear → freeze None.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "AB", 2)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("m-before-decide-clear", st[0] == 2 && !st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("m-before-freeze-none", match (t) {
            case Some(_) => false
            case None => true
        })
        let s = snapshotSel(w)
        failures += check("m-before-zero-write", s[2] == -1 && !s[3])
    }

    // 3 M-before with record, no new candidate: publish (éA,v1) by lawful
    // accept; M→(AB,v2) without staging; freeze reads the kept record basis
    // (éA,1); submit vs live (AB,2) → 5 + zero writes.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("m-before-record-published", st[0] == 1 && match (w.currentSource()) {
            case Some(r) => r.mirrorText == "éA" && r.mirrorVersion == 1
            case None => false
        })
        w.advanceMirror("AB", 2)
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let basisOk = match (t) {
            case Some(v) => v.mirrorText == "éA" && v.mirrorVersion == 1
            case None => false
        }
        failures += check("m-before-ticket-kept-basis", basisOk)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("m-before-submit-refuse5", r[0] == 5)
        let s = snapshotSel(w)
        failures += check("m-before-zero-write", s[2] == -1 && !s[3] && s[4] == "AB")
    }

    // 3b M-before with a new candidate: candidate D(éA) no longer matches
    // live mirror (AB) → decide clear → record cleared → freeze None.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("m-before2-published", st[0] == 1 && st[1])
        w.advanceMirror("AB", 2)
        let d = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("m-before2-decide-clear", d[0] == 2)
        w.applyCandidatePresentationSource(d[0], d[1])
        failures += check("m-before2-record-cleared", !hasSource(w))
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("m-before2-freeze-none", match (t) {
            case Some(_) => false
            case None => true
        })
        let s = snapshotSel(w)
        failures += check("m-before2-zero-write", s[2] == -1 && !s[3])
    }

    // 4 same bytes, version moved before freeze: record (éA,v1); M→(éA,v3).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("same-bytes-published", st[0] == 1 && st[1])
        w.advanceMirror("éA", 3)
        let d = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("same-bytes-decide-keep", d[0] == 0)
        w.applyCandidatePresentationSource(d[0], d[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("same-bytes-submit-refuse6", r[0] == 6)
        let s = snapshotSel(w)
        failures += check("same-bytes-zero-write", s[2] == -1 && !s[3])
    }

    // 5 M-after-freeze: freeze first, then advance → submit 5 + zero writes.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("m-after-published", st[0] == 1 && st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        w.advanceMirror("AB", 2)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("m-after-submit-refuse5", r[0] == 5)
        let s = snapshotSel(w)
        failures += check("m-after-zero-write", s[2] == -1 && !s[3] && s[4] == "AB")
    }

    // 6 pending pollution: decideA frozen; M advances; candidateB decided;
    // txA succeeds with FROZEN decision (not live re-read) → record (éA,v1).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("pending-published", st[0] == 1 && st[1])
        let dA = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("pending-decideA-keep", dA[0] == 0)
        w.advanceMirror("AB", 2)
        let dB = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("pending-decideB-clear", dB[0] == 2)
        w.applyCandidatePresentationSource(dA[0], dA[1])
        let recOk = match (w.currentSource()) {
            case Some(r) => r.mirrorText == "éA" && r.mirrorVersion == 1
            case None => false
        }
        failures += check("pending-record-unpolluted", recOk)
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("pending-submit-refuse5", r[0] == 5)
    }

    // 7 failure keeps old: record (éA,v1); txB decided promote but settle fails
    // (apply never called) → record still (éA,v1).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("failure-published", st[0] == 1 && st[1])
        w.advanceMirror("新", 4)
        w.setDisplay("新")
        let dB = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("failure-decideB-promote", dB[0] == 1)
        // settle fails → apply NOT called (rollback path touches nothing).
        let recOk = match (w.currentSource()) {
            case Some(r) => r.mirrorText == "éA" && r.mirrorVersion == 1
            case None => false
        }
        failures += check("failure-record-kept", recOk)
    }

    // 8 unproven transform: candidate D=X≠mirror → clear → freeze None.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        w.setDisplay("X")
        let st = stageAndPromote(w)
        failures += check("transform-decide-clear", st[0] == 2 && !st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("transform-freeze-none", match (t) {
            case Some(_) => false
            case None => true
        })
    }

    // 9 legal republish (external SET): record (éA,v1); D+M → (新,v4) →
    // promote → freeze → submit 0.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st0 = stageAndPromote(w)
        failures += check("republish-published", st0[0] == 1 && st0[1])
        w.advanceMirror("新", 4)
        w.setDisplay("新")
        let st = stageAndPromote(w)
        failures += check("republish-decide-promote", st[0] == 1 && st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("republish-submit-ok", r[0] == 0)
        let s = snapshotSel(w)
        failures += check("republish-selection-set", s[2] == 4 && s[3])
    }

    // 10 interaction inherit: record (éA,v1); repaint path calls no decide/apply
    // → record unchanged → freeze still carries (éA,1).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("inherit-published", st[0] == 1 && st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("inherit-ticket-basis", match (t) {
            case Some(v) => v.mirrorText == "éA" && v.mirrorVersion == 1
            case None => false
        })
    }

    // 11 native generation moved after freeze: ticket scene 7 vs current 99
    // → submit refuses 3 through the real submit entry (query gate covered
    // by the native scene test; this covers the submit-side generation check).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("query-published", st[0] == 1 && st[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        unsafe { stub_set_scene_gen(99u64) }
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("query-submit-refuse3", r[0] == 3)
        let s = snapshotSel(w)
        failures += check("query-zero-write", s[2] == -1 && !s[3])
        unsafe { stub_set_scene_gen(7u64) }
    }

    // R1 bind-away: publish (AB,v2) by lawful accept; switch to 24
    // (node miss → clear); freeze(25) has no record → None; zero writes.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.setDisplay("AB")
        w.bind(25, "AB", 2)
        let st = stageAndPromote(w)
        failures += check("raway-published", st[0] == 1 && match (w.currentSource()) {
            case Some(r) => r.mirrorText == "AB" && r.mirrorVersion == 2
            case None => false
        })
        w.bind(24, "AB", 2)
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("raway-freeze-none", match (t) {
            case Some(_) => false
            case None => true
        })
        let s = snapshotSel(w)
        failures += check("raway-zero-write", s[2] == -1 && !s[3])
    }

    // B0 carry-rebind-immediate: published (AB,v2); direct rebind with
    // identical facts → carry with the new epoch → freeze/submit pass
    // WITHOUT any staged candidate in between (device steady state).
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.setDisplay("AB")
        w.bind(25, "AB", 2)
        let st = stageAndPromote(w)
        failures += check("carry-published", st[0] == 1 && st[1])
        w.bind(25, "AB", 2)
        let carried = match (w.currentSource()) {
            case Some(r) => r.mirrorText == "AB" && r.mirrorVersion == 2 &&
                r.bindingEpoch == w.textSessionBindingEpoch
            case None => false
        }
        failures += check("carry-record-reatttached", carried)
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("carry-submit-ok", r[0] == 0)
        let s = snapshotSel(w)
        failures += check("carry-selection-set", s[2] == 2 && s[3])
    }

    // B1 rebind-with-advanced-mirror refuses with zero writes (the closed
    // bypass, GREEN expectation): published (AB,v1); direct rebind whose
    // mirror advanced to v2 (same bytes) → retire → freeze None.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.setDisplay("AB")
        w.bind(25, "AB", 1)
        let st = stageAndPromote(w)
        failures += check("b1-published", st[0] == 1 && st[1])
        w.bind(25, "AB", 2)
        failures += check("b1-retired", !hasSource(w))
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        failures += check("b1-freeze-none", match (t) {
            case Some(_) => false
            case None => true
        })
        let s = snapshotSel(w)
        failures += check("b1-zero-write", s[2] == -1 && !s[3])
    }

    // B2 unchanged rebind succeeds after lawful accept (R2, the drag shape):
    // published (AB,v2); away clears; bind back retires; the tap-triggered
    // refresh-present republishes → freeze/submit pass.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.setDisplay("AB")
        w.bind(25, "AB", 2)
        let st = stageAndPromote(w)
        failures += check("rback-published", st[0] == 1 && st[1])
        w.bind(24, "AB", 2)
        failures += check("rback-away-cleared", !hasSource(w))
        w.bind(25, "AB", 2)
        failures += check("rback-bind-pending", !hasSource(w))
        let st2 = stageAndPromote(w)
        failures += check("rback-republished", st2[0] == 1 && st2[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let basisOk = match (t) {
            case Some(v) => v.mirrorText == "AB" && v.mirrorVersion == 2
            case None => false
        }
        failures += check("rback-ticket-fresh-basis", basisOk)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("rback-submit-ok", r[0] == 0)
        let s = snapshotSel(w)
        failures += check("rback-selection-set", s[2] == 2 && s[3])
    }

    // B3 same-bytes new version recovers after a REAL new-D publish:
    // continue from a retired B1 state; candidate D==mirror(v2) → promote →
    // freeze/submit pass with v2 registered.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.setDisplay("AB")
        w.bind(25, "AB", 1)
        let st0 = stageAndPromote(w)
        failures += check("b3-published-v1", st0[0] == 1 && st0[1])
        w.bind(25, "AB", 2)
        failures += check("b3-retired", !hasSource(w))
        let st = stageAndPromote(w)
        failures += check("b3-republish-promote", st[0] == 1 && match (w.currentSource()) {
            case Some(r) => r.mirrorText == "AB" && r.mirrorVersion == 2
            case None => false
        })
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("b3-submit-ok", r[0] == 0)
        let s = snapshotSel(w)
        failures += check("b3-selection-set-v2", s[2] == 2 && s[3])
    }

    // B4 old PENDING never produces a false accept on the new binding.
    // half 1: a late keep-decision keeps the carried record → submit passes.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let st = stageAndPromote(w)
        failures += check("b4-published", st[0] == 1 && st[1])
        let dOld = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("b4-staged-keep", dOld[0] == 0)
        w.bind(25, "éA", 1)
        failures += check("b4-carried", match (w.currentSource()) {
            case Some(r) => r.mirrorText == "éA" && r.mirrorVersion == 1 &&
                r.bindingEpoch == w.textSessionBindingEpoch
            case None => false
        })
        w.applyCandidatePresentationSource(dOld[0], dOld[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("b4-keep-submit-ok", r[0] == 0)
    }
    // half 2: a late STALE promote-decision can only refuse, never register.
    if (true) {
        let w = PresentationSourceHarnessWindow()
        w.bind(25, "éA", 1)
        unsafe { stub_set_scene_gen(7u64) }
        let dStale = w.decideCandidatePresentationSource(w.nativeInputScene)
        failures += check("b4-staged-promote", dStale[0] == 1)
        w.advanceMirror("AB", 2)
        w.bind(25, "AB", 2)
        failures += check("b4-retired", !hasSource(w))
        w.applyCandidatePresentationSource(dStale[0], dStale[1])
        let t = w.freezePresentationHit(25, 2.0, 0.0)
        let r = match (t) {
            case Some(v) => w.submitPresentationSelection(25, v, v)
            case None => (9, -1, -1)
        }
        failures += check("b4-stale-refuses", r[0] != 0)
        let s = snapshotSel(w)
        failures += check("b4-stale-zero-write", s[2] == -1 && !s[3])
    }

    if (failures == 0) {
        println("ALL_SOURCE_CASES_HOLD")
    } else {
        println("SOURCE_CASES_FAILED ${failures}")
    }
    return failures
}
