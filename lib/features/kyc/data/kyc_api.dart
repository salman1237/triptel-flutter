import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/kyc_status.dart';

abstract class KycApi {
  /// `GET /kyc/me` (auth).
  Future<KycStatus> getMe();

  /// `POST /kyc/submit` (auth, multipart). `documentFront` is required,
  /// `documentBack` optional (API.md §11). Resubmitting resets status to
  /// PENDING server-side.
  Future<void> submit({
    required String nidNumber,
    required String documentFrontPath,
    String? documentBackPath,
  });
}

class KycApiImpl implements KycApi {
  KycApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<KycStatus> getMe() async {
    final response = await _client.get('/kyc/me');
    return KycStatus.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> submit({
    required String nidNumber,
    required String documentFrontPath,
    String? documentBackPath,
  }) async {
    await _client.post(
      '/kyc/submit',
      data: FormData.fromMap({
        'nid_number': nidNumber,
        'document_front': await MultipartFile.fromFile(documentFrontPath),
        if (documentBackPath != null)
          'document_back': await MultipartFile.fromFile(documentBackPath),
      }),
    );
  }
}
