/// Web / unsupported platforms: ads are not available.
Future<void> initAds() async {}

/// Returns true if the user earned the reward.
Future<bool> showRewardedAd({required String adUnitId, required String userId, required String nonce}) async {
  throw UnsupportedError('Rewarded ads are only available in the Android / iOS app.');
}
