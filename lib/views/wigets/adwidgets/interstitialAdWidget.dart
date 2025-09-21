// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:italian_brainrot_app/services/ad_helper.dart';
// import 'package:saibai_men_app/provider.dart';

// class AdInterstitial {
//   InterstitialAd? _interstitialAd;
//   int num_of_attempt_load = 0;
//   bool? ready;

//   // create interstitial ads
//   Future<void> createAd([WidgetRef? ref, Function? afterAdFunction]) async {
//     InterstitialAd.load(
//       adUnitId: AdHelper.interstitialAdUnitId,
//       request: const AdRequest(),
//       adLoadCallback: InterstitialAdLoadCallback(
//         // 広告が正常にロードされたときに呼ばれます。
//         onAdLoaded: (InterstitialAd ad) {
//           print('InterstitialAd loadedああああああああ');
//           _interstitialAd = ad;
//           num_of_attempt_load = 0;
//           if (ref != null) {
//             ref.read(isLoadingProvider.state).state = false;
//           }
//           showAd(afterAdFunction);
//         },
//         // 広告のロードが失敗した際に呼ばれます。
//         onAdFailedToLoad: (LoadAdError error) async {
//           print('InterstitialAd failed to loadああああああああ: $error');
//           num_of_attempt_load++;
//           _interstitialAd = null;
//           if (num_of_attempt_load <= 2) {
//             await createAd(ref);
//           }
//         },
//       ),
//     );
//   }

//   // show interstitial ads to user
//   Future<void> showAd(Function? afterAdFunction) async {
//     ready = false;
//     if (_interstitialAd == null) {
//       print('Warning: attempt to show interstitial before loaded.');
//       return;
//     }
//     _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (InterstitialAd ad) {
//         print("ad onAdshowedFullscreen");
//       },
//       onAdDismissedFullScreenContent: (InterstitialAd ad) {
//         ad.dispose();
//         afterAdFunction?.call(); // 広告が閉じられた後に afterAdFunction を呼び出す
//         print("ad onAdDismissedFullScreenContent");
//       },
//       onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError aderror) {
//         print('$ad OnAdFailed $aderror');
//         ad.dispose();
//         createAd();
//       },
//     );

//     // 広告の表示には.show()を使う
//     await _interstitialAd!.show();
//     _interstitialAd = null;
//   }
// }
