import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/data/local/isar_service.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/data/models/anime_model.dart';
import 'package:otakulog/data/models/daily_activity.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/data/models/user_model.dart';
import 'package:otakulog/data/models/user_session_model.dart';
import 'package:otakulog/data/remote/backup_mapper.dart';
import 'package:otakulog/features/cloud/models/backup_payload.dart';
import 'package:otakulog/features/cloud/models/cloud_availability_state.dart';
import 'package:otakulog/features/downloads/download_queue_notifier.dart';
import 'package:otakulog/features/downloads/downloads_manager_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _animeController = TextEditingController();
  final _chapterController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _adultMode = 'off';
  String _searchMedium = 'anime';
  bool _blurCovers = false;
  bool _notificationsEnabled = true;
  bool _preferDataSaverDownloads = true;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isResettingLocalData = false;

  @override
  void dispose() {
    _nameController.dispose();
    _animeController.dispose();
    _chapterController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(retentionPreferencesProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No profile found yet.',
                  style: TextStyle(color: AppTheme.secondaryText)),
            );
          }
          _seed(user, prefsAsync.valueOrNull);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _label('Profile'),
              const SizedBox(height: 10),
              _fieldLabel('Display Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('Enter your display name'),
              ),
              const SizedBox(height: 20),
              _label('Defaults'),
              const SizedBox(height: 10),
              _fieldLabel('Average Minutes Per Episode'),
              const SizedBox(height: 8),
              TextField(
                controller: _animeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('e.g. 24'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Average Minutes Per Chapter'),
              const SizedBox(height: 8),
              TextField(
                controller: _chapterController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('e.g. 15'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Default Search Medium'),
              const SizedBox(height: 8),
              _dropdown<String>(
                value: _searchMedium,
                items: const ['anime', 'manga'],
                onChanged: (value) => setState(() => _searchMedium = value!),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Adult Content Preference'),
              const SizedBox(height: 8),
              _dropdown<String>(
                value: _adultMode,
                items: const ['off', 'mixed', 'explicitOnly'],
                onChanged: (value) => setState(() => _adultMode = value!),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _blurCovers,
                activeThumbColor: AppTheme.accent,
                title: const Text('Blur covers in public mode',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Hide covers in shared or public-facing moments.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) => setState(() => _blurCovers = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                activeThumbColor: AppTheme.accent,
                title: const Text('Enable reminders',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Allow one local reminder on inactive days.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _preferDataSaverDownloads,
                activeThumbColor: AppTheme.accent,
                title: const Text('Use data-saver chapter downloads',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Downloads lower-size MangaDex pages for offline reading.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) =>
                    setState(() => _preferDataSaverDownloads = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(user),
                child: Text(_isSaving ? 'SAVING...' : 'SAVE SETTINGS'),
              ),
              const SizedBox(height: 24),
              _label('Offline'),
              const SizedBox(height: 10),
              _downloadsCard(ref),
              const SizedBox(height: 24),
              _label('About'),
              const SizedBox(height: 10),
              _aboutCard(packageInfoAsync),
              const SizedBox(height: 24),
              _label('Danger Zone'),
              const SizedBox(height: 10),
              _dangerZoneCard(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppTheme.secondaryText)),
        ),
      ),
    );
  }

  Widget _cloudStatusCard(CloudAvailabilityState state) {
    final (title, subtitle) = switch (state) {
      CloudAvailabilityState.disabledMissingConfig => (
          'Local-only mode',
          'Cloud is not configured in this build. Your tracker still works fully offline.',
        ),
      CloudAvailabilityState.signedOut => (
          'Cloud ready',
          'Sign in to back up your data. Your tracker stays local. Backup is optional.',
        ),
      CloudAvailabilityState.ready => (
          'Cloud connected',
          'You are signed in and can back up or restore data.',
        ),
      CloudAvailabilityState.degradedOffline => (
          'Cloud degraded',
          'Cloud features are temporarily unavailable. Local tracking still works.',
        ),
    };
    return _infoCard(title, subtitle);
  }

  Widget _authCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to back up your data',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your tracker stays local. Backup is optional.',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Email'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('name@example.com'),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('Enter your password'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child: Text(_isSigningIn ? 'SIGNING IN...' : 'SIGN IN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSigningUp ? null : _signUp,
                  child: Text(_isSigningUp ? 'CREATING...' : 'SIGN UP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signedInCard(String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signed in',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: AppTheme.secondaryText)),
          const SizedBox(height: 6),
          const Text(
            'Signing out will not erase your local data.',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signOut,
              child: const Text('SIGN OUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupCard({
    required CloudAvailabilityState cloudState,
    required DateTime? lastBackupAt,
    required AsyncValue<BackupPreview?> backupPreviewAsync,
  }) {
    final canUseBackup = cloudState == CloudAvailabilityState.ready;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Cloud Backup',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            lastBackupAt == null
                ? 'No successful backup yet.'
                : 'Last backup: ${DateFormat('MMM d, yyyy - h:mm a').format(lastBackupAt)}',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 12),
          backupPreviewAsync.when(
            data: (preview) {
              if (preview == null) {
                return const Text('No cloud backup found yet.',
                    style: TextStyle(color: AppTheme.secondaryText));
              }
              return Text(
                'Cloud backup from ${DateFormat('MMM d, yyyy').format(preview.exportedAt)} - ${preview.libraryCount} items - ${preview.sessionsCount} sessions',
                style: const TextStyle(color: AppTheme.secondaryText),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text('Cloud preview unavailable.',
                style: TextStyle(color: AppTheme.secondaryText)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canUseBackup && !_isBackingUp ? _backupNow : null,
                  child: Text(_isBackingUp ? 'BACKING UP...' : 'BACKUP NOW'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      canUseBackup && !_isRestoring ? _restoreData : null,
                  child: Text(_isRestoring ? 'RESTORING...' : 'RESTORE DATA'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(AsyncValue<dynamic> packageInfoAsync) {
    final versionText = packageInfoAsync.valueOrNull == null
        ? 'Version unavailable'
        : '${packageInfoAsync.value.version} (${packageInfoAsync.value.buildNumber})';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OtakuLog',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () => context.push('/debug/analytics'),
            child: Text(versionText,
                style: const TextStyle(color: AppTheme.secondaryText)),
          ),
          const SizedBox(height: 10),
          const Text(
            'A local-first anime and manga tracker with quick logging, wrapped stats, and optional cloud backup.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Privacy: your tracker works locally first. Cloud backup is optional and only used when you sign in.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: _sendFeedback,
            icon: const Icon(Icons.mail_outline),
            label: const Text('SEND FEEDBACK'),
          ),
        ],
      ),
    );
  }

  Widget _downloadsCard(WidgetRef ref) {
    final totalBytesAsync = ref.watch(totalDownloadedBytesProvider);
    final downloadsAsync = ref.watch(downloadedChaptersProvider);
    final count = downloadsAsync.valueOrNull?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline manga downloads',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count downloaded chapter${count == 1 ? '' : 's'} • ${totalBytesAsync.when(data: DownloadsManagerScreen.formatBytes, loading: () => 'Calculating...', error: (_, __) => 'Unavailable')}',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/downloads'),
              icon: const Icon(Icons.download_done_outlined),
              label: const Text('MANAGE DOWNLOADS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset local app data',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Erase this device profile, library, sessions, retention preferences, and local analytics. Cloud backups are not deleted.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
              onPressed: _isResettingLocalData ? null : _resetLocalData,
              child: Text(_isResettingLocalData
                  ? 'RESETTING...'
                  : 'RESET LOCAL DATA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }

  void _seed(dynamic user, dynamic prefs) {
    if (_initialized) return;
    _nameController.text = user.displayName;
    _animeController.text = user.defaultAnimeWatchTime.toString();
    _chapterController.text = user.avgChapterMinutes.toString();
    _adultMode = user.defaultAdultMode;
    _searchMedium = user.defaultSearchMedium;
    _blurCovers = user.blurCoverInPublic;
    _notificationsEnabled = prefs?.notificationsEnabled ?? true;
    _preferDataSaverDownloads = prefs?.preferDataSaverDownloads ?? true;
    _initialized = true;
  }

  Future<void> _save(dynamic user) async {
    setState(() => _isSaving = true);
    try {
      final savedUser = user.copyWith(
        name: _nameController.text.trim().isEmpty
            ? user.name
            : _nameController.text.trim(),
        updatedAt: DateTime.now(),
        defaultSearchType: _searchMedium,
        defaultContentRating: _adultMode,
        defaultAnimeWatchTime:
            int.tryParse(_animeController.text.trim()) ??
                user.defaultAnimeWatchTime,
        defaultMangaReadTime: int.tryParse(_chapterController.text.trim()) ??
            user.defaultMangaReadTime,
        filter18Plus: _blurCovers,
      );
      await ref.read(userRepositoryProvider).saveUser(savedUser);

      final prefs = await ref.read(retentionPreferencesProvider.future);
      await ref.read(retentionPreferencesServiceProvider).save(
            prefs.copyWith(
              notificationsEnabled: _notificationsEnabled,
              preferDataSaverDownloads: _preferDataSaverDownloads,
              lastAppOpenedAtIso: DateTime.now().toIso8601String(),
            ),
          );

      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(searchDefaultsProvider);
      ref.invalidate(retentionReminderProvider);

      _showMessage('Settings updated');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signUp() async {
    if (!_validateAuthInputs()) return;
    setState(() => _isSigningUp = true);
    try {
      await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(authSessionProvider);
      _showMessage(
          'Account created. Check your inbox if email confirmation is enabled.');
    } catch (error) {
      ref.read(cloudDegradedProvider.notifier).state = _isOfflineError(error);
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  Future<void> _signIn() async {
    if (!_validateAuthInputs()) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.read(cloudDegradedProvider.notifier).state = false;
      ref.invalidate(authSessionProvider);
      _showMessage('Signed in');
    } catch (error) {
      ref.read(cloudDegradedProvider.notifier).state = _isOfflineError(error);
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
      ref.read(cloudDegradedProvider.notifier).state = false;
      ref.invalidate(authSessionProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage('Signed out');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _resetLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reset local data?'),
        content: const Text(
          'This will erase all local tracker data on this device and return you to onboarding. Cloud backups stay untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResettingLocalData = true);
    try {
      await ref.read(reminderServiceProvider).cancelReminder();
      await IsarService.instance.writeTxn(() async {
        await IsarService.instance.animeModels.clear();
        await IsarService.instance.mangaModels.clear();
        await IsarService.instance.userSessionModels.clear();
        await IsarService.instance.userModels.clear();
        await IsarService.instance.dailyActivitys.clear();
      });
      await ref
          .read(retentionPreferencesServiceProvider)
          .save(const RetentionPreferences());
      await ref.read(downloadedChapterStoreProvider).clearAll();
      await ref.read(localAnalyticsServiceProvider).reset();
      if (ref.read(authServiceProvider).isAvailable) {
        await ref.read(authServiceProvider).signOut();
      }

      ref.invalidate(authSessionProvider);
      ref.invalidate(authUserProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(analyticsSnapshotProvider);
      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(libraryAnimeProvider);
      ref.invalidate(libraryMangaProvider);
      ref.invalidate(allSessionsProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(latestSessionByContentProvider);
      ref.invalidate(activityTimelineProvider);
      ref.invalidate(dailyActivityProvider);
      ref.invalidate(monthlyActivityProvider);
      ref.invalidate(earliestActivityDateProvider);
      ref.invalidate(userPreferenceProfileProvider);
      ref.invalidate(recommendationsProvider);
      ref.invalidate(weeklyWrappedProvider);
      ref.invalidate(monthlyWrappedProvider);
      ref.invalidate(wrappedPromptProvider);
      ref.invalidate(retentionReminderProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      ref.invalidate(downloadedChaptersProvider);
      ref.invalidate(totalDownloadedBytesProvider);
      ref.invalidate(downloadQueueNotifierProvider);

      if (!mounted) return;
      _showMessage('Local app data reset');
      context.go('/launch');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isResettingLocalData = false);
    }
  }

  Future<void> _backupNow() async {
    setState(() => _isBackingUp = true);
    try {
      final profile = await ref.read(currentUserProvider.future);
      final library = await ref.read(combinedLibraryProvider.future);
      final sessions = await ref.read(allSessionsProvider.future);
      final result = await ref.read(syncServiceProvider).pushLocalToRemote(
            profile: profile,
            library: library,
            sessions: sessions,
          );
      if (result.success) {
        await ref.read(localAnalyticsServiceProvider).track('backup_now');
        ref.invalidate(analyticsSnapshotProvider);
      }
      ref.read(cloudDegradedProvider.notifier).state = !result.success &&
          (result.message.toLowerCase().contains('internet') ||
              result.message.toLowerCase().contains('socket'));
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage(result.message);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreData() async {
    final remote = await ref.read(syncServiceProvider).previewRemoteBackup();
    if (remote == null) {
      _showMessage('No backup found');
      return;
    }
    if (!mounted) {
      return;
    }
    final preview = ref.read(backupMapperProvider).buildPreview(remote.payload);
    if (remote.payload.schemaVersion > BackupPayload.currentSchemaVersion) {
      _showMessage('This backup was created by a newer app version.');
      return;
    }

    final mode = await showModalBottomSheet<RestoreMode>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Restore your data',
                style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how to apply your cloud backup to this device.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                'Backup from ${DateFormat('MMM d, yyyy - h:mm a').format(preview.exportedAt)}\n'
                '- ${preview.libraryCount} library items\n'
                '- ${preview.sessionsCount} sessions\n'
                '- Display name: ${preview.profileName ?? 'Unknown'}',
                style:
                    const TextStyle(color: AppTheme.primaryText, height: 1.5),
              ),
              const SizedBox(height: 18),
              _restoreOption(
                title: 'Merge with current data',
                subtitle:
                    'Recommended. Keeps this device data and combines it with the backup.',
                onTap: () => Navigator.pop(sheetContext, RestoreMode.merge),
              ),
              const SizedBox(height: 10),
              _restoreOption(
                title: 'Replace local data',
                subtitle:
                    'Erases current device data and restores only the cloud backup.',
                destructive: true,
                onTap: () =>
                    Navigator.pop(sheetContext, RestoreMode.replaceLocal),
              ),
            ],
          ),
        ),
      ),
    );

    if (mode == null) return;
    if (!mounted) {
      return;
    }
    if (mode == RestoreMode.replaceLocal) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Replace local data?'),
          content: const Text(
              'This will overwrite local profile data, library items, sessions, and retention preferences on this device.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Replace')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isRestoring = true);
    try {
      final result =
          await ref.read(syncServiceProvider).pullRemoteToLocal(mode: mode);
      if (result.success) {
        await ref.read(localAnalyticsServiceProvider).track(
              mode == RestoreMode.merge
                  ? 'restore_merge'
                  : 'restore_replace_local',
            );
        ref.invalidate(analyticsSnapshotProvider);
      }
      ref.read(cloudDegradedProvider.notifier).state = !result.success &&
          (result.message.toLowerCase().contains('internet') ||
              result.message.toLowerCase().contains('socket'));
      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(allSessionsProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(latestSessionByContentProvider);
      ref.invalidate(activityTimelineProvider);
      ref.invalidate(dailyActivityProvider);
      ref.invalidate(userPreferenceProfileProvider);
      ref.invalidate(recommendationsProvider);
      ref.invalidate(weeklyWrappedProvider);
      ref.invalidate(monthlyWrappedProvider);
      ref.invalidate(wrappedPromptProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage(result.message);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _sendFeedback() async {
    final packageInfo = await ref.read(packageInfoProvider.future);
    final authUser = ref.read(authUserProvider);
    final user = await ref.read(currentUserProvider.future);
    final subject =
        Uri.encodeComponent('OtakuLog feedback ${packageInfo.version}');
    final body = Uri.encodeComponent(
      'App version: ${packageInfo.version} (${packageInfo.buildNumber})\n'
      'Profile: ${user?.displayName ?? 'Unknown'}\n'
      'Signed in: ${authUser?.email ?? 'No'}\n\n'
      'What works well?\n\n'
      'What feels confusing?\n\n'
      'What would you add?\n',
    );
    final mailto = Uri.parse('mailto:xvx016xc@gmail.com?subject=$subject&body=$body');

    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text:
            'OtakuLog feedback ${packageInfo.version}\n\nWhat works well?\n\nWhat feels confusing?\n\nWhat would you add?\n',
      ),
    );
    if (!mounted) {
      return;
    }
    _showMessage('No mail app found. Feedback template copied to clipboard.');
  }

  Widget _restoreOption({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: destructive
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: destructive ? Colors.redAccent : AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: AppTheme.secondaryText)),
          ],
        ),
      ),
    );
  }

  bool _validateAuthInputs() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Enter both email and password');
      return false;
    }
    return true;
  }

  bool _isOfflineError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('internet');
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('AuthRetryableFetchException')) {
      return 'Could not reach Supabase. Check your internet connection.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _label(String value) {
    return Text(
      value.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: AppTheme.primaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: AppTheme.secondaryText),
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString(),
                        style: const TextStyle(color: AppTheme.primaryText)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
