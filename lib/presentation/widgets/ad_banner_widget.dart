import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real AdMob BannerAd when configured.
    // See FIREBASE_SETUP.md for AdMob integration instructions.
    //
    // return SizedBox(
    //   height: 50,
    //   child: AdWidget(ad: _bannerAd),
    // );

    return Container(
      height: 50,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        'Ad Space',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}
