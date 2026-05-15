import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privacy Policy for Daily Reset', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Last updated: May 2026', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            _section('Information We Collect',
              'Daily Reset collects minimal data to provide you with the best experience:\n\n'
              '• Account information: When you sign in with Google, we store your email and display name for authentication purposes only.\n'
              '• App usage data: Streak counts, completed features, mood entries, and favorite quotes are stored locally on your device.\n'
              '• Cloud backup data: If you sign in, your favorites and reflection history are synced to Firebase for backup purposes.'),
            _section('How We Use Your Information',
              '• To provide and improve the app\'s core features\n'
              '• To sync your data across devices when you sign in\n'
              '• To show relevant advertisements through Google AdMob\n'
              '• We do not sell or share your personal data with third parties'),
            _section('Cloud Storage',
              'When you sign in with Google, your favorites and reflection data is stored in Firebase Cloud Firestore. '
              'This data is protected by Firebase Security Rules that ensure only you can access your own data.'),
            _section('Advertisements',
              'Daily Reset uses Google AdMob to display ads. AdMob may collect device identifiers and usage data to serve personalized ads. '
              'You can opt out of personalized ads in your device settings.\n\n'
              'Premium users do not see advertisements.'),
            _section('Data Security',
              '• Local data is stored using encrypted Hive boxes on your device\n'
              '• Cloud data is transmitted over HTTPS and stored in Firebase with security rules\n'
              '• Backup files are encrypted with your chosen password before export'),
            _section('Data Retention',
              '• Local data persists until you clear the app data or uninstall the app\n'
              '• Cloud data persists until you delete your account\n'
              '• You can delete your local data at any time using the "Clear Cache" option in Settings'),
            _section('Children\'s Privacy',
              'Daily Reset is not intended for children under 13. We do not knowingly collect data from children under 13.'),
            _section('Changes to This Policy',
              'We may update this privacy policy from time to time. Changes will be reflected in the "Last updated" date above.'),
            _section('Contact Us',
              'If you have questions about this privacy policy, please contact us at dailyreset.app@gmail.com.'),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        const SizedBox(height: 20),
      ],
    );
  }
}