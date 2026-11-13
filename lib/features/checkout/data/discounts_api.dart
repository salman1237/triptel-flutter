import '../../../core/network/api_client.dart';
import 'models/discount_check_result.dart';
import 'models/discount_preview_result.dart';

abstract class DiscountsApi {
  /// FR-303: `POST /discounts/check` (public, pre-login estimate). Always
  /// returns 200 -- an invalid code is `{"valid": false, "reason": ...}`,
  /// never a thrown `ApiException` (API.md §4).
  Future<DiscountCheckResult> check(String code);

  /// FR-304: `POST /discounts/preview` (auth, authoritative -- called right
  /// before charging). `{"valid": false, ...}` is still a normal 200
  /// response; a `404 Product not found or inactive` is the one case that
  /// throws `ApiException` (API.md §4).
  Future<DiscountPreviewResult> preview(String code, String productId);
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

  @override
  Future<DiscountPreviewResult> preview(String code, String productId) async {
    final response = await _client.post('/discounts/preview',
        data: {'code': code, 'product_id': productId});
    return DiscountPreviewResult.fromJson(response as Map<String, dynamic>);
  }
}
