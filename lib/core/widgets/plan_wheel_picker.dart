import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../theme/typography.dart';

/// Vertical wheel picker over data sizes (or days), selected row drawn as a
/// white pill card, Design_System.md §2 (country plans).
class PlanWheelPicker extends StatefulWidget {
  const PlanWheelPicker({
    super.key,
    required this.labels,
    this.initialIndex = 0,
    this.onChanged,
  });

  final List<String> labels;
  final int initialIndex;
  final ValueChanged<int>? onChanged;

  @override
  State<PlanWheelPicker> createState() => _PlanWheelPickerState();
}

class _PlanWheelPickerState extends State<PlanWheelPicker> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 56,
        perspective: 0.004,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: widget.onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: widget.labels.length,
          builder: (context, index) {
            final selected = _controller.selectedItem == index;
            return Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: selected
                    ? BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: const [appCardShadow],
                      )
                    : null,
                child: Text(
                  widget.labels[index],
                  style: selected
                      ? AppTypography.headline(color: AppColors.primary)
                      : AppTypography.body(color: AppColors.inkMuted),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
