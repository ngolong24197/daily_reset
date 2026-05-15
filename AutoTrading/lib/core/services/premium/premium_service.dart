import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../persistence/persistence_service.dart';

class PremiumService {
  static const String _premiumProductId = 'com.dailyreset.premium';
  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  final PersistenceService _persistence;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PremiumService(this._persistence);

  bool get isPremium => _persistence.isPremium();

  Future<void> init() async {
    if (!_isMobile) return;
    try {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {},
      );
    } catch (_) {
      // Gracefully handle missing plugin on web/desktop
    }
  }

  Future<void> purchasePremium() async {
    if (!_isMobile) return;
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) return;

      final response = await _inAppPurchase.queryProductDetails({_premiumProductId});
      if (response.productDetails.isEmpty) return;

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (_) {
      // Store not configured in dev
    }
  }

  Future<void> restorePurchases() async {
    if (!_isMobile) return;
    try {
      await _inAppPurchase.restorePurchases();
    } catch (_) {
      // Store not configured in dev
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> details) {
    for (final detail in details) {
      if (detail.productID == _premiumProductId) {
        switch (detail.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _persistence.setPremium(true);
            break;
          case PurchaseStatus.error:
          case PurchaseStatus.pending:
          case PurchaseStatus.canceled:
            break;
        }
      }
      if (detail.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(detail);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}