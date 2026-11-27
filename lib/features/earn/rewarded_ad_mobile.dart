import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

bool _ready = false;

Future<void> initAds() async {
  if (_ready) return;
  await MobileAds.instance.initialize();
  _ready = true;
}

/// Loads + shows one rewarded ad. Server-Side Verification options carry the
/// one-time nonce, so Google's servers (not this app) credit the coins.
/// Returns true if the user earned the reward.
Future<bool> showRewardedAd({required String adUnitId, required String userId, required String nonce}) async {
  await initAds();
  final loaded = Completer<RewardedAd>();
  await RewardedAd.load(
    adUnitId: adUnitId,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: loaded.complete,
      onAdFailedToLoad: (e) => loaded.completeError(Exception('Ad not available right now (${e.code}). Try again in a minute.')),
    ),
  );
  final ad = await loaded.future.timeout(const Duration(seconds: 20));
  await ad.setServerSideOptions(ServerSideVerificationOptions(userId: userId, customData: nonce));

  final done = Completer<bool>();
  var earned = false;
  ad.fullScreenContentCallback = FullScreenContentCallback(
    onAdDismissedFullScreenContent: (a) {
      a.dispose();
      if (!done.isCompleted) done.complete(earned);
    },
    onAdFailedToShowFullScreenContent: (a, e) {
      a.dispose();
      if (!done.isCompleted) done.completeError(Exception('Could not show the ad.'));
    },
  );
  await ad.show(onUserEarnedReward: (_, __) => earned = true);
  return done.future;
}
