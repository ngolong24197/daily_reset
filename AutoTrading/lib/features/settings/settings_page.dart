import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/services/notification/notification_service.dart';
import '../../main.dart';
import '../premium/premium_page.dart';
import '../favorites/favorites_page.dart';
import '../reflection/reflection_history_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isRefreshing = false;
  bool _isSyncing = false;

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime(BuildContext context, int currentHour, int currentMinute, String type) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
    );
    if (picked == null) return;

    final hour = picked.hour;
    final minute = picked.minute;
    final persistence = ref.read(persistenceProvider);
    final notificationService = ref.read(notificationServiceProvider);

    if (type == 'morning') {
      await persistence.settingsBox.put('morningNotificationHour', hour);
      await persistence.settingsBox.put('morningNotificationMinute', minute);
      await notificationService.scheduleMorningReminder(NotificationTime(hour: hour, minute: minute));
    } else {
      await persistence.settingsBox.put('reflectionNotificationHour', hour);
      await persistence.settingsBox.put('reflectionNotificationMinute', minute);
      await notificationService.scheduleReflectionReminder(NotificationTime(hour: hour, minute: minute));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumProvider);
    final authState = ref.watch(authStateProvider);
    final isLoggedIn = authState.value != null;
    final user = authState.value;
    final persistence = ref.read(persistenceProvider);

    final morningEnabled = persistence.settingsBox.get('morningNotification', defaultValue: true) as bool;
    final reflectionEnabled = persistence.settingsBox.get('eveningNotification', defaultValue: true) as bool;
    final morningHour = persistence.settingsBox.get('morningNotificationHour', defaultValue: 8) as int;
    final morningMinute = persistence.settingsBox.get('morningNotificationMinute', defaultValue: 0) as int;
    final reflectionHour = persistence.settingsBox.get('reflectionNotificationHour', defaultValue: 21) as int;
    final reflectionMinute = persistence.settingsBox.get('reflectionNotificationMinute', defaultValue: 0) as int;

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
              subtitle: Text(isPremium ? 'No ads, unlimited favorites' : '\$2 one-time purchase'),
              trailing: isPremium ? null : const Icon(Icons.chevron_right),
              onTap: isPremium ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumPage())),
            ),
          ),

          // Account
          const _SectionHeader(title: 'Account'),
          if (isLoggedIn && user != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
              title: Text(user.displayName ?? 'User'),
              subtitle: Text(user.email ?? ''),
              trailing: TextButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in with Google'),
              subtitle: const Text('Backup favorites & reflections to cloud'),
              onTap: _signIn,
            ),

          // Cloud backup (only when logged in)
          if (isLoggedIn) ...[
            ListTile(
              leading: _isSyncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              title: const Text('Backup to Cloud'),
              subtitle: const Text('Upload favorites & reflections'),
              enabled: !_isSyncing,
              onTap: _backupToCloud,
            ),
            ListTile(
              leading: _isSyncing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_download),
              title: const Text('Restore from Cloud'),
              subtitle: const Text('Download cloud data to this device'),
              enabled: !_isSyncing,
              onTap: _restoreFromCloud,
            ),
          ],

          // History
          const _SectionHeader(title: 'History'),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorite Quotes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesPage())),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reflection History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReflectionHistoryPage())),
          ),

          // Notifications
          const _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: const Text('Morning Reminder'),
            subtitle: morningEnabled
                ? GestureDetector(
                    onTap: () => _pickTime(context, morningHour, morningMinute, 'morning'),
                    child: Text(_formatTime(morningHour, morningMinute), style: const TextStyle(decoration: TextDecoration.underline)),
                  )
                : const Text('Off'),
            value: morningEnabled,
            onChanged: (val) async {
              await persistence.settingsBox.put('morningNotification', val);
              final notificationService = ref.read(notificationServiceProvider);
              if (val) {
                await notificationService.scheduleMorningReminder(
                  NotificationTime(hour: morningHour, minute: morningMinute),
                );
              } else {
                await notificationService.cancelMorningReminder();
              }
              if (mounted) setState(() {});
            },
          ),
          SwitchListTile(
            title: const Text('Reflection Reminder'),
            subtitle: reflectionEnabled
                ? GestureDetector(
                    onTap: () => _pickTime(context, reflectionHour, reflectionMinute, 'reflection'),
                    child: Text(_formatTime(reflectionHour, reflectionMinute), style: const TextStyle(decoration: TextDecoration.underline)),
                  )
                : const Text('Off'),
            value: reflectionEnabled,
            onChanged: (val) async {
              await persistence.settingsBox.put('eveningNotification', val);
              final notificationService = ref.read(notificationServiceProvider);
              if (val) {
                await notificationService.scheduleReflectionReminder(
                  NotificationTime(hour: reflectionHour, minute: reflectionMinute),
                );
              } else {
                await notificationService.cancelReflectionReminder();
              }
              if (mounted) setState(() {});
            },
          ),

          // Content
          const _SectionHeader(title: 'Content'),
          ListTile(
            leading: Icon(isPremium ? Icons.cloud_download : Icons.lock_outline),
            title: const Text('Refresh Content'),
            subtitle: Text(
              isPremium
                  ? 'Download new quotes and questions'
                  : 'Premium feature',
            ),
            enabled: isPremium && !_isRefreshing,
            trailing: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: isPremium ? () => _refreshContent() : null,
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

  Future<void> _signIn() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign out failed. Please try again.')),
        );
      }
    }
  }

  Future<void> _backupToCloud() async {
    setState(() => _isSyncing = true);
    try {
      final persistence = ref.read(persistenceProvider);
      final cloudService = ref.read(cloudBackupServiceProvider);

      final favoriteIds = persistence.getFavoriteQuotes();
      final reflections = persistence.moodBox.keys.map((key) {
        final data = persistence.moodBox.get(key);
        if (data == null) return null;
        final map = Map<String, dynamic>.from(data as Map);
        return <String, dynamic>{
          'date': key.toString(),
          'mood': map['mood'],
          'journalText': map['journalText'],
          'createdAt': map['createdAt'],
        };
      }).whereType<Map<String, dynamic>>().toList();

      final success = await cloudService.uploadAll(
        favoriteQuoteIds: favoriteIds,
        reflections: reflections,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Backup uploaded successfully!' : 'Backup failed. Please try again.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _isSyncing = true);
    try {
      final cloudService = ref.read(cloudBackupServiceProvider);
      final result = await cloudService.downloadAll();

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed. Please try again.')),
        );
        return;
      }

      final persistence = ref.read(persistenceProvider);

      // Restore favorites
      if (result.favoriteQuoteIds.isNotEmpty) {
        final existing = persistence.getFavoriteQuotes();
        final merged = {...existing, ...result.favoriteQuoteIds}.toList();
        await persistence.settingsBox.put('favoriteQuotes', merged);
      }

      // Restore reflections
      for (final entry in result.reflections) {
        final date = entry['date'] as String;
        final moodIndex = entry['mood'] as int;
        await persistence.moodBox.put(date, {
          'id': date,
          'date': date,
          'mood': moodIndex,
          'journalText': entry['journalText'] ?? '',
          'createdAt': entry['createdAt'] ?? DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored ${result.favoriteQuoteIds.length} favorites and ${result.reflections.length} reflections.')),
      );
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _refreshContent() async {
    setState(() => _isRefreshing = true);
    try {
      final content = ref.read(contentProvider);
      final result = await content.refreshFromRemote();

      if (!mounted) return;

      if (result.totalSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content refreshed successfully!')),
        );
      } else if (result.partialSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content partially refreshed. Some updates failed.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach server. Try again later.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content refresh failed. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset App?'),
        content: const Text('This will delete all your progress — streak, moods, completed features, seen content, and quiz history. The app will start fresh. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final persistence = ref.read(persistenceProvider);

    // Clear streak
    await persistence.streakBox.clear();

    // Clear moods
    await persistence.moodBox.clear();

    // Clear settings (completed features, favorites, quiz results, notification times)
    await persistence.settingsBox.clear();
    // Restore notification defaults
    await persistence.settingsBox.put('morningNotification', true);
    await persistence.settingsBox.put('eveningNotification', true);
    await persistence.settingsBox.put('morningNotificationHour', 8);
    await persistence.settingsBox.put('morningNotificationMinute', 0);
    await persistence.settingsBox.put('reflectionNotificationHour', 21);
    await persistence.settingsBox.put('reflectionNotificationMinute', 0);

    // Clear seen content
    await persistence.seenContentBox.clear();

    // Clear remote content cache
    await persistence.remoteContentBox.clear();

    // Re-schedule notifications with default times
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleMorningReminder(const NotificationTime(hour: 8, minute: 0));
    await notificationService.scheduleReflectionReminder(const NotificationTime(hour: 21, minute: 0));

    // Restart the app to reflect all changes
    if (mounted) {
      restartApp();
    }
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