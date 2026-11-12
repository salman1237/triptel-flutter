import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Base screen scaffold: lilac background, optional hero at the top, gutter padding.
class TriptelScaffold extends StatelessWidget {
  const TriptelScaffold({
    super.key,
    required this.body,
    this.hero,
    this.bottomBar,
    this.appBar,
    this.scrollable = true,
  });

  final Widget body;
  final Widget? hero;
  final Widget? bottomBar;
  final PreferredSizeWidget? appBar;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: body,
    );

    return Scaffold(
      backgroundColor: AppColors.lilac50,
      appBar: appBar,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        top: hero == null,
        bottom: false,
        child: Column(
          children: [
            if (hero != null) hero!,
            Expanded(
              child:
                  scrollable ? SingleChildScrollView(child: content) : content,
            ),
          ],
        ),
      ),
    );
  }
}
