"""Experimental explicit-version client for fixed-binding text_document workspaces.

The existing protocol does not atomically bind INVOKE to a resource instance or
stream. Use only where the provider guarantees that a resource ID cannot be
rebound during the endpoint lifetime (such as CjguiTextDocumentWorkspace).
This adapter cannot establish that guarantee for arbitrary providers.
"""
from dataclasses import dataclass, field
from typing import Optional
from hashlib import sha256
from functools import wraps
from threading import RLock
from types import MappingProxyType
from client import SharedOperationArgument, SharedOperationClient, IDENTIFIER, OPAQUE_IDENTITY

class DocumentProtocolError(ValueError):
    pass

class DocumentUnsupportedError(DocumentProtocolError):
    pass

class DocumentUnavailableError(DocumentProtocolError):
    pass

class DocumentRemoteError(DocumentProtocolError):
    def __init__(self, reason):
        self.reason = reason
        super().__init__(reason)

@dataclass(frozen=True)
class DocumentTarget:
    endpoint_instance: str
    endpoint_bind_generation: int
    stream_id: str
    resource_id: int
    aggregate_version: int
    resource_projection_version: Optional[int]
    document_version: int
    byte_length: int
    selection: Optional[tuple[int, int, int]]
    declared_actions: tuple[str, ...]
    authorized_actions: tuple[str, ...]
    _issuer: object = field(repr=False, compare=False)
    _descriptor_fingerprint: str = field(repr=False, compare=False)

@dataclass(frozen=True)
class DocumentRange:
    available: bool
    conflict: bool
    reason: str
    version: int
    content: Optional[str]

@dataclass(frozen=True)
class DocumentMutation:
    outcome: str  # applied, rejected, conflict, unknown
    reason: str
    version_before: Optional[int] = None
    version_after: Optional[int] = None
    version_domain: str = "unknown"

def _number(value, label):
    if not isinstance(value, int) or isinstance(value, bool) or value < 0 or value > 9223372036854775807:
        raise DocumentProtocolError(f'invalid {label}')
    return value

def _one(response, name):
    value = response.value(name)
    if len(value) != 1 or not value[0]: raise DocumentProtocolError(f'invalid {name}')
    return value[0]

def _field(response, resource, name, kind):
    values = [v for v in response.values('FIELD') if len(v) >= 2 and v[0] == str(resource) and v[1] == name]
    if len(values) != 1 or len(values[0]) < 4 or values[0][2] != kind:
        raise DocumentProtocolError(f'invalid or duplicate {name}')
    v = values[0]
    if kind == 'INTEGER':
        if len(v) != 4 or not v[3].isdigit(): raise DocumentProtocolError(f'invalid {name}')
        return int(v[3])
    if len(v) != 5 or not v[3].isdigit(): raise DocumentProtocolError(f'invalid {name}')
    try: b = bytes.fromhex(v[4]) if v[4] != '-' else b''; text = b.decode('utf-8')
    except (ValueError, UnicodeError) as exc: raise DocumentProtocolError(f'invalid {name}') from exc
    if len(b) != int(v[3]): raise DocumentProtocolError(f'invalid {name}')
    return text

def _serialized(method):
    @wraps(method)
    def call(self, *args, **kwargs):
        with self._lock:
            return method(self, *args, **kwargs)
    return call

class DocumentClient:
    def __init__(self, client, *, binding_contract):
        if binding_contract != 'fixed_text_document_workspace':
            raise DocumentUnsupportedError('unsupported provider binding contract')
        self.client = client
        # Freeze the descriptor used for the actual exchange: an external
        # mutation of its source mapping cannot redirect a pending operation.
        self._transport = (SharedOperationClient(MappingProxyType(dict(client.descriptor)), client.fragment_bytes)
                           if type(client) is SharedOperationClient else client)
        self._lock = RLock()
        self._issuer = object()
        self._known_stream = None
        self._initial_fingerprint = self._fingerprint()
    def _identity(self):
        d = self.client.descriptor
        endpoint = d.get('endpoint_instance'); gen = d.get('endpoint_bind_generation')
        if not isinstance(endpoint,str) or not OPAQUE_IDENTITY.fullmatch(endpoint): raise DocumentProtocolError('endpoint identity unavailable')
        return endpoint, _number(gen,'binding generation')
    def _fingerprint(self):
        d = self.client.descriptor
        return sha256(repr(tuple(d.get(k) for k in ("socket_path", "capability", "caller", "endpoint_instance", "endpoint_bind_generation"))).encode()).hexdigest()
    def _check(self, target):
        if target._issuer is not self._issuer or target.stream_id != self._known_stream or self._fingerprint() != self._initial_fingerprint or target._descriptor_fingerprint != self._fingerprint() or self._identity() != (target.endpoint_instance,target.endpoint_bind_generation):
            raise DocumentProtocolError('endpoint binding changed')
    @_serialized
    def target(self, resource_id):
        _number(resource_id,'resource id')
        if self._fingerprint() != self._initial_fingerprint:
            raise DocumentProtocolError('endpoint binding changed')
        try:
            endpoint,gen=self._identity(); fingerprint=self._fingerprint(); r=self._transport.get_context([resource_id])
            if r.kind == 'ERROR':
                error=r.value('ERROR')
                if not error or not IDENTIFIER.fullmatch(error[0]): raise DocumentProtocolError('invalid error receipt')
                raise DocumentRemoteError(error[0])
            observed_streams=r.values('STREAM_ID')
            if len(observed_streams)==1 and len(observed_streams[0])==1:
                observed=observed_streams[0][0]
                if self._known_stream is not None and observed != self._known_stream:
                    self._known_stream=None
            if r.kind != 'SNAPSHOT' or r.text('RESOURCE_TYPE_UTF8_HEX') != 'text_document':
                raise DocumentUnsupportedError('unsupported resource type')
            if (_one(r,'ENDPOINT_INSTANCE'),r.integer('ENDPOINT_BIND_GENERATION')) != (endpoint,gen):
                raise DocumentProtocolError('endpoint binding changed')
            actions=tuple(v[0] for v in r.values('ACTION') if len(v)>0)
            if any(not IDENTIFIER.fullmatch(a) for a in actions) or len(set(actions)) != len(actions) or len(actions) != len(r.values('ACTION')):
                raise DocumentProtocolError('invalid or duplicate action declaration')
            authorized=[]
            for action in actions:
                scopes=[v for v in r.values('AUTH_SCOPE') if len(v)>0 and v[0]==action]
                if len(scopes)>1: raise DocumentProtocolError('duplicate authorization scope')
                ids=[v for v in r.values('AUTH_SCOPE_RESOURCE_ID') if len(v)>0 and v[0]==action]
                if not scopes:
                    if ids: raise DocumentProtocolError('orphan authorization resource')
                    continue
                scope=scopes[0]
                if scope == (action,'ALL'):
                    if ids: raise DocumentProtocolError('contradictory authorization scope')
                    authorized.append(action)
                elif len(scope)==3 and scope[1]=='IDS' and scope[2].isdigit():
                    if any(len(v)!=2 or not v[1].isdigit() for v in ids) or len(ids)!=int(scope[2]) or len({v[1] for v in ids})!=len(ids):
                        raise DocumentProtocolError('invalid authorization resource list')
                    if any(int(v[1])==resource_id for v in ids): authorized.append(action)
                else: raise DocumentProtocolError('invalid authorization scope')
            stream=_one(r,'STREAM_ID')
            if not IDENTIFIER.fullmatch(stream): raise DocumentProtocolError('invalid stream identity')
            aggregate=_number(r.integer('VERSION'),'aggregate version')
            resources=[v for v in r.values('RESOURCE') if len(v) >= 1 and v[0] == str(resource_id)]
            if r.integer('RESOURCES') == 0 and not r.values('RESOURCE'):
                raise DocumentUnavailableError('resource unavailable or unauthorized')
            if r.integer('RESOURCES') != 1 or len(r.values('RESOURCE')) != 1 or len(resources)!=1 or len(resources[0])!=4:
                raise DocumentProtocolError('resource missing or duplicated')
            resource=resources[0]
            if not resource[1].isdigit() or not resource[3].isdigit() or int(resource[1]) == 0: raise DocumentProtocolError('invalid resource')
            try: encoded=bytes.fromhex(resource[2]); encoded.decode('utf-8')
            except (ValueError,UnicodeError) as exc: raise DocumentProtocolError('invalid resource name') from exc
            if len(encoded)!=int(resource[1]): raise DocumentProtocolError('invalid resource name length')
            fields=[v for v in r.values('FIELD') if len(v)>0 and v[0]==str(resource_id)]
            if len(fields)!=int(resource[3]) or any(len(v)<3 for v in fields) or len({v[1] for v in fields})!=len(fields):
                raise DocumentProtocolError('invalid or duplicate resource fields')
            version=_number(_field(r,resource_id,'documentVersion','INTEGER'),'document version'); length=_number(_field(r,resource_id,'byteLength','INTEGER'),'byte length')
            if _field(r,resource_id,'positionUnit','STRING') != 'UTF8_BYTE': raise DocumentProtocolError('unsupported position unit')
            selection=None
            selected=[v for v in fields if v[1]=='isSelected']
            if selected:
                if len(selected[0])!=4 or selected[0][2]!='BOOLEAN' or selected[0][3] not in ('0','1','true','false','TRUE','FALSE'):
                    raise DocumentProtocolError('invalid isSelected')
                present=[name for name in ('selectionStart','selectionEnd','selectionDocumentVersion') if any(v[1]==name for v in fields)]
                if selected[0][3].lower() in ('1','true'):
                    if len(present)!=3: raise DocumentProtocolError('incomplete selection')
                    selection=tuple(_number(_field(r,resource_id,name,'INTEGER'),name) for name in ('selectionStart','selectionEnd','selectionDocumentVersion'))
                    if selection[2] == version and (selection[0]>length or selection[1]>length):
                        raise DocumentProtocolError('selection outside matching document version')
                elif present: raise DocumentProtocolError('unselected document carries selection')
            elif any(v[1] in ('selectionStart','selectionEnd','selectionDocumentVersion') for v in fields):
                raise DocumentProtocolError('selection identity unavailable')
            if self._identity() != (endpoint,gen) or self._fingerprint() != fingerprint:
                raise DocumentProtocolError('endpoint binding changed')
            target=DocumentTarget(endpoint,gen,stream,resource_id,aggregate,None,version,length,selection,actions,tuple(authorized),self._issuer,fingerprint)
            self._known_stream=stream
            return target
        except (ValueError,IndexError,KeyError) as exc:
            if isinstance(exc,DocumentProtocolError): raise
            raise DocumentProtocolError(str(exc)) from exc
    @_serialized
    def read(self,target,start,end):
        self._check(target); _number(start,'start'); _number(end,'end')
        if 'READ_RANGE' not in target.authorized_actions: raise DocumentUnavailableError('range read unavailable or unauthorized')
        if end < start or end > target.byte_length or end-start > 65536: raise DocumentProtocolError('invalid range')
        try:
            r=self._transport.read_range(target.resource_id,start,end,target.document_version)
            if r.kind == 'ERROR':
                error=r.value('ERROR')
                if not error or not IDENTIFIER.fullmatch(error[0]): raise DocumentProtocolError('invalid error receipt')
                raise DocumentRemoteError(error[0])
            if r.kind != 'RANGE': raise DocumentProtocolError('not a range response')
            available=r.boolean('AVAILABLE'); conflict=r.boolean('CONFLICT'); version=_number(r.integer('VERSION'),'version'); reason=_one(r,'REASON')
            if not IDENTIFIER.fullmatch(reason): raise DocumentProtocolError('invalid reason')
            if r.integer('RESOURCE') != target.resource_id: raise DocumentProtocolError('wrong resource')
            pair=r.value('RANGE')
            if len(pair)!=2 or not all(x.isdigit() for x in pair) or int(pair[1])<int(pair[0]): raise DocumentProtocolError('invalid range receipt')
            if available:
                if conflict or reason != 'available' or version!=target.document_version or tuple(map(int,pair))!=(start,end): raise DocumentProtocolError('contradictory range')
                content=r.text('CONTENT_UTF8_HEX')
                if len(content.encode('utf-8'))!=end-start: raise DocumentProtocolError('incorrect range length')
            else:
                if reason == 'available': raise DocumentProtocolError('contradictory unavailable range')
                if r.values('CONTENT_UTF8_HEX'): raise DocumentProtocolError('unavailable range has content')
                content=None
            return DocumentRange(available,conflict,reason,version,content)
        except (ValueError,IndexError,KeyError) as exc:
            if isinstance(exc,DocumentProtocolError): raise
            raise DocumentProtocolError(str(exc)) from exc
    @_serialized
    def replace(self,target,start,end,text):
        self._check(target); _number(start,'start'); _number(end,'end')
        if 'REPLACE_RANGE' not in target.authorized_actions: raise DocumentUnavailableError('range replacement unavailable or unauthorized')
        if end<start or end>target.byte_length or end-start>65536 or not isinstance(text,str):
            raise DocumentProtocolError('invalid replacement')
        try: encoded=text.encode('utf-8')
        except UnicodeError as exc: raise DocumentProtocolError('invalid replacement UTF-8') from exc
        if len(encoded)>65536: raise DocumentProtocolError('invalid replacement')
        args=(SharedOperationArgument.integer('start',start),SharedOperationArgument.integer('end',end),SharedOperationArgument.string('text',text))
        return self._invoke(target, 'REPLACE_RANGE', target.document_version, args, document_receipt=True)
    @_serialized
    def open_authorized(self):
        """Invoke the app's public OPEN_DOCUMENT once.

        The request carries no filesystem path: the application consumes its
        own pre-authorized queue. Use `document_opened_since` with the returned
        aggregate version to obtain the exact new resource ID; do not guess the
        most recent selection or a title.
        """
        try:
            r=self._transport.invoke(0,'OPEN_DOCUMENT',[],())
            if r.kind == 'ERROR':
                error=r.value('ERROR')
                if not error or not IDENTIFIER.fullmatch(error[0]): raise DocumentProtocolError('invalid error receipt')
                return DocumentMutation('rejected' if len(error)==1 and error[0] in {
                    'owner_busy','unauthorized_action','unauthorized_resource','invalid_request','invalid_parameters'} else 'unknown',error[0])
            if r.kind != 'RESULT': raise DocumentProtocolError('not a result')
            applied=r.boolean('APPLIED'); conflict=r.boolean('CONFLICT')
            before=_number(r.integer('VERSION_BEFORE'),'before'); after=_number(r.integer('VERSION_AFTER'),'after')
            reason=_one(r,'REASON')
            if not IDENTIFIER.fullmatch(reason): raise DocumentProtocolError('invalid reason')
            if applied and (conflict or after != before + 1): raise DocumentProtocolError('contradictory open receipt')
            if not applied and before != after: raise DocumentProtocolError('refusal changed version')
            return DocumentMutation('applied' if applied else ('conflict' if conflict else 'rejected'),reason,before,after)
        except (ValueError,IndexError,KeyError) as exc:
            if isinstance(exc,DocumentProtocolError): raise
            raise DocumentProtocolError(str(exc)) from exc
    @_serialized
    def document_opened_since(self,since_version):
        """Return the single exact new resource ID after a public open."""
        _number(since_version,'since version')
        try:
            r=self._transport.changes(since_version,(),stream_id=self._known_stream or '')
            if r.kind == 'ERROR':
                error=r.value('ERROR')
                if not error or not IDENTIFIER.fullmatch(error[0]): raise DocumentProtocolError('invalid error receipt')
                raise DocumentRemoteError(error[0])
            if r.kind != 'CHANGES': raise DocumentProtocolError('not a changes response')
            if r.boolean('RESYNC_REQUIRED'): raise DocumentUnavailableError('changes resync required')
            opened=[v for v in r.values('CHANGE') if len(v)==3 and v[2]=='document_opened']
            if len(opened)!=1: raise DocumentUnavailableError('expected exactly one document_opened')
            resource_id=_number(int(opened[0][1]),'document opened resource id')
            observed=_one(r,'STREAM_ID')
            if not IDENTIFIER.fullmatch(observed): raise DocumentProtocolError('invalid stream identity')
            self._known_stream=observed
            return resource_id
        except (ValueError,IndexError,KeyError) as exc:
            if isinstance(exc,DocumentProtocolError): raise
            raise DocumentProtocolError(str(exc)) from exc
    @_serialized
    def close(self,target,*,decision=None,expected_version=None):
        """Close one explicit target with an optional save/discard decision."""
        self._check(target)
        if 'CLOSE_DOCUMENT' not in target.authorized_actions:
            raise DocumentUnavailableError('close unavailable or unauthorized')
        version=target.document_version if expected_version is None else _number(expected_version,'expected version')
        if decision not in (None,'close','save','discard','cancel'):
            raise DocumentProtocolError('invalid close decision')
        args=() if decision is None else (SharedOperationArgument.string('decision',decision),)
        return self._invoke(target,'CLOSE_DOCUMENT',version,args,document_receipt=False)
    @_serialized
    def invoke_history(self,target,action,*,expected_version):
        """Invoke an explicitly declared history action once, using the caller's version domain."""
        self._check(target); _number(expected_version,'expected version')
        if action not in ('UNDO','REDO') or action not in target.authorized_actions:
            raise DocumentUnavailableError('history action unavailable or unauthorized')
        return self._invoke(target,action,expected_version,(),document_receipt=False)
    def _invoke(self,target,action,expected_version,args,*,document_receipt):
        try:
            r=self._transport.invoke(expected_version,action,[target.resource_id],args)
            if r.kind == 'ERROR':
                error = r.value('ERROR')
                if not error or not IDENTIFIER.fullmatch(error[0]): raise DocumentProtocolError('invalid error receipt')
                # Only pre-claim or parse/authorization failures prove no write.
                if len(error) == 1 and error[0] in {'owner_busy','unauthorized_action','unauthorized_resource','invalid_request','invalid_parameters'}:
                    return DocumentMutation('rejected',error[0])
                return DocumentMutation('unknown',error[0])
            if r.kind != 'RESULT': raise DocumentProtocolError('not a result')
            applied=r.boolean('APPLIED'); conflict=r.boolean('CONFLICT'); before=_number(r.integer('VERSION_BEFORE'),'before'); after=_number(r.integer('VERSION_AFTER'),'after'); reason=_one(r,'REASON')
            if not IDENTIFIER.fullmatch(reason): raise DocumentProtocolError('invalid reason')
            if applied and (conflict or (document_receipt and before!=expected_version) or after<before): raise DocumentProtocolError('contradictory receipt')
            if applied and reason in ('version_conflict','unknown_target','unknown_document','document_closed',
                                       'unauthorized_action','unauthorized_resource') and not (
                    action == 'CLOSE_DOCUMENT' and reason == 'document_closed'):
                raise DocumentProtocolError('contradictory success reason')
            if applied and document_receipt:
                # Fixed workspace's replaceRangesUnlocked returns precisely
                # these two success forms, with one increment only for change.
                if not ((reason == 'applied' and after == before + 1) or
                        (reason == 'already_at_target' and after == before)):
                    raise DocumentProtocolError('invalid document success receipt')
            if not applied and document_receipt and reason in ('applied','already_at_target'):
                raise DocumentProtocolError('contradictory refusal reason')
            if not applied and before!=after: raise DocumentProtocolError('refusal changed version')
            return DocumentMutation('applied' if applied else ('conflict' if conflict else 'rejected'),reason,before,after,
                'document' if document_receipt and (applied or (conflict and reason == 'version_conflict')) else 'unknown')
        except (TimeoutError,OSError,ValueError,IndexError,KeyError) as exc:
            return DocumentMutation('unknown',type(exc).__name__)
