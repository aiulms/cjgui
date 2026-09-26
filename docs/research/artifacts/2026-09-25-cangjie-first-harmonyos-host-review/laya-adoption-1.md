# Laya adoption 1

Decision: not adopted.

The route answer selected `pure_cangjie_now` with low confidence (`0.2136`),
but that route contradicts two hard, reproducible constraints: the Cangjie
`XComponent` import does not compile, and no documented Cangjie-to-Native mount
handle is available. The gap answer selected `insufficient`, also at low
confidence (`0.2887`). Laya is a classifier, not a public-API or runtime proof;
the build and header evidence remains authoritative.

Useful signal retained: the high `insufficient` probability on the gap question
warns that the initial candidate set was incomplete. That led to explicitly
investigating the documented pure-Cangjie Canvas route.
