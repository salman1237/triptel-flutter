import '../../../core/network/api_client.dart';
import 'models/referral_summary.dart';

abstract class ReferralsApi {
  /// `GET /referrals/me` (auth).
  Future<ReferralSummary> getMe();

  /// `POST /referrals/claim` (auth) `{"code"}` (3-16 chars). 400:
  /// already has a referrer / invalid / self / after first completed
  /// purchase.
  Future<ReferralSummary> claim(String code);

  /// `GET /referrals/validate?code=` (public). FR-803: live preview on
  /// the register screen.
  Future<ReferralValidation> validate(String code);
}

class ReferralsApiImpl implements ReferralsApi {
  ReferralsApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<ReferralSummary> getMe() async {
    final response = await _client.get('/referrals/me');
    return ReferralSummary.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ReferralSummary> claim(String code) async {
    final response = await _client.post('/referrals/claim', data: {
      'code': code,
    });
    return ReferralSummary.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<ReferralValidation> validate(String code) async {
    final response =
        await _client.get('/referrals/validate', query: {'code': code});
    return ReferralValidation.fromJson(response as Map<String, dynamic>);
  }
}
