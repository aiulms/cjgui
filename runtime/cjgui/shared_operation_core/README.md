# CJGUI Shared Operation Client

`client.py` is the public Python entry for an application-issued CJGUI shared
operation descriptor. It is deliberately generic: resources, actions and
parameter shapes come from the running application, not from this repository
or a hard-coded consumer list.

## Start a shared-document window

The normal document window starts **without** an external endpoint:

```sh
cd runtime/cjgui/examples/shared_document_window_app
zsh ./run.sh
```

For an explicitly authorized developer session, add `--with-connection` (and
optionally `--file PATH`). The running app prints one `DESCRIPTOR_PATH` line
to its standard output after its private endpoint is ready. It is the only
path a client needs; never guess a socket path or copy a descriptor out of its
private directory.

```sh
zsh ./run.sh --with-connection
# CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH /private/.../connection.cjgui
```

The descriptor contains a capability. Keep its mode `0600`, do not commit it,
and do not paste it into bug reports. `describe --json` deliberately omits the
capability from its output; the legacy plain `describe` form is only for
private local inspection.

## CLI workflow

Run from this directory, substituting the emitted descriptor path. `--json`
keeps response fields ordered and machine-readable while decoding every
`*_UTF8_HEX` field to an additional `text` value.

```sh
python3 client.py "$DESCRIPTOR" --json describe
python3 client.py "$DESCRIPTOR" --json get
python3 client.py "$DESCRIPTOR" --json get --target RESOURCE_ID
python3 client.py "$DESCRIPTOR" --json window-interaction
python3 client.py "$DESCRIPTOR" --json read-range RESOURCE_ID START END DOCUMENT_VERSION
```

`GET_CONTEXT` includes an optional `WINDOW_*` block when the application has a
live composable window. `WINDOW_ACCEPTED_SCENE_VERSION` is the Cangjie scene
the native side accepted; `WINDOW_SUBMITTED_*` identifies a Metal submission;
`WINDOW_METAL_COMPLETED_FRAME_INDEX` advances only for a real completed
readback; and `WINDOW_OVERLAY_DRAWN_SCENE_VERSION` comes from the AppKit
overlay's `drawRect`. None means a person has necessarily seen the pixels:
`WINDOW_PRESENTATION_STATE unavailable` retains that honest platform limit.
`WINDOW_REFRESH_PENDING` and `WINDOW_LAST_NATIVE_FAILURE` describe a retained
temporary failure without converting a read into an implicit retry.

`GET_WINDOW_PROGRESS` is the separately authorized, scalar-only read for a
live window's session/scene/frame progress. It intentionally contains no
resource list, field value, draft, component tree, focus, selection or layer.
After reading
the `WINDOW_SESSION` and the desired scene version, a caller can use the
client’s bounded, read-only wait entrance. It polls `GET_WINDOW_PROGRESS` at a
fixed interval; polling does not trigger build/layout/Metal work in the app.

`GET_WINDOW_INTERACTION` is a second, explicitly granted read for
`WINDOW_INTERACTION_VERSION`, `WINDOW_FOCUS`, optional UTF-16
`WINDOW_SELECTION`, and `WINDOW_ACTIVE_LAYER`. These are interaction identity
and coordinates, never text or domain content. Because a current window focus
or layer cannot be truthfully assigned to an arbitrary narrow resource scope,
the transport emits no interaction facts for an `IDS`-only grant and returns
`unauthorized_resource`; the action needs an `ALL` resource scope. Read
`ACTION` and `AUTH_SCOPE` dynamically rather than assuming either endpoint was
granted by an application.

```sh
python3 client.py "$DESCRIPTOR" wait-window cjgui_window_1 12 \
  --phase overlay --timeout-ms 2000 --poll-ms 100
```

The result line is `WINDOW_WAIT_OUTCOME completed|pending_failure|closed|timeout`.
The CLI returns `7` for timeout, `6` for a closed/replaced session, and `3`
for an outstanding refresh failure. Do not reuse a prior session identity after
a window has closed or reopened.

For an incremental, discardable public projection, use `observe` with an
explicit target scope. The first turn reads a target snapshot. Later turns
read `GET_CHANGES` and re-read only the changed targets; an expired cursor or
changed stream identity performs an explicit target resync. A timeout never
updates the cached projection, and an endpoint loss clears it and returns
`reconnect_required`: supply a fresh app-issued descriptor before resuming.

```sh
python3 client.py "$DESCRIPTOR" --json observe --target RESOURCE_ID \
  --turns 2 --interval-ms 100 --timeout-ms 2000
```

The observer cache is only a local view of resource IDs and wire snapshots;
use `observer.snapshots()` or CLI JSON `resources` to consume its latest
public content. One `observe_once` call has one monotonic timeout budget across
changes, every target reread and an explicit resync. Any timeout, protocol,
authorization or endpoint failure clears its cached view; multiple changed
targets are published together only after all rereads validate. The
application domain remains the source of truth. `GET_CONTEXT` without
`--target` retains its compatible full-context behavior. Explicit unknown
targets return `unknown_resource`; they are not silently replaced with a full
snapshot.

`GET_CONTEXT` may include an optional `STREAM_ID`. Current rule-set and
document owners emit it under the same owner lock/read boundary as `VERSION`
and the resources, so an `initial` or `resynced` observer result is already
bound to its cursor. A stream replacement—including one that resets to a lower
version—causes a resync before version comparison; a target reread must match
both its changes version and stream identity before publication. An older
provider without snapshot `STREAM_ID` remains compatible, but the observer
explicitly reports `snapshot_identity_unavailable` and uses a full resync on
each later turn instead of claiming reliable incremental observation.

Read the dynamic `ACTION`, `PARAMETER`, resource `documentVersion`, and
`positionUnit` fields before invoking an action. Current document positions
are `UTF8_BYTE`: offsets are byte positions and must not cut an accepted text
boundary. The current owner rejects UTF-8 scalar interiors plus CRLF, common
combining-mark/variation-selector/skin-tone and ZWJ adjacency, and pairs
regional indicators from the start of a consecutive run. This is a
conservative profile, not a claim of complete UAX #29 extended-grapheme
segmentation for every Unicode script; clients that need full grapheme-aware
editing must retain their platform segmenter and retry rejected offsets rather
than silently rounding a public replacement range. The normal document app
currently publishes `REPLACE_RANGE` and `REPLACE_RANGES` only for its editable
documents; discovery remains the source of truth for any particular app and
descriptor.

For an ordinary replacement, place multiline input in a file or standard
input rather than putting CJK or shell-newline escaping on the command line:

```sh
python3 client.py "$DESCRIPTOR" --json invoke DOCUMENT_VERSION REPLACE_RANGE \
  --target RESOURCE_ID --arg start=INTEGER:START --arg end=INTEGER:END \
  --arg-file text=/absolute/path/to/replacement.txt

printf '第一行\n第二行🙂' | python3 client.py "$DESCRIPTOR" --json invoke \
  DOCUMENT_VERSION REPLACE_RANGE --target RESOURCE_ID \
  --arg start=INTEGER:START --arg end=INTEGER:END --arg-stdin text
```

For `REPLACE_RANGES`, give the CLI an UTF-8 JSON array rather than encoding a
protocol body yourself. Every item has exactly `start`, `end`, and `text`; its
ranges are sorted original-version `UTF8_BYTE` offsets.

```json
[
  {"start": 3, "end": 6, "text": "A"},
  {"start": 9, "end": 12, "text": "第二处"}
]
```

```sh
python3 client.py "$DESCRIPTOR" --json invoke DOCUMENT_VERSION REPLACE_RANGES \
  --target RESOURCE_ID --arg-replacements-file replacements=/absolute/path/to/replacements.json
```

The client preserves raw protocol text by default for existing scripts. Its
recognizable exit statuses are:

| Status | Meaning |
| --- | --- |
| `0` | operation applied, or range was available |
| `2` | local client/descriptor/input/connection failure |
| `3` | remote protocol or rejected action result |
| `4` | exact-version conflict; re-read before retrying |
| `5` | denied action or resource scope |
| `6` | document was closed |
| `7` | bounded window-progress wait timed out |

An app can revoke a descriptor or close a document while a client is running.
Do not retry a `4`, `5`, or `6` result blindly: rediscover or re-read first;
only an application-issued fresh descriptor can restore a revoked capability.

## Importable API and atomic multi-range replacement

The same framing, descriptor privacy checks, UTF-8 byte accounting, response
parsing and exit-result vocabulary are available to Python callers. One
`REPLACE_RANGES` call uses ranges from one original document version; the
document accepts no overlapping/duplicate ranges, commits all valid ranges
once, and creates one human undo entry.

```python
from client import SharedOperationArgument, SharedOperationClient, TextReplacement

operation = SharedOperationClient.from_descriptor(descriptor_path)
snapshot = operation.get_context()             # discover resource/version first
result = operation.invoke(
    expected_version=document_version,
    action="REPLACE_RANGES",
    targets=[resource_id],
    arguments=[
        SharedOperationArgument.text_replacements("replacements", [
            TextReplacement(start=0, end=3, text="外部"),
            TextReplacement(start=9, end=12, text="第二处"),
        ])
    ],
)
assert result.kind == "RESULT"
```

`TextReplacement` text may contain newlines, Chinese and emoji; the client
encodes the bounded typed argument. Its byte offsets are still the original
document's coordinates, not offsets shifted by earlier entries. Inspect
`APPLIED`, `CONFLICT`, `VERSION_BEFORE`, `VERSION_AFTER`, and `REASON` on the
structured response. A conflict leaves the document and its undo history
unchanged.

The batch wire type is named `TEXT_REPLACEMENTS` in action discovery. It is a
document-specific parameter type, not a general-purpose command channel; use
`TextReplacement` or `--arg-replacements-file` rather than constructing its
encoded body by hand.

## Controlled saves

Saving a bound document uses an adjacent, process-visible `*.cjgui-save-lock`
directory as an exclusive claim. CJGUI instances targeting the same path will
return `save_in_progress` while another save holds that claim; a newly-created
target is never overwritten, and a stale existing-file baseline returns
`external_file_conflict` while keeping the in-memory draft intact.

The external-file check is a conservative comparison, not an operating-system
compare-and-swap primitive. A non-CJGUI process that changes the file after the
last comparison and does not honor the lock can still race the final rename.
For shared ownership, have every writer use the CJGUI binding/lock or a
separate application-level coordinator.

## Fair-scheduling performance baseline

The ordinary headless second consumer also has a **bounded diagnostics mode**
for transport measurements. It keeps the same domain, descriptor and owner
`pump` path as the consumer; queue counters are process-local diagnostics only
and are neither serialized into a descriptor nor exposed to an external
client. Build it once, then run the reusable ten-minute workload plus its
post-close recovery pass:

```sh
cd runtime/cjgui/examples/shared_operation_second_consumer
zsh ./build.sh
python3 ./transport_perf_baseline.py \
  --duration-seconds 600 --sample-seconds 5 --recovery-seconds 15 --idle-seconds 5 \
  --output /tmp/cjgui-transport-perf-600s.json
```

The V2 JSON report records sampled CPU, RSS, process threads and **numeric**
FDs (`lsof -Ff`, excluding entries such as `cwd` and `txt`), request
latency/outcome counts, owner-side accepted/ready queue high-water marks, a
no-peer idle context, and one connected-but-no-frame read-deadline context.
It reports retained task handles separately from loops that have actually
entered I/O; neither number is an operating-system thread count. Its
assertions prove only that this real headless consumer completed public
descriptor exchanges, observed its fixed local loops, and removed its owned
endpoint after each run. They do not prove GUI input, IME, GPU presentation, a
real model, packaging, or release behavior.

## Normal window cost baseline

The packaged rule-set and shared-document applications accept finite
`--measurement-warmup-ms 0..60000` and `--measurement-duration-ms 1..900000`
bounds. They keep the ordinary `CjguiComposableUiWindowTurnScheduler` loops
and close through the normal window/endpoint cleanup path; they do not add a
benchmark state owner. Each normal app reports `WINDOW_READY` only after its
initial native frame was submitted, then emits `MEASUREMENT_START` after the
same explicit warmup. Neither marker claims human-visible presentation.

After building both normal bundles with their respective `run.sh`, a two-round
idle comparison is:

```sh
cd runtime/cjgui
python3 ./examples/window_perf_baseline.py \
  --duration-seconds 60 --warmup-seconds 5 --sample-seconds 1 --rounds 2 \
  --cycles document_no_connection_idle,document_connection_idle,rule_set_connection_idle \
  --output /tmp/cjgui-normal-window-idle-60s-rounds2.json
```

An authorized, disposable mixed-load run is:

```sh
cd runtime/cjgui
python3 ./examples/window_perf_baseline.py \
  --duration-seconds 180 --warmup-seconds 5 --sample-seconds 1 \
  --fixture-record-count 1001 --public-get-interval-ms 100 \
  --cycles rule_set_fixture_full_context,rule_set_fixture_targeted_context,rule_set_fixture_observation \
  --output /tmp/cjgui-rule-read-comparison-180s.json
```

`rule_set_fixture_batch` creates process-local rules, applies an authorized
100-target batch, verifies an intentionally stale version conflict, reads the
targets back, and waits for a later completed Metal frame. `document_edit`
does an in-memory document replacement, verifies the stale conflict and an
exact range readback, then waits for a later completed frame. Neither cycle
opens or modifies a user-owned file. `rule_set_fixture_batch_idle_recovery`
performs the same fixture without the continuous reader when a same-process
quiet-recovery control is needed.

The comparison cycles use the same process-local 1,001-record/100-target
fixture and 100-ms pacing: `full_context` reads a compatible full snapshot,
`targeted_context` asks only for rule `1`, and `observation` uses changes plus
target rereads and the narrow window-progress endpoint. The report records
executable/source hashes, readiness and warmup timing, process CPU/RSS/thread
samples, public-read outcomes/latency and response bytes, business facts, and
the sampled interval after the business action finishes in the same process.
An infinite request loop is a separate high-pressure experiment, not a normal
recovery baseline. Full snapshots include shared build/layout/submission
counters; narrow progress contains only scalar session/scene/frame facts. GPU
completion is not human presentation.

Current machine evidence: two 60-second idle rounds produced six exit-0 cycles
with 60–61 samples each. The paced 180-second mixed run exited 0 for both
windows: the 1,001-record rule fixture completed its batch/conflict/readback
and later frame; it served 1,081 full snapshots at p95 145.653 ms and used
26.3–91.3% CPU after the business action. The same fixture without the reader
used 0.9–30.6% CPU in its recovery interval. The paced document cycle served
1,479 snapshots at p95 24.643 ms with 1.0–3.9% CPU. These are current-machine
measurements, not a portability, release, or human-presentation claim.

The runner drains both child output streams while it runs and retains only the
last 64 KiB of stderr. This prevents native diagnostic output from blocking a
normal child process through a full pipe; it does not suppress or reinterpret
the child's diagnostic stream.
