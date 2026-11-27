class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.balance,
    required this.winning,
    required this.referCode,
    required this.totalRefer,
    required this.totalPlay,
    required this.totalKill,
    required this.totalWin,
    required this.status,
    this.avatarUrl,
    this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final double balance;
  final double winning;
  final String referCode;
  final int totalRefer;
  final int totalPlay;
  final int totalKill;
  final double totalWin;
  final String status;
  final String? avatarUrl;
  final String? createdAt;

  double get total => balance + winning;
  bool get isBanned => status == 'banned';

  static double _d(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;
  static int _i(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: _i(j['id']),
        name: j['name'] ?? '',
        email: j['email'] ?? '',
        phone: j['phone'] ?? '',
        balance: _d(j['balance']),
        winning: _d(j['winning']),
        referCode: j['refer_code'] ?? '',
        totalRefer: _i(j['total_refer']),
        totalPlay: _i(j['total_play']),
        totalKill: _i(j['total_kill']),
        totalWin: _d(j['total_win']),
        status: j['status'] ?? 'active',
        avatarUrl: (j['avatar_url'] as String?)?.isEmpty ?? true ? null : j['avatar_url'],
        createdAt: j['created_at'],
      );

  AppUser copyWith({String? name, double? balance, double? winning, String? avatarUrl}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone,
        balance: balance ?? this.balance,
        winning: winning ?? this.winning,
        referCode: referCode,
        totalRefer: totalRefer,
        totalPlay: totalPlay,
        totalKill: totalKill,
        totalWin: totalWin,
        status: status,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );
}

class AuthResult {
  AuthResult(this.user, this.access, this.refresh, this.accessExpiresAt);
  final AppUser user;
  final String access;
  final String refresh;
  final int accessExpiresAt;

  factory AuthResult.fromJson(Map<String, dynamic> j) {
    final tk = j['tokens'] as Map<String, dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return AuthResult(
      AppUser.fromJson((j['user'] as Map).cast<String, dynamic>()),
      tk['access_token'] as String,
      tk['refresh_token'] as String,
      (tk['expires_at'] ?? now + (tk['expires_in'] as num).toInt()).toInt(),
    );
  }
}
