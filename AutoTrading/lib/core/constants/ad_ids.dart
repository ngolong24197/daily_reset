import 'dart:io';
import 'package:flutter/foundation.dart';

class AdIds {
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/9214589741'
          : 'ca-app-pub-3940256099942544/2435281174';
    }
    return Platform.isAndroid
        ? 'YOUR_ANDROID_BANNER_AD_ID'
        : 'YOUR_IOS_BANNER_AD_ID';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'YOUR_ANDROID_INTERSTITIAL_AD_ID'
        : 'YOUR_IOS_INTERSTITIAL_AD_ID';
  }

  static String get adAppId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544~3347511713'
          : 'ca-app-pub-3940256099942544~1458002511';
    }
    return Platform.isAndroid
        ? 'YOUR_ANDROID_APP_ID'
        : 'YOUR_IOS_APP_ID';
  }
}