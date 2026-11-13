import '../../../core/network/api_client.dart';
import 'models/discount_check_result.dart';

abstract class DiscountsApi {
  /// FR-303: `POST /discounts/check` (public, pre-login estimate). Always
  /// returns 200 -- an invalid code is `{"valid": false, "reason": ...}`,
  /// never a thrown `ApiException` (API.md §4).
  Future<DiscountCheckResult> check(String code);
}

class DiscountsApiImpl implements DiscountsApi {
  DiscountsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<DiscountCheckResult> check(String code) async {
    final response =
        await _client.post('/discounts/check', data: {'code': code});
    return DiscountCheckResult.fromJson(response as Map<String, dynamic>);
  }
}
