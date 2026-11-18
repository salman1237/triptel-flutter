import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../../core/network/absolute_url.dart';
import '../../../core/network/api_client.dart';
import 'models/support_attachment.dart';
import 'models/support_category.dart';
import 'models/support_ticket.dart';

abstract class SupportApi {
  /// `POST /support/tickets` (auth, multipart). `filePaths` is capped at 5
  /// server-side (API.md section 12); FR-410's own call site never sends
  /// `order_id` (the real FK UUID isn't available on its data path) or
  /// files, but FR-1102's does send files -- `order_id` is still never
  /// sent by this client, since no screen has a real order UUID to put
  /// there (`GET /orders/my-esims` doesn't return one either); the order
  /// is identified in [body]'s text instead.
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  });

  /// `GET /support/tickets` (auth), up to 100, newest activity first.
  Future<List<SupportTicket>> getTickets();

  /// `GET /support/tickets/{id}` (auth) -- ticket + full `messages` thread.
  Future<SupportTicket> getTicket(String id);

  /// `POST /support/tickets/{id}/messages` (auth, multipart). Replying to
  /// a RESOLVED ticket reopens it; a CLOSED ticket rejects this with a 400
  /// (API.md section 12) -- surfaced to the caller as the real
  /// [ApiException] message, not guessed client-side.
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
  });

  /// `POST /support/tickets/{id}/close` (auth).
  Future<SupportTicket> closeTicket(String id);

  /// `GET /support/attachments/{id}` (auth) -- raw file bytes.
  Future<Uint8List> downloadAttachment(SupportAttachment attachment);

  /// `GET /support/categories` (public). `PARTNER` is filtered out of the
  /// result -- hidden in this customer app.
  Future<List<SupportCategory>> getCategories();
}

class SupportApiImpl implements SupportApi {
  SupportApiImpl(this._client);

  final ApiClient _client;

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String body,
    required String category,
    List<String> filePaths = const [],
  }) async {
    final response = await _client.post(
      '/support/tickets',
      data: FormData.fromMap({
        'subject': subject,
        'body': body,
        'category': category,
        if (filePaths.isNotEmpty)
          'files': [
            for (final path in filePaths) await MultipartFile.fromFile(path),
          ],
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

  @override
  Future<SupportTicket> getTicket(String id) async {
    final response = await _client.get('/support/tickets/$id');
    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicket> replyToTicket(
    String id, {
    required String body,
    List<String> filePaths = const [],
  }) async {
    final response = await _client.post(
      '/support/tickets/$id/messages',
      data: FormData.fromMap({
        'body': body,
        if (filePaths.isNotEmpty)
          'files': [
            for (final path in filePaths) await MultipartFile.fromFile(path),
          ],
      }),
    );
    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SupportTicket> closeTicket(String id) async {
    final response = await _client.post('/support/tickets/$id/close');
    return SupportTicket.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Uint8List> downloadAttachment(SupportAttachment attachment) =>
      // `attachment.url` is already absolute from the API root (`/api/v1/
      // support/attachments/<id>`, API.md section 12) -- resolve it with
      // `resolveApiUrl` like every other server-relative asset path, not
      // the `/api/v1`-inclusive API base URL, or the path doubles up.
      _client.getBytes(resolveApiUrl(attachment.url));

  @override
  Future<List<SupportCategory>> getCategories() async {
    final response = await _client.get('/support/categories');
    return (response as List)
        .where((c) => (c as Map<String, dynamic>)['value'] != 'PARTNER')
        .map((c) => SupportCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
