import 'package:flutter_test/flutter_test.dart';
import 'package:triptel/features/support/data/models/support_message.dart';

void main() {
  test(
      'SupportMessage.fromJson defaults messageType to TEXT and leaves '
      'shares null for a plain message', () {
    final message = SupportMessage.fromJson(const {
      'id': 'm1',
      'body': 'Hello',
      'is_staff': false,
      'author': 'You',
      'created_at': '2026-11-19T10:00:00Z',
      'attachments': [],
    });

    expect(message.messageType, 'TEXT');
    expect(message.sharedOrder, isNull);
    expect(message.sharedProduct, isNull);
    expect(message.authorAvatarUrl, isNull);
  });

  test(
      'SupportMessage.fromJson parses an ORDER_SHARE message with its '
      'real shared_order (API.md section 12)', () {
    final message = SupportMessage.fromJson(const {
      'id': 'm2',
      'body': '',
      'is_staff': false,
      'author': 'You',
      'author_avatar_url': 'https://beta.triptel.co/avatar.png',
      'message_type': 'ORDER_SHARE',
      'shared_order': {
        'id': 'order-1',
        'order_no': 'ORD-1',
        'status': 'COMPLETED',
        'total_amount': '12.50',
        'currency': 'USD',
        'product_title': 'Bangladesh 1GB 7Days',
        'esim_profile_id': 'esim-1',
      },
      'shared_product': null,
      'created_at': '2026-11-19T10:00:00Z',
      'attachments': [],
    });

    expect(message.messageType, 'ORDER_SHARE');
    expect(message.sharedOrder, isNotNull);
    expect(message.sharedOrder!.orderNo, 'ORD-1');
    expect(message.sharedProduct, isNull);
  });

  test(
      'SupportMessage.fromJson leaves sharedOrder null when the message '
      'type is ORDER_SHARE but the order was since deleted (ON DELETE '
      'SET NULL, API.md section 12) -- still a readable message', () {
    final message = SupportMessage.fromJson(const {
      'id': 'm3',
      'body': '',
      'is_staff': false,
      'author': 'You',
      'message_type': 'ORDER_SHARE',
      'shared_order': null,
      'created_at': '2026-11-19T10:00:00Z',
      'attachments': [],
    });

    expect(message.messageType, 'ORDER_SHARE');
    expect(message.sharedOrder, isNull);
  });

  test(
      'SupportMessage.fromJson parses a PRODUCT_SHARE message with its '
      'real shared_product', () {
    final message = SupportMessage.fromJson(const {
      'id': 'm4',
      'body': 'Check this one out',
      'is_staff': true,
      'author': 'Support',
      'message_type': 'PRODUCT_SHARE',
      'shared_product': {
        'id': 'product-1',
        'title': 'Japan 3GB 15Days',
        'data_amount_gb': '3.00',
        'validity_days': 15,
        'is_unlimited': false,
        'retail_price': '18.99',
        'currency': 'USD',
        'country_slug': 'japan',
      },
      'created_at': '2026-11-19T10:00:00Z',
      'attachments': [],
    });

    expect(message.messageType, 'PRODUCT_SHARE');
    expect(message.sharedProduct, isNotNull);
    expect(message.sharedProduct!.title, 'Japan 3GB 15Days');
    expect(message.sharedOrder, isNull);
  });
}
