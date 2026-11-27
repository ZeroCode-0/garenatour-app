import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/wallet/wallet_repository.dart';
import 'package:app/features/matches/match_list_controller.dart';

void main() {
  test('MatchQuery equality and hashing works for caching', () {
    const q1 = MatchQuery(typeCode: 'CS', status: 'upcoming');
    const q2 = MatchQuery(typeCode: 'CS', status: 'upcoming');
    const q3 = MatchQuery(typeCode: 'BR', status: 'upcoming');

    expect(q1, equals(q2));
    expect(q1.hashCode, equals(q2.hashCode));
    expect(q1 == q3, isFalse);
  });

  test('Wallet refresh provider increments properly', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(walletRefreshProvider), 0);
    container.read(walletRefreshProvider.notifier).state++;
    expect(container.read(walletRefreshProvider), 1);
  });
}
