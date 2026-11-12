import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

class PaymentMethodOption {
  const PaymentMethodOption(
      {required this.id, required this.label, this.subtitle, this.icon});
  final String id;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// Bottom sheet listing payment methods (FR-305: shown only when wallet doesn't
/// already cover the total).
class PaymentMethodSheet extends StatelessWidget {
  const PaymentMethodSheet(
      {super.key, required this.options, required this.onSelected});

  final List<PaymentMethodOption> options;
  final ValueChanged<String> onSelected;

  static Future<String?> show(
      BuildContext context, List<PaymentMethodOption> options) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (context) => PaymentMethodSheet(
        options: options,
        onSelected: (id) => Navigator.of(context).pop(id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose payment method', style: AppTypography.headline()),
            const SizedBox(height: 12),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(option.icon ?? Icons.payment,
                    color: AppColors.primary),
                title: Text(option.label, style: AppTypography.body()),
                subtitle: option.subtitle != null
                    ? Text(option.subtitle!,
                        style: AppTypography.caption(color: AppColors.inkMuted))
                    : null,
                onTap: () => onSelected(option.id),
              ),
          ],
        ),
      ),
    );
  }
}
