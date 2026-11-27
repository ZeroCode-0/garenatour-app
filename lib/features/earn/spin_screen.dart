import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_button.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/bz_snack.dart';
import '../../core/widgets/bz_states.dart';
import '../auth/auth_controller.dart';
import '../extras/extras_repository.dart';
import '../wallet/wallet_repository.dart';

class SpinScreen extends ConsumerStatefulWidget {
  const SpinScreen({super.key});

  @override
  ConsumerState<SpinScreen> createState() => _SpinScreenState();
}

class _SpinScreenState extends ConsumerState<SpinScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );
  late Animation<double> _animation;
  double _currentAngle = 0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _animation = Tween<double>(begin: 0, end: 0).animate(_animCtrl);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSpin(Map<String, dynamic> data) async {
    if (_spinning) return;
    final canFree = data['can_free_spin'] == true;
    final coinCost = (data['coin_cost'] as num?)?.toInt() ?? 20;
    final userCoins = (data['user_coins'] as num?)?.toInt() ?? 0;

    if (!canFree && userCoins < coinCost) {
      showSnack(context, 'You need $coinCost coins to spin. Watch ads to earn coins!', kind: SnackKind.error);
      return;
    }

    setState(() => _spinning = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await ref.read(extrasRepoProvider).spinPlay();
      final targetSlice = (res['slice_index'] as num?)?.toInt() ?? 0;
      final slicesCount = ((data['slices'] as List?)?.length ?? 8);

      // Slices are laid out clockwise. Pointer is at 12 o'clock (top, 270 deg / -pi/2).
      // Calculate target rotation angle (5 full rotations + offset for slice)
      const double fullRotations = 5 * 2 * pi;
      final double sliceAngle = (2 * pi) / slicesCount;
      // Center of target slice
      final double targetSliceAngle = (targetSlice * sliceAngle) + (sliceAngle / 2);
      // We want slice at top (3*pi/2), so target rotation = fullRotations + (3*pi/2 - targetSliceAngle)
      final double targetFinalAngle = _currentAngle + fullRotations + (2 * pi - targetSliceAngle);

      _animation = Tween<double>(
        begin: _currentAngle,
        end: targetFinalAngle,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

      _animCtrl.reset();
      await _animCtrl.forward();

      _currentAngle = targetFinalAngle % (2 * pi);
      HapticFeedback.heavyImpact();

      // Invalidate providers to update coins and wallet
      ref.invalidate(spinProvider);
      ref.read(extrasRefreshProvider.notifier).state++;
      ref.read(walletRefreshProvider.notifier).state++;
      ref.read(authControllerProvider.notifier).patchWallet(
            balance: double.tryParse('${res['user_balance'] ?? ''}'),
          );

      if (mounted) {
        _showWinnerDialog(res);
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, kind: SnackKind.error);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not spin. Please try again.', kind: SnackKind.error);
    } finally {
      if (mounted) setState(() => _spinning = false);
    }
  }

  void _showWinnerDialog(Map<String, dynamic> res) {
    final msg = res['message'] ?? 'Congratulations!';
    final type = res['prize_type'] ?? 'none';
    final isNone = type == 'none';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isNone ? AppColors.line : AppColors.gold, width: 1.5),
        ),
        title: Text(
          isNone ? 'Good Try!' : '🎉 WINNER!',
          textAlign: TextAlign.center,
          style: AppText.h2.copyWith(color: isNone ? AppColors.textDim : AppColors.gold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNone ? '💔' : (type == 'cash' ? '💰' : '🪙'),
              style: const TextStyle(fontSize: 54),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: AppText.bodyM,
            ),
          ],
        ),
        actions: [
          Center(
            child: BzButton(
              label: 'CLAIM REWARD',
              kind: BzBtn.primary,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spinAsync = ref.watch(spinProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lucky Spin & Win'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showRules(context),
          ),
        ],
      ),
      body: BzBackground(
        child: SafeArea(
          child: spinAsync.when(
            loading: () => const BzLoader(label: 'Loading Lucky Wheel…'),
            error: (e, _) => BzError(message: '$e', onRetry: () => ref.invalidate(spinProvider)),
            data: (d) {
              final slices = ((d['slices'] as List?) ?? []).cast<Map<String, dynamic>>();
              final canFree = d['can_free_spin'] == true;
              final coinCost = (d['coin_cost'] as num?)?.toInt() ?? 20;
              final userCoins = (d['user_coins'] as num?)?.toInt() ?? 0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                children: [
                  BzCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('YOUR COINS', style: AppText.label.copyWith(fontSize: 10, color: AppColors.textDim)),
                                Text('$userCoins Coins', style: AppText.bodyStrong.copyWith(color: AppColors.gold)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: canFree ? AppColors.success.withValues(alpha: 0.15) : AppColors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: canFree ? AppColors.success : AppColors.line),
                          ),
                          child: Text(
                            canFree ? '✨ 1 Free Spin Ready' : 'Cost: $coinCost Coins/Spin',
                            style: AppText.label.copyWith(
                              color: canFree ? AppColors.success : AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Wheel area
                  Center(
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow circle
                          Container(
                            width: 310,
                            height: 310,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          // The rotating wheel
                          AnimatedBuilder(
                            animation: _animCtrl,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _spinning ? _animation.value : _currentAngle,
                                child: CustomPaint(
                                  size: const Size(300, 300),
                                  painter: _WheelPainter(slices: slices),
                                ),
                              );
                            },
                          ),
                          // Top pointer (Indicator)
                          Positioned(
                            top: 0,
                            child: CustomPaint(
                              size: const Size(28, 36),
                              painter: _PointerPainter(),
                            ),
                          ),
                          // Center cap
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                              ),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'SPIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Action button
                  BzButton(
                    label: canFree ? '🎰 FREE SPIN NOW' : '🎰 SPIN ($coinCost COINS)',
                    kind: BzBtn.primary,
                    loading: _spinning,
                    onPressed: _spinning ? null : () => _startSpin(d),
                  ),
                  const SizedBox(height: 12),
                  if (!canFree)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/earn'),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 18, color: AppColors.primaryHi),
                        label: Text('Need more coins? Watch Ads', style: AppText.bodyS.copyWith(color: AppColors.primaryHi)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardHi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lucky Spin Rules', style: AppText.h2),
            const SizedBox(height: 12),
            const Text('• Every player gets 1 Free Spin every 24 hours.'),
            const SizedBox(height: 6),
            const Text('• Extra spins cost 20 coins each (earned from watching rewarded ads).'),
            const SizedBox(height: 6),
            const Text('• Cash rewards are added directly to your deposit balance.'),
            const SizedBox(height: 6),
            const Text('• Coin rewards are credited instantly to your coin purse.'),
          ],
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.slices});
  final List<Map<String, dynamic>> slices;

  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFFDD835),
    Color(0xFFFB8C00),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final count = max(slices.length, 1);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * pi) / count;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF222230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < count; i++) {
      paint.color = _palette[i % _palette.length];
      final startAngle = i * sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw label
      final label = slices[i]['label'] ?? '';
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(startAngle + sweepAngle / 2);

      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(radius * 0.45, -textPainter.height / 2));
      canvas.restore();
    }

    // Outer rim
    final rimPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, radius - 3, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => false;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
