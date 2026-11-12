import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Pill search field used atop Explore / destination sheets.
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
    this.onClose,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [appCardShadow],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.inkMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.body(color: AppColors.inkMuted),
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTypography.body(),
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child:
                  const Icon(Icons.close, color: AppColors.inkMuted, size: 20),
            ),
        ],
      ),
    );
  }
}
