import '../../../core/network/api_client.dart';
import 'models/esim_status.dart';
import 'models/esim_topup.dart';
import 'models/topup_option.dart';
import 'models/topup_shurjopay_checkout.dart';

abstract class EsimStatusApi {
  /// `GET /esims/{esim_id}/status` (auth) -- cached 5 min server-side.
  Future<EsimStatus> getStatus(String esimId);

  /// `POST /esims/{esim_id}/refresh` (auth, 20/min) -- same response shape,
  /// forces a re-fetch. The server also enforces its own per-eSIM cooldown;
  /// the client disables the button for ~30s after use (FR-403).
  Future<EsimStatus> refresh(String esimId);

  /// `GET /esims/{esim_id}/topup-options` (auth) -- FR-407. Empty = hide
  /// the section entirely.
  Future<List<TopupOption>> getTopupOptions(String esimId);

  /// `POST /esims/{esim_id}/topup` (auth, 10/min) -- pay from wallet,
  /// synchronous (FR-408).
  Future<EsimTopup> topupWithWallet(String esimId, String packageCode);

  /// `POST /payments/shurjopay/esim-topup-initiate` (auth,
  /// password-changed) -- FR-408.
  Future<TopupShurjoPayCheckout> initiateTopupShurjoPay(
      String esimId, String packageCode);
}

class EsimStatusApiImpl implements EsimStatusApi {
  EsimStatusApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<EsimStatus> getStatus(String esimId) async {
    final response = await _client.get('/esims/$esimId/status');
    return EsimStatus.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<EsimStatus> refresh(String esimId) async {
    final response = await _client.post('/esims/$esimId/refresh');
    return EsimStatus.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<TopupOption>> getTopupOptions(String esimId) async {
    final response = await _client.get('/esims/$esimId/topup-options');
    return (response as List)
        .map((json) => TopupOption.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EsimTopup> topupWithWallet(String esimId, String packageCode) async {
    final response = await _client
        .post('/esims/$esimId/topup', data: {'package_code': packageCode});
    return EsimTopup.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TopupShurjoPayCheckout> initiateTopupShurjoPay(
      String esimId, String packageCode) async {
    final response = await _client.post(
      '/payments/shurjopay/esim-topup-initiate',
      query: {'esim_id': esimId},
      data: {'package_code': packageCode},
    );
    return TopupShurjoPayCheckout.fromJson(response as Map<String, dynamic>);
  }
}
