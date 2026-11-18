import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/support_attachment.dart';
import 'support_providers.dart';

/// FR-1103: downloads an attachment with the real auth header (an
/// `Image.network`/system viewer can't add it on its own, API.md section
/// 12) and hands it to the OS share sheet to open/save -- a provider seam,
/// same reasoning as `receiptSharerProvider` (real platform channel, not
/// drivable inside a widget test).
typedef SupportAttachmentOpener = Future<void> Function(
    SupportAttachment attachment);

final supportAttachmentOpenerProvider =
    Provider<SupportAttachmentOpener>((ref) => (attachment) async {
          final bytes = await ref.read(supportApiProvider).downloadAttachment(
                attachment,
              );
          await SharePlus.instance.share(ShareParams(
            files: [
              XFile.fromData(bytes,
                  mimeType: attachment.contentType, name: attachment.name),
            ],
          ));
        });
