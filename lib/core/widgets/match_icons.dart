import 'package:flutter/material.dart';

/// Maps an admin-chosen icon key (stored with a match overview bullet or reward
/// row) to a Material icon. Unknown keys fall back to a neutral dot.
IconData matchIcon(String key) {
  switch (key.trim().toLowerCase()) {
    case 'groups':
    case 'players':
    case 'team':
      return Icons.groups_rounded;
    case 'shield':
    case 'fairplay':
    case 'secure':
      return Icons.shield_rounded;
    case 'ban':
    case 'nohack':
    case 'block':
      return Icons.block_rounded;
    case 'trophy':
    case 'winner':
      return Icons.emoji_events_rounded;
    case 'medal':
    case 'rank':
      return Icons.military_tech_rounded;
    case 'crown':
    case 'king':
      return Icons.workspace_premium_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'timer':
    case 'clock':
    case 'time':
      return Icons.schedule_rounded;
    case 'map':
    case 'location':
      return Icons.map_rounded;
    case 'gun':
    case 'weapon':
      return Icons.sports_martial_arts_rounded;
    case 'target':
    case 'aim':
    case 'kill':
      return Icons.gps_fixed_rounded;
    case 'fire':
    case 'hot':
      return Icons.local_fire_department_rounded;
    case 'bolt':
    case 'fast':
      return Icons.bolt_rounded;
    case 'cash':
    case 'money':
    case 'prize':
    case 'taka':
      return Icons.payments_rounded;
    case 'gift':
    case 'reward':
      return Icons.card_giftcard_rounded;
    case 'warning':
    case 'alert':
      return Icons.warning_amber_rounded;
    case 'info':
      return Icons.info_outline_rounded;
    case 'check':
    case 'ok':
      return Icons.check_circle_rounded;
    case 'phone':
    case 'mobile':
      return Icons.smartphone_rounded;
    case 'wifi':
    case 'ping':
      return Icons.wifi_rounded;
    case 'record':
    case 'video':
      return Icons.videocam_rounded;
    case 'discord':
      return Icons.forum_rounded;
    case 'rule':
    case 'rules':
      return Icons.gavel_rounded;
    default:
      return Icons.chevron_right_rounded;
  }
}

/// The keys an admin can choose from (kept in sync with [matchIcon]).
const kMatchIconKeys = <String>[
  'groups', 'shield', 'ban', 'trophy', 'medal', 'crown', 'star',
  'timer', 'map', 'gun', 'target', 'fire', 'bolt', 'cash', 'gift',
  'warning', 'info', 'check', 'phone', 'wifi', 'record', 'rules',
];
