import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';
import 'consent.dart';

/// リワード広告。見終わったら [onReward]。読み込めなければ false を返す。
class RewardAd {
  static Future<bool> show(void Function() onReward) async {
    if (!await AdsConsent.ready.timeout(const Duration(seconds: 8), onTimeout: () => false)) return false;
    var ready = false;
    RewardedAd? ad;
    try {
      final done = Completer<RewardedAd?>();
      await RewardedAd.load(
        adUnitId: AdHelper.rewardedAdUnitId,
        request: AdsConsent.adRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (a) => done.complete(a),
          onAdFailedToLoad: (_) => done.complete(null),
        ),
      );
      ad = await done.future.timeout(const Duration(seconds: 8), onTimeout: () => null);
      ready = ad != null;
    } catch (_) {
      ready = false;
    }
    if (!ready || ad == null) return false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) => a.dispose(),
      onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
    );
    await ad.show(onUserEarnedReward: (_, __) => onReward());
    return true;
  }
}
