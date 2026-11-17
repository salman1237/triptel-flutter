import '../../../core/network/api_client.dart';
import '../../esims/data/models/esim_status.dart';

abstract class TrackingApi {
  /// `GET /esims/public/{token}` (public, 60/min) -- FR-501. Same response
  /// shape as the authenticated `/esims/{id}/status` (reuses [EsimStatus]),
  /// except `share_url` is always null here. 404 for an unknown/short
  /// token.
  Future<EsimStatus> getPublicStatus(String token);
}

class TrackingApiImpl implements TrackingApi {
  TrackingApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<EsimStatus> getPublicStatus(String token) async {
    final response = await _client.get('/esims/public/$token');
    return EsimStatus.fromJson(response as Map<String, dynamic>);
  }
}
