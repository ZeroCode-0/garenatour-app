class WalletSummary {
  WalletSummary(this.balance, this.winning);
  final double balance;
  final double winning;
  double get total => balance + winning;
  factory WalletSummary.fromJson(Map<String, dynamic> j) => WalletSummary(
        double.tryParse('${j['balance'] ?? 0}') ?? 0,
        double.tryParse('${j['winning'] ?? 0}') ?? 0,
      );
}

class DepositInfo {
  DepositInfo({
    required this.numbers,
    required this.minDeposit,
    required this.maxDeposit,
    this.helpLink,
    this.instructions = '',
  });
  final Map<String, String> numbers; // bkash/nagad/rocket -> number
  final double minDeposit;
  final double maxDeposit;
  final String? helpLink;
  final String instructions;

  factory DepositInfo.fromJson(Map<String, dynamic> j) => DepositInfo(
        numbers: ((j['numbers'] as Map?) ?? {}).map((k, v) => MapEntry(k.toString(), '$v')),
        minDeposit: double.tryParse('${j['min_deposit'] ?? 0}') ?? 0,
        maxDeposit: double.tryParse('${j['max_deposit'] ?? 0}') ?? 0,
        helpLink: (j['help_link'] as String?)?.isEmpty ?? true ? null : j['help_link'],
        instructions: j['instructions'] ?? '',
      );
}

class WithdrawInfo {
  WithdrawInfo({
    required this.winning,
    required this.minWithdraw,
    required this.maxWithdraw,
    required this.perDay,
    required this.usedToday,
    required this.canWithdraw,
    this.hasPin = false,
  });
  final double winning;
  final double minWithdraw;
  final double maxWithdraw;
  final int perDay;
  final int usedToday;
  final bool canWithdraw;
  final bool hasPin;

  factory WithdrawInfo.fromJson(Map<String, dynamic> j) => WithdrawInfo(
        winning: double.tryParse('${j['winning'] ?? 0}') ?? 0,
        minWithdraw: double.tryParse('${j['min_withdraw'] ?? 0}') ?? 0,
        maxWithdraw: double.tryParse('${j['max_withdraw'] ?? 0}') ?? 0,
        perDay: (j['per_day'] as num?)?.toInt() ?? 1,
        usedToday: (j['used_today'] as num?)?.toInt() ?? 0,
        canWithdraw: j['can_withdraw'] == true,
        hasPin: j['has_pin'] == true,
      );
}

class Txn {
  Txn({required this.kind, required this.title, required this.ref, required this.amount, required this.status, required this.at});
  final String kind; // deposit | withdraw | match
  final String title;
  final String ref;
  final double amount;
  final String status;
  final String at;

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        kind: j['kind'] ?? '',
        title: j['provider'] ?? j['title'] ?? '',
        ref: j['ref'] ?? j['trx_id'] ?? '',
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        status: j['status'] ?? '',
        at: j['created_at'] ?? j['time'] ?? '',
      );
}
