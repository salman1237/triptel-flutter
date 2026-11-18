import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/install/url_launcher_provider.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../bootstrap/application/bootstrap_providers.dart';
import '../../bootstrap/data/models/public_settings.dart';
import '../application/contact_shortcuts.dart';

/// FR-1104: WhatsApp/phone/email shortcuts from `GET /settings/public`
/// (API.md section 1) -- each row only shows when its field is real and
/// non-null, never invented or hidden-as-a-whole for one missing field.
Future<void> showContactShortcutsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ContactShortcutsSheet(),
  );
}

class ContactShortcutsSheet extends ConsumerWidget {
  const ContactShortcutsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrapAsync = ref.watch(bootstrapProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lilac50,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, 20, AppSpacing.gutter, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact us', style: AppTypography.headline()),
            const SizedBox(height: 16),
            switch (bootstrapAsync) {
              AsyncData(:final value) => _Rows(settings: value.settings),
              AsyncError() => Text(
                  "We couldn't load contact details.",
                  style: AppTypography.body(color: AppColors.inkMuted),
                ),
              _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            },
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({required this.settings});

  final PublicSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whatsapp = settings.supportWhatsapp;
    final phone = settings.supportPhone;
    final email = settings.supportEmail;
    final launch = ref.read(urlLauncherProvider);

    if (whatsapp == null && phone == null && email == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyState(
          icon: Icons.support_agent_outlined,
          message: 'No contact details are available right now.',
        ),
      );
    }

    return ListGroup(
      children: [
        if (whatsapp != null)
          ListRow(
            key: const ValueKey('contact-whatsapp-row'),
            icon: Icons.chat_bubble_outline,
            title: 'WhatsApp',
            subtitle: whatsapp,
            onTap: () => launch(contactWhatsappUri(whatsapp)),
          ),
        if (phone != null)
          ListRow(
            key: const ValueKey('contact-phone-row'),
            icon: Icons.call_outlined,
            title: 'Call us',
            subtitle: phone,
            onTap: () => launch(contactPhoneUri(phone)),
          ),
        if (email != null)
          ListRow(
            key: const ValueKey('contact-email-row'),
            icon: Icons.email_outlined,
            title: 'Email us',
            subtitle: email,
            onTap: () => launch(contactEmailUri(email)),
          ),
      ],
    );
  }
}
