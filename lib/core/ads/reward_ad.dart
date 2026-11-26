import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../strings.dart';

import 'ad_helper.dart';
import 'consent.dart';

/// リワード広告。事前に [preload] で読み込んでおき、[acquire] で取り出して [show] する。
class RewardAd {
  static RewardedAd? _cached;
  static DateTime? _loadedAt;
  static Future<RewardedAd?>? _loading;

  /// 読み込みから、この時間を過ぎた広告は、期限切れとして捨てる(AdMobは約1時間で失効)。
  static const _expire = Duration(minutes: 50);

  /// 先に読み込んでおく(待たない)。すでに読み込み済み・読み込み中なら何もしない。
  static void preload() {
    _discardExpired();
    if (_cached != null || _loading != null) return;
    _loading = _load().whenComplete(() => _loading = null);
  }

  static void _discardExpired() {
    if (_cached != null && DateTime.now().difference(_loadedAt!) > _expire) {
      _cached!.dispose();
      _cached = null;
    }
  }

  static Future<RewardedAd?> _load() async {
    try {
      if (!await AdsConsent.ready.timeout(const Duration(seconds: 8), onTimeout: () => false)) return null;
      final done = Completer<RewardedAd?>();
      await RewardedAd.load(
        adUnitId: AdHelper.rewardedAdUnitId,
        request: AdsConsent.adRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (a) => done.complete(a),
          onAdFailedToLoad: (_) => done.complete(null),
        ),
      );
      final ad = await done.future.timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (ad != null) {
        _cached = ad;
        _loadedAt = DateTime.now();
      }
      return ad;
    } catch (_) {
      return null;
    }
  }

  /// 表示できる広告を返す(読み込み済みならすぐ。読み込み中なら待つ。無ければ読み込む)。
  /// 読み込めなければ null。呼び出し側がキャンセルしても、読み込みは続き、次回に使える。
  static Future<RewardedAd?> acquire() async {
    _discardExpired();
    if (_cached == null) {
      _loading ??= _load().whenComplete(() => _loading = null);
      await _loading;
    }
    return _cached;
  }

  /// [acquire] した広告を表示する。見終わったら [onReward]。表示後、広告は使い捨て。
  static Future<void> show(RewardedAd ad, void Function() onReward) async {
    if (identical(_cached, ad)) _cached = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) => a.dispose(),
      onAdFailedToShowFullScreenContent: (a, _) => a.dispose(),
    );
    await ad.show(onUserEarnedReward: (_, __) => onReward());
  }

  /// 読み込み中は、操作できない待ち画面(キャンセルボタン付き)を出してから表示する。
  /// 戻り値: true=表示した / false=読み込めなかった / null=キャンセルした。
  static Future<bool?> showWithLoading(BuildContext context, void Function() onReward) async {
    var cancelled = false;
    final nav = Navigator.of(context, rootNavigator: true);
    final waiting = Completer<void>();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Flexible(child: Text(S.adLoading)),
          ]),
          actions: [
            TextButton(
              key: const Key('adCancel'),
              onPressed: () {
                cancelled = true;
                Navigator.pop(c);
              },
              child: Text(S.cancel),
            ),
          ],
        ),
      ),
    ).whenComplete(() => waiting.complete());
    final ad = await acquire();
    if (cancelled) return null; // 読み込みは続き、次回に使える
    if (nav.canPop()) nav.pop(); // 待ち画面を閉じる
    await waiting.future;
    if (ad == null) return false;
    await show(ad, onReward);
    return true;
  }
}
