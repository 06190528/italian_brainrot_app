// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:italian_brainrot_app/services/ad_helper.dart';
// import 'package:saibai_men_app/provider.dart';

// class RewardAdLoader {
//   static RewardedAd? _rewardedAd;
//   final WidgetRef ref;

//   RewardAdLoader({required this.ref});

//   void loadAndShowRewardAd(
//       BuildContext context, Future<void> Function() function) {
//     _rewardedAd?.dispose();
//     ref.read(isLoadingProvider.state).state = true;

//     RewardedAd.load(
//       adUnitId: AdHelper.rewardedAdUnitId,
//       request: AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (RewardedAd ad) {
//           _rewardedAd = ad;
//           ad.show(
//               onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
//             await function();
//             ref.read(isLoadingProvider.state).state = false;
//           });
//           ad.fullScreenContentCallback = FullScreenContentCallback(
//             onAdDismissedFullScreenContent: (RewardedAd ad) {
//               ad.dispose();
//             },
//             onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
//               ad.dispose();
//             },
//           );
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           ref.read(isLoadingProvider.state).state = false;
//           print('RewardedAd failed to load: $error');
//         },
//       ),
//     );
//   }
// }
