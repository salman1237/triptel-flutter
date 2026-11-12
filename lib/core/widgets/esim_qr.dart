import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/tokens.dart';

/// eSIM activation QR. Rules.md: error correction H, logo 22% of QR width on a
/// white circular disc, app mark (not wordmark). Changing these needs a damage
/// test (see test/features/esims) before shipping.
class EsimQr extends StatelessWidget {
  const EsimQr({super.key, required this.data, this.size = 220, this.logo});

  final String data;
  final double size;
  final Widget? logo;

  static const logoFraction = 0.22;

  @override
  Widget build(BuildContext context) {
    final logoSize = size * logoFraction;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: data,
            size: size,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            backgroundColor: AppColors.surface,
          ),
          if (logo != null)
            Container(
              width: logoSize + 8,
              height: logoSize + 8,
              decoration: const BoxDecoration(
                  color: AppColors.surface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SizedBox(width: logoSize, height: logoSize, child: logo),
            ),
        ],
      ),
    );
  }
}
