import '../../../core/network/api_client.dart';
import 'models/legal_document.dart';

abstract class LegalApi {
  /// `GET /settings/legal` (public).
  Future<List<LegalDocument>> getDocuments();

  /// `GET /settings/legal/{slug}` (public). 404 `Document not found`.
  Future<LegalDocumentDetail> getDocument(String slug);
}

class LegalApiImpl implements LegalApi {
  LegalApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<LegalDocument>> getDocuments() async {
    final response = await _client.get('/settings/legal');
    return (response as List)
        .map((json) => LegalDocument.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LegalDocumentDetail> getDocument(String slug) async {
    final response = await _client.get('/settings/legal/$slug');
    return LegalDocumentDetail.fromJson(response as Map<String, dynamic>);
  }
}
