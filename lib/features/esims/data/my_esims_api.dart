import '../../../core/network/api_client.dart';
import 'models/my_esim.dart';

abstract class MyEsimsApi {
  /// `GET /orders/my-esims` (auth) -- newest first.
  Future<List<MyEsim>> getMyEsims();
}

class MyEsimsApiImpl implements MyEsimsApi {
  MyEsimsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<MyEsim>> getMyEsims() async {
    final response = await _client.get('/orders/my-esims');
    return (response as List)
        .map((e) => MyEsim.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
