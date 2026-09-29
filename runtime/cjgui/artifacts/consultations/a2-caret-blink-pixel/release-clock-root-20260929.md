# A2 normal-build caret clock

The product visual window first remained pixel-identical across 28 captures after
the binding-epoch repair. A temporary, environment-gated native trace of that
normal build showed an eligible focused node 1000, a shared accepted/view node,
declared rect `(252.685,87,1.5,21)`, and a scheduled timer, but `t=0` and a
deadline of `530000` microseconds at every declaration. Raw trace:
`/Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/builds/run-20260929-132807-87656.log`
(lines 606–640). The trace instrumentation was removed after diagnosis.

Cause: `CjguiMonotonicMicros()` is deliberately a constant-zero macro in a
normal renderer build because it is for interval probes. The caret clock used
that probe function, so every timer wake read zero and never advanced phase.
The caret now calls an independent `mach_continuous_time()` based clock. The
old queued-timer binding-epoch risk is separately fixed by resetting the
generation at actual owned-session rebind and reconciling epoch before the
`scheduled` early return.

The non-TESTING release-clock test was RED with `0 -> 0` and GREEN with an
advancing clock. Raw outputs: `native-release-clock-red-20260929.log` and
`native-release-clock-green-20260929.log`. The binding-epoch case was RED
with `binding change stranded queued blink timer` and GREEN after the fix;
the GREEN raw output is `native-epoch-green-20260929.log`.
The final targeted test also calls the public native rebind setter with a
queued old timer and no later caret declaration; it retires the old generation
and installs the new epoch. Raw result:
`native-binding-setter-green-20260929.log`.

Final normal product visual evidence:
`/Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/a2-caret-final-20260929/visual/real-clock-frames/samples.json`
and `artifacts/builds/run-20260929-133058-89923.log`. The normal app binary
SHA-256 was `88c236228f0b815612886b7b3ebf97ae30783c8f601449ba44c955bcea6b1571`.
Thirty real window captures have exactly two whole-window hashes; phase changes are confined to
pixel bbox `(617,314,620,356)`, alternating fourteen times. The accepted
geometry remains `(252.684825,87,1,21)` and six text raster/upload counters
show zero difference from the settled same-session baseline at turns 70–220.
After the session was unlocked, the same binary passed source-window acceptance:
`/Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/a2-caret-final-20260929/source/real-clock-frames/samples.json`
and `artifacts/builds/run-20260929-160115-76193.log`. Twenty-eight captures
have exactly two whole-window hashes and fourteen transitions, confined to
pixel bbox `(546,368,548,402)`. The accepted source caret used the normal
input node and the full owner fixture `**甲乙🙂丙丁**\n`; the six text
raster/upload counters stayed unchanged from the same-session baseline.

After activating Finder, the source-window defocus capture
`/Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/a2-caret-final-20260929/source/defocused-frames/samples.json`
has eighteen identical whole-window frames and no transition after settling.
The native log has no subsequent periodic frame submission. Visual and source
captures are synthetic-CGEvent normal-window runs, not physical input; the
visual-specific defocus was not separately captured.
