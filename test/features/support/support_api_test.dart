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
  String? seenPath;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    seenPath = options.path;
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
      url: '/support/attachments/att-1',
    ));

    expect(result, bytes);
    expect(adapter.seenPath, '/support/attachments/att-1');
  });
}
