class Slider {
  Slider(this.image, this.link);
  final String image;
  final String link;
  factory Slider.fromJson(Map<String, dynamic> j) =>
      Slider(j['image_url'] ?? '', j['link'] ?? '');
}

class LeaderRow {
  LeaderRow({
    required this.rank,
    required this.name,
    required this.prize,
    required this.kills,
    required this.wins,
    required this.isMe,
    this.avatarUrl,
    this.metric = 0,
  });
  final int rank;
  final String name;
  final double prize;
  final int kills;
  final int wins;
  final bool isMe;
  final String? avatarUrl;

  /// the value for the currently selected sort (wins / earnings / kills)
  final num metric;

  factory LeaderRow.fromJson(Map<String, dynamic> j) => LeaderRow(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        name: j['name'] ?? '',
        prize: double.tryParse('${j['prize'] ?? 0}') ?? 0,
        kills: (j['kills'] as num?)?.toInt() ?? 0,
        wins: (j['wins'] as num?)?.toInt() ?? 0,
        isMe: j['is_me'] == true,
        avatarUrl: (j['avatar_url'] as String?)?.isEmpty ?? true ? null : j['avatar_url'],
        metric: (j['metric'] as num?) ?? double.tryParse('${j['metric'] ?? 0}') ?? 0,
      );
}

class ReferInfo {
  ReferInfo({
    required this.referCode,
    required this.totalRefer,
    required this.totalEarned,
    required this.bonusRule,
    required this.shareText,
    required this.appLink,
  });
  final String referCode;
  final int totalRefer;
  final double totalEarned;
  final String bonusRule;
  final String shareText;
  final String appLink;

  factory ReferInfo.fromJson(Map<String, dynamic> j) => ReferInfo(
        referCode: j['refer_code'] ?? '',
        totalRefer: (j['total_refer'] as num?)?.toInt() ?? 0,
        totalEarned: double.tryParse('${j['total_earned'] ?? 0}') ?? 0,
        bonusRule: j['bonus_rule'] ?? '',
        shareText: j['share_text'] ?? '',
        appLink: j['app_link'] ?? '',
      );
}

class Referral {
  Referral({required this.name, required this.joinedAt, required this.deposited, this.avatarUrl});
  final String name;
  final String joinedAt;
  final double deposited;
  final String? avatarUrl;
  factory Referral.fromJson(Map<String, dynamic> j) => Referral(
        name: j['name'] ?? '',
        joinedAt: j['joined_at'] ?? '',
        deposited: double.tryParse('${j['deposited'] ?? 0}') ?? 0,
        avatarUrl: (j['avatar_url'] as String?)?.isEmpty ?? true ? null : j['avatar_url'],
      );
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
    this.data = const {},
  });
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;
  final String? imageUrl;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        isRead: j['is_read'] == true,
        createdAt: j['created_at'] ?? '',
        imageUrl: (j['image_url'] as String?)?.isEmpty ?? true ? null : j['image_url'],
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
