import 'package:intl/intl.dart';

/// Formatting helpers. Powered by NeXdEvE.
class Fmt {
  Fmt._();

  static final _money = NumberFormat('#,##0.00', 'en_US');
  static final _moneyCompact = NumberFormat('#,##0.##', 'en_US');

  /// ৳1,250.00
  static String taka(dynamic v) => '৳${_money.format(_toNum(v))}';

  /// ৳1,250 (drops .00)
  static String takaShort(dynamic v) => '৳${_moneyCompact.format(_toNum(v))}';

  static String plain(dynamic v) => _money.format(_toNum(v));

  static num _toNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// "12 Jan, 09:45 PM"
  static String matchTime(String iso) {
    final d = DateTime.tryParse(iso.replaceFirst(' ', 'T'))?.toLocal();
    if (d == null) return iso;
    return DateFormat('d MMM, hh:mm a').format(d);
  }

  static String dayMonth(String iso) {
    final d = DateTime.tryParse(iso.replaceFirst(' ', 'T'))?.toLocal();
    if (d == null) return iso;
    return DateFormat('d MMM yyyy').format(d);
  }

  static String dateTime(String iso) {
    final d = DateTime.tryParse(iso.replaceFirst(' ', 'T'))?.toLocal();
    if (d == null) return iso;
    return DateFormat('d MMM yyyy, hh:mm a').format(d);
  }

  static String relative(String iso) {
    final d = DateTime.tryParse(iso.replaceFirst(' ', 'T'))?.toLocal();
    if (d == null) return iso;
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(d);
  }

  /// Countdown to a future time, or "LIVE" / "" when past.
  static String countdown(String iso) {
    final d = DateTime.tryParse(iso.replaceFirst(' ', 'T'))?.toLocal();
    if (d == null) return '';
    final diff = d.difference(DateTime.now());
    if (diff.isNegative) return 'Starting…';
    if (diff.inDays > 0) return 'in ${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return 'in ${diff.inMinutes}m';
    return 'in ${diff.inSeconds}s';
  }
}
