import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/launch.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/bz_background.dart';
import '../../core/widgets/bz_card.dart';
import '../../core/widgets/common.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  static const _telegram = 'https://t.me/nexdeveowner';
  static const _website = 'https://nexdeve.com/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer')),
      extendBodyBehindAppBar: true,
      body: BzBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Column(children: [
                  SvgPicture.asset('assets/icons/emblem.svg', width: 92)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 0, end: -4, duration: 1400.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 16),
                  const GradientText('NeXdEvE', style: TextStyle(fontFamily: AppText.display, fontWeight: FontWeight.w700, fontSize: 30)),
                  const SizedBox(height: 6),
                  Text('FULL-STACK GAME APP STUDIO', style: AppText.label.copyWith(letterSpacing: 3, fontSize: 10.5)),
                ]),
              ),
              const SizedBox(height: 28),
              const SectionHeader('About'),
              BzCard(
                child: Text(
                  'আপনার কি একটি প্রফেশনাল ওয়েবসাইট বা মোবাইল অ্যাপ্লিকেশন প্রয়োজন?\n\n'
                  'আমরা আধুনিক ও স্কেলেবল টেকনোলজি ব্যবহার করে সম্পূর্ণ কাস্টম সলিউশন তৈরি করি — '
                  'ফাস্ট, সিকিউর এবং প্রিমিয়াম।',
                  style: AppText.bodyM,
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader('What We Build'),
              BzCard(
                child: Column(children: const [
                  _Service(Icons.emoji_events_rounded, 'Tournament & Top-Up apps'),
                  _Service(Icons.smartphone_rounded, 'Android / iOS / Windows apps'),
                  _Service(Icons.dashboard_customize_rounded, 'Admin panels + backend systems'),
                  _Service(Icons.hub_rounded, 'API design & integration'),
                  _Service(Icons.storage_rounded, 'Database design & optimization'),
                  _Service(Icons.verified_user_rounded, 'Secure & scalable architecture'),
                ]),
              ),
              const SizedBox(height: 20),
              const SectionHeader('Contact'),
              _Link(icon: Icons.telegram_rounded, label: 'Telegram', sub: 't.me/nexdeveowner', onTap: () => openLink(context, _telegram)),
              const SizedBox(height: 10),
              _Link(icon: Icons.language_rounded, label: 'Website', sub: 'nexdeve.com', onTap: () => openLink(context, _website)),
              const SizedBox(height: 30),
              Center(child: Text('© ${DateTime.now().year}  ·  Garena Tour  ·  Powered by NeXdEvE',
                  style: AppText.tiny.copyWith(color: AppColors.textFaint), textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Service extends StatelessWidget {
  const _Service(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 17, color: AppColors.cyan),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.bodyM)),
        ]),
      );
}

class _Link extends StatelessWidget {
  const _Link({required this.icon, required this.label, required this.sub, required this.onTap});
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BzCard(
        onTap: onTap,
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(gradient: AppColors.primaryGrad, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(label, style: AppText.bodyStrong), Text(sub, style: AppText.bodyS)],
          ),
          const Spacer(),
          const Icon(Icons.open_in_new_rounded, size: 15, color: AppColors.textMuted),
        ]),
      );
}
