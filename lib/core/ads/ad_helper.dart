import 'dart:io';

import '../constants.dart';

/// 広告ユニットID。
/// 本番ID: AdMob の「イタリアンブレインロット大戦争」(Android / iOS)の広告ユニット(2026-11-08に画面で確認)。
/// デバッグビルドは常にテスト広告(開発中に本番広告を誤クリックしないため)。リリースビルドだけ本番。
class AdHelper {
  static const String _prodBannerAndroid = 'ca-app-pub-2847746899486154/1453847465';
  static const String _prodBannerIos = 'ca-app-pub-2847746899486154/2865672492';
  static const String _prodRewardedAndroid = 'ca-app-pub-2847746899486154/9239509154';
  static const String _prodRewardedIos = 'ca-app-pub-2847746899486154/2662987355';

  static bool get _useTest => useTestAds;

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
