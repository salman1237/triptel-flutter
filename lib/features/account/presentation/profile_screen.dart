import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/models/current_user.dart';

/// FR-1002: Profile. Avatar (real `avatar_url` if present, else a plain
/// placeholder -- no upload endpoint is documented, so no upload UI),
/// name/username, email + a real verified badge (`email_verified`), a
/// real Google-linked badge (`has_google`), phone edit (`PUT /auth/me/
/// preferences`), and a link to the existing change-password screen
/// (FR-105's `/set-password`, reused as-is -- it already does exactly
/// this, forced or voluntary).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return TriptelScaffold(
      key: const ValueKey('profile-screen'),
      appBar: AppBar(title: const Text('Profile')),
      body: switch (userAsync) {
        AsyncData(:final value) => _ProfileBody(user: value),
        AsyncError() => Center(
            child: ErrorState(
              message: "We couldn't load your profile.",
              onRetry: () => ref.invalidate(currentUserProvider),
            ),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.user});

  final CurrentUser user;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.user.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhone() async {
    setState(() => _saving = true);
    try {
      await ref.read(authApiProvider).updatePhone(_phoneController.text.trim());
      if (!mounted) return;
      ref.invalidate(currentUserProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone number saved.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            key: const ValueKey('profile-avatar'),
            radius: 40,
            backgroundColor: AppColors.lilac100,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(user.fullName ?? user.username,
            textAlign: TextAlign.center, style: AppTypography.title()),
        Text('@${user.username}',
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: AppColors.inkMuted)),
        const SizedBox(height: 16),
        ListGroup(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(user.email, style: AppTypography.body())),
                  StatusDot(
                    label: user.emailVerified ? 'Verified' : 'Not verified',
                    tone: user.emailVerified
                        ? StatusTone.success
                        : StatusTone.danger,
                  ),
                ],
              ),
            ),
            if (user.hasGoogle)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.primary, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Text('Google account linked',
                            style: AppTypography.body())),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('profile-phone-field'),
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: 8),
        PillButton(
          key: const ValueKey('profile-save-phone-button'),
          label: _saving ? 'Saving...' : 'Save phone',
          fullWidth: false,
          onPressed: _saving ? null : _savePhone,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: const ValueKey('profile-change-password-button'),
          label: 'Change password',
          variant: PillButtonVariant.secondary,
          onPressed: () => context.push('/set-password'),
        ),
      ],
    );
  }
}
