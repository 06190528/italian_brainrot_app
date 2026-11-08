import 'dart:io';

import '../constants.dart';

/// 広告ユニットID。本番IDは、このアプリ用にAdMobで作ってから [prod*] に入れる。
/// (元アプリ saibai_men_app の本番IDは流用しない)
class AdHelper {
  static const String _prodBannerAndroid = '';
  static const String _prodBannerIos = '';
  static const String _prodRewardedAndroid = '';
  static const String _prodRewardedIos = '';

  static bool get _useTest => useTestAds || _prodBannerAndroid.isEmpty;

  static String get bannerAdUnitId {
    if (_useTest) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid ? _prodBannerAndroid : _prodBannerIos;
  }

  static String get rewardedAdUnitId {
    if (_useTest) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid ? _prodRewardedAndroid : _prodRewardedIos;
  }
}
