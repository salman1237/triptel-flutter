import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_client.dart';
import 'package:triptel/features/support/data/models/support_attachment.dart';
import 'package:triptel/features/support/data/support_api.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._json);
  final String _json;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = utf8.encode(_json);
    return ResponseBody.fromBytes(bytes, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

class _FakeBytesAdapter implements HttpClientAdapter {
  _FakeBytesAdapter(this._bytes);
  final Uint8List _bytes;
  Uri? seenUri;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // `options.path` is the raw, unresolved argument passed to `dio.get()`
    // -- `options.uri` is the real request URL after Dio merges it with
    // `baseUrl`, which is what actually matters here (FR-1103's reviewer
    // caught a bug where the raw path alone hid a double `/api/v1` prefix).
    seenUri = options.uri;
    return ResponseBody.fromBytes(_bytes, 200, headers: {
      Headers.contentTypeHeader: ['image/png'],
    });
  }
}

void main() {
  test(
      'SupportApiImpl.getCategories hides PARTNER from the real documented '
      'response (API.md section 12)', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(jsonEncode([
        {'value': 'ESIM', 'label': 'eSIM not working'},
        {'value': 'PAYMENT', 'label': 'Payment issue'},
        {'value': 'REFUND', 'label': 'Refund'},
        {'value': 'ACCOUNT', 'label': 'Account'},
        {'value': 'PARTNER', 'label': 'Partner'},
        {'value': 'OTHER', 'label': 'Other'},
      ]));
    final api = SupportApiImpl(ApiClient(dio: dio));

    final categories = await api.getCategories();

    expect(categories.map((c) => c.value),
        ['ESIM', 'PAYMENT', 'REFUND', 'ACCOUNT', 'OTHER']);
    expect(categories.any((c) => c.value == 'PARTNER'), isFalse);
  });

  test(
      'SupportApiImpl.downloadAttachment hits the real authenticated path '
      '(API.md section 12) and returns the real bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final adapter = _FakeBytesAdapter(bytes);
    final dio = Dio()..httpClientAdapter = adapter;
    final api = SupportApiImpl(ApiClient(dio: dio));

    final result = await api.downloadAttachment(const SupportAttachment(
      id: 'att-1',
      name: 'photo.jpg',
      contentType: 'image/jpeg',
      sizeBytes: 4,
      // The real documented shape (API.md section 12): already absolute
      // from the API root, including `/api/v1` -- not relative to the
      // `/api/v1`-inclusive API base URL.
      url: '/api/v1/support/attachments/att-1',
    ));

    expect(result, bytes);
    expect(adapter.seenUri.toString(),
        'https://beta.triptel.co/api/v1/support/attachments/att-1');
  });
}
