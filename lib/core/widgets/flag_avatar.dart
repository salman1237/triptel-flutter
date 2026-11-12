import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Circular flag image (country.flag_url), globe fallback for regionals/errors.
class FlagAvatar extends StatelessWidget {
  const FlagAvatar({super.key, this.flagUrl, this.size = 36});

  final String? flagUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final globe = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: AppColors.lilac100, shape: BoxShape.circle),
      child: Icon(Icons.public, size: size * 0.6, color: AppColors.primary),
    );

    if (flagUrl == null || flagUrl!.isEmpty) return globe;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: flagUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => globe,
        errorWidget: (_, __, ___) => globe,
      ),
    );
  }
}
