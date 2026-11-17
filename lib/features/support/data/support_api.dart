import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/support_ticket.dart';

abstract class SupportApi {
  /// `POST /support/tickets` (auth, multipart) -- FR-410 never sends
  /// `order_id`: the real order UUID this FK expects isn't available
  /// anywhere on the eSIM detail screen's data path (only `esim_id` and
  /// the display `order_no` string are), so the order is identified in
  /// [body]'s text instead of guessing a value that would fail the
  /// backend's foreign-key constraint. No `files` -- FR-410 doesn't need
  /// attachments.
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
  });

  /// `GET /support/tickets` (auth), up to 100, newest activity first.
  Future<List<SupportTicket>> getTickets();
}

class SupportApiImpl implements SupportApi {
  SupportApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
  }) async {
    final response = await _client.post(
      '/support/tickets',
      data: FormData.fromMap({
        'subject': subject,
        'body': body,
        'category': category,
      }),
    );
    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<SupportTicket>> getTickets() async {
    final response = await _client.get('/support/tickets');
    return (response as List)
        .map((t) => SupportTicket.fromJson(t as Map<String, dynamic>))
        .toList();
  }
}
