import '../../../core/network/api_client.dart';
import 'models/kyc_status.dart';

abstract class KycApi {
  /// `GET /kyc/me` (auth).
  Future<KycStatus> getMe();
}

class KycApiImpl implements KycApi {
  KycApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<KycStatus> getMe() async {
    final response = await _client.get('/kyc/me');
    return KycStatus.fromJson(response as Map<String, dynamic>);
  }
}
