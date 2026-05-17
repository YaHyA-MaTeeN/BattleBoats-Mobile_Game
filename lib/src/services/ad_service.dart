import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static bool _initialized = false;
  static RewardedAd? _rewardedAd;

  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  static void loadRewardedAd({String? adUnitId}) {
    final String id = adUnitId ?? testRewardedAdUnitId;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  static Future<bool> showRewardedAd({
    required Function(RewardItem) onEarnedReward,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
      return false;
    }

    bool granted = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      granted = true;
      onEarnedReward(reward);
    });

    return granted;
  }
}
