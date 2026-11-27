import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'mode_visual.dart';

/// Match cover art: the admin-set banner image (with a readability scrim) or,
/// if none, a themed painted gradient with the mode glyph.
class MatchBanner extends StatelessWidget {
  const MatchBanner({super.key, required this.typeCode, this.imageUrl, this.height, this.fit = BoxFit.cover});
  final String? typeCode;
  final String? imageUrl;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox(height: height, child: ModeArt(code: typeCode));
    }
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            memCacheWidth: 600,
            memCacheHeight: 340,
            maxWidthDiskCache: 800,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (_, __) => ModeArt(code: typeCode, glyphOpacity: 0.10),
            errorWidget: (_, __, ___) => ModeArt(code: typeCode),
          ),
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.imageScrim)),
        ],
      ),
    );
  }
}
