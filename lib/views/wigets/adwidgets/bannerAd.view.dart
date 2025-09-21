import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:italian_brainrot_app/services/ad_helper.dart';

class BannerAdWidget extends StatelessWidget {
  final BannerAd myBanner;
  final double width; // 横幅のパラメータを追加

  BannerAdWidget({super.key, required this.width})
      : myBanner = BannerAd(
          adUnitId: AdHelper.bannerAdUnitId,
          size: AdSize(width: width.toInt(), height: AdSize.banner.height),
          request: const AdRequest(),
          listener: const BannerAdListener(),
        ) {
    myBanner.load();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: myBanner.size.height.toDouble(),
      child: AdWidget(ad: myBanner),
    );
  }
}
