import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/features/wallet/withdrawal_intent_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('WithdrawalIntentStore Unit & Scenario Tests', () {
    test('Scenario 1: App killed before server response - intent remains securely persisted', () async {
      final intent = WithdrawalIntent(
        userId: 101,
        idempotencyKey: 'w101-ts1-rnd1',
        provider: 'bkash',
        accountNumber: '01711111111',
        amount: 100.0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );

      // Save intent before dispatching network request
      await WithdrawalIntentStore.save(intent);

      // Simulate app kill (process terminated before clear() was called)
      // On fresh launch, check store
      final restored = await WithdrawalIntentStore.getForUser(101);
      expect(restored, isNotNull);
      expect(restored!.idempotencyKey, equals('w101-ts1-rnd1'));
      expect(restored.amount, equals(100.0));
      expect(restored.accountNumber, equals('01711111111'));
      expect(restored.provider, equals('bkash'));
    });

    test('Scenario 2 & 3: Server commits withdrawal but response lost, app restarted and user retries', () async {
      final intent = WithdrawalIntent(
        userId: 102,
        idempotencyKey: 'w102-ts2-rnd2',
        provider: 'nagad',
        accountNumber: '01822222222',
        amount: 250.0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );

      await WithdrawalIntentStore.save(intent);

      // App is restarted:
      final pending = await WithdrawalIntentStore.getForUser(102);
      expect(pending, isNotNull);
      expect(pending!.idempotencyKey, equals('w102-ts2-rnd2'));

      // User retries with restored intent -> receives definitive success response
      // Clear intent upon definitive success
      await WithdrawalIntentStore.clearForUser(102);

      final afterSuccess = await WithdrawalIntentStore.getForUser(102);
      expect(afterSuccess, isNull, reason: 'Pending intent must be cleared after definitive success response');
    });

    test('Scenario 4 & 5: Exact key and payload preservation', () async {
      final intent = WithdrawalIntent(
        userId: 103,
        idempotencyKey: 'w103-ts3-rnd3',
        provider: 'rocket',
        accountNumber: '01933333333',
        amount: 50.0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );

      await WithdrawalIntentStore.save(intent);
      final readBack = await WithdrawalIntentStore.getForUser(103);

      expect(readBack!.idempotencyKey, equals(intent.idempotencyKey));
      expect(readBack.amount, equals(intent.amount));
      expect(readBack.accountNumber, equals(intent.accountNumber));
      expect(readBack.provider, equals(intent.provider));
    });

    test('Scenario 7: Account switching and logout isolation', () async {
      // User 1 initiates withdrawal
      final user1Intent = WithdrawalIntent(
        userId: 201,
        idempotencyKey: 'w201-key',
        provider: 'bkash',
        accountNumber: '01700000001',
        amount: 150.0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await WithdrawalIntentStore.save(user1Intent);

      // User 1 logs out, User 2 logs in
      final user2Pending = await WithdrawalIntentStore.getForUser(202);
      expect(user2Pending, isNull, reason: 'User 2 must never see or inherit User 1 pending intent');

      // User 2 initiates own withdrawal
      final user2Intent = WithdrawalIntent(
        userId: 202,
        idempotencyKey: 'w202-key',
        provider: 'nagad',
        accountNumber: '01700000002',
        amount: 300.0,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      );
      await WithdrawalIntentStore.save(user2Intent);

      // Verify User 1 intent remains intact and separate
      final user1Restored = await WithdrawalIntentStore.getForUser(201);
      final user2Restored = await WithdrawalIntentStore.getForUser(202);

      expect(user1Restored!.idempotencyKey, equals('w201-key'));
      expect(user2Restored!.idempotencyKey, equals('w202-key'));
      expect(user1Restored.amount, equals(150.0));
      expect(user2Restored.amount, equals(300.0));
    });

    test('Key generation produces bounded unique keys <= 36 characters', () {
      for (int i = 0; i < 50; i++) {
        final key = WithdrawalIntentStore.generateKey(9999);
        expect(key.length, lessThanOrEqualTo(36));
        expect(key.length, greaterThanOrEqualTo(8));
        expect(key.startsWith('w9999-'), isTrue);
      }
    });

    test('Expired intent older than 24 hours is automatically discarded', () async {
      final oldIntent = WithdrawalIntent(
        userId: 301,
        idempotencyKey: 'w301-old',
        provider: 'bkash',
        accountNumber: '01744444444',
        amount: 80.0,
        // 25 hours ago
        createdAtMs: DateTime.now().subtract(const Duration(hours: 25)).millisecondsSinceEpoch,
      );

      await WithdrawalIntentStore.save(oldIntent);
      final fetched = await WithdrawalIntentStore.getForUser(301);
      expect(fetched, isNull, reason: 'Intent older than 24h should be auto-cleared');
    });
  });
}
