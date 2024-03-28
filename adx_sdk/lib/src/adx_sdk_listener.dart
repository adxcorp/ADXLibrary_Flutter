class BannerListener {
  void Function() onAdLoaded;
  void Function(int errorCode) onAdError;
  void Function() onAdClicked;

  BannerListener({
    required this.onAdLoaded,
    required this.onAdError,
    required this.onAdClicked
  });
}

class InterstitialAdListener {

  void Function() onAdLoaded;
  void Function(int errorCode) onAdError;
  void Function() onAdImpression;
  void Function() onAdClicked;
  void Function() onAdClosed;
  void Function() onAdFailedToShow;

  InterstitialAdListener({
      required this.onAdLoaded,
      required this.onAdError,
      required this.onAdImpression,
      required this.onAdClicked,
      required this.onAdClosed,
      required this.onAdFailedToShow
  });
}

class RewardedAdListener {
  void Function() onAdLoaded;
  void Function(int errorCode) onAdError;
  void Function() onAdImpression;
  void Function() onAdClicked;
  void Function() onAdRewarded;
  void Function() onAdClosed;
  void Function() onAdFailedToShow;

  RewardedAdListener({
    required this.onAdLoaded,
    required this.onAdError,
    required this.onAdImpression,
    required this.onAdClicked,
    required this.onAdRewarded,
    required this.onAdClosed,
    required this.onAdFailedToShow
  });
}