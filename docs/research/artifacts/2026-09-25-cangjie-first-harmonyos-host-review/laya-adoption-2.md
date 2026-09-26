# Laya adoption 2

Decision: route recommendation not adopted; candidate discovery retained.

Laya strongly preferred `switch_to_canvas_now` (`0.9491`, confidence `0.816`),
but the available evidence proves only compilation and packaging. It does not
prove runtime rendering, CJGUI command coverage, Chinese text, input, frame
pacing, lifecycle recovery, or performance. Immediate replacement would lower
the acceptance standard.

The result is retained as a reason to run a bounded Canvas spike, not to change
the current delivery route. The `canvas_status` answer itself was
`insufficient` with very low confidence (`0.0881`), which is consistent with
keeping the label `candidate, not equivalent` until experiments decide.
