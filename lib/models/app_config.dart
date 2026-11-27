class AppConfig {
  AppConfig({
    required this.appStatus,
    required this.closeNotice,
    required this.notice,
    required this.links,
    required this.android,
    required this.ios,
    this.walletAbout = '',
    this.walletIncomeNote = '',
  });

  final String appStatus; // open | closed
  final String closeNotice;
  final String notice;
  final AppLinks links;
  final PlatformUpdate android;
  final PlatformUpdate ios;

  /// admin-editable text shown on the Wallet page
  final String walletAbout;
  final String walletIncomeNote;

  bool get isClosed => appStatus == 'closed';

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        appStatus: j['app_status'] ?? 'open',
        closeNotice: j['close_notice'] ?? 'Under maintenance.',
        notice: j['notice'] ?? '',
        links: AppLinks.fromJson((j['links'] as Map?)?.cast<String, dynamic>() ?? {}),
        android: PlatformUpdate.fromJson((j['android'] as Map?)?.cast<String, dynamic>() ?? {}),
        ios: PlatformUpdate.fromJson((j['ios'] as Map?)?.cast<String, dynamic>() ?? {}),
        walletAbout: '${(j['wallet'] as Map?)?['about'] ?? ''}',
        walletIncomeNote: '${(j['wallet'] as Map?)?['income_note'] ?? ''}',
      );
}

class AppLinks {
  AppLinks({this.support, this.depositHelp, this.youtube, this.facebook, this.telegram});
  final String? support, depositHelp, youtube, facebook, telegram;

  static String? _s(dynamic v) => (v == null || '$v'.isEmpty) ? null : '$v';

  factory AppLinks.fromJson(Map<String, dynamic> j) => AppLinks(
        support: _s(j['support']),
        depositHelp: _s(j['deposit_help']),
        youtube: _s(j['youtube']),
        facebook: _s(j['facebook']),
        telegram: _s(j['telegram']),
      );
}

class PlatformUpdate {
  PlatformUpdate({
    required this.version,
    required this.build,
    required this.forceUpdate,
    this.updateLink,
    this.updateNotice,
  });

  final String version;
  final int build;
  final bool forceUpdate;
  final String? updateLink;
  final String? updateNotice;

  factory PlatformUpdate.fromJson(Map<String, dynamic> j) => PlatformUpdate(
        version: j['version'] ?? '1.0.0',
        build: (j['build'] as num?)?.toInt() ?? 1,
        forceUpdate: j['force_update'] == true,
        updateLink: (j['update_link'] as String?)?.isEmpty ?? true ? null : j['update_link'],
        updateNotice: (j['update_notice'] as String?)?.isEmpty ?? true ? null : j['update_notice'],
      );
}
