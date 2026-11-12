import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';
import 'flag_avatar.dart';

/// White list row: flag, name, optional network/"5G" tag, chevron.
class CountryRow extends StatelessWidget {
  const CountryRow({
    super.key,
    required this.name,
    this.flagUrl,
    this.subtitle,
    this.onTap,
  });

  final String name;
  final String? flagUrl;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            FlagAvatar(flagUrl: flagUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.body()),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            AppTypography.caption(color: AppColors.inkMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
