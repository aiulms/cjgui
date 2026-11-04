import unittest
from unittest.mock import Mock
from client import parse_response
from cjgui_document_client import DocumentClient, DocumentProtocolError

P = 'PROTOCOL CJGUI_SHARED_OPERATION/2\n'
def response(kind, body): return parse_response(P + 'KIND ' + kind + '\n' + body + '\nEND')
def context():
    return response('SNAPSHOT', '\n'.join(('ENDPOINT_INSTANCE endpoint-1','ENDPOINT_BIND_GENERATION 3','VERSION 13','STREAM_ID stream-1','RESOURCE_TYPE_UTF8_HEX 13 746578745F646F63756D656E74','ACTION READ_RANGE PARAMETERS 3 TARGETS 1 1','ACTION REPLACE_RANGE PARAMETERS 3 TARGETS 1 1','AUTH_SCOPE READ_RANGE ALL','AUTH_SCOPE REPLACE_RANGE ALL','RESOURCES 1','RESOURCE 7101 1 41 3','FIELD 7101 documentVersion INTEGER 5','FIELD 7101 byteLength INTEGER 3','FIELD 7101 positionUnit STRING 9 555446385F42595445')))
class DocumentTests(unittest.TestCase):
    def setUp(self):
        self.raw=Mock(); self.raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; self.raw.get_context.return_value=context(); self.api=DocumentClient(self.raw, binding_contract='fixed_text_document_workspace')
    def test_document_version_and_true_receipt(self):
        t=self.api.target(7101); self.assertEqual((t.aggregate_version,t.document_version,t.resource_projection_version),(13,5,None))
        self.raw.invoke.return_value=response('RESULT','APPLIED true\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON applied')
        r=self.api.replace(t,0,3,'新'); self.assertEqual((r.outcome,r.version_after),('applied',6)); self.assertEqual(self.raw.invoke.call_args.args[0],5); self.assertEqual(self.raw.invoke.call_count,1)
    def test_malformed_and_timeout_unknown_no_retry(self):
        t=self.api.target(7101)
        for reply in (response('RESULT','APPLIED true\nAPPLIED false\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON applied'), TimeoutError('late')):
            self.raw.invoke.reset_mock(); self.raw.invoke.side_effect=reply if isinstance(reply,Exception) else None; self.raw.invoke.return_value=reply
            self.assertEqual(self.api.replace(t,0,3,'x').outcome,'unknown'); self.assertEqual(self.raw.invoke.call_count,1)
    def test_wrong_endpoint_rejected_without_sending(self):
        t=self.api.target(7101); self.raw.descriptor={'endpoint_instance':'endpoint-2','endpoint_bind_generation':3}
        with self.assertRaises(DocumentProtocolError): self.api.replace(t,0,1,'x')
        self.raw.invoke.assert_not_called()
    def test_exact_resource_version_range(self):
        t=self.api.target(7101); self.raw.read_range.return_value=response('RANGE','AVAILABLE true\nCONFLICT false\nRESOURCE 7101\nVERSION 5\nRANGE 0 3\nREASON available\nCONTENT_UTF8_HEX 3 E4B8AD')
        self.assertEqual(self.api.read(t,0,3).content,'中')
        self.raw.read_range.return_value=response('RANGE','AVAILABLE true\nCONFLICT false\nRESOURCE 7102\nVERSION 5\nRANGE 0 3\nREASON available\nCONTENT_UTF8_HEX 3 E4B8AD')
        with self.assertRaises(DocumentProtocolError): self.api.read(t,0,3)

class DocumentBoundaries(unittest.TestCase):
    def setUp(self):
        self.raw=Mock(); self.raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; self.raw.get_context.return_value=context(); self.api=DocumentClient(self.raw, binding_contract='fixed_text_document_workspace')
    def test_unknown_type_and_duplicate_field(self):
        bad=context().raw.replace('746578745F646F63756D656E74','756E6B6E6F776E000000000000')
        self.raw.get_context.return_value=parse_response(bad)
        with self.assertRaises(DocumentProtocolError): self.api.target(7101)
        self.raw.get_context.return_value=parse_response(context().raw.replace('FIELD 7101 documentVersion INTEGER 5','FIELD 7101 documentVersion INTEGER 5\nFIELD 7101 documentVersion INTEGER 5'))
        with self.assertRaises(DocumentProtocolError): self.api.target(7101)
    def test_preclaim_refusal_vs_claimed_unknown(self):
        t=self.api.target(7101)
        self.raw.invoke.return_value=response('ERROR','ERROR owner_busy')
        self.assertEqual(self.api.replace(t,0,0,'x').outcome,'rejected')
        self.raw.invoke.return_value=response('ERROR','ERROR request_cancelled')
        self.assertEqual(self.api.replace(t,0,0,'x').outcome,'unknown')
    def test_conflict_and_rejected_versions_are_not_mislabeled(self):
        t=self.api.target(7101)
        self.raw.invoke.return_value=response('RESULT','APPLIED false\nCONFLICT true\nVERSION_BEFORE 6\nVERSION_AFTER 6\nREASON version_conflict')
        r=self.api.replace(t,0,0,'x'); self.assertEqual((r.outcome,r.version_domain),('conflict','document'))
        self.raw.invoke.return_value=response('RESULT','APPLIED false\nCONFLICT false\nVERSION_BEFORE 13\nVERSION_AFTER 13\nREASON document_closed')
        r=self.api.replace(t,0,0,'x'); self.assertEqual((r.outcome,r.version_domain),('rejected','unknown'))
    def test_snapshot_not_portable_to_other_client(self):
        t=self.api.target(7101); other=DocumentClient(self.raw, binding_contract='fixed_text_document_workspace')
        with self.assertRaises(DocumentProtocolError): other.replace(t,0,0,'x')
        self.raw.invoke.assert_not_called()

class HistoryTests(unittest.TestCase):
    def test_only_declared_history_with_explicit_version_is_sent_once(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}
        raw.get_context.return_value=context(); api=DocumentClient(raw, binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        with self.assertRaises(DocumentProtocolError): api.invoke_history(target,'UNDO',expected_version=5)
        raw.invoke.assert_not_called()
        extended=context().raw.replace('RESOURCES 1','ACTION UNDO PARAMETERS 0 TARGETS 1 1\nAUTH_SCOPE UNDO ALL\nRESOURCES 1')
        raw.get_context.return_value=parse_response(extended); target=api.target(7101)
        raw.invoke.return_value=response('RESULT','APPLIED false\nCONFLICT false\nVERSION_BEFORE 13\nVERSION_AFTER 13\nREASON human_history_only')
        result=api.invoke_history(target,'UNDO',expected_version=5)
        self.assertEqual((result.outcome,result.reason,result.version_domain),('rejected','human_history_only','unknown'))
        self.assertEqual(raw.invoke.call_args.args[:3],(5,'UNDO',[7101])); self.assertEqual(raw.invoke.call_count,1)

class SafetyTests(unittest.TestCase):
    def setUp(self):
        self.raw=Mock(); self.raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3,'socket_path':'/tmp/one','capability':'private'}; self.raw.get_context.return_value=context(); self.api=DocumentClient(self.raw, binding_contract='fixed_text_document_workspace')
    def test_changed_descriptor_or_unadvertised_scope_never_sends(self):
        t=self.api.target(7101); self.raw.descriptor['capability']='changed'
        with self.assertRaises(DocumentProtocolError): self.api.replace(t,0,0,'x')
        self.raw.invoke.assert_not_called()
        self.raw.descriptor['capability']='private'; c=context().raw.replace('AUTH_SCOPE REPLACE_RANGE ALL','AUTH_SCOPE REPLACE_RANGE IDS 1\nAUTH_SCOPE_RESOURCE_ID REPLACE_RANGE 7102'); self.raw.get_context.return_value=parse_response(c); t=self.api.target(7101)
        with self.assertRaises(DocumentProtocolError): self.api.replace(t,0,0,'x')
        self.raw.invoke.assert_not_called()
    def test_bad_boolean_and_contradictory_success_are_unknown(self):
        t=self.api.target(7101)
        for payload in ('APPLIED yes\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON applied', 'APPLIED true\nCONFLICT true\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON applied', 'APPLIED true\nCONFLICT false\nVERSION_BEFORE 13\nVERSION_AFTER 14\nREASON applied'):
            self.raw.invoke.reset_mock(); self.raw.invoke.return_value=response('RESULT',payload)
            self.assertEqual(self.api.replace(t,0,0,'x').outcome,'unknown'); self.assertEqual(self.raw.invoke.call_count,1)
    def test_utf8_bounds_before_any_mutation(self):
        t=self.api.target(7101)
        for start,end,value in ((-1,0,'x'),(0,4,'x'),(0,0,'x'*65537)):
            with self.assertRaises(DocumentProtocolError): self.api.replace(t,start,end,value)
        self.raw.invoke.assert_not_called()

class IdentityBoundaryTests(unittest.TestCase):
    def test_known_stream_replacement_retires_old_target_without_mutation(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); old=api.target(7101)
        raw.get_context.return_value=parse_response(context().raw.replace('STREAM_ID stream-1','STREAM_ID stream-2')); fresh=api.target(7101)
        self.assertEqual(fresh.stream_id,'stream-2')
        with self.assertRaises(DocumentProtocolError): api.replace(old,0,0,'x')
        raw.invoke.assert_not_called()
    def test_unknown_binding_contract_is_unsupported(self):
        from cjgui_document_client import DocumentUnsupportedError
        with self.assertRaises(DocumentUnsupportedError): DocumentClient(Mock(),binding_contract='dynamic_provider')

class CapturedProtocolTests(unittest.TestCase):
    def test_real_workspace_04_shape_and_exact_version_domains(self):
        captured=response('SNAPSHOT', '\n'.join((
            'ENDPOINT_INSTANCE 8ee97578394d53210000000000000001',
            'ENDPOINT_BIND_GENERATION 1','VERSION 13',
            'STREAM_ID text-document-15069162832039482953',
            'RESOURCE_TYPE_UTF8_HEX 13 746578745F646F63756D656E74',
            'ACTION READ_RANGE PARAMETERS 3 TARGETS 1 1',
            'ACTION REPLACE_RANGE PARAMETERS 3 TARGETS 1 1',
            'AUTH_SCOPE READ_RANGE IDS 2','AUTH_SCOPE_RESOURCE_ID READ_RANGE 7101',
            'AUTH_SCOPE_RESOURCE_ID READ_RANGE 7102',
            'AUTH_SCOPE REPLACE_RANGE IDS 2','AUTH_SCOPE_RESOURCE_ID REPLACE_RANGE 7101',
            'AUTH_SCOPE_RESOURCE_ID REPLACE_RANGE 7102',
            'RESOURCES 1','RESOURCE 7101 12 E8AFB4E6988EE69687E6A1A3 8',
            'FIELD 7101 documentVersion INTEGER 5','FIELD 7101 byteLength INTEGER 38',
            'FIELD 7101 previewLimit INTEGER 512',
            'FIELD 7101 positionUnit STRING 9 555446385F42595445',
            'FIELD 7101 isSelected BOOLEAN 1','FIELD 7101 selectionStart INTEGER 38',
            'FIELD 7101 selectionEnd INTEGER 38','FIELD 7101 selectionDocumentVersion INTEGER 5')))
        raw=Mock(); raw.descriptor={'endpoint_instance':'8ee97578394d53210000000000000001','endpoint_bind_generation':1}; raw.get_context.return_value=captured
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); t=api.target(7101)
        self.assertEqual((t.aggregate_version,t.resource_projection_version,t.document_version,t.selection),(13,None,5,(38,38,5)))
        raw.invoke.return_value=response('RESULT','APPLIED true\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON applied')
        self.assertEqual(api.replace(t,0,0,'x').outcome,'applied'); self.assertEqual(raw.invoke.call_args.args[0],5)

class StaleSelectionAndStreamTests(unittest.TestCase):
    def test_failed_new_stream_parse_also_invalidates_previous_snapshot(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); old=api.target(7101)
        bad=context().raw.replace('STREAM_ID stream-1','STREAM_ID stream-2').replace('FIELD 7101 documentVersion INTEGER 5','FIELD 7101 documentVersion INTEGER 5\nFIELD 7101 documentVersion INTEGER 5')
        raw.get_context.return_value=parse_response(bad)
        with self.assertRaises(DocumentProtocolError): api.target(7101)
        with self.assertRaises(DocumentProtocolError): api.replace(old,0,0,'x')
        raw.invoke.assert_not_called()
    def test_old_version_selection_is_not_compared_to_new_body_length(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}
        base=context().raw.replace('RESOURCE 7101 1 41 3','RESOURCE 7101 1 41 7').replace('FIELD 7101 positionUnit STRING 9 555446385F42595445','FIELD 7101 positionUnit STRING 9 555446385F42595445\nFIELD 7101 isSelected BOOLEAN 1\nFIELD 7101 selectionStart INTEGER 8\nFIELD 7101 selectionEnd INTEGER 8\nFIELD 7101 selectionDocumentVersion INTEGER 4')
        raw.get_context.return_value=parse_response(base); api=DocumentClient(raw,binding_contract='fixed_text_document_workspace')
        self.assertEqual(api.target(7101).selection,(8,8,4))

class DescriptorFreezeTests(unittest.TestCase):
    def test_transport_keeps_snapshot_when_caller_changes_mapping(self):
        from client import SharedOperationClient
        descriptor={'socket_path':'/tmp/old','capability':'secret','caller':'caller',
                    'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}
        api=DocumentClient(SharedOperationClient(descriptor),binding_contract='fixed_text_document_workspace')
        descriptor['socket_path']='/tmp/new'
        self.assertEqual(api._transport.descriptor['socket_path'],'/tmp/old')
        with self.assertRaises(TypeError): api._transport.descriptor['socket_path']='/tmp/new'

class ExportReviewRegression(unittest.TestCase):
    def test_descriptor_change_before_first_target_rejects_without_io(self):
        from unittest.mock import patch
        from client import SharedOperationClient
        for key in ('capability','caller'):
            descriptor={'socket_path':'/tmp/old','capability':'cap','caller':'caller',
                        'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}
            api=DocumentClient(SharedOperationClient(descriptor),binding_contract='fixed_text_document_workspace')
            descriptor[key]='changed'
            with patch.object(SharedOperationClient,'get_context',return_value=context()) as get_context:
                with self.assertRaises(DocumentProtocolError): api.target(7101)
                get_context.assert_not_called()
    def test_success_receipt_with_failure_reason_is_unknown(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        for reason in ('version_conflict','unknown_target'):
            raw.invoke.reset_mock(); raw.invoke.return_value=response('RESULT',f'APPLIED true\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 6\nREASON {reason}')
            self.assertEqual(api.replace(target,0,0,'x').outcome,'unknown'); self.assertEqual(raw.invoke.call_count,1)
    def test_available_range_requires_available_reason(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        raw.read_range.return_value=response('RANGE','AVAILABLE true\nCONFLICT false\nRESOURCE 7101\nVERSION 5\nRANGE 0 3\nREASON version_conflict\nCONTENT_UTF8_HEX 3 E4B8AD')
        with self.assertRaises(DocumentProtocolError): api.read(target,0,3)
    def test_fixed_workspace_valid_applied_and_noop_versions(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        for reason,after,want in (('applied',6,'applied'),('already_at_target',5,'applied'),('applied',5,'unknown'),('already_at_target',6,'unknown')):
            raw.invoke.return_value=response('RESULT',f'APPLIED true\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER {after}\nREASON {reason}')
            self.assertEqual(api.replace(target,0,0,'x').outcome,want)

class OppositeReceiptRegression(unittest.TestCase):
    def test_refusal_with_success_reason_is_not_a_definite_rejection(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        raw.invoke.return_value=response('RESULT','APPLIED false\nCONFLICT false\nVERSION_BEFORE 5\nVERSION_AFTER 5\nREASON applied')
        self.assertEqual(api.replace(target,0,0,'x').outcome,'unknown'); self.assertEqual(raw.invoke.call_count,1)
    def test_unavailable_range_cannot_claim_available(self):
        raw=Mock(); raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; raw.get_context.return_value=context()
        api=DocumentClient(raw,binding_contract='fixed_text_document_workspace'); target=api.target(7101)
        raw.read_range.return_value=response('RANGE','AVAILABLE false\nCONFLICT false\nRESOURCE 7101\nVERSION 5\nRANGE 0 0\nREASON available')
        with self.assertRaises(DocumentProtocolError): api.read(target,0,3)

class LifecycleClientTests(unittest.TestCase):
    def setUp(self):
        self.raw=Mock(); self.raw.descriptor={'endpoint_instance':'endpoint-1','endpoint_bind_generation':3}; self.raw.get_context.return_value=context()
        self.api=DocumentClient(self.raw,binding_contract='fixed_text_document_workspace'); self.target=self.api.target(7101)
    def test_open_authorized_and_exact_new_id_from_plain_resync_flag(self):
        self.raw.invoke.return_value=response('RESULT','APPLIED true\nCONFLICT false\nVERSION_BEFORE 13\nVERSION_AFTER 14\nREASON opened')
        opened=self.api.open_authorized()
        self.assertEqual((opened.outcome,opened.reason,opened.version_after),('applied','opened',14))
        self.raw.changes.return_value=response('CHANGES','STREAM_ID stream-1\nSINCE_VERSION 13\nCURRENT_VERSION 14\nRESYNC_REQUIRED false\nCHANGES 1\nCHANGE 14 7200 document_opened')
        self.assertEqual(self.api.document_opened_since(13),7200)
        self.raw.changes.assert_called_once_with(13,(),stream_id='stream-1')
    def test_document_opened_requires_one_change_and_no_resync(self):
        from cjgui_document_client import DocumentUnavailableError
        self.raw.changes.return_value=response('CHANGES','STREAM_ID stream-1\nSINCE_VERSION 13\nCURRENT_VERSION 14\nRESYNC_REQUIRED true\nCHANGES 0')
        with self.assertRaises(DocumentUnavailableError): self.api.document_opened_since(13)
        self.raw.changes.return_value=response('CHANGES','STREAM_ID stream-1\nSINCE_VERSION 13\nCURRENT_VERSION 15\nRESYNC_REQUIRED false\nCHANGES 2\nCHANGE 14 7200 document_opened\nCHANGE 15 7201 document_opened')
        with self.assertRaises(DocumentUnavailableError): self.api.document_opened_since(13)

if __name__ == '__main__':
    unittest.main()
