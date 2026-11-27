import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class PodiumEntry {
  const PodiumEntry({required this.name, required this.metric, this.avatarUrl});
  final String name;
  final String metric; // e.g. "24 Wins" or "৳3.1K"
  final String? avatarUrl;
}

/// Top-3 podium — #2 left, #1 centre (raised, crown, gold ring), #3 right.
class Podium extends StatelessWidget {
  const Podium({super.key, required this.entries});
  final List<PodiumEntry?> entries; // [first, second, third]

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _col(entries.length > 1 ? entries[1] : null, place: 2, h: 92, ring: const Color(0xFFC7C7D1))),
        Expanded(child: _col(entries.isNotEmpty ? entries[0] : null, place: 1, h: 124, ring: AppColors.gold)),
        Expanded(child: _col(entries.length > 2 ? entries[2] : null, place: 3, h: 74, ring: const Color(0xFFCD7F45))),
      ],
    );
  }

  Widget _col(PodiumEntry? e, {required int place, required double h, required Color ring}) {
    if (e == null) return const SizedBox.shrink();
    final avatarR = place == 1 ? 30.0 : 24.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (place == 1)
            const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 22)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -3, duration: 900.ms, curve: Curves.easeInOut),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [ring, ring.withValues(alpha: 0.4)])),
            child: CircleAvatar(
              radius: avatarR,
              backgroundColor: AppColors.cardHi,
              backgroundImage: e.avatarUrl != null ? CachedNetworkImageProvider(e.avatarUrl!) : null,
              child: e.avatarUrl == null
                  ? Text(e.name.isNotEmpty ? e.name[0].toUpperCase() : '?', style: AppText.h3)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(e.name, style: AppText.bodyStrong.copyWith(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(e.metric, style: AppText.numM.copyWith(fontSize: 11, color: ring)),
          const SizedBox(height: 7),
          Container(
            height: h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ring.withValues(alpha: 0.30), ring.withValues(alpha: 0.04)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: ring.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('$place', style: AppText.h1.copyWith(color: ring, fontSize: 26)),
          ).animate().slideY(begin: 0.4, end: 0, duration: 420.ms, delay: (place * 90).ms, curve: Curves.easeOutCubic).fadeIn(),
        ],
      ),
    );
  }
}

String kMetric(String sort, num v) => switch (sort) {
      'earnings' => Fmt.takaShort(v),
      'kills' => '${v.toInt()} Kills',
      _ => '${v.toInt()} Wins',
    };
