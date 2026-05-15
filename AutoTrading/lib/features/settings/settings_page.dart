import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers.dart';
import '../../core/services/backup/backup_service.dart';
import '../../core/services/notification/notification_service.dart';
import '../premium/premium_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final persistence = ref.read(persistenceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Premium section
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(isPremium ? Icons.verified : Icons.lock_outline),
              title: Text(isPremium ? 'Premium Active' : 'Upgrade to Premium'),
              subtitle: Text(isPremium ? 'No ads, encrypted backup' : '\$2 one-time purchase'),
              trailing: isPremium ? null : const Icon(Icons.chevron_right),
              onTap: isPremium ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumPage())),
            ),
          ),

          // Notifications
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Morning Reminder'),
            subtitle: const Text('8:00 AM'),
            value: persistence.settingsBox.get('morningNotification', defaultValue: true) as bool,
            onChanged: (val) async {
              await persistence.settingsBox.put('morningNotification', val);
              final notificationService = NotificationService();
              await notificationService.init();
              if (val) {
                await notificationService.scheduleMorningReminder(
                  const NotificationTime(hour: 8, minute: 0),
                );
              } else {
                await notificationService.cancelMorningReminder();
              }
              if (mounted) setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Reflection Reminder'),
            subtitle: const Text('9:00 PM'),
            value: persistence.settingsBox.get('eveningNotification', defaultValue: true) as bool,
            onChanged: (val) async {
              await persistence.settingsBox.put('eveningNotification', val);
              final notificationService = NotificationService();
              await notificationService.init();
              if (val) {
                await notificationService.scheduleReflectionReminder(
                  const NotificationTime(hour: 21, minute: 0),
                );
              } else {
                await notificationService.cancelReflectionReminder();
              }
              if (mounted) setState(() {});
            },
          ),

          // Backup
          const _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Export Backup'),
            subtitle: Text(isPremium ? 'Encrypted backup file' : 'Premium feature'),
            enabled: isPremium && !_isExporting,
            onTap: isPremium ? () => _exportBackup(context) : null,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Import Backup'),
            subtitle: Text(isPremium ? 'Restore from file' : 'Premium feature'),
            enabled: isPremium && !_isImporting,
            onTap: isPremium ? () => _importBackup(context) : null,
          ),

          // Misc
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Cache'),
            onTap: () => _clearCache(context),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Daily Reset'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final password = await _showPasswordDialog(context, title: 'Set Backup Password');
    if (password == null || password.length < 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters')),
        );
      }
      return;
    }

    setState(() => _isExporting = true);
    try {
      final persistence = ref.read(persistenceProvider);
      final backupService = BackupService(persistence);
      final filePath = await backupService.exportBackup(password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup saved to: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['drb'],
    );
    if (result == null || result.files.single.path == null) return;

    final password = await _showPasswordDialog(context, title: 'Enter Backup Password');
    if (password == null) return;

    setState(() => _isImporting = true);
    try {
      final persistence = ref.read(persistenceProvider);
      final backupService = BackupService(persistence);
      final success = await backupService.importBackup(password, result.files.single.path!);
      if (mounted) {
        if (success) {
          // Refresh providers with restored data
          ref.read(streakProvider.notifier).updateStreak(DateTime.now());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore failed. Wrong password or corrupted file.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context, {required String title}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter password (min 8 characters)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will clear cached data for past days. Your current streak and preferences will be kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final persistence = ref.read(persistenceProvider);
              // Clear completed features from past days (keep today)
              final today = DateTime.now();
              final todayStr = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
              final keys = persistence.settingsBox.keys
                  .where((k) => k.toString().startsWith('completed_') && k.toString() != 'completed_$todayStr')
                  .toList();
              for (final key in keys) {
                await persistence.settingsBox.delete(key);
              }
              // Clear mood entries older than 30 days
              final cutoff = today.subtract(const Duration(days: 30));
              final moodKeys = persistence.moodBox.keys.toList();
              for (final key in moodKeys) {
                final keyStr = key.toString();
                if (keyStr.length == 10) {
                  try {
                    final date = DateTime.parse(keyStr);
                    if (date.isBefore(cutoff)) {
                      await persistence.moodBox.delete(key);
                    }
                  } catch (_) {}
                }
              }
              Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
    );
  }
}