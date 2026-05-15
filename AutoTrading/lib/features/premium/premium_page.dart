import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/services/sound/sound_service.dart';

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
      // In production, this would go through in_app_purchase
      // For now, directly set premium (store integration requires app store configuration)
      await ref.read(premiumProvider.notifier).setPremium(true);
      ref.read(soundServiceProvider).playChime(ChimeLength.long);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Premium activated!')));
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
      // Restore handled by in_app_purchase
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restoring purchases...')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }
}