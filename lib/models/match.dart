class MatchType {
  MatchType({
    required this.code,
    required this.name,
    required this.iconUrl,
    this.cardImage,
    this.rules,
    this.liveCount = 0,
  });
  final String code;
  final String name;
  final String iconUrl;
  final String? cardImage;
  final String? rules;
  final int liveCount;

  factory MatchType.fromJson(Map<String, dynamic> j) => MatchType(
        code: j['code'] ?? '',
        name: j['name'] ?? '',
        iconUrl: j['icon_url'] ?? '',
        cardImage: (j['card_image'] as String?)?.isEmpty ?? true ? null : j['card_image'] as String,
        rules: j['rules'],
        liveCount: (j['live_count'] as num?)?.toInt() ?? 0,
      );
}

class GameMatch {
  GameMatch({
    required this.matchKey,
    required this.title,
    required this.type,
    required this.typeName,
    required this.mode,
    required this.map,
    required this.startAt,
    this.bannerUrl,
    this.numId,
    required this.entryFee,
    required this.perKill,
    required this.prizePool,
    required this.totalSlots,
    required this.joinedSlots,
    required this.status,
    required this.joined,
    required this.resultPublished,
    this.prizeDetails,
    this.rules,
    this.platform,
    this.room,
    this.myKills,
    this.myPrize,
    this.overview = const [],
    this.rewards = const [],
    this.teamModeLabel,
    this.teamSizeOverride,
  });

  final String matchKey;
  final String title;
  final String? type;
  final String? typeName;
  final String? bannerUrl;
  final int? numId;
  final String mode; // Solo | Duo | Squad
  final String map;
  final String startAt;
  final double entryFee;
  final double perKill;
  final double prizePool;
  final int totalSlots;
  final int joinedSlots;
  final String status; // upcoming | live | completed | cancelled
  final bool joined;
  final bool resultPublished;
  final String? prizeDetails;
  final String? rules;
  final String? platform;
  final RoomInfo? room;
  final int? myKills;
  final double? myPrize;

  /// admin-editable "About tournament" bullets: [{icon, text}]
  final List<MatchInfoItem> overview;

  /// admin-editable reward rows: [{label, amount, icon}]
  final List<MatchReward> rewards;
  final String? teamModeLabel;
  final int? teamSizeOverride;

  /// [startAt] parsed to a local DateTime (falls back to "now" if unparseable).
  DateTime get startAtDate =>
      DateTime.tryParse(startAt.replaceFirst(' ', 'T'))?.toLocal() ?? DateTime.now();

  int get slotsLeft => (totalSlots - joinedSlots).clamp(0, totalSlots);
  double get fillRatio => totalSlots == 0 ? 0 : joinedSlots / totalSlots;
  bool get isFull => slotsLeft <= 0;

  /// exact players required — server-set override, else mode-derived
  int get teamSize =>
      teamSizeOverride ?? (mode == 'Duo' ? 2 : (mode == 'Squad' ? 4 : 1));
  String get teamLabel => teamModeLabel ?? mode;

  static double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
  static int _i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

  factory GameMatch.fromJson(Map<String, dynamic> j) => GameMatch(
        matchKey: j['match_key'] ?? '',
        title: j['title'] ?? '',
        type: j['type'] ?? j['type_code'],
        typeName: j['type_name'],
        bannerUrl: (j['banner_url'] as String?)?.isEmpty ?? true ? null : j['banner_url'] as String?,
        numId: j['num_id'] != null ? _i(j['num_id']) : null,
        mode: j['mode'] ?? 'Solo',
        map: j['map'] ?? '',
        startAt: j['start_at'] ?? '',
        entryFee: _d(j['entry_fee']),
        perKill: _d(j['per_kill']),
        prizePool: _d(j['prize_pool']),
        totalSlots: _i(j['total_slots']),
        joinedSlots: _i(j['joined_slots']),
        status: j['status'] ?? 'upcoming',
        joined: j['joined'] == true,
        resultPublished: j['result_published'] == true,
        prizeDetails: j['prize_details'],
        rules: j['rules'],
        platform: j['platform'],
        room: j['room'] is Map ? RoomInfo.fromJson((j['room'] as Map).cast<String, dynamic>()) : null,
        myKills: j['my_kills'] != null ? _i(j['my_kills']) : null,
        myPrize: j['my_prize'] != null ? _d(j['my_prize']) : null,
        overview: (j['overview'] as List?)
                ?.whereType<Map>()
                .map((e) => MatchInfoItem.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        rewards: (j['rewards'] as List?)
                ?.whereType<Map>()
                .map((e) => MatchReward.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        teamModeLabel: (j['team_mode'] as String?)?.isEmpty ?? true ? null : j['team_mode'] as String?,
        teamSizeOverride: j['team_size'] != null && _i(j['team_size']) > 0 ? _i(j['team_size']) : null,
      );
}

/// One "About tournament" bullet.
class MatchInfoItem {
  MatchInfoItem(this.icon, this.text);
  final String icon; // key into iconForKey()
  final String text;
  factory MatchInfoItem.fromJson(Map<String, dynamic> j) =>
      MatchInfoItem('${j['icon'] ?? ''}', '${j['text'] ?? ''}');
}

/// One reward row.
class MatchReward {
  MatchReward(this.label, this.amount, this.icon);
  final String label;
  final String amount;
  final String icon;
  factory MatchReward.fromJson(Map<String, dynamic> j) =>
      MatchReward('${j['label'] ?? ''}', '${j['amount'] ?? ''}', '${j['icon'] ?? ''}');
}

class RoomInfo {
  RoomInfo({this.id, this.password, this.availableAt});
  final String? id;
  final String? password;
  final String? availableAt;

  bool get ready => id != null && id!.isNotEmpty;

  factory RoomInfo.fromJson(Map<String, dynamic> j) => RoomInfo(
        id: j['id'],
        password: j['password'],
        availableAt: j['available_at'],
      );
}

class MatchPlayer {
  MatchPlayer({required this.ign, this.slotNo = 1, this.kills = 0});
  final String ign;
  final int slotNo;
  final int kills;
  factory MatchPlayer.fromJson(Map<String, dynamic> j) => MatchPlayer(
        ign: j['ign'] ?? '',
        slotNo: (j['slot_no'] as num?)?.toInt() ?? 1,
        kills: (j['kills'] as num?)?.toInt() ?? 0,
      );
}

class MatchWinner {
  MatchWinner({required this.position, required this.ign, required this.kills, required this.prize});
  final int position;
  final String ign;
  final int kills;
  final double prize;
  factory MatchWinner.fromJson(Map<String, dynamic> j) => MatchWinner(
        position: (j['position'] as num?)?.toInt() ?? 0,
        ign: j['ign'] ?? '',
        kills: (j['kills'] as num?)?.toInt() ?? 0,
        prize: double.tryParse('${j['prize'] ?? 0}') ?? 0,
      );
}
