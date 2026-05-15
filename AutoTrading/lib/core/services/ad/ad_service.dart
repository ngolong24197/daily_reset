import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;
  bool _isInitialized = false;

  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get _bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-4165496434380827/6431510150'
        : 'ca-app-pub-3940256099942544/2435281174';
  }

  static String get _interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-4165496434380827/5856795083'
        : 'ca-app-pub-3940256099942544/4411468910';
  }

  Future<void> init() async {
    if (!_isMobile) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadInterstitial();
    } catch (_) {
      // Gracefully handle missing plugin on web/desktop
    }
  }

  void loadInterstitial() {
    if (!_isMobile || !_isInitialized) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoaded = false;
        },
      ),
    );
  }

  Future<void> showInterstitial(VoidCallback onAdClosed) async {
    if (!_isMobile || !_isInitialized) {
      onAdClosed();
      return;
    }
    if (_isInterstitialLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialLoaded = false;
          loadInterstitial();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialLoaded = false;
          loadInterstitial();
          onAdClosed();
        },
      );
      await _interstitialAd!.show();
    } else {
      onAdClosed();
    }
  }

  BannerAd? createBannerAd() {
    if (!_isMobile || !_isInitialized) return null;
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}