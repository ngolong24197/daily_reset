import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.verified, size: 80, color: Color(0xFFFFA726)),
            const SizedBox(height: 24),
            const Text('Daily Reset Premium', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _featureTile(Icons.block, 'Remove Ads', 'No more interstitial ads'),
            _featureTile(Icons.backup, 'Encrypted Backup', 'AES-256 encrypted export/import'),
            _featureTile(Icons.favorite, 'Support Development', 'Help us keep improving'),
            const Spacer(),
            if (isPremium)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text('Premium Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ]),
              )
            else ...[
              FilledButton(
                onPressed: _purchasing ? null : _purchase,
                child: _purchasing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('\$2.00 — Unlock Premium Forever'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _restore,
                child: const Text('Restore Purchases'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _featureTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFFA726)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }

  Future<void> _purchase() async {
    setState(() => _purchasing = true);
    try {
      final premiumService = ref.read(premiumServiceProvider);
      await premiumService.purchasePremium();
      // Give the purchase stream time to process
      await Future.delayed(const Duration(seconds: 1));
      // Refresh state from persistence in case stream hasn't fired yet
      final isPremium = ref.read(persistenceProvider).isPremium();
      if (isPremium != ref.read(premiumProvider)) {
        await ref.read(premiumProvider.notifier).setPremium(isPremium);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    try {
      final premiumService = ref.read(premiumServiceProvider);
      await premiumService.restorePurchases();
      await Future.delayed(const Duration(seconds: 1));
      final isPremium = ref.read(persistenceProvider).isPremium();
      if (isPremium != ref.read(premiumProvider)) {
        await ref.read(premiumProvider.notifier).setPremium(isPremium);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchases restored')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }
}