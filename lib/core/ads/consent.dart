import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告の同意(UMP)と初期化。同意が取れてから `MobileAds.initialize()` する。
/// ストア申告(個人に合わせない広告・子ども向けではない)と一致させる:
/// 広告リクエストは、すべて [adRequest](非個人化)を使う。
class AdsConsent {
  static final _ready = Completer<bool>();

  /// 広告を出してよい状態になったら true。同意が無い・失敗したら false。
  static Future<bool> get ready => _ready.future;

  /// アプリの起動後に呼ぶ(待たない)。対象外の地域では、同意フォームは出ない。
  static Future<void> start() async {
    if (_ready.isCompleted) return;
    var ok = false;
    try {
      await _requestConsent();
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.updateRequestConfiguration(
            RequestConfiguration(tagForChildDirectedTreatment: TagForChildDirectedTreatment.no));
        await MobileAds.instance.initialize();
        ok = true;
      }
    } catch (_) {} // 失敗しても、広告なしで続ける
    if (!_ready.isCompleted) _ready.complete(ok);
  }

  static AdRequest adRequest() => const AdRequest(nonPersonalizedAds: true);

  static Future<void> _requestConsent() async {
    final info = ConsentInformation.instance;
    final updated = Completer<void>();
    info.requestConsentInfoUpdate(ConsentRequestParameters(), () => updated.complete(), (_) => updated.complete());
    await updated.future.timeout(const Duration(seconds: 10), onTimeout: () {});
    final shown = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((_) => shown.complete());
    await shown.future.timeout(const Duration(minutes: 5), onTimeout: () {}); // フォームの間は、ユーザーの操作を待つ
  }
}
