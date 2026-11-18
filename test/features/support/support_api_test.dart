import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/core/network/api_client.dart';
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
}
