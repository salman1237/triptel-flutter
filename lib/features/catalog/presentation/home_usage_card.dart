import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../esims/application/esim_usage_shape.dart';
import '../../esims/data/models/esim_status.dart';
import '../../esims/data/models/my_esim.dart';

/// FR-201b: replaces Home's empty hero for a signed-in user with an active
/// eSIM. Shows [status]'s real usage ring/remaining data and validity
/// countdown (same pure functions FR-403's detail screen uses, so the two
/// screens can never disagree about what "X left"/"Y days left" means) --
/// tapping the card opens that eSIM's real detail screen; "Buy more data"
/// still reaches the explore sheet, since this card replaces the hero's
/// search entry point too.
class HomeUsageCard extends StatelessWidget {
  const HomeUsageCard({
    super.key,
    required this.esim,
    required this.status,
    required this.onViewEsim,
    required this.onBuyMore,
    DateTime? now,
  }) : _now = now;

  final MyEsim esim;
  final EsimStatus status;
  final VoidCallback onViewEsim;
  final VoidCallback onBuyMore;
  final DateTime? _now;

  @override
  Widget build(BuildContext context) {
    final fraction = usageFraction(status.usage);
    final centerText = usageCenterText(status.usage);
    final countdown =
        validityCountdownLabel(status.validity, _now ?? DateTime.now());

    return HeroHeader(
      child: InkWell(
        key: const ValueKey('home-usage-card'),
        onTap: onViewEsim,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(
          children: [
            UsageRing(
              fraction: fraction,
              centerText: centerText,
              size: 88,
              textColor: AppColors.surface,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.product.title,
                      style: AppTypography.title(color: AppColors.surface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(countdown,
                      style: AppTypography.body(color: AppColors.surface)),
                  const SizedBox(height: 12),
                  PillButton(
                    key: const ValueKey('home-usage-card-buy-more'),
                    label: 'Buy more data',
                    fullWidth: false,
                    onPressed: onBuyMore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
