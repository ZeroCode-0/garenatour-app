import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/bz_snack.dart';

/// Opens an external link reliably.
///
/// We deliberately do NOT gate on `canLaunchUrl` — on Android 11+ it returns
/// false unless every target intent is declared in the manifest `<queries>`,
/// which silently breaks perfectly valid https links. Instead we just try to
/// launch, walking through launch modes, and only surface an error if every
/// attempt throws.
Future<void> openLink(BuildContext? context, String? raw) async {
  final url = _normalize(raw);
  if (url == null) {
    if (context != null && context.mounted) {
      showSnack(context, 'No link attached.', kind: SnackKind.error);
    }
    return;
  }

  final uri = Uri.parse(url);
  for (final mode in const [
    LaunchMode.externalApplication,
    LaunchMode.externalNonBrowserApplication,
    LaunchMode.platformDefault,
  ]) {
    try {
      if (await launchUrl(uri, mode: mode)) return;
    } catch (_) {
      // try the next mode
    }
  }
  if (context != null && context.mounted) {
    showSnack(context, "Couldn't open the link.", kind: SnackKind.error);
  }
}

/// Adds a scheme when the admin typed a bare domain like `t.me/xyz`.
String? _normalize(String? raw) {
  var s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  if (s.startsWith('mailto:') || s.startsWith('tel:')) return s;
  if (!s.contains('://')) s = 'https://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty) return null;
  return s;
}
