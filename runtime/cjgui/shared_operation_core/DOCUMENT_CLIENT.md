# Typed document client

`cjgui_document_client.py` is an experimental typed layer over the existing
descriptor-gated `SharedOperationClient`. It provides document targets,
UTF-8 range reads, and one-shot range replacement without adding a second
transport, history, or owner state.

## Scope and versions

Use this client only with a provider that explicitly guarantees that a
`text_document` resource ID is never rebound during the endpoint lifetime, such
as `CjguiTextDocumentWorkspace`. The workspace may add and close business
documents at runtime: every open receives a new ID, a closed ID is retired, and
a later open of the same path is a new instance. The shared-operation protocol
does not atomically bind an ordinary `INVOKE` to a resource instance or stream,
so this client cannot make arbitrary dynamically rebound providers safe. It
rejects a changed descriptor binding locally before sending a request.

Discover a new resource through the application's existing change feed or
current context; do not infer it from list position, title, path, or the most
recent selection. `startup` uses `GET_CONTEXT`; after a runtime open, a caller
can use `GET_CHANGES` and the `document_opened` entry (or a fresh `GET_CONTEXT`)
and then pass that exact numeric ID to `target`. The typed client validates the
resource kind and never guesses an ID.

A newly opened document is granted to the existing external connection by the
application when it opened the document. `target` reads the live
`AUTH_SCOPE` response, so a target created before the grant is unavailable
until the caller explicitly requests a new target. A target obtained for a
closed document is rejected by the provider; do not substitute a same-path or
same-title document.

## Runtime open, close, and reopen

The ordinary application owns file/path admission and the human lifecycle
actions. The public client does not open arbitrary paths. After an application
open, the exact new ID appears in `GET_CHANGES` as `document_opened` and in the
next `GET_CONTEXT`; after a close, the same ID reports `document_closed` and a
retained target write is refused. A reopen of the same file is a fresh
instance with a fresh ID, even when its document version is again zero.

Closing one document must not invalidate another target. Retained targets for
sibling documents keep their own document version; the workspace aggregate
version can change for unrelated lifecycle events and is not a document
version. When a document is closed, its ID is retired for the endpoint
lifetime, so an old request cannot reach a later instance.

`target(resource_id)` returns an immutable snapshot of that resource's current
document version, byte length, endpoint and stream identity, and action
declarations/authorization. Pass that same target to `read` and `replace`.
The client never refreshes it. `document_version` is the version domain for
document ranges and replacements; `aggregate_version` describes the broader
context and must not be substituted. Projection versions are separate and may
be unavailable.

## Read and replace

Each `read` is limited to 64 KiB and validates the resource, requested range,
response range, document version, availability, and UTF-8 byte count. A short
document can be read in one call:

```python
from client import SharedOperationClient
from cjgui_document_client import DocumentClient

transport = SharedOperationClient.from_descriptor(descriptor_path)
documents = DocumentClient(
    transport, binding_contract="fixed_text_document_workspace"
)

# Both IDs were observed in this application's current context.
target_a = documents.target(resource_a)
target_b = documents.target(resource_b)

def read_short(target):
    if target.byte_length > 64 * 1024:
        raise ValueError("this example reads short documents in one range")
    result = documents.read(target, 0, target.byte_length)
    if (not result.available or result.conflict or result.content is None
            or result.version != target.document_version
            or len(result.content.encode("utf-8")) != target.byte_length):
        raise RuntimeError(f"read failed: {result.reason}")
    return result.content

body_a = read_short(target_a)
body_b = read_short(target_b)

# Uses A's retained target and is sent once. Surface conflict/unknown; do not resend.
mutation = documents.replace(target_a, start, end, replacement)
if mutation.outcome in ("conflict", "unknown"):
    print(mutation.outcome, mutation.reason)

# A separate read proves B still matches its own retained document version.
if read_short(target_b) != body_b:
    raise RuntimeError("B changed")
```

For longer documents, request bounded ranges using one retained target and
valid UTF-8 byte boundaries. An unavailable or conflicting range is returned
as an outcome; do not refresh and resend as an implicit retry. `replace`
returns `applied`, `conflict`, `rejected`, or `unknown`, with its version domain
when known. `unknown` does not prove that no write occurred.

After a mutation, a caller may explicitly request a new target if it chooses to
observe the latest document. That is a separate operation and must not be used
to convert a conflict or unknown outcome into an automatic retry. The same rule
applies after a runtime open or close: obtain a new target from the change
feed/current context, never rebind a retained target by similarity.

## Public lifecycle open and close

An application may install a lifecycle policy for the public `OPEN_DOCUMENT`
and `CLOSE_DOCUMENT` actions. The application still decides which paths are
eligible and which live documents are granted close authority; the transport
and workspace only route the declared action, the exact target, and its
expected document version.

`OPEN_DOCUMENT` takes zero targets and zero arguments. It consumes one path
that the application already queued (for example through its own launch or
authorization input), never an arbitrary path supplied by the caller. A
successful result appends one `document_opened` change. Use that change, not
the most recent selection or a title, to obtain the exact new resource ID:

```python
opened = documents.open_authorized()
if opened.outcome != "applied":
    raise RuntimeError(f"open refused: {opened.reason}")
new_id = documents.document_opened_since(opened.version_before)
new_target = documents.target(new_id)
```

`CLOSE_DOCUMENT` takes exactly one explicit target and an optional `decision`.
`expected_version` is that document's version. A mismatch is a
`version_conflict` and the document remains open. For a dirty document a
missing decision (or `close`) is refused with `unsaved_decision_required`;
nothing is discarded by default. `save` saves through that document's own file
binding and only closes after a successful save; `discard` is an explicit
decision; `cancel` returns `close_cancelled` without side effects. An unknown,
retired, or unauthorized target is refused by name and never falls back to the
current selection.

```python
closed = documents.close(retained_target, decision="save",
                         expected_version=retained_target.document_version)
if closed.outcome not in ("applied", "rejected", "conflict"):
    raise RuntimeError(f"close outcome unknown: {closed.reason}")
```

A retired document's dynamic action grants are removed together with its
body, history, and file association. Static application scopes are unchanged,
so a retained sibling target keeps its own authorization, body, and version.
An old target of the closed document is refused (`document_closed` or
`unknown_resource`) even if the same path is immediately reopened as a new
resource.

One live document owns one `CjguiTextDocumentFileBinding`. The workspace
claims the binding before reading a file or attaching it to a document, and
refuses a second live owner with `binding_in_use`. Retirement releases the
claim and clears the binding's trusted baseline; the file on disk is untouched,
and reusing that binding afterwards starts from the new target's file.

## History and saves

`invoke_history(target, "UNDO"|"REDO", expected_version=...)` sends only when
that action is both declared and authorized for the target. This workspace
does not declare external history actions, so the call reports unavailable
without sending an invocation. Undo and redo remain ordinary human-only application operations. File saving
and the dirty-document decision stay owned by the document workspace and its
file binding; granting a newly opened document to the connection does not
widen history or any other action.

## Consumer example

The [shared document window consumer](../examples/shared_document_window_app/README.md)
includes a short client example. A caller outside the exported SDK can pass
the SDK root explicitly; paths may contain spaces and no `PYTHONPATH` is
needed:

```zsh
python3 "/path/to/caller/client.py" \
  --sdk-root "/path/with spaces/Public Document SDK" \
  --descriptor "$DESCRIPTOR" --resource-id "$RESOURCE_ID"
```
