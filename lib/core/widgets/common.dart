import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../format.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'bz_card.dart';

/// A countdown that ticks every second, entirely on-device — no API calls.
/// Shows [liveLabel] once [target] is reached.
class LiveCountdown extends StatefulWidget {
  const LiveCountdown(
    this.target, {
    super.key,
    this.style,
    this.prefix = '',
    this.liveLabel = 'LIVE',
    this.liveStyle,
  });

  final DateTime target;
  final TextStyle? style;
  final String prefix;
  final String liveLabel;
  final TextStyle? liveStyle;

  @override
  State<LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<LiveCountdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.target.difference(DateTime.now());
    if (left.isNegative || left.inSeconds == 0) {
      return Text(widget.liveLabel, style: widget.liveStyle ?? widget.style);
    }
    return Text('${widget.prefix}${_fmt(left)}', style: widget.style);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmt(Duration d) {
    final h = _two(d.inHours % 24);
    final m = _two(d.inMinutes % 60);
    final s = _two(d.inSeconds % 60);
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h ${m}m';
    if (d.inHours > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

/// gradient-filled headline
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.gradient, this.textAlign});
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (b) => (gradient ??
              const LinearGradient(colors: [Colors.white, AppColors.primaryHi]))
          .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
      child: Text(text, style: style ?? AppText.h1, textAlign: textAlign),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: AppText.label.copyWith(color: AppColors.text, fontSize: 12.5, letterSpacing: 1.6)),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(children: [
                Text(actionLabel!, style: AppText.bodyS.copyWith(color: AppColors.primaryHi, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryHi),
              ]),
            ),
        ],
      ),
    );
  }
}

/// small status pill (LIVE / UPCOMING / JOINED …)
class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.color = AppColors.primary, this.icon, this.pulse = false});
  final String text;
  final Color color;
  final IconData? icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    if (pulse) {
      dot = dot.animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 700.ms).then().fade(begin: 1, end: 0.35, duration: 700.ms);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 9 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 11, color: color) else dot,
          const SizedBox(width: 5),
          Text(text.toUpperCase(), style: TextStyle(fontFamily: AppText.display, color: color, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

/// balance / stat tile with an animated count-up
class MoneyTile extends StatelessWidget {
  const MoneyTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });
  final String label;
  final double value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BzCard(
      padding: const EdgeInsets.all(15),
      borderColor: accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label.toUpperCase(), style: AppText.label.copyWith(fontSize: 9.5))),
            ],
          ),
          const SizedBox(height: 12),
          MoneyText(value, style: AppText.numXl.copyWith(fontSize: 20, color: accent)),
        ],
      ),
    );
  }
}

/// ৳ amount that animates from its previous value
class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.style, this.prefix = '৳'});
  final double value;
  final TextStyle? style;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${Fmt.plain(v)}', style: style ?? AppText.numL),
    );
  }
}

class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.label, required this.value, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value, style: AppText.numM.copyWith(fontSize: 13, color: color ?? AppColors.text)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: AppText.label.copyWith(fontSize: 8.5, letterSpacing: 0.8)),
        ],
      );
}

/// thin gradient progress bar
class FillBar extends StatelessWidget {
  const FillBar({super.key, required this.ratio, this.height = 6});
  final double ratio;
  final double height;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: height, color: AppColors.cardHi),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0, 1)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => FractionallySizedBox(
              widthFactor: v,
              child: Container(height: height, decoration: const BoxDecoration(gradient: AppColors.primaryGradH)),
            ),
          ),
        ],
      ),
    );
  }
}

class KV extends StatelessWidget {
  const KV(this.k, this.v, {super.key, this.valueStyle});
  final String k, v;
  final TextStyle? valueStyle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(k, style: AppText.bodyM)),
            const SizedBox(width: 12),
            Flexible(child: Text(v, textAlign: TextAlign.right, style: valueStyle ?? AppText.bodyStrong)),
          ],
        ),
      );
}

/// staggered entrance for list children
extension AnimateStagger on Widget {
  Widget stagger(int index) => animate()
      .fadeIn(duration: 320.ms, delay: (40 * index).ms)
      .slideY(begin: 0.08, end: 0, duration: 320.ms, delay: (40 * index).ms, curve: Curves.easeOutCubic);
}
